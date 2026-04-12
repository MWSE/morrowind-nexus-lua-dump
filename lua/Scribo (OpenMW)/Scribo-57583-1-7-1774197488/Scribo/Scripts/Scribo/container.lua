local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')
local player = world.players[1]

local function getContainers( near )
    local allConts = {}    
    if I.CCC_cont and I.CCC_cont.getContainersCarriedByPlayer then
        local conts = I.CCC_cont.getContainersCarriedByPlayer()
        for _, cont in ipairs(conts) do
            table.insert(allConts, cont)
        end
    end
    if near and I.CCC_cont and I.CCC_cont.getContainersNearbyPlayer then
        local conts = I.CCC_cont.getContainersNearbyPlayer()
        for _, cont in ipairs(conts) do
            table.insert(allConts, cont)
        end
    end
    return allConts
end

local function getInventories( near )
    local invents = {}
    local allConts = getContainers(near)    
    table.insert(invents, types.Actor.inventory(player))
    for _, cont in ipairs(allConts) do
        table.insert(invents, types.Container.inventory(cont))
    end
    return invents
end


local function findInContainers(itemId)
    local invents = getInventories()
    for _, inventory in ipairs(invents) do
        if inventory:find(itemId) ~= nil then return true end
    end            
    return false
end

local function countInContainers(itemId)
    local count = 0
    local invents = getInventories()
    for _, inventory in ipairs(invents) do
        count = count + (inventory:countOf(itemId) or 0)
    end            
    return count
end

local function removeFromInventory(inventory, itemId, countRemove)
    local count = inventory:countOf(itemId)
    local toRemove = math.min(countRemove, count)

    if toRemove > 0 then
        local item = inventory:find(itemId)
        if item then
            item:remove(toRemove)
            countRemove = countRemove - toRemove
        end
    end

    return countRemove
end

local function removeInContainers(itemId, count)
    local restRemove = count
    local invents = getInventories()
    for _, inventory in ipairs(invents) do
        restRemove = removeFromInventory(inventory, itemId, restRemove)
        if restRemove == 0 then return end
    end       
end


return {
    find = findInContainers,
    count = countInContainers,
    remove = removeInContainers,
}