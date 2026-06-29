local async = require('openmw.async')
local types = require('openmw.types')
local world = require('openmw.world')

local activeObjects = {}
local recordSources = {
    types.Apparatus.records,
    types.Armor.records,
    types.Book.records,
    types.Clothing.records,
    types.Ingredient.records,
    types.Light.records,
    types.Lockpick.records,
    types.Miscellaneous.records,
    types.Potion.records,
    types.Probe.records,
    types.Repair.records,
    types.Weapon.records,
}

local supportedLooseTypes = {
    [types.Apparatus] = true,
    [types.Armor] = true,
    [types.Book] = true,
    [types.Clothing] = true,
    [types.Ingredient] = true,
    [types.Light] = true,
    [types.Lockpick] = true,
    [types.Miscellaneous] = true,
    [types.Potion] = true,
    [types.Probe] = true,
    [types.Repair] = true,
    [types.Weapon] = true,
}

local function player()
    return world.players and world.players[1] or nil
end

local function sendToPlayer(eventName, data)
    local p = player()
    if p and p:isValid() then
        p:sendEvent(eventName, data)
    end
end

local function isSupportedObject(object)
    if not object or not object:isValid() then
        return false
    end
    return object.type == types.Container
        or types.Actor.objectIsInstance(object)
        or supportedLooseTypes[object.type] == true
end

local function addActiveObject(object)
    if isSupportedObject(object) then
        activeObjects[object.id] = object
    end
end

local function isCurrentPlayer(object)
    local p = player()
    return p and object and object:isValid() and object.id == p.id
end

local function isInPlayerSpace(object)
    local p = player()
    return p
        and p:isValid()
        and object
        and object:isValid()
        and object.enabled
        and object.cell
        and p.cell
        and p.cell:isInSameSpace(object)
end

local function favoriteSet(ids)
    local set = {}
    for _, id in ipairs(ids or {}) do
        set[tostring(id)] = true
    end
    return set
end

local function hasItem(inventory, itemId)
    local ok, count = pcall(function()
        return inventory:countOf(itemId)
    end)
    return ok and (tonumber(count) or 0) > 0
end

local function itemRecordInfo(itemId)
    for _, records in ipairs(recordSources) do
        local ok, record = pcall(function()
            return records[itemId]
        end)
        if ok and record then
            local info = { name = itemId }
            local nameOk, name = pcall(function()
                return record.name
            end)
            if nameOk and name and name ~= '' then
                info.name = tostring(name)
            end

            local iconOk, icon = pcall(function()
                return record.icon
            end)
            if iconOk and icon and icon ~= '' then
                info.icon = tostring(icon)
            end

            return info
        end
    end
    return { name = itemId }
end

local function containerInventory(object, resolveUnresolved)
    if object.type ~= types.Container then
        return nil
    end

    local ok, inventory = pcall(types.Container.inventory, object)
    if not ok or not inventory then
        return nil
    end

    if inventory:isResolved() then
        return inventory
    end

    if resolveUnresolved then
        local resolved = pcall(function()
            inventory:resolve()
        end)
        if resolved and inventory:isResolved() then
            return inventory
        end
    end

    return nil
end

local function actorInventory(object)
    if isCurrentPlayer(object) or not types.Actor.objectIsInstance(object) then
        return nil
    end

    local ok, inventory = pcall(types.Actor.inventory, object)
    if ok and inventory and inventory:isResolved() then
        return inventory
    end
    return nil
end

local function appendResult(resultsById, itemId, object)
    local result = resultsById[itemId]
    if not result then
        local info = itemRecordInfo(itemId)
        result = {
            itemId = itemId,
            name = info.name,
            icon = info.icon,
            objects = {},
        }
        resultsById[itemId] = result
    end
    result.objects[#result.objects + 1] = object
end

local function scan(data)
    data = data or {}
    local ids = data.favoriteIds or {}
    local favorites = favoriteSet(ids)
    local trackContainers = data.trackContainers == true
    local trackActorInventories = data.trackActorInventories == true
    local resolveUnresolvedContainers = data.resolveUnresolvedContainers == true
    local resultsById = {}

    for _, actor in ipairs(world.activeActors or {}) do
        addActiveObject(actor)
    end

    for objectId, object in pairs(activeObjects) do
        if not isInPlayerSpace(object) then
            activeObjects[objectId] = nil
        else
            if favorites[object.recordId] then
                appendResult(resultsById, object.recordId, object)
            end

            local inventory
            if trackContainers then
                inventory = containerInventory(object, resolveUnresolvedContainers)
            end
            if not inventory and trackActorInventories then
                inventory = actorInventory(object)
            end

            if inventory then
                for _, itemId in ipairs(ids) do
                    if itemId ~= object.recordId and hasItem(inventory, itemId) then
                        appendResult(resultsById, itemId, object)
                    end
                end
            end
        end
    end

    local results = {}
    for _, itemId in ipairs(ids) do
        if resultsById[itemId] then
            results[#results + 1] = resultsById[itemId]
        end
    end

    sendToPlayer('ItemBrowserProximityTool_ScanResults', { results = results })
end

return {
    engineHandlers = {
        onObjectActive = async:callback(addActiveObject),
        onActorActive = async:callback(addActiveObject),
        onItemActive = async:callback(addActiveObject),
    },
    eventHandlers = {
        ItemBrowserProximityTool_ScanRequest = scan,
    },
}
