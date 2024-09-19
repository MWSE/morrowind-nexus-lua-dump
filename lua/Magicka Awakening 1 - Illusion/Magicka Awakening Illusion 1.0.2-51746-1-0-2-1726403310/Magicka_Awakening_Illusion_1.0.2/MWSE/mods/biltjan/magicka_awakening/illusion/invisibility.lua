--- Persisting Shadows
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.invisibilityEnabled
local invisibilityDurationRate = config.invisibilityDurationRate
local illusionRequirement = config.invisibilityIllusionRequirement

-- "Constants"
local maxChameleonMagnitude = 100
local minMagnitudeConstant = 10
local maxMagnitudeConstant = 15

-- Chameleon Spell
local function persistingShadows(duration, min, max)
  local spell = tes3.createObject{objectType = tes3.objectType.spell, getIfExists = false}
  tes3.setSourceless(spell)
  spell.alwaysSucceeds = true
  spell.name = "Persisting Shadows"
  spell.castType = tes3.spellType.spell
  spell.magickaCost = 0
  local effect = spell.effects[1]
  effect.id = tes3.effect.chameleon
  effect.min = min
  effect.max = max
  effect.radius = 0
  effect.rangeType = tes3.effectRange.touch
  effect.duration = math.floor(duration/invisibilityDurationRate)
  effect.attribute =  -1
  effect.skill = -1
  return spell
end

--- Invisibility
--- @param e magicEffectRemovedEventData
local function invisibilityBreak(e)
  -- Check if enabled
  if enabled then 
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    local effect = e.effect
    if effect.object.id == tes3.effect.invisibility then
      if caster.illusion.base >= illusionRequirement then
        -- Main function
        local target = e.mobile
        local min = math.min(minMagnitudeConstant + math.floor(caster.illusion.current/2) + math.floor(caster.personality.current/4) + math.floor(caster.luck.current/10), maxChameleonMagnitude)
        local max = math.min(maxMagnitudeConstant + math.floor(caster.illusion.current) + math.floor(caster.personality.current/4) + math.floor(caster.luck.current/10), maxChameleonMagnitude)
        local function castSpell()
          tes3.cast{reference = e.caster, instant = true, alwaysSucceeds = true, spell = persistingShadows(effect.duration, min, max), target = target}
        end 

        timer.register("castDelay", castSpell)
        timer.start({
            type = timer.active,
            persist = true,
            iterations = 1,
            duration = 0.2,
            callback = "castDelay"
        })
      end
    end
  end
end

return invisibilityBreak
