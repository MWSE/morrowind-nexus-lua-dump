--[[
	NOD Fashionwind RaGruzgob Addon

	Support module for Lucevar's NPC Outfit Diversity mod Fashionwind RaGruzgob addon, 
	distributing Onion-compatible clothing to NPCs for better compatibility.

	Thanks to MD and NullCascade. This code is based on their work from Mage Robes.
]]--

if (mwse.buildDate < 20220701) then
	event.register("initialized", function()
		tes3.messageBox("NPC Outfit Diversity RaGruzgob Addon requires a newer version of MWSE. Please run MWSE-Update.exe.")
	end)
	return
end

-- A dictionary of item IDs to objects. Will be filled in post-initialization. Any new items need to be defined here for quick lookup.
local fashion = {
	["_rv_ears_1"] = false,
	["_rv_ears_2"] = false,
}

-- NPCs to give items
local npcDistributionList = {
	["ra'gruzgob"] = "_rv_ears_1"
}

local function getFashionForNPC(npc)
	local newFashionId = nil

	-- Get the NPC's items
	if (npcDistributionList[npc.id:lower()]) then
		-- if NPC is in the table, qualify = true, and item to be added
		mwse.log("Giving item %s to %s", npcDistributionList[npc.id], npc.id)
		newFashionId = npcDistributionList[npc.id]
		return true, newFashionId
	else
		return false
	end
end

local function onInitialized()
	-- Go through and resolve our items.
	for k, _ in pairs(fashion) do
		fashion[k] = tes3.getObject(k)
	end

	-- Hit all the NPCs and give them their new items.
	for npc in tes3.iterateObjects(tes3.objectType.npc) do
		local qualifies, newFashion = getFashionForNPC(npc)
		if (qualifies) then
			npc.inventory:addItem({ item = newFashion })
		end
	end
end
event.register("initialized", onInitialized)
