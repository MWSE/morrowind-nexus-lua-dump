local i18n = mwse.loadTranslations("dubaua.enhanced_critical")
local CONFIG_KEY = "dubaua_critical_config"

-- Tier-based critical hit system inspired by Oblivion.
-- Weapon skill determines the tier (apprentice / journeyman / expert).
-- Each tier defines a min/max critical chance range.
-- Luck interpolates within that range (clamped between LuckMinForCrit and LuckMaxForCrit).
-- Weapon type and tier define the critical damage multiplier.
-- Critical chance = frequency, critical multiplier = impact.
-- Arrows and bolts do not apply additional critical multipliers.
local SkillTiers = {apprentice = "apprentice", journeyman = "journeyman", expert = "expert"}

local function getSkillTier(skillValue)
  if skillValue < 50 then return SkillTiers.apprentice end
  if skillValue < 75 then return SkillTiers.journeyman end
  return SkillTiers.expert
end

local CritChanceByTier = {
  [SkillTiers.apprentice] = {min = 0.05, max = 0.12},
  [SkillTiers.journeyman] = {min = 0.010, max = 0.21},
  [SkillTiers.expert] = {min = 0.15, max = 0.30},
}

local LuckMinForCrit = 40
local LuckMaxForCrit = 100

local CritMultiplierByWeaponTypeAndTier = {
  [tes3.weaponType.shortBladeOneHand] = {
    [SkillTiers.apprentice] = 2.0,
    [SkillTiers.journeyman] = 3.0,
    [SkillTiers.expert] = 4.0,
  },
  [tes3.weaponType.longBladeOneHand] = {
    [SkillTiers.apprentice] = 1.5,
    [SkillTiers.journeyman] = 1.75,
    [SkillTiers.expert] = 2.0,
  },
  [tes3.weaponType.longBladeTwoClose] = {
    [SkillTiers.apprentice] = 1.2,
    [SkillTiers.journeyman] = 1.4,
    [SkillTiers.expert] = 1.6,
  },
  [tes3.weaponType.bluntOneHand] = {
    [SkillTiers.apprentice] = 1.5,
    [SkillTiers.journeyman] = 1.75,
    [SkillTiers.expert] = 2.0,
  },
  [tes3.weaponType.bluntTwoClose] = {
    [SkillTiers.apprentice] = 1.2,
    [SkillTiers.journeyman] = 1.4,
    [SkillTiers.expert] = 1.6,
  },
  [tes3.weaponType.bluntTwoWide] = {
    [SkillTiers.apprentice] = 1.2,
    [SkillTiers.journeyman] = 1.4,
    [SkillTiers.expert] = 1.6,
  },
  [tes3.weaponType.spearTwoWide] = {
    [SkillTiers.apprentice] = 1.2,
    [SkillTiers.journeyman] = 1.4,
    [SkillTiers.expert] = 1.6,
  },
  [tes3.weaponType.axeOneHand] = {
    [SkillTiers.apprentice] = 1.5,
    [SkillTiers.journeyman] = 1.75,
    [SkillTiers.expert] = 2.0,
  },
  [tes3.weaponType.axeTwoHand] = {
    [SkillTiers.apprentice] = 1.2,
    [SkillTiers.journeyman] = 1.4,
    [SkillTiers.expert] = 1.6,
  },
  [tes3.weaponType.marksmanBow] = {
    [SkillTiers.apprentice] = 1.8,
    [SkillTiers.journeyman] = 2.4,
    [SkillTiers.expert] = 3.0,
  },
  [tes3.weaponType.marksmanCrossbow] = {
    [SkillTiers.apprentice] = 1.5,
    [SkillTiers.journeyman] = 1.75,
    [SkillTiers.expert] = 2.0,
  },
  [tes3.weaponType.marksmanThrown] = {
    [SkillTiers.apprentice] = 1.8,
    [SkillTiers.journeyman] = 2.4,
    [SkillTiers.expert] = 3.0,
  },
  [tes3.weaponType.arrow] = {
    [SkillTiers.apprentice] = 1.0,
    [SkillTiers.journeyman] = 1.0,
    [SkillTiers.expert] = 1.0,
  },
  [tes3.weaponType.bolt] = {
    [SkillTiers.apprentice] = 1.0,
    [SkillTiers.journeyman] = 1.0,
    [SkillTiers.expert] = 1.0,
  },
}

