local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')

local doSwish = false
local doHit = false

local muted = {}
local swishSounds = {
  "Weapon Swish",
  "SwishM",
  "SwishL",
  "SwishS",
}
local hitSounds = {
  "Light Armor Hit",
  "Medium Armor Hit",
  "Heavy Armor Hit",
}

local function soundManager()
  if not types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight) then return end

  for _, sound in ipairs(swishSounds) do
    if core.sound.isSoundPlaying(sound, self) then
      if not muted[sound] then
        core.sound.playSound3d(sound, self, { volume = 0 })
        doSwish = true
        muted[sound] = true
      end
    else
      muted[sound] = nil
    end
  end
  for _, sound in ipairs(hitSounds) do
    if core.sound.isSoundPlaying(sound, self) then
      if not muted[sound] then
        core.sound.playSound3d(sound, self, { volume = 0 })
        doHit = true
        muted[sound] = true
      end
    else
      muted[sound] = nil
    end
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
