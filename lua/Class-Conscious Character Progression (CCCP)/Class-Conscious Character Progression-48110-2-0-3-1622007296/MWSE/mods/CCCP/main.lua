local mod = "Class-Conscious Character Progression"
local version = "2.0.2"

local config = require("CCCP.config")
local data = require("CCCP.data")

local savedData, gainsMessages, simulateActive, enterFrameActive, currentEndurance, currentIntelligence, currentMagickaMultiplier

local statMenuId = tes3ui.registerID("MenuStat")
local hudMenuId = tes3ui.registerID("MenuMulti")
local magickaBarId = tes3ui.registerID("MenuStat_magic_fillbar")

local fortifyMAX = include("FortifyMAX.interop")
local fortifyMAXMagickaEnabled = false
local fortifyMAXSpellTickEnabled = false

-- Print all those debug messages in the log, if the mod is configured to do so.
local function debugMsg(message)
    if config.debugMode then
        mwse.log(string.format("[CCCP %s DEBUG] %s", version, message))
    end
end


-- Runs each time the player hovers over the level display in the stat menu, but only if the MCP feature expanding this
-- tooltip is active.
local function levelUpProgressTooltip(e)

    -- Allows the vanilla tooltip to be created. Otherwise we can't modify it, because it doesn't exist.
    e.source:forwardEvent(e)

    -- This will be true during chargen, when our persistent data has not been saved yet.
    if savedData == nil then
        return
    end

    debugMsg("Modifying tooltip.")

    -- Find the block that contains the attribute list. Doing it this way is necessary because none of these elements
    -- have names, so can't be referenced directly.
    local tooltip = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
    local layout = tooltip.children[1].children[1]
    local children = layout.children
    children[2].borderBottom = 6

    -- The actual attribute list starts at the third child of the layout element. So, starting from there, hide each
    -- attribute in the list. This hides the vanilla elements; we'll be re-creating them with our own text.
    for i = 3, #children do
        children[i].visible = false
    end

    -- Go through each of the attributes, one at a time, in the proper order.
    for i = 1, #tes3.mobilePlayer.attributes do

        -- Create the element for this attribute's display and set its properties to equal the vanilla attribute
        -- display. widthProportional 1.0 gives it the entire width of the tooltip to work with. childAlignX 0.5 centers
        -- it in its available space.
        local attributeBlock = layout:createBlock({})
        attributeBlock.flowDirection = "left_to_right"
        attributeBlock.autoHeight = true
        attributeBlock.autoWidth = true
        attributeBlock.widthProportional = 1.0
        attributeBlock.childAlignX = 0.5

        -- MWSE attribute IDs are 0-7 instead of 1-8, so compensate for this off by one issue.
        local attributeId = i - 1

        -- Needed to retrieve values from our player data, which uses strings as table keys.
        local attributeString = tostring(attributeId)

        local displayThreshold, displayProgress
        local displayText = tes3.attributeName[attributeId]

        -- tes3.attributeName returns an all lowercase string. This finds the first lowercase character in the string
        -- and converts it to uppercase.
        displayText = string.gsub(displayText, "%l", string.upper, 1)

        -- The luck progress threshold is (basically) 1.0 in the code, so the luck display is handled differently so
        -- luck will display in a manner consistent with other attributes.
        if attributeId == tes3.attribute.luck then

            -- The displayed increase threshold for luck is equal to the average threshold of the other attributes.
            displayThreshold = math.ceil( config.attributeIncreaseRate / 0.8 )

            -- Luck progress is a fractional value from 0 to 1, so just multiply it by the displayed threshold.
            displayProgress = math.floor( displayThreshold * savedData.attributeProgress[attributeString] )

            --[[ The actual luck threshold in the code is very slightly less than 1 (otherwise, the first luck increase
            would require one more attribute increase than intended due to the fact that float values aren't 100%
            accurate). Since it's decreased by exactly 1 when luck increases, a consequence is that, immediately after a
            luck increase, luck progress can be very slightly less than 0, which would make the displayed progress here
            -1. This would confuse the player, so just make it say 0 in this case. ]]--
            displayProgress = math.max(displayProgress, 0)

        -- For attributes other than luck, it's much more straightforward. We round the threshold up and round progress
        -- down to ensure the two numbers are never the same in the tooltip (which would be confusing to the player).
        else
            displayThreshold = math.ceil(savedData.increaseThresholds[attributeString])
            displayProgress = math.floor(savedData.attributeProgress[attributeString])
        end

        -- Adjust the display text to show the progress and threshold, and create the actual tooltip text to display for
        -- this attribute. The result will be something like "Strength: 80/125".
        displayText = displayText .. string.format(": %d/%d", displayProgress, displayThreshold)
        attributeBlock:createLabel({ text = displayText })
    end
end

-- Runs when the stat menu is created.
local function onMenuStatActivated(e)

    -- Checks to see if MCP's "levelup skills tooltip" feature is enabled. If not, there's nothing to change.
    if not tes3.hasCodePatchFeature(tes3.codePatchFeature.levelupSkillsTooltip) then
        return
    end

    debugMsg("Registering tooltip event for levelUpProgress tooltip.")
    local menu = e.element

    -- layoutElem is the level block in the stat menu. levelElem is the actual level display (1, 2, and so on).
    local layoutElem = menu:findChild(tes3ui.registerID("MenuStat_level_layout"))
    local levelElem = layoutElem:findChild(tes3ui.registerID("MenuStat_level"))

    -- Registers our tooltip function to occur when the player hovers the mouse over the level display.
    levelElem:register("help", levelUpProgressTooltip)

    -- Find the actual element for the "Level" label and register the event to change its tooltip as well. This for loop
    -- is necessary because the specific element in question doesn't have a name, so we have to iterate through all the
    -- children of its parent element to find it.
    for _, child in pairs(layoutElem.children) do
        if child.text == "Level" then
            child:register("help", levelUpProgressTooltip)
            break
        end
    end
end

-- Sometimes when max magicka is changed the game won't actually update the display unless we force it to.
local function updateMenu(menu)
    if menu then
        local magMax = tes3.mobilePlayer.magicka.baseRaw
        local magCurrent = tes3.mobilePlayer.magicka.currentRaw

        local bar = menu:findChild(magickaBarId)

        if bar then
            bar.widget.current = magCurrent
            bar.widget.max = magMax

            bar:updateLayout()
            menu:updateLayout()
        end
    end
end

local function updateDisplay()
    local statMenu = tes3ui.findMenu(statMenuId)
    local hudMenu = tes3ui.findMenu(hudMenuId)

    updateMenu(statMenu)
    updateMenu(hudMenu)
end

-- Called each time the player's level increases.
local function setLevel(lvl)

    -- Actually change the player's level.
    mwscript.setLevel{
        reference = tes3.player,
        level = lvl,
    }

    -- Find the element of the stat menu that displays the player's level, and change the text of that element.
    -- Otherwise Morrowind won't update the display.
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    local elem = menu:findChild(tes3ui.registerID("MenuStat_level"))
    elem.text = tostring(lvl)
    menu:updateLayout()
end

--[[ Runs three times each time the player opens the training service menu, once for each skill. Instead of requiring
multiple training sessions to increase a skill affected by slowdown (as GCD did), we just make it cost more instead. The
result is the same.

This function works pretty much exactly like onExerciseSkill does, with identical calculations. The only difference is
that the training price is multiplied by the final slowdown rate (2, 3, 4, etc.) here, while in onExerciseSkill the
amount of progress is divided by the same number. ]]--
local function onCalcTrainingPrice(e)
    debugMsg("Calculating training price.")

    if config.slowdownRate <= 0 then
        debugMsg("Slowdown rate is 0. Not adjusting price.")
        return
    end

    local skillId = e.skillId
    local skillString = tostring(skillId)
    local mobileSkill = skillId + 1
    local currentSkill = tes3.mobilePlayer.skills[mobileSkill].base
    local difference = currentSkill - savedData.slowdownPoint[skillString]
    debugMsg(string.format("%s: %f", tes3.skillName[skillId], currentSkill))
    debugMsg(string.format("slowdownPoint: %f", savedData.slowdownPoint[skillString]))
    debugMsg(string.format("difference: %f", difference))

    if difference < 0 then
        debugMsg("Skill is less than slowdown point. Not adjusting price.")
        return
    end

    local exponent = difference + 1
    local rate = 1 + ( 0.001 * config.slowdownRate )
    local multiplier = math.ceil( rate ^ exponent )
    debugMsg(string.format("exponent: %f", exponent))
    debugMsg(string.format("rate: %f", rate))
    debugMsg(string.format("multiplier: %f", multiplier))

    debugMsg(string.format("Old price: %f", e.price))
    e.price = e.price * multiplier
    debugMsg(string.format("New price: %f", e.price))
end

-- Runs each time any skill is used. In the case of Athletics, this can be every frame as long as the player is running
-- or swimming, which is why there are no debug statements in this function.
local function onExerciseSkill(e)

    -- This is only true during chargen. Skill gains before chargen is complete would skew the mod's initial
    -- calculations, so we just disable them here.
    if simulateActive then
        e.progress = 0
        return
    end

    -- If the player sets the slowdown rate to 0, there will be no slowdown regardless, so no point in doing the
    -- calculations.
    if config.slowdownRate <= 0 then
        return
    end

    local skillId = e.skill

    -- Skill IDs in the slowdownPoint table are saved as strings.
    local skillString = tostring(skillId)

    -- Skill IDs on mobile actors are off by 1 compared to those used by MWSE.
    local mobileSkill = skillId + 1
    local currentSkill = tes3.mobilePlayer.skills[mobileSkill].base

    -- How much above or below the slowdown point the skill currently is.
    local difference = currentSkill - savedData.slowdownPoint[skillString]

    -- The skill has not yet reached the slowdown point, so no slowdown.
    if difference < 0 then
        return
    end

    -- Slowdown starts when the skill is equal to the slowdown point (and the difference is 0).
    local exponent = difference + 1

    -- The slowdown rate is presented in the MCM as a slider from 0-100 for simplicity, but the actual slowdown rate
    -- ranges from 1.0-1.1 (actually the lowest is 1.001, since if it's 1.0 we won't get to this point anyway). This is
    -- the base of the equation.
    local rate = 1 + ( 0.001 * config.slowdownRate )

    --[[ The slowdown rate (starting at 1.035 with default settings) increases at an exponential rate as the skill
    increases. It's multiplied by itself each time the skill increases beyond the slowdown point.

    The result is rounded up, which means progress always ends up being divided by an integer. As soon as the skill
    reaches the slowdown point, the skill will start progressing at 1/2 the normal rate. After a certain point, it will
    slow down further to 1/3 the normal rate, then 1/4, then 1/5, and so on, and this progressive slowdown will happen
    faster and faster at an exponential rate over time. Eventually progression will become so slow that making
    significant additional gains becomes prohibitively time-consuming. ]]--
    local divisor = math.ceil( rate ^ exponent )
    local multiplier = 1 / divisor

    e.progress = e.progress * multiplier
