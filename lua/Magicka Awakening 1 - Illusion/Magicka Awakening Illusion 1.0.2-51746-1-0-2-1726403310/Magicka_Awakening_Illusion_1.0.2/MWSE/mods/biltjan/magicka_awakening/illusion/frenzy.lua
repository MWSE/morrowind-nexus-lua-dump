--- Permanent Frenzy
-- Config
local config = require("biltjan.magicka_awakening.config")
local enabled = config.frenzyEnabled
local willpowerResist = config.frenzyWillpowerResist
local illusionRequirement = config.frenzyIllusionRequirement

-- "Constants"
local willPowerDivider = 3

-- Permanent Frenzy
--- @param e magicEffectRemovedEventData
local function permanentFrenzy(e)
  -- Check if enabled
  if enabled then 
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    local effect = e.effect
    if((effect.object.id == tes3.effect.frenzyHumanoid) or (effect.object.id == tes3.effect.frenzyCreature)) then
      if caster.illusion.base >= illusionRequirement then
        -- Main function
        local target = e.mobile
        if (((target.objectType == tes3.objectType.mobileNPC) and (effect.object.id == tes3.effect.frenzyHumanoid))) or   -- Handle Humanoids
          ((target.objectType == tes3.objectType.mobileCreature) and (effect.object.id == tes3.effect.frenzyCreature)) then   -- Handle Creatures
            local willMult = 1
            if not(willpowerResist) then willMult = 0 end
            local increasedValue = math.max(e.effectInstance.effectiveMagnitude - willMult * math.floor(target.willpower.current / willPowerDivider), 0)
            target.fight = target.fight + increasedValue
        end
      end
    end
  end
end

return permanentFrenzy