--- Permanent Calm
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.calmEnabled
local willpowerResist = config.calmWillpowerResist
local illusionRequirement = config.calmIllusionRequirement

-- "Constants"
local willPowerDivider = 3
local minFight = 30

-- Permanent Calm
--- @param e magicEffectRemovedEventData
local function permanentCalm(e)
  -- Check if enabled
  if enabled then 
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    if caster.illusion.base >= illusionRequirement then
      -- Main function
      local target = e.mobile
      local effect = e.effect
      if (((target.objectType == tes3.objectType.mobileNPC) and (effect.object.id == tes3.effect.calmHumanoid))) or   -- Handle Humanoids
        ((target.objectType == tes3.objectType.mobileCreature) and (effect.object.id == tes3.effect.calmCreature)) then   -- Handle Creatures
          local willMult = 1
          if not(willpowerResist) then willMult = 0 end
          local reducedValue = math.max(e.effectInstance.effectiveMagnitude - willMult * math.floor(target.willpower.current / willPowerDivider), 0)
          target.fight = math.max(target.fight - reducedValue, minFight)
      end
    end
  end
end

return permanentCalm