if world then return end -- player only 
 
local self = require('openmw.self')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local async = require('openmw.async')
local playerInventory = types.Actor.inventory(self)	

------------------------------ profession ------------------------------
 
-- solo: opening from pliershides every other profession from the dropdown until the window closes.
-- registerProfession{
--	name = "Jewelcrafting",
--	skillId = "jewelcrafting",
--	version = 1,
--	solo = true,
-- }
------------------------------ wildcards -------------------------------

 if not registerWildcard then
	error("Please update Crafting Framework")
end

-- tool
registerWildcard{
	id = "jc_pliers",
	name = "Jewelcrafting Pliers",
	version = 1,
	func = function()
		local ret = {}
		for _, item in pairs(types.Player.inventory(self):getAll(types.Miscellaneous)) do
			if item.recordId:find("jc_pliers") then
				table.insert(ret, item)
			end
		end
		return ret
	end,
}

-- gem wildcards for recipes
local gemWildCards = {
	["Any Diamond"] = { 
		["ingred_diamond_01"] = true, 
		["t_ingmine_diamondblue_01"] = true, 
		["t_ingmine_diamondred_01"] = true, 
		["ab_ingmine_bluediamond"] = true, 
		["ab_ingmine_reddiamond"] = true,
	},
	["Blue Diamond"] = {
		["t_ingmine_diamondblue_01"] = true,
		["ab_ingmine_bluediamond"] = true,
	},
	["Red Diamond"] = { 
		["t_ingmine_diamondred_01"] = true, 
		["ab_ingmine_reddiamond"] = true,
	},
	["Amethyst"] = { 
		["t_ingmine_amethyst_01"] = true, 
		["ab_ingmine_amethyst_01"] = true,
	},
	["Sapphire"] = { 
		["t_ingmine_sapphire_01"] = true, 
		["ab_ingmine_sapphire_01"] = true, 
	},
	["Garnet"] = { 
		["t_ingmine_garnet_01"] = true, 
		["ab_ingmine_garnet_01"] = true,
	},
	["Quartz"] = { 
		["t_ingmine_smokyquartz_01"] = true, 
		["t_ingmine_rosequartz_01"] = true,
	},
	["Topaz"] = {
		["t_ingmine_topaz_01"] = true,
		["ab_ingmine_topaz_01"] = true,
		["t_ingmine_topazblue_01"] = true,
	},
	["Jade"] = {
		["t_ingmine_jade_01"] = true,
		["ab_ingmine_firejade_01"] = true
	},
	["Agate"] = { 
		["t_ingmine_agate_01"] = true,
		["t_ingmine_agate_03"] = true,
		["t_ingmine_agate_02"] = true,
		["t_ingmine_agate_04"] = true,
	},
	["Opal"] = {
		["t_ingmine_opal_01"] = true,
		["t_ingmine_fireopal_01"] = true,
	},
	["Opal or Agate"] = {
		["t_ingmine_opal_01"] = true,
		["t_ingmine_fireopal_01"] = true,
		["t_ingmine_agate_01"] = true,
		["t_ingmine_agate_03"] = true,
		["t_ingmine_agate_02"] = true,
		["t_ingmine_agate_04"] = true,		
	},	
	["Agate or Quartz"] = {
		["t_ingmine_smokyquartz_01"] = true, 
		["t_ingmine_rosequartz_01"] = true,
		["t_ingmine_agate_01"] = true,
		["t_ingmine_agate_03"] = true,
		["t_ingmine_agate_02"] = true,
		["t_ingmine_agate_04"] = true,		
	},
	["Topaz or Jade"] = {
		["t_ingmine_topaz_01"] = true,
		["ab_ingmine_topaz_01"] = true,
		["t_ingmine_topazblue_01"] = true,
		["t_ingmine_jade_01"] = true,
		["ab_ingmine_firejade_01"] = true,	
	},
}

--[[ unused gems		
		"t_ingmine_citrine_01",
		"t_ingmine_turquoise_01",
		"t_ingmine_amber_01",
		"t_ingmine_bloodstone_01",
		"t_ingmine_onyx_01",
		-- oaab
		"ab_ingmine_blacktourmaline_01",
		"ab_ingmine_tourmaline_01",
		"ab_ingmine_peridot_01",
		"ab_ingmine_lodestone",
	},
		-- vanilla + tamriel rebuilt
		"t_ingmine_aquamarine_01",
		"t_ingmine_ametrine_01",
		"t_ingmine_spinel_01",
		"t_ingmine_lapislazuli_01",
		"t_ingmine_moonstone_01",
		"t_ingmine_khajiiteye_01",
		"t_ingmine_tektite_01",
		"t_ingmine_foolsgold_01",
		"t_ingmine_salt_01",
		-- oaab
		"ab_ingmine_diopside_01",
	},
	rare = {
		-- vanilla + tamriel rebuilt	
		"t_ingmine_spellstone_01",
		"t_ingmine_flashgrit_01",
	},
}
]]

local isPliersCache = {}

local function isPliers(item)
	local recordId = item.recordId
	if isPliersCache[recordId] == nil then
		local record = types.Miscellaneous.records[recordId]
		if record then
			isPliersCache[recordId] = (record.name == "Jewelcrafting Pliers")
		else
			isPliersCache[recordId] = false
		end
	end
	return isPliersCache[recordId]
end

registerWildcard{ -- tools
	id = "jc_jewelpliers",
	name = "Jewelcrafting Pliers",
	version = 1,
	--icon = "icons/tr/m/tr_misc_tongs_01.dds",
	func = function()
		local playerInventory = types.Actor.inventory(self)	
		local ret = {}
		for _, item in pairs(playerInventory:getAll(types.Miscellaneous)) do
			if isPliers(item) then
				table.insert(ret, item)
			end
		end
		return ret
	end,
}