end

local function setCurAtr(atr, value)
    tes3.setStatistic{
        reference = tes3.player,
        attribute = atr,
        current = value,
    }
end

-- Cycles through all magic effects on the player and adds up the total magnitude of a particular effect with a
-- particular attribute, with a source that's a permanent ability.
local function getPermAtrEffectMag(effect, atr)
    local mag = 0
    local activeEffect = tes3.mobilePlayer.activeMagicEffects

    for _ = 1, tes3.mobilePlayer.activeMagicEffectCount do
        activeEffect = activeEffect.next

        if activeEffect.effectId == effect
        and activeEffect.attributeId == atr then
            local instance = activeEffect.instance

            if instance.sourceType == tes3.magicSourceType.spell
            and instance.source.castType == tes3.spellType.ability then
                mag = mag + activeEffect.magnitude
            end
        end
    end

    return mag
end

-- Returns the magnitude of a specific effect with a specific attribute.
local function getAtrEffectMag(effect, atr)
    return tes3.getEffectMagnitude{
        reference = tes3.player,
        effect = effect,
        attribute = atr,
    }
end

-- Called on each magicka regen tick to mod current magicka amount.
local function changeCurrentMagicka(addedAmount)
    tes3.modStatistic{
        reference = tes3.player,
        name = "magicka",
        current = addedAmount,
    }
end

-- Called during initial calculations and on every magicka regen tick to check whether or not the player is affected by
-- Stunted Magicka.
local function getStunted()
    return tes3.isAffectedBy{
        reference = tes3.player,
        effect = tes3.effect.stuntedMagicka,
    }
end

-- Runs every 0.1 seconds after chargen is complete, except when the menu is open. There are no debugMsg lines in this
-- function because it runs so frequently.
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

-- Runs after initial calculations, on game load, each time a magic skill is raised, and each time intelligence (or
-- magicka multiplier) changes.
local function setMagicka(fromGameLoaded)

    -- Set to the new values for later comparisons in onEnterFrame. Using .currentRaw instead of .current here to allow
    -- for negative values when comparing (.current always returns >= 0, while .currentRaw can be negative).
    currentIntelligence = tes3.mobilePlayer.intelligence.currentRaw
    currentMagickaMultiplier = tes3.mobilePlayer.magickaMultiplier.current

    -- Player has disabled max magicka handling, so don't actually change magicka (the game's vanilla values will take
    -- over, at least the next time intelligence changes).
    if not config.maxMagickaHandling then
        debugMsg("Max magicka handling is disabled. Skipping magicka calculations.")
        return
    end

    -- We don't want to actually use a negative value in these calculations, so get .current as well.
    local currentIntelligenceNonNeg = tes3.mobilePlayer.intelligence.current

    debugMsg(string.format("Performing magicka calculations. currentIntelligenceNonNeg: %f", currentIntelligenceNonNeg))
    debugMsg(string.format("currentMagickaMultiplier: %f", currentMagickaMultiplier))

    -- This is the second main component of our max magicka calculations (the first was determined in our initial
    -- calculations). It takes into account the player's current magic skill total, modified by the configurable
    -- magMaxProgress variable.
    local progress = ( savedData.totalMagicSkills * 0.1 * config.magMaxProgress ) + 1000

    -- Preliminary magicka total, with the unaffected portion of the magicka pool tacked on as a bonus.
    local total = ( savedData.startingEffect * progress ) + savedData.unaffectedMagicka

    debugMsg(string.format("savedData.startingEffect: %f", savedData.startingEffect))
    debugMsg(string.format("progress: %f", progress))
    debugMsg(string.format("total: %f", total))

    -- Modify our preliminary total by the ratio of current to initial intelligence. So as intelligence increases, max
    -- magicka will increase proportionally, as in the vanilla game.
    local relativeIntelligence = currentIntelligenceNonNeg / savedData.initialIntelligence
    total = total * relativeIntelligence

    -- The total is further modified by the overall max magicka multiplier.
    local newMaxMagicka = total * 0.01 * config.magMaxMultiplier

    debugMsg(string.format("relativeIntelligence: %f", relativeIntelligence))
    debugMsg(string.format("total: %f", total))
    debugMsg(string.format("newMaxMagicka: %f", newMaxMagicka))

    --[[ The "normalized" magicka multiplier is the ratio between the current and base magicka multiplier. The base
    magicka multiplier never changes throughout the game, and the current magicka multiplier only changes when the
    Fortify Maximum Magicka magnitude changes (which in the vanilla game only happens when the player equips/unequips
    the Mantle of Woe). The normalized magicka multiplier is therefore almost always 1.0.

    To give an example, let's say the player is a Breton with The Mage birthsign, for a total magicka multiplier of 2.0.
    Base magicka multiplier will remain 2.0 throughout the game, and current magicka multiplier will also be 2.0 except
    when the Mantle of Woe is equipped, for a normalized magicka multiplier of 1.0. When the player equips the Mantle of
    Woe, their current magicka multiplier increases from 2.0 to 7.0, leading to a normalized magicka multiplier of 7/2,
    or 3.5. This means that their max magicka will be 3.5 times the normal value as long as they have the Mantle of Woe
    equipped.

    This result is the same as it would be in the vanilla game, except that the amount of magicka being multiplied is
    potentially much greater than it would be in vanilla for magic-focused characters. ]]--
    local adjustMaxMagicka = tes3.mobilePlayer.magickaMultiplier.normalized
    newMaxMagicka = newMaxMagicka * adjustMaxMagicka
    debugMsg(string.format("adjustMaxMagicka: %f", adjustMaxMagicka))
    debugMsg(string.format("newMaxMagicka: %f", newMaxMagicka))

    -- Determine the magnitude of Fortify Magicka (not Fortify Maximum Magicka) the player is under. We'll need to
    -- compensate for this later.
    local fortifyMagickaMagnitude = tes3.getEffectMagnitude{
        reference = tes3.player,
        effect = tes3.effect.fortifyMagicka,
    }

    --[[ The "normalized" magicka is the ratio between current and max magicka. Set the new current magicka to maintain
    the old ratio. (Note that by the time this function runs, if it's done as a result of an intelligence change,
    Morrowind has already made its own vanilla changes to magicka, resulting very briefly in vanilla current/max magicka
    amounts. This will be important below, but Morrowind will maintain the same ratio as before, so we can just grab the
    current ratio here without jumping through the hoops we have to later.) ]]--
    local newCurrentMagicka = newMaxMagicka * tes3.mobilePlayer.magicka.normalized
    debugMsg(string.format("fortifyMagickaMagnitude: %f", fortifyMagickaMagnitude))
    debugMsg(string.format("newCurrentMagicka: %f", newCurrentMagicka))

    -- If the player is under a Fortify Magicka effect, we need to compensate for that. This is because Fortify Magicka
    -- increases the ratio between current and max magicka. The problem is basically the same as with Fortify Health in
    -- the health calculations, except there's no related MCP feature so it's simpler.
    if fortifyMagickaMagnitude > 0 then

        -- However, if the player is using the magicka component of Fortify MAX, we don't want to do this here, because
        -- Fortify MAX will handle it.
        if fortifyMAXMagickaEnabled then
            debugMsg("There is a Fortify Magicka magnitude, but the player is using Fortify MAX. Skipping Fortify Magicka calculations.")
        else

            --[[ There is a problem, however. By the time this function runs, Morrowind has already made its vanilla
            changes to magicka. We need to know what the previous magicka value was, but we can't just grab it from
            mobilePlayer because it's already been changed. Therefore, we need to save this value in our persistent
            player data, which we do at the bottom of this function. This necessitates a nil check in case this is the
            very first time this function has been run for this character, but that's very unlikely. It could happen if
            the player disabled max magicka handling, started a new game, then enabled max magicka handling for the
            first time while under a Fortify Magicka effect. ]]--
            if savedData.lastMaxMagicka then

                -- We know what the player's last max magicka was, but we also need to know what their current magicka
                -- was just before the change. We determine this by multiplying the last max magicka by the magicka
                -- ratio (which is still correct even after vanilla Morrowind makes its changes).
                local lastCurrentMagicka = savedData.lastMaxMagicka * tes3.mobilePlayer.magicka.normalized

                -- What the player's (present/last) current magicka would be if not for Fortify Magicka.
                local currentMagickaWouldBe = lastCurrentMagicka - fortifyMagickaMagnitude

                -- This is what the magicka ratio would be if not for Fortify Magicka. This is the ratio we'll be
                -- maintaining.
                local ratioWouldBe = currentMagickaWouldBe / savedData.lastMaxMagicka

                -- What current magicka needs to be after Fortify Magicka wears off in order to maintain the above
                -- ratio.
                local currentMagickaWillBe = newMaxMagicka * ratioWouldBe

                -- Add back the Fortify Magicka magnitude, to ensure the ratio is correct after it wears off.
                newCurrentMagicka = currentMagickaWillBe + fortifyMagickaMagnitude

                debugMsg(string.format("savedData.lastMaxMagicka: %f", savedData.lastMaxMagicka))
                debugMsg(string.format("lastCurrentMagicka: %f", lastCurrentMagicka))
                debugMsg(string.format("currentMagickaWouldBe: %f", currentMagickaWouldBe))
                debugMsg(string.format("ratioWouldBe: %f", ratioWouldBe))
                debugMsg(string.format("currentMagickaWillBe: %f", currentMagickaWillBe))
                debugMsg(string.format("newCurrentMagicka: %f", newCurrentMagicka))
            end
        end
    end

    -- Actually changes max and current magicka to the values calculated above.
    tes3.setStatistic{
        reference = tes3.player,
        name = "magicka",
        base = newMaxMagicka,
    }

    tes3.setStatistic{
        reference = tes3.player,
        name = "magicka",
        current = newCurrentMagicka,
    }

    -- Force the game to update the magicka bars.
    updateDisplay()

    -- Save the new max magicka value in player data, so we can refer to it next time if needed.
    savedData.lastMaxMagicka = newMaxMagicka

    -- If the player is using the magicka component of Fortify MAX, we need to tell that mod to do its calculations to
    -- account for any Fortify Magicka magnitude. But we don't want to do that when this function is called from
    -- onLoaded, because Fortify MAX already does its calculations on game load anyway.
    if fortifyMAXMagickaEnabled
    and not fromGameLoaded then
        fortifyMAX.recalc.magicka = true
        debugMsg("Fortify MAX magicka component enabled. Setting fortifyMAX.recalc.magicka to true.")
    end
