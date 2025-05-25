local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local Debug = require("scripts.TakeAll.takeAll_debug")

-- Initialize with debug message
Debug.log("TakeAll", "Global script initialized")

-- Activation queues - this follows QuickLoot's approach exactly
local activateNextUpdate = {}
local activateSecondNextUpdate = {}
local deleteSecondNextUpdate = {}
local openedGUIs = {} -- Track opened GUIs

-- Process the activation queue - copied directly from QuickLoot's onUpdate function
local function onUpdate(dt)
    for _, t in pairs(activateNextUpdate) do
        local item = t[1]
        local player = t[2]
        local container = t[3]

        Debug.log("TakeAll", "Processing item: " .. item.type.records[item.recordId].name)

        -- Set ownership if container is provided
        if container then
            Debug.log("TakeAll", "Setting ownership for: " .. item.type.records[item.recordId].name)
            item.owner.factionId = container.owner.factionId
            item.owner.factionRank = container.owner.factionRank
            item.owner.recordId = container.owner.recordId
        end

        -- Activate the item
        Debug.log("TakeAll", "Activating item: " .. item.type.records[item.recordId].name)
        item:activateBy(player)
    end

    -- Handle deleted corpses
    for i, t in pairs(deleteSecondNextUpdate) do
        if t[2] > 1 then
            t[2] = 1
        else
            Debug.log("TakeAll", "Removing corpse: " .. t[1].recordId)
            t[1]:remove(1)
            table.remove(deleteSecondNextUpdate, i)
        end
    end

    -- Move second queue to first queue and clear second queue
    activateNextUpdate = activateSecondNextUpdate
    activateSecondNextUpdate = {}
end

-- Take a single item
local function take(data)
    if not data or #data < 3 then
        Debug.error("TakeAll_Global", "Invalid data received in take event")
        return
    end

    local player = data[1]
    local container = data[2]
    local item = data[3]
    local isPickpocketing = data[4] or false

    Debug.log("TakeAll", "Global take received for: " .. item.type.records[item.recordId].name)

    -- For pickpocketing or books, move directly
    if isPickpocketing or item.type == types.Book then
        item:moveInto(types.Player.inventory(player))
        return true
        -- Special handling for gold - needs delayed activation
    elseif item.recordId == "gold_001" or item.recordId == "gold_005" or
        item.recordId == "gold_010" or item.recordId == "gold_025" or
        item.recordId == "gold_100" then
        item:teleport(player.cell, player.position, player.rotation)
        table.insert(activateSecondNextUpdate, { item, player, container })
        return true
        -- Regular items
    else
        item:teleport(player.cell, player.position, player.rotation)
        item.owner.factionId = container.owner.factionId
        item.owner.factionRank = container.owner.factionRank
        item.owner.recordId = container.owner.recordId
        table.insert(activateNextUpdate, { item, player })
        return true
    end
end

-- Take all items from a container
local function takeAll(data)
    if not data or #data < 2 then
        Debug.error("TakeAll_Global", "Invalid data received in takeAll event")
        return 0
    end

    local player = data[1]
    local container = data[2]
    local disposeCorpse = data[3] or false

    Debug.log("TakeAll", "TakeAll received for container: " .. container.recordId)

    -- Ensure the container is resolved
    types.Container.inventory(container):resolve()

    local itemCount = 0

    -- Process all items
    for _, item in pairs(types.Container.inventory(container):getAll()) do
        local itemRecord = item.type.records[item.recordId]

        Debug.log("TakeAll", "Processing container item: " .. item.recordId)

        -- Skip uncarriable items
        if not itemRecord.name or itemRecord.name == "" or not types.Item.isCarriable(item) then
            Debug.log("TakeAll", "Skipping uncarriable item: " .. item.recordId)
            -- Books move directly
        elseif item.type == types.Book then
            Debug.log("TakeAll", "Moving book directly: " .. itemRecord.name)
            item:moveInto(types.Player.inventory(player))
            itemCount = itemCount + 1
            -- Gold needs special handling
        elseif item.recordId == "gold_001" or item.recordId == "gold_005" or
            item.recordId == "gold_010" or item.recordId == "gold_025" or
            item.recordId == "gold_100" then
            Debug.log("TakeAll", "Gold handling: " .. item.recordId)
            item:teleport(player.cell, player.position, player.rotation)
            table.insert(activateSecondNextUpdate, { item, player, container })
            itemCount = itemCount + 1
            -- Standard items
        else
            Debug.log("TakeAll", "Standard item handling: " .. itemRecord.name)
            item:teleport(player.cell, player.position, player.rotation)
            item.owner.factionId = container.owner.factionId
            item.owner.factionRank = container.owner.factionRank
            item.owner.recordId = container.owner.recordId
            table.insert(activateNextUpdate, { item, player })
            itemCount = itemCount + 1
        end
    end

    -- Handle corpse disposal if needed
    if disposeCorpse and types.Actor.objectIsInstance(container) and types.Actor.isDead(container) then
        Debug.log("TakeAll", "Queueing corpse disposal for: " .. container.recordId)
        table.insert(deleteSecondNextUpdate, { container, 2 })
    end

    return itemCount
end

-- Take a book
local function takeBook(data)
    if not data or #data < 2 then
        Debug.error("TakeAll_Global", "Invalid data received in takeBook event")
        return
    end

    local player = data[1]
    local book = data[2]

    Debug.log("TakeAll", "Taking book: " .. book.type.records[book.recordId].name)

    -- Move the book to player's inventory
    book:moveInto(types.Player.inventory(player))

    return true
end

-- Register event handlers and engine callbacks
return {
    interfaceName = "TakeAll_Global",
    interface = {},
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        TakeAll_take = take,
        TakeAll_takeAll = takeAll,
        TakeAll_takeBook = takeBook,
        TakeAll_test = function(data)
            Debug.log("TakeAll", "Test event received: " .. tostring(data[1]))
            return true
        end,
        TakeAll_openGUI = function(playerObject)
            openedGUIs[playerObject.id] = world.getGameTime()
        end,
        TakeAll_closeGUI = function(playerObject)
            openedGUIs[playerObject.id] = nil
        end
    }
}
