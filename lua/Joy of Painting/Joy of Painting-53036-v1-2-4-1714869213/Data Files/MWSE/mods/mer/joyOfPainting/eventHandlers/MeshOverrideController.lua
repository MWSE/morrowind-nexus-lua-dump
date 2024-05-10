local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("MeshOverrideController")
--- @param e meshLoadEventData
local function manageMeshLoad(e)
    --logger:debug(e.path)
    local override = config.meshOverrides[e.path:lower()]
    if override then
        logger:debug("Overriding mesh %s with %s", e.path, override)
        e.path = override
    end
end
event.register("meshLoad", manageMeshLoad)