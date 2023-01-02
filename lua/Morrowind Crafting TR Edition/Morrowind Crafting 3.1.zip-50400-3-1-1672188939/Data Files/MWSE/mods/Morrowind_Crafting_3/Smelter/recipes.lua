--[[ Smelting-materials listing -- Smelting ore, scrap, and alloying
		Part of Morrowind Crafting 3.0
		Group = Ores, Scrap, Special
		Toccatta and Drac --]]

local makerlist = {}
makerlist = {
	{id = "mc_adamantium_ingot",
	alias = "Adamantium ingot from ore",
	ingreds = {
		{ id = "ingred_adamantium_ore_01", count = 1 }
		},
	yieldCount = 5,
	difficulty = 15,
	skillCap = 35,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_adamantium_ingot",
	alias = "Batch smelt adamantium ore into ingots",
	ingreds = {
		{ id = "ingred_adamantium_ore_01", count = 1 }
		},
	yieldCount = 5,
	autocomplete = true,
	difficulty = 15,
	skillCap = 35,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_adamantium_ingot",
	alias = "Adamantium ingot from scrap",
	ingreds = {
		{ id = "mc_scrap_adamantium", count = 1 }
		},
	yieldCount = 1,
	difficulty = 15,
	skillCap = 35,
	group = "Scrap",
	taskTime = 0.5
	},
	
	{id = "mc_adamantium_ingot",
	alias = "Batch smelt adamantium scrap into ingots",
	ingreds = {
		{ id = "mc_scrap_adamantium", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 15,
	skillCap = 35,
	group = "Scrap",
	taskTime = 0.5
	},
	
	{id = "mc_dae_steel_ingot",
	alias = "Daedric steel ingot from scrap",
	ingreds = {
		{ id = "mc_scrap_daesteel", count = 1 }
		},
	yieldCount = 1,
	difficulty = 20,
	skillCap = 40,
	group = "Scrap",
	taskTime = 0.25
	},
	
	{id = "mc_dae_steel_ingot",
	alias = "Batch smelt Daedric steel scrap into ingots",
	ingreds = {
		{ id = "mc_scrap_daesteel", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 20,
	skillCap = 40,
	group = "Scrap",
	taskTime = 0.25
	},

	{id = "mc_dae_steel_ingot",
	alias = "Daedric steel ingot from alloying",
	ingreds = {
		{ id = "mc_iron_ingot", count = 20 },
		{ id = "mc_daedric_ebony", count = 1 }
		},
	yieldCount = 25,
	difficulty = 20,
	skillCap = 40,
	group = "Special",
	taskTime = 0.5
	},
	
	{id = "mc_daedric_ebony",
	alias = "Infuse raw Daedric ebony",
	ingreds = {
		{ id = "ingred_raw_ebony_01", count = 1 },
		{ id = "AnyDremoraSoul", count = 1 },
		{ id = "Magicka", count = 50}
		},
	yieldCount = 1,
	difficulty = 80,
	skillCap = 1000,
	group = "Special",
	taskTime = 1
	},
	
	{id = "mc_dae_ebony_ingot",
	alias = "Refine raw Daedric ebony",
	ingreds = {
		{ id = "mc_daedric_ebony", count = 10 }
		},
	yieldCount = 1,
	difficulty = 80,
	skillCap = 1000,
	group = "Special",
	taskTime = 3
	},
	
	{id = "mc_dae_ebony_ingot",
	alias = "Infuse refined Daedric ebony",
	ingreds = {
		{ id = "mc_ebony_ingot", count = 1 },
		{ id = "AnyDremoraSoul", count = 1 },
		{ id = "Magicka", count = 50}
		},
	yieldCount = 1,
	difficulty = 80,
	skillCap = 1000,
	group = "Special",
	taskTime = 3
	},
	
	{id = "mc_dwemer_ingot",
	alias = "Refine Dwemer Steel",
	ingreds = {
		{ id = "ingred_scrap_metal_01", count = 5 }
		},
	byproduct = {{ id = "mc_iron_ingot", yield = 22 }},
	yieldCount = 1,
	difficulty = 20,
	skillCap = 1000,
	group = "Special",
	taskTime = 0.5
	},
	
	{id = "mc_ebony_ingot",
	ingreds = {
		{ id = "ingred_raw_ebony_01", count = 10 }
		},
	yieldCount = 1,
	difficulty = 15,
	skillCap = 35,
	group = "Ores",
	taskTime = 2
	},
	
	{id = "mc_glass_ingot",
	ingreds = {
		{ id = "ingred_raw_glass_01", count = 10 }
		},
	yieldCount = 1,
	difficulty = 15,
	skillCap = 35,
	group = "Ores",
	taskTime = 2
	},
	
	{id = "mc_iron_ingot",
	alias = "Iron ingot from MC ore",
	ingreds = {
		{ id = "mc_iron_ore", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	skillCap = 25,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_iron_ingot",
	alias = "Batch smelt MC iron ore into ingots",
	ingreds = {
		{ id = "mc_iron_ore", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 5,
	skillCap = 25,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_iron_ingot",
	alias = "Iron ingot from TR ore",
	ingreds = {
		{ id = "T_IngMine_OreIron_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	skillCap = 25,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_iron_ingot",
	alias = "Batch smelt TR iron ore into ingots",
	ingreds = {
		{ id = "T_IngMine_OreIron_01", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 5,
	skillCap = 25,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_iron_ingot",
	alias = "Iron ingot from iron scrap",
	ingreds = {
		{ id = "mc_scrap_iron", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	skillCap = 25,
	group = "Scrap",
	taskTime = 0.2
	},
	
	{id = "mc_iron_ingot",
	alias = "Batch smelt iron scrap into iron ingots",
	ingreds = {
		{ id = "mc_scrap_iron", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 5,
	skillCap = 25,
	group = "Scrap",
	taskTime = 0.2
	},
	
	{id = "mc_iron_ingot",
	alias = "Iron ingot from Dwemer scrap",
	ingreds = {
		{ id = "mc_scrap_dwemer", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	skillCap = 25,
	group = "Scrap",
	taskTime = 0.25
	},
	
	{id = "mc_iron_ingot",
	alias = "Batch smelt Dwemer scrap into iron ingots",
	ingreds = {
		{ id = "mc_scrap_dwemer", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 5,
	skillCap = 25,
	group = "Scrap",
	taskTime = 0.25
	},
	
	{id = "mc_iron_ingot",
	alias = "Iron ingots from scrap metal",
	ingreds = {
		{ id = "ingred_scrap_metal_01", count = 1 }
		},
	yieldCount = 4,
	difficulty = 5,
	skillCap = 25,
	group = "Scrap",
	taskTime = 0.2
	},
	
	{id = "mc_iron_ingot",
	alias = "Batch smelt scrap metal into iron ingots",
	ingreds = {
		{ id = "ingred_scrap_metal_01", count = 1 }
		},
	yieldCount = 4,
	autocomplete = true,
	difficulty = 5,
	skillCap = 25,
	group = "Scrap",
	taskTime = 0.2
	},
	
	{id = "mc_orichalcum_ingot",
	alias = "Orichalcum ingot from TR ore",
	ingreds = {
		{ id = "T_IngMine_OreOrichalcum_01", count = 3 },
		{ id = "mc_iron_ingot", count = 5 }
		},
	yieldCount = 8,
	difficulty = 15,
	skillCap = 35,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_orichalcum_ingot",
	alias = "Batch smelt TR orichalcum ore into ingots",
	ingreds = {
		{ id = "T_IngMine_OreOrichalcum_01", count = 3 },
		{ id = "mc_iron_ingot", count = 5 }
		},
	yieldCount = 8,
	autocomplete = true,
	difficulty = 15,
	skillCap = 35,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_orichalcum_ingot",
	alias = "Orichalcum ingot from scrap",
	ingreds = {
		{ id = "mc_scrap_orcish", count = 1 }
		},
	yieldCount = 1,
	difficulty = 15,
	skillCap = 35,
	group = "Scrap",
	taskTime = 0.25
	},
	
	{id = "mc_orichalcum_ingot",
	alias = "Batch smelt orichalcum scrap into ingots",
	ingreds = {
		{ id = "mc_scrap_orcish", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 15,
	skillCap = 35,
	group = "Scrap",
	taskTime = 0.25
	},
	
	{id = "mc_orichalcum_ingot",
	alias = "Orichalcum ingot from alloying",
	ingreds = {
		{ id = "mc_iron_ingot", count = 2 },
		{ id = "mc_silver_ingot", count = 4 },
		{ id = "ingred_void_salts_01", count = 2 },
		{ id = "mc_netch_acid", count = 3 }
		},
	yieldCount = 4,
	difficulty = 45,
	skillCap = 35,
	group = "Special",
	taskTime = 0.4
	},
	
	{id = "mc_silver_ingot",
	alias = "Silver ingot from MC ore",
	ingreds = {
		{ id = "mc_silver_ore", count = 1 }
		},
	yieldCount = 1,
	difficulty = 10,
	skillCap = 30,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_silver_ingot",
	alias = "Batch smelt silver MC ore into ingots",
	ingreds = {
		{ id = "mc_silver_ore", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 10,
	skillCap = 30,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_silver_ingot",
	alias = "Silver ingot from TR ore",
	ingreds = {
		{ id = "T_IngMine_OreSilver_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 10,
	skillCap = 30,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_silver_ingot",
	alias = "Batch smelt silver TR ore into ingots",
	ingreds = {
		{ id = "T_IngMine_OreSilver_01", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 10,
	skillCap = 30,
	group = "Ores",
	taskTime = 0.5
	},
	
	{id = "mc_silver_ingot",
	alias = "Silver ingot from scrap",
	ingreds = {
		{ id = "mc_scrap_silver", count = 1 }
		},
	yieldCount = 1,
	difficulty = 10,
	skillCap = 30,
	group = "Scrap",
	taskTime = 0.25
	},
	
	{id = "mc_silver_ingot",
	alias = "Batch smelt silver scrap into ingots",
	ingreds = {
		{ id = "mc_scrap_silver", count = 1 }
		},
	yieldCount = 1,
	autocomplete = true,
	difficulty = 10,
	skillCap = 30,
	group = "Scrap",
	taskTime = 0.25
	}
}
return makerlist
