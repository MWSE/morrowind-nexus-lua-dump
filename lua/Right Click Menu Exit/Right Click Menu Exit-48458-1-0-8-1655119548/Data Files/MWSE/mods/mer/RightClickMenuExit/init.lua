local Interop = {}
local config = require("mer.RightClickMenuExit.config")

Interop.registerMenu = function(e)
    assert(e.menuId, "menuId is required")
    assert(e.buttonId, "buttonId is required")
    mwse.log("[RightClickMenuExit] Registering Menu %s with button %s", e.menuId, e.buttonId)
    table.insert(config.buttonMapping, (#config.buttonMapping-2), {
        menu = e.menuId,
        button = e.buttonId
    })
end

return Interop