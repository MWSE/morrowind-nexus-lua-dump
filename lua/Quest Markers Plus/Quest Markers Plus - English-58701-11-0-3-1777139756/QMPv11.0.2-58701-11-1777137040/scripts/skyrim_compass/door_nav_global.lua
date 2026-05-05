local world = require('openmw.world')
local types = require('openmw.types')

local MAX_DEPTH = 4

local function safeDestCell(door)
    local ok, cell = pcall(function() return types.Door.destCell(door) end)
    if ok then return cell end
end

local function findExitDoors(cell, depth, checked)
    if not cell or depth > MAX_DEPTH then return {} end
    if checked[cell.id] then return {} end
    checked[cell.id] = true

    local results = {}
    for _, door in pairs(cell:getAll(types.Door)) do
        if types.Door.isTeleport(door) and door.enabled then
            local dc = safeDestCell(door)
            if dc then
                if dc.isExterior then
                    table.insert(results, { x = door.position.x, y = door.position.y, z = door.position.z })
                else
                    local deeper = findExitDoors(dc, depth + 1, checked)
                    if #deeper > 0 then
                        table.insert(results, { x = door.position.x, y = door.position.y, z = door.position.z })
                    end
                end
            end
        end
    end
    return results
end

return {
    eventHandlers = {
        ["SkyrimCompass:findExitDoors"] = function(data)
            if not data.cellId or not data.player then return end
            local cell = world.getCellById(data.cellId)
            if not cell then return end
            local doors = findExitDoors(cell, 1, {})
            data.player:sendEvent("SkyrimCompass:exitDoorsFound", { doors = doors })
        end,
    },
}
