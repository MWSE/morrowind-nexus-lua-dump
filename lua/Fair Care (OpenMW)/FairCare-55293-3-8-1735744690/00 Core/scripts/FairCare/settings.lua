local core = require('openmw.core')
local storage = require('openmw.storage')
local T = require('openmw.types')

local mData = require('scripts.FairCare.data')

local module = {
    MOD_NAME = "FairCare",
    potionScriptPath = "scripts/FairCare/potion.lua",
    isLuaApiRecentEnough = core.API_REVISION >= 68,
    isOpenMW049 = core.API_REVISION > 29,
    interfaceVersion = 1.1,
    saveVersion = 3.8,
}

module.globalKey = "SettingsGlobal" .. module.MOD_NAME
module.creaturesKey = "SettingsCreatures" .. module.MOD_NAME
module.healingTweaksKey = "SettingsHealing" .. module.MOD_NAME
module.regenSettingsKey = "SettingsHealthRegen" .. module.MOD_NAME
module.potionSettingsKey = "SettingsPotions" .. module.MOD_NAME
module.woundedImpactsKey = "SettingsWoundedImpacts" .. module.MOD_NAME
module.healerImpactsKey = "SettingsHealerImpacts" .. module.MOD_NAME

local function getStorage(key)
    return storage.globalSection(key)
end
module.getSection = getStorage

local function canCreatureTypeHeal(type)
    return getStorage(module.creaturesKey):get(mData.creatureTypes[type] .. "_heal")
end
module.canCreatureTypeHeal = canCreatureTypeHeal

local function getHealChanceImpactKey(chanceTypeKey)
    return "healChanceImpact_" .. chanceTypeKey
end
module.getHealChanceImpactKey = getHealChanceImpactKey

local ratios = { ["1/4"] = 1 / 4, ["1/2"] = 1 / 2, ["1"] = 1, ["2"] = 2, ["4"] = 4 }
local function getHealthRegenRatio()
    return ratios[getStorage(module.regenSettingsKey):get("healthRegenRatio")]
end
module.getHealthRegenRatio = getHealthRegenRatio

local function canActorTypeRegen(actor, record)
    local key = tostring(actor.type) .. (actor.type == T.Creature and mData.creatureTypes[record.type] or "")
    return getStorage(module.regenSettingsKey):get(key .. "_regen")
end
module.canActorTypeRegen = canActorTypeRegen

return module
