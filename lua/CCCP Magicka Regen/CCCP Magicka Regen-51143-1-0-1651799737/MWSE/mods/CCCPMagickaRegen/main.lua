local config = require("CCCPMagickaRegen.config")
local modInfo = require("CCCPMagickaRegen.modInfo")

local savedData, simulateActive

local magicSkillList = {
    tes3.skill.alchemy,
    tes3.skill.alteration,
    tes3.skill.conjuration,
    tes3.skill.destruction,
    tes3.skill.enchant,
    tes3.skill.illusion,
    tes3.skill.mysticism,
    tes3.skill.restoration,
}

-- Print all those debug messages in the log, if the mod is configured to do so.
local function debugMsg(message)
    if config.debugMode then
        mwse.log(string.format("[%s %s DEBUG] %s", modInfo.mod, modInfo.version, message))
    end
end

-- Called on each magicka regen tick to mod current magicka amount.
local function changeCurrentMagicka(addedAmount)
    tes3.modStatistic{
        reference = tes3.player,
        name = "magicka",
        current = addedAmount,
    }
end

-- Called on every magicka regen tick to check whether or not the player is affected by Stunted Magicka.
local function getStunted()
    return tes3.isAffectedBy{
        reference = tes3.player,
        effect = tes3.effect.stuntedMagicka,
    }
end

