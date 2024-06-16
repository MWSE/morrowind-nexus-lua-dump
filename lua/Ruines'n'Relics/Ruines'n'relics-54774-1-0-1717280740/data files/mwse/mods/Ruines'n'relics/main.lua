----------------------------------------------------------------
-- LUA CODE
--
--    Author: The Wanderer and dietBob196045.
--    Ruins'n'Relics a 2024 Modathon mod
--
----------------------------------------------------------------
mwse.log("[Ruins'n'Relics] Loaded successfully.")

-------------------------------------------------------------------------
local journalid = "rnr_old_journal"
local function setDoOnce(ref,Var)
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.journalid = refData.journalid or {} -- Force initializing the parent table.
    refData.journalid.doOnce = Var -- Actually set your value.
end
local function getDoOnce(ref)
    local refData = ref.data
    return refData.journalid and refData.journalid.doOnce
end
local function onLoadJournal(e)
--Only give them the journal once.
  if getDoOnce(e.reference) ~= true then
    setDoOnce(e.reference, true)
    mwscript.addItem({ reference = tes3.player, item = journalid, count = 1 })
    tes3.messageBox("You have been given an old adventurers journal." )
  end
  
end

local function rnr_forceequip(e)
	
	local weapon = tes3.getObject("rnr_dagger_Dae_cursed")	
	e.mobile:equip({item = weapon, addItem = true})
	tes3.messageBox( "You can not let go of the cursed dagger here!" )
		
end

-- Function to handle the event of unequipping an item
local function rnr_onUnequip(e)
    -- Check if the unequipped item is the one to be restricted
    if e.item.id == "rnr_dagger_Dae_cursed" then
        -- Get the player's current cell
        local playerCell = tes3.getPlayerCell()

        -- Check if the player is in the specified cell where unequipping is allowed
        if playerCell and playerCell.id == "rnr_Tomb_dae" then
			local player = tes3.mobilePlayer
            -- Allow unequipping the item in the specified cell
            e.claim = false
			
            return
        else
            -- Prevent unequipping the item in other cells	
			local weapon = tes3.getObject("rnr_dagger_Dae_cursed")
			
			if e.reference ~= tes3.player then
				return
			elseif e.item.id:lower() ~= "rnr_dagger_dae_cursed" then
				return
			end
			
			timer.frame.delayOneFrame(function()
					rnr_forceequip(e) 
				end)
			
        end
    end
end

-- Function to move the dropped item to a specific location if in allowed cell
local function rnr_DroppedItem(e)
	local droppedItem = e.reference.baseObject
    
	if droppedItem and droppedItem.id:lower() == "rnr_dagger_dae_cursed" then
		local destinationCell = tes3.getCell{ id = "rnr_Tomb_dae" }	
		if destinationCell and destinationCell.id == "rnr_Tomb_dae" then

			-- remove dropped "rnr_dagger_Dae_cursed" from play
			tes3.setEnabled({ reference = e.reference, enabled = false })  --- disable misc item

			-- item = "rnr_sacred_relic_blade"
			-- place blade back on the alter...
			local item = tes3.getObject("rnr_sacred_relic_blade")		
			tes3.createReference({
				object = "rnr_sacred_relic_blade",
				position = { -6, -1008, 85 },
				orientation = {726,0,0},
				cell = destinationCell
			})
		
		else       	
			-- shouldn't get here they can't unequip dagger.
			e.claim = true
			timer.frame.delayOneFrame(function()
					rnr_forceequip(e) 
					--e.mobile:equip({item=weapon, addItem=true})
				end)			

		end	
	end 
end

--[[
-- maybe.... not tested it...
local Cooldown  -- store the last cast time for spell
local cooldownTime = 300  -- Set cooldown time in seconds 300 = 5 mins
-- Function to modify the duration of a Levitate spell
local function rnr_modLevitateDuration(e)
    -- Check if the spell being cast is our Levitate spell
    if e.sourceInstance.source.id == "sc_rnr_bird_en" then
		-- restrict over use... maybe!!!
		local currentTime = tes3.getSimulationTimestamp()
		if Cooldown then
			local timeSinceLastCast = currentTime - Cooldown
			if timeSinceLastCast < cooldownTime then
				tes3.messageBox("You must wait %.1f more seconds before casting %s again.", cooldownTime - timeSinceLastCast, e.source.name)
				return false  -- Prevent the spell from being cast
			end
		end
	    -- Update/reset the last cast time for the spell
		Cooldown = currentTime
	
        -- Generate a random duration between 30 and 120 seconds (adjust as needed)
        local randomDuration = math.random(3, 12) * 10
		--mwse.log("### Random time  %d", randomDuration)
        -- Modify the duration of the spell
        e.sourceInstance.duration = randomDuration
		tes3.messageBox("You have %d seconds this time around.", randomDuration)
    end
end

-- Register the event handler for spell casting
event.register("spellCast", rnr_modLevitateDuration)
--]]
--Register the "loaded" event
event.register("loaded", onLoadJournal)
-- Register the event handler
event.register("unequipped", rnr_onUnequip)
-- Register the event handler for dropped items
event.register("itemDropped", rnr_DroppedItem)
