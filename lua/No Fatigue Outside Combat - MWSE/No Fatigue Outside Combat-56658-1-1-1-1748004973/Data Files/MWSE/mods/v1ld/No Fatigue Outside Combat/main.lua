-- v1ld.git@gmail.com, May 2025
-- Reuse freely

-- MCM data
local defaultConfig = {
    run = true,
    swim = false,
    jump = false,
    encumbrance = false,
    logLevel = "INFO",
}

local configPath = "No Fatigue Outside Combat"
local myConfig = mwse.loadConfig(configPath, defaultConfig)

-- default fatigue regen/sec = 2.5 + 0.02 * endurance
-- we use 0 to speed up filling the bar after combat
local noFatigueValue = 0.0

-- convenient constants
local run = "run"
local jump = "jump"
local swim = "swim"
local encumbrance = "encumbrance"

-- configuration is by kind (run/jump/swim) so we associate gmsts with kinds
local fatigueGMSTs = {
    [tes3.gmst.fFatigueRunBase] = run,
    [tes3.gmst.fFatigueRunMult] = run,
    [tes3.gmst.fFatigueJumpBase] = jump,
    [tes3.gmst.fFatigueJumpMult] = jump,
    [tes3.gmst.fFatigueSwimWalkBase] = swim,
    [tes3.gmst.fFatigueSwimWalkMult] = swim,
    [tes3.gmst.fFatigueSwimRunBase] = swim,
    [tes3.gmst.fFatigueSwimRunMult] = swim,
    [tes3.gmst.fEncumberedMoveEffect] = encumbrance,
}
local savedGMSTs = {}

local log = mwse.Logger.new()
log:setLogLevel(myConfig.logLevel)

local function recordFatigueGMSTs()
    log:debug("Recording original GMST values")
    for gmst, _ in pairs(fatigueGMSTs) do
        savedGMSTs[gmst] = tes3.findGMST(gmst).value
        log:info("Recorded %s = %f", tes3.findGMST(gmst).id, tes3.findGMST(gmst).value)
    end
end

local function resetFatigueGMSTs()
    log:debug("Updating GMSTs based on settings")
    for gmst, kind in pairs(fatigueGMSTs) do
        tes3.findGMST(gmst).value = myConfig[kind] and noFatigueValue or savedGMSTs[gmst]
        log:trace("Update %s = %f", tes3.findGMST(gmst).id, tes3.findGMST(gmst).value)
    end
end

local function restoreFatigueGMSTs()
    log:debug("Restoring GMSTs to recorded original values")
    for gmst, _ in pairs(fatigueGMSTs) do
        tes3.findGMST(gmst).value = savedGMSTs[gmst]
        log:trace("Restored %s = %f", tes3.findGMST(gmst).id, tes3.findGMST(gmst).value)
    end
end

local function gameLoadedCallback(e)
    log:info("Game loaded, initializing fatigue from settings (log level = %s)", myConfig.logLevel)
    -- if we load into combat, game is already using the right fatigue
    recordFatigueGMSTs()
    if not tes3.mobilePlayer.inCombat then
        resetFatigueGMSTs()
    end
end
event.register(tes3.event.loaded, gameLoadedCallback)

local function combatStartedCallback(e)
    log:debug("Combat started for %splayer", (e.actor.actorType ~= tes3.actorType.player) and "non-" or "")
    if e.actor.actorType == tes3.actorType.player then
        restoreFatigueGMSTs()
    end
end
event.register(tes3.event.combatStarted, combatStartedCallback)

local function combatStoppedCallback(e)
    log:debug("Combat stopped for %splayer", tes3.mobilePlayer.inCombat and "non-" or "")
    -- we don't get combatStopped events for the player, so brute force check inCombat instead
    if not tes3.mobilePlayer.inCombat then
        resetFatigueGMSTs()
    end
end
event.register(tes3.event.combatStopped, combatStoppedCallback)

-- MCM menus
local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = configPath,
        config = myConfig,
    })

    template:register()
    template:saveOnClose(configPath, myConfig)

    local page = template:createSideBarPage{
        label = "No Fatigue Outside Combat",
        description = "Settings for removing fatigue use and encumbrance slowdown except when in combat.\n\nHover over each setting to learn more about it. Some settings are disabled until a save is loaded.",
    }

    local onlyAfterLoad = "\n\nThis setting is only available once a save has been loaded."

    local fatigue = page:createCategory{ label = "Control stamina use outside of combat" }
    fatigue:createYesNoButton{
        label = "Running doesn't increase fatigue",
        description = "Remove fatigue when running except when in combat." .. onlyAfterLoad,
        configKey = run,
        inGameOnly = true,
        callback = function (self) resetFatigueGMSTs() end
    }
    fatigue:createYesNoButton{
        label = "Swimming doesn't increase fatigue",
        description = "Remove fatigue when swimming except when in combat." .. onlyAfterLoad,
        configKey = swim,
        inGameOnly = true,
        callback = function (self) resetFatigueGMSTs() end
    }
    fatigue:createYesNoButton{
        label = "Jumping doesn't increase fatigue",
        description = "Remove fatigue when jumping except when in combat." .. onlyAfterLoad,
        configKey = jump,
        inGameOnly = true,
        callback = function (self) resetFatigueGMSTs() end
    }

    local movement = page:createCategory{ label = "Slow down from encumbrance outside of combat" }
    movement:createYesNoButton{
        label = "Encumbrance doesn't slow you down",
        description = "Remove encumbrance penalty to movement except when in combat." .. onlyAfterLoad,
        configKey = encumbrance,
        inGameOnly = true,
        callback = (function (self) resetFatigueGMSTs() end)
    }

    local dev = page:createCategory{ label = "Log verbosity" }
    dev:createDropdown{
        label = "Log level",
        description = "Set the log verbosity level.\n\nUseful for debugging or tracing.",
        options = {
            { label = "TRACE", value = "TRACE" },
            { label = "DEBUG", value = "DEBUG" },
            { label = "INFO",  value = "INFO" },
            { label = "WARN",  value = "WARN" },
            { label = "ERROR", value = "ERROR" },
            { label = "NONE",  value = "NONE" },
        },
        configKey = "logLevel",
        callback = function(self) log:setLogLevel(myConfig.logLevel) end,
    }
end
event.register(tes3.event.modConfigReady, registerModConfig)