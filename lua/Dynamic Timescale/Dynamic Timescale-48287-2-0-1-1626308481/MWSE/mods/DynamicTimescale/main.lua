local modInfo = require("DynamicTimescale.modInfo")
local config = require("DynamicTimescale.config")
local common = require("DynamicTimescale.common")

local waryCounter, stillState, stillCounter, isInInterior, isInDungeon, isInTown, isInNamed, speedUp

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

-- Runs each time any object is activated.
local function onActivate(e)

    -- Only increment waryCounter if the object is being activated by the player and the mod is configured to do so.
    if config.waryOnActivate and e.activator == tes3.player then
        waryCounterIncrement()
    end
end

-- Runs each time any actor takes damage.
local function onDamaged(e)

    -- Only increment waryCounter when the player is damaged sufficiently and the mod is configured to do so.
    if config.waryOnDamage
    and e.reference == tes3.player
    and e.damage >= ( tes3.mobilePlayer.health.base * 0.01 * config.damageThreshold ) then
        waryCounterIncrement()
    end
end

-- Runs each time a spell is cast by anybody.
local function onSpellCast(e)

    -- Only increment waryCounter if the spell is being cast by the player and the mod is configured to do so.
    if config.waryOnSpellCast and e.caster == tes3.player then
        waryCounterIncrement()
    end
end

-- Runs each time any actor (including the player) attacks with a weapon or fists.
local function onAttack(e)

    -- Only increment waryCounter if the attack is coming from or targeting the player and mod is configured to do so.
    if config.waryOnAttacks
    and ( e.reference == tes3.player or e.targetReference == tes3.player ) then
        waryCounterIncrement()
    end
end

-- Runs each time the travel service menu is opened. This function exists so gondola travel will use town instead of
-- wilderness timescale.
local function onTravelMenu()
    if tes3ui.getServiceActor().reference.object.class.id == "Gondolier" then

        -- If travel service provider is a gondolier, change GMST based on town timescale (depending on config setting).
        common.changeFastTravelTime(config.townTimescale)

        -- Then change it back after travel is complete.
        timer.start{
            duration = 0.1,
            callback = function()
                common.changeFastTravelTime(config.wildernessTimescale)
            end,
        }
    end
end

local function keyCheck(e, state)

    -- Exit out if the player didn't press the correct key.
    if e.keyCode ~= config.fastForwardHotkey.keyCode then
        return
    end

    -- We don't want to change the timescale when the menu is open.
    if tes3.menuMode() then
        return
    end

    -- Player just pressed down the hotkey.
    if state == "down" then

        -- If player is also holding control, Turbo timescale applies.
        if e.isControlDown then
            speedUp = "turbo"
        else
            speedUp = "fast forward"
        end

    -- Player just released the hotkey.
    else
        speedUp = "neither"
    end
end

-- Runs each time any menu is opened. Needed to handle the case where the player opens the menu while in Fast Forward /
-- Turbo mode.
local function onMenuEnter()
    if speedUp ~= "neither" then
        speedUp = "neither"
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

local function checkCell()
    if tes3.player.cell.isInterior then

        -- Default to dungeon cell if none of the conditions are true.
        isInInterior = false
        isInDungeon = true
        isInTown = false
        isInNamed = false

        -- This nil check is needed because only interior cells behaving as exteriors (e.g. Mournhold) have a region.
        if tes3.player.cell.region then

            -- Player is in one of the "exterior" Mournhold cells (that are technically interiors, but should be treated
            -- as city/town cells).
            if tes3.player.cell.region.name == "Mournhold Region" then
                isInDungeon = false
                isInTown = true
            end

        -- If resting is illegal, assume the player is in a city/town interior.
        elseif tes3.player.cell.restingIsIllegal then
            isInDungeon = false
            isInInterior = true

        -- This cell connects the Kogoruhn stronghold with a geographically distant exit, so "should" be much larger
        -- than depicted. Depending on mod configuration, this cell can be treated as a wilderness cell.
        elseif config.charmasBreathWilderness and tes3.player.cell.name == "Kogoruhn, Charma's Breath" then
            isInDungeon = false
        end

    -- Player is in an exterior cell.
    else

        -- Default to wilderness cell is none of the conditions are true.
        isInInterior = false
        isInDungeon = false
        isInTown = false
        isInNamed = false

        -- Exterior cells where resting is illegal are presumed to be part of a city/town.
        if tes3.player.cell.restingIsIllegal then
            isInTown = true

        -- Otherwise if the cell has a name, it's a named location (wilderness cells don't have names).
        elseif tes3.player.cell.name then
            isInNamed = true
        end
    end
end

-- Runs each time the player changes cells.
local function onCellChanged()
    checkCell()
end

