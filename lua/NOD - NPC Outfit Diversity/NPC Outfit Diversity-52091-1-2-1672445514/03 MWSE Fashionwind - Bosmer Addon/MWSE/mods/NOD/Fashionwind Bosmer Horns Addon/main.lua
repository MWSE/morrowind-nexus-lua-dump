--[[
	NOD Fashionwind Bosmer Horns Addon

	Support module for Lucevar's NPC Outfit Diversity mod Fashionwind Bosmer horns and antlers addon, 
	distributing Onion-compatible clothing to NPCs for better compatibility.

	Thanks to MD and NullCascade. This code is based on their work from Mage Robes.
]]--

if (mwse.buildDate < 20220701) then
	event.register("initialized", function()
		tes3.messageBox("NPC Outfit Diversity Bosmer Addon requires a newer version of MWSE. Please run MWSE-Update.exe.")
	end)
	return
end

-- A dictionary of item IDs to objects. Will be filled in post-initialization. Any new items need to be defined here for quick lookup.
local fashion = {
	["_rv_antlers_1"] = false,
	["_rv_antlers_2"] = false,
	["_rv_horns_1"] = false,
	["_rv_horns_2"] = false,
	["_rv_horns_3"] = false,
	["_rv_ears_1"] = false,
	["_rv_ears_2"] = false,
}

-- NPCs to not give items (player defined).
local npcBlacklist = {}

-- NPCs to give items
local npcDistributionList = {
	["aengoth"] = "_rv_antlers_1",
	["allimir"] = "_rv_antlers_2",
	["anruin"] = "_rv_horns_2",
	["arathor"] = "_rv_horns_2",
	["elegnan"] = "_rv_antlers_1",
	["eradan"] = "_rv_antlers_1",
	["fargoth"] = "_rv_horns_2",
	["galbedir"] = "_rv_antlers_1",
	["natesse"] = "_rv_antlers_1",
	["nedhelas"] = "_rv_horns_2",
	["new_shoes bragor"] = "_rv_horns_2",
	["thaeril"] = "_rv_horns_3",

}

local function getFashionForNPC(npc)
	-- Check blacklist.
	if (npcBlacklist[npc.id:lower()]) then
		mwse.log("Skipping item assignment for %s. Blacklisted", npc.id)
		return false
	end

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
	-- Load the config file.
	local config = mwse.loadConfig("NOD Fashionwind Bosmer Horns Addon")
	if (config == nil) then
		config = {
			npcBlacklist = {
				"todd",
			},
		}
	end
	config.npcBlacklist = config.npcBlacklist or {}

	-- Build our blacklists.
	for _, v in pairs(config.npcBlacklist) do
		npcBlacklist[v:lower()] = true
	end
	mwse.log("Blacklists:\nNPCs: %s", json.encode(npcBlacklist))

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
