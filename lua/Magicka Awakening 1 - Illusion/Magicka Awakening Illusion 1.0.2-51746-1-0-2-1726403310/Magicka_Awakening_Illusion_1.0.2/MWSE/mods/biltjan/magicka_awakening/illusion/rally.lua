--- Permanent Rally
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.rallyEnabled
local willpowerResist = config.rallyWillpowerResist
local illusionRequirement = config.rallyIllusionRequirement

-- "Constants"
local willPowerDivider = 3

-- Permanent Rally
--- @param e magicEffectRemovedEventData
local function permanentRally(e)
  -- Check if enabled
  if enabled then 
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    local effect = e.effect
    if((effect.object.id == tes3.effect.rallyHumanoid) or (effect.object.id == tes3.effect.rallyCreature)) then
      if caster.illusion.base >= illusionRequirement then
        -- Main function
        local target = e.mobile
        if (((target.objectType == tes3.objectType.mobileNPC) and (effect.object.id == tes3.effect.rallyHumanoid))) or   -- Handle Humanoids
          ((target.objectType == tes3.objectType.mobileCreature) and (effect.object.id == tes3.effect.rallyCreature)) then   -- Handle Creatures
            local willMult = 1
            if not(willpowerResist) then willMult = 0 end
            local decreasedValue = math.max(e.effectInstance.effectiveMagnitude - willMult * math.floor(target.willpower.current / willPowerDivider), 0)
            target.flee = target.flee - decreasedValue
        end
      end
    end
  end
end

return permanentRally
