-- v1ld.git@gmail.com, May 2025

-- Almost all the code is from Necrolesian's awesome CCCP mod.
-- Read Necrolesian's license on the CCCP mod for reuse terms.

local savedData, simulateActive
local version = "1" -- configuration layout versioning, saved with save game

local defaultConfig = {
    slowdownStart = 60,
    slowdownSpread = 80,
    slowdownRate = 35,
    logLevel = "INFO",
}

local configPath = "CCCP GCD Class Based Skill Leveling"
local config = mwse.loadConfig(configPath, defaultConfig)

local log = mwse.Logger.new()
log:setLogLevel(config.logLevel)

--[[ Runs three times each time the player opens the training service menu, once for each skill. Instead of requiring
multiple training sessions to increase a skill affected by slowdown (as GCD did), we just make it cost more instead. The
result is the same.

This function works pretty much exactly like onExerciseSkill does, with identical calculations. The only difference is
that the training price is multiplied by the final slowdown rate (2, 3, 4, etc.) here, while in onExerciseSkill the
amount of progress is divided by the same number. ]]--
local function onCalcTrainingPrice(e)
    log:trace("Calculating training price.")

    if config.slowdownRate <= 0 then
        log:trace("Slowdown rate is 0. Not adjusting price.")
        return
    end

    local skillId = e.skillId
    local skillString = tostring(skillId)
    local mobileSkill = skillId + 1
    local currentSkill = tes3.mobilePlayer.skills[mobileSkill].base
    local difference = currentSkill - savedData.slowdownPoint[skillString]
    log:trace("%s: %f", tes3.skillName[skillId], currentSkill)
    log:trace("Slowdown point: %f", savedData.slowdownPoint[skillString])
    log:trace("Difference: %f", difference)

    if difference < 0 then
        log:trace("Skill is less than slowdown point. Not adjusting price.")
        return
    end

    local exponent = difference + 1
    local rate = 1 + ( 0.001 * config.slowdownRate )
    local multiplier = math.ceil( rate ^ exponent )
    log:trace("Exponent: %f", exponent)
    log:trace("Rate: %f", rate)
    log:trace("Multiplier: %f", multiplier)

    log:debug("Old price: %f", e.price)
    e.price = e.price * multiplier
    log:debug("New price: %f", e.price)
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

    if e.skill ~= tes3.skill.athletics then
        log:trace("Slowdown for %s: %f. Reducing %f to %f", tes3.skillName[e.skill], multiplier, e.progress, e.progress * multiplier)
    end

    e.progress = e.progress * multiplier
end

