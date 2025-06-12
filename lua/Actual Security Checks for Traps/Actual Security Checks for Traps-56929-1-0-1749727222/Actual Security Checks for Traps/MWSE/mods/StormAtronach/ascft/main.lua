local config_default = {
    enabled = true,
    maxTrapLevel = 150,
    agilityModifier = 0.15,
    luckModifier = 0.15,
    securityModifier = 0.40,
    flatBonus = 40,
    chanceMultiplier = 1,
    logLevel = "error"
}

local config = mwse.loadConfig("sa_ascft", config_default)
local log = mwse.Logger.new({modName = "Actual Security Checks for Traps"})


--- @param e trapDisarmEventData
local function trapDisarmCallback(e)
    -- Step 1: We check if a trap is actually present
    if e.reference and not e.trapPresent then
        tes3.messageBox("This is not trapped.")
        return
    end
    -- Step 2: Check the level of the lock. If greater than 0, the trap will have the same. If zero, it will be random
    local trapLevel = 0
    if e.lockData.level > 0 then
        trapLevel = e.lockData.level
        log:trace("Lock level: %s, trap level: %s", e.lockData.level, trapLevel)
    else
        trapLevel = math.clamp(e.lockData.trap.magickaCost,1,config.maxTrapLevel)
        log:trace("No lock level found?. Lock level: %s, trap level: %s", e.lockData.level, trapLevel)
    end
        -- Step 4: We perform a skill check
    local securitySkill = e.disarmer.security.current or 0
    local luck =e.disarmer.luck.current or 0
    local agility = e.disarmer.agility.current or 0
    local probeQuality = e.tool.quality or 0
    local skillCheck = (config.agilityModifier*agility + config.luckModifier*luck + config.securityModifier*securitySkill+config.flatBonus)*probeQuality
    if skillCheck < trapLevel then
        e.chance = -10
        tes3.messageBox("I need to improve my skill or use better tools")
    else
    e.chance = (skillCheck - trapLevel)*config.chanceMultiplier
    log:trace("Skill check: %s, Trap level: %s, Chance: %s",skillCheck,trapLevel,e.chance)
    log:trace("Security skill: %s -- luck: %s -- agility: %s -- probe quality: %s", securitySkill, luck, agility, probeQuality)
    end
end

event.register("initialized", function ()
event.register(tes3.event.trapDisarm, trapDisarmCallback, {priority = -100})
log.level = config.logLevel
print("Actual Security Checks for Traps: initialized")
end)


--- MCM Registration
event.register("modConfigReady", function()
    local template = mwse.mcm.createTemplate({ name = "Actual Security Checks for Traps" })
    template:saveOnClose("sa_ascft", config)

    local page = template:createSideBarPage({
        label = "Settings",
        description = "Configure trap scaling and skill modifiers for the mod."
    })

    page:createOnOffButton({
        label = "Enable the mod",
        description = "Disables or enables the functionality of this mod",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = config}
    })

    page:createSlider({
        label = "Max Trap Level",
        description = "Maximum possible trap level.",
        min = 1,
        max = 200,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "maxTrapLevel",
            table = config
        }
    })

    page:createSlider({
        label = "Agility Modifier",
        description = "Multiplier for agility in disarm chance.",
        min = 0,
        max = 0.5,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
        variable = mwse.mcm.createTableVariable{
            id = "agilityModifier",
            table = config
        }
    })

    page:createSlider({
        label = "Luck Modifier",
        description = "Multiplier for luck in disarm chance.",
        min = 0,
        max = 0.5,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
        variable = mwse.mcm.createTableVariable{
            id = "luckModifier",
            table = config
        }
    })

    page:createSlider({
        label = "Security Modifier",
        description = "Multiplier for security skill in disarm chance.",
        min = 0,
        max = 0.5,
        step = 0.01,
        jump = 0.1,
        decimalPlaces = 2,
        variable = mwse.mcm.createTableVariable{
            id = "securityModifier",
            table = config
        }
    })

    page:createSlider({
        label = "Flat Bonus",
        description = "Flat bonus added to disarm chance.",
        min = 0,
        max = 50,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "flatBonus",
            table = config
        }
    })
    page:createSlider({
        label = "Chance Multiplier",
        description = "This multiplies the actual disarm chance when the skill check is passed. Increase it if you feel you are wasting too many probes.",
        min = 0,
        max = 5,
        step = 0.1,
        jump = 1,
        decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{
            id = "chanceMultiplier",
            table = config
        }
    })

    page:createLogLevelOptions({
    config = config,
    configKey = "logLevel",
    logger = log
})

    mwse.mcm.register(template)
end)