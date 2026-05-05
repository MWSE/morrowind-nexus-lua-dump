
local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local commonConteiners = {
    ["tin_crate_02"] = true,
    ["tin_crate_seashell"] = true,
    ["tin_barrel_01"] = true,
    ["tin_crate_06"] = true,
}

local commonConteinersCells = {
    ["vivec, dank nook"] = true,
    ["kumul"] = true,
    ["Esm3ExteriorCell:-3:-2"] = true,
    ["Esm3ExteriorCell:1:-7"] = true,
}

local function getContainerCells()
    local cells = {}
    for _, cell in ipairs(world.cells) do
        if commonConteinersCells[cell.id] then
            table.insert(cells, cell)
        end
    end
    return cells
end

local cells = getContainerCells()

local function getCommonContainers(contId)
    local containers = {}

    for _, cell in ipairs(cells) do
        for _, obj in ipairs(cell:getAll(types.Container)) do
            if commonConteiners[obj.recordId] and obj.recordId ~= contId then
                table.insert(containers, obj)
            end
        end
    end
    return containers
end


local function collectContainers(data)
    local currContainer = data.container

    if commonConteiners[currContainer.recordId] then
        local inventory = types.Container.inventory(data.container)
        local containers = getCommonContainers(currContainer.recordId)
        
        for _, containerFrom in ipairs(containers) do
            local inventoryFrom = types.Container.inventory(containerFrom)
            for _, item in ipairs(inventoryFrom:getAll()) do
                item:moveInto(inventory)
            end
        end
    end    
end

I.ItemUsage.addHandlerForType(types.Container, function(item, actor)
    collectContainers({container=item})    
end)


return {
    eventHandlers = {
        hrCollectConteiners = collectContainers,

        hrRemoveActor = function(data)
            local actor = data.actor
            actor:sendEvent('RemoveAIPackages', 'Combat')
 
            if actor and actor.remove then
                actor:remove()
                return true
            end
        end
    }
}

