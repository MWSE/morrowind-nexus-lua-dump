--[[
	NOD Fashionwind Addon

	Support module for Lucevar's NPC Outfit Diversity mod Fashionwind core addon, 
	distributing Onion-compatible clothing to NPCs for better compatibility.

	Thanks to MD and NullCascade. This code is based on their work from Mage Robes.
]]--

if (mwse.buildDate < 20220701) then
	event.register("initialized", function()
		tes3.messageBox("NPC Outfit Diversity Fashionwind Addon requires a newer version of MWSE. Please run MWSE-Update.exe.")
	end)
	return
end

-- A dictionary of item IDs to objects. Will be filled in post-initialization. Any new items need to be defined here for quick lookup.
local fashion = {
	["_rv_glasses1"] = false,
	["_rv_glasses2"] = false,
	["_rv_glasses3"] = false,
	["_rv_glasses4"] = false,
	["_rv_goggles1"] = false,
	["_rv_goggles2"] = false,
	["_rv_goggles3"] = false,
	["_rv_goggles4"] = false,
	["_rv_glasses4s"] = false,
	["_rv_glasses2s"] = false,
	["_rv_glasses1s"] = false,
	["_rv_goggles5"] = false,
	["_rv_goggles6"] = false,
	["_rv_goggles7"] = false,
	["_rv_goggles8"] = false,
	["_rv_lenses1"] = false,
	["_rv_blindfold1"] = false,
	["_rv_eyepatch1l"] = false,
	["_rv_lenses2"] = false,
	["_rv_eyepatch1r"] = false,
	["_rv_facewrap_1"] = false,
	["_rv_facewrap_2"] = false,
	["_rv_facewrap_3"] = false,
	["_rv_facewrap_4"] = false,
	["_rv_facewrap_5"] = false,
	["_rv_facewrap_6"] = false,
	["_rv_facewrap_7"] = false,
	["_rv_facewrap_8"] = false,
	["_rv_ashmask_1"] = false,
	["_rv_ashmask_2"] = false,
	["_rv_ashmask_3"] = false,
	["_rv_daedramask_1"] = false,
	["_rv_daedramask_2"] = false,
	["_rv_daedramask_3"] = false,
	["_rv_orcishmask_1"] = false,
	["_rv_daedramask_4"] = false,
	["_rv_orcishmask_2"] = false,
}

-- NPCs to not give items (player defined).
local npcBlacklist = {}

-- NPCs to give items
local npcDistributionList = {
	["aengoth"] = "_rv_lenses2",
	["anarenen"] = "_rv_lenses1",
	["andil"] = "_rv_lenses1",
	["aurane frernis"] = "_rv_lenses1",
	["chargen class"] = "_rv_glasses1",
	["daras aryon"] = "_rv_goggles6",
	["detritus caria"] = "_rv_glasses4s",
	["edwinna elbert"] = "_rv_goggles4",
	["louis beauchamp"] = "_rv_glasses2s",
	["senilias cadiusus"] = "_rv_glasses2",
	["telinturco"] = "_rv_facewrap_5",
	["ulms drathen"] = "_rv_eyepatch1r",
	["undil"] = "_rv_facewrap_5",
	["velsa salaron"] = "_rv_goggles5",
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
	local config = mwse.loadConfig("NOD Fashionwind Addon")
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