local defaultConfig = {playerCanCrit = true, enemyCanCrit = true}

local config = mwse.loadConfig(CONFIG_KEY) or defaultConfig

local function getGoverningAttributeId(skillId)
  if skillId == nil then return nil end

  -- MWSE exposes skill metadata in different shapes depending on version.
  if tes3.getSkill then
    local s = tes3.getSkill(skillId)
    if s then
      if s.attribute then return s.attribute end
      if s.attributeId then return s.attributeId end
      if s.governingAttribute then return s.governingAttribute end
      if s.governingAttributeId then return s.governingAttributeId end
    end
  end

  return nil
end

local function getCritChanceFromLuck(luckValue, critChanceMin, critChanceMax)
  if luckValue == nil then return 0 end

  -- Clamp luck into a fixed range so chance stays stable across extreme values.
  local luckLimited = math.min(math.max(luckValue, LuckMinForCrit), LuckMaxForCrit)
  local luckRange = math.max(LuckMaxForCrit - LuckMinForCrit, 1)
  local luckDelta = (luckLimited - LuckMinForCrit) / luckRange

  return critChanceMin + (critChanceMax - critChanceMin) * luckDelta
end

local function getCritStatsForWeapon(weapon, mobile)
  local skillId = weapon.skillId
  -- Skills are 1-based in MWSE mobile.skills; skillId is 0-based.
  local skillValueBase = mobile.skills[skillId + 1].base
  if skillValueBase < 25 then return 0, 1.0 end

  local tier = getSkillTier(skillValueBase)
  local chanceRange = CritChanceByTier[tier]
  if chanceRange == nil then return 0, 1.0 end

  local luckValue = mobile.attributes[tes3.attribute.luck + 1].current
  local critChance = getCritChanceFromLuck(luckValue, chanceRange.min, chanceRange.max)

  local multByTier = CritMultiplierByWeaponTypeAndTier[weapon.type]
  local critMult = (multByTier ~= nil and multByTier[tier]) or 1.0

  local speedMult = weapon.speed or 1
  if weapon.isProjectile and mobile.readiedWeapon ~= nil then
    speedMult = mobile.readiedWeapon.object.speed
  end

  local damageMult = critMult * speedMult

  return critChance, damageMult
end

-- Linearly interpolate min/max crit chance by creature level (low -> high), then apply luck scaling.
local function getCritStatsForCreature(mobile)
  if mobile == nil then return 0, 1.0 end

  local luck = mobile.attributes and mobile.attributes[tes3.attribute.luck + 1]
  local luckValue = luck and luck.current
  local level = mobile.level or (mobile.object and mobile.object.level) or 1

  local lowLevel = 1
  local highLevel = 20
  local chanceLowLevelMin = 0.05
  local chanceLowLevelMax = 0.10
  local chanceHighLevelMin = 0.15
  local chanceHighLevelMax = 0.30
  local t = (math.min(math.max(level, lowLevel), highLevel) - lowLevel) /
                math.max(highLevel - lowLevel, 1)

  local critChanceMin = chanceLowLevelMin + (chanceHighLevelMin - chanceLowLevelMin) * t
  local critChanceMax = chanceLowLevelMax + (chanceHighLevelMax - chanceLowLevelMax) * t
  local critChance = getCritChanceFromLuck(luckValue, critChanceMin, critChanceMax)

  -- Every 5 levels, crit damage increases by 50% (capped at 400%).
  local damageMult = math.min(1 + 0.5 * (math.floor(level / 5) + 1), 4.0)

  return critChance, damageMult
