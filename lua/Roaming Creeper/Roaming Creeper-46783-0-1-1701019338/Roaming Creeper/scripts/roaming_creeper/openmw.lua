local function include(moduleName)
    local status, result = pcall(require, moduleName)
    if (status) then
        return result
    end
end

I = include("openmw.interfaces")
types = include("openmw.types")
util = include("openmw.util")
core = include("openmw.core")
async = include("openmw.async")
storage = include("openmw.storage")
vfs = include("openmw.vfx")
world = include("openmw.world")
self = include("openmw.self")
nearby = include("openmw.nearby")
input = include("openmw.input")
ambient = include("openmw.ambient")
ui = include("openmw.ui")
camera = include("openmw.camera")
postprocessing = include("openmw.postprocessing")
debug = include("openmw.debug")
calendar = include("openmw_aux.calendar")
aux_util = include("openmw_aux.util")
time = include("openmw_aux.time")
aux_ui = include("openmw_aux.ui")
