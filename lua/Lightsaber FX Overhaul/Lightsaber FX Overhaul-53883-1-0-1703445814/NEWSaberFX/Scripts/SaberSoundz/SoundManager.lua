local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')

local CSOSwishPrefix = "Sound\\Fx\\Item\\CSOSwing\\Swing"
local doSwish = false
local hasSaberEquipped = false
local inventory = types.Actor.inventory(self.object)
local sabers = {
  "sabrelaser_exarkun",
  "sabrelaser2_bastila",
  "sabrelaser2_exarkun",
  "sabrelaser2_maul",
  "sabrelaser_dooku",
  "sabrelaser_luke",
  "sabrelaser_marajade",
  "sabrelaser_obiwan",
  "sabrelaser_sith",
  "sabrelaser_vader",
  "sabrelaser_windu",
  "sabrelaser_yun"
}

local function soundManager()

  for _, id in pairs(sabers) do
    local saber = inventory:find(id)
    if saber and types.Actor.hasEquipped(self, saber) then
      hasSaberEquipped = true
      break
    end
    hasSaberEquipped = false
  end

  if not hasSaberEquipped then return end

  -- First, we listen for a specific sound and kill it if we find it.
  -- We also flip a marker on that indicates one of the two sound types was played.
  if core.sound.isSoundPlaying("SwishS", self) then
    core.sound.stopSound3d("SwishS", self)
    doSwish = true
  elseif core.sound.isSoundPlaying("SwishS", self) then
    core.sound.stopSound3d("SwishM", self)
    doSwish = true
  elseif  core.sound.isSoundPlaying("SwishL", self) then
    core.sound.stopSound3d("SwishL", self)
    doSwish = true
  elseif  core.sound.isSoundPlaying("Weapon Swish", self) then
    core.sound.stopSound3d("Weapon Swish", self)
    doSwish = true
  end

  if core.contentFiles.has("Combat Sounds Overhaul.esp")then
    for soundNum=1, 26 do
      if core.sound.isSoundFilePlaying(CSOSwishPrefix .. soundNum .. ".wav", self) then
        core.sound.stopSoundFile3d(CSOSwishPrefix .. soundNum .. ".wav", self)
        doSwish = true
      end
    end
  end

  -- Play the sound, and flip the marker back *off* so it doesn't play again
  if doSwish then
    core.sound.playSoundFile3d("Sound\\Vader\\SaberSoundz\\vader_hit" .. math.random(1, 26) .. ".wav", self)
    doSwish = false
  end

end


return {
  engineHandlers = {
    onUpdate = soundManager
  }
}
