local types = require'openmw.types'

local events = require'scripts.styxd.stackmaster.events'
local StackInfo = require'scripts.styxd.stackmaster.StackInfo'

local M = {}

M.eventHandlers = {}

M.eventHandlers[events.ReturnStack.eventName] = function(eventData)
    local playerInventory = types.Actor.inventory(eventData.player)
    local info = StackInfo.new(eventData.stackInfoProps)
    local inventoryStack = info:findInInventory(playerInventory)

    if inventoryStack then
        info:teleportToStackPosition(inventoryStack, eventData.keepOneItem)
    end
end

return M
