require("CraftingFramework.mcm")
require("CraftingFramework.components.RecoverMaterials")
require("CraftingFramework.components.CraftingEvents")
require("CraftingFramework.test")

local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("CraftingFramework")
local metadata = toml.loadMetadata("The Crafting Framework")

--Register crafting menu with RightClickMenuExit
event.register(tes3.event.initialized, function()
    local RightClickMenuExit = include("mer.RightClickMenuExit")
    if RightClickMenuExit and RightClickMenuExit.registerMenu then
        RightClickMenuExit.registerMenu{
            menuId = "CF_Menu",
            buttonId = "Crafting_Menu_CancelButton"
        }
    end
    logger:info("Initialized v%s", metadata.package.version)
end)