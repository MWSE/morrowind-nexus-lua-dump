--- Enfeebling Light
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.lightEnabled
local lightMagnitudeRate = config.lightMagnitudeRate
local illusionRequirement = config.lightIllusionRequirement

-- Drain Willpower Spell
local function enfeeblingLight(duration, min, max)
  local spell = tes3.createObject{objectType = tes3.objectType.spell, getIfExists = false}
  tes3.setSourceless(spell)
  spell.alwaysSucceeds = true
  spell.name = "Enfeebling Light"
  spell.castType = tes3.spellType.spell
  spell.magickaCost = 0
  local effect = spell.effects[1]
  effect.id = tes3.effect.drainAttribute
  effect.min = min
  effect.max = max
  effect.radius = 0
  effect.rangeType = tes3.effectRange.touch
  effect.duration = duration
  effect.attribute =  2
  effect.skill = -1
  return spell
end

--- Light
--- @param e spellResistEventData
local function light(e)
  -- Check if enabled
  if enabled then
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    local effect = e.effect
    if ( effect.id == tes3.effect.light ) then
      if (caster.illusion) then
        if caster.illusion.base >= illusionRequirement then
          -- Main function
          local target = e.target
          if target.mobile.resistMagicka < 100 then
            if(caster ~= target) then
              local min = math.floor(e.effect.min / lightMagnitudeRate)
              local max = math.floor(e.effect.max / lightMagnitudeRate)
              tes3.cast{reference = target, instant = true, alwaysSucceeds = true, spell = enfeeblingLight(effect.duration, min, max), target = target}
            end
          end
        end
      end
    end
  end
end

return light

-- TODO: Maybe make a clean up when light effect is removed
