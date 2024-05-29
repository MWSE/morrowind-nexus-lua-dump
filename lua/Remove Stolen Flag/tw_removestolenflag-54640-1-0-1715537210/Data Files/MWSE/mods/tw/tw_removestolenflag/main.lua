mwse.log("[tw_removestolenflag] Loaded successfully.")

-- -- Function to remove the stolen flag from stolen items in the player's inventory
 local function tw_removeStolenFlag(e)

	if e.item.id == "tw_removestolenflag" then 		
-- mwse.log("**** unequip  %s", e.item.id)		
		local inventory = tes3.player.object.inventory
		-- Iterate through the player's inventory
		for _, itemStack in pairs(inventory) do
			local item = itemStack.object	
-- mwse.log("**** item  %s", item.name)
			local stolenFlag		
			for _, stolenItemID in ipairs(item.stolenList) do	
			-- Check if the item has the stolen flag
				if stolenItemID then				
-- mwse.log("****1 stolen  %s", stolenItemID)
				-- tes3.setItemIsStolen({ item = item, stolen = false })
				stolenFlag = true
				else
				stolenFlag = false
				end 
			end
			if stolenFlag then
				-- Remove the stolen flag
				tes3.setItemIsStolen({ item = item, stolen = false })            
mwse.log("The stolen flag has been removed from %s ", item.name)			 
			end
		end
		tes3.messageBox("The stolen flag has been removed from all your inventory items.")
		timer.frame.delayOneFrame(function() tes3.mobilePlayer:unequip({item = "tw_removestolenflag"}) end)
	end 
 end
 
 -- Register the function to be called whenever the player equips a new item
 event.register(tes3.event.equipped, tw_removeStolenFlag)
 
-------------------------------------------------------------------------

local function setDoOnce(ref,Var)
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.Stolen_flag = refData.Stolen_flag or {} -- Force initializing the parent table.
    refData.Stolen_flag.doOnce = Var -- Actually set your value.
end
local function getDoOnce(ref)
    local refData = ref.data
    return refData.Stolen_flag and refData.Stolen_flag.doOnce
end
local function tw_givering(e)

--Only give them the teleportation key once.
  if getDoOnce(e.reference) ~= true then
    setDoOnce(e.reference, true)
    mwscript.addItem({ reference = tes3.player, item = "tw_removestolenflag", count = 1 })
    tes3.messageBox("You have been gifted the Remove Stolen Flag ring" )
  end
  
end
--Register the "loaded" event
event.register("loaded", tw_givering)