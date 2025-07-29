local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local util = require('openmw.util')

-- for activating books in your inventory
I.ItemUsage.addHandlerForType(types.Book, function(bookObject, activatingActor)
    activatingActor:sendEvent('openmwBooksEnhancedBookActivated', { activatedBookObject = bookObject })
    return true
end)

local function takeItemIntoPlayerInventory(data)
    -- Hacky way of triggering a stealing ingame, courtesy of @zackhasacat
    if data.isStolen then
        local idOfTempItem = "misc_com_bottle_13"
        local bounty = math.max(1, types.Book.records[data.bookObject.recordId].value)
        local tempStolenObjectToTriggerCrime = world.createObject(
            idOfTempItem,
            bounty)
        tempStolenObjectToTriggerCrime.enabled = true
        tempStolenObjectToTriggerCrime.owner.recordId = data.bookObject.owner.recordId
        tempStolenObjectToTriggerCrime.owner.factionId = data.bookObject.owner.factionId
        tempStolenObjectToTriggerCrime.owner.factionRank = data.bookObject.owner.factionRank
        tempStolenObjectToTriggerCrime:teleport(data.player.cell, data.player.position)

        world._runStandardActivationAction(tempStolenObjectToTriggerCrime, data.player)

        data.player:sendEvent(
            'openmwBooksEnhancedRemoveTempStolenItem',
            { player = data.player, tempStolenItemId = idOfTempItem, amountToRemove = bounty })
    end
    data.bookObject:moveInto(types.Player.inventory(data.player))
end

local function removeTempObjectsUsedToTriggerCrime(data)
    while data.amountToRemove > 0 do
        local tempItemToRemove = types.Player.inventory(data.player):find(data.tempStolenItemId)
        if tempItemToRemove then
            tempItemToRemove:remove(1)
        end
        data.amountToRemove = data.amountToRemove - 1
    end
end


return {
    eventHandlers = {
        openmwBooksEnhancedBookTaken = takeItemIntoPlayerInventory,
        openmwBooksEnhancedBookStolenSoRemoveTempObjectsNowThatTickHasPassed = removeTempObjectsUsedToTriggerCrime,
    }
}
