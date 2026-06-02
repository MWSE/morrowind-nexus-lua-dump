local cupContainers = {
	["teamod_teacup_q2"] = "q2",
	["teamod_teacup_q6"] = "q6",
	["teamod_teacup_q7"] = "q7",
	["teamod_teacup_qg"] = "qg",
	["teamod_teacup_st01"] = "st01",
	["teamod_teacup_st02"] = "st02",
	["teamod_teacup_st03"] = "st03",
	["teamod_teacup_st04"] = "st04",
	["teamod_teacup_st05"] = "st05",
	["teamod_teacup_st06"] = "st06",
	["teamod_teacup_st07"] = "st07",
	["teamod_teacup_st08"] = "st08",
	["teamod_teacup_st09"] = "st09",
	["teamod_teacup_st10"] = "st10",
	["teamod_teacup_st11"] = "st11",
	["teamod_teacup_st12"] = "st12",
	["teamod_teacup_cali_red"] = "calred",
	["teamod_teacup_cali_silv"] = "calsilv",
	["teamod_teacup_kb02"] = "kb02",
}

if world then
	local core = require('openmw.core')
	local I = require('openmw.interfaces')
	registerGlobalEvent("tea_brewComplete", 1.0, function(data)
		-- downgrade water in kettle onlyy once
		local snaps = data.stationSnapshots or {}
		local last = snaps[#snaps]
		local kettle = last and last[3]
		if kettle and kettle:isValid() then
			-- nil player param skips consumedWater
			core.sendGlobalEvent("SunsDusk_downgradeWorldConsumable", { nil, kettle, data.count })
		end
		
		local kind = data.craftData and data.craftData.teaKind
		local suffix = data.craftData and data.craftData.teaSuffix
		local cupBuckets, nonCup = {}, {}
		local hasCups = false
		for item, cnt in pairs(data.consumedIngredients or {}) do
			local container = cupContainers[item.recordId]
			if container and kind and suffix then
				local resultId = "tm_" .. kind .. "_" .. container .. "_" .. suffix
				local bucket = cupBuckets[resultId]
				if not bucket then
					bucket = { count = 0, items = {} }
					cupBuckets[resultId] = bucket
				end
				bucket.count = bucket.count + cnt
				bucket.items[item] = cnt
				hasCups = true
			else
				nonCup[item] = cnt
			end
		end
		
		-- fallback
		if not hasCups then
			I.CraftingFramework.craftItem(data)
			return
		end
		
		for item, cnt in pairs(nonCup) do
			core.sendGlobalEvent("CraftingFramework_removeItem", { data.player, item, cnt })
		end
		
		for resultId, bucket in pairs(cupBuckets) do
			local sub = {}
			for k, v in pairs(data) do sub[k] = v end
			sub.recordId = resultId
			sub.count = bucket.count
			sub.consumedIngredients = bucket.items
			I.CraftingFramework.craftItem(sub)
		end
	end)
	return
end

if not registerWildcard then
	error("Please update Crafting Framework")
end

-- ml of water
local function readPotionWaterMl(item)
	local name = types.Potion.record(item).name or ""
	if name:lower():sub(-8) ~= "l water)" then return 0 end
	local cur = name:match("%(([^/]+)/")
	if not cur then return 0 end
	local liters = cur:match("([%d%.]+)L")
	if liters then return tonumber(liters) * 1000 end
	local ml = cur:match("(%d+)%s*ml")
	return ml and tonumber(ml) or 0
end

registerProfession{
	name = "Brew Tea",
	skillId = "alchemy",
	version = 1,
	solo = true,
}

registerProfession{
	name = "Brew Coffee",
	skillId = "alchemy",
	version = 1,
}

registerWildcard{
	id = "Tea Cup",
	name = "Tea Cup",
	version = 1,
	func = function()
		local ret = {}
		for _, item in pairs(types.Player.inventory(self):getAll(types.Miscellaneous)) do
			if cupContainers[item.recordId] then
				table.insert(ret, item)
			end
		end
		return ret
	end,
}

local teapotMeshes = {
	["meshes/sky/m/sky_misc_copkettle_01.nif"] = true, -- t_com_copperkettle_01
	["meshes/oaab/m/kettle_redware_01.nif"] = true, -- ab_misc_comredwareteapot
	["meshes/sky/m/sky_misc_copkettle_02.nif"] = true, -- t_com_coppetteapot_01
	["meshes/oaab/m/kettle_akaviri.nif"] = true, -- ab_misc_kettleceremonial
	["meshes/oaab/m/kettle_bug_01.nif"] = true, -- ab_misc_debugteapot
	["meshes/oaab/m/ceramicteapot_01.nif"] = true, -- ab_misc_ceramicteapot01
	["meshes/oaab/m/ceramicteapot_02.nif"] = true, -- ab_misc_ceramicteapot01hang
	["meshes/oaab/m/copperkettle01.nif"] = true, -- ab_misc_comcopperkettle01
	["meshes/sunsdusk/teapot_red.nif"] = true, -- sd_teapot_red
	["meshes/tr/m/tr_ind_velk_kettle01.nif"] = true, -- t_de_punavitkettle_01
	["meshes/sum/m/sum_misc_celb_teapot.nif"] = true, -- t_he_blueceladonteapot_01
	["meshes/sum/m/sum_misc_celg_teapot.nif"] = true, -- t_he_greenceladonteapot_01
	["meshes/pi/m/pi_m_yne_c_teapot.nif"] = true, -- t_yne_clayteapot
	["meshes/pi/m/pi_m_yne_s_teapot.nif"] = true, -- t_yne_stoneteapot
	["meshes/pi/m/pi_m_yne_w_teapot.nif"] = true, -- t_yne_woodenteapot_01
	["meshes/hr/m/hr_misc_pew_teapot_01.nif"] = true, -- t_bre_pewterteapot_01
	["meshes/hr/m/hr_misc_stnwr_tpot_01.nif"] = true, -- t_bre_stonewareteapot_01
	["meshes/barabus/bar_brasskettle.nif"] = true, -- TM_kettle_bar_01
	["meshes/barabus/bar_cu_kettle.nif"] = true, -- TM_kettle_bar_02
	["meshes/teamod/st_kettle_castiron.nif"] = true, -- teamod_kettle_st01
	["meshes/teamod/st_kettle_steel.nif"] = true, -- teamod_kettle_st02
	["meshes/q/qteapot2.nif"] = true, -- teamod_teapot_Q2
	["meshes/q/qteapot6.nif"] = true, -- teamod_teapot_Q6
	["meshes/q/qteapot7.nif"] = true, -- teamod_teapot_Q7
	["meshes/q/qteapot_glass.nif"] = true, -- teamod_teapot_QG
	["meshes/q/qteapot_glass_lrg.nif"] = true, -- teamod_teapot_QGL
	["meshes/teamod/st_teapot_01.nif"] = true, -- teamod_teapot_ST01
	["meshes/teamod/st_teapot_02.nif"] = true, -- teamod_teapot_ST02
	["meshes/teamod/st_teapot_03.nif"] = true, -- teamod_teapot_ST03
	["meshes/teamod/st_teapot_04.nif"] = true, -- teamod_teapot_ST04
	["meshes/teamod/st_teapot_05.nif"] = true, -- teamod_teapot_ST05
	["meshes/teamod/st_teapot_06.nif"] = true, -- teamod_teapot_ST06
	["meshes/teamod/st_teapot_07.nif"] = true, -- teamod_teapot_ST07
	["meshes/teamod/st_teapot_08.nif"] = true, -- teamod_teapot_ST08
	["meshes/teamod/st_teapot_09.nif"] = true, -- teamod_teapot_ST09
	["meshes/teamod/st_teapot_10.nif"] = true, -- teamod_teapot_ST10
	["meshes/teamod/st_teapot_11.nif"] = true, -- teamod_teapot_ST11
	["meshes/teamod/st_teapot_12.nif"] = true, -- teamod_teapot_ST12
}

local coffeePotMeshes = {
	["meshes/teamod/st_coffeepot_01.nif"] = true, -- teamod_coffeepot_ST01
	["meshes/teamod/st_coffeepot_02.nif"] = true, -- teamod_coffeepot_ST02
	["meshes/teamod/st_coffeepot_03.nif"] = true, -- teamod_coffeepot_ST03
	["meshes/teamod/st_coffeepot_04.nif"] = true, -- teamod_coffeepot_ST04
	["meshes/teamod/st_coffeepot_05.nif"] = true, -- teamod_coffeepot_ST05
	["meshes/teamod/st_coffeepot_06.nif"] = true, -- teamod_coffeepot_ST06
	["meshes/q/qcoffeepot2.nif"] = true, -- teamod_coffeepot_Q2
	["meshes/q/qcoffeepot6.nif"] = true, -- teamod_coffeepot_Q6
	["meshes/q/qcoffeepot7.nif"] = true, -- teamod_coffeepot_Q7
	["meshes/q/qcoffeepot_glass.nif"] = true, -- teamod_coffeepot_QG
}

local function closestVessel(meshes)
	local playerPos = self.position
	local found, best = nil, math.huge
	for _, item in pairs(nearby.items) do
		if types.Potion.objectIsInstance(item) and meshes[types.Potion.record(item).model:lower()] then
			local d = (playerPos - item.position):length()
			if d < best then
				best = d
				found = item
			end
		end
	end
	return found
end

local function closestKettle()
	local k = closestVessel(teapotMeshes)
	if k then return k end
	return closestVessel(coffeePotMeshes)
end

-- max cups: min, empty cups owned, 250ml units in nearest correct crafting station
local function brewCap(kind)
	local cups = 0
	for _, item in pairs(types.Player.inventory(self):getAll(types.Miscellaneous)) do
		if cupContainers[item.recordId] then
			cups = cups + item.count
		end
	end
	local k = (kind == "cof") and closestVessel(coffeePotMeshes) or closestKettle()
	local units = k and math.floor(readPotionWaterMl(k) / 250) or 0
	return math.min(cups, units)
end

registerStation{
	id = "Teakettle",
	name = "Tea Kettle",
	version = 1,
	func = function()
		if cheatMode then return true end
		local k = closestKettle()
		if not k then return false end
		local ml = readPotionWaterMl(k)
		if ml < 250 then return false end
		return string.format("%i", ml), k.type.record(k).name, k
	end,
}

registerStation{
	id = "CoffeePot",
	name = "Coffee Pot",
	version = 1,
	func = function()
		if cheatMode then return true end
		local k = closestVessel(coffeePotMeshes)
		if not k then return false end
		local ml = readPotionWaterMl(k)
		if ml < 250 then return false end
		return string.format("%i", ml), k.type.record(k).name, k
	end,
}

registerIngredientsModifier{
	id = "tea_batchScale",
	func = function(recipe, ctx)
		local cap = brewCap(recipe.userData and recipe.userData.kind)
		if cap < 1 then return end
		local ingr = ingredientsMutable(ctx)
		for _, i in ipairs(ingr) do
			if i.wildcardId == "Tea Cup" then
				i.count = cap
			end
		end
	end,
}

-- result count
registerResultCountModifier{
	id = "tea_batchCount",
	func = function(recipe, ctx)
		local cap = brewCap(recipe.userData and recipe.userData.kind)
		if cap > 0 then ctx.modified = cap end
	end,
}

-- swaps the base potion for the chosen tea/cup pairing
-- also stashes kind/suffix in craftData so cups can be split
registerResultItemModifier{
	id = "tea_resolveCup",
	func = function(recipe, ctx)
		local cup
		for _, ingredient in ipairs(ctx.ingredients) do
			if ingredient.type == "wildcard" and ingredient.selectedId then
				cup = ingredient.selectedId
				break
			end
		end
		local container = cup and cupContainers[cup]
		if not container then return end
		local data = recipe.userData
		ctx.modified = "tm_" .. data.kind .. "_" .. container .. "_" .. data.suffix
		ctx.craftData.teaKind = data.kind
		ctx.craftData.teaSuffix = data.suffix
	end,
}

registerExpModifier{
	id = "tea_flatExp",
	func = function(recipe, ctx)
		for skillId, info in pairs(ctx.skills) do
			if info.diffMod and info.diffMod > 0 and info.diffMod ~= 1 then
				ctx.modified[skillId] = ctx.modified[skillId] / info.diffMod
			end
			info.diffMod = 1
		end
		if ctx.modified["sunsdusk_cooking"] then
			ctx.modified["sunsdusk_cooking"] = ctx.modified["sunsdusk_cooking"] / 12
		end
	end,
}

local recipes = require("scripts.ceremonialtea.recipes")
return recipes