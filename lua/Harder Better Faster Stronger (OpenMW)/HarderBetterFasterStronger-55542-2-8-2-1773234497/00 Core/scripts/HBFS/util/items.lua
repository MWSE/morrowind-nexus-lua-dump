local T = require('openmw.types')
local I = require('openmw.interfaces')

local log = require('scripts.HBFS.util.log')
local mStore = require('scripts.HBFS.config.store')
local mTools = require('scripts.HBFS.util.tools')

local module = {}

module.commitTheft = function(player, value)
    local crimeLevel = T.Player.getCrimeLevel(player)
    local output = I.Crimes.commitCrime(player, { arg = value, type = T.Player.OFFENSE_TYPE.Theft })
    if output.wasCrimeSeen and crimeLevel == T.Player.getCrimeLevel(player) then
        T.Player.setCrimeLevel(player, crimeLevel + value)
    end
end

local function getItemConditionRatio(loot, lootProps)
    local ratio = 1
    local reasons = {}
    if lootProps.isCorpse then
        ratio = ratio * math.random() ^ 2 * 1 / 2
        table.insert(reasons, "is a corpse")
    end
    local record = loot.type.record(loot)
    if loot.type == T.Container then
        if lootProps.submerged then
            ratio = ratio * math.random() ^ 2 * 1 / 2
            table.insert(reasons, "is submerged")
        end
    else
        if loot.type == T.Creature and record.type == T.Creature.TYPE.Undead then
            ratio = ratio * (1 / 4 + math.random() * 1 / 4)
            table.insert(reasons, "is an undead")
        elseif record.class == "guard" then
            ratio = ratio * math.min(1, 15 / 16 + math.random() * 1 / 8)
            table.insert(reasons, "is a guard")
        else
            lootProps.baseFightValue = lootProps.baseFightValue or T.Actor.stats.ai.fight(loot).base
            ratio = ratio * math.max(0, math.min(1, (1 + math.random() / 2 - lootProps.baseFightValue / 200)))
            table.insert(reasons, string.format("has a base fight value of %d", lootProps.baseFightValue))
        end
    end
    return ratio, reasons
end

module.degradeLootItems = function(loot, lootProps)
    local inventory = loot.type.inventory(loot)
    for _, type in ipairs({ T.Armor, T.Weapon }) do
        for _, item in ipairs(inventory:getAll(type)) do
            local condition = T.Item.itemData(item).condition
            if condition then
                local conditionRatio, reasons = getItemConditionRatio(loot, lootProps)
                if conditionRatio ~= 1 then
                    T.Item.itemData(item).condition = math.floor(condition * conditionRatio)
                    log(string.format("Changed \"%s\"'s item '\"%s\" condition from %d to %d (ratio %.2f) because he %s",
                            loot.recordId, item.recordId, condition, condition * conditionRatio, conditionRatio, table.concat(reasons, " and ")))
                end
            end
        end
    end
end

module.onOpenContainer = function(state, container)
    if not container or state.openedContainers[container.id] then return end
    local data = {}
    if string.find(container.recordId, "corpse") then
        data.isCorpse = true
        log(string.format("%s is a corpse, its content will be degraded", mTools.objectId(container)))
    end
    local waterLevel = container.cell.waterLevel
    if waterLevel and waterLevel > container.position.z then
        data.submerged = true
        log(string.format("%s is submerged, its content will be degraded", mTools.objectId(container)))
    end
    if next(data) and mStore.settings.conditionalItemDegradation.value then
        module.degradeLootItems(container, data)
        state.openedContainers[container.id] = { object = container }
    end
end

return module

