local Interop = {}
local common = require("mer.RightClickMenuExit.common")
local config = common.config
local logger = common.createLogger("Interop")

---@class RightClickMenuExit.registerMenu.params
---@field menuId string
---@field buttonId string

---@param e RightClickMenuExit.registerMenu.params
Interop.registerMenu = function(e)
    assert(e.menuId, "menuId is required")
    assert(e.buttonId, "buttonId is required")
    logger:debug("Registering menu %s with button %s", e.menuId, e.buttonId)
    config.registeredButtons[e.menuId] = {
        closeButton = e.buttonId
    }
end

return Interop