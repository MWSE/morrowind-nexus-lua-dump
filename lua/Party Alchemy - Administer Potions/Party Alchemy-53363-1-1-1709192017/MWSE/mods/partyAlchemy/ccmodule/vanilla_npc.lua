local this = {}

local CCshared = require("Controlled Consumption.shared")
local shared = require("partyAlchemy.shared")


-- Name to identify this module.
this.name = "Vanilla NPC Style"
this.consumeVersion = 1.2


-- We use a simple timestamp to keep track of each follower's consumption state.
local lastConsumed = {}

-- Cooldown time.
local cooldownTime = 5

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
            
            local timeLeft = (((lastConsumed[companion.reference.id] or 0) + (cooldownTime / (3600 / tes3.getGlobal("timescale")))) - tes3.getSimulationTimestamp())
            
            if companion and timeLeft <= 0 then
                local data = shared.getPersistentData()
                data.shan.consume.lastAdministered = tes3.getSimulationTimestamp()
                
                shared.administerPotionInteractive(companion.reference, c.item, c.itemData)
                lastConsumed[companion.reference.id] = tes3.getSimulationTimestamp()
            else
                tes3.messageBox("You must wait another %d seconds before giving another potion to %s.", (timeLeft * (3600 / tes3.getGlobal("timescale"))), companion.reference.object.name)
            end
        end
    end)
end

-- Set any remaining timestamps so that they persist through saves.
function this.onSave(e)
	local data = shared.getPersistentData()
  
  if data.shan.consume.lastConsumed == nil then
      data.shan.consume.lastConsumed = {}
  end

  for k, v in pairs(lastConsumed) do
    if (v + cooldownTime) > tes3.getSimulationTimestamp() then
        data.shan.consume.lastConsumed[k] = v
    else
        data.shan.consume.lastConsumed[k] = nil
    end
  end
end

-- Loaded event. Resume any consumption restrictions.
function this.onLoaded(e)
	-- Ensure our potion expiry list is empty.
	lastConsumed = {}

	local data = shared.getPersistentData()
  --loading an earlier save, persistent timers are invalid
  if (data.shan.consume.lastAdministered == nil) or (data.shan.consume.lastAdministered > tes3.getSimulationTimestamp()) then
      data.shan.consume.lastConsumed = nil
  else
    if data.shan.consume.lastConsumed then
      for k, v in pairs(data.shan.consume.lastConsumed) do
          lastConsumed[k] = v
      end
    end
  end
end

-- Callback for when this module is set as the active one.
function this.onSetActive()
	-- Delete any save data.
	local data = shared.getPersistentData()
	if (data) then
		data.shan.consume.lastConsumed = nil
	end

	-- Also unset any data in our module.
	lastConsumed = {}

	-- Setup the events we care about.
  event.register("itemTileUpdated", this.onItemTileUpdated, { filter = "MenuContents" })
	event.register("save", this.onSave)
	event.register("loaded", this.onLoaded)
end

-- Callback for when this module is turned off.
function this.onSetInactive()
	-- Delete any save data.
	local data = shared.getPersistentData()
	if (data) then
		data.shan.consume.lastConsumed = nil
	end
	
	-- Also unset any data in our module.
	lastConsumed = {}

	-- Remove the events we cared about.
  event.unregister("itemTileUpdated", this.onItemTileUpdated, { filter = "MenuContents" })
	event.unregister("save", this.onSave)
	event.unregister("loaded", this.onLoaded)
end

return this