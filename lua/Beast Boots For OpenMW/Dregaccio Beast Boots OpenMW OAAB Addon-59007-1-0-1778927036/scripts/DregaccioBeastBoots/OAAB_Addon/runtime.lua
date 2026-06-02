-- Dregaccio Beast Boots OpenMW Lua runtime
-- This script swaps normal boot records to beast-compatible clones only at runtime.
local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')

local SCAN_INTERVAL = 0.70
local busy = false
local elapsed = SCAN_INTERVAL

local toBeast = {
    ["ab_a_bonemlightboots"] = "dregbb_cec2bd90722cbfa0",
    ["ab_a_bugblueboots"] = "dregbb_11f8a2abc5f328fa",
    ["ab_a_buggreenboots"] = "dregbb_7916c4e33a1e7f43",
    ["ab_a_dreughboots"] = "dregbb_576634a6f6ab9626",
    ["ab_a_irondeboots"] = "dregbb_f61bb39fe55f5447",
    ["ab_a_steelboots"] = "dregbb_eeedb922aa1825cd",
}
local toNormal = {}
for normal, beast in pairs(toBeast) do toNormal[beast] = normal end


local function lower(value)
    if value == nil then return nil end
    return string.lower(tostring(value))
end

local function safe(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function isValidObject(obj)
    return obj ~= nil and safe(function() return obj:isValid() end) == true
end

local function isActor(obj)
    return isValidObject(obj) and types.Actor.objectIsInstance(obj)
end

local function npcRecord(actor)
    if not isActor(actor) or not types.NPC.objectIsInstance(actor) then return nil end
    return safe(types.NPC.record, actor)
end

local function raceRecord(raceId)
    if raceId == nil then return nil end
    local rec = safe(types.NPC.races.record, raceId)
    if rec ~= nil then return rec end
    return safe(types.NPC.races.record, lower(raceId))
end

local function isBeastActor(actor)
    local rec = npcRecord(actor)
    if rec == nil or rec.race == nil then return false end
    local race = raceRecord(rec.race)
    return race ~= nil and race.isBeast == true
end

local function isBootOrShoe(item)
    if not isValidObject(item) then return false end
    if types.Armor.objectIsInstance(item) then
        local rec = safe(types.Armor.record, item)
        return rec ~= nil and rec.type == types.Armor.TYPE.Boots
    end
    if types.Clothing.objectIsInstance(item) then
        local rec = safe(types.Clothing.record, item)
        return rec ~= nil and rec.type == types.Clothing.TYPE.Shoes
    end
    return false
end

local function copyItemState(source, target)
    local sourceData = safe(types.Item.itemData, source)
    local targetData = safe(types.Item.itemData, target)
    if sourceData ~= nil and targetData ~= nil then
        pcall(function() targetData.condition = sourceData.condition end)
        pcall(function() targetData.enchantmentCharge = sourceData.enchantmentCharge end)
        pcall(function() targetData.soul = sourceData.soul end)
    end
    if source.owner ~= nil and target.owner ~= nil then
        pcall(function() target.owner.recordId = source.owner.recordId end)
        pcall(function() target.owner.factionId = source.owner.factionId end)
        pcall(function() target.owner.factionRank = source.owner.factionRank end)
    end
end

local function equippedInBootSlot(actor, item)
    if not isActor(actor) or not isValidObject(item) then return false end
    local okHasEquipped = safe(types.Actor.hasEquipped, actor, item)
    if okHasEquipped == true then return true end
    local equipped = safe(types.Actor.getEquipment, actor, types.Actor.EQUIPMENT_SLOT.Boots)
    return equipped == item
end

local function useItem(actor, item)
    if not isActor(actor) or not isValidObject(item) then return end
    core.sendGlobalEvent('UseItem', { object = item, actor = actor, force = true })
end

local function targetRecordFor(actor, item)
    if not isBootOrShoe(item) then return nil end
    local id = lower(item.recordId)
    if id == nil then return nil end
    if isBeastActor(actor) then
        return toBeast[id]
    else
        return toNormal[id]
    end
end

local function replaceInventoryItem(actor, item, targetRecordId, equipAfter)
    if not isActor(actor) or not isValidObject(item) or targetRecordId == nil then return nil end
    local count = item.count or 1
    if count < 1 then count = 1 end
    local inventory = types.Actor.inventory(actor)
    local replacement = world.createObject(targetRecordId, count)
    copyItemState(item, replacement)
    replacement:moveInto(inventory)
    item:remove(count)
    if equipAfter == true then
        useItem(actor, replacement)
    end
    return replacement
end

local function processItem(actor, item, forceEquip)
    if busy or not isActor(actor) or not isValidObject(item) then return false end
    local target = targetRecordFor(actor, item)
    if target == nil or lower(item.recordId) == lower(target) then return false end
    busy = true
    local shouldEquip = forceEquip == true or equippedInBootSlot(actor, item)
    local ok = pcall(replaceInventoryItem, actor, item, target, shouldEquip)
    busy = false
    return ok
end

local function scanInventory(actor)
    if busy or not isActor(actor) then return end
    local inventory = types.Actor.inventory(actor)
    if inventory == nil then return end
    local armors = safe(function() return inventory:getAll(types.Armor) end) or {}
    for _, item in ipairs(armors) do
        processItem(actor, item, false)
    end
    local clothing = safe(function() return inventory:getAll(types.Clothing) end) or {}
    for _, item in ipairs(clothing) do
        processItem(actor, item, false)
    end
end

local function scanActors()
    if busy then return end
    local seen = {}
    for _, player in ipairs(world.players) do
        if isActor(player) and player.id ~= nil and not seen[player.id] then
            seen[player.id] = true
            scanInventory(player)
        end
    end
    for _, actor in ipairs(world.activeActors) do
        if isActor(actor) and actor.id ~= nil and not seen[actor.id] then
            seen[actor.id] = true
            scanInventory(actor)
        end
    end
end

local function itemUsageHandler(item, actor)
    if busy or not isActor(actor) or not isValidObject(item) then return nil end
    local target = targetRecordFor(actor, item)
    if target == nil or lower(item.recordId) == lower(target) then return nil end
    processItem(actor, item, true)
    return false
end

I.ItemUsage.addHandlerForType(types.Armor, itemUsageHandler)
I.ItemUsage.addHandlerForType(types.Clothing, itemUsageHandler)

return {
    engineHandlers = {
        onUpdate = function(dt)
            elapsed = elapsed + dt
            if elapsed >= SCAN_INTERVAL then
                elapsed = 0
                scanActors()
            end
        end,
    },
    eventHandlers = {
        DregaccioBeastBootsScan = function()
            scanActors()
        end,
    },
}
