local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local function getItemRecord(item)
    local recordId = item.recordId
    if not recordId then return nil end

    local record = nil
    pcall(function() record = types.Ingredient.record(recordId) end)
    if not record then pcall(function() record = types.Potion.record(recordId) end) end
    if not record then pcall(function() record = types.Miscellaneous.record(recordId) end) end
    if not record then pcall(function() record = types.Weapon.record(recordId) end) end
    if not record then pcall(function() record = types.Armor.record(recordId) end) end
    if not record then pcall(function() record = types.Clothing.record(recordId) end) end
    if not record then pcall(function() record = types.Book.record(recordId) end) end
    if not record then pcall(function() record = types.Light.record(recordId) end) end
    if not record then pcall(function() record = types.Lockpick.record(recordId) end) end
    if not record then pcall(function() record = types.Probe.record(recordId) end) end
    if not record then pcall(function() record = types.Apparatus.record(recordId) end) end
    if not record then pcall(function() record = types.Repair.record(recordId) end) end

    return record
end

local function getItemValue(item)
    local record = getItemRecord(item)
    if record and record.value then
        return record.value
    end
    return 0
end

local function getItemWeight(item)
    local record = getItemRecord(item)
    if record and record.weight then
        return record.weight
    end
    return 0
end

local function getOwnerInfo(obj)
    local ownerNpc = nil
    local ownerFaction = nil
    local ownerFactionRank = 0

    -- Check the .owner object
    if obj.owner then
        pcall(function() ownerNpc = obj.owner.recordId end)
        pcall(function() ownerFaction = obj.owner.factionId end)
        pcall(function() ownerFactionRank = obj.owner.factionRank or 0 end)
    end

    return ownerNpc, ownerFaction, ownerFactionRank
end

local function getInventory(target, isCorpse)
    if isCorpse then
        return types.Actor.inventory(target)
    else
        return types.Container.inventory(target)
    end
end

-- Check if taking an item would be theft for the given player
-- Mirrors engine logic from MechanicsManager::isAllowedToUse
local function isTheft(player, ownerNpc, ownerFaction, ownerFactionRank)
    if ownerNpc then
        return true
    end
    if ownerFaction then
        local playerRank = types.NPC.getFactionRank(player, ownerFaction)
        return playerRank < (ownerFactionRank or 0)
    end
    return false
end

local function onTakeAll(data)
    local target = data.target
    local player = data.player
    local isCorpse = data.isCorpse or false

    if not target or not target:isValid() then
        player:sendEvent('TakeAllResult', { count = 0 })
        return
    end

    -- Corpses don't have ownership (looting the dead is legal)
    local targetOwnerNpc, targetOwnerFaction, targetOwnerFactionRank = nil, nil, 0
    if not isCorpse then
        targetOwnerNpc, targetOwnerFaction, targetOwnerFactionRank = getOwnerInfo(target)
    end

    local targetInventory = getInventory(target, isCorpse)
    local playerInventory = types.Actor.inventory(player)
    local itemCount = 0
    local totalValue = 0
    local totalWeight = 0
    local stolenValue = 0

    local items = targetInventory:getAll()

    -- Copy the list since we're modifying it
    local itemsToMove = {}
    for _, item in ipairs(items) do
        table.insert(itemsToMove, item)
    end

    for _, item in ipairs(itemsToMove) do
        -- Check item ownership (inherit from container if item has none)
        -- Corpse items are never stolen
        local itemOwnerNpc, itemOwnerFaction, itemOwnerFactionRank = nil, nil, 0
        if not isCorpse then
            itemOwnerNpc, itemOwnerFaction, itemOwnerFactionRank = getOwnerInfo(item)
            if not itemOwnerNpc then itemOwnerNpc = targetOwnerNpc end
            if not itemOwnerFaction then
                itemOwnerFaction = targetOwnerFaction
                itemOwnerFactionRank = targetOwnerFactionRank
            end
        end

        local isStolen = isTheft(player, itemOwnerNpc, itemOwnerFaction, itemOwnerFactionRank)
        local itemValue = getItemValue(item)
        local itemWeight = getItemWeight(item)
        local stackCount = item.count or 1

        totalValue = totalValue + (itemValue * stackCount)
        totalWeight = totalWeight + (itemWeight * stackCount)

        if isStolen then
            stolenValue = stolenValue + (itemValue * stackCount)
        end

        item:moveInto(playerInventory)
        itemCount = itemCount + stackCount
    end

    -- Commit theft crime if any items were stolen
    if stolenValue > 0 then
        pcall(function()
            if I.Crimes and I.Crimes.commitCrime then
                I.Crimes.commitCrime(player, {
                    type = types.Player.OFFENSE_TYPE.Theft,
                    arg = stolenValue,
                    faction = targetOwnerFaction,
                })
            end
        end)
    end

    -- Dispose of corpse if requested
    if data.disposeCorpse and target:isValid() then
        target:remove()
    end

    -- Send result back to player
    player:sendEvent('TakeAllResult', {
        count = itemCount,
        value = totalValue,
        weight = totalWeight,
    })
end

return {
    eventHandlers = {
        TakeAllRequest = onTakeAll,
    },
}
