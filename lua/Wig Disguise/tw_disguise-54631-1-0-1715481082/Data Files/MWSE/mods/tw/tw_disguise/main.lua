
-- Wear any wig from my "Wigs and Things" shop in Caldera and guards will not recognise you so will not try and arrest you if you have a bounty while you are wearing it.
-- What is happening? well it's quite simple, putting on one of the wigs and your bounty becomes 0 take it off and you original bounty is restored. 
-- This also work the other way get a bounty why wearing a wig then take it off your bounty will become what your original bounty was.
-- This will also work with any mod that also uses the same wig setup.
-- This is a Lua coded mod there is no esp to directly install. It does require a compatible mod to be installed and active of course.

mwse.log("[tw_disguise] Loaded successfully.")

local tw_wigLists = {
    { id = "Fshan_ARG_hair" },
    { id = "Fshan_Bret_hair" },
    { id = "Fshan_DE_hair" },
    { id = "Fshan_HE_hair" },
    { id = "Fshan_IMP_hair" },
    { id = "Fshan_KHJ_hair" },
    { id = "Fshan_NORD_hair" },
    { id = "Fshan_ORC_hair" },
    { id = "Fshan_REDG_hair" },
    { id = "Fshan_WE_hair" },
}	

local PC_Bounty
local doOnce

-- Function to check if the player is wearing an item by checking a left subset of the name contained in a list
local function tw_isWearingWig()
    local player = tes3.mobilePlayer

    -- Iterate through the player's equipped items
    for _, stack in pairs(player.object.equipment) do
        -- Get the name of the equipped item
        local itemName = stack.object.id
		if string.sub(itemName, 1, 6 ) == "Fshan_" then  -- reduce the total checks
			-- Iterate through the subset list
			for _, subsetName in ipairs(tw_wigLists) do
				subsetName = subsetName.id
				-- Check if the left subset of the item's name matches any subset in the list
				local leftSubstring = string.sub(itemName, 1, string.len(subsetName))
				if leftSubstring == subsetName then
					return true -- Player is wearing a wig
				end
			end
		end		
    end
    return false -- Player is not wearing any item with a subset from the list
	
end
--- This is a generic iterator function used
--- to loop over a tes3referenceList
local function iterReferenceList(list)
    local function iterator()
        local ref = list.head

        if list.size ~= 0 then
            coroutine.yield(ref)
        end

        while ref.nextNode do
            ref = ref.nextNode
            coroutine.yield(ref)
        end
    end
    return coroutine.wrap(iterator)
end

local function tw_modifyGuardBehavior(e)

	if tw_isWearingWig() then	
		if doOnce == 0 then
			doOnce = 1
            PC_Bounty = tes3.mobilePlayer.bounty	
		end
		tes3.mobilePlayer.bounty = 0
	
	else
		tes3.mobilePlayer.bounty = PC_Bounty
		doOnce = 0
	end

end

local function tw_onEquip(e)
	tw_modifyGuardBehavior(e)
end

local function tw_onUnequip(e)
    tw_modifyGuardBehavior(e)
end

event.register(tes3.event.equipped, tw_onEquip)
event.register(tes3.event.unequipped, tw_onUnequip)
event.register(tes3.event.cellChanged, tw_modifyGuardBehavior)
