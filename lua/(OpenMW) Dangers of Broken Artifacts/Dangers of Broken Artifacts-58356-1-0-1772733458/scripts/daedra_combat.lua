local AI    = require('openmw.interfaces').AI
local self  = require('openmw.self')
local core  = require('openmw.core')
local types = require('openmw.types')
local anim  = require('openmw.animation')

local deathReported = false
local deathTime     = nil
local target        = nil

local summonMgef = core.magic.effects.records[core.magic.EFFECT_TYPE.SummonScamp]

local function playSummonVfx()
    if summonMgef and summonMgef.castStatic then
        local modelPath = types.Static.record(summonMgef.castStatic).model
        
        anim.addVfx(self, modelPath, {
            particleTextureOverride = "textures/vfx_summon.dds",
            loop = false
        })
        
        anim.addVfx(self, modelPath, {
            particleTextureOverride = "textures/vfx_summon_glow.dds",
            loop = false
        })
    end
end

return {
    eventHandlers = {
        CursedItem_Attack = function(data)
            target = data.target
            AI.startPackage({
                type   = "Combat",
                target = target
            })
        end,
        CursedItem_PlayVFX_Self = function()
            playSummonVfx()
        end
    },
    engineHandlers = {
        onUpdate = function()
            if deathTime then
                if core.getSimulationTime() - deathTime >= 1 then
                    if target and target:isValid() then
                        target:sendEvent("CursedItem_PlayDeathSound", {})
                    end
                    core.sendGlobalEvent("CursedItem_DaedraDied", {
                        daedra = self,
                        actor  = target
                    })
                    deathTime = nil
                end
                return
            end
            
            if not deathReported then
                local health = types.Actor.stats.dynamic.health(self).current
                if health <= 0 then
                    deathReported = true
                    deathTime = core.getSimulationTime()
                    playSummonVfx()
                end
            end
        end
    }
}