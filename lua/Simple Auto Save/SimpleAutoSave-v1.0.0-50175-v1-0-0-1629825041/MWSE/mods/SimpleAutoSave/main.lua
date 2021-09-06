--[[

	Simple Auto Save by Snowball91
    version 1.0.0

    Inspired by "Sophisticated Save System" by NullCascade.

]]--


local config = require("SimpleAutoSave.config")

-- Autosave mechanism works as follows:
-- Every few real-time seconds, a timer ticks and calls a lightweight callback (timerEvent) that
-- checks if sufficient time has elapsed since any last save. If so, a separate function is called
-- that checks for other conditions (chargen state, combat) and actually saves.
-- Autosave is timestamped by capturing the save event - this way we can also count in-game saves
-- such as when resting.

-- Pro-tip: don't do anything in main.lua because the environment is not particularly stable until
-- after initialization ("initialized" event) - cram everything into a function and register that.
-- Additionally, MWSE clears all timers on reload, so it's better to have them initialized during
-- "loaded" event.
local sasTimer = nil
local sasTimerTick = 5
local minTimeFromSave = 15
local lastSaveAttemptTime = nil

function timerEvent()
    -- Ignore ticks happening when in menu (also ignore real-time flow in menu mode)
    if tes3.menuMode() then
        lastSaveAttemptTime = lastSaveAttemptTime + sasTimerTick
        return
    end

    -- Check how long ago a save was (not too early, not too late)
    local timeSinceAutosave = os.clock() - lastSaveAttemptTime
    if timeSinceAutosave < minTimeFromSave then
        return
    end
    if timeSinceAutosave > config.autoSavePeriod * 60 then
        doAutosave()
    end
end

function setupTimers()
    lastSaveAttemptTime = os.clock()
    sasTimer = timer.start{
        type = timer.real,
        duration = sasTimerTick,
        iterations = -1,
        callback = timerEvent,
    }
    cellLoaded = false -- see cellChangeEvent
end

function doAutosave()
    -- Note that we've tried to autosave, no matter the outcome.
    -- Otherwise the game will be saved the second after e.g. combat ends (too noticeable).
    lastSaveAttemptTime = os.clock()

    -- Prevent saving while still in character generation -- try finding docs on that, ha!
    if tes3.worldController.charGenState.value ~= -1 then
        return
    end

    -- Optional: prevent saving while in combat.
    if config.dontSaveInCombat and tes3.getMobilePlayer().inCombat then
        return
    end

    -- Otherwise just do the autosave.
    tes3.saveGame({ file = "autosave", name = "Autosave" })
end

-- Autosave on cell change -- we have to ignore the first occurrence that happens during loading!
local cellLoaded = false
function cellChangeEvent(e)
    -- Note that the first run is done
    if not cellLoaded then
        cellLoaded = true
        return
    end

    -- Don't save unless configured to
    if not config.saveOnCellChange then
        return
    end

    -- Don't save if we just have a moment ago
    local timeSinceAutosave = os.clock() - lastSaveAttemptTime
    if timeSinceAutosave < minTimeFromSave then
        return
    end

    -- Handle the optional exterior-exterior transition situation
    if config.dontSaveOnExtTransitions then
        wasInterior = e.previousCell.isInterior -- would fail if we didn't ignore the first run
        isInterior = e.cell.isInterior
        if (not wasInterior) and (not isInterior) then
            return
        end
    end

    -- Autosave, finally
    doAutosave()
end

-- Intercept save event to time-stamp the last save of any kind ("restart" the autosave "timer").
function onSave(e)
    lastSaveAttemptTime = os.clock()
end

-- Register the MCM, events and run
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\SimpleAutoSave\\mcm.lua")
end)

event.register("initialized", function() mwse.log("[SimpleAutoSave] Initialized") end)
event.register("loaded", setupTimers)
event.register("cellChanged", cellChangeEvent)
event.register("save", onSave)
