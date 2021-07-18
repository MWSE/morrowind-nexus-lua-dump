local modInfo = require("PassTheTime.modInfo")
local config = require("PassTheTime.config")
local common = require("PassTheTime.common")

local function keyCheck(e, state)

    -- Exit out if the player didn't press the correct key.
    if e.keyCode ~= config.fastForwardHotkey.keyCode then
        return
    end

    -- We don't want to change the timescale when the menu is open.
    if tes3.menuMode() then
        return
    end

    local newTimescale = config.normalTimescale

    -- Player just pressed down the hotkey.
    if state == "down" then

        -- If player is also holding control, Turbo timescale applies, otherwise Fast Forward timescale.
        if e.isControlDown then
            newTimescale = config.turboTimescale
        else
            newTimescale = config.fastForwardTimescale
        end
    end

    common.changeTimescale(newTimescale, false, config.displayMessages)
end

-- Runs each time any menu is opened.
local function onMenuEnter()

    -- Needed to handle the case where the player opens the menu in Fast Forward mode.
    -- tonumber() is needed because the text entry box in the MCM changes the value to a string in the config file.
    if tes3.findGlobal("Timescale").value ~= tonumber(config.normalTimescale) then
        common.changeTimescale(config.normalTimescale, false, config.displayMessages)
    end
end

-- Runs each time any key is released.
local function onKeyUp(e)
    keyCheck(e, "up")
end

-- Runs each time any key is pressed down.
local function onKeyDown(e)
    keyCheck(e, "down")
end

-- Set the timescale to the configured normal value on game load.
local function onLoaded()
    common.changeTimescale(config.normalTimescale, config.adjustFastTravelTime, false)
end

local function onInitialized()
    event.register("loaded", onLoaded)
    event.register("keyDown", onKeyDown)
    event.register("keyUp", onKeyUp)
    event.register("menuEnter", onMenuEnter)
    mwse.log("[%s %s] Initialized.", modInfo.mod, modInfo.version)
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("PassTheTime.mcm")
end

event.register("modConfigReady", onModConfigReady)