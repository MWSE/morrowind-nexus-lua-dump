local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')

local doSwish = false
local doHit = false

local function soundManager()

if not types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight) then return
end

  if core.sound.isSoundPlaying("Weapon Swish", self) then
    core.sound.stopSound3d("Weapon Swish", self)
    doSwish = true
  elseif core.sound.isSoundPlaying("SwishM", self) then
    core.sound.stopSound3d("SwishM", self)
    doSwish = true
  elseif  core.sound.isSoundPlaying("SwishL", self) then
    core.sound.stopSound3d("SwishL", self)
    doSwish = true
  elseif core.sound.isSoundPlaying("SwishS", self) then
    core.sound.stopSound3d("SwishS", self)
    doSwish = true
  elseif core.sound.isSoundPlaying("Light Armor Hit", self) then
    core.sound.stopSound3d("Light Armor Hit", self)
    doHit = true
  elseif core.sound.isSoundPlaying("Medium Armor Hit", self) then
    core.sound.stopSound3d("Medium Armor Hit", self)
    doHit = true
  elseif core.sound.isSoundPlaying("Heavy Armor Hit", self) then
    core.sound.stopSound3d("Heavy Armor Hit", self)
    doHit = true
  end

  if doSwish then
    core.sound.playSoundFile3d("Sound\\Fx\\Item\\CSOswing\\Swing" .. math.random(1, 26) .. ".wav", self)
    doSwish = false
  end

  if doHit then
    core.sound.playSoundFile3d("Sound\\Fx\\Item\\CSOhit\\hit" .. math.random(1, 102) .. ".wav", self)
    doHit = false
  end

end


return {
  engineHandlers = {
    onUpdate = soundManager
  }
}
