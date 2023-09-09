local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local log = require("scripts.morrowind_world_randomizer.utils.log")
local generatorData = require("scripts.morrowind_world_randomizer.generator.data")
local tableLib = require("scripts.morrowind_world_randomizer.utils.table")
local objectIds = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

---@class mwr.itemPosData
---@field pos integer
---@field type string
---@field subType string
---@field isArtifact boolean|nil
---@field isDangerous boolean|nil

---@class mwr.itemsData
---@field items table<string, mwr.itemPosData>
---@field groups table<string, table<string>>

local this = {}

local dangerousEnchantIds = {}

for _, enchant in pairs(core.magic.enchantments) do
    if enchant.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        for _, eff in pairs(enchant.effects) do
            if generatorData.forbiddenEffectsIds[eff.effect.id] then
                dangerousEnchantIds[enchant.id:lower()] = true
                break
            end
        end
    end
end

local function checkMajorRequirements(id, scriptId)
    if (scriptId == "" or generatorData.scriptWhiteList[scriptId]) and not generatorData.forbiddenIds[id] then
        return true
    end
    return false
end

local function checkMinorRequirements(item, objectType)
    local model = item.model:lower()
    local icon = item.icon:lower()
    if model and not generatorData.forbiddenModels[model] and icon ~= "icons\\" and not generatorData.forbiddenIcons[icon] and
            not (objectType == objectIds.book and item.enchant == "") and not (item.value and item.value == 0) then
        return true
    end
    return false
end

---@param smart boolean|nil
---@return mwr.itemsData
function this.generateData(smart)
    ---@type mwr.itemsData
    local out = {groups = {}, items = {}}

    local recordData = {
        [objectIds.alchemy] = {types.Potion, "value"},
        [objectIds.apparatus] = {types.Apparatus, "value"},
        [objectIds.armor] = {types.Armor, "value"},
        [objectIds.clothing] = {types.Clothing, "value"},
        [objectIds.ingredient] = {types.Ingredient, "value"},
        [objectIds.lockpick] = {types.Lockpick, "value"},
        [objectIds.probe] = {types.Probe, "value"},
        [objectIds.weapon] = {types.Weapon, "value"},
        [objectIds.book] = {types.Book, "value"},
        -- [objectIds.miscItem] = {types.Miscellaneous, "value"},
    }

    local dangerousItems = {}
    local itemCount = {}

    if smart then
        local processItems = function(data)
            for _, item in pairs(data) do
                local id = item.recordId:lower()
                if not itemCount[id] then
                    itemCount[id] = 1
                else
                    itemCount[id] = itemCount[id] + 1
                end
            end
        end
        for _, cell in pairs(world.cells) do
            local npcs = cell:getAll(types.NPC) or {}
            local creatures = cell:getAll(types.Creature) or {}
            local containers = cell:getAll(types.Container) or {}
            for groupId, records in pairs(recordData) do
                processItems(cell:getAll(records[1]))
                for _, actor in pairs(npcs) do
                    processItems(types.Actor.inventory(actor):getAll(records[1]))
                end
                for _, actor in pairs(creatures) do
                    processItems(types.Actor.inventory(actor):getAll(records[1]))
                end
                for _, container in pairs(containers) do
                    processItems(types.Container.content(container):getAll(records[1]))
                end
            end
        end
    end

    for groupId, records in pairs(recordData) do
        local itemData = {}
        for _, item in pairs(records[1].records) do
            local scriptId = item.mwscript:lower()
            local itemId = item.id:lower()
            local count = smart and itemCount[itemId] or true
            if checkMajorRequirements(itemId, scriptId) and checkMinorRequirements(item, groupId) and count then
                local type = tostring(item.type or "0")
                table.insert(itemData, {id = itemId, value = item[records[2]], type = type})
                if item.enchant and item.enchant ~= "" and dangerousEnchantIds[item.enchant:lower()] then
                    dangerousItems[itemId] = true
                end
            end
        end
        table.sort(itemData, function(a, b) return a.value < b.value end)
        if not out.groups[groupId] then out.groups[groupId] = {} end
        local group = out.groups[groupId]
        for _, dt in pairs(itemData) do
            if not group[dt.type] then group[dt.type] = {} end
            table.insert(group[dt.type], dt.id)
        end
    end

    for groupId, group in pairs(out.groups) do
        local count = 0
        for subType, ids in pairs(group) do
            for pos, id in pairs(ids) do
                count = count + 1
                ---@type mwr.itemPosData
                local data = {pos = pos, type = groupId, subType = subType}
                if generatorData.obtainableArtifacts[id] then data.isArtifact = true end
                if dangerousItems[id] then data.isDangerous = true end
                out.items[id] = data
            end
        end
        log(groupId, count)
    end

    return out
end

return this