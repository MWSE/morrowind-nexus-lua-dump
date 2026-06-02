craftingSounds.forging = {
	version = 1,
	{
		sound = "sound/CraftingFramework/fire_swoosh.ogg",
		duration = 1.346,
		at = 0.0,
		to = 0.85,
		volume = 0.7,
		fade_in = nil,
		fade_out = nil
	},
	{ 
		sound = "sound/CraftingFramework/random_metal1.ogg",	
		duration = 26,
		from = 0.03,
		to = 0.9,
		volume = 0.5,
		fade_in = 0.33,
		fade_out = 0.33,
		randomOffset = {0,20},
	},
	{
		sounds = {
			{sound = "sound/CraftingFramework/anvil_hit1.ogg", duration = 0.2},
			{sound = "sound/CraftingFramework/anvil_hit2.ogg", duration = 0.2},
			{sound = "sound/CraftingFramework/anvil_hit3.ogg", duration = 0.2},
			{sound = "sound/CraftingFramework/anvil_hit4.ogg", duration = 0.2},
		},
		from = 0.05, to = 0.9, interval = { min = 0.55, max = 0.65 }, volume = 0.95 
	},
	{ sound = "sound/CraftingFramework/sizzling.ogg", at = 0.9, volume = 1.2 },
}

craftingSounds.alchemy = {
	{ sound = "potion fail",		at = 0.0, duration = 1.8, volume = 0.5, fade_in = 0.4, fade_out = 0.5 },
	{ sound = "potion success",
		loop = true,
		from = 0.04,
		to = 0.99,
		interval = { min = 0.4, max = 0.5 },
		pitch_fade_in = { duration = 2.3, from = 0.1 },
		pitch_fade_out = { duration = 0.7, to = 0.99 },
		fade_in = 0.5,
		fade_out = 0.5,
		duration = 1.35,
		volume = 0.6,
		randomOffset = {0,0.6},
		pitch = { min = 0.49, max = 0.5 },
		--minTimeToEnd = 0.2,
		--skipIfIncomplete = true 
	},
	{ sound = "potion fail", at = 0.99, duration = 1.8, volume = 0.5, fade_in = 0.4, fade_out = 0.5 },
}


-- ------------------------------ leather wildcard ------------------------------

registerWildcard{
	id = "Any leather",
	name = "Any leather",
	version = 1,
	--icon = "path.dds",
	func = function(snap)
		local ret = {}
		-- recordId predicate shared by both code paths
		local function isLeatherLike(recordId)
			return recordId:find("hide")
				or recordId:find("pelt")
				or recordId:find("leather")
				or recordId:find("_skin_01")
		end
		if snap then
			-- only ingredient and misc qualify; scan those two buckets
			for _, bucket in ipairs({ snap.byType.Ingredient, snap.byType.Miscellaneous }) do
				for _, item in ipairs(bucket or {}) do
					if isLeatherLike(item.recordId) then
						table.insert(ret, item)
					end
				end
			end
		else
			for _, inv in ipairs(inventorySources()) do
				for _, item in pairs(inv:getAll()) do
					if isLeatherLike(item.recordId)
						and (types.Ingredient.objectIsInstance(item) or types.Miscellaneous.objectIsInstance(item))
					then
						table.insert(ret, item)
					end
				end
			end
		end
		table.sort(ret, function(a,b) return a.count > b.count end)
		return ret
	end,
}

-- ------------------------------ soul wildcards ------------------------------

local function soulFilter(prevTierGem, tierGem)
	return function(snap)
		local mult = core.getGMST("fSoulGemMult")
		local prevRec = prevTierGem and types.Miscellaneous.records[prevTierGem]
		local tierRec = tierGem and types.Miscellaneous.records[tierGem]
		local minCap = prevRec and prevRec.value * mult or 0
		local maxCap = tierRec and tierRec.value * mult or math.huge
		local ret = {}
		-- per-item soul-value gate, shared
		local function consider(item)
			if item.recordId:sub(1,12) == "misc_soulgem" then
				local soul = types.Item.itemData(item).soul
				if soul and types.Creature.records[soul] then
					local soulValue = types.Creature.records[soul].soulValue or 0
					if soulValue > minCap and soulValue <= maxCap then
						table.insert(ret, item)
					end
				end
			end
		end
		if snap then
			for _, item in ipairs(snap.byType.Miscellaneous or {}) do
				consider(item)
			end
		else
			for _, inv in ipairs(inventorySources()) do
				for _, item in pairs(inv:getAll(types.Miscellaneous)) do
					consider(item)
				end
			end
		end
		table.sort(ret, function(a,b) return a.count > b.count end)
		return ret
	end
end

registerWildcard{
	id = "Any petty soul",
	name = "Any petty soul",
	version = 1,
	--icon = "path.dds",
	func = soulFilter(nil, "misc_soulgem_petty"),
}
registerWildcard{
	id = "Any lesser soul",
	name = "Any lesser soul",
	version = 1,
	--icon = "path.dds",
	func = soulFilter("misc_soulgem_petty", "misc_soulgem_lesser"),
}
registerWildcard{
	id = "Any common soul",
	name = "Any common soul",
	version = 1,
	--icon = "path.dds",
	func = soulFilter("misc_soulgem_lesser", "misc_soulgem_common"),
}
registerWildcard{
	id = "Any greater soul",
	name = "Any greater soul",
	version = 1,
	--icon = "path.dds",
	func = soulFilter("misc_soulgem_common", "misc_soulgem_greater"),
}
registerWildcard{
	id = "Any grand soul",
	name = "Any grand soul",
	version = 1,
	--icon = "path.dds",
	func = soulFilter("misc_soulgem_greater", "misc_soulgem_grand"),
}


--wildcardFunctions["Any Daedra soul"] = function()
--	local ret = {}
--	for _, item in pairs(types.Player.inventory(self):getAll(types.Miscellaneous)) do
--		if item.recordId:sub(1,12) == "misc_soulgem" then
--			local soul = types.Item.itemData(item).soul
--			if soul then
--				local creature = types.Creature.records[soul]
--				if creature.type == types.Creature.TYPE.Daedra then
--					table.insert(ret, item)
--				end
--			end
--		end
--	end
--	table.sort(ret, function(a,b) return a.count > b.count end)
--	return ret
--end