local function changeTimescale()

    -- Get the previous timescale value to compare it to the new one.
    local oldTimescale = tes3.findGlobal("Timescale").value
    local newTimescale

    -- Player is holding control+hotkey.
    if speedUp == "turbo" then
        newTimescale = config.turboTimescale

    -- Player is holding hotkey without the control key.
    elseif speedUp == "fast forward" then
        newTimescale = config.fastForwardTimescale

    -- Player is in combat and the combat timescale is enabled.
    elseif config.enableCombatTimescale and tes3.mobilePlayer.inCombat then
        newTimescale = config.combatTimescale

    -- Player is in sneak mode and the sneaking timescale is enabled.
    elseif config.enableSneakingTimescale and tes3.mobilePlayer.isSneaking then
        newTimescale = config.sneakingTimescale

    -- Player is wary and the wary timescale is enabled.
    elseif config.enableWaryTimescale and waryCounter > 0 then
        newTimescale = config.waryTimescale

    -- Player has been still for at least config.stillTime seconds and the still timescale is enabled. stillCounter
    -- should never be < 0.
    elseif config.enableStillTimescale and stillCounter == 0 then
        newTimescale = config.stillTimescale

    -- None of the above apply, and the player is in a town interior cell (where resting is illegal).
    elseif isInInterior then
        newTimescale = config.interiorTimescale

    -- Player is in a dungeon interior cell (where resting is legal) and none of the above apply.
    elseif isInDungeon then
        newTimescale = config.dungeonTimescale

    -- Player is in a town/city exterior cell (where resting is illegal) and none of the above apply.
    elseif isInTown then
        newTimescale = config.townTimescale

    -- Player is in a named exterior cell where resting is legal, and none of the above apply.
    elseif isInNamed then
        newTimescale = config.namedTimescale

    -- Wilderness timescale is the default (nothing else applies, player is in an exterior cell that's legal to rest in
    -- and has no specific name).
    else
        newTimescale = config.wildernessTimescale
    end

    -- If it's nighttime, and we're not in Fast Forward/Turbo mode, apply the night multiplier. tonumber() is needed
    -- because the text entry box in the MCM changes the value to a string in the config file.
    if speedUp == "neither"
    and ( tes3.findGlobal("GameHour").value >= tonumber(config.nightBegin)
    or tes3.findGlobal("GameHour").value <= tonumber(config.nightEnd) ) then
        newTimescale = newTimescale * config.nightMultiplier
    end

    -- If the timescale hasn't changed this frame, no need to actually set it.
    if tonumber(newTimescale) ~= oldTimescale then
        tes3.findGlobal("Timescale").value = tonumber(newTimescale)

        -- Display a messagebox with the new timescale if player has configured the mod to do so.
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

        -- No need to do anything if player remains still.
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

        -- No need to do anything if player continues moving.
        if not checkMoving() then

            -- Again, change state variable so this only happens once when the player stops moving.
            stillState = true

            -- Special case when config.stillTime is 0, because duration 0 on a timer is bad.
            if config.stillTime == 0 then
                stillCounter = stillCounter -1
            else

                -- Wait config.stillTime seconds after player stops moving, then decrement stillCounter by 1.
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

-- Runs every frame except when the menu is open.
local function onSimulate()

    -- Determine whether the player has been still for long enough to apply the still timescale.
    stillCount()

    -- Determine which timescale applies and change it if needed.
    changeTimescale()
end

local function onLoaded()

    -- Determine the type of cell the player is in.
    checkCell()

    -- Adjust the relevant GMST right away depending on MCM settings.
    common.changeFastTravelTime(config.wildernessTimescale)

    -- Variable cleanup on game load.
    waryCounter = 0
    speedUp = "neither"

    -- Player is initially still.
    stillState = true

    -- Apply still timescale immediately if player has set config.stillTime to 0.
    if config.stillTime == 0 then
        stillCounter = 0
    else

        -- Otherwise, act as though the player just stopped moving. It will be at least config.stillTime seconds before
        -- the still timescale is applied.
        stillCounter = 1
        timer.start{
            duration = config.stillTime,
            callback = function()
                stillCounter = stillCounter - 1
            end,
        }
    end
end

local function onInitialized()
    event.register("loaded", onLoaded)
    event.register("cellChanged", onCellChanged)
    event.register("attack", onAttack)
    event.register("spellCast", onSpellCast)
    event.register("damaged", onDamaged)
    event.register("activate", onActivate)
    event.register("keyDown", onKeyDown)
    event.register("keyUp", onKeyUp)
    event.register("menuEnter", onMenuEnter)
    event.register("uiActivated", onTravelMenu, { filter = "MenuServiceTravel" })
    event.register("simulate", onSimulate)
    mwse.log("[%s %s] Initialized.", modInfo.mod, modInfo.version)
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("DynamicTimescale.mcm")
end

event.register("modConfigReady", onModConfigReady)