for wildcardName, eligibleItemsTable in pairs(gemWildCards) do -- ingredients/materials
	registerWildcard({ 
		id = wildcardName,
		name = wildcardName,
		version = 1,
		func = function()
			local playerInventory = types.Actor.inventory(self)	
			local ret = {}
			for _, item in pairs(playerInventory:getAll(types.Ingredient)) do
				if eligibleItemsTable[item.recordId] then
					table.insert(ret, item)
				end
			end
			return ret
		end,
	})
end
------------------------------ chain modifiers ------------------------------

if registerQualityModifier then
	local I = require('openmw.interfaces')
	registerQualityModifier{
		id = "jc_quality",
		func = function(recipe, ctx)
			local jcStat = I.SkillFramework.getSkillStat("jewelcrafting")
			local jcSkill = jcStat and jcStat.modified or 5
			local enchantSkill = types.NPC.stats.skills.enchant(self).modified
			local jcRatio = jcSkill / (recipe.level or 1)
			if ctx.artisansTouch then jcRatio = (jcRatio + 1) / 2 end
			jcRatio = math.max(0.4, math.min(15, jcRatio))
			local q = jcRatio + enchantSkill / 400
			if ctx.artisansTouch then q = q + 0.10 end
			ctx.modified = math.floor(q * 50 + 0.5) / 50
			--print("JC overridden quality with",ctx.modified)
		end,
	}
end

-- bonus exp for gems
local commonIngredients = {
	--["ingred_adamantium_ore_01"] = true,
	--["t_ingmine_amethyst_01"] = true,
	["ingred_bonemeal_01"] = true,
	["t_ingmine_coal_01"] = true,
	--["ingred_daedras_heart_01"] = true,
	--["ingred_diamond_01"] = true,
	--["ingred_scrap_metal_01"] = true,
	--["ingred_raw_ebony_01"] = true,
	--["ingred_emerald_01"] = true,
	--["t_ingmine_oregold_01"] = true,
	["t_ingmine_oreiron_01"] = true,
	["misc_soulgem_lesser"] = true,
	--["t_ingmine_agate_03"] = true,
	--["ingred_pearl_01"] = true,
	["ingred_racer_plumes_01"] = true,
	--["ingred_raw_glass_01"] = true,
	--["ingred_ruby_01"] = true,
	--["t_ingmine_sapphire_01"] = true,
	["t_ingmine_oresilver_01"] = true,
}

-- xp by tier, harder recipes (ingred, quantity, skill) pay better. reads userData.tier.
if registerXpModifier then
	registerXpModifier{
		id = "jc_xp",
		func = function(recipe, ctx)
			-- extravagant/exquisite don't get penalized
			if recipe.level >= 45 then
				local diffMod = ctx.diffMod
				if ctx.splittedExp then
					diffMod = diffMod * 2
				end
				diffMod = (diffMod + 2) / 3
				if ctx.splittedExp then
					diffMod = diffMod / 2
				end
				ctx.modified = diffMod * ctx.recipeExp
				--print("JC overridden experience with", ctx.modified)
			end
			-- bonus xp from gems
			local bonusExp = 0
			for a,b in pairs(ctx.ingredients) do
				if not commonIngredients[a.recordId] then
					bonusExp = bonusExp + 2.5
				end
			end
			ctx.modified = ctx.modified + bonusExp
		end,
	}
end

-- amulets get enchant capacity bonus over rings
if registerStatsModifier then
	registerStatsModifier{
		id = "jc_stats",
		func = function(recipe, ctx)
			local kind = recipe.userData and recipe.userData.kind
			if kind == "necklace" then
				local recordCapacity = ctx.record.enchantCapacity
				ctx.modified.enchantCapacity = math.floor(recordCapacity * ctx.qualityMult * 1.05 + 0.5)+5 -- 5% more and +5 than CF formula
				--print("JC overridden enchantCapacity with", ctx.modified.enchantCapacity)
			end
			local jcStat = I.SkillFramework.getSkillStat("jewelcrafting")
			local jcSkill = jcStat and jcStat.modified or 5
			jcSkill = math.floor(jcSkill /2) * 2
			local recordWeight = ctx.record.weight
			ctx.modified.weight = math.max(0, (ctx.modified.weight or recordWeight) * (1 - jcSkill/200))
			ctx.modified.weight = math.floor(ctx.modified.weight*20+0.5)/20
			--print("JC overridden weight with", ctx.modified.weight)
		end,
	}
end

-- artisans touch crit for 2x value on touched jewelcrafting crafts
if registerValueModifier then
	local I = require('openmw.interfaces')
	local ui = require('openmw.ui')
	registerValueModifier{
		id = "jc_value_proc",
		func = function(recipe, ctx)
			if recipe.profession ~= "Jewelcrafting" then return end
			if not ctx.artisansTouch then return end
			local jcStat = I.SkillFramework.getSkillStat("jewelcrafting")
			local jcSkill = jcStat and jcStat.modified or 5
			local chance = 0.10 + jcSkill * 0.001
			if ctx.isPreview then
				-- chance-weighted expected value
				ctx.modified = ctx.modified * (1 + chance * (critMult - 1))
				--print("JC overridden preview value with", ctx.modified)
			elseif math.random() < chance then
				ctx.modified = ctx.modified * 2
				ui.showMessage("A brilliant cut!")
			end
		end,
	}
end

local recipes = require("scripts.jewelcrafting.recipes")
return recipes