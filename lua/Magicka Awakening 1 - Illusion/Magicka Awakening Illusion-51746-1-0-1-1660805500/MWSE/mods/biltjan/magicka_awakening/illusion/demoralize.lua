--- Permanent Demoralize
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.demoralizeEnabled
local willpowerResist = config.demoralizeWillpowerResist
local illusionRequirement = config.demoralizeIllusionRequirement

-- "Constants"
local willPowerDivider = 3

-- Permanent Demoralize
--- @param e magicEffectRemovedEventData
local function permanentDemoralize(e)
  -- Check if enabled
  if enabled then 
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    if caster.illusion.base >= illusionRequirement then
      -- Main function
      local target = e.mobile
      local effect = e.effect
      if (((target.objectType == tes3.objectType.mobileNPC) and (effect.object.id == tes3.effect.demoralizeHumanoid))) or   -- Handle Humanoids
        ((target.objectType == tes3.objectType.mobileCreature) and (effect.object.id == tes3.effect.demoralizeCreature)) then   -- Handle Creatures
          local willMult = 1
          if not(willpowerResist) then willMult = 0 end
          local increasedValue = math.max(e.effectInstance.effectiveMagnitude - willMult * math.floor(target.willpower.current / willPowerDivider), 0)
          target.flee = target.flee + increasedValue
      end
    end
  end
end

return permanentDemoralize
