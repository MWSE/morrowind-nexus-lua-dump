local common = require("Keyboard Layout Changer.common")
local config = require("Keyboard Layout Changer.config").getConfig()

local function onInitialized()
    common.log("Changing layout to " .. config.keyboardLayout)
    common.changeLayout(config.keyboardLayout)
end

event.register("initialized", onInitialized)

event.register("modConfigReady", function()
    mwse.mcm.register(require("Keyboard Layout Changer.mcm"))
end)
