local types = require("openmw.types")
local world = require("openmw.world")

local exploredCells = {}

local function cellCheck(cell)
    -- cell:getAll() is available only in the global scope
    for _, door in pairs(cell:getAll(types.Door)) do
        local destCell = types.Door.destCell(door)
        if destCell == nil then goto continue end

        if exploredCells[destCell.id] then
            goto continue
        else
            exploredCells[cell.id] = true
        end

        if destCell.isExterior then
            if destCell.region == "red mountain region" then
                return true
            end
        elseif cellCheck(destCell) then
            return true
        end
        ::continue::
    end
    return false
end

local function isCellInRM(cellId)
    exploredCells = {}
    local cell = world.getCellById(cellId)
    local result = cellCheck(cell)
    world.players[1]:sendEvent("updateInRM", result)
end

return {
    eventHandlers = {
        isCellInRM = isCellInRM
    }
}
