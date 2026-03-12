local i18n = mwse.loadTranslations("dubaua.enhanced_critical")
local CONFIG_KEY = "dubaua_critical_config"

-- Tier-based critical hit system inspired by Oblivion.
-- Weapon skill determines the tier (apprentice / journeyman / expert).
-- Each tier defines a min/max critical chance range.
-- Luck interpolates within that range (clamped between LuckMinForCrit and LuckMaxForCrit).
-- Weapon type and tier define the critical damage multiplier.
-- Critical chance = frequency, critical multiplier = impact.
-- Arrows and bolts do not apply additional critical multipliers.
local SkillTiers = {
  novice = "novice",
  apprentice = "apprentice",
  journeyman = "journeyman",
  expert = "expert"
}
local isTest = rawget(_G, "__TEST") == true

local function getSkillTier(skillValue)
  if skillValue < 25 then return SkillTiers.novice end
  if skillValue < 50 then return SkillTiers.apprentice end
  if skillValue < 75 then return SkillTiers.journeyman end
  return SkillTiers.expert
end

local CritChanceByTier = {
  [SkillTiers.apprentice] = {min = 0.05, max = 0.12},
  [SkillTiers.journeyman] = {min = 0.10, max = 0.21},
  [SkillTiers.expert] = {min = 0.15, max = 0.30},
}

local LuckMinForCrit = 40
local LuckMaxForCrit = 100

local HandToHandCritMultiplierByTier = {
  [SkillTiers.apprentice] = 2.0,
  [SkillTiers.journeyman] = 3.0,
  [SkillTiers.expert] = 4.0,
}

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

local defaultConfig = {playerCanCrit = true, enemyCanCrit = true, debugLogging = false}

local config = mwse.loadConfig(CONFIG_KEY) or defaultConfig

local function debugLog(fmt, ...)
  if not config.debugLogging then return end
  if not (mwse and mwse.log) then return end
  mwse.log("[dubaua_critical] " .. fmt, ...)
end

local function getMobileName(mobile)
  if mobile == nil then return "nil" end
  return (mobile.reference and mobile.reference.object and mobile.reference.object.name) or
             (mobile.object and mobile.object.name) or (mobile.object and mobile.object.id) or
             "unknown"
end

local function getReferenceName(reference)
  if reference == nil then return "nil" end
  return
      (reference.object and reference.object.name) or (reference.object and reference.object.id) or
          "unknown"
end

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

local function isNonCreature(actorType)
  return actorType == tes3.actorType.player or actorType == tes3.actorType.npc
end

-- Forward declarations so getActorCritStats captures locals (not globals).
local getCritStatsForWeapon
local getCritStatsForCreature
local getCritStatsForHandToHand

local function getActorCritStats(mobile, weapon)
  if mobile.actorType == tes3.actorType.creature then return getCritStatsForCreature(mobile) end

  if weapon ~= nil then return getCritStatsForWeapon(weapon, mobile) end

  return getCritStatsForHandToHand(mobile)
end

getCritStatsForWeapon = function(weapon, mobile)
  if mobile == nil then return 0, 1.0 end
  if weapon == nil then return 0, 1.0 end

  local skillId = weapon.skillId
  -- Skills are 1-based in MWSE mobile.skills; skillId is 0-based.
  local skillValueBase = mobile.skills[skillId + 1].base

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

  local damageMultiplier = critMult * speedMult

  return critChance, damageMultiplier
end

-- Linearly interpolate min/max crit chance by creature level (low -> high), then apply luck scaling.
getCritStatsForCreature = function(mobile)
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
  local damageMultiplier = math.min(1 + 0.5 * (math.floor(level / 5) + 1), 4.0)

  return critChance, damageMultiplier
end

getCritStatsForHandToHand = function(mobile)
  if mobile == nil then return 0, 1.0 end

  local actorType = mobile.actorType
  if not isNonCreature(actorType) then return 0, 1.0 end
  if tes3.skill == nil or tes3.skill.handToHand == nil then return 0, 1.0 end

  local handToHandSkill = mobile.skills and mobile.skills[tes3.skill.handToHand + 1]
  if handToHandSkill == nil then return 0, 1.0 end

  local skillValueBase = handToHandSkill.base

  local tier = getSkillTier(skillValueBase)
  local chanceRange = CritChanceByTier[tier]
  if chanceRange == nil then return 0, 1.0 end

  local luckValue = mobile.attributes[tes3.attribute.luck + 1].current
  local critChance = getCritChanceFromLuck(luckValue, chanceRange.min, chanceRange.max)
  local damageMultiplier = HandToHandCritMultiplierByTier[tier] or 1.0

  return critChance, damageMultiplier
end

local function mathRound(x) return math.floor(x * 10 + 0.5) / 10 end

local function addCritTooltip(e)
  if e.object.objectType ~= tes3.objectType.weapon then return end

  local weapon = e.object
  local mobile = tes3.mobilePlayer
  if mobile == nil then return end
  if not config.playerCanCrit then return end

  local critChance, damageMultiplier = getCritStatsForWeapon(weapon, mobile)
  if critChance <= 0 then return end

  local chanceStr = string.format("%.0f%%", mathRound(critChance * 100))
  local damageStr = string.format("%.0f%%", damageMultiplier * 100)
  local formatText = chanceStr .. " " .. i18n("tooltip.crit.chance") .. " " .. damageStr .. " " ..
                         i18n("tooltip.crit.damage")

  local label = e.tooltip:createLabel{id = "Crit_Tooltip_Label", text = formatText}
  label.wrapText = false
