local mcm = require("sb_MPS.mcm")
local ui = require("sb_MPS.ui")

mcm.init()

--- @param e simulateEventData
local function simulateCallback(e)
    local format = "%i, %i, %i"
    local coords = tes3.player.position
    local divisor = 8192;

    if (mcm.config.units == 1) then
        format = "%i m, %i m, %i m"
        coords = tes3vector3.new(coords.x / 69.99104, coords.y / 69.99104, coords.z / 69.99104)
        divisor = 8192 / 69.99104
    elseif (mcm.config.units == 2) then
        format = "%i ft, %i ft, %i ft"
        coords = tes3vector3.new((coords.x / 69.99104) * (1.0 / 0.3048), (coords.y / 69.99104) * (1.0 / 0.3048), (coords.z / 69.99104) * (1.0 / 0.3048))
        divisor = (8192 / 69.99104) * (1.0 / 0.3048)
    end

    if (mcm.config.style == 0 or (mcm.config.style == 1 and tes3.player.cell.isInterior)) then
        ui.coords.text = string.format(format, math.round(coords.x), math.round(coords.y), math.round(coords.z))
    elseif (mcm.config.style == 1) then
        ui.coords.text = string.format("%i, %i - " .. format, tes3.player.cell.gridX, tes3.player.cell.gridY, math.round(coords.x) % divisor, math.round(coords.y) % divisor, math.round(coords.z))
    elseif (mcm.config.style == 2) then
        if (tes3.player.cell.isInterior) then
            local closestDoor
            for reference in tes3.player.cell:iterateReferences(tes3.objectType.door) do
                if (closestDoor == nil) then
                    closestDoor = reference
                elseif (reference.position:distance(tes3.player.position) < closestDoor.position:distance(tes3.player.position) and closestDoor.destination and closestDoor.destination.cell.isInterior == false) then
                    closestDoor = reference
                end
            end
            
            if (closestDoor) then
                local exteriorCell = closestDoor.destination.cell
                ui.coords.text = string.format("%i, %i - " .. format, exteriorCell.gridX, exteriorCell.gridY, math.round(coords.x), math.round(coords.y), math.round(coords.z))
            else
                ui.coords.text = string.format("???, ??? - " .. format, math.round(coords.x), math.round(coords.y), math.round(coords.z))
            end
        else
            ui.coords.text = string.format("%i, %i - " .. format, tes3.player.cell.gridX, tes3.player.cell.gridY, math.round(coords.x) % divisor, math.round(coords.y) % divisor, math.round(coords.z))
        end
    end
end

--- @param e initializedEventData
local function initializedCallback(e)
    ui.init()
    event.register(tes3.event.simulate, simulateCallback)
end
event.register(tes3.event.initialized, initializedCallback)