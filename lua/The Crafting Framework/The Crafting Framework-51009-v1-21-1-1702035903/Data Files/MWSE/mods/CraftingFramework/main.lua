require("CraftingFramework.mcm")
require("CraftingFramework.components.RecoverMaterials")
require("CraftingFramework.components.CraftingEvents")
require("CraftingFramework.test")
require("CraftingFramework.carryableContainers")

local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("CraftingFramework")
local metadata = toml.loadMetadata("The Crafting Framework") --[[@as MWSE.Metadata]]
local config = require("CraftingFramework.config")
local CraftingFramework = require("CraftingFramework")

event.register(tes3.event.initialized, function()
    --Register crafting menu with RightClickMenuExit
    local RightClickMenuExit = include("mer.RightClickMenuExit")
    if RightClickMenuExit and RightClickMenuExit.registerMenu then
        RightClickMenuExit.registerMenu{
            menuId = "CF_Menu",
            buttonId = "Crafting_Menu_CancelButton"
        }
    end

    --Register default configs
    local SoundType = CraftingFramework.SoundType
    for id, sounds in pairs(config.static.defaultConstructionSounds) do
        SoundType.register{
            id = id,
            soundPaths = sounds
        }
    end

    logger:info("Initialized v%s", metadata.package.version)

end)

event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.CraftingFramework = CraftingFramework
end)

event.register("initialized", function()
    config.initialized = true
end, { priority = 0x7FFFFFFF})

---Ensure all carryable containers can be accessed in crafting
CraftingFramework.MaterialStorage:new{
    isStorage = function (self, reference)
        local isCarryable = CraftingFramework.CarryableContainer.isCarryableContainer(reference)
        logger:debug("%s is %sa carryable container", reference.object.name, isCarryable and "" or "NOT ")
        return CraftingFramework.CarryableContainer.isCarryableContainer(reference)
    end,
}