end

local function addHandToHandCritTooltip(e)
  if e.skill ~= tes3.skill.handToHand then return end

  local mobile = tes3.mobilePlayer
  if mobile == nil then return end
  if not config.playerCanCrit then return end

  local critChance, damageMultiplier = getCritStatsForHandToHand(mobile)
  if critChance <= 0 then return end

  local chanceStr = string.format("%.0f%%", mathRound(critChance * 100))
  local damageStr = string.format("%.0f%%", damageMultiplier * 100)
  local formatText = chanceStr .. " " .. i18n("tooltip.crit.chance") .. " " .. damageStr .. " " ..
                         i18n("tooltip.crit.damage")

  local label = e.tooltip:createLabel{id = "HandToHand_Crit_Tooltip_Label", text = formatText}
  label.wrapText = false
end

local function canActorCrit(e)
  if e.source ~= "attack" then return false end
  if e.attacker == nil then return false end

  local actorType = e.attacker.actorType
  if actorType == tes3.actorType.player then return config.playerCanCrit end
  if actorType == tes3.actorType.npc then return config.enemyCanCrit end
  if actorType == tes3.actorType.creature then return config.enemyCanCrit end

  return false
end

local function getWeaponObject(e, attacker)
  if attacker.actorType == tes3.actorType.creature then return nil end

  return e.projectile and e.projectile.firingWeapon or
             (attacker.readiedWeapon and attacker.readiedWeapon.object)
end

local function isProbablyVanillaCrit(e, attacker, weaponObject)
  if weaponObject == nil then return false, false end

  local isProjectileAttack = e.projectile ~= nil
  local isThrown = weaponObject.type == tes3.weaponType.marksmanThrown
  local isRanged = isProjectileAttack or isThrown
  local maxWeaponDamage = math.max(weaponObject.slashMax or 0, weaponObject.chopMax or 0,
                                   weaponObject.thrustMax or 0)

  return e.damage > maxWeaponDamage * (isRanged and 1.5 or 1), isRanged
end

local function getCriticalDamage(originalDamage, critChance, damageMultiplier, maybeVanillaCrit,
                                 isRanged, target)
  if math.random() >= critChance then return originalDamage end

  local vanillaCorrection = 1
  if maybeVanillaCrit then
    vanillaCorrection = isRanged and 2.5 or 4
  else
    tes3.playSound({reference = target, sound = "critical damage"})
  end

  local critDamage = originalDamage * damageMultiplier / vanillaCorrection
  debugLog(
      "crit proc vanillaCorrection=%.2f maybeVanillaCrit=%s critDamage=%.4f originalDamage=%.4f",
      vanillaCorrection, tostring(maybeVanillaCrit), critDamage, originalDamage)

  return math.max(originalDamage, critDamage)
end

local function onDamage(e)
  if not canActorCrit(e) then return end

  local target = e.reference
  local mobile = e.attacker
  local weaponObject = getWeaponObject(e, mobile)
  local originalDamage = e.damage

  local critChance, damageMultiplier = getActorCritStats(mobile, weaponObject)
  debugLog("onDamage attacker='%s' target='%s' critChance=%.4f damageMultiplier=%.4f",
           getMobileName(mobile), getReferenceName(target), critChance, damageMultiplier)
  local maybeVanillaCrit, isRanged = isProbablyVanillaCrit(e, mobile, weaponObject)
  e.damage = getCriticalDamage(originalDamage, critChance, damageMultiplier, maybeVanillaCrit,
                               isRanged, target)
end

local function onDamageFatigue(e)
  if not canActorCrit(e) then return end

  local target = e.reference
  local mobile = e.attacker
  if not isNonCreature(mobile.actorType) then return end

  local originalDamage = e.fatigueDamage

  local critChance, damageMultiplier = getCritStatsForHandToHand(mobile)
  debugLog("onDamageFatigue attacker='%s' target='%s' critChance=%.4f damageMultiplier=%.4f",
           getMobileName(mobile), getReferenceName(target), critChance, damageMultiplier)
  e.fatigueDamage = getCriticalDamage(originalDamage, critChance, damageMultiplier, false, false,
                                      target)
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

  page:createOnOffButton{
    label = i18n("mcm.debugLogging.label"),
    variable = mwse.mcm.createTableVariable {id = "debugLogging", table = config},
  }
end

if isTest then
  _G.__dubaua_critical_exports = {
    getSkillTier = getSkillTier,
    SkillTiers = SkillTiers,
    CritChanceByTier = CritChanceByTier,
    LuckMinForCrit = LuckMinForCrit,
    LuckMaxForCrit = LuckMaxForCrit,
    CritMultiplierByWeaponTypeAndTier = CritMultiplierByWeaponTypeAndTier,
    config = config,
    getCritChanceFromLuck = getCritChanceFromLuck,
    getActorCritStats = getActorCritStats,
    getCritStatsForWeapon = getCritStatsForWeapon,
    getCritStatsForCreature = getCritStatsForCreature,
    getCritStatsForHandToHand = getCritStatsForHandToHand,
    mathRound = mathRound,
    onDamage = onDamage,
    onDamageFatigue = onDamageFatigue,
  }
end

event.register("damage", onDamage)
event.register("damageHandToHand", onDamageFatigue)
event.register("uiObjectTooltip", addCritTooltip, {priority = 0})
event.register("uiSkillTooltip", addHandToHandCritTooltip, {priority = 0})
event.register("modConfigReady", registerModConfig)
