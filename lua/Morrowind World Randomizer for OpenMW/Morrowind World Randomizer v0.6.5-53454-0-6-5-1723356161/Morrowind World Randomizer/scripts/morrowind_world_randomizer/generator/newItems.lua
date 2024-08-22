require("scripts.morrowind_world_randomizer.generator.items")
local config = require("scripts.morrowind_world_randomizer.config.local").data.item
local random = require("scripts.morrowind_world_randomizer.utils.random")
local types = require("openmw.types")
local core = require("openmw.core")
local world = require("openmw.world")

local this = {}

---@type mwr.itemsData
local itemsData

local allowedTypes = {[types.Potion] = true, [types.Armor] = true, [types.Clothing] = true, [types.Weapon] = true,}

local fieldsForStats = {"baseArmor", "health", "value", "weight", "isMagical", "isSilver", "reach", "speed", "enchantCapacity"}
local fieldsForWeapon = {{"chopMinDamage", "chopMaxDamage"}, {"slashMinDamage", "slashMaxDamage"}, {"thrustMinDamage", "thrustMaxDamage"}}

local prefixList = {"Weak", "Unstable", "Volatile", "Strange", "Strong"} --TODO add i10n

function this.init(globalData, cfgData)
    itemsData = globalData.itemsData
    if cfgData then
        config = cfgData.item
    end
end

---@return string|nil
function this.new(oldId, itType)
    if not itType or not oldId then return end
    if not allowedTypes[itType] then return end
    ---@type mwr.itemPosData
    local data = itemsData.items[oldId]
    if not data then return end
    if not data.count or config.new.threshold > data.count then return end
    local group = itemsData.groups[data.type][data.subType]
    if not group then return end
    local groupCount = #group
    local posMul = data.pos / groupCount
    local record = itType.record(oldId)
    if not record then return end
    local newItemData = {template = record}
    local prefixContribut = 0
    local prefixContributCount = 0
    if record.model and config.new.change.model then
        local newModelItemPos = random.getRandom(data.pos, groupCount, config.new.model.rregion.min, config.new.model.rregion.max)
        local newModelItem = group[newModelItemPos]
        local rec = itType.record(newModelItem)
        if rec then
            newItemData.model = rec.model
            if config.new.linkIconToModel then
                newItemData.icon = rec.icon
            end
        end
    end
    if record.icon and config.new.change.icon and not config.new.linkIconToModel then
        local newModelItemPos = random.getRandom(data.pos, groupCount, config.new.model.rregion.min, config.new.model.rregion.max)
        local newModelItem = group[newModelItemPos]
        local rec = itType.record(newModelItem)
        if rec then
            newItemData.icon = rec.icon
        end
    end
    if config.new.change.enchantment then
        if (record.enchant and math.random() < config.new.enchantment.chance / 100) or
                (itType == types.Book and record.isScroll) then
            local enchGroups = {}
            if itType == types.Book then
                table.insert(enchGroups, itemsData.enchantments[core.magic.ENCHANTMENT_TYPE.CastOnce])
            elseif itType == types.Weapon then
                if record.type ~= types.Weapon.TYPE.MarksmanBow and record.type ~= types.Weapon.TYPE.MarksmanCrossbow then
                    table.insert(enchGroups, itemsData.enchantments[core.magic.ENCHANTMENT_TYPE.CastOnStrike])
                end
                if not (record.type == types.Weapon.TYPE.Arrow or record.type == types.Weapon.TYPE.Bolt or
                        record.type == types.Weapon.TYPE.MarksmanThrown) then
                    table.insert(enchGroups, itemsData.enchantments[core.magic.ENCHANTMENT_TYPE.ConstantEffect])
                    table.insert(enchGroups, itemsData.enchantments[core.magic.ENCHANTMENT_TYPE.CastOnUse])
                end
            else
                table.insert(enchGroups, itemsData.enchantments[core.magic.ENCHANTMENT_TYPE.ConstantEffect])
                table.insert(enchGroups, itemsData.enchantments[core.magic.ENCHANTMENT_TYPE.CastOnUse])
            end
            local grp = enchGroups[math.random(1, #enchGroups)]
            local newEnchPos = random.getRandom(math.floor(#grp * posMul), #grp, config.new.enchantment.rregion.min, config.new.enchantment.rregion.max)
            prefixContribut = prefixContribut + 1
            newItemData.enchant = grp[newEnchPos]
        else
            newItemData.enchant = ""
            prefixContributCount = prefixContributCount + 1
        end
    end
    for _, field in pairs(fieldsForStats) do
        if record[field] then
            local newItPos = random.getRandom(data.pos, groupCount, config.new.stats.rregion.min, config.new.stats.rregion.max)
            prefixContribut = prefixContribut + (newItPos >= data.pos and 1 or 0)
            prefixContributCount = prefixContributCount + 1
            local newItem = group[newItPos]
            local rec = itType.record(newItem)
            if rec then
                newItemData[field] = rec[field]
            end
        end
    end
    if itType == types.Weapon then
        for _, fieldData in pairs(fieldsForWeapon) do
            if record[fieldData[1]] then
                local newItPos = random.getRandom(data.pos, groupCount, config.new.stats.rregion.min, config.new.stats.rregion.max)
                prefixContribut = prefixContribut + (newItPos >= data.pos and 1 or 0)
                prefixContributCount = prefixContributCount + 1
                local newItem = group[newItPos]
                local rec = itType.record(newItem)
                if rec then
                    newItemData[fieldData[1]] = rec[fieldData[1]]
                    newItemData[fieldData[2]] = rec[fieldData[2]]
                end
            end
        end
    end
    if record.effects then
        newItemData.effects = {}
        for _, effect in pairs(record.effects) do
            table.insert(newItemData.effects, effect)
        end
        if config.new.effects.remove.chance * 0.01 > math.random() then
            local removeCount = math.random(config.new.effects.remove.iregion.min, config.new.effects.remove.iregion.max)
            for i = 1, removeCount do
                if #newItemData.effects > 0 then
                    prefixContributCount = prefixContributCount + 1
                    local effectPos = math.random(1, #newItemData.effects)
                    table.remove(newItemData.effects, effectPos)
                else
                    break
                end
            end
        end
        if config.new.effects.add.chance * 0.01 > math.random() then
            local addCount = math.random(config.new.effects.add.iregion.min, config.new.effects.add.iregion.max)
            for i = 1, addCount do
                if #newItemData.effects < 4 then
                    local newItPos = random.getRandom(data.pos, groupCount, config.new.stats.rregion.min, config.new.stats.rregion.max)
                    local newItem = group[newItPos]
                    local rec = itType.record(newItem)
                    if rec and #rec.effects > 0 then
                        prefixContribut = prefixContribut + (newItPos >= data.pos and 1 or 0)
                        prefixContributCount = prefixContributCount + 1
                        local effect = rec.effects[math.random(1, #rec.effects)]
                        table.insert(newItemData.effects, effect)
                    end
                else
                    break
                end
            end
        end
    end
    if record.name then
        local prefix = config.new.change.prefix and prefixList[1 + math.min(4, math.max(0, math.floor(4 * prefixContribut / prefixContributCount)))] or ""
        if config.new.change.name then
            local newItemId = group[math.random(1, groupCount)]
            local rec = itType.record(newItemId)
            if rec then
                newItemData.name = prefix.." "..rec.name
            end
        else
            newItemData.name = prefix.." "..record.name
        end
    end
    if itType.createRecordDraft then
        local newItemDraft = itType.createRecordDraft(newItemData)
        local newRecord = world.createRecord(newItemDraft)
        return newRecord.id
    end
    return nil
end

return this