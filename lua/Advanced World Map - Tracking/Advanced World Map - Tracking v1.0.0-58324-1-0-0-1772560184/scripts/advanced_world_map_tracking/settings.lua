local I = require("openmw.interfaces")
local input = require('openmw.input')

local config = require("scripts.advanced_world_map_tracking.config.config")
local commonData = require("scripts.advanced_world_map_tracking.common")



I.Settings.registerPage{
  key = commonData.settingPage,
  l10n = commonData.l10nKey,
  name = "ModName",
  description = "ModDescription",
}

---@class settings.boolSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default boolean|nil
---@field trueLabel string|nil
---@field falseLabel string|nil
---@field disabled boolean|nil

---@class settings.numberSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default number|nil
---@field min number|nil
---@field max number|nil
---@field integer boolean|nil
---@field disabled boolean|nil

---@class settings.selectSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default string
---@field items string[]
---@field disabled boolean|nil


---@param args settings.boolSetting
local function boolSetting(args)
    return {
        key = args.key,
        renderer = "checkbox",
        name = args.name,
        description = args.description,
        default = args.default or false,
        argument = {
            trueLabel = args.trueLabel,
            falseLabel = args.falseLabel,
            disabled = args.disabled,
        }
    }
end

---@param args settings.numberSetting
local function numberSetting(args)
    local data = {
        key = args.key,
        renderer = "number",
        name = args.name,
        description = args.description,
        default = args.default or 0,
        argument = {
            min = args.min,
            max = args.max,
            integer = args.integer,
            disabled = args.disabled,
        }
    }
    return data
end

local function inputKey(args)
    local data = {
        renderer = "DijectKeyBindings:inputBinding",
        key = args.key,
        name = args.name,
        description = args.description,
        default = args.default,
        argument = {
            action = args.action
        }
    }
    return data
end

local function color(args)
    local data = {
        renderer = "color",
        key = args.key,
        name = args.name,
        description = args.description,
        default = args.default,
        argument = {
            disabled = args.disabled,
        }
    }
    return data
end

---@param args settings.selectSetting
local function selectSetting(args)
    local data = {
        key = args.key,
        renderer = "select",
        name = args.name,
        description = args.description,
        default = args.default,
        argument = {
            l10n = commonData.l10nKey,
            disabled = args.disabled,
            items = args.items,
        }
    }
    return data
end


I.Settings.registerGroup{
    key = commonData.settingStorageId,
    page = commonData.settingPage,
    l10n = commonData.l10nKey,
    name = "SpellDetection",
    permanentStorage = true,
    order = 0,
    settings = {
        boolSetting{key = "spDetection.animal.enabled", name = "DetectAnimalEnabled", default = config.data.spDetection.animal.enabled},
        boolSetting{key = "spDetection.animal.detectNPC", name = "DetectAnimalNPC", default = config.data.spDetection.animal.detectNPC},
        boolSetting{key = "spDetection.animal.detectEnemy", name = "DetectAnimalEnemy", description = "DetectAnimalEnemyDescription", default = config.data.spDetection.animal.detectEnemy},
        color{key = "spDetection.animal.color", name = "DetectAnimalColor", default = config.data.spDetection.animal.color},
        color{key = "spDetection.animal.npcColor", name = "DetectAnimalNPCColor", default = config.data.spDetection.animal.npcColor},
        color{key = "spDetection.animal.enemyColor", name = "DetectAnimalEnemyColor", default = config.data.spDetection.animal.enemyColor},
        numberSetting{key = "spDetection.animal.distanceMul", name = "DetectAnimalDistanceMul", description = "DetectAnimalDistanceMulDescription", default = config.data.spDetection.animal.distanceMul, min = 0.1},
        boolSetting{key = "spDetection.key.enabled", name = "DetectKeyEnabled", default = config.data.spDetection.key.enabled},
        color{key = "spDetection.key.color", name = "DetectKeyColor", default = config.data.spDetection.key.color},
        numberSetting{key = "spDetection.key.distanceMul", name = "DetectKeyDistanceMul", description = "DetectKeyDistanceMulDescription", default = config.data.spDetection.key.distanceMul, min = 0.1},
        boolSetting{key = "spDetection.enchantment.enabled", name = "DetectEnchantmentEnabled", default = config.data.spDetection.enchantment.enabled},
        color{key = "spDetection.enchantment.color", name = "DetectEnchantmentColor", default = config.data.spDetection.enchantment.color},
        numberSetting{key = "spDetection.enchantment.distanceMul", name = "DetectEnchantmentDistanceMul", description = "DetectEnchantmentDistanceMulDescription", default = config.data.spDetection.enchantment.distanceMul, min = 0.1},
        numberSetting{key = "spDetection.enchantment.maxTooltipItems", name = "DetectEnchantmentMaxTooltipItems", description = "DetectEnchantmentMaxTooltipItemsDescription", default = config.data.spDetection.enchantment.maxTooltipItems, min = 1, integer = true},
        numberSetting{key = "spDetection.markerSize", name = "DetectMarkerSize", description = "DetectMarkerSizeDescription", default = config.data.spDetection.markerSize, min = 1, max = 50},
    },
}