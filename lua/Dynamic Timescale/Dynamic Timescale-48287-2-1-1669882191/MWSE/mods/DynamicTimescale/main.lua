local modInfo = require("DynamicTimescale.modInfo")
local config = require("DynamicTimescale.config")
local common = require("DynamicTimescale.common")
local interop = require("DynamicTimescale.interop")

local waryCounter, stillState, stillCounter, isInInterior, isInDungeon, isInTown, isInNamed, speedUp

local keyStates = {
    neither = 0,
    fastForward = 1,
    turbo = 2,
}

local function waryCounterIncrement()

    -- waryCounter represents the number of wariness-triggering events that have occured within the past config.waryTime
    -- seconds. Player is wary when waryCounter > 0. (waryCounter should never be < 0.) When any wariness-triggering
    -- event occurs, increment waryCounter, wait config.waryTime seconds, then decrement waryCounter.
    waryCounter = waryCounter + 1
    timer.start{
        duration = config.waryTime,
        callback = function()
            waryCounter = waryCounter - 1
        end,
    }
end

local function onActivate(e)
    if config.waryOnActivate and e.activator == tes3.player then
        waryCounterIncrement()
    end
end

local function onDamaged(e)
    if config.waryOnDamage
    and e.reference == tes3.player
    and e.damage >= ( tes3.mobilePlayer.health.base * 0.01 * config.damageThreshold ) then
        waryCounterIncrement()
    end
end

local function onSpellCast(e)
    if config.waryOnSpellCast and e.caster == tes3.player then
        waryCounterIncrement()
    end
end

local function onAttack(e)
    if config.waryOnAttacks
    and ( e.reference == tes3.player or e.targetReference == tes3.player ) then
        waryCounterIncrement()
    end
end

-- This function exists so gondola travel will use town instead of wilderness timescale.
local function onTravelMenu()
    if tes3ui.getServiceActor().reference.object.class.id == "Gondolier" then
        common.changeFastTravelTime(config.townTimescale)

        timer.start{
            duration = 0.1,
            callback = function()
                common.changeFastTravelTime(config.wildernessTimescale)
            end,
        }
    end
end

local function keyCheck(e, down)
    if e.keyCode ~= config.fastForwardHotkey.keyCode then
        return
    end

    if tes3.menuMode() then
        return
    end

    if down then
        if e.isControlDown then
            speedUp = keyStates.turbo
        else
            speedUp = keyStates.fastForward
        end
    else
        speedUp = keyStates.neither
    end
end

-- Needed to handle the case where the player opens the menu while in Fast Forward / Turbo mode.
local function onMenuEnter()
    speedUp = keyStates.neither
end

local function onKeyUp(e)
    keyCheck(e, false)
end

local function onKeyDown(e)
    keyCheck(e, true)
end

local function checkCell()
    if tes3.player.cell.isInterior then
        -- Default to dungeon cell if none of the conditions are true.
        isInInterior = false
        isInDungeon = true
        isInTown = false
        isInNamed = false

        -- This nil check is needed because only interior cells behaving as exteriors (e.g. Mournhold) have a region.
        if tes3.player.cell.region then
            if tes3.player.cell.region.name == "Mournhold Region" then
                isInDungeon = false
                isInTown = true
            end

        elseif tes3.player.cell.restingIsIllegal then
            isInDungeon = false
            isInInterior = true

        -- This cell connects the Kogoruhn stronghold with a geographically distant exit, so "should" be much larger
        -- than depicted. Depending on mod configuration, this cell can be treated as a wilderness cell.
        elseif config.charmasBreathWilderness and tes3.player.cell.name == "Kogoruhn, Charma's Breath" then
            isInDungeon = false
        end
    else
        -- Default to wilderness cell is none of the conditions are true.
        isInInterior = false
        isInDungeon = false
        isInTown = false
        isInNamed = false

        if tes3.player.cell.restingIsIllegal then
            isInTown = true

        -- Wilderness cells don't have names.
        elseif tes3.player.cell.name then
            isInNamed = true
        end
    end
end

local function onCellChanged()
    checkCell()
end

