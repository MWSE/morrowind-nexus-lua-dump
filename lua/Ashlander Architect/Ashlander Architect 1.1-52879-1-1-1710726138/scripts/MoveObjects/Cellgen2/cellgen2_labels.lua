local structureData = require("scripts.MoveObjects.StructureData")
local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")

local cellNames = {}
local cellGenStorage = storage.globalSection("AACellGen2")

cellGenStorage:set("cellNames", {})
local function getCellName(baseCellName)
    if not cellNames[baseCellName] then
        return baseCellName
    else
        return cellNames[baseCellName]
    end
end
local function setCellName(baseCellName, newCellName)
    cellNames[baseCellName] = newCellName
    cellGenStorage:set("cellNames", cellNames)
end

return {
    interfaceName = "AA_CellGen_2_Labels",
    interface = {
        version = 1,
        setCellName = setCellName,
        getCellName = getCellName,
    },
    eventHandlers = {
        cellRename2 = function(data)
            local originalCell = data.originalCell
            local text = data.text
            setCellName(originalCell,text)
        end
    },
    engineHandlers = {
        onSave = function() return { cellNames = cellNames } end,
        onLoad = function(data)
            if not data then
                return
            end
            cellNames = data.cellNames
            cellGenStorage:set("cellNames", cellNames)
        end
    }
}