end

-- Runs after initial calculations, on game load, each time a skill is raised, and each time endurance changes.
local function setHealth()

    -- Set to the new value for later comparisons in onEnterFrame. No need to use .currentRaw here; we don't need to be
    -- able to detect the change from one negative endurance value to another, since the game isn't doing any health
    -- calculations in this case that we need to fix (unlike with magicka).
    currentEndurance = tes3.mobilePlayer.endurance.current
    debugMsg(string.format("Performing health calculations. currentEndurance: %f", currentEndurance))

    -- Adjust current in use and background points (which might have just changed due to a skillup) using the
    -- configurable multipliers and add them for total health points.
    local weightedPointsInUse = savedData.inUsePoints * 0.01 * config.healthInUseMult
    local weightedPointsBack = savedData.backgroundPoints * 0.01 * config.healthBackgroundMult
    local currentHealthPoints = weightedPointsInUse + weightedPointsBack

    -- The health constant was determined during initial calculations. Health is determined by health points, the health
    -- constant, and current endurance.
    local baseHealth = savedData.healthConstant * currentHealthPoints * currentEndurance

    -- Tack on the configurable health bonus. The health bonus serves as a minimum max health, even with an endurance of
    -- 0, so a bad endurance drain won't kill the player outright.
    local newMaxHealth = baseHealth + config.healthBonus

    -- Determine the magnitude of Fortify Health the player is under. This needs to be compensated for in our
    -- calculations.
    local fortifyHealthMagnitude = tes3.getEffectMagnitude{
        reference = tes3.player,
        effect = tes3.effect.fortifyHealth,
    }

    debugMsg(string.format("weightedPointsInUse: %f", weightedPointsInUse))
    debugMsg(string.format("weightedPointsBack: %f", weightedPointsBack))
    debugMsg(string.format("currentHealthPoints: %f", currentHealthPoints))
    debugMsg(string.format("baseHealth: %f", baseHealth))
    debugMsg(string.format("newMaxHealth: %f", newMaxHealth))
    debugMsg(string.format("fortifyHealthMagnitude: %f", fortifyHealthMagnitude))

    -- Checks to see if the player has the "fortify maximum health" MCP feature enabled. This feature causes Fortify
    -- Health to increase max health in addition to current health. If so, increase the new max health to compensate.
    -- (When Fortify Health wears off, max health will be lowered to the calculated value.)
    if tes3.hasCodePatchFeature(tes3.codePatchFeature.fortifyMaximumHealth) then
        newMaxHealth = newMaxHealth + fortifyHealthMagnitude
        debugMsg(string.format("newMaxHealth: %f", newMaxHealth))
    end

    -- The "normalized" health is the ratio between current and max health. Set the new current health to maintain the
    -- old ratio.
    local newCurrentHealth = newMaxHealth * tes3.mobilePlayer.health.normalized
    debugMsg(string.format("newCurrentHealth: %f", newCurrentHealth))

    --[[ If the player is under a Fortify Health effect, then we have some additional calculations to do. The problem is
    that Fortify Health changes the health ratio. This is true regardless of whether the player is using the MCP feature
    affecting Fortify Health, but more so if they're not. If we don't compensate for this, the current (skewed) ratio
    would be maintained when health changes, and when Fortify Health wears off, since the base max health is different
    than it was before, the ratio would also be different than it would have been with no Fortify Health.

    Here's an example. Let's say the player has a health of 60/120, a ratio of 50%. They're then affected by Fortify
    Health 50 points (and they *are* using the relevant MCP patch), which brings their health to 110/170, a ratio of
    about 64.7%.

    Now the player is affected by a Fortify Endurance effect, the health calculations are redone, and the new max health
    is determined to be 150 instead of 120. This will be further increased by 50 because of Fortify Health, bringing max
    health to 200 (when Fortify Health wears off, it will be lowered to the proper value of 150). Current health will be
    calculated to maintain the existing ratio of 64.7%, which means it will be set to about 129.4.

    This is all well and good so far. When Fortify Health wears off, max health will be lowered from 200 to 150 (the
    calculated value), while current health will be lowered from 129.4 to 79.4, in both cases being lowered by 50. The
    new health therefore will be 79.4/150, a ratio of about 52.9%, which is higher than the 50% ratio they had before.
    When the Fortify Endurance effect wears off and max health is lowered back down to 120, the 52.9% ratio will be
    maintained, leading to a health of about 63.5/120. In other words, the player got free healing.

    Something similar would happen if the player was subject to a Drain Endurance effect while under the effect of
    Fortify Health, except that in this case it would be detrimental to the player, not beneficial (the health ratio
    would end up being lower than before instead of higher).

    To compensate for this, we need to do a bit of mathematical gymnastics. ]]--
    if fortifyHealthMagnitude > 0 then

        -- What the player's (present) max health would be if not for the Fortify Health effect. This is identical to
        -- what it really is if the player is not using the MCP feature (if so, that will be compensated for later).
        local maxHealthWouldBe = tes3.mobilePlayer.health.base

        -- What the player's (present) current health would be if not for Fortify Health.
        local currentHealthWouldBe = tes3.mobilePlayer.health.current - fortifyHealthMagnitude

        -- And what the player's *new* max health would be without Fortify Health. Again this is identical to the
        -- calculated value if the player is not using the MCP feature.
        local maxHealthWillBe = newMaxHealth

        -- If the player is using the MCP feature, then Fortify Health affects max health as well, so adjust our
        -- calculated values for what max health (present and new) would be without it.
        if tes3.hasCodePatchFeature(tes3.codePatchFeature.fortifyMaximumHealth) then
            maxHealthWouldBe = maxHealthWouldBe - fortifyHealthMagnitude
            maxHealthWillBe = maxHealthWillBe - fortifyHealthMagnitude
        end

        -- Now that we know what our present current/max health would be if not for the Fortify Health effect, we can
        -- calculate what the health ratio would normally be. This is the ratio we'll be maintaining.
        local ratioWouldBe = currentHealthWouldBe / maxHealthWouldBe

        -- What the player's current health needs to be after Fortify Health wears off in order to maintain the above
        -- ratio.
        local currentHealthWillBe = maxHealthWillBe * ratioWouldBe

        -- Add back Fortify Health magnitude, to ensure the ratio is correct after it wears off.
        newCurrentHealth = currentHealthWillBe + fortifyHealthMagnitude

        debugMsg(string.format("maxHealthWouldBe: %f", maxHealthWouldBe))
        debugMsg(string.format("currentHealthWouldBe: %f", currentHealthWouldBe))
        debugMsg(string.format("maxHealthWillBe: %f", maxHealthWillBe))
        debugMsg(string.format("ratioWouldBe: %f", ratioWouldBe))
        debugMsg(string.format("currentHealthWillBe: %f", currentHealthWillBe))
        debugMsg(string.format("newCurrentHealth: %f", newCurrentHealth))
    end

    -- Actually change max and current health.
    tes3.setStatistic{
        reference = tes3.player,
        name = "health",
        base = newMaxHealth,
    }

    tes3.setStatistic{
        reference = tes3.player,
        name = "health",
        current = newCurrentHealth,
    }
end

-- Called in initialCalculations and onSkillRaised to check if a skill is on the magic skill list in data.lua.
local function checkMagicSkill(id)
    for _, tableId in ipairs(data.magicSkillList) do
        if id == tableId then
            debugMsg("This is a magic skill.")
            return true
        end
    end

    return false
end

