local this = {}

local shared = require("partyAlchemy.shared")

-- Name to identify this module.
this.name = "Oblivion Style"
this.consumeVersion = 1.2

-- How many potions we can sustain before potion drinking is blocked.
local potionLimit = 4

-- A list of current active potions.
local lastLimitConsumed = {}
--tab[npc_ref] = [endTime1, endTime2, endTime3, endTime4]



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
            
            if lastLimitConsumed[companion.reference.id] == nil then
                lastLimitConsumed[companion.reference.id] = {0.0, 0.0, 0.0, 0.0}
            end
            local potions = lastLimitConsumed[companion.reference.id]
            
            local activePotionCount = 0
            local shortestPotion = 0
            for i = 1, potionLimit do
                if potions[i] > tes3.getSimulationTimestamp() then
                    if shortestPotion == 0 then
                        shortestPotion = potions[i]
                    end
                    activePotionCount = activePotionCount + 1
                    if potions[i] < shortestPotion then
                        shortestPotion = potions[i]
                    end
                end
            end
            if activePotionCount >= potionLimit then
              local timeLeft = (shortestPotion - tes3.getSimulationTimestamp())
              tes3.messageBox("%s may not have more than %d potions active at once.  You must wait another %d seconds.", companion.reference.object.name, potionLimit, (timeLeft * (3600 / tes3.getGlobal("timescale"))))
              return
            end
            
            if companion then
                local data = shared.getPersistentData()
                data.shan.consume.lastAdministered = tes3.getSimulationTimestamp()
                
                shared.administerPotionInteractive(companion.reference, c.item, c.itemData)
                -- Start our cooldown based on the longest effect duration. Use game time so that resting affects it.
                local duration = shared.getLongestPotionDuration(c.item) * (1/3600) * tes3.getGlobal("timescale")
                local endTime = tes3.getSimulationTimestamp() + duration
                local id_lowest = 1
                for i = 1, potionLimit do
                    if potions[i] < potions[id_lowest] then
                        id_lowest = i
                    end
                end
                if endTime > potions[id_lowest] then
                    lastLimitConsumed[companion.reference.id][id_lowest] = endTime
                end
            end
        end
    end)
end

-- Set any remaining time so that it persists through saves.
function this.onSave(e)
	local data = shared.getPersistentData()
  
  if data.shan.consume.lastLimitConsumed == nil then
      data.shan.consume.lastLimitConsumed = {}
  end
	
	-- Get any unexpired potions and store them in an array.
  for k, v in pairs(lastLimitConsumed) do
    local hasPotionActive = false
    
    for i = 1, potionLimit do
        if v[i] > tes3.getSimulationTimestamp() then
          hasPotionActive = true
        end
    end
    
    if hasPotionActive then
        data.shan.consume.lastLimitConsumed[k] = v --[]
    else
        data.shan.consume.lastLimitConsumed[k] = nil
    end
  end
end

-- Loaded event. Resume any consumption restrictions.
function this.onLoaded(e)
	local data = shared.getPersistentData()

	-- Ensure our potion expiry list is empty.
	lastLimitConsumed = {}

  --loading an earlier save, persistent timers are invalid
  if (data.shan.consume.lastAdministered == nil) or (data.shan.consume.lastAdministered > tes3.getSimulationTimestamp()) then
      data.shan.consume.lastLimitConsumed = nil
  else
    local characterPotions = data.shan.consume.lastLimitConsumed
    if characterPotions then
      -- They drank recently. Copy the remaining time.
      for k, v in pairs(characterPotions) do
        lastLimitConsumed[k] = v
      end
    end
  end
end

-- Callback for when this module is set as the active one.
function this.onSetActive()
	-- Delete any save data.
	local data = shared.getPersistentData()
	if (data) then
		data.shan.consume.lastLimitConsumed = nil
	end

	-- Also unset any data in our module.
	lastLimitConsumed = {}

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
		data.shan.consume.lastLimitConsumed = nil
	end

	-- Also unset any data in our module.
	lastLimitConsumed = {}
	
	-- Remove the events we cared about.
  event.unregister("itemTileUpdated", this.onItemTileUpdated, { filter = "MenuContents" })
	event.unregister("save", this.onSave)
	event.unregister("loaded", this.onLoaded)
end

return this