local function blinkTeleport()
    local player = tes3.player
    local eyePos = player.position + tes3vector3.new(0, 0, 128)
    local dir = tes3.getPlayerEyeVector()

    local rayResult = tes3.rayTest{
        position = eyePos,
        direction = dir,
        distance = 1000,
        ignore = { player }
    }

    if rayResult and rayResult.intersection then
        -- Add a small Z offset so you don't clip into the floor
        local targetPos = rayResult.intersection + tes3vector3.new(0, 0, 16)

        tes3.positionCell{
            reference = player,
            position = targetPos,
            cell = rayResult.cell or player.cell -- fallback to current cell
        }

        tes3.playSound{ sound = "mysticism cast" }
        tes3.createVisualEffect{ reference = player, effect = "VFX_Summon" }
    else
        tes3.messageBox("Blink failed - no valid target.")
    end
end



event.register("spellCast", function(e)
    if e.source.id == "blinkTelep" then
        blinkTeleport()
        return false
    end
end)
