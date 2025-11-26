local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local world = require('openmw.world')

local function takeItemIntoPlayerInventory(data)
    if data.isStolen then
        local bounty = math.max(1, types.Book.records[data.bookObject.recordId].value)
        if not core.API_REVISION or core.API_REVISION < 96 then
            -- Hacky way of triggering a stealing ingame from before openmw having a Crime interface, courtesy of @daisyhasacat
            local idOfTempItem = "misc_com_bottle_13"
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
        else
            local crimes = require('openmw.interfaces').Crimes
            crimes.commitCrime(
                data.player,
                {
                    arg = bounty,
                    faction = data.bookObject.owner.factionId,
                    type = types.Player.OFFENSE_TYPE.Theft
                }
            )
        end
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

local function processBookItemForGatheredVariables(data)
    local bookRecord = types.Book.records[data.activatedBookObject.recordId]
    local bookText = bookRecord.text
    if not string.find(bookText, "%%") then
        data.player:sendEvent('openmwBooksEnhancedBookActivated', { activatedBookObject = data.activatedBookObject, replacedBookText = nil })
        return
    end

    local globalVariables = world.mwscript.getGlobalVariables(data.player)
    local gatheredVariableValues = {}
    local playerRecord = types.Player.record(data.player)
    for w in string.gmatch(bookText, "%%([%w_]+)") do
        if string.lower(w) == "pcname" then
            gatheredVariableValues[w] = playerRecord.name
        elseif string.lower(w) == "pcclass" then
            gatheredVariableValues[w] = types.Player.classes.records[playerRecord.class].name
        elseif string.lower(w) == "pcrace" then
            gatheredVariableValues[w] = types.Player.races.records[playerRecord.race].name
        else
            gatheredVariableValues[w] = globalVariables[w]
        end
    end

    for pattern, value in pairs(gatheredVariableValues) do
        bookText = string.gsub(bookText, "%%" .. pattern, value)
    end

    data.player:sendEvent('openmwBooksEnhancedBookActivated', { activatedBookObject = data.activatedBookObject, replacedBookText = bookText })
end


return {
    eventHandlers = {
        openmwBooksEnhancedBookTaken = takeItemIntoPlayerInventory,
        openmwBooksEnhancedBookStolenSoRemoveTempObjectsNowThatTickHasPassed = removeTempObjectsUsedToTriggerCrime,
        openmwBooksEnhancedBookTakenCheckItForVariables = processBookItemForGatheredVariables,
    }
}
