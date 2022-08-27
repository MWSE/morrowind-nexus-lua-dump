--- Paralyzing Torpor
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.silenceEnabled
local paralyzeDurationRate = config.paralyzeDurationRate
local illusionRequirement = config.paralyzeIllusionRequirement

-- "Constants"
local maxDrainMagnitude = 200
local minMagnitudeConstant = 10
local maxMagnitudeConstant = 15

-- Drain Speed Spell
local function torpor(duration, min, max)
  local spell = tes3.createObject{objectType = tes3.objectType.spell, getIfExists = false}
  tes3.setSourceless(spell)
  spell.alwaysSucceeds = true
  spell.name = "Paralyzing Torpor"
  spell.castType = tes3.spellType.spell
  spell.magickaCost = 0
  local effect = spell.effects[1]
  effect.id = tes3.effect.drainAttribute
  effect.min = min
  effect.max = max
  effect.radius = 0
  effect.rangeType = tes3.effectRange.touch
  effect.duration = math.floor(duration/paralyzeDurationRate)
  effect.attribute =  4
  effect.skill = -1
  return spell
end

--- Silence
--- @param e magicEffectRemovedEventData
local function paralyzeBreak(e)
  -- Check if enabled
  if enabled then 
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    if caster.illusion.base >= illusionRequirement then
      -- Main function
      local target = e.mobile
      local effect = e.effect
      if ( effect.object.id == tes3.effect.paralyze ) and (target.resistParalysis < 100) then
        local min = math.min((minMagnitudeConstant + math.floor(caster.illusion.current/2) + math.floor(caster.personality.current/4) + math.floor(caster.luck.current/10)) * ((100 - target.resistParalysis)/100), maxDrainMagnitude)
        local max = math.min((maxMagnitudeConstant + math.floor(caster.illusion.current) + math.floor(caster.personality.current/4) + math.floor(caster.luck.current/10)) * ((100 - target.resistParalysis)/100), maxDrainMagnitude)
        tes3.cast{reference = e.caster, instant = true, alwaysSucceeds = true, spell = torpor(effect.duration, min, max), target = target}
      end
    end
  end
end

return paralyzeBreak
