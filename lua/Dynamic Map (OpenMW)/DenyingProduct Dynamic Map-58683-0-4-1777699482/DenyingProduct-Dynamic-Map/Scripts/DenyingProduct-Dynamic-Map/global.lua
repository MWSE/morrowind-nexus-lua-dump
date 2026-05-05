local world = require('openmw.world')

local function sendPlayerCells(e)
    local player = e.actor
    if not player then return end

    local result = {}

    for _, cell in pairs(world.cells) do
        if cell.isExterior and cell.name and cell.name ~= "" then
            table.insert(result, {
                name = cell.name,
                x = cell.gridX,
                y = cell.gridY
            })
            -- print("CELL:", cell.name)
            -- print("  gridX:", cell.gridX)
            -- print("  gridY:", cell.gridY)
            -- print("  pos:", cell.position and cell.position.x, cell.position and cell.position.y)
            -- print("-----")
        end
    end

    player:sendEvent('fromGlobal', {
        message = "Hello from global script!",
        value = result
    })
end

return {
    eventHandlers = {
        sendPlayerCells = sendPlayerCells
    }
}