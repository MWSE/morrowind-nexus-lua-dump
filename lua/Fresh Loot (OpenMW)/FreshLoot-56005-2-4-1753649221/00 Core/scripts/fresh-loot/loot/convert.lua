local core = require("openmw.core")
local T = require("openmw.types")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mWorld = require("scripts.fresh-loot.util.world")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mObj = require("scripts.fresh-loot.util.objects")
local mStats = require("scripts.fresh-loot.loot.stats")
local mMod = require("scripts.fresh-loot.loot.modifier")

local module = {}

local itemTypeToSetting = {
    [T.Armor] = mStore.cfg.doArmors.key,
    [T.Clothing] = mStore.cfg.doClothing.key,
    [T.Weapon] = mStore.cfg.doWeapons.key,
}

local function getItems(state, loot, ownerId)
    local unlevelledIds = {}
    local unlevelledRecordIds = {}
    local unlevelledCount = 0
    local levelledCount = 0
    local inventory = loot.type.inventory(loot)
    for _, item in ipairs(inventory:getAll()) do
        unlevelledIds[item.id] = true
        unlevelledRecordIds[item.recordId] = true
        unlevelledCount = unlevelledCount + 1
    end
    local isResolved = inventory:isResolved()
    log(string.format("%s is %sresolved, found %d unlevelled items", inventory, isResolved and "" or "not ", unlevelledCount), mTypes.logLevels.Debug)
    if not isResolved and loot.type == T.Container then
        inventory:resolve()
    end
    local addedValueSum = 0
    local validItems = {}

    local function processItem(item)
        local record = mObj.getRecord(item)
        local levelled = not unlevelledIds[item.id]
        if levelled and ownerId then
            addedValueSum = addedValueSum + mObj.getItemValue(record)
        end

        if not mTypes.itemTypes[item.type]
                or not state.settings[itemTypeToSetting[item.type]]
                or not mObj.areValidItemProps(item, record) then return end

        if levelled then
            levelledCount = levelledCount + 1

            if not isResolved
                    and not unlevelledRecordIds[item.recordId]
                    and not state.cache.validItems[record.id] then
                log(string.format("Found new valid levelled item \"%s\"", record.id))
                table.insert(state.validItems, record.id)
                state.cache.validItems[record.id] = true
            end
        end

        if not state.cache.validItems[record.id] then return end

        local get = levelled
        if not get then
            if loot.type == T.Container then
                get = state.settings[mStore.cfg.doUnlevelledItems.key]
            else
                -- only converts equipped items
                get = T.Actor.hasEquipped(loot, item)
            end
        end
        if not get then return end

        table.insert(validItems, mTypes.new.validItem(item, record, levelled))
    end

    for _, item in ipairs(inventory:getAll()) do
        processItem(item)
    end
    if addedValueSum > 0 then
        local wealth = mStats.addToNpcsWealth(state, ownerId, addedValueSum, false)
        log(string.format("\"%s\"'s (owner \"%s\") inventory wealth is %d", loot.recordId, ownerId, wealth))
    end

    log(string.format("%s is resolved, found %d levelled items and %d total valid items", inventory, levelledCount, #validItems))
    return validItems
end

local function pickLevelledModifier(state, cacheTypes, affixTypes, itemType, ctx)
    local modLevel = mMod.getRandomModifierLevel(state, ctx.lootLevel)
    for level = modLevel, 1, -1 do
        local ids = {}
        for _, cacheType in ipairs(cacheTypes) do
            for _, affixType in ipairs(affixTypes) do
                mHelpers.addArrayToArray(ids, mMod.getModIdsFromItem(state, cacheType, affixType, itemType, level, ctx))
            end
        end
        if #ids ~= 0 then
            local lvlMod = mTypes.new.lvlMod(state.cache.modifiers[ids[math.random(1, #ids)]], level)
            if ctx.ownerWealth then
                ctx.ownerWealth.spent = ctx.ownerWealth.spent
                        + mMod.getModPrice(ctx.item.record, ctx.item.type, lvlMod.mod, lvlMod.lvl)
            end
            return lvlMod
        end
    end
    return nil
end
module.pickLevelledModifier = pickLevelledModifier

local function getItemModifiers(state, item, ctx)
    local lvlMods = {}
    ctx.item.lvlMods = lvlMods

    local cacheTypes, affixTypes
    if math.random() < state.settings[mStore.cfg.propsModifiersChance.key] / 100 then
        cacheTypes = { state.cache.modifierTypes.props }
        affixTypes = { mTypes.affixTypes.Any }
    else
        cacheTypes = { state.cache.modifierTypes.effects }
        affixTypes = mTypes.affixTypes.pick()
    end
    local lvlMod = pickLevelledModifier(state, cacheTypes, affixTypes, item.type, ctx)
    if not lvlMod then
        -- some items cannot have props mods (e.g. rings)
        if cacheTypes[1] == state.cache.modifierTypes.props then
            cacheTypes = { state.cache.modifierTypes.effects }
            affixTypes = mTypes.affixTypes.pick()
            lvlMod = pickLevelledModifier(state, cacheTypes, affixTypes, item.type, ctx)
        end
        if not lvlMod then
            log(string.format("Could not find any 1st modifier, in container \"%s\", for item \"%s\", %d too expensive mods",
                    ctx.loot.recordId, ctx.item.record.id, ctx.item.tooExpensiveMods))
            return nil
        end
    end
    table.insert(lvlMods, lvlMod)

    if math.random() > state.settings[mStore.cfg.secondModifierChance.key] / 100
            + ctx.chanceBoost * state.settings[mStore.cfg.secondModifierChanceBoostReduction.key] / 100 then
        return lvlMods
    end

    if lvlMod.mod.effects then
        -- don't add a props mod after an effects mod, as some props can affect the effect mods selection (e.g. reduced armor weight can change its class)
        cacheTypes = { state.cache.modifierTypes.effects }
    else
        mMod.applyLvlModsOnItem(lvlMods, item.type, ctx.item.record, mObj.itemRecordToTable(item.type, ctx.item.record))
        if math.random() < state.settings[mStore.cfg.propsModifiersChance.key] / 100 then
            cacheTypes = { state.cache.modifierTypes.props }
        else
            cacheTypes = { state.cache.modifierTypes.effects }
        end
    end
    affixTypes = { mTypes.affixTypes.other(lvlMod.mod.affixType) }
    lvlMod = pickLevelledModifier(state, cacheTypes, affixTypes, item.type, ctx)
    if not lvlMod then
        -- some items cannot have props mods (e.g. rings)
        if cacheTypes[1] == state.cache.modifierTypes.props then
            cacheTypes = { state.cache.modifierTypes.effects }
            lvlMod = pickLevelledModifier(state, cacheTypes, affixTypes, item.type, ctx)
        end
        if not lvlMod then
            log(string.format("Could not find any %s 2nd modifier, in container \"%s\", for item \"%s\", %d too expensive mods",
                    affixTypes[1], ctx.loot.recordId, ctx.item.record.id, ctx.item.tooExpensiveMods))
        end
    end
    if lvlMod then
        table.insert(lvlMods, lvlMod)
    end
    return lvlMods
end

local function buildModdedRecord(type, record, lvlMods)
    mMod.sortLvlMods(lvlMods)
    local newRecord = mObj.itemRecordToTable(type, record)
    local enchantId = mMod.getEnchantId(lvlMods)
    if enchantId ~= nil then
        assert(core.magic.enchantments.records[enchantId] ~= nil, "Cannot find enchantment ID " .. enchantId)
    end
    newRecord.enchant = enchantId
    newRecord.name = mMod.getItemName(record.name, lvlMods)
    mMod.applyLvlModsOnItem(lvlMods, type, record, newRecord)
    return newRecord, mMod.getKey(lvlMods)
end
module.buildModdedRecord = buildModdedRecord

local function convertItem(state, item, ctx)
    local lvlMods = getItemModifiers(state, item, ctx)
    if not lvlMods then return nil end

    local record = ctx.item.record
    local recordPatch, key = buildModdedRecord(item.type, record, lvlMods)
    local newRecord = mWorld.createRecord(item.type, recordPatch, record)

    log(string.format("From item \"%s\", count %d, in loot \"%s\" level %.2f, generated item %s, with key \"%s\", enchant \"%s\"",
            record.id, item.count, ctx.loot.recordId, ctx.lootLevel, newRecord.id, key, newRecord.enchant), mTypes.logLevels.Debug)

    local count = item.count
    local newCount = 1
    if mTypes.itemTypes[item.type].convertWholeStackTypes[record.type] then
        newCount = math.ceil(count * state.settings[mStore.cfg.projectileStackReduction.key] / 100)
    end
    local inventoryItem = mWorld.replaceItem(ctx.loot, item, record, count, newRecord, newCount)
    state.items[inventoryItem.item.id] = mTypes.new.itemData(inventoryItem.item, count, record.id, mMod.lvlModsToLvlModIds(lvlMods))
    return inventoryItem
end

local function convertItemRecordId(state, item, newRecordId)
    local itemData = state.items[item.id]
    if not itemData then return end
    local record = item.type.record(newRecordId)
    local recordPatch = buildModdedRecord(item.type, record, mMod.lvlModIdsToLvlMods(state, itemData.lvlModIds))
    return mWorld.createRecord(item.type, recordPatch, record)
end
module.convertItemRecordId = convertItemRecordId

local function shouldRestoreItem(state, item, filter)
    if mObj.isObjectInvalid(item) then return false end
    local parent = item.parentContainer
    if parent then
        if filter.notLootIds and filter.notLootIds[parent.id] then return false end
        if filter.onlyLoot and filter.onlyLoot.id ~= parent.id then return false end
    end
    if filter.types[mTypes.itemRestoreTypes.All] then return true end
    if item.type == T.Armor and filter.types[mTypes.itemRestoreTypes.Armors] then return true end
    if item.type == T.Clothing and filter.types[mTypes.itemRestoreTypes.Clothing] then return true end
    if item.type == T.Weapon and filter.types[mTypes.itemRestoreTypes.Weapons] then return true end

    if not parent then return false end

    if filter.types[mTypes.itemRestoreTypes.InLoot] then
        return parent.id == filter.onlyLoot.id
    end

    -- once the player looked into a container or an inventory, its content cannot be reverted (excepted with global settings above)
    if mTypes.isAccessed(mObj.getLootData(state, parent)) then
        return false
    end

    if filter.types[mTypes.itemRestoreTypes.Equipped]
            and parent.type.baseType == T.Actor then return true end
    return false
end

local function restoreItems(state, filter, quiet)
    local restored = { notEquipped = 0, equipped = 0 }
    local actors = {}
    local equipped = {}
    local items = state.items
    if filter.onlyLoot then
        items = {}
        for _, item in ipairs(filter.onlyLoot.type.inventory(filter.onlyLoot):getAll()) do
            if state.items[item.id] then
                items[item.id] = true
            end
        end
    end
    for id in pairs(items) do
        local data = state.items[id]
        if shouldRestoreItem(state, data.object, filter) then
            state.items[id] = nil
            local parent = data.object.parentContainer
            local inventoryItem = mWorld.replaceItem(parent, data.object, mObj.getRecord(data.object), data.object.count, data.object.type.records[data.oldRecordId], data.oldCount)
            if inventoryItem.slot then
                actors[parent.id] = parent
                if not equipped[parent.id] then
                    equipped[parent.id] = {}
                end
                table.insert(equipped[parent.id], inventoryItem)
                restored.equipped = restored.equipped + 1
            else
                restored.notEquipped = restored.notEquipped + 1
            end
            if parent then
                local ownerId
                if parent.type == T.NPC then
                    ownerId = parent.recordId
                elseif parent.type == T.Container then
                    ownerId = parent.owner.recordId
                end
                if ownerId then
                    local wealth = state.npcsWealth[ownerId]
                    if wealth then
                        wealth.spent = wealth.spent + inventoryItem.valueDiff
                        log(string.format("Actor %s spent wealth changed by %d", ownerId, inventoryItem.valueDiff))
                    end
                end
            end
        end
    end
    if filter.types[mTypes.itemRestoreTypes.Equipped] then
        for _, data in pairs(state.actors) do
            if not mTypes.isAccessed(data) then
                data.equipped = false
            end
        end
    end
    for actorId, itemsToEquip in pairs(equipped) do
        actors[actorId]:sendEvent(mDef.events.equipItems, itemsToEquip)
    end
    if restored.equipped + restored.notEquipped == 0 then return end
    local messages = {}
    if restored.notEquipped > 0 then
        table.insert(messages, tostring(restored.notEquipped) .. " not equipped")
    end
    if restored.equipped > 0 then
        table.insert(messages, tostring(restored.equipped) .. " equipped")
    end
    core.sendGlobalEvent(mDef.events.sendPlayersEvent, mTypes.new.playersEvent(mDef.events.showMessage, mTypes.new.message(
            string.format("Restored items: %s", table.concat(messages, ", ")), quiet)))
end
module.restoreItems = restoreItems

local function setLootLevel(state, ctx)
    local reasons = {}
    if ctx.loot.type == T.Container then
        local levelReasons
        ctx.lootLevel, ctx.crowdChanceBoost, levelReasons = mStats.getLootLevel(state, ctx.loot)
        mHelpers.addArrayToArray(reasons, levelReasons)
    else
        ctx.lootLevel = mStats.getActorScaledLevel(state, mObj.getActorLevel(ctx.loot), ctx.loot.type == T.Creature)
        table.insert(reasons, string.format("actor \"%s\" (lvl %.2f)", ctx.loot.recordId, ctx.lootLevel))
    end

    if ctx.lootLevel > 0 then
        local scale = state.settings[mStore.cfg.playerLevelScaling.key] / 100
        if scale ~= 0 then
            ctx.lootLevel = ctx.lootLevel * (1 - scale) + state.playerLevel * scale
            table.insert(reasons, string.format("player level scaling %.2f", scale))
        end
        if ctx.boosts.lock ~= 0 then
            ctx.lootLevel = ctx.lootLevel + ctx.boosts.lock * state.settings[mStore.cfg.maxLockLevelBoost.key]
            table.insert(reasons, string.format("lock boost %.2f", ctx.boosts.lock * state.settings[mStore.cfg.maxLockLevelBoost.key]))
        end
        if ctx.boosts.trap ~= 0 then
            ctx.lootLevel = ctx.lootLevel + ctx.boosts.trap * state.settings[mStore.cfg.maxTrapLevelBoost.key]
            table.insert(reasons, string.format("trap boost %.2f", ctx.boosts.trap * state.settings[mStore.cfg.maxTrapLevelBoost.key]))
        end
        if ctx.boosts.waterDepth ~= 0 then
            ctx.lootLevel = ctx.lootLevel + ctx.boosts.waterDepth * state.settings[mStore.cfg.maxWaterDepthLevelBoost.key]
            table.insert(reasons, string.format("water depth boost %.2f", ctx.boosts.waterDepth * state.settings[mStore.cfg.maxWaterDepthLevelBoost.key]))
        end
    end

    log(string.format("Loot \"%s\" difficulty level is %.2f (crowd level %.2f) because of { %s }",
            ctx.loot.recordId, ctx.lootLevel, ctx.crowdChanceBoost, table.concat(reasons, ", ")))
end

local function isValidLoot(state, loot, lootRecord, activated)
    if loot.type == T.Container then
        if not mTypes.isAnalyzed(state.containers[loot.id])
                or mTypes.hasWares(state.containers[loot.id])
                or not mObj.isValidContainer(state, lootRecord) then
            return false
        end
    else
        if not mObj.isValidActor(state, lootRecord)
                or activated and T.Actor.isDead(loot) then
            return false
        end
    end

    if not mObj.hasValidInventory(loot) then
        return false
    end
    return true
end

local function shouldProcessLoot(loot, activated)
    if loot.type == T.Container then
        if T.Lockable.isLocked(loot) then
            return false
        end
    else
        -- dialogue with actors: Do nothing
        if activated then
            return false
        end
    end
    return true
end

local function onContainerOpen(state, loot, activated)
    if mTypes.isAccessed(mObj.getLootData(state, loot)) then return end

    local lootRecord = mObj.getRecord(loot)
    if not isValidLoot(state, loot, lootRecord, activated) then
        log(string.format("\"%s\" won't be processed anymore", loot.recordId))
        if loot.type == T.Container then
            mTypes.setAccessed(state.containers, loot, mTypes.new.containerData)
        else
            mTypes.setEquipped(state.actors, loot, mTypes.new.actorData)
            mTypes.setAccessed(state.actors, loot, mTypes.new.actorData)
        end
        return
    end
    if not shouldProcessLoot(loot, activated) then
        log(string.format("\"%s\" should not be processed yet", loot.recordId))
        return
    end
    if loot.type == T.Container then
        mTypes.setAccessed(state.containers, loot, mTypes.new.containerData)
    else
        mTypes.setEquipped(state.actors, loot, mTypes.new.actorData)
    end

    local ownerId = loot.type == T.Container and loot.owner.recordId or (loot.type == T.NPC and loot.recordId or nil)
    local itemsData = getItems(state, loot, ownerId)
    if #itemsData == 0 then return end

    -- if the mod is disabled, don't convert item, but tag accessed loots
    if not state.settings[mStore.cfg.enabled.key] then return end

    local ownerWealth
    if ownerId then
        ownerWealth = state.npcsWealth[ownerId]
    elseif loot.type == T.Creature then
        ownerWealth = mTypes.new.wealthStat(mObj.getItemsValueSum(loot), 1)
    end
    local maxWealthValue
    if ownerWealth then
        local maxWealthRatio = state.settings[ownerId and mStore.cfg.maxModsValueOverNpcWealth.key or mStore.cfg.maxModsValueOverCreatureWealth.key]
        if maxWealthRatio ~= 0 then
            maxWealthValue = (ownerWealth.total / math.max(1, ownerWealth.npcCount)) * maxWealthRatio / 100
        end
        log(string.format("\"%s\"'s inventory wealth is %d, max expense is %d", loot.recordId, ownerWealth.total, maxWealthValue))
    end
    local ctx = mTypes.new.lootContext(loot, lootRecord, ownerId, ownerWealth, maxWealthValue)

    if loot.type == T.Container then
        local boosts = { state.containers[loot.id].boosts }
        mHelpers.addArrayToArray(boosts, state.containers[loot.id].doorsBoosts)
        if #boosts > 0 then
            ctx.boosts = mStats.mergeBoosts(boosts)
        end
    end
    ctx.boosts = ctx.boosts or mTypes.new.lockableBoosts(0, 0, 0)

    setLootLevel(state, ctx)
    if ctx.lootLevel == 0 then return end

    local baseChance = state.settings[mStore.cfg.firstModifierChance.key] / 100
    local crowdChanceBoost, lootLevelChanceBoost, lockChanceBoost, trapChanceBoost, waterDepthChanceBoost = 0, 0, 0, 0, 0
    if loot.type == T.Container then
        if state.settings[mStore.cfg.enableCrowdChanceBoost.key] then
            crowdChanceBoost = ctx.crowdChanceBoost * baseChance
        end
        lootLevelChanceBoost = math.min(1, (ctx.lootLevel / state.settings[mStore.cfg.endGameLootLevel.key]) ^ 2)
                * state.settings[mStore.cfg.maxLootLevelChanceBoost.key] / 100
        lockChanceBoost = ctx.boosts.lock * state.settings[mStore.cfg.maxLockChanceBoost.key] / 100
        trapChanceBoost = ctx.boosts.trap * state.settings[mStore.cfg.maxTrapChanceBoost.key] / 100
        waterDepthChanceBoost = ctx.boosts.waterDepth * state.settings[mStore.cfg.maxWaterDepthChanceBoost.key] / 100
    end
    ctx.chanceBoost = crowdChanceBoost + lootLevelChanceBoost + lockChanceBoost + trapChanceBoost + waterDepthChanceBoost
    local firstModChance = baseChance + ctx.chanceBoost
    log(string.format("First mod chance for loot \"%s\" is base %.2f + crowd %.2f + loot lvl %.2f + lock %.2f + trap %.2f + water depth %.2f = %.2f",
            ctx.loot.recordId, baseChance, crowdChanceBoost, lootLevelChanceBoost, lockChanceBoost, trapChanceBoost, waterDepthChanceBoost, firstModChance), mTypes.logLevels.Debug)

    local conversionCount = 0
    local itemsToEquip = {}
    for _, itemData in ipairs(itemsData) do
        if itemData.item.count > 0 then
            local lootLevel = ctx.lootLevel
            local doConvert = false
            if math.random() < firstModChance then
                doConvert = true
            elseif loot.type ~= T.Container and itemData.item.type == T.Weapon and math.random() < state.settings[mStore.cfg.equippedWeaponSecondChance.key] / 100 then
                doConvert = true
                ctx.lootLevel = math.max(1, lootLevel * state.settings[mStore.cfg.equippedWeaponSecondChanceLootLevelRatio.key] / 100)
                log(string.format("Actor \"%s\" got his weapon converted thanks to a second chance, with a loot level reduced to %.1f", ctx.loot.recordId, ctx.lootLevel), mTypes.logLevels.Debug)
            end
            if doConvert then
                ctx.item = mTypes.new.itemContext(itemData.record, itemData.item.type)
                local inventoryItem = convertItem(state, itemData.item, ctx)
                if inventoryItem then
                    conversionCount = conversionCount + 1
                    if inventoryItem.slot then
                        table.insert(itemsToEquip, inventoryItem)
                    end
                end
                ctx.lootLevel = lootLevel
            end
        end
    end
    if conversionCount > 0 then
        log(string.format("Converted %d items in loot \"%s\"", conversionCount, loot.recordId))
        if loot.type == T.Container then
            if not loot:hasScript(mDef.containerScriptPath) then
                loot:addScript(mDef.containerScriptPath, {})
            end
        elseif not loot:hasScript(mDef.actorScriptPath) then
            loot:addScript(mDef.actorScriptPath, {})
        end
        if ownerId then
            log(string.format("\"%s\"'s (owner \"%s\") spent %d to convert items", loot.recordId, ownerId, state.npcsWealth[ownerId].spent))
        end
    end
    if #itemsToEquip ~= 0 then
        loot:sendEvent(mDef.events.equipItems, itemsToEquip)
    end

    -- clear data not useful anymore
    if loot.type == T.Container then
        state.containers[loot.id].levelStats = {}
        state.containers[loot.id].levelStatsOverride = nil
        state.containers[loot.id].boosts = nil
        state.containers[loot.id].doorsBoosts = nil
    end
end
module.onContainerOpen = onContainerOpen

local function filterConvertedItems(state, items)
    local convertedItems = {}
    for _, item in ipairs(items) do
        local data = state.items[item.id]
        if data then
            local lvlMods = {}
            for _, lvlModId in ipairs(data.lvlModIds) do
                local mod = state.cache.modifiers[lvlModId.id]
                if mod then
                    table.insert(lvlMods, mTypes.new.lvlMod(mTypes.new.modLayoutData(mod), lvlModId.lvl))
                else
                    log(string.format("Could not find mod %s", lvlModId.id))
                end
            end
            table.insert(convertedItems, mTypes.new.convertedItemEventData(item, mObj.getRecord(item).name, lvlMods))
        else
            log(string.format("Item %s is not a converted one", mObj.objectId(item)), mTypes.logLevels.Debug)
        end
    end
    return convertedItems
end
module.filterConvertedItems = filterConvertedItems

return module