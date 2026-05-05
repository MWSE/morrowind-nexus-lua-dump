local world = require('openmw.world')

local function DP_DVD_sendPlayerCells(e)
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
        end
    end

    player:sendEvent('DP_DVD_fromGlobal', {
        value = result
    })
end

return {
    eventHandlers = {
        DP_DVD_sendPlayerCells = DP_DVD_sendPlayerCells
    }
}