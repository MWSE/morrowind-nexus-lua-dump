if not require("scripts.TamrielData.utils.version_check").isFeatureSupported("miscSpells") then
    return
end

local types = require('openmw.types')
local world = require('openmw.world')
local crimes = require('openmw.interfaces').Crimes

local function triggerCrimeIfTrespassing(data)
    if not data.targetObject or not data.targetObject.owner or not types.Lockable.isLocked(data.targetObject) then
        return
    end

    if data.targetObject.globalVariable and world.mwscript.getGlobalVariables(data.player)[data.targetObject.globalVariable] ~= 0 then
        return
    end

    local ownerData = data.targetObject.owner

    local isTrespassing =
        ownerData.recordId
        or
        (ownerData.factionId and types.NPC.getFactionRank(data.player, ownerData.factionId) == 0)
        or
        (ownerData.factionId and types.NPC.getFactionRank(data.player, ownerData.factionId) < (ownerData.factionRank or 1))

    if isTrespassing then
        crimes.commitCrime(
            data.player,
            {
                faction = ownerData.factionId,
                type = types.Player.OFFENSE_TYPE.Trespassing
            }
        )
    end
end

local function teleportPlayer(data)
    data.player:teleport(data.cell, data.position, { onGround = true, rotation = data.rotation })

    triggerCrimeIfTrespassing(data)

    local passwall_target_effect_model = types.Static.records[data.vfxStatic].model
    world.vfx.spawn(passwall_target_effect_model, data.position)
end

return {
    eventHandlers = {
        T_Passwall_teleportPlayer = teleportPlayer,
    }
}
