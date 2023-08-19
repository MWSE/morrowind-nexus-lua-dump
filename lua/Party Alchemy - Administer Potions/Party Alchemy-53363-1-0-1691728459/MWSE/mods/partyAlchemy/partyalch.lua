local config = require("partyAlchemy.config")


--- Administer the potion on the given NPC, interactively.
---
--- Player-only, the weapon/poison must be present in the player's inventory.
---
--- @param reference tes3reference
--- @param potion tes3alchemy
--- @param potionData tes3itemData|nil
local function administerPotionInteractive(reference, potion, potionData)
    -- callback for 1-frame delay so NPC can receive item to then remove it from their inventory
    local function callback(e)
        -- administer potion to the NPC
        tes3.applyMagicSource{reference=reference, source=potion.id}
        -- this consumes the potion from NPC inventory
        tes3.removeItem{reference=reference, item=potion, itemData=potionData, playSound=false} --Sound\Fx\item\drink.wav
        tes3.playSound{
            reference = tes3.player,
            soundPath = 'Fx\\item\\drink.wav'
        }
    end
    
    --wait for item to land so it can be removed
    timer.frame.delayOneFrame(callback)
end

--- Add click events to inventory tiles for interactive administering of potions.
local function addPAClickEvent(e)
    -- Ensure it's a supported item.
    if not (e.item.id == "misc_pa_flask") then
        return
    end

    -- Register a new click event for when we drop a potion on it.
    e.element:registerBefore("mouseClick", function()
        local success, c = pcall(function()
            -- Get the thing that is currently on the cursor tile.
            local c = tes3ui.findHelpLayerMenu("CursorIcon"):getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
            -- Ensure it's a alchemy object.
            return assert(
                c.item.objectType == tes3.objectType.alchemy
                and c
            )
        end)
        if success then
            local companion = e.menu:getPropertyObject("MenuContents_Actor")
            
            if companion then
                administerPotionInteractive(companion.reference, c.item, c.itemData)
            end
        end
    end)
end
event.register("itemTileUpdated", addPAClickEvent, { filter = "MenuContents" })