-- Called on every skill increase by the onSkillRaised function.
local function incrementSkill(skill)
    local skillName = tes3.skillName[skill]

    -- Key values in our saved data tables are strings, not numbers.
    local skillString = tostring(skill)

    -- Go through each skill in our config table, looking for a match.
    for _, configSkill in ipairs(config.skillFactors) do
        local configSkillId = configSkill.skill

        -- A match is found, so do our calculations.
        if configSkillId == skill then
            local backgroundFactor = configSkill.healthBackFactor
            local inUseFactor = configSkill.healthInUseFactor
            local configSkillFactors = configSkill.factors

            -- Increment background and in use points depending on the health factors for this skill. (The in use factor
            -- is first modified by the saved "in use proportion" for the skill, which is determined by the initial
            -- skill value.)
            savedData.backgroundPoints = savedData.backgroundPoints + backgroundFactor
            savedData.inUsePoints = savedData.inUsePoints + ( inUseFactor * savedData.inUseProportion[skillString])

            debugMsg(string.format("savedData.increaseFactors[%s]: %f", skillName, savedData.increaseFactors[skillString]))
            debugMsg(string.format("backgroundFactor: %f", backgroundFactor))
            debugMsg(string.format("inUseFactor: %f", inUseFactor))
            debugMsg(string.format("savedData.backgroundPoints: %f", savedData.backgroundPoints))
            debugMsg(string.format("savedData.inUsePoints: %f", savedData.inUsePoints))

            -- Go through all the skill factors for the skill that's increasing.
            for _, currentFactor in ipairs(configSkillFactors) do
                local currentAttributeId = currentFactor.attribute
                local currentAttributeString = tostring(currentAttributeId)
                local currentAttributeName = tes3.attributeName[currentAttributeId]
                local factor = currentFactor.factor
                debugMsg(string.format("%s factor: %f", currentAttributeName, factor))

                -- We need to increase the progress for each attribute depending on the skill factors for the skill
                -- being raised and the skill's increase factor.
                local amountToAdd = factor * savedData.increaseFactors[skillString]

                -- Actually increase the attribute progress value for this attribute, if there's anything to add.
                if amountToAdd > 0 then
                    savedData.attributeProgress[currentAttributeString] = savedData.attributeProgress[currentAttributeString] + amountToAdd
                    debugMsg(string.format("savedData.attributeProgress[%s] has increased by %f to %f.", currentAttributeName, amountToAdd, savedData.attributeProgress[currentAttributeString]))
                end
            end

            -- No point in going through the rest of the skills in the config table.
            break
        end
    end

    -- Used to determine how much (if any) progress is earned toward a luck increase for this skillup. Starts at 0 every
    -- time because we're only interested in the number of attribute gains for this particular skillup.
    local attributesGained = 0

    -- Iterate through all eight attributes one at a time.
    for name, attributeId in pairs(tes3.attribute) do
        local attributeString = tostring(attributeId)

        -- Luck has to be handled last, after all the other attributes have been checked and possibly increased, (and
        -- attributesGained incremented correctly) so skip it for now.
        if attributeId ~= tes3.attribute.luck then

            --[[ Checks to see if the progress value for this attribute is now high enough for an attribute increase.
            Increase threshold varies by attribute (unless the player installed this mod mid-game). An if statement
            would normally be adequate here, but we're using while because there could in theory be more than one
            increase in the same attribute for one skillup, if the player makes insane changes in the MCM. ]]--
            while savedData.attributeProgress[attributeString] >= savedData.increaseThresholds[attributeString] do

                -- Reset attributeProgress for the next increase, and so we don't get stuck in an infinite loop here.
                savedData.attributeProgress[attributeString] = savedData.attributeProgress[attributeString] - savedData.increaseThresholds[attributeString]

                debugMsg(string.format("savedData.increaseThresholds[%s]: %f", name, savedData.increaseThresholds[attributeString]))
                debugMsg(string.format("savedData.attributeProgress[%s] has been lowered by %f to %f.", name, savedData.increaseThresholds[attributeString], savedData.attributeProgress[attributeString]))
                debugMsg(string.format("Increasing %s by 1.", name))

                -- Actually increase the attribute by 1.
                tes3.modStatistic{
                    reference = tes3.player,
                    attribute = attributeId,
                    value = 1,
                }

                -- Insert the notification message into the gainsMessages table (which is always blank when this
                -- function is called), to be displayed to the player later.
                table.insert(gainsMessages, string.format("Your %s has improved.", name))

                --Increment attributesGained to give progress to luck later.
                attributesGained = attributesGained + 1

                -- Increment levelUpProgress, which is checked later for a possible level increase.
                tes3.mobilePlayer.levelUpProgress = tes3.mobilePlayer.levelUpProgress + 1

                debugMsg(string.format("attributesGained: %f", attributesGained))
                debugMsg(string.format("levelUpProgress: %f", tes3.mobilePlayer.levelUpProgress))
            end
        end
    end

    --[[ Increase to luck progress depends on how many other attributes gained a point during this skillup. With a
    luckIncreaseRate of 100, the player would make 1/7 progress toward a luck point for each attribute increase, and
    luck would increase at the same rate as the average of the other attributes. luckIncreaseRate is 70 by default,
    which means luck will increase slower, at 70% of the rate of other attributes on average. ]]--
    local addToLuck = ( attributesGained * 0.01 * config.luckIncreaseRate ) / 7

    -- If any luck progress has been made, then do our luck calculations. (addToLuck is the amount of progress toward a
    -- luck increase, not the number of points to add to luck).
    if addToLuck > 0 then

        -- We could just say "7" below, but this makes it more clear.
        local luckString = tostring(tes3.attribute.luck)

        -- Increase luck progress by the amount calculated above.
        savedData.attributeProgress[luckString] = savedData.attributeProgress[luckString] + addToLuck
        debugMsg(string.format("savedData.attributeProgress[luck] has increased by %.20f to %.20f.", addToLuck, savedData.attributeProgress[luckString]))

        --[[ The actual luck increase threshold here is 0.999999 instead of 1.0 because the float values used here are
        not 100% accurate. After about 16 decimal places they start to deviate from the exact values. For the most part
        this doesn't matter (the deviation is so tiny that it would take forever for the rate of increase to be
        noticeably different from what it should be). But one result of this tiny deviation is that, when luck progress
        is supposed to be 1.0, it's actually very slightly less than 1. Which means if we used 1.0 as the threshold,
        luck would not actually increase until the next attribute increase afterward.

        This would actually only affect the very first luck increase of the game; this first luck increase would take
        one more attribute increase than intended if the threshold were exactly 1.0. Further increases would happen
        after the intended number of additional attribute increases, since luck progress is decreased by 1 each time.

        But to ensure that even the first luck increase happens when intended, the threshold is slightly less than 1.
        This will not skew the luck increase rate, even over a long time, because the progress value is still lowered by
        exactly 1 each time luck increases.

        This does have a consequence for MCP's levelups per attribute tooltip, but that's easily addressed. (Also note
        that, while the actual increase threshold for luck is (just about) 1.0, the MCP tooltip displays it differently,
        multiplying it by the average increase threshold for other attributes, so it's displayed like any other
        attribute.) ]]--
        while savedData.attributeProgress[luckString] > 0.999999 do

            -- Reset luck progress for the next luck increase.
            savedData.attributeProgress[luckString] = savedData.attributeProgress[luckString] - 1
            debugMsg(string.format("savedData.attributeProgress[luck] has been lowered by 1 to %.20f.", savedData.attributeProgress[luckString]))
            debugMsg("Increasing luck by 1.")

            -- Actually increase luck by 1.
            tes3.modStatistic{
                reference = tes3.player,
                attribute = tes3.attribute.luck,
                value = 1,
            }

            -- Insert the notification message to be displayed later.
            table.insert(gainsMessages, "Your luck has improved.")
        end
    end
end

-- The first function called each time a skill increases.
local function onSkillRaised(e)
    local skillId = e.skill
    local skillName = tes3.skillName[skillId]
    debugMsg(string.format("%s skill has been raised.", skillName))

    --[[ This GMST determines the levelup progress threshold displayed in the levelup progress tooltip. It was changed
    on game load, but it's necessary to update it on each skillup in case the player changed attributesToLevel between
    skillups. Otherwise, levelUpProgress might exceed iLevelupTotal without this mod triggering a levelup, which might
    trigger the vanilla levelup process (a bad thing). ]]--
    tes3.findGMST(tes3.gmst.iLevelupTotal).value = config.attributesToLevel

    -- Set this variable to an empty table at the beginning of the skillup process on each skillup. This is used to
    -- store the messages related to attribute and level increases the player will receive for this skillup, so they can
    -- be displayed in a single messagebox later.
    gainsMessages = {}

    -- Increases any attributes that need to be increased due to this skillup.
    incrementSkill(skillId)

    --[[ If any non-luck attributes were increased in the incrementSkill function, levelUpProgress was incremented, and
    we might need to give the player a levelup. (Using while rather than if because, in theory, there could be more than
    one levelup resulting from a single skillup, though this would only happen if the player sets insane values in the
    MCM.) ]]--
    while tes3.mobilePlayer.levelUpProgress >= config.attributesToLevel do
        debugMsg(string.format("levelUpProgress of %f is >= config.attributesToLevel of %f.", tes3.mobilePlayer.levelUpProgress, config.attributesToLevel))

        -- Reset levelUpProgress so it can begin counting toward the next levelup (and so we don't get stuck in an
        -- infinite loop here).
        tes3.mobilePlayer.levelUpProgress = tes3.mobilePlayer.levelUpProgress - config.attributesToLevel

        -- Actually changes the player's level and updates the level display.
        local nextLevel = (tes3.player.object.level + 1)
        debugMsg(string.format("Gaining level %f.", nextLevel))
        setLevel(nextLevel)

        -- Inserts the levelup message to be displayed later.
        table.insert(gainsMessages, "You have gained an additional level.")

        -- Plays the normal Morrowind levelup ditty.
        tes3.streamMusic{ path = "Special/MW_Triumph.mp3" }

        -- We also need to insert the levelup message, if the mod is configured to display them.
        if config.displayLevelMessages then

            -- If the table in the data file does not contain a levelup message for this level, the default message will
            -- be used.
            local levelMessage = data.levelUpMessages[nextLevel] or data.levelUpMessages.default

            -- Insert a newline at the beginning of the message. Since the code below will also insert a newline after
            -- the previous message, this means there will be a blank line before the levelup message, to help set it
            -- apart.
            levelMessage = "\n" .. levelMessage
            table.insert(gainsMessages, levelMessage)
        end
    end

    -- Now that the skill has been increased, and background and in use points have been incremented in incrementSkill,
    -- we need to run health calculations again.
    setHealth()

    -- Check to see if this is one of the eight magic skills. If so, increment the magic skills total and re-run max
    -- magicka calculations.
    if checkMagicSkill(skillId) then
        savedData.totalMagicSkills = savedData.totalMagicSkills + 1
        debugMsg(string.format("savedData.totalMagicSkills: %f", savedData.totalMagicSkills))

        setMagicka(false)
    end

    --[[ If any attribute increases resulted from this skillup, the associated messages (along with messages associated
    with any levelup) have been added to the gainsMessages table. The resultMessage variable will become the actual
    content of the messagebox shown to the player. Starts blank so nothing is displayed if there were no attribute or
    level increases this skillup. ]]--
    local resultMessage = ""

    -- Runs through all the messages stored in gainsMessages, one at a time.
    for i, message in ipairs(gainsMessages) do

        -- Adds each message to the messagebox.
        resultMessage = resultMessage .. message

        -- If the current message is *not* the last message to add, then add a newline so the next message will display
        -- on a different line within the same messagebox. Without this if condition, there would be a blank line at the
        -- bottom of the messagebox.
        if i ~= #gainsMessages then
            resultMessage = resultMessage .. "\n"
        end
    end

    --[[ Display the resulting messagebox containing messages for all the attribute gains the player earned for this
    skillup, along with any level increase. If there were no attribute gains, nothing will display.

    We display messages this way, all in a single messagebox, rather than one at a time on each individual attribute/
    level increase, because of Morrowind's limit of three messageboxes displayed at a time. There can easily be two non-
    luck attribute increases, plus a luck increase, plus a level increase, plus the levelup message text, for five
    messageboxes, plus the skillup messagebox that's still handled by Morrowind, for a total of six. (And in theory
    there can be many more, if the player sets unusual values in the MCM.) Without this method, the player would never
    see some of those messages. ]]--
    if resultMessage ~= "" then
        tes3.messageBox(resultMessage)
    end
