local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local v3 = require("openmw.util").vector3
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local camera = require("openmw.camera")
local input = require("openmw.input")
local ui = require("openmw.ui")
local async = require("openmw.async")
local availableSnapPoints = {}

local function onSave()
return {availableSnapPoints = availableSnapPoints}
end
local function onLoad(data)
if not data then return end
availableSnapPoints = data.availableSnapPoints

end
local function addObject(object,data)

end
return {
interfaceName = "AA_Snapping",
interface = {},
    engineHandlers =    {
        onSave = onSave,
        onLoad = onLoad,
    }
    ,
    eventHandlers = {

    }
}