-- Runs every 0.1 seconds after chargen is complete, except when the menu is open.
local function magRegenTick()
    --[[ These values are used in the magicka regen calculations, and will also need to be saved in our persistent
    player data so we can refer to the previous values, so we get them here up front. The GameHour global variable is a
    number from 0-24 that represents the in-game time (it's a float value, so it would be about 11.75 at 11:45 AM, for
    example). DaysPassed is the same value you see in the journal (Day 1, Day 2, and so on). Timescale represents how
    quickly in-game time passes compared to real time. The default timescale in vanilla Morrowind is 30, which means 30
    in-game seconds pass for each real-life second. ]]--
    local currentMagicka = tes3.mobilePlayer.magicka.currentRaw
    local currentGameTime = tes3.findGlobal("GameHour").value
    local currentGameDay = tes3.findGlobal("DaysPassed").value
    local currentTimescale = tes3.findGlobal("Timescale").value

    -- We'll be dividing by this value, so let's make sure we don't divide by zero (math.max returns the higher of the
    -- two values). If the player is using a negative timescale, weird things would happen, and I didn't feel like
    -- taking such an unlikely occurrence into account.
    currentTimescale = math.max(currentTimescale, 0.1)

    --[[ If the player has disabled magicka regen or is affected by Stunted Magicka, we don't want to regenerate
    magicka. Same if the player is already at or above max magicka (i.e. magicka ratio >= 1.0). Also, these calculations
    require that we know the most recent values for current magicka, game time, game day and timescale, so if those
    values aren't saved, we cannot proceed. ]]--
    if ( not config.magickaRegen )
    or getStunted()
    or tes3.mobilePlayer.magicka.normalized >= 1.0
    or ( not savedData.lastCurrentMagicka )
    or ( not savedData.lastGameTime )
    or ( not savedData.lastGameDay )
    or ( not savedData.lastTimescale ) then

        -- Even if we're not regenerating magicka this tick, we need to save these current values in our player data for
        -- use in case things change in the next tick. This will happen in the very first regen tick for a character, so
        -- we can save the current magicka and time-related values for the first time.
        savedData.lastCurrentMagicka = currentMagicka
        savedData.lastGameTime = currentGameTime
        savedData.lastGameDay = currentGameDay
        savedData.lastTimescale = currentTimescale
        return
    end

    --[[ It's possible that the timescale has changed since the last tick (which is why we check it every tick in the
    first place). If so, we don't necessarily want to use the *current* timescale for this tick's calculations, but
    whichever of the two timescales is higher. Otherwise, the result could potentially be that the player will receive a
    much higher amount of magicka than normal this tick.

    To take an extreme example, let's say the player had a timescale of 3600 last tick, but now the timescale is only 6.
    Using a timescale of 6 for this tick's calculations would result in a much larger amount of magicka per game hour.
    Normally that's okay, because correspondingly less game time will have passed with a timescale of 6. But the
    timescale could have been 3600 for most of this past tick, which means much more in-game time would have passed than
    would be expected with a timescale of 6. This can result in a very noticeable boost to current magicka this tick,
    vastly more than the player should receive.

    Therefore, we use the higher of the two timescales, because it's better for the player to receive too little magicka
    for one tick than way too much. ]]--
    local currentTimescaleToUse = math.max(currentTimescale, savedData.lastTimescale)

    -- Calculate the number of real-life seconds that pass per in-game hour.
    local secondsPerGameHour = 3600 / currentTimescaleToUse

    local currentWillpower = tes3.mobilePlayer.willpower.current

    --[[ These are all presented as sliders from 0-100 in the MCM, but in the code they're decimal multipliers from 0-1.
    So adjust them here so they can be used in our calculations. willpowerInfluence and fatigueInfluence are the extent
    to which those stats influence magicka regen. neutralFatigueRatio is the fatigue ratio that would result in "normal"
    magicka regen rate. ]]--
    local willpowerInfluence = 0.01 * config.magRegenWilInfluence
    local neutralFatigueRatio = 0.01 * config.magRegenFatValue
    local fatigueInfluence = 0.01 * config.magRegenFatInfluence

    -- The extent to which fatigue does *not* influence magicka regen.
    local fatigueNoninfluence = 1 - fatigueInfluence

    -- The neutral fatigue ratio modified by the fatigue influence proportion.
    local weightedFatValue = fatigueInfluence * neutralFatigueRatio

    -- The higher this is, the slower magicka will regen, and vice versa. The highest possible value is 1, which will be
    -- seen if fatigue influence is 0. Very high fatigue influence and very low neutral fatigue ratio can have crazy
    -- results.
    local divisor = fatigueNoninfluence + weightedFatValue

    -- Avoid a possible divide by zero error if the player makes unusual changes in the MCM. (Though if this happens,
    -- the result would be an insane regen rate.)
    divisor = math.max(divisor, 0.01)

    -- This is a straight-up multiplier to regen rate. Minimum 1, maximum 100 (which is insane).
    local fatigueMultiplier = 1 / divisor

    --[[ If willpower influence is very low, the ineffective component will be very close to the neutral willpower
    value, and the effective component will be very low, leading to a willpower modifier very close to 1.0 regardless of
    current willpower. If willpower influence is very high, the ineffective component will be very low, and the
    effective component will be very close to current willpower, leading to a willpower modifier very close to a direct
    ratio between current willpower and the neutral willpower value. Willpower modifier is a straight-up multiplier to
    regen rate. ]]--
    local ineffectiveComponent = config.magRegenWilValue * ( 1 - willpowerInfluence )
    local effectiveComponent = currentWillpower * willpowerInfluence
    local willpowerModifier = ( effectiveComponent + ineffectiveComponent ) / config.magRegenWilValue

    -- The player's current magic skill total also influences regen rate, depending on the configurable magRegenProgress
    -- setting.
    local progressComponent = savedData.totalMagicSkills * 0.1 * config.magRegenProgress

    -- Another straight-up multiplier to regen rate. Generally ranges from about 0.5 to 0.9 times willpower modifier.
    local rateMultiplier = ( progressComponent + 1000 ) * 0.0005 * willpowerModifier

    --[[ fatigueValue is yet another multiplier to regen rate. If fatigue influence is very low, then fatigueValue will
    be very close to 1.0 regardless of current fatigue. If fatigue influence is very high, then fatigueValue will be
    very close to current fatigue ratio (and fatigueMultiplier will be higher to make up for it, depending on the
    neutral fatigue ratio). ]]--
    local fatigueRatio = tes3.mobilePlayer.fatigue.normalized
    local fatigueValue = ( fatigueRatio * fatigueInfluence ) + fatigueNoninfluence

    -- Apply the fatigueValue, fatigueMultiplier and rateMultiplier multipliers to how many "regen points" the player
    -- started out with. (Multipliers for willpower and the player's current magic skill total have already been
    -- applied.) regenRate is the amount of magicka the player will gain per second of real time.
    rateMultiplier = rateMultiplier * fatigueValue
    local regenPoints = savedData.startRegenPoints * fatigueMultiplier
    local regenRate = regenPoints * rateMultiplier

    --[[ How much magicka the player will gain per game hour. This will later be multiplied by the number of game hours
    that have passed since the last tick (normally a very small fraction of a game hour for most ticks) to determine the
    actual amount of magicka gained this tick.

    This seems unnecessarily complicated at first, compared to just calculating an amount per 0.1 seconds real time and
    applying it. The reason we do it this way is that it accounts for all sorts of non-standard situations, such as
    waiting, resting, fast travel, training, or anything else that causes time to pass. This way, the player will gain
    magicka for the passage of this time basically as though they had just stood there letting ticks go by the whole
    time. ]]--
    local magickaPerGameHour = regenRate * secondsPerGameHour

    -- Using a new variable for this so we can save the actual in-game time in our persistent data later.
    local currentTimeToUse = currentGameTime

    --[[ We need to calculate how much game time has passed since the last tick, but this is more complicated if the day
    has changed, since the GameHour global will be reset to 0. So, if it's a new day since the last tick, we just add 24
    to the current game time (or possibly a multiple of 24 if more than one day has passed) so we can compare it to the
    current time later. ]]--
    if currentGameDay ~= savedData.lastGameDay then
        local dayDiff = currentGameDay - savedData.lastGameDay
        currentTimeToUse = currentTimeToUse + ( 24 * dayDiff )
    end

    -- How many game hours (or fraction of a game hour for most ticks) have passed since the last tick.
    local hoursPassed = currentTimeToUse - savedData.lastGameTime

    -- In most cases this is the actual amount of magicka to add this tick.
    local magickaToAdd = hoursPassed * magickaPerGameHour

    --[[ If a full game hour or more has passed, then (almost certainly) the player is waiting, resting, or doing
    something else that causes the passage of time. In this case, the amount of magicka gained for that time would
    normally depend on the timescale, with a lower timescale resulting in more magicka gained (since magicka per game
    hour will be higher).

    This would reward the player for using a very low timescale; they could just wait an hour to fully restore magicka.
    It would also punish the player for using a high timescale, significantly reducing the magicka gained per hour of
    waiting, etc.

    To make it so that the amount of magicka gained on waiting, etc. does not depend on timescale, we check to see if
    the timescale is something other than 30. If it is, then we recalculate magickaToAdd as though the timescale were
    30. This way, waiting or otherwise instantly passing time will result in the same magicka gain regardless of the
    timescale the player is using.

    This could potentially result in the player receiving (much) too much magicka if they're using a timescale of about
    36000 or higher (and so an hour or more game time passes within 0.1 seconds real time). But this is unlikely enough
    that I don't think it's worth bothering to compensate for. ]]--
    if hoursPassed >= 1.0 and currentTimescaleToUse ~= 30 then
        magickaToAdd = hoursPassed * regenRate * 120
    end

    -- There are a couple other unusual circumstances that we need to compensate for before actually adding magicka.
    -- First, we need the player's max magicka.
    local maxMagicka = tes3.mobilePlayer.magicka.baseRaw

    --[[ We also need to use the player's current magicka in these calculations, but we actually want to use the *lower*
    of current magicka now and current magicka at the end of the last tick, after the regen was applied. For most ticks
    these will be the same, but they'll be different if the player has lost or gained magicka since the last tick.

    The reason we want to do this is in case the player has gained magicka since the end of the last tick. This would
    happen when the player e.g. uses a Restore Magicka potion, but more importantly when the player rests (Morrowind
    will do its vanilla magicka restoration on rest). In this case, we want to use the previous, lower value.

    This is to compensate for the vanilla magicka gain on resting. We don't want to double up and provide the vanilla
    resting gain plus the full regen gain for that time. But using the higher, post-vanilla-gain value for the
    calculations can result in too little magicka being gained under certain circumstances. Specifically, this can
    happen when, after the vanilla gain, the regen gain would bring magicka above the max if not compensated for. In
    this case, it's compensated for twice, and we would overcompensate if we used the higher value. Using the lower
    value results in the correct amount of magicka being added.

    Here's an example. Let's say the player has magicka of 60/120. Now they *rest* (not wait) for five hours. Regen
    calculations determine that five hours of passed time result in a regen tick of 50 magicka, which would result in
    magicka of 110/120. But Morrowind has added the vanilla magicka gain upon resting before this is all calculated.
    Let's say Morrowind has added 25 magicka for resting for five hours, bringing magicka at the beginning of the tick
    to 85/120. What we want is for the regen to bring magicka up to 110/120, which is what it would have been without
    the vanilla magicka gain. (Don't worry, when the vanilla gain exceeds what the regen tick would give us, the vanilla
    gain is kept.)

    If we didn't compensate for anything here, the regen tick of 50 would then bring magicka up to 135/120, which is
    bad. So, below we compensate for a situation where the tick would bring magicka above the max, ensuring the regen
    amount is no more than the difference between current and max magicka. If we used the current, higher value of
    current magicka in these calculations, this would mean the regen amount of this tick is reduced from 50 to 35.

    But we don't want to bring magicka all the way up to max this tick. So, we additionally compensate for a situation
    where the current magicka at the beginning of the tick is higher than current magicka at the end of the last tick,
    subtracting that difference from the regen amount for this tick. (If this brings the regen amount below 0, nothing
    will happen; magicka won't be decreased below the vanilla gain amount).

    In this case, the vanilla gain amount is 25. If we used the (higher) current magicka amount in the calculations, the
    tick amount at this point would be 35, and we would subtract 25 from it to compensate for vanilla gain, leading to a
    regen amount of 10 for this tick. Since magicka is currently 85/120, a regen amount of 10 would give us 95/120
    magicka, which is 15 below the 110/120 we should be at.

    Now, let's do the calculations again using the (lower) previous current magicka amount. Again, calculated regen
    amount is 50 for this tick, magicka started at 60/120 but is now 85/120 due to the vanilla resting gain. We'll use
    60, the lower amount, as current magicka for the calculations. First, we'll check to see if we need to compensate
    for the regen tick bringing us above max magicka. Difference between current and max is 60, and the tick amount is
    50, so it would not bring us above max. Tick amount remains 50 so far.

    Then we compensate for the vanilla gain. The vanilla gain amount is 25, so we subtract that amount from the regen
    amount of 50 to arrive at a new regen amount of 25 for this tick. Magicka is currently 85/120, and adding the tick
    amount of 25 leads to 110/120, which is the correct amount.

    Using the lower value for current magicka in the calculations will never result in magicka being brought above the
    max, because we also compensate for the vanilla increase. So, if the originally calculated tick amount in the above
    example had been 80 instead of 50, it would be brought down to 60 first in the max magicka check, then lowered by 25
    (to 35) in the vanilla gain check, resulting in a new magicka of 120/120.

    The result of all this is that the player gets either the vanilla resting gain *or* the regen gain, whichever is
    higher, but not both. Getting both could be too overpowered. Characters that aren't particularly magic-focused will
    have an advantage to resting rather than waiting, since the vanilla resting gain will be higher than the regen gain.
    While more magic-focused characters will receive the higher regen gain regardless. In other words, the vanilla
    resting gain just compensates for slow magicka regen while resting. ]]--
    local currentToUse = math.min(currentMagicka, savedData.lastCurrentMagicka)

    -- Ensure that the regen tick will not bring current magicka above max magicka.
    local maxMinusCurrent = maxMagicka - currentToUse
    local actualRate = math.min(magickaToAdd, maxMinusCurrent)

    -- If current magicka has increased since the last tick (e.g. from resting), we need to compensate for that by
    -- reducing the regen amount by the amount magicka has increased.
    if currentMagicka > savedData.lastCurrentMagicka then
        local magickaDiff = currentMagicka - savedData.lastCurrentMagicka
        actualRate = actualRate - magickaDiff
    end

    -- Actually increase current magicka by the regen amount, assuming regen amount is still positive. (If it was made
    -- negative by the last check, magicka will not be decreased.)
    if actualRate > 0 then
        changeCurrentMagicka(actualRate)
    end

    -- Save these values in our player data so we can compare them in the next tick.
    savedData.lastGameTime = currentGameTime
    savedData.lastGameDay = currentGameDay
    savedData.lastTimescale = currentTimescale
    savedData.lastCurrentMagicka = tes3.mobilePlayer.magicka.currentRaw
end

-- Runs after initial calculations are complete or when a savegame is loaded. This function just starts our magicka
-- regen timer. Timers are wiped out on game load, so there's no need to worry about multiple instances running.
local function initMagRegenTimer()
    debugMsg("Initiating magicka regen timer.")

    -- Iterations of -1 means the timer will run indefinitely, every 0.1 seconds. Timers run on simulate time by
    -- default, so the callback won't run in menu mode.
    timer.start{
        iterations = -1,
        duration = 0.1,
        callback = magRegenTick,
    }
end

-- Called in initialCalculations to check if a skill is on the magic skill list in data.lua.
local function checkMagicSkill(id)
    for _, tableId in ipairs(magicSkillList) do
        if id == tableId then
            debugMsg("This is a magic skill.")
            return true
        end
    end

    return false
end

-- Called each time a skill increases.
local function onSkillRaised(e)
    local skillId = e.skill
    debugMsg(string.format("%s skill has been raised.", tes3.skillName[skillId]))

    -- Check to see if this is one of the eight magic skills. If so, increment the magic skills total.
    if checkMagicSkill(skillId) then
        savedData.totalMagicSkills = savedData.totalMagicSkills + 1
        debugMsg(string.format("savedData.totalMagicSkills: %f", savedData.totalMagicSkills))
    end
end

--[[ Called immediately after chargen is complete (or if the player installs this mod mid-game). This function runs only
once per character and is responsible for all initial calculations. This mod uses the player's initial skill values in
these calculations, and these initial values can only be determined at the beginning of the game (MWSE has no way to
determine initial skill values after the fact). If the player installs the mod mid-game, the calculations will assume
the player's initial skills were all average, and the result will be less than ideal. ]]--
local function initialCalculations(newGame)
    local initialSkillSum = 0

    -- Creates a block of persistent data that's saved in the player's savegame. This is needed so certain values
    -- calculated here can persist between game sessions and be referred to (and in some cases modified) later. This
    -- block of data starts off as a blank table.
    tes3.player.data.CCCPMagickaRegen = {}

    -- The local variable savedData is just an alias for our persistent block of data, making it easier to reference.
    savedData = tes3.player.data.CCCPMagickaRegen
    savedData.totalMagicSkills = 0

    -- If newGame is true, then this function is being run after chargen, as intended.
    if newGame then
        debugMsg("This is a new game, so using actual skills.")

        -- Go through all 27 of the player's skills, one at a time.
        for i, skill in ipairs(tes3.mobilePlayer.skills) do
            -- Skill IDs in MWSE are 0-26, but the actual skills used by the game for mobile actors are indexed 1-27.
            local skillId = i - 1

            -- We need to add up all the initial skills.
            local initialSkill = skill.base
            initialSkillSum = initialSkillSum + initialSkill
            debugMsg(string.format("%s skill: %f", tes3.skillName[skillId], initialSkill))
            debugMsg(string.format("initialSkillSum so far: %f", initialSkillSum))

            -- This checks to see if the current skill is one of the eight magic skills. We need to add up the total of
            -- the player's magic skills and save that data for later use.
            if checkMagicSkill(skillId) then
                savedData.totalMagicSkills = savedData.totalMagicSkills + initialSkill
                debugMsg(string.format("savedData.totalMagicSkills so far: %f", savedData.totalMagicSkills))
            end
        end

    --[[ newGame will be false only if the player starts using this mod during an existing playthrough rather than
    starting a new game. This is bad because one of the saved values which the mod uses in its regen calculations is
    based on the player's initial skill values, which MWSE has no way of determining after the fact. This is why
    starting a new game is strongly recommended with this mod.

    If this mod is installed mid-game, magicka regen calculations will be made using average initial skill values. The
    actual regen rate will still vary by character, since the player's current skills are taken into account, but the
    result will likely be very different from what it would be if these calculations had been done after chargen as
    intended. ]]--
    else
        debugMsg("This is not a new game, so using typical average initial skills.")

        -- Set this sum to the average value for vanilla Morrowind. (If the player is using a mod that changes this, we
        -- have no way of knowing.)
        initialSkillSum = 400

        local averageSkill = initialSkillSum / 27

        -- We don't know what the player's starting magic skill total was, so set it to an average.
        savedData.totalMagicSkills = averageSkill * 8

        debugMsg(string.format("initialSkillSum: %f", initialSkillSum))
        debugMsg(string.format("savedData.totalMagicSkills: %f", savedData.totalMagicSkills))
    end

    -- We need the player's average starting skill.
    local initialSkillAverage = initialSkillSum / 27
    debugMsg(string.format("initialSkillAverage: %f", initialSkillAverage))

    -- The total magic skills the player would have if all initial skills were average. The actual initial magic skill
    -- total will be compared with this and used in magicka regen calculations.
    local avgInitialMagicSkills = initialSkillAverage * 8
    debugMsg(string.format("avgInitialMagicSkills: %f", avgInitialMagicSkills))

    -- Determine the ratio of actual to average initial magic skills, affected by a configurable offset.
    local magRegenOffsetTotal = savedData.totalMagicSkills + config.magRegenStartOffset
    local magRegenAvgOffsetTotal = avgInitialMagicSkills + config.magRegenStartOffset
    local magRegenRelativeOffsetTotal = magRegenOffsetTotal / magRegenAvgOffsetTotal

    -- Calculate how many "regen points" the player starts out with, which is a function of the player's starting magic
    -- skills, the magicka regen offset, and the configurable base regen rate (which acts as a straight multiplier).
    -- This value will be used in magicka regen calculations later.
    local magRegenRelativeToAvg = magRegenRelativeOffsetTotal * avgInitialMagicSkills
    savedData.startRegenPoints = ( magRegenRelativeToAvg * 0.01 * config.magRegenBaseRate ) / 1000

    debugMsg(string.format("magRegenOffsetTotal: %f", magRegenOffsetTotal))
    debugMsg(string.format("magRegenAvgOffsetTotal: %f", magRegenAvgOffsetTotal))
    debugMsg(string.format("magRegenRelativeOffsetTotal: %f", magRegenRelativeOffsetTotal))
    debugMsg(string.format("magRegenRelativeToAvg: %f", magRegenRelativeToAvg))
    debugMsg(string.format("savedData.startRegenPoints: %f", savedData.startRegenPoints))

    -- If the player installed this mod mid-game, we need to make an additional adjustment here.
    if not newGame then
        debugMsg("This is not a new game. Recalculating totalMagicSkills based on current skills.")

        -- The saved total of magic skills is currently based on average initial values (which was needed for the
        -- earlier calculations), but we need to determine the actual total so the regen calculations later will be
        -- (close to) right.
        savedData.totalMagicSkills = 0

        -- Add up all of the player's current magic skills.
        for _, skillId in ipairs(magicSkillList) do
            savedData.totalMagicSkills = savedData.totalMagicSkills + tes3.mobilePlayer.skills[skillId + 1].base
            debugMsg(string.format("savedData.totalMagicSkills so far: %f", savedData.totalMagicSkills))
        end

        tes3.messageBox("You have installed CCCP Magicka Regen mid-playthrough.\n\nThis is not ideal, and will result in the mod not working as intended.\n\nTo experience CCCP Magicka Regen as intended, it is highly recommended to start a new game.")
    end

    debugMsg(string.format("savedData: %s", json.encode(tes3.player.data.CCCPMagickaRegen, { indent = true })))

    -- Start the timer for magicka regen ticks.
    initMagRegenTimer()
end

-- Called every frame until chargen is complete.
local function onSimulate()
    -- Checks the CharGenState global variable, which is set to 10 at the beginning of chargen and to -1 after chargen
    -- is complete. In other words, wait until chargen finishes, then run the rest of the function.
    if tes3.findGlobal("CharGenState").value ~= -1 then
        return
    end

    debugMsg("Chargen has been completed. Performing initial calculations.")

    -- Once chargen is finally complete, we unregister the event that calls this function so it won't keep running every
    -- frame, then run all the initial calculations.
    simulateActive = false
    event.unregister("simulate", onSimulate)
    initialCalculations(true)
end

-- Called each time the game is loaded, whether a savegame or a new game.
local function onLoaded(e)
    -- The player has started a new game, which means we need to register the simulate event during chargen (so we can
    -- detect when chargen ends).
    if e.newGame then
        -- These lines are debug messages that will be printed to MWSE.log if the mod is configured to do so.
        debugMsg("A new game has been started.")

        -- The simulate event occurs every frame, except when the menu is open.
        simulateActive = true
        event.register("simulate", onSimulate)

    -- The player has loaded a savegame.
    else
        debugMsg("A savegame has been loaded.")

        -- Assign our persistent player data to a local variable for easy access.
        savedData = tes3.player.data.CCCPMagickaRegen

        -- This means the player is installing this mod mid-game with a save that did not previously use this mod.
        if savedData == nil then
            debugMsg("This savegame did not previously use CCCP Magicka Regen. Performing initial calculations.")

            -- We need to run our initial calculations, assuming average values for initial skills since this is not a
            -- new game (and MWSE has no way to determine initial skill values after the fact).
            initialCalculations(false)

        -- The player has loaded a savegame that was previously using this mod. This is what will normally happen when
        -- the player loads their save.
        else
            debugMsg("This savegame uses CCCP Magicka Regen.")
            -- Start the timer for magicka regen ticks.
            initMagRegenTimer()
        end
    end
end

-- Called just before each game load, whether a savegame or new game.
local function onLoad()
    --[[ Unregister the simulate event if it's currently registered. Otherwise, the player could start a new game and
    then, during chargen, load a savegame. This would result in the onSimulate function running after the savegame is
    loaded. Since chargen is complete in the savegame, the mod would re-run its initial calculations using the
    savegame's current skill values, which would screw up the mod's saved values for that save.

    In other words, it's very important that the onSimulate function only runs during chargen. This ensures that's the
    case. ]]--
    if simulateActive then
        simulateActive = false
        event.unregister("simulate", onSimulate)
    end
end

-- Runs when the mod is initialized, basically as soon as Morrowind is started.
local function onInitialized()
    local buildDate = mwse.buildDate
    local tooOld = string.format("[%s %s] MWSE is too out of date. Update MWSE to use this mod.", modInfo.mod, modInfo.version)

    if not buildDate
    or buildDate < 20210518 then
        tes3.messageBox(tooOld)
        mwse.log(tooOld)
        return
    end

    -- This variable is used to keep track of whether the simulate event is registered. It's important to make sure
    -- onSimulate only runs when it's supposed to. Otherwise, bad things would happen.
    simulateActive = false

    -- The load event occurs just before a savegame or new game is loaded, while the loaded event occurs just after the
    -- game is loaded.
    event.register("load", onLoad)
    event.register("loaded", onLoaded)

    --[[ The skillRaised event occurs when a skill is increased by use, training or reading a skillbook (i.e. when
    Morrowind plays the skillup sound). In the vanilla game, scripted skill increases, such as those from certain quest
    rewards, don't count. However, there is a mod called Quest Skill Reward Fix that triggers the skillRaised event for
    scripted skill increases. Using that mod is highly recommended. ]]--
    event.register("skillRaised", onSkillRaised)

    mwse.log(string.format("[%s %s] Initialized.", modInfo.mod, modInfo.version))
end

event.register("initialized", onInitialized)

-- Register the mod config menu.
local function onModConfigReady()
    dofile("CCCPMagickaRegen.mcm")
end

event.register("modConfigReady", onModConfigReady)