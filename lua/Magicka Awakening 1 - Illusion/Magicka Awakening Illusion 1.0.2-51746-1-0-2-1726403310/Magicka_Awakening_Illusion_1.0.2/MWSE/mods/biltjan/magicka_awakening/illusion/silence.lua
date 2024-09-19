--- Deafening Silence
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.silenceEnabled
local silenceDurationRate = config.silenceDurationRate
local illusionRequirement = config.silenceIllusionRequirement

-- "Constants"
local maxSoundMagnitude = 100
local minMagnitudeConstant = 10
local maxMagnitudeConstant = 15

-- Sound Spell
local function deafeningSilence(duration, min, max)
  local spell = tes3.createObject{objectType = tes3.objectType.spell, getIfExists = false}
  tes3.setSourceless(spell)
  spell.alwaysSucceeds = true
  spell.name = "Deafening Silence"
  spell.castType = tes3.spellType.spell
  spell.magickaCost = 0
  local effect = spell.effects[1]
  effect.id = tes3.effect.sound
  effect.min = min
  effect.max = max
  effect.radius = 0
  effect.rangeType = tes3.effectRange.touch
  effect.duration = math.floor(duration/silenceDurationRate)
  effect.attribute =  -1
  effect.skill = -1
  return spell
end

--- Silence
--- @param e magicEffectRemovedEventData
local function silenceBreak(e)
  -- Check if enabled
  if enabled then 
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    local effect = e.effect
    if effect.object.id == tes3.effect.silence then
      if caster.illusion.base >= illusionRequirement then
        -- Main function
        local target = e.mobile
        if (target.resistMagicka < 100) then
          local min = math.min(minMagnitudeConstant + math.floor(caster.illusion.current/2) + math.floor(caster.personality.current/4) + math.floor(caster.luck.current/10), maxSoundMagnitude)
          local max = math.min(maxMagnitudeConstant + math.floor(caster.illusion.current) + math.floor(caster.personality.current/4) + math.floor(caster.luck.current/10), maxSoundMagnitude)
          tes3.cast{reference = e.caster, instant = true, alwaysSucceeds = true, spell = deafeningSilence(effect.duration, min, max), target = target}
        end
      end
    end
  end
end

return silenceBreak
