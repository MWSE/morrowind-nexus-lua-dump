local this = {}

-- Name to identify this module.
this.name = "Disabled"
this.consumeVersion = 1.2

local shared = require("partyAlchemy.shared")


--- Add click events to inventory tiles for interactive administering of potions.
-- Our main logic for seeing if a potion can be consumed or not.
function this.onItemTileUpdated(e)
    -- Ensure it's a supported item.
    if not (e.item.id == "misc_pa_flask") then
        return
    end

    -- Register a new click event for when we drop a potion on it.
    e.element:registerBefore("mouseClick", function()
        local success, c = pcall(function()
            -- Get the thing that is currently on the cursor tile.
            local c = tes3ui.findHelpLayerMenu("CursorIcon"):getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
            -- Ensure it's an alchemy object.
            return assert(
                c.item.objectType == tes3.objectType.alchemy
                and c
            )
        end)
        if success then
            local companion = e.menu:getPropertyObject("MenuContents_Actor")
            
            if companion then
                shared.administerPotionInteractive(companion.reference, c.item, c.itemData)
            end
        end
    end)
end

-- Callback for when this module is set as the active one.
function this.onSetActive()
	-- Setup the events we care about.
  event.register("itemTileUpdated", this.onItemTileUpdated, { filter = "MenuContents" })
end

-- Callback for when this module is turned off.
function this.onSetInactive()
	-- Remove the events we cared about.
  event.unregister("itemTileUpdated", this.onItemTileUpdated, { filter = "MenuContents" })
end

return this