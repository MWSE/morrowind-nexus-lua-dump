--[[

	Immersive Wait by Snowball91
    version 1.0.0

    Based on "Pass The Time" by Necrosian.
    Inspired by "Purist Friendly Magicka Regen" by Remiros and Greatness7.

    TODO(?): figure out how to prevent waiting while falling

]]--


local config = require("ImmersiveWait.config")
local common = require("ImmersiveWait.common")

local isWaiting -- the immersive wait mode is currently active
local inLegalCell -- is player currently in a cell where rest is legal
local regenTimer -- a real time clock whose ticks update the player's statistics
local lastRegenTickReal -- time of the last regen tick (real time)
local lastRegenTickGame -- time of the last regen tick (game time)
local isStunted -- true for characters under The Atronach birthsign
local isVampire -- true for characters currently suffering from vampirism


-- Register the Mod Config Menu.
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\ImmersiveWait\\mcm.lua")
end)


-- Conditionally print a message.
function printIfTrue(message, condition)
    if condition then
        tes3.messageBox(message)
    end
end

-- Check a variety of conditions that all must be met for wait to be possible.
function isWaitPossible(printMessages)
    -- Disallow waiting when the vanilla game would.
    if not tes3.canRest() then
        printIfTrue("Cannot rest while in danger!", printMessages)
        return false
    end

    -- Disallow waiting while moving.
    p = tes3.mobilePlayer
    if p.isRunning or p.isWalking or p.isSneaking or p.isSwimming or p.isJumping or p.isFlying then
        printIfTrue("Cannot rest while moving!", printMessages)
        return false
    end

    -- Otherwist let the player wait.
    return true
end


-- Start/stop the regen timer.
function startTimer()
    -- Create or restart the timer.
    if not regenTimer then
        regenTimer = timer.start{
            type = timer.real,
            duration = 0.1,
            iterations = -1,
            callback = onTimerTick
        }
    else
        regenTimer:resume()
        regenTimer:reset()
    end
    lastRegenTickReal = os.clock()
    lastRegenTickGame = tes3.findGlobal("GameHour").value
    -- Check if the player can regenerate magicka (no need to recheck every tick).
    -- Cannot be checked earlier either, e.g. on "loaded" event:
    -- what if the player has just started a new game and not selected the birthsign yet?
    isStunted = tes3.isAffectedBy{
        reference = tes3.player,
        effect = tes3.effect.stuntedMagicka,
    }
    isVampire = tes3.isAffectedBy{
        reference = tes3.player,
        effect = tes3.effect.vampirism,
    }
    -- Set the status flag.
    isWaiting = true
end

-- Try to stop the regen timer.
function stopTimer()
    if regenTimer then
        regenTimer:pause()
    end
    -- Set the status flag.
    isWaiting = false
end

-- Compute regen every timer tick.
function onTimerTick()
    -- Exit wait if something interrupted.
    if not isWaitPossible{printMessages = true} then
        common.changeTimescale(config.normalTimescale, config.debugMessages)
        stopTimer()
        return
    end

    -- Vanilla fatigue regen is real-time-based, hence independent of the timescale setting.
    -- To preserve this, we have to do the regen calculations with respect to the default timescale.
    local relativeTimescale = tes3.findGlobal("Timescale").value / config.normalTimescale
    local realTimeElapsed = os.clock() - lastRegenTickReal
    lastRegenTickReal = os.clock()
    
    -- Health and magicka regen is however game-time-based, thus we need separate clocks for that.
    local gameTimeElapsed = tes3.findGlobal("GameHour").value - lastRegenTickGame
    lastRegenTickGame = tes3.findGlobal("GameHour").value

    -- Restore fatigue according to vanilla rate of (2.5 + 0.02 * endurance) fatigue/sec.
    local fatigueRegenRate = 2.5 + 0.02 * tes3.mobilePlayer.endurance.current
    fatigueRegenRate = fatigueRegenRate / 2 -- a very arbitrary nerf but it's just SO OP otherwise
    local fatigueRegenAmount = fatigueRegenRate * realTimeElapsed * (relativeTimescale - 1) -- the game itself will add its own regen too
    -- Manually handle bounds, because the API does not control that...
    fatigueRegenAmount = math.max(0, math.min(fatigueRegenAmount, tes3.mobilePlayer.fatigue.base - tes3.mobilePlayer.fatigue.current))
    tes3.modStatistic{
        reference = tes3.mobilePlayer,
        name = "fatigue",
        current = fatigueRegenAmount,
    }

    -- Restore health and magicka when resting.
    if inLegalCell then
        -- Health only for non-vampire characters.
        if not isVampire then
            local healthRegenRate = 0.1 * tes3.mobilePlayer.health.base
            local healthRegenAmount = healthRegenRate * gameTimeElapsed
            healthRegenAmount = math.max(0, math.min(healthRegenAmount, tes3.mobilePlayer.health.base - tes3.mobilePlayer.health.current))
            tes3.modStatistic{
                reference = tes3.mobilePlayer,
                name = "health",
                current = healthRegenAmount,
            }
        end

        -- Magicka only for non-stunted characters.
        if not isStunted then
            local magickaRegenRate = 0.15 * tes3.mobilePlayer.intelligence.current
            local magickaRegenAmount = magickaRegenRate * gameTimeElapsed
            magickaRegenAmount = math.max(0, math.min(magickaRegenAmount, tes3.mobilePlayer.magicka.base - tes3.mobilePlayer.magicka.current))
            tes3.modStatistic{
                reference = tes3.mobilePlayer,
                name = "magicka",
                current = magickaRegenAmount,
            }
        end
    end
