local types = require('openmw.types')
local core = require('openmw.core')
local o = require('scripts.knockback.settingsObject').o
local storage = require('openmw.storage')
local util = require('openmw.util')
local globalSection = storage.globalSection('KNOCKBACK_GLOBAL_SETTINGS')



local function spawnVFX(pos)
        local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.FireDamage]
        local model = types.Static.records[effect.areaStatic].model
        core.sendGlobalEvent('SpawnVfx', { model = model, position = pos })
end

---@class ActorData
---@field uv Vector3

return {
        eventHandlers = {
                ---@param data { actor: GameObject, nextPos: Vector3, res: RayCastingResult, ground: boolean  }
                ENEMY_KNOCKBACK = function(data)
                        local targetPos
                        targetPos = data.nextPos

                        -- local newRot = trans.rotateZ(data.actor.rotation:getPitch() + 0.45)

                        data.actor:teleport(data.actor.cell, targetPos,
                                { onGround = data.ground, rotation = data.rotation })

                        if globalSection:get(o.showTrail.key) == true then
                                spawnVFX(data.actor:getBoundingBox().center)
                        end

                        data.actor:sendEvent('TELE_DONE')
                end,
                SET_SETTINGS_VALUE = function(data)
                        globalSection:set(data.key, data.value)
                end
        },
}
