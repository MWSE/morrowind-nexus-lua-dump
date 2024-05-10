local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("MeshOverrideController")

local MeshService = {}

function MeshService.registerOverride(id, override)
    local obj = tes3.getObject(id)
    if not obj then
        logger:error("Could not find object %s", id)
        return
    end
    local originalMesh = "meshes\\" .. obj.mesh:lower()
    logger:debug("Registering mesh override for %s: %s -> %s", id, originalMesh, override)
    config.meshOverrides[originalMesh] = override:lower()
end

return MeshService