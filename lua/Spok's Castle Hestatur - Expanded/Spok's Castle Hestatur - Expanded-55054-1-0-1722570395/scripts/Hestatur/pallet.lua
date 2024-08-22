
local currentPalletCell = "hestatur, attic"
local world = require("openmw.world")
local types = require("openmw.types")
local function onSave()
    return{
        currentPalletCell = currentPalletCell
    }
end
local function onLoad(data)
    if data then
        currentPalletCell = data.currentPalletCell
    end
end

local function movePalletToCell(newCellId)
    local oldCell = world.getCellById(currentPalletCell)
    local newCell = world.getCellById(newCellId)
    if not oldCell or not newCell or oldCell == newCell then
        return
    end

    local palletContainers = {}
    local palletObj
    local palletMarker
    --print("going forward")
    for index, obj in ipairs(oldCell:getAll()) do
        if (obj.recordId):sub(1,17) == ("zhac_pallet_cont_") then
            table.insert(palletContainers, obj)
        elseif obj.recordId == "zhac_hestatur_pallet" then
            palletObj = obj
        end
    end
    for index, obj in ipairs(newCell:getAll()) do
        if obj.recordId == "zhac_hestatur_pallet_marker" then
            palletMarker = obj
            break
        end
    end
    for index, cont in ipairs(palletContainers) do
        local relativePos = cont.position - palletObj.position
        cont:teleport(newCell, palletMarker.position + relativePos, cont.rotation)
    end
    palletObj:teleport(newCell, palletMarker.position, palletObj.rotation)
    currentPalletCell = newCellId
end

return {
    eventHandlers = {movePalletToCell = movePalletToCell},
    engineHandlers = {
        onObjectActive = onObjectActive,
        onSave = onSave,
        onLoad = onLoad,
    }
}