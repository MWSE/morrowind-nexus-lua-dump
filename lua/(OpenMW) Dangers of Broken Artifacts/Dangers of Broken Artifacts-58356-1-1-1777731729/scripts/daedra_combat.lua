local AI    = require('openmw.interfaces').AI
local self  = require('openmw.self')
local core  = require('openmw.core')
local types = require('openmw.types')
local anim  = require('openmw.animation')
local async = require('openmw.async')

local target = nil
local deathHandled = false

local VFX_SUMMON_START = 'VFX_Summon_Start'
local VFX_SUMMON_END   = 'VFX_Summon_End'
local VFX_PARTICLE     = 'vfx_conj_flare02.tga'

local function playStaticVfx(staticId, opts)
    opts = opts or {}
    pcall(function()
        local rec = types.Static.records[staticId]
        if rec and rec.model then
            anim.addVfx(self, rec.model, {
                particleTextureOverride = opts.particleTexture,
                loop = opts.loop,
                vfxId = opts.vfxId,
            })
        end
    end)
end

local spawnVfxPlayed = false
local function playSpawnVfx()
    if spawnVfxPlayed then return end
    playStaticVfx(VFX_SUMMON_START, { particleTexture = VFX_PARTICLE })
    spawnVfxPlayed = true
end

local function playDeathVfx()
    playStaticVfx(VFX_SUMMON_END, { particleTexture = VFX_PARTICLE })
end

local function handleDeath()
    if deathHandled then return end
    deathHandled = true

    playDeathVfx()

    async:newUnsavableSimulationTimer(1, function()
        if target and target:isValid() then
            target:sendEvent("CursedItem_PlayDeathSound", {})
        end
        core.sendGlobalEvent("CursedItem_DaedraDied", {
            daedra = self,
            actor  = target,
        })
    end)
end

return {
    engineHandlers = {
        onSave = function()
            return {
                target = target,
                deathHandled = deathHandled,
                spawnVfxPlayed = spawnVfxPlayed,
            }
        end,
        onLoad = function(saved)
            if not saved then return end
            target = saved.target
            deathHandled = saved.deathHandled or false
            spawnVfxPlayed = saved.spawnVfxPlayed or false
            if types.Actor.isDead(self) and not deathHandled then
                handleDeath()
            elseif types.Actor.isDead(self) then
                core.sendGlobalEvent("CursedItem_DaedraDied", {
                    daedra = self,
                    actor  = target,
                })
            end
        end,
    },

    eventHandlers = {
        CursedItem_Attack = function(data)
            target = data.target
            AI.startPackage({
                type   = "Combat",
                target = target,
            })
        end,
        CursedItem_PlayVFX_Self = function()
            playSpawnVfx()
        end,
        Died = function()
            handleDeath()
        end,
        CursedItem_Follow = function(data)
            target = data.target
            AI.startPackage({
                type = "Follow",
                target = target,
                cancelOther = true,
            })
        end,
        CursedItem_Despawn_VFX = function()
            playDeathVfx() 
        end,
    }
}