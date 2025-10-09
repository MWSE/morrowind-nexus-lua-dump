local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local acti = require("openmw.interfaces").Activation
local base_64 = require("scripts.MoveObjects.utility.base_64")
local settlementList = {}
local time = require('openmw_aux.time')
local myModData = storage.globalSection("AASettlements")
local treeData = {}
local config = require("scripts.MoveObjects.config")
if not config.isUpdated then
    error("Your OpenMW version is too old!" )
end


local function serializeCellObjects(cellId, onlyNewObjects)
    onlyNewObjects = onlyNewObjects ~= nil
   -- print(onlyNewObjects)
    local cell = world.getCellById(cellId)

    local text = I.CellSave.serializeObjectLs(cell:getAll())
    --print(text)
    local encoded = base_64.encode_base64(text)
    
    world.players[1]:sendEvent("showExportText",encoded)
   -- local decoded = base_64.decode_base64(encoded)
   -- print(decoded)
    return encoded
end

return{
    interfaceName = "CellExport",
    interface = {
        serializeCellObjects = serializeCellObjects,
        serializeCell = serializeCell,
        codeTest = codeTest,
        serializeObjectLs = serializeObjectLs,
    },
    eventHandlers = {
        serializeCellObjects = serializeCellObjects,
    }
}