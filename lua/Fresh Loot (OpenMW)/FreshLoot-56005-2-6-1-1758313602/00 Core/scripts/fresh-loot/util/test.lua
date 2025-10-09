local core = require("openmw.core")
local T = require("openmw.types")
local world = require("openmw.world")

local mCfg = require("scripts.fresh-loot.config.configuration")
local mDef = require("scripts.fresh-loot.config.definition")
local mTypes = require("scripts.fresh-loot.config.types")
local mConvert = require("scripts.fresh-loot.loot.convert")
local mMod = require("scripts.fresh-loot.loot.modifier")
local mWorld = require("scripts.fresh-loot.util.world")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local module = {}

local function cPrint(msg)
    for _, player in ipairs(world.players) do
        player:sendEvent(mDef.events.printToConsole, msg)
    end
end

local function testPickModifiers(state, lootLevel, alpha)
    local prevAlpha
    if alpha then
        prevAlpha = mCfg.modifierLevel.pickAlpha
        mCfg.modifierLevel.pickAlpha = alpha
    end
    local levels = {  }
    for _ = 1, mCfg.modifierLevel.maxLevel do
        table.insert(levels, 0)
    end
    for _ = 1, 100000 do
        local lvl = mMod.getRandomModifierLevel(state, lootLevel)
        levels[lvl] = levels[lvl] + 1
    end
    local sum = 0
    for i = 1, mCfg.modifierLevel.maxLevel do
        sum = sum + levels[i]
    end
    local counts = {}
    for i = 1, mCfg.modifierLevel.maxLevel do
        table.insert(counts, string.format("%d=%2.4f%%", i, 100 * levels[i] / sum))
    end
    cPrint(string.format("Alpha %s ; Item level %s ; Levels %s",
            mCfg.modifierLevel.pickAlpha, lootLevel, table.concat(counts, ", ")))
    if prevAlpha then
        mCfg.modifierLevel.pickAlpha = prevAlpha
    end
end
module.testPickModifiers = testPickModifiers

local function testItemModifiers(state, itemId, lootLevel)
    local record, type
    for _, itemType in ipairs({ T.Armor, T.Clothing, T.Weapon }) do
        local itemRecord = itemType.records[itemId]
        if itemRecord then
            type = itemType
            record = itemRecord
        end
    end
    local cacheTypes = { state.cache.modifierTypes.props, state.cache.modifierTypes.effects }
    local affixTypes = { mTypes.affixTypes.Any }
    local stats = {}

    for _ = 1, 10000 do
        local lvlMod = mConvert.pickLevelledModifier(state, cacheTypes, affixTypes, type,
                { lootLevel = lootLevel, item = { record = record, lvlMods = {} }, })
        if lvlMod then
            stats[lvlMod.mod.id] = (stats[lvlMod.mod.id] or 0) + 1
        end
    end
    local bestStats = {}
    local function setBestStats()
        for modId, count in mHelpers.spairs(stats, function(t, a, b) return t[a] > t[b] end) do
            table.insert(bestStats, string.format("%s: %4d", modId, count))
            if #bestStats == 100 then return end
        end
    end
    setBestStats()

    cPrint(string.format("Most frequent mods for item \"%s\" and loot level %d:\n%s", itemId, lootLevel, table.concat(bestStats, "\n\t")))
end
module.testItemModifiers = testItemModifiers

local function showFactionRankStats(state)
    local messages = { "" }
    for factionId, factionStats in pairs(state.factionRanksLevel) do
        table.insert(messages, string.format("Average actor level per rank in faction \"%s\": %.2f", factionId, factionStats.sum / factionStats.count))
    end
    cPrint(string.format("Actor stats:%s", table.concat(messages, "\n    ")))
end
module.showFactionRankStats = showFactionRankStats

local function showWealthStats(state)
    local messages = { "" }
    for _, actor in pairs(mWorld.getActiveActors()) do
        if actor.type == T.NPC then
            local wealth = state.npcsWealth[actor.recordId]
            if wealth then
                table.insert(messages, string.format("\"%s\": total=%d, spent=%d, npcCount=%d", actor.recordId, wealth.total, wealth.spent, wealth.npcCount))
            end
        end
    end
    cPrint(string.format("NPCs' wealth stats:%s", table.concat(messages, "\n    ")))
end
module.showWealthStats = showWealthStats

local function getActorFromRecordId(recordId)
    for _, actor in ipairs(world.activeActors) do
        if actor.recordId == recordId then
            return actor
        end
    end
end

local function createItem(recordId, count, modId1, lvl1, modId2, lvl2, actorRecordId)
    local actor
    if actorRecordId then
        actor = getActorFromRecordId(actorRecordId)
        if not actor then
            core.sendGlobalEvent(mDef.events.sendPlayersEvent, mTypes.new.playersEvent(mDef.events.showMessage, mTypes.new.message(
                    string.format("Could not find actor \"%s\"", actorRecordId))))
            return
        end
    else
        actor = world.players[1]
    end
    local item = world.createObject(recordId, 1)
    item:moveInto(actor.type.inventory(actor))
    core.sendGlobalEvent(mDef.events.convertTestItem, { item = item, count = count, modId1 = modId1, lvl1 = lvl1, modId2 = modId2, lvl2 = lvl2, actor = actor })
end
module.createItem = createItem

local function convertTestItem(state, item, count, modId1, lvl1, modId2, lvl2, actor)
    local lvlMods = {
        mTypes.new.lvlMod(state.cache.modifiers[modId1], lvl1)
    }
    if modId2 then
        table.insert(lvlMods, mTypes.new.lvlMod(state.cache.modifiers[modId2], lvl2))
    end

    local record = mObj.getRecord(item)
    local recordPatch, _ = mConvert.buildModdedRecord(item.type, record, lvlMods)
    local newRecord = mWorld.createRecord(item.type, recordPatch, record)
    local inventoryItem = mWorld.replaceItem(actor, item, record, count, newRecord, count)
    state.items[inventoryItem.item.id] = mTypes.new.itemData(inventoryItem.item, count, record.id, mMod.lvlModsToLvlModIds(lvlMods))
end
module.convertTestItem = convertTestItem

return module