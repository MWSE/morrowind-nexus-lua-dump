--- Permanent Calm
-- Config
local config = mwse.loadConfig("biltjan_calm") or {
  enabled = true,
  accountEnemyWillpower = true,
  minimumIllusion = 50,
}
-- "Constants"
local willPowerDivider = 3
local minFight = 30

-- Config
local function registerModConfig()
  local template = mwse.mcm.createTemplate("Permanent Calm")
  template:saveOnClose("biltjan_calm", config)
  template:register()

  local page = template:createSideBarPage{label="Preferences"}
  -- Enable/Disable Mod
  page:createOnOffButton{label = "Enable/Disable Permanent Calm",
  description = "The Fight value of the target will be reduced by the Calm spell magnitude.\nResistance applies (e.g. Bretons will be harder to calm down).",
  variable = mwse.mcm.createTableVariable{id = "enabled", table = config}}

  -- Enable/Disable Willpower Resistance
  page:createOnOffButton{label = "Account for Target's Willpower",
  description = "If enabled, the PERMANENT decrease will be reduced by 1/3 of the target's willpower.\nYou would still be able to calm a high willpower enemy like vanilla, but to permanently calm them you would need a very high magnitude of Calm.",
  variable = mwse.mcm.createTableVariable{id = "accountEnemyWillpower", table = config}}
    
  -- Minimum Illusion level
  page:createSlider{label = "Minimum Illusion",
  description = "Minimum Base Illusion level to permanently calm.\nFortify skills won't work here.\nDefault value: 50.",
  min = 1, max = 100,
  step = 1, jump = 5, 
  variable = mwse.mcm.createTableVariable{id = "minimumIllusion", table = config }}
end


-- Permanent Calm
--- @param e magicEffectRemovedEventData
local function permanentCalm(e)
  -- Check if enabled
  if config.enabled then
    -- Check if Illusion level is adequate
    local caster = e.caster.mobile
    if caster and caster.illusion and caster.illusion.base >= config.minimumIllusion then
      -- Main function
      local target = e.mobile
      local effect = e.effect
      if (((target.objectType == tes3.objectType.mobileNPC) and (effect.object.id == tes3.effect.calmHumanoid))) or   -- Handle Humanoids
        ((target.objectType == tes3.objectType.mobileCreature) and (effect.object.id == tes3.effect.calmCreature)) then   -- Handle Creatures
          local willMult = 1
          if not(config.accountEnemyWillpower) then willMult = 0 end
          local reducedValue = math.max(e.effectInstance.effectiveMagnitude - willMult * math.floor(target.willpower.current / willPowerDivider), 0)
          target.fight = math.max(target.fight - reducedValue, minFight)
      end
    end
  end
end

event.register("modConfigReady", registerModConfig)
event.register(tes3.event.magicEffectRemoved, permanentCalm)