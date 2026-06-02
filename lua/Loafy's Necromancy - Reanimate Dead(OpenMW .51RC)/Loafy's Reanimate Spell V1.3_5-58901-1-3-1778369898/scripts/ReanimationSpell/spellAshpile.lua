local self      = require('openmw.self')
local core      = require('openmw.core')
local types     = require('openmw.types')
local anim      = require('openmw.animation')
local util      = require('openmw.util')
local vfs       = require('openmw.vfs')

local vfxTimer = 0
local playedOnce = false

local function onInit()
   
end


local function onUpdate(dt)
local containerInv = types.Container.inventory(self)
local allItems     = containerInv:getAll()
local vfxInterval = 1.7


local ashSmokeEffect = "ReanimationSpell/vfx_ashsmoke.dds"
  if #allItems == 0 then 
     core.sendGlobalEvent("clearZombieRemains", self)
    end

     vfxTimer = vfxTimer + dt
        local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Blind]
        local pos = self.position + util.vector3(0, 0, -75)
        local model = types.Static.records[effect.hitStatic].model
        if not playedOnce then
          core.sendGlobalEvent('SpawnVfx', {
            model = model, 
            position = pos, 

            options = {
                 useAmbientLight = true, 
                 vfxId = "ashpileglow",
                 scale = 1,
                 mwMagicVfx = false,
                 particleTextureOverride = ashSmokeEffect
                }})  
                 core.sound.playSound3d("fire", self, {
                    loop = false,
                    volume = 1.5,
                    pitch = 0.3, 
                    lazy = true   
                    })
          playedOnce = true
        end
    if vfxTimer >= vfxInterval then
        vfxTimer = 0
         core.sound.stopSound3d("fire",self)
    
          core.sendGlobalEvent('SpawnVfx', {
            model = model, 
            position = pos, 

            options = {
                 useAmbientLight = true, 
                 mwMagicVfx = false,
                 vfxId = "ashpileglow",
                 scale = 1,
                 particleTextureOverride = ashSmokeEffect
                
                }})  
    end
end

return {    
    engineHandlers = {
    onUpdate = onUpdate,
    onInit = onInit
   }
}