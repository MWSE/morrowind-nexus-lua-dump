local mp = "scripts/InspectIt/"
local types = require('openmw.types')
local util = require('openmw.util')

local function loadConfig(path)
    local ok, config = pcall(require, path)
    if ok then
        return config
    else
        print("[InspectIt] Warning: Could not load config " .. path .. ": " .. tostring(config))
        return {}
    end
end

local weapon        = (loadConfig(mp .. "config.weapon"))[types.Weapon] or {}
local armor         = (loadConfig(mp .. "config.armor"))[types.Armor] or {}
local clothing      = (loadConfig(mp .. "config.clothing"))[types.Clothing] or {}
local book          = (loadConfig(mp .. "config.book"))[types.Book] or {}
local ingredient    = (loadConfig(mp .. "config.ingredient"))[types.Ingredient] or {}
local potion        = (loadConfig(mp .. "config.potion"))[types.Potion] or {}
local miscellaneous = (loadConfig(mp .. "config.miscellaneous"))[types.Miscellaneous] or {}
local apparatus     = (loadConfig(mp .. "config.apparatus"))[types.Apparatus] or {}
local lockpick      = (loadConfig(mp .. "config.lockpick"))[types.Lockpick] or {}
local probe         = (loadConfig(mp .. "config.probe"))[types.Probe] or {}
local repair        = (loadConfig(mp .. "config.repair"))[types.Repair] or {}
local light         = (loadConfig(mp .. "config.light"))[types.Light] or {}
local container     = (loadConfig(mp .. "config.container"))[types.Container] or {}
local activator     = (loadConfig(mp .. "config.activator"))[types.Activator] or {}
local NPC           = (loadConfig(mp .. "config.npc"))[types.NPC] or {}
local creature      = (loadConfig(mp .. "config.creature"))[types.Creature] or {}

local OBJECT_WIDGET_CONFIG = {
    [types.Weapon]        = weapon,
    [types.Armor]        = armor,
    [types.Clothing]     = clothing,
    [types.Book]       = book,
    [types.Ingredient]  = ingredient,
    [types.Potion]     = potion,
    [types.Miscellaneous] = miscellaneous,
    [types.Apparatus]  = apparatus,
    [types.Lockpick]    = lockpick,
    [types.Probe]      = probe,
    [types.Repair]     = repair,
    [types.Light]      = light,
    [types.Container]  = container,
    [types.Activator]  = activator,
    [types.NPC]        = NPC,
    [types.Creature]   = creature,
}

local configsToCheck = {
    { name = "Weapon", config = weapon },
    { name = "Armor", config = armor },
    { name = "Clothing", config = clothing },
    { name = "Book", config = book },
    { name = "Ingredient", config = ingredient },
    { name = "Potion", config = potion },
    { name = "Miscellaneous", config = miscellaneous },
    { name = "Apparatus", config = apparatus },
    { name = "Lockpick", config = lockpick },
    { name = "Probe", config = probe },
    { name = "Repair", config = repair },
    { name = "Light", config = light },
    { name = "Container", config = container },
    { name = "Activator", config = activator },
    { name = "NPC", config = NPC },
    { name = "Creature", config = creature }
}

for _, entry in ipairs(configsToCheck) do
    if not entry.config then
        print("[InspectIt] ERROR: Configuration table is nil for " .. entry.name)
    elseif not entry.config.title then
        print("[InspectIt] ERROR: Missing 'title' in config for " .. entry.name)
    end
end

return OBJECT_WIDGET_CONFIG