end

-- Handle key press/release events
local function keyCheck(e, state)
    -- Exit out if the player didn't press the correct key.
    if e.keyCode ~= config.waitHotkey.keyCode then
        return
    end

    -- We don't want to change the timescale when the menu is open.
    if tes3.menuMode() then
        return
    end

    -- Distinguish between pressing and releasing the hotkey.
    if state == "down" then
        -- Disallow wait when in combat
        if not isWaitPossible{printMessages = true} then
            return
        end
        
        -- Check if it's legal to rest here
        inLegalCell = not tes3.getPlayerCell().restingIsIllegal
        if not inLegalCell then
            tes3.messageBox("You cannot rest here, only wait.")
        end

        -- Apply the wait timescale and enable the regen timer.
        common.changeTimescale(config.waitTimescale, config.debugMessages)
        startTimer()
    else
        -- Set the default timescale and disable regen.
        common.changeTimescale(config.normalTimescale, config.debugMessages)
        stopTimer()
    end
end

-- Stop wait on attack.
function stopOnAttack(e)
    -- Ignore events from other actors.
    if (e.reference ~= tes3.player) then
        return
    end
    -- If we're waiting - interrupt.
    if isWaiting then
        tes3.messageBox("Cannot attack while waiting!")
        common.changeTimescale(config.normalTimescale, config.debugMessages)
        stopTimer()
    end
end

-- Stop wait on cast.
function stopOnCast(e)
    -- Ignore events from other actors.
    if (e.caster ~= tes3.player) then
        return
    end
    -- If we're waiting - interrupt.
    if isWaiting then
        tes3.messageBox("Cannot cast while waiting!")
        common.changeTimescale(config.normalTimescale, config.debugMessages)
        stopTimer()
    end
end

-- Stop wait on activation.
function stopOnActivate(e)
    if isWaiting then
        tes3.messageBox("Cannot do that while waiting!")
        common.changeTimescale(config.normalTimescale, config.debugMessages)
        stopTimer()
    end
end

-- Run each time any menu is opened.
function onMenuEnter()
    -- Needed to handle the case where the player opens the menu in Fast Forward mode.
    ---- tonumber() is needed because the text entry box in the MCM changes the value to a string in the config file.
    if tes3.findGlobal("Timescale").value ~= config.normalTimescale then
        common.changeTimescale(config.normalTimescale, config.debugMessages)
        stopTimer()
    end
end

-- Run each time any key is released.
function onKeyUp(e)
    keyCheck(e, "up")
end

-- Run each time any key is pressed down.
function onKeyDown(e)
    keyCheck(e, "down")
end

-- Set the timescale to the configured normal value on game load, adjust travel time if necessary.
function onLoaded()
    common.changeTimescale(config.normalTimescale, false)
    common.adjustTravelTimeIfConfigured()
end


-- Init
function onInitialized()
    event.register("loaded", onLoaded)
    event.register("keyDown", onKeyDown)
    event.register("keyUp", onKeyUp)
    event.register("menuEnter", onMenuEnter)
    event.register("attack", stopOnAttack)
    event.register("spellCast", stopOnCast)
    event.register("activate", stopOnActivate)
    mwse.log("[Immersive Wait 1.0.0] Initialized.")
end

event.register("initialized", onInitialized)