end

local function mathRound(x) return math.floor(x * 10 + 0.5) / 10 end

local function addCritTooltip(e)
  if e.object.objectType ~= tes3.objectType.weapon then return end

  local weapon = e.object
  local mobile = tes3.mobilePlayer
  if mobile == nil then return end
  if not config.playerCanCrit then return end

  local critChance, damageMult = getCritStatsForWeapon(weapon, mobile)
  if critChance <= 0 then return end

  local chanceStr = string.format("%.0f%%", mathRound(critChance * 100))
  local damageStr = string.format("%.0f%%", damageMult * 100)
  local formatText = chanceStr .. " " .. i18n("tooltip.crit.chance") .. " " .. damageStr .. " " ..
                         i18n("tooltip.crit.damage")

  local label = e.tooltip:createLabel{id = "Crit_Tooltip_Label", text = formatText}
  label.wrapText = false
end

local function onDamage(e)
  if e.source ~= "attack" then return end
  if e.attacker == nil then return end

  local target = e.reference
  local mobile = e.attacker

  local actorType = mobile.actorType
  local isPlayer = actorType == tes3.actorType.player
  local isNpc = actorType == tes3.actorType.npc
  local isCreature = actorType == tes3.actorType.creature

  local critChance
  local damageMult

  local maybeVanillaCrit = false
  local isRanged = false
  local maxWeaponDamage = 0

  -- Creatures use a separate crit curve; NPCs/players use weapon/skill-based stats.
  if isCreature then
    if not config.enemyCanCrit then return end
    critChance, damageMult = getCritStatsForCreature(mobile)
  else
    if isPlayer then
      if not config.playerCanCrit then return end
    elseif isNpc then
      if not config.enemyCanCrit then return end
    else
      return
    end

    local weaponObject = e.projectile and e.projectile.firingWeapon or
                             (mobile.readiedWeapon and mobile.readiedWeapon.object)
    if weaponObject == nil then return end

    local isProjectileAttack = e.projectile ~= nil
    local isThrown = weaponObject.type == tes3.weaponType.marksmanThrown
    isRanged = isProjectileAttack or isThrown

    maxWeaponDamage = math.max(weaponObject.slashMax or 0, weaponObject.chopMax or 0,
                               weaponObject.thrustMax or 0)

    maybeVanillaCrit = e.damage > maxWeaponDamage * (isRanged and 1.5 or 1)

    critChance, damageMult = getCritStatsForWeapon(weaponObject, mobile)
  end

  local originalDamage = e.damage

  if math.random() < critChance then
    local vanillaCorrection = 1

    if maybeVanillaCrit then
      vanillaCorrection = isRanged and 2.5 or 4
    else
      tes3.playSound({reference = target, sound = "critical damage"})
    end

    local critDamage = originalDamage * damageMult / vanillaCorrection

    e.damage = math.max(originalDamage, critDamage)
  end
end

local function registerModConfig()
  local template = mwse.mcm.createTemplate(i18n("mod.name"))
  template:saveOnClose(CONFIG_KEY, config)
  template:register()

  local page = template:createSideBarPage{label = i18n("mcm.settings.label")}

  page.sidebar:createInfo{text = i18n("mcm.info")}

  page:createOnOffButton{
    label = i18n("mcm.playerCanCrit.label"),
    variable = mwse.mcm.createTableVariable {id = "playerCanCrit", table = config},
  }

  page:createOnOffButton{
    label = i18n("mcm.enemyCanCrit.label"),
    variable = mwse.mcm.createTableVariable {id = "enemyCanCrit", table = config},
  }
end

event.register("damage", onDamage)
event.register("uiObjectTooltip", addCritTooltip, {priority = 0})
event.register("modConfigReady", registerModConfig)