local function changeTimescale()
    local oldTimescale = tes3.findGlobal("Timescale").value
    local newTimescale

    -- If another mod has blocked Dynamic Timescale, then skip this whole thing.
    for _, block in pairs (interop.blocks) do
        if block then
            return
        end
    end

    if speedUp == keyStates.turbo then
        newTimescale = config.turboTimescale
    elseif speedUp == keyStates.fastForward then
        newTimescale = config.fastForwardTimescale
    elseif config.enableCombatTimescale and tes3.mobilePlayer.inCombat then
        newTimescale = config.combatTimescale
    elseif config.enableSneakingTimescale and tes3.mobilePlayer.isSneaking then
        newTimescale = config.sneakingTimescale
    elseif config.enableWaryTimescale and waryCounter > 0 then
        newTimescale = config.waryTimescale
    -- stillCounter should never be < 0.
    elseif config.enableStillTimescale and stillCounter == 0 then
        newTimescale = config.stillTimescale
    elseif isInInterior then
        newTimescale = config.interiorTimescale
    elseif isInDungeon then
        newTimescale = config.dungeonTimescale
    elseif isInTown then
        newTimescale = config.townTimescale
    elseif isInNamed then
        newTimescale = config.namedTimescale
    else
        newTimescale = config.wildernessTimescale
    end

    -- If it's nighttime, and we're not in Fast Forward/Turbo mode, apply the night multiplier. tonumber() is needed
    -- because the text entry box in the MCM changes the value to a string in the config file.
    if speedUp == keyStates.neither
    and ( tes3.findGlobal("GameHour").value >= tonumber(config.nightBegin)
    or tes3.findGlobal("GameHour").value <= tonumber(config.nightEnd) ) then
        newTimescale = newTimescale * config.nightMultiplier
    end

    if tonumber(newTimescale) ~= oldTimescale then
        tes3.findGlobal("Timescale").value = tonumber(newTimescale)

        if config.displayMessages then
            tes3.messageBox("Timescale is now %.0f.", tes3.findGlobal("Timescale").value)
        end
    end
end

-- Returns true only when the player is not moving. No need to check isSwimming, because isWalking or isRunning will
-- also be true if the player is moving in the water. isWalking is always true when isSneaking is true, whether the
-- player is moving or not, so the player will never be considered still while in sneak mode.
local function checkMoving()
    return tes3.mobilePlayer.isWalking
    or tes3.mobilePlayer.isRunning
    or tes3.mobilePlayer.isJumping
    or tes3.mobilePlayer.isFlying
end

local function stillCount()
    -- Player was still the previous frame.
    if stillState then
        if checkMoving() then
            -- Change state variable so this only happens once when the player starts moving.
            stillState = false

            -- stillCounter is incremented by 1 when the player starts moving, and decremented by 1 config.stillTime
            -- seconds after they stop moving. Therefore it's only 0 if the player is currently still *and* has been
            -- still for at least config.stillTime. Player has just started to move, so increment stillCounter.
            stillCounter = stillCounter + 1
        end

    -- Player was moving the previous frame.
    else
        if not checkMoving() then
            -- Again, change state variable so this only happens once when the player stops moving.
            stillState = true

            -- Special case when config.stillTime is 0, because duration 0 on a timer is bad.
            if config.stillTime == 0 then
                stillCounter = stillCounter -1
            else
                timer.start{
                    duration = config.stillTime,
                    callback = function()
                        stillCounter = stillCounter - 1
                    end
                }
            end
        end
    end
end

local function onSimulate()
    stillCount()
    changeTimescale()
end

local function onLoaded()
    checkCell()
    common.changeFastTravelTime(config.wildernessTimescale)

    -- Variable cleanup on game load.
    waryCounter = 0
    speedUp = keyStates.neither

    -- Player is initially still.
    stillState = true

    -- Apply still timescale immediately if player has set config.stillTime to 0.
    if config.stillTime == 0 then
        stillCounter = 0
    -- Otherwise, act as though the player just stopped moving. It will be at least config.stillTime seconds before the
    -- still timescale is applied.
    else
        stillCounter = 1
        timer.start{
            duration = config.stillTime,
            callback = function()
                stillCounter = stillCounter - 1
            end,
        }
    end
end

-- Remove all blocks on game load. This allows other mods to (re)instate their blocks on loaded.
local function onLoad()
    interop.blocks = {}
end

local function onInitialized()
    event.register(tes3.event.load, onLoad)
    event.register(tes3.event.loaded, onLoaded)
    event.register(tes3.event.cellChanged, onCellChanged)
    event.register(tes3.event.attack, onAttack)
    event.register(tes3.event.spellCast, onSpellCast)
    event.register(tes3.event.damaged, onDamaged)
    event.register(tes3.event.activate, onActivate)
    event.register(tes3.event.keyDown, onKeyDown)
    event.register(tes3.event.keyUp, onKeyUp)
    event.register(tes3.event.menuEnter, onMenuEnter)
    event.register(tes3.event.uiActivated, onTravelMenu, { filter = "MenuServiceTravel" })
    event.register(tes3.event.simulate, onSimulate)
    mwse.log("[%s %s] Initialized.", modInfo.mod, modInfo.version)
end

event.register(tes3.event.initialized, onInitialized)

local function onModConfigReady()
    dofile("DynamicTimescale.mcm")
end

event.register(tes3.event.modConfigReady, onModConfigReady)