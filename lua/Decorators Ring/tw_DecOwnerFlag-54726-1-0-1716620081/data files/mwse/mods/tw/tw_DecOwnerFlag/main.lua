mwse.log("[tw_DecOwnerFlag] Loaded successfully.")

-- A Decorators aid. 
-- On loading this mod you will be gifted with a ring that when equipped, it will auto unequip, will remove the owned flag from everything in your current cell.
-- This should resolve the issue with "Perfect Placement" where it's not possible to manipulate items that have the "owned" tag.
-- i.e. You clear a location and decide you want to squat there, but can't easily redecorate, because things are "owned.

local types = {
    --tes3.objectType.static,
    --tes3.objectType.activator,
    tes3.objectType.container,
    tes3.objectType.miscItem,
    tes3.objectType.weapon,   
    tes3.objectType.clothing,
    tes3.objectType.armor, 
    tes3.objectType.ammunition,
    tes3.objectType.alchemy,
    tes3.objectType.ingredient,
    tes3.objectType.apparatus,
    tes3.objectType.repairItem,
    tes3.objectType.book,
	tes3.objectType.light,
}

local function tw_DecOwnerFlag(e)
-- are they wearing the right ring ?
local item = e.item.id
if item == "tw_DecoratorsRing" then
	local cell = tes3.getPlayerCell()
	if cell.isInterior and not cell.behavesAsExterior then
		-- remove owner flag from everything in the cell
		for ref in cell:iterateReferences(types) do
			tes3.setOwner({ reference = ref, remove = true, owner = tes3.player })
		end
		
	else		
		-- This is not a interior cell so do nothing
		tes3.messageBox "This ring only works when in a interior cell."
	end
	timer.frame.delayOneFrame(function() tes3.mobilePlayer:unequip({item = "tw_DecoratorsRing"}) end)
end

end
 
-- Register the function to be called whenever the player equips a new item
event.register(tes3.event.equipped, tw_DecOwnerFlag)
 
-------------------------------------------------------------------------
local function setDoOnce(ref,Var)
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.Owner_flag = refData.Owner_flag or {} -- Force initializing the parent table.
    refData.Owner_flag.doOnce = Var -- Actually set your value.
end
local function getDoOnce(ref)
    local refData = ref.data
    return refData.Owner_flag and refData.Owner_flag.doOnce
end
local function tw_giveDecRing(e)
--if e.item.id:lower() == "tw_decoratorsring" then
--Only give them the teleportation key once.
  if getDoOnce(e.reference) ~= true then
    setDoOnce(e.reference, true)
    mwscript.addItem({ reference = tes3.player, item = "tw_DecoratorsRing", count = 1 })
    tes3.messageBox("You have been gifted the Decorators Aid ring" )
  end
--end
end

--Register the "loaded" event
event.register("loaded", tw_giveDecRing)
