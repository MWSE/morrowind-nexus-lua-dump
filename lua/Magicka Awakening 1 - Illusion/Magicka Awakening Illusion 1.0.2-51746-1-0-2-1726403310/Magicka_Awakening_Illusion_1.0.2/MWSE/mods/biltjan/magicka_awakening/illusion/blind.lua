--- Stolen Vision
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.blindEnabled
local blindMagnitudeMult = config.blindMagnitudeMult
local blindDurationMult = config.blindDurationMult
local illusionRequirement = config.blindIllusionRequirement

local function stolenVision(duration, durationMult, min, max)
  local spell = tes3.createObject{objectType = tes3.objectType.spell, getIfExists = false}
  tes3.setSourceless(spell)
  spell.alwaysSucceeds = true
  spell.name = "Stolen Vision"
  spell.castType = tes3.spellType.spell
  spell.magickaCost = 0
          local effect = spell.effects[1]
          effect.id = tes3.effect.fortifyAttack
          effect.min = math.floor(min)
          effect.max = math.floor(max)
          effect.radius = 0
          effect.rangeType = tes3.effectRange.self
          effect.duration = math.floor(duration * durationMult)
          effect.attribute =  -1
          effect.skill = -1
  return spell
end

--- Blind
--- @param e spellResistEventData
local function blindStealVision(e)
  -- Check if enabled
  if enabled then
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    local effect = e.effect
    if(effect.id == tes3.effect.blind) then
      if caster.illusion.base >= illusionRequirement then
        -- Main function
        local target = e.target.mobile
        if target.resistMagicka < 100 then
          -- durationMult will be rounded in the spell duration
          local durationMult = blindDurationMult / 100
          local min = e.effect.min * ((100 - target.resistMagicka)/100) * blindMagnitudeMult / 100
          local max = e.effect.max * ((100 - target.resistMagicka)/100) * blindMagnitudeMult / 100
          tes3.cast{reference = e.caster, instant = true, alwaysSucceeds = true, spell = stolenVision(effect.duration, durationMult, min, max), target = e.caster}
        end
      end
    end
  end
end

return blindStealVision