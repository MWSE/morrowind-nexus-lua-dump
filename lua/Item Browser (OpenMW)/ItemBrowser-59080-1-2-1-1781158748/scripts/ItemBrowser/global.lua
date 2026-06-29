local world = require('openmw.world')
local types = require('openmw.types')

local itemIndex = require('scripts.ItemBrowser.item_index')

local MAX_ITEM_QUANTITY = 2147483647

local function player()
    return world.players and world.players[1] or nil
end

local function sendToPlayer(eventName, data)
    local p = player()
    if p and p:isValid() then
        p:sendEvent(eventName, data)
    end
end

local function onSearchRequest(data)
    local ok, result = pcall(function()
        data = data or {}
        return itemIndex.search(data)
    end)

    if ok then
        sendToPlayer('ItemBrowser_SearchResults', result)
    else
        sendToPlayer('ItemBrowser_SearchError', { message = tostring(result) })
    end
end

local function onDetailRequest(data)
    local ok, result = pcall(function()
        data = data or {}
        return itemIndex.details(data.recordId)
    end)

    if ok and result then
        sendToPlayer('ItemBrowser_ItemDetails', result)
    elseif not ok then
        sendToPlayer('ItemBrowser_SearchError', { message = tostring(result) })
    end
end

local function onAddItemRequest(data)
    data = data or {}
    if data.allowAdd == false then
        sendToPlayer('ItemBrowser_AddResult', { ok = false, key = 'message_add_disabled' })
        return
    end

    local recordId = tostring(data.recordId or '')
    local item = itemIndex.find(recordId)
    if not item then
        sendToPlayer('ItemBrowser_AddResult', { ok = false, key = 'message_not_found', recordId = recordId })
        return
    end

    local p = player()
    if not p or not p:isValid() then
        return
    end

    local quantity = math.min(MAX_ITEM_QUANTITY, math.max(1, math.floor(tonumber(data.quantity) or 1)))
    local ok, err = pcall(function()
        world.createObject(item.id, quantity):moveInto(types.Player.inventory(p))
    end)

    if ok then
        sendToPlayer('ItemBrowser_AddResult', {
            ok = true,
            key = 'message_added',
            recordId = item.id,
            name = item.displayName,
            quantity = quantity,
        })
    else
        sendToPlayer('ItemBrowser_AddResult', {
            ok = false,
            key = 'message_add_failed',
            recordId = item.id,
            message = tostring(err),
        })
    end
end

return {
    eventHandlers = {
        ItemBrowser_SearchRequest = onSearchRequest,
        ItemBrowser_DetailRequest = onDetailRequest,
        ItemBrowser_AddItemRequest = onAddItemRequest,
    },
}
