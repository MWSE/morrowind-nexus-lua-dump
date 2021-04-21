local mod = "Take a Hike"
local version = "1.0.2"

local config = require("TakeAHike.config")

local oldCell, oldPosition, oldOrientation, magicFailMessage

--Called from onInfoResponse when it's time to teleport the player back to their original position.
local function teleportBack()

    -- Position the player where they were before.
    tes3.positionCell({
        reference = tes3.mobilePlayer,
        cell = oldCell,
        position = oldPosition,
        orientation = oldOrientation,
        teleportCompanions = false
    })

    -- Fade in from black so the player can see.
    tes3.fadeIn{duration = 1.0}
end

-- Runs on every dialogue response (topic, choice, greeting, voice greeting).
local function onInfoResponse(e)

    -- The player has turned off this option, so do nothing.
    if not config.disableJailTransport then
        return
    end

    --Checks the result text for "gotojail", which is the hardcoded function Morrowind uses to send the player to jail, confiscate stolen items, reduce skills, and so on.
    if e.command:lower():find("^gotojail") then

        --Obtain the player's current position (this occurs before the player is teleported to the prison marker).
        oldCell = tes3.getPlayerCell()
        oldPosition = tes3.player.position:copy()
        oldOrientation = tes3.player.orientation:copy()

        -- Fade to black so the player won't notice the teleportation.
        tes3.fadeOut{duration = 0.5}

        --Wait long enough for the player to have been teleported to the prison marker before teleporting them back.
        timer.start{
            duration = 0.1,
            callback = teleportBack
        }
    end
end

--Runs each time any source of magic effects (spells, enchanted items, scrolls, potions, ingredients) is used.
local function onMagicCasted(e)

    -- The player has turned off this option, so do nothing.
    if not config.disableTeleport then
        return
    end

    -- It's not the player using the magic source, so we don't care.
    if e.caster ~= tes3.player then
        return
    end

    -- This is a spell, so we don't care (spells are handled in onSpellCast).
    if e.sourceInstance.sourceType == 1 then
        return
    end

    local isTeleport = false
    local almsiviNum = nil
    local divineNum = nil
    local recallNum = nil

    --Check each effect to see if it includes a teleportation effect (and remember which effect that is).
    for i = 1, #e.source.effects do
        if e.source.effects[i].id == tes3.effect.almsiviIntervention then
            isTeleport = true
            almsiviNum = i
        elseif e.source.effects[i].id == tes3.effect.divineIntervention then
            isTeleport = true
            divineNum = i
        elseif e.source.effects[i].id == tes3.effect.recall then
            isTeleport = true
            recallNum = i
        end
    end

    -- Not teleportation, so we don't care.
    if not isTeleport then
        return
    end

    --Change the teleportation effect to Reflect (it will only be 1 point for 1 second) to prevent the player from teleporting.
    if almsiviNum then
        e.sourceInstance.source.effects[almsiviNum].id = tes3.effect.reflect
    end

    if divineNum then
        e.sourceInstance.source.effects[divineNum].id = tes3.effect.reflect
    end

    if recallNum then
        e.sourceInstance.source.effects[recallNum].id = tes3.effect.reflect
    end

    tes3.messageBox("The aether refuses to allow you to mingle with it.")

    -- Play the spell failure sound.
    tes3.playSound{
        sound = "Spell Failure Mysticism",
        reference = tes3.player,
    }

    -- Wait for the effect to be applied.
    timer.start{
        duration = 0.1,
        callback = function()

            -- Cancel the hit sound for the Reflect effect.
            tes3.removeSound{
                sound = "mysticism hit",
                reference = tes3.player,
            }

            --Change the effect for this item back to the original teleportation effect (otherwise a Recall amulet would be converted to a Reflect amulet for example).
            if almsiviNum then
                e.sourceInstance.source.effects[almsiviNum].id = tes3.effect.almsiviIntervention
            end

            if divineNum then
                e.sourceInstance.source.effects[divineNum].id = tes3.effect.divineIntervention
            end

            if recallNum then
                e.sourceInstance.source.effects[recallNum].id = tes3.effect.recall
            end
        end,
    }
end

--Runs each time a regular spell is cast, before success or failure is determined.
local function onSpellCast(e)

    -- The player has turned off this option, so do nothing.
    if not config.disableTeleport then
        return
    end

    -- If it's not the player casting the spell, we don't care.
    if e.caster ~= tes3.player then
        return
    end

    local isTeleport = false

    --Check each of the spell's effects to see if it includes a teleportation effect.
    for i = 1, #e.source.effects do
        if e.source.effects[i].id == tes3.effect.almsiviIntervention
        or e.source.effects[i].id == tes3.effect.divineIntervention
        or e.source.effects[i].id == tes3.effect.recall then
            isTeleport = true
            break
        end
    end

    -- This is not a teleportation spell, so we don't care.
    if not isTeleport then
        return
    end

    -- Force the spell to fail.
    e.castChance = 0

    -- Restore the magicka the player expended to cast the spell.
    tes3.modStatistic{
        reference = tes3.player,
        name = "magicka",
        current = e.source.magickaCost,
    }

    -- Change this GMST so our custom failure message will be displayed.
    tes3.findGMST("sMagicSkillFail").value = "The aether refuses to allow you to mingle with it."

    -- Wait for the failure message to be displayed then change the GMST back.
    timer.start{
        duration = 0.1,
        callback = function()
            tes3.findGMST("sMagicSkillFail").value = magicFailMessage
        end,
    }
end

local function onInitialized()
    event.register("spellCast", onSpellCast)
    event.register("magicCasted", onMagicCasted)
    event.register("infoResponse", onInfoResponse)

    magicFailMessage = tes3.findGMST("sMagicSkillFail").value

    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)

-- Register the mod config menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\TakeAHike\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)