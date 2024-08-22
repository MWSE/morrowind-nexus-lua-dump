
local this = {}

---@param cell tes3cell
---@return tes3reference|nil
function this.getRandomDoorMarker(cell)
    local marker
    local markers = {}
    for mrk in cell:iterateReferences(tes3.objectType.static) do
        if mrk.isLocationMarker and mrk.id:lower() == "doormarker" then
            table.insert(markers, mrk)
        end
    end
    if #markers > 0 then
        marker = markers[math.random(#markers)]
    end
    return marker
end

---@return tes3reference
function this.getRandomExteriorDoorMarker()
    local marker
    while marker == nil do
        local cell = tes3.dataHandler.nonDynamicData.cells[math.random(#tes3.dataHandler.nonDynamicData.cells)]
        if cell.isOrBehavesAsExterior then
            marker = this.getRandomDoorMarker(cell)
        end
    end
    return marker
end

---@param cell tes3cell
---@return tes3reference|nil
function this.getExitExteriorMarker(cell, checkedDoors)
    if cell.isOrBehavesAsExterior then
        return nil
    end
    if not checkedDoors then checkedDoors = {} end
    local markers = {}
    for door in cell:iterateReferences(tes3.objectType.door) do
        if door.destination and not checkedDoors[door] then
            checkedDoors[door] = true
            if door.destination.cell.isOrBehavesAsExterior then
                table.insert(markers, door.destination.marker)
            else
                local marker = this.getExitExteriorMarker(door.destination.cell, checkedDoors)
                if marker then
                    table.insert(markers, marker)
                end
            end
        end
    end
    if #markers > 0 then
        return markers[math.random(#markers)]
    end
    return nil
end

return this