--[[ Called immediately after chargen is complete (or if the player installs this mod mid-game). This function runs only
once per character and is responsible for all initial calculations. This mod uses the player's initial skill and
attribute values to calculate many of the values that will be used throughout the mod, and these initial values can only
be determined at the beginning of the game (MWSE has no way to determine initial skill/attribute values after the fact).
If the player installs the mod mid-game, the calculations will assume the player's initial skills and attributes were
all average, and the result will be less than ideal. ]]--
local function initialCalculations(newGame)
    local initialSkills = {}

    -- Creates a block of persistent data that's saved in the player's savegame. This is needed so certain values
    -- calculated here can persist between game sessions and be referred to (and in some cases modified) later. This
    -- block of data starts off as a blank table.
    tes3.player.data.v1ldCGCBSL = {}

    -- The local variable savedData is just an alias for our persistent block of data, making it easier to reference.
    savedData = tes3.player.data.v1ldCGCBSL
    savedData.slowdownPoint = {}
    savedData.version = version

    -- If newGame is true, then this function is being run after chargen, as intended.
    if newGame then
        -- Go through all 27 of the player's skills, one at a time.
        for i, skill in ipairs(tes3.mobilePlayer.skills) do
            -- Skill IDs in MWSE are 0-26, but the actual skills used by the game for mobile actors are indexed 1-27.
            local skillId = i - 1

            -- Obtain the player's current (initial) skill values. We also need to add up all the initial skills.
            initialSkills[skillId] = skill.base
            log:info("Base %s: %f", tes3.skillName[skillId], initialSkills[skillId])
        end

    -- newGame will be false only if the player starts using this mod during an existing playthrough rather than
    -- starting a new game.
    else
        log:info("This is not a new game, so using typical average initial skills and attributes.")

        -- Set these sums to the average values for vanilla Morrowind. (If the player is using a mod that changes this,
        -- we have no way of knowing.) Note that the attribute sum does not include luck.
        local initialSkillSum = 400
        local averageSkill = initialSkillSum / 27

        -- Pretend that the player's skills all started at the average value.
        for i, _ in ipairs(tes3.mobilePlayer.skills) do
            local skillId = i - 1
            initialSkills[skillId] = averageSkill
            log:info("Base %s: %f", tes3.skillName[skillId], initialSkills[skillId])
        end
    end

    for i, _ in ipairs(tes3.mobilePlayer.skills) do
        -- Skill IDs in MWSE are 0-26, but the actual skills used by the game for mobile actors are indexed 1-27.
        local configSkillId = i - 1
        local skillName = tes3.skillName[configSkillId]

        --[[ configSkillId is the numeric skill ID 0-26. tostring turns it into a string, "0" - "26". This is needed
        when we'll be saving data for each skill in our persistent data. Numeric keys in tables will always be converted
        to strings when being saved in the player data, so we need to save them as strings in the first place so we can
        consistently retrieve their values. ]]--
        local skillString = tostring(configSkillId)

        -- Calculate the skill slowdown point for each skill (the point where skill progression starts to slow down) by
        -- adding a percentage of the initial skill value to the base slowdown point.
        local slowdownExtra = initialSkills[configSkillId] * 0.01 * config.slowdownSpread
        savedData.slowdownPoint[skillString] = config.slowdownStart + slowdownExtra
        log:trace("Slowdown extra %s: %f", skillName, slowdownExtra)
        log:info("Slowdown point %s: %f", skillName, savedData.slowdownPoint[skillString])
    end
end

-- Called every frame until chargen is complete.
local function onSimulate()
    -- Checks the CharGenState global variable, which is set to 10 at the beginning of chargen and to -1 after chargen
    -- is complete. In other words, wait until chargen finishes, then run the rest of the function.
    if tes3.findGlobal("CharGenState").value ~= -1 then
        return
    end

    -- Once chargen is finally complete, we unregister the event that calls this function so it won't keep running every
    -- frame, then run all the initial calculations.
    log:trace("Chargen is complete.")
    simulateActive = false
    event.unregister("simulate", onSimulate)
    initialCalculations(true)
end

-- Called each time the game is loaded, whether a savegame or a new game.
local function onLoaded(e)
    -- The player has started a new game, which means we need to register the simulate event during chargen (so we can
    -- detect when chargen ends).
    if e.newGame then
        -- The simulate event occurs every frame, except when the menu is open.
        simulateActive = true
        event.register("simulate", onSimulate)

    -- The player has loaded a savegame.
    else
        -- Assign our persistent player data to a local variable for easy access.
        savedData = tes3.player.data.v1ldCGCBSL

        -- This means either the player is installing this mod mid-game with a save that did not previously use CCCP
        if savedData == nil or savedData.version == nil then
            -- We need to run our initial calculations, assuming average values for initial skills/attributes since this
            -- is not a new game (and MWSE has no way to determine initial skill/attribute values after the fact).
            initialCalculations(false)
        else
            log:info("Loaded saved skill slowdown points")
            for i, _ in ipairs(tes3.mobilePlayer.skills) do
                log:info("Slowdown point %s: %f", tes3.skillName[i-1], savedData.slowdownPoint[tostring(i-1)])
            end
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
end

-- Runs when the mod is initialized, basically as soon as Morrowind is started.
local function onInitialized()

    simulateActive = false

    -- The load event occurs just before a savegame or new game is loaded, while the loaded event occurs just after the
    -- game is loaded.
    event.register("load", onLoad)
    event.register("loaded", onLoaded)

    -- This event occurs each time a skill is used (making progress toward a skill increase). The negative priority
    -- ensures any other mods using the same event get to go first. This is important for compatibility with Nimble
    -- Armor.
    event.register("exerciseSkill", onExerciseSkill, { priority = -10 })

    -- This event occurs each time the cost of training is calculated (three times each time the player opens the
    -- training service menu).
    event.register("calcTrainingPrice", onCalcTrainingPrice)
