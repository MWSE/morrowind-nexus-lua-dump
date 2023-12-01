
local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")
local util = require("openmw.util")



return {
    interfaceName = "CellGenData",
    interface = {
        version = 1,
        cellData = cellData,
    }
}