end

-- Runs every frame for every effect on every actor.
local function onSpellTick(e)
    if e.target ~= tes3.player then
        return
    end

    local effect = e.effect
    local effectId = effect.id
    local effectAtr = effect.attribute

    -- When the player is under a Restore Intelligence effect and int reaches max (or is already at max), int will no
    -- longer change, but the game will continue to recalculate magicka every tick of the effect. Therefore, once int
    -- reaches max, we end the effect, to avoid magicka being reset to vanilla.
    if effectId == tes3.effect.restoreAttribute
    and effectAtr == tes3.attribute.intelligence then
        local curInt = tes3.mobilePlayer.intelligence.currentRaw
        local baseInt = tes3.mobilePlayer.intelligence.base

        -- We can't just use totalFortIntMag, because the player might have a permanent ability that fortifies int,
        -- which increases .base *and* contributes to totalFortIntMag, which means it would be taken into account twice
        -- and the limit would be wrong.
        local totalFortIntMag = getAtrEffectMag(tes3.effect.fortifyAttribute, tes3.attribute.intelligence)
        local permFortIntMag = getPermAtrEffectMag(tes3.effect.fortifyAttribute, tes3.attribute.intelligence)
        local fortIntMag = totalFortIntMag - permFortIntMag

        -- We're assuming the player is using the MCP bugfix patches related to Fortify/Drain/Restore Attribute. If not,
        -- this won't work properly when under a fortify effect.
        local limit = baseInt + fortIntMag

        if curInt >= limit then
            local drainIntMag = getAtrEffectMag(tes3.effect.drainAttribute, tes3.attribute.intelligence)

            --[[ When a Drain Intelligence effect ends, int will be increased by the drain magnitude, up to its maximum
            (the base value plus any Fortify Int magnitude). If int has already been restored up to max, it will not
            change when the drain effect ends, but the game will still recalculate magicka. So we need to ensure that
            int never gets restored up to max while under a drain effect (to ensure it changes when the effect ends, and
            therefore this mod will detect it and do its thing). Otherwise magicka could be reset to vanilla. ]]--
            if drainIntMag > 0 then
                local target = limit - 1

                -- Wait a frame to give the restore effect time to end and make sure int changes each tick of the
                -- effect.
                timer.delayOneFrame(function()
                    setCurAtr(tes3.attribute.intelligence, target)

                    local newInt = tes3.mobilePlayer.intelligence.currentRaw
                    debugMsg("Player is under a Drain Intelligence effect, and current intelligence has reached max. Setting current intelligence to 1 less than max.")
                    debugMsg(string.format("Drain Intelligence magnitude: %f", drainIntMag))
                    debugMsg(string.format("Target: %f", target))
                    debugMsg(string.format("New intelligence: %f", newInt))
                end)
            end

            debugMsg("Player is under a Restore Intelligence effect and current intelligence is at max. Ending effect.")
            debugMsg(string.format("Current intelligence: %f", curInt))
            debugMsg(string.format("Base intelligence: %f", baseInt))
            debugMsg(string.format("Total Fortify Intelligence magnitude: %f", totalFortIntMag))
            debugMsg(string.format("Permanent Fortify Intelligence magnitude: %f", permFortIntMag))
            debugMsg(string.format("Relevant Fortify Intelligence magnitude: %f", fortIntMag))
            debugMsg(string.format("Limit: %f", limit))

            -- Force the effect to end immediately.
            e.effectInstance.state = tes3.spellState.ending
        end

    -- When int is damaged to 0, further Damage Int ticks will not change int further, but the game will recalculate
    -- magicka anyway every tick. To prevent that we end the effect once int reaches 0.
    elseif effectId == tes3.effect.damageAttribute
    and effectAtr == tes3.attribute.intelligence then
        local curInt = tes3.mobilePlayer.intelligence.currentRaw

        if curInt <= 0 then
            debugMsg("Player is under a Damage Intelligence effect and current intelligence is 0. Ending effect.")
            debugMsg(string.format("Current intelligence: %f", curInt))

            e.effectInstance.state = tes3.spellState.ending
        end
    end
end

-- Called every frame, but only after chargen is complete.
local function onEnterFrame()

    -- No point in doing health or magicka calculations if the player is dead.
    if tes3.mobilePlayer.health.current <= 0 then
        return
    end

    -- Endurance has changed, so re-run health calculations.
    if tes3.mobilePlayer.endurance.current ~= currentEndurance then
        debugMsg("Endurance has changed. Setting health.")
        setHealth()
    end

    -- Either intelligence or magicka multiplier has changed, so re-run max magicka calculations. This is almost
    -- certainly an intelligence change. The only way the player can change their magicka multiplier in the vanilla game
    -- is by equipping/unequipping the Mantle of Woe, which has a Fortify Maximum Magicka enchantment.
    if tes3.mobilePlayer.intelligence.currentRaw ~= currentIntelligence
    or tes3.mobilePlayer.magickaMultiplier.current ~= currentMagickaMultiplier then
        debugMsg("Intelligence or magicka multiplier has changed. Setting magicka.")
        setMagicka(false)
    end
end

