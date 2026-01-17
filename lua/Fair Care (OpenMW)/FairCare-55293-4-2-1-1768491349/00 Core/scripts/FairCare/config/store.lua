local storage = require('openmw.storage')
local T = require('openmw.types')

local mDef = require('scripts.FairCare.config.definition')
local mTypes = require('scripts.FairCare.config.types')

local module = {}

module.groups = {
    global = { name = "Global", key = "" },
    creatures = { name = "Creatures", key = "" },
    healing = { name = "Healing", key = "" },
    healthRegen = { name = "HealthRegen", key = "" },
    potions = { name = "Potions", key = "" },
    woundedImpacts = { name = "WoundedImpacts", key = "" },
    healerImpacts = { name = "HealerImpacts", key = "" },
}

for _, group in pairs(module.groups) do
    group.key = "Settings" .. group.name .. mDef.MOD_NAME
    group.asTable = function()
        return storage.globalSection(group.key):asTable()
    end
    group.get = function(key)
        local section = storage.globalSection(group.key)
        if key then
            return section:get(key)
        else
            return section
        end
    end
    group.set = function(key, value)
        storage.globalSection(group.key):set(key, value)
    end
end

module.getHealChanceImpactKey = function(chanceTypeKey)
    return "healChanceImpact_" .. chanceTypeKey
end

local ratios = { ["1/4"] = 1 / 4, ["1/2"] = 1 / 2, ["1"] = 1, ["2"] = 2, ["4"] = 4 }
module.getHealthRegenRatio = function(value)
    return ratios[value]
end

module.getActorTypeRegenKey = function(actor, record)
    return tostring(actor.type) .. (actor.type == T.Creature and mTypes.creatureTypes[record.type] or "") .. "_regen"
end

return module
