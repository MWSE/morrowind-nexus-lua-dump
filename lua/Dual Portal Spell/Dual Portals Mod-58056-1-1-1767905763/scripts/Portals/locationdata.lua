local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(math.rad(z))
        return rotate
    end
end
local data = {
    ulanababia = {
        cellId = "ulanababia, shrine",
        position = util.vector3(4039.006591796875, 692.10540771484375, 14785),
        rotation = createRotation(0,0,0.743894)
    },
    ballFell = {
        cellId = "bal fell, inner shrine",
        position = util.vector3(4605.26025390625, 5413.45654296875, 14465),
        rotation = createRotation(0,0,0.56275)
    }
}


return {
    interfaceName = "PortalLocs",
    interface = {data = data
    },P
}
