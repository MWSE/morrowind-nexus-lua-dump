local core = require("openmw.core")
local self = require("openmw.self")

local mDef = require("scripts.fresh-loot.config.definition")

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        revertLoot = function() return core.sendGlobalEvent(mDef.events.revertLoot, self) end,
    },
}
