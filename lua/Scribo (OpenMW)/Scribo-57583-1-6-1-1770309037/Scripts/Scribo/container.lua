local types = require('openmw.types')
local world = require('openmw.world')
local player = world.players[1]


local function findInContainers(itemId)
    local inventory = types.Actor.inventory(player)
    if inventory:find(itemId) ~= nil  then
        return true
    else
        local ttItems = world.getCellByName("ToddTest"):getAll(types.Container)        
        local miscConts = inventory:getAll(types.Miscellaneous)
        for _, misc in ipairs(miscConts) do
            for index, value in ipairs(ttItems) do
                if (value.id == misc.id) then
                    local inventoryCont  = types.Container.inventory(value)
                    if inventoryCont:find(itemId) ~= nil then return true end
                end
            end            
        end
    end
    return false
end

local function countInContainers(itemId)
    
    local inventory = types.Actor.inventory(player)
    local count = inventory:count(itemId)

    local ttItems = world.getCellByName("ToddTest"):getAll(types.Container)        
    local miscConts = inventory:getAll(types.Miscellaneous)
    for _, misc in ipairs(miscConts) do
        for index, value in ipairs(ttItems) do
            if (value.id == misc.id) then
                local inventoryCont  = types.Container.inventory(value)
                count = count + inventoryCont:count(itemId)
            end
        end            
    end
    return count
end

local function removeFromInventory(inventory, itemId, countRemove)
    local count = inventory:count(itemId)
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
    
    local inventory = types.Actor.inventory(player)
    local restRemove = removeFromInventory(inventory, itemId, count)    
    if restRemove == 0 then return end

    local ttItems = world.getCellByName("ToddTest"):getAll(types.Container)        
    local miscConts = inventory:getAll(types.Miscellaneous)
    for _, misc in ipairs(miscConts) do
        for index, value in ipairs(ttItems) do
            if (value.id == misc.id) then
                local inventoryCont  = types.Container.inventory(value)
                restRemove = removeFromInventory(inventoryCont, itemId, restRemove)

                if restRemove == 0 then return end
            end
        end            
    end
    return count
end

local function testContainers()
    local inventory = types.Actor.inventory(player)
    local ttItems = world.getCellByName("ToddTest"):getAll(types.Container)        
    local miscConts = inventory:getAll(types.Miscellaneous)
    for _, misc in ipairs(miscConts) do
        for index, value in ipairs(ttItems) do
            --§print("test container: ", value.recordId, misc.recordId)
            if (value.id == misc.id) then
                print("Container: ", value.id, misc.id)
            end
        end            
    end
end

return {
    find = findInContainers,
    count = countInContainers,
    remove = removeInContainers,
    test = testContainers
}