end
event.register("initialized", onInitialized)

-- MCM
local function onModConfigReady()
    local template = mwse.mcm.createTemplate({
        name = configPath,
        config = config,
    })

    template:register()
    template:saveOnClose(configPath, config)

    local onlyChargen = "This value is used only during the mod's initial calculations upon completing chargen. Changing this value after chargen is complete will have no effect."

    local page = template:createSideBarPage{
        label = "CCCP & GCD Class-based Skill Leveling Settings",
        description = "Skill leveling slows down after a threshold based on the original skill value from right after chargen, using a method from the CCCP mod and GCD before it. Skills level up normally up to the threshold and then leveling slows down, getting progressively slower as the skill goes further over the threshold.\n\nHover over each setting to learn more about how this works.",
    }

    page:createSlider{
        label = "Slowdown start point",
        description =
            "The point at which skill progression can potentially begin to slow down.\n" ..
            "\n" ..
            "This is the base slowdown point used by the mod. A certain amount (which will vary by skill) will be added to this value to determine the actual slowdown point for each skill.\n" ..
            "\n" ..
            "The \"skill uncap\" feature of Morrowind Code Patch is recommended. If that feature is not enabled, skills will not progress beyond 100 regardless of any of this mod's slowdown settings.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 60",
        configKey = "slowdownStart",
        max = 100,
        defaultSetting = 60,
    }

    page:createSlider{
        label = "Slowdown spread",
        description =
            "The actual slowdown point in-game will vary by skill. This setting is the percentage of the initial value of each skill that will be added to the base start point to determine the slowdown point for each skill.\n" ..
            "\n" ..
            "With the default settings, the slowdown point for each skill will be 60 plus 80 percent of the starting value of that skill. With these settings, a skill that starts at 5 will have a slowdown point of 64, while a skill that starts at 45 will have a slowdown point of 96.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 80",
        configKey = "slowdownSpread",
        max = 200,
        jump = 10,
        defaultSetting = 80,
    }

    page:createSlider{
        label = "Slowdown rate",
        description =
            "This setting determines the rate at which skill progression will slow down once a skill reaches its slowdown point.\n" ..
            "\n" ..
            "When a skill reaches its slowdown point, it will start to progress at 1/2 its normal rate. After some additional skill increases, the rate of progression will slow to 1/3 normal, then 1/4, then 1/5, and so on.\n" ..
            "\n" ..
            "The rate at which the divisor (2, 3, 4, 5...) increases is exponential, with the base of the formula (the number being taken to an exponent) derived from this setting. Eventually, progression in the affected skill will become so slow that further increases will be prohibitively time-consuming, and the higher this setting, the earlier that happens.\n" ..
            "\n" ..
            "This setting also affects paid training, with the cost required to train a skill affected by the same multiplier as skill progression. For example, if the progression rate for a skill is 1/3 normal due to skill slowdown, the cost to train that skill will be three times normal.\n" ..
            "\n" ..
            "Setting this value to 100 will result in a very rapid skill slowdown, while setting it to 0 will disable the skill slowdown system. Changing this setting will have an immediate effect on skill progression rates for affected skills.\n" ..
            "\n" ..
            "Default: 35",
        configKey = "slowdownRate",
        max = 100,
        defaultSetting = 35,
    }
    
    page:createDropdown({
        label = "Logging Level",
        description = "Set the log level for debugging or informational purposes. Default=INFO.\n\nSet to DEBUG for more detailed logs and TRACE for extreme verbosity. Do not leave on TRACE for long sessions.",
        options = {
            { label = "TRACE", value = "TRACE" },
            { label = "DEBUG", value = "DEBUG" },
            { label = "INFO",  value = "INFO" },
            { label = "WARN",  value = "WARN" },
            { label = "ERROR", value = "ERROR" },
            { label = "NONE",  value = "NONE" },
        },
        configKey = "logLevel",
        callback = function(self) log:setLogLevel(config.logLevel) end,
    })
end
event.register("modConfigReady", onModConfigReady)