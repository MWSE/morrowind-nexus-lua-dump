local tatau = require("sb_tatau.interop")
local tattooList = require("sb_remi_tattoos.tattoos")
local crafting = require("CraftingFramework.components.MenuActivator")
local recipeList = require("sb_remi_tattoos.recipes")

local function onInitialized()
    for _, tattoo in pairs(tattooList) do
        tatau:register(tattoo)
    end
    tatau:registerAll()
    crafting:new(
    ---@type CraftingFramework.MenuActivator.data
        {
            id = "sb_tattooshop",
            name = "Vellus Acorius: Tattooist",
            type = "event",
            recipes = recipeList,
            craftButtonText = "Buy Tattoo",
            recipeHeaderText = "Available Tattoos",
            customRequirementsHeaderText = "",
            materialsHeaderText = "Cost",
            menuHeight = math.min(800, tes3.worldController.viewHeight * 0.66),
            menuWidth = math.min(720 * 1.5, tes3.worldController.viewWidth * 0.66),
            -- previewHeight = 0,
            -- previewWidth = 0
        }
    )
end
event.register("initialized", onInitialized)

--- @param e loadedEventData
local function loadedCallback(e)
    if (tes3.player.data["sb_remi_tattoos"] == nil) then
        tes3.player.data["sb_remi_tattoos"] = {}
    end
end
event.register(tes3.event.loaded, loadedCallback)

--- @param e bodyPartsUpdatedEventData
local function bodyPartsUpdatedCallback(e)
    if (e.reference == tes3.player) then
        tatau:prepare(tes3.player)
        if (tes3.player.data["sb_remi_tattoos"]) then
            for _, tatId in pairs(tes3.player.data["sb_remi_tattoos"]) do
                tatau:applyTattoo(tes3.player, tatId)
            end
        end
    end
end
event.register(tes3.event.bodyPartsUpdated, bodyPartsUpdatedCallback)

--- @param e activateEventData
local function activateCallback(e)
    if (e.activator == tes3.player and e.target.baseObject.id == "rem_tat_inkwell_01") then
        event.trigger("sb_tattooshop")
    end
end
event.register(tes3.event.activate, activateCallback)