--[[ Called immediately after chargen is complete (or if the player installs this mod mid-game). This function runs only
once per character and is responsible for all initial calculations. This mod uses the player's initial skill and
attribute values to calculate many of the values that will be used throughout the mod, and these initial values can only
be determined at the beginning of the game (MWSE has no way to determine initial skill/attribute values after the fact).
If the player installs the mod mid-game, the calculations will assume the player's initial skills and attributes were
all average, and the result will be less than ideal. ]]--
local function initialCalculations(newGame)
    local initialSkills = {}
    local initialSkillSum = 0
    local racialAttributes = {}
    local racialAttributeSum = 0
    local skillPoints = {}
    local totalSkillFactors = 0
    local startingAttributes = {}
    local adjustedInUseTotal = 0
    local backgroundTotal = 0
    local inUseTotal = 0

    -- racialAttributeStart is the percentage of the player's starting attributes determined by racial attributes.
    -- What's left over is determined by the player's initial skills.
    local classAttributeStart = 1 - ( 0.01 * config.racialAttributeStart )

    -- Just modifies the configurable attribute increase rate for use in formulas below, so it can be presented in the
    -- MCM as an easy-to-understand percentage.
    local increaseRateConstant = 0.01 * config.attributeIncreaseRate * 0.008

    debugMsg(string.format("classAttributeStart: %f", classAttributeStart))
    debugMsg(string.format("increaseRateConstant: %f", increaseRateConstant))

    -- Creates a block of persistent data that's saved in the player's savegame. This is needed so certain values
    -- calculated here can persist between game sessions and be referred to (and in some cases modified) later. This
    -- block of data starts off as a blank table.
    tes3.player.data.CCCP = {}

    -- The local variable savedData is just an alias for our persistent block of data, making it easier to reference.
    savedData = tes3.player.data.CCCP
    savedData.increaseFactors = {}
    savedData.increaseThresholds = {}
    savedData.attributeProgress = {}
    savedData.inUseProportion = {}
    savedData.slowdownPoint = {}
    savedData.version = version
    savedData.backgroundPoints = 0
    savedData.totalMagicSkills = 0

    -- If newGame is true, then this function is being run after chargen, as intended.
    if newGame then
        debugMsg("This is a new game, so using actual skills and attributes.")

        -- Go through all 27 of the player's skills, one at a time.
        for i, skill in ipairs(tes3.mobilePlayer.skills) do

            -- Skill IDs in MWSE are 0-26, but the actual skills used by the game for mobile actors are indexed 1-27.
            local skillId = i - 1

            -- Obtain the player's current (initial) skill values. We also need to add up all the initial skills.
            initialSkills[skillId] = skill.base
            initialSkillSum = initialSkillSum + initialSkills[skillId]
            debugMsg(string.format("%s skill: %f", tes3.skillName[skillId], initialSkills[skillId]))
            debugMsg(string.format("initialSkillSum so far: %f", initialSkillSum))

            -- This checks to see if the current skill is one of the eight magic skills. We need to add up the total of
            -- the player's magic skills and save that data for later use.
            if checkMagicSkill(skillId) then
                savedData.totalMagicSkills = savedData.totalMagicSkills + initialSkills[skillId]
                debugMsg(string.format("savedData.totalMagicSkills so far: %f", savedData.totalMagicSkills))
            end
        end

        -- Go through all eight of the player's attributes, one at a time.
        for i, attribute in ipairs(tes3.mobilePlayer.attributes) do

            -- There's a similar off-by-one issue for attributes as there is for skills.
            local attributeId = i - 1

            -- These attribute values would be the player's normal starting attributes in vanilla Morrowind. These are
            -- the player's "racial" attributes, determined only by the player's race and favored attributes (and any
            -- birthsign bonus) and not influenced by skills.
            racialAttributes[attributeId] = attribute.base

            -- Add up all the player's starting attributes, like we did with skills. Luck is excluded because it's
            -- handled differently.
            if attributeId ~= tes3.attribute.luck then
                racialAttributeSum = racialAttributeSum + racialAttributes[attributeId]
            end

            debugMsg(string.format("%s attribute: %f", tes3.attributeName[attributeId], racialAttributes[attributeId]))
            debugMsg(string.format("racialAttributeSum (not including luck) so far: %f", racialAttributeSum))
        end

    --[[ newGame will be false only if the player starts using this mod during an existing playthrough rather than
    starting a new game. This is bad because the saved values (which the mod uses on every skillup) are based on the
    player's initial skill and attribute values, which MWSE has no way of determining after the fact. This is why
    starting a new game is strongly recommended with this mod.

    Installing the mod mid-game has a number of consequences. First, skill increase factors (which serve as multipliers
    to the progress made toward attribute increases on skillup) will all be set to an average value. This means that
    while each skill will have different amounts of influence on each attribute depending on the configurable skill
    factors, the skills will have basically the same amount of influence overall (unless funky changes are made to skill
    factors in the MCM).

    Second, attribute increase thresholds (which determine how much progress toward a gain is required for each
    attribute) will also be very similar (though not identical, since they also depend in part on the sum of skill
    factors for each attribute, which are not exactly the same by default). This means that while each attribute will
    have a different number of progress points added depending on the skill factors of the skill being raised, each
    attribute will basically be equally easy to increase overall (again, unless weird things are done to skill factors).

    Third, health, max magicka and magicka regen calculations will be made using average initial skill values. The final
    values will still vary by character, since the player's current skills are taken into account, but the result will
    likely be very different from what it would be if these calculations had been done after chargen as intended. The
    "in use proportion" (an estimate of how often a skill will be used, based on initial skill values) will also be
    identical for all skills, and will therefore have no bearing on how skills' in use factors are used to increase
    health later on.

    Fourth, the skill slowdown points for all skills will be identical, instead of skills being treated differently
    depending on whether the player specializes in them. ]]--
    else
        debugMsg("This is not a new game, so using typical average initial skills and attributes.")

        -- Set these sums to the average values for vanilla Morrowind. (If the player is using a mod that changes this,
        -- we have no way of knowing.) Note that the attribute sum does not include luck.
        initialSkillSum = 400
        racialAttributeSum = 290

        local averageSkill = initialSkillSum / 27
        local averageAttribute = racialAttributeSum / 7

        -- We don't know what the player's starting magic skill total was, so set it to an average.
        savedData.totalMagicSkills = averageSkill * 8

        debugMsg(string.format("initialSkillSum: %f", initialSkillSum))
        debugMsg(string.format("racialAttributeSum: %f", racialAttributeSum))
        debugMsg(string.format("savedData.totalMagicSkills: %f", savedData.totalMagicSkills))

        -- Pretend that the player's skills all started at the average value.
        for i, _ in ipairs(tes3.mobilePlayer.skills) do
            local skillId = i - 1
            initialSkills[skillId] = averageSkill
            debugMsg(string.format("%s skill: %f", tes3.skillName[skillId], initialSkills[skillId]))
        end

        -- Do the same with attributes.
        for i, _ in ipairs(tes3.mobilePlayer.attributes) do
            local attributeId = i - 1

            -- Luck typically starts at 40, so just use that value.
            if attributeId == tes3.attribute.luck then
                racialAttributes[attributeId] = 40
            else
                racialAttributes[attributeId] = averageAttribute
            end

            debugMsg(string.format("%s attribute: %f", tes3.attributeName[attributeId], racialAttributes[attributeId]))
        end
    end

    -- We need the player's average starting skill and attribute.
    local initialSkillAverage = initialSkillSum / 27
    local racialAttributeAverage = racialAttributeSum / 7

    -- And the average "offset" skills, one for increase factor calculations and one for health calculations.
    local averageOffsetSkill = initialSkillAverage + config.initialSkillOffset
    local avgInUseOffsetSkill = initialSkillAverage + config.healthInUseOffset

    debugMsg(string.format("initialSkillAverage: %f", initialSkillAverage))
    debugMsg(string.format("racialAttributeAverage: %f", racialAttributeAverage))
    debugMsg(string.format("averageOffsetSkill: %f", averageOffsetSkill))
    debugMsg(string.format("avgInUseOffsetSkill: %f", avgInUseOffsetSkill))

    -- Goes through the skill factors table in the config file, which is a table of tables containing all the factors
    -- for each skill.
    for _, configSkill in ipairs(config.skillFactors) do
        local configSkillId = configSkill.skill
        local skillName = tes3.skillName[configSkillId]

        -- configSkill.factors is the table containing skill factors within each skill table.
        local configSkillFactors = configSkill.factors

        --[[ configSkillId is the numeric skill ID 0-26. tostring turns it into a string, "0" - "26". This is needed
        when we'll be saving data for each skill in our persistent data. Numeric keys in tables will always be converted
        to strings when being saved in the player data, so we need to save them as strings in the first place so we can
        consistently retrieve their values. ]]--
        local skillString = tostring(configSkillId)

        -- Each skill has a unique background factor and in use factor used in health calculations.
        local backgroundFactor = configSkill.healthBackFactor
        local inUseFactor = configSkill.healthInUseFactor

        -- Calculate the value of each initial skill modified by a configurable offset.
        local offsetSkill = initialSkills[configSkillId] + config.initialSkillOffset

        --[[ Calculate an "increase factor" for each skill by comparing the initial value of the skill to the average of
        initial skills, all modified by the offset. A larger offset will result in increase factors closer to 1 (less
        difference between skills), while a smaller offset will result in increase factors farther away from 1 (more
        difference between skills).

        The increase factor serves as a multiplier to the progress made towards attribute gains when the relevant skill
        increases. These values are saved in our persistent data so we can refer to them later. ]]--
        savedData.increaseFactors[skillString] = offsetSkill / averageOffsetSkill

        debugMsg(string.format("Iterating through %s skill in config table.", skillName))
        debugMsg(string.format("offsetSkill[%s]: %f", skillName, offsetSkill))
        debugMsg(string.format("savedData.increaseFactors[%s]: %f", skillName, savedData.increaseFactors[skillString]))

        -- Add up the totals of all background and in use factors for all skills.
        backgroundTotal = backgroundTotal + backgroundFactor
        inUseTotal = inUseTotal + inUseFactor

        -- Background factors are modified by initial skill values then added up across all skills to determine the
        -- player's "background points," which is used in health calculations later.
        savedData.backgroundPoints = savedData.backgroundPoints + ( initialSkills[configSkillId] * backgroundFactor )

        --[[ adjustedInUseTotal is used to calculate the player's initial "in use points," which is also used in health
        calculations later. It contains the square of each initial skill value (modified by the in use offset), and will
        later be divided by the average initial skill modified by the same offset to determine in use points.

        This means initial skill values will have a very significant effect on in use points. If the player starts the
        game with high values for the skills with high in use factors, they will have a much higher total in use points
        than they would otherwise, and therefore will have higher starting health. ]]--
        local skillWeighting = initialSkills[configSkillId] + config.healthInUseOffset
        local weightedInUse = skillWeighting * inUseFactor
        adjustedInUseTotal = adjustedInUseTotal + ( initialSkills[configSkillId] * weightedInUse )

        -- The in use proportion for a skill is that skill's relative starting value compared to the average, modified
        -- by the in use offset. This basically serves as an estimate for how often the skill will be "in use" by the
        -- player, and will modify in use factors when calculating health later.
        savedData.inUseProportion[skillString] = skillWeighting / avgInUseOffsetSkill

        debugMsg(string.format("backgroundTotal so far: %f", backgroundTotal))
        debugMsg(string.format("InUseTotal so far: %f", inUseTotal))
        debugMsg(string.format("savedData.backgroundPoints so far: %f", savedData.backgroundPoints))
        debugMsg(string.format("skillWeighting[%s]: %f", skillName, skillWeighting))
        debugMsg(string.format("weightedInUse[%s]: %f", skillName, weightedInUse))
        debugMsg(string.format("adjustedInUseTotal so far: %f", adjustedInUseTotal))
        debugMsg(string.format("savedData.inUseProportion[%s]: %f", skillName, savedData.inUseProportion[skillString]))

        -- Calculate the skill slowdown point for each skill (the point where skill progression starts to slow down) by
        -- adding a percentage of the initial skill value to the base slowdown point.
        local slowdownExtra = initialSkills[configSkillId] * 0.01 * config.slowdownSpread
        savedData.slowdownPoint[skillString] = config.slowdownStart + slowdownExtra
        debugMsg(string.format("slowdownExtra[%s]: %f", skillName, slowdownExtra))
        debugMsg(string.format("savedData.slowdownPoint[%s]: %f", skillName, savedData.slowdownPoint[skillString]))

        -- Go through each skill factor for the current skill, one at a time.
        for _, currentFactor in ipairs(configSkillFactors) do
            local currentAttributeId = currentFactor.attribute
            local currentAttributeName = tes3.attributeName[currentAttributeId]
            local factor = currentFactor.factor

            -- We need to calculate the total of all (7 * 27 = 189) skill factors for a later calculation.
            totalSkillFactors = totalSkillFactors + factor

            debugMsg(string.format("%s factor for %s: %f", currentAttributeName, skillName, factor))
            debugMsg(string.format("totalSkillFactors so far: %f", totalSkillFactors))

            -- The first time this inner for loop runs, the skillPoints table will be blank, so set the starting value
            -- for each attribute to 0.
            if skillPoints[currentAttributeId] == nil then
                skillPoints[currentAttributeId] = 0
            end

            -- We also need to know the total "skill points" for each attribute, determined by initial skill values and
            -- those skills' factors for each attribute. These contribute to determining the player's actual initial
            -- attributes and how quickly each attribute increases.
            skillPoints[currentAttributeId] = skillPoints[currentAttributeId] + ( initialSkills[configSkillId] * factor )
            debugMsg(string.format("skillPoints[%s] so far: %f", currentAttributeName, skillPoints[currentAttributeId]))
        end
    end

    -- The points expectation is how many "skill points" an attribute would have if all skills that influence it were
    -- totally average (average initial value and average total of factors).
    local totalPointsExpectation = totalSkillFactors * initialSkillAverage
    local pointsExpectation = totalPointsExpectation / 7
    debugMsg(string.format("totalPointsExpectation: %f", totalPointsExpectation))
    debugMsg(string.format("pointsExpectation: %f", pointsExpectation))

    -- How many background points the player would be expected to have if all initial skills were average. (Actual
    -- background points will vary depending on which skills start high.)
    local expectationBack = backgroundTotal * initialSkillAverage

    -- Calculate how many in use points an average player can be expected to have, compensating for the fact that
    -- typical players will have more than the "average" value because armor skills have high in use factors and
    -- everybody picks one.
    local proportionalVariance = 200 / initialSkillAverage
    local healthCompensate = 1 + ( proportionalVariance / avgInUseOffsetSkill )
    local expectationInUse = inUseTotal * initialSkillAverage * healthCompensate

    -- The actual number of in use points the player starts with.
    savedData.inUsePoints = adjustedInUseTotal / avgInUseOffsetSkill

    -- Calculate the total number of expected health points, modified by configurable multipliers for background and in
    -- use points (these multipliers will also be used when actually calculating health later).
    local weightedExpInUse = expectationInUse * 0.01 * config.healthInUseMult
    local weightedExpBack = expectationBack * 0.01 * config.healthBackgroundMult
    local totalExpectedPoints = weightedExpInUse + weightedExpBack

    -- The health constant is used in health calculations, and is calculated such that an average character will start
    -- out with health close to healthBase.
    savedData.healthConstant = ( config.healthBase - config.healthBonus ) / ( racialAttributeAverage * totalExpectedPoints )

    debugMsg(string.format("expectationBack: %f", expectationBack))
    debugMsg(string.format("proportionalVariance: %f", proportionalVariance))
    debugMsg(string.format("healthCompensate: %f", healthCompensate))
    debugMsg(string.format("expectationInUse: %f", expectationInUse))
    debugMsg(string.format("savedData.inUsePoints: %f", savedData.inUsePoints))
    debugMsg(string.format("weightedExpInUse: %f", weightedExpInUse))
    debugMsg(string.format("weightedExpBack: %f", weightedExpBack))
    debugMsg(string.format("totalExpectedPoints: %f", totalExpectedPoints))
    debugMsg(string.format("savedData.healthConstant: %f", savedData.healthConstant))

    -- The "skill points" for each of the seven main attributes (not including luck) were calculated earlier. Iterate
    -- through these values one at a time and use them to perform other attribute-related calculations.
    for index, points in pairs(skillPoints) do

        -- Like with skills, attribute keys in our persistent data tables need to be saved as strings rather than
        -- numbers ("0" rather than 0 for strength, for example).
        local attributeString = tostring(index)

        local attributeName = tes3.attributeName[index]

        -- The "adjusted scores" for each attribute will average about 1, and typically range from about 0.6 - 2, though
        -- they can be lower or higher with unusual values for configurable variables. These serve as multipliers that
        -- contribute to determining the player's starting attributes and how quickly each attribute increases.
        local adjustedScore = ( ( ( points / pointsExpectation ) - 1 ) * 0.01 * config.attributeSpread ) + 1

        -- Multiply the average of the player's racial starting attributes by the "adjusted scores" calculated above
        -- (based on initial skills and skill factors). The result is what the player's starting attributes would be if
        -- they were determined entirely by initial skills, not by race.
        local classComponentAttribute = racialAttributeAverage * adjustedScore * classAttributeStart

        -- A configurable percentage of the player's racial attributes. If the player sets racialAttributeStart to 100%,
        -- starting attributes will be equal to racial attributes.
        local raceComponentAttribute = racialAttributes[index] * 0.01 * config.racialAttributeStart

        -- Combine racial attributes and skill-determined attributes to determine the player's actual starting
        -- attributes. The math.round function rounds to the nearest integer. Note that simply rounding each attribute
        -- like this is different from GCD's very convoluted method, but on average the result should be the same.
        startingAttributes[index] = math.round( classComponentAttribute + raceComponentAttribute )

        --[[ First, a ratio is calculated between the racial attribute and the average of racial attributes. The ratio
        is modified by the configurable racial attribute progress variable (the lower this variable is, the closer to 1
        the ratio is). It's then additionally modified by the "adjusted score" calculated above based on initial skills
        and skill factors. The result is the relative rate of increase of each attribute. ]]--
        local relativeIncreaseRate = ( ( ( ( racialAttributes[index] / racialAttributeAverage ) - 1 ) * 0.01 * config.racialAttributeProgress ) + 1 ) * adjustedScore

        -- The relative increase rates are modified by the configurable overall attribute increase rate to determine the
        -- absolute rate of increase. (Actually these values determine the increase threshold for each attribute; a
        -- higher relative increase rate means a lower increase threshold, making an attribute faster to increase.)
        local increaseRate = relativeIncreaseRate * increaseRateConstant

        --[[ Calculate the actual thresholds for attribute increases used by the mod, and save these thresholds for
        later use. These thresholds will never be modified for this character, even if the player later changes the
        values (such as skill factors) that went into calculating them.

        The thresholds are just the inverse of the "increase rates" calculated above. A higher "increase rate" means a
        lower threshold. A perfectly average attribute (with a racial value equal to the average, and all skills that
        influence it also average) would have a threshold of 125, assuming attributeIncreaseRate is set to the default
        value. ]]--
        savedData.increaseThresholds[attributeString] = 1 / increaseRate

        -- These progress values are the actual values that the mod increases on each skillup. When a progress value for
        -- an attribute reaches that attribute's increase threshold, the attribute increases by 1. The progress values
        -- start at half of the threshold, to make the first increase of each attribute faster.
        savedData.attributeProgress[attributeString] = 0.5 * savedData.increaseThresholds[attributeString]

        debugMsg(string.format("adjustedScore[%s]: %f", attributeName, adjustedScore))
        debugMsg(string.format("classComponentAttribute[%s]: %f", attributeName, classComponentAttribute))
        debugMsg(string.format("raceComponentAttribute[%s]: %f", attributeName, raceComponentAttribute))
        debugMsg(string.format("startingAttributes[%s]: %f", attributeName, startingAttributes[index]))
        debugMsg(string.format("relativeIncreaseRate[%s]: %f", attributeName, relativeIncreaseRate))
        debugMsg(string.format("increaseRate[%s]: %f", attributeName, increaseRate))
        debugMsg(string.format("savedData.increaseThresholds[%s]: %f", attributeName, savedData.increaseThresholds[attributeString]))
        debugMsg(string.format("savedData.attributeProgress[%s]: %f", attributeName, savedData.attributeProgress[attributeString]))
    end

    --[[ Also calculate starting luck through a completely different method. The *difference* between the player's
    starting luck and 40 is multipled by the configurable luck increase rate percentage (default 70%).

    This means that the luck bonus from choosing luck as a favored attribute is multipled by the same percentage used to
    determine later luck gains relative to other attribute gains, which balances what would otherwise be a strong
    incentive to start with luck as high as possible. (In other words, this is done to ensure choosing luck as a favored
    attribute would not confer a particular advantage compared to choosing another attribute.)

    The math.floor function rounds *down* to the nearest integer. GCD did the same. ]]--
    startingAttributes[tes3.attribute.luck] = math.floor( ( ( racialAttributes[tes3.attribute.luck] - 40 ) * 0.01 * config.luckIncreaseRate ) + 40 )

    -- The luck increase threshold is 1 in the code (actually very slightly less than 1, and there's a good reason for
    -- that), though it's displayed differently in-game.
    savedData.attributeProgress[tostring(tes3.attribute.luck)] = 0.5
    debugMsg(string.format("startingAttributes[luck]: %f", startingAttributes[tes3.attribute.luck]))

    -- The total magic skills the player would have if all initial skills were average. The actual initial magic skill
    -- total will be compared with this and used in magicka calculations.
    local avgInitialMagicSkills = initialSkillAverage * 8

    -- Determine the player's total magic skills relative to the average, modified by a configurable offset. The
    -- relative offset total would be 1.0 for an average character. A higher offset will pull the relative offset total
    -- closer to 1.0, while a lower offset will push it further away from 1.0.
    local magMaxOffsetTotal = savedData.totalMagicSkills + config.magMaxStartOffset
    local magMaxAvgOffsetTotal = avgInitialMagicSkills + config.magMaxStartOffset
    local magMaxRelativeOffsetTotal = magMaxOffsetTotal / magMaxAvgOffsetTotal

    -- The average magic skill total multiplied by the relative offset total ratio (which is modified by the offset).
    -- This value is used in max magicka calculations.
    local startMaxPoints = magMaxRelativeOffsetTotal * avgInitialMagicSkills

    -- The vanilla "magicka multiplier" is affected by the fPCbaseMagickaMult GMST and any Fortify Maximum Magicka
    -- effect the player is under. This acts as a multiplier to max magicka, as in the vanilla game.
    local startMagickaMultiplier = tes3.mobilePlayer.magickaMultiplier.base

    -- We need to store the player's starting intelligence value in persistent data, because the max magicka formula
    -- later uses the ratio of current to initial intelligence in its calculations.
    savedData.initialIntelligence = startingAttributes[tes3.attribute.intelligence]

    -- How much magicka the player would have at the beginning of the game using the vanilla formula.
    local startMagicka = savedData.initialIntelligence * startMagickaMultiplier

    --[[ Determine the "unaffected" portion of the player's magicka pool. This portion of the pool is not affected by
    most of the mod's magicka calculations (it will only be affected by intelligence, Fortify Maximum Magicka and the
    magMaxMultiplier config setting), and serves as a minimum max magicka value for even the least magically-inclined
    characters. math.min returns the lowest of the two values, to ensure unaffected magicka can't be higher than
    starting magicka. ]]--
    savedData.unaffectedMagicka = config.magMaxUnaffected * startMagickaMultiplier
    savedData.unaffectedMagicka = math.min(savedData.unaffectedMagicka, startMagicka)

    -- What's left over after the unaffected portion is taken out is the "affected" portion of the magicka pool, which
    -- is affected by the mod's full magicka calculations.
    local affectedMagicka = startMagicka - savedData.unaffectedMagicka

    debugMsg(string.format("avgInitialMagicSkills: %f", avgInitialMagicSkills))
    debugMsg(string.format("magMaxOffsetTotal: %f", magMaxOffsetTotal))
    debugMsg(string.format("magMaxAvgOffsetTotal: %f", magMaxAvgOffsetTotal))
    debugMsg(string.format("magMaxRelativeOffsetTotal: %f", magMaxRelativeOffsetTotal))
    debugMsg(string.format("startMaxPoints: %f", startMaxPoints))
    debugMsg(string.format("startMagickaMultiplier: %f", startMagickaMultiplier))
    debugMsg(string.format("savedData.initialIntelligence: %f", savedData.initialIntelligence))
    debugMsg(string.format("startMagicka: %f", startMagicka))
    debugMsg(string.format("savedData.unaffectedMagicka: %f", savedData.unaffectedMagicka))
    debugMsg(string.format("affectedMagicka: %f", affectedMagicka))

    -- Check if the player is affected by Stunted Magicka (i.e. has chosen The Atronach as a birthsign). If so, boost
    -- the affected portion of the magicka pool, to compensate for the lack of magicka regen.
    if getStunted() then
        affectedMagicka = affectedMagicka * 1.3
        debugMsg("Player is affected by Stunted Magicka. Boosting affectedMagicka.")
        debugMsg(string.format("affectedMagicka: %f", affectedMagicka))
    end

    -- This is one component of the later max magicka calculations, taking into account initial magic skills and the
    -- size of the affected portion of the magicka pool.
    savedData.startingEffect = ( affectedMagicka * startMaxPoints ) / 400000

    -- Just like with max magicka, determine the ratio of actual to average initial magic skills, affected by a
    -- configurable offset (which can differ from the max magicka offset, which is why we have to do this twice).
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

    -- If this function is being run after chargen as intended, we need to adjust the player's attributes.
    if newGame then
        debugMsg("This is a new game, so changing current attributes.")

        -- Actually set the player's attributes to the values determined above.
        for _, attributeId in pairs(tes3.attribute) do
            tes3.setStatistic{
                reference = tes3.player,
                attribute = attributeId,
                value = startingAttributes[attributeId],
            }
        end

    -- Otherwise (if the player installed or upgraded this mod mid-game), we don't want to change attributes, but we do
    -- need to make a few additional adjustments here.
    else
        debugMsg("This is not a new game. Calculating additional health background and in use points, and recalculating totalMagicSkills, based on current skills.")

        -- The saved total of magic skills is currently based on average initial values (which was needed for the
        -- earlier calculations), but we need to determine the actual total so the magicka calculations later will be
        -- (close to) right.
        savedData.totalMagicSkills = 0

        -- Iterate through the skill tables in the config file.
        for _, configSkill in ipairs(config.skillFactors) do
            local skillId = configSkill.skill
            local backgroundFactor = configSkill.healthBackFactor
            local inUseFactor = configSkill.healthInUseFactor
            local skillName = tes3.skillName[skillId]

            -- The key values in persistent data tables are necessarily strings, not numbers.
            local skillString = tostring(skillId)

            -- Compensate for the off-by-one issue for skill IDs.
            local mobileSkill = skillId + 1

            -- Determine the difference between the player's current skill and the "initial" value used earlier (which
            -- is just an average value in this case).
            local currentSkill = tes3.mobilePlayer.skills[mobileSkill].base
            local difference = currentSkill - initialSkills[skillId]

            -- Add to (or possibly subtract from)  background points to determine the real current value.
            savedData.backgroundPoints = savedData.backgroundPoints + ( difference * backgroundFactor )

            --[[ Adjust in use points based on current skill values. Note that the mod's calculations of in use points
            (unlike the background points calculations) treat subsequent skill gains differently than initial skill
            points, so the result here will not be identical to what it would be if the real initial skill values were
            known. ]]--
            savedData.inUsePoints = savedData.inUsePoints + ( difference * inUseFactor * savedData.inUseProportion[skillString])

            debugMsg(string.format("Iterating through %s skill in config table.", skillName))
            debugMsg(string.format("currentSkill: %f", currentSkill))
            debugMsg(string.format("difference: %f", difference))
            debugMsg(string.format("savedData.backgroundPoints so far: %f", savedData.backgroundPoints))
            debugMsg(string.format("savedData.inUsePoints so far: %f", savedData.inUsePoints))

            -- If this is a magic skill, add to the actual magic skills total.
            if checkMagicSkill(skillId) then
                savedData.totalMagicSkills = savedData.totalMagicSkills + currentSkill
                debugMsg(string.format("savedData.totalMagicSkills so far: %f", savedData.totalMagicSkills))
            end
        end

        tes3.messageBox("You have installed CCCP mid-playthrough.\n\nThis is not ideal, and will result in several aspects of the mod not working as intended.\n\nTo experience CCCP as intended, it is highly recommended to start a new game.")
    end

    debugMsg(string.format("savedData: %s", json.encode(tes3.player.data.CCCP, { indent = true })))

    -- Run the calculations for max health and max magicka.
    setHealth()
    setMagicka(false)

    -- Start the timer for magicka regen ticks.
    initMagRegenTimer()

    -- Register the enterFrame event (which occurs every frame) so we can start checking for endurance and intelligence
    -- changes (and adjust health and magicka accordingly).
    enterFrameActive = true
    event.register("enterFrame", onEnterFrame)
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

    -- Change the GMST used by Morrowind to determine how many skillups are required to level. This GMST won't actually
    -- be used by this mod; we're only doing this so the levelup progress tooltip will display the correct threshold.
    tes3.findGMST(tes3.gmst.iLevelupTotal).value = config.attributesToLevel

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
        savedData = tes3.player.data.CCCP

        -- This means either the player is installing this mod mid-game with a save that did not previously use CCCP
        -- (savedData is nil), or this save previously used CCCP 1.0 (savedData is not nil but savedData.version is).
        if savedData == nil or savedData.version == nil then
            debugMsg("This savegame did not previously use CCCP or used an old version. Performing initial calculations.")

            -- We need to run our initial calculations, assuming average values for initial skills/attributes since this
            -- is not a new game (and MWSE has no way to determine initial skill/attribute values after the fact).
            initialCalculations(false)

        -- The player has loaded a savegame that uses the current version of CCCP. This is what will normally happen
        -- when the player loads their save.
        else
            debugMsg("This savegame uses the current version of CCCP. Setting health and magicka.")

            -- Run the calculations for max health and max magicka.
            setHealth()
            setMagicka(true)

            -- Start the timer for magicka regen ticks.
            initMagRegenTimer()

            -- The enterFrame event occurs every frame, including when the menu is open.
            enterFrameActive = true
            event.register("enterFrame", onEnterFrame)
        end
    end
