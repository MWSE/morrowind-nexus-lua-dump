local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local log = require("scripts.morrowind_world_randomizer.utils.log")
local generatorData = require("scripts.morrowind_world_randomizer.generator.data")
local tableLib = require("scripts.morrowind_world_randomizer.utils.table")
local objectIds = require("scripts.morrowind_world_randomizer.generator.types").objectStrType
local spellLib = require("scripts.morrowind_world_randomizer.utils.spell")
local itemCountData = require("scripts.morrowind_world_randomizer.data.ItemCountData")

---@class mwr.itemPosData
---@field pos integer
---@field type string
---@field subType string
---@field isArtifact boolean|nil
---@field isDangerous boolean|nil
---@field count integer

---@class mwr.itemsData
---@field items table<string, mwr.itemPosData>
---@field groups table<string, table<string>>
---@field enchantments table<table<string>>

local this = {}

local function checkMajorRequirements(id, scriptId, unsafeMode)
    if (unsafeMode or ((scriptId == "" or generatorData.scriptWhiteList[scriptId]) and not generatorData.forbiddenIds[id])) and not id:find("generated:") then
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

---@class mwr.generator.ItemGeneratorParams
---@field smart boolean?
---@field unsafe boolean?

---@param params mwr.generator.ItemGeneratorParams|nil
---@return mwr.itemsData
function this.generateData(params)
    if not params then params = {} end
    ---@type mwr.itemsData
    local out = {groups = {}, items = {}} ---@diagnostic disable-line: missing-fields

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

    local enchantments = {}
    local dangerousEnchantIds = {}

    do
        local enchWithCost = {}
        for _, enchType in pairs(core.magic.ENCHANTMENT_TYPE) do
            enchWithCost[enchType] = {}
            enchantments[enchType] = {}
        end
        for _, enchant in pairs(core.magic.enchantments.records) do
            local id = enchant.id:lower()
            local isDangerous = false
            local cost = 0
            for _, eff in pairs(enchant.effects) do
                cost = cost + spellLib.calculateEffectCost(eff)
                if generatorData.forbiddenEffectsIds[eff.effect.id] then
                    isDangerous = true
                end
            end
            if enchant.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
                dangerousEnchantIds[id] = isDangerous
            end
            if not isDangerous then
                table.insert(enchWithCost[enchant.type], {id, cost})
            end
        end
        for _, enchType in pairs(core.magic.ENCHANTMENT_TYPE) do
            local array = enchWithCost[enchType]
            table.sort(array, function(a, b) return a[2] < b[2] end)
            for _, dt in ipairs(array) do
                table.insert(enchantments[enchType], dt[1])
            end
        end
    end

    out.enchantments = enchantments

    local dangerousItems = {}
    local itemCount = {}

    if params.smart then
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
            local scriptId = (item.mwscript or ""):lower()
            local itemId = item.id:lower()
            local itemCountExists = itemCount[itemId]
            if checkMajorRequirements(itemId, scriptId, params.unsafe) and checkMinorRequirements(item, groupId) and (not params.smart or itemCountExists) then
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
        for i, dt in ipairs(itemData) do
            if not group[dt.type] then group[dt.type] = {} end
            table.insert(group[dt.type], dt.id)
            ---@diagnostic disable-next-line: missing-fields
            out.items[dt.id] = {count = itemCountData[dt.id], type = groupId, subType = dt.type,
                isArtifact = generatorData.obtainableArtifacts[dt.id] and true or false, isDangerous = dangerousItems[dt.id] and true or false}
        end
    end

    for groupId, group in pairs(out.groups) do
        local count = 0
        for subType, ids in pairs(group) do
            for pos, id in ipairs(ids) do
                count = count + 1
                out.items[id].pos = pos
            end
        end
        log(groupId, count)
    end

    return out
end

return this