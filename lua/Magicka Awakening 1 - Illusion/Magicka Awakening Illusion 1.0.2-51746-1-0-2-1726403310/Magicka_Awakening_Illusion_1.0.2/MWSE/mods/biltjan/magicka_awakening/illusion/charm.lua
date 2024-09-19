--- Alluring Trade
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.charmEnabled
local charmMagnitudeRate = config.charmMagnitudeRate
local illusionRequirement = config.charmIllusionRequirement

-- Drain Mercantile Spell
local function alluringTrade(duration, min, max)
  local spell = tes3.createObject{objectType = tes3.objectType.spell, getIfExists = false}
  tes3.setSourceless(spell)
  spell.alwaysSucceeds = true
  spell.name = "Alluring Trade"
  spell.castType = tes3.spellType.spell
  spell.magickaCost = 0
  local effect = spell.effects[1]
  effect.id = tes3.effect.drainSkill
  effect.min = min
  effect.max = max
  effect.radius = 0
  effect.rangeType = tes3.effectRange.touch
  effect.duration = duration
  effect.attribute = -1
  effect.skill = 24
  return spell
end

--- Charm
--- @param e spellResistEventData
local function charm(e)
  -- Check if enabled
  if enabled then 
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    local effect = e.effect
    if effect.id == tes3.effect.charm then
      if(caster.illusion) then
        if caster.illusion.base >= illusionRequirement then
          -- Main function
          local target = e.target
          if target.mobile.resistMagicka < 100 then
            if(caster ~= target) then
              local min = math.floor(e.effect.min / charmMagnitudeRate)
              local max = math.floor(e.effect.max / charmMagnitudeRate)
              tes3.cast{reference = target, instant = true, alwaysSucceeds = true, spell = alluringTrade(effect.duration, min, max), target = target}
            end
          end
        end
      end
    end
  end
end

return charm

-- TODO: Maybe make a clean up when light effect is removed