end

-- Called just before each game load, whether a savegame or new game.
local function onLoad()

    --[[ Unregister the simulate event if it's currently registered. Otherwise, the player could start a new game and
    then, during chargen, load a savegame. This would result in the onSimulate function running after the savegame is
    loaded. Since chargen is complete in the savegame, the mod would re-run its initial calculations using the
    savegame's current skill/attribute values, which would totally screw up the mod's saved values for that save.

    In other words, it's very important that the onSimulate function only runs during chargen. This ensures that's the
    case. ]]--
    if simulateActive then
        simulateActive = false
        event.unregister("simulate", onSimulate)
    end

    -- Unregister the enterFrame event if it's currently registered. The onEnterFrame function should only run *after*
    -- chargen is complete. Otherwise, it would result in errors, since the saved player data does not exist during
    -- chargen.
    if enterFrameActive then
        enterFrameActive = false
        event.unregister("enterFrame", onEnterFrame)
    end
end

-- Runs when the mod is initialized, basically as soon as Morrowind is started.
local function onInitialized()
    local buildDate = mwse.buildDate
    local tooOld = string.format("[%s %s] MWSE is too out of date. Update MWSE to use this mod.", mod, version)

    -- This mod uses a couple recently-added MWSE features (.currentRaw and .baseRaw for attributes, and attribute param
    -- for tes3.getEffectMagnitude), so require up to date MWSE with these features.
    if not buildDate
    or buildDate < 20210518 then
        tes3.messageBox(tooOld)
        mwse.log(tooOld)
        return
    end

    -- These variables are used to keep track of whether the simulate and enterFrame events are registered. In both
    -- cases, it's important to make sure the corresponding functions (especially onSimulate) only run when they're
    -- supposed to. Otherwise, bad things would happen.
    simulateActive = false
    enterFrameActive = false

    -- These GMSTs are used by Morrowind to determine how much to add to levelUpProgress each time a major or minor
    -- skill increases. We don't want this to happen - this mod controls levelUpProgress manually - so we set these
    -- GMSTs to 0 here.
    tes3.findGMST(tes3.gmst.iLevelupMajorMult).value = 0
    tes3.findGMST(tes3.gmst.iLevelupMinorMult).value = 0

    -- The load event occurs just before a savegame or new game is loaded, while the loaded event occurs just after the
    -- game is loaded.
    event.register("load", onLoad)
    event.register("loaded", onLoaded)

    --[[ The skillRaised event occurs when a skill is increased by use, training or reading a skillbook (i.e. when
    Morrowind plays the skillup sound). In the vanilla game, scripted skill increases, such as those from certain quest
    rewards, don't count, which means such skill increases will not contribute to attribute or level increases. However,
    there is a mod called Quest Skill Reward Fix that triggers the skillRaised event for scripted skill increases. Using
    that mod is highly recommended. ]]--
    event.register("skillRaised", onSkillRaised)

    -- This event occurs each time a skill is used (making progress toward a skill increase). The negative priority
    -- ensures any other mods using the same event get to go first. This is important for compatibility with Nimble
    -- Armor.
    event.register("exerciseSkill", onExerciseSkill, { priority = -10 })

    -- This event occurs each time the cost of training is calculated (three times each time the player opens the
    -- training service menu).
    event.register("calcTrainingPrice", onCalcTrainingPrice)

    -- With the filter, this event occurs when the stat menu is created.
    event.register("uiActivated", onMenuStatActivated, { filter = "MenuStat" })

    -- Set these here on initialized so we only need to check them once (changing those settings in Fortify MAX requires
    -- a restart).
    if fortifyMAX then
        fortifyMAXMagickaEnabled = fortifyMAX.magicka
        fortifyMAXSpellTickEnabled = fortifyMAX.spellTick
    end

    -- No need to do this stuff on spellTick if the player isn't using the max magicka handling part of CCCP. Or if they
    -- have the spellTick component of Fortify Max enabled, which does the exact same thing just for all attributes.
    if config.maxMagickaHandling
    and not fortifyMAXSpellTickEnabled then
        event.register("spellTick", onSpellTick)
        debugMsg("Max magicka handling enabled and Fortify MAX spellTick component not detected. Registering spellTick event.")
    end

    mwse.log(string.format("[%s %s] Initialized.", mod, version))
end

-- Low priority to ensure Fortify MAX, if present, can set its interop variables before we check them.
event.register("initialized", onInitialized, { priority = -10 })

-- Register the mod config menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\CCCP\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)