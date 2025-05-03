local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("Carryable Containers")

local Initializer = require("CraftingFramework.util.initializer"):new{
    modPath = "mods/CraftingFramework/carryableContainers",
    logger = logger
}
Initializer:initAll("interops")
Initializer:initAll("eventHandlers")
local components = Initializer:initAll("components")

event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.carryableContainers = components
end)
