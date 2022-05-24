--[[ Woodworiking-materials listing -- creating wooden items
		Part of Morrowind Crafting 3.0
		Toccatta and Drac --]]
		-- Classes = Containers, Beds, Clothing Storage, Tables, Seating, Shelving, Furniture, Decorations, Kitchen, Miscellaneous, Tools, Shelter
		-- Group = Ash, Cypress, Hickory, Oak, Parasol, Pine, Scrapwood, Swirlwood
local makerlist = {}
makerlist = {
	{id = "mc_bed01",
	ingreds = {
		{ id = "mc_log_oak", count = 17 },
		{ id = "mc_prepared_cloth", count = 10 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Beds",
	group = "Oak",
	taskTime = 4
	},
	
	{id = "mc_bed02",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 },
		{ id = "mc_prepared_cloth", count = 10 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Beds",
	group = "Hickory",
	taskTime = 2
	},
	
	{id = "mc_bed03",
	ingreds = {
		{ id = "mc_log_pine", count = 6 },
		{ id = "mc_prepared_cloth", count = 10 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Beds",
	group = "Pine",
	taskTime = 2
	},
	
	{id = "mc_bed04",
	ingreds = {
		{ id = "mc_log_oak", count = 31 },
		{ id = "mc_prepared_cloth", count = 20 }
		},
	yieldCount = 1,
	difficulty = 100,
	class = "Beds",
	group = "Oak",
	taskTime = 2
	},
	
	{id = "mc_bed05",
	ingreds = {
		{ id = "mc_log_hickory", count = 14 },
		{ id = "mc_prepared_cloth", count = 20 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Beds",
	group = "Hickory",
	taskTime = 3.5
	},
	
	{id = "mc_bed06",
	ingreds = {
		{ id = "mc_log_pine", count = 16 },
		{ id = "mc_prepared_cloth", count = 20 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Beds",
	group = "Pine",
	taskTime = 2
	},
	
	{id = "mc_bed07",
	ingreds = {
		{ id = "mc_log_hickory", count = 18 },
		{ id = "mc_prepared_cloth", count = 20 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Beds",
	group = "Hickory",
	taskTime = 3
	},
	
	{id = "mc_bed08",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 8 },
		{ id = "mc_prepared_cloth", count = 10 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Beds",
	group = "Swirlwood",
	taskTime = 3
	},
	
	{id = "mc_bed09",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 16 },
		{ id = "mc_prepared_cloth", count = 20 }
		},
	yieldCount = 1,
	difficulty = 100,
	class = "Beds",
	group = "Swirlwood",
	taskTime = 5
	},
	
	{id = "mc_bed10",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 10 },
		{ id = "mc_prepared_cloth", count = 10 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Beds",
	group = "Swirlwood",
	taskTime = 2
	},
	
	{id = "mc_bed11",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 16 },
		{ id = "mc_prepared_cloth", count = 20 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Beds",
	group = "Swirlwood",
	taskTime = 4
	},

	{id = "mc_bed13",
	ingreds = {
		{ id = "mc_log_hickory", count = 17 },
		{ id = "mc_prepared_cloth", count = 10 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Beds",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_bed14",
	ingreds = {
		{ id = "mc_log_hickory", count = 31 },
		{ id = "mc_prepared_cloth", count = 20 }
		},
	yieldCount = 1,
	difficulty = 100,
	class = "Beds",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_bed15",
	ingreds = {
		{ id = "mc_log_hickory", count = 10 },
		{ id = "mc_prepared_cloth", count = 10 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Beds",
	group = "Hickory",
	taskTime = 5
	},

	{id = "mc_bed16",
	ingreds = {
		{ id = "mc_log_hickory", count = 10 },
		{ id = "mc_prepared_cloth", count = 10 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Beds",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_bed17",
	ingreds = {
		{ id = "mc_log_hickory", count = 16 },
		{ id = "mc_prepared_cloth", count = 20 }
		},
	yieldCount = 1,
	difficulty = 100,
	class = "Beds",
	group = "Hickory",
	taskTime = 5
	},
	
	{id = "mc_hammock",
	ingreds = {
		{ id = "mc_log_ash", count = 3 },
		{ id = "mc_prepared_cloth", count = 4 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Beds",
	group = "Ash",
	taskTime = 2
	},	
	
	{id = "mc_drawers01",
	ingreds = {
		{ id = "mc_log_oak", count = 7 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Clothing Storage",
	group = "Oak",
	taskTime = 4
	},

	{id = "mc_drawers02",
	ingreds = {
		{ id = "mc_log_cypress", count = 7 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Clothing Storage",
	group = "Cypress",
	taskTime = 3.5
	},

	{id = "mc_drawers04",
	ingreds = {
		{ id = "mc_log_parasol", count = 9 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Clothing Storage",
	group = "Parasol",
	taskTime = 3.5
	},

	{id = "mc_drawers06",
	ingreds = {
		{ id = "mc_log_scrap", count = 6 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Clothing Storage",
	group = "Scrapwood",
	taskTime = 2
	},

	{id = "mc_drawers07",
	ingreds = {
		{ id = "mc_log_oak", count = 7 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Clothing Storage",
	group = "Oak",
	taskTime = 3
	},

	{id = "mc_drawers08",
	ingreds = {
		{ id = "mc_log_parasol", count = 7 },
		{id = "mc_iron_ingot", count = 6}
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Clothing Storage",
	group = "Parasol",
	taskTime = 6
	},

	{id = "mc_drawers09",
	ingreds = {
		{ id = "mc_log_oak", count = 6 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Clothing Storage",
	group = "Oak",
	taskTime = 3
	},

	{id = "mc_drawers10",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{id = "mc_iron_ingot", count = 4}
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Clothing Storage",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_drawers11",
	ingreds = {
		{ id = "mc_log_hickory", count = 6 },
		{id = "mc_iron_ingot", count = 5}
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Clothing Storage",
	group = "Hickory",
	taskTime = 3
	},
	
	{id = "mc_wardrobe01",
	ingreds = {
		{ id = "mc_log_oak", count = 11 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Clothing Storage",
	group = "Oak",
	taskTime = 4
	},

	{id = "mc_wardrobe02",
	ingreds = {
		{ id = "mc_log_hickory", count = 13 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Clothing Storage",
	group = "Hickory",
	taskTime = 3.5
	},

	{id = "mc_wardrobe03",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 15 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Clothing Storage",
	group = "Swirlwood",
	taskTime = 6
	},
--[[
	{id = "mc_Rwardrobe03",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 17 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 100,
	class = "Clothing Storage",
	group = "Swirlwood",
	taskTime = 8
	},
]]

	{id = "mc_wardrobe04",
	ingreds = {
		{ id = "mc_log_parasol", count = 11 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 84,
	class = "Clothing Storage",
	group = "Parasol",
	taskTime = 5.5
	},

	{id = "mc_wardrobe05",
	ingreds = {
		{ id = "mc_log_oak", count = 14 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 82,
	class = "Clothing Storage",
	group = "Oak",
	taskTime = 5.4
	},

	{id = "mc_wardrobe07",
	ingreds = {
		{ id = "mc_log_ash", count = 20 },
		{ id = "mc_iron_ingot", count = 6 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Clothing Storage",
	group = "Ash",
	taskTime = 3.5
	},

	{id = "mc_wardrobe08",
	ingreds = {
		{ id = "mc_log_hickory", count = 18 },
		{ id = "mc_iron_ingot", count = 10 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Clothing Storage",
	group = "Hickory",
	taskTime = 4.5
	},

	{id = "mc_wardrobe09",
	ingreds = {
		{ id = "mc_log_parasol", count = 18 },
		{ id = "mc_iron_ingot", count = 10 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Clothing Storage",
	group = "Parasol",
	taskTime = 4
	},
	
	{id = "mc_hutch",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 }
		},
	yieldCount = 1,
	difficulty = 75,
	class = "Furniture",
	group = "Hickory",
	taskTime = 3.75
	},

	{id = "mc_hutch01",
	ingreds = {
		{ id = "mc_log_oak", count = 12 }
		},
	yieldCount = 1,
	difficulty = 85,
	class = "Furniture",
	group = "Oak",
	taskTime = 5
	},

	{id = "mc_cabinet01",
	ingreds = {
		{ id = "mc_log_oak", count = 9 }
		},
	yieldCount = 1,
	difficulty = 75,
	class = "Furniture",
	group = "Oak",
	taskTime = 3.75
	},

	{id = "mc_Rcabinet01",
	ingreds = {
		{ id = "mc_log_oak", count = 10 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 85,
	class = "Furniture",
	group = "Oak",
	taskTime = 4.25
	},

	{id = "mc_cabinet03",
	ingreds = {
		{ id = "mc_log_oak", count = 8 },
		{id = "mc_iron_ingot", count = 4}
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Furniture",
	group = "Oak",
	taskTime = 2.5
	},

	{id = "mc_cabinet04",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 12 },
		{id = "mc_iron_ingot", count = 4}
		},
	yieldCount = 1,
	difficulty = 85,
	class = "Tables",
	group = "Swirlwood",
	taskTime = 4
	},

	{id = "mc_couch01",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 4 },
		{ id = "mc_prepared_cloth", count = 10 },
		{ id = "mc_straw", count = 24},
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Furniture",
	group = "Swirlwood",
	taskTime = 4
	},

	{id = "mc_couch02",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 4 },
		{ id = "mc_prepared_cloth", count = 10 },
		{ id = "mc_straw", count = 24},
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Furniture",
	group = "Swirlwood",
	taskTime = 4
	},
	
	{id = "mc_drawers03",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 9 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Clothing Storage",
	group = "Swirlwood",
	taskTime = 5
	},
	
	{id = "mc_Rwardrobe02",
	ingreds = {
		{ id = "mc_log_hickory", count = 12 },
		{ id = "mc_iron_ingot", count = 4 }
		},
	yieldCount = 1,
	difficulty = 85,
	class = "Clothing Storage",
	group = "Hickory",
	taskTime = 5.25
	},
	
	{id = "mc_Rhutch",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Clothing Storage",
	group = "Hickory",
	taskTime = 6
	},
	
	{id = "mc_Rwardrobe01",
	ingreds = {
		{ id = "mc_log_oak", count = 10 },
		{ id = "mc_iron_ingot", count = 4 }
		},
	yieldCount = 1,
	difficulty = 75,
	class = "Clothing Storage",
	group = "Oak",
	taskTime = 5
	},
	
	{id = "mc_bar01",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Containers",
	group = "Hickory",
	taskTime = 4
	},
	
	{id = "mc_bar02",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Containers",
	group = "Hickory",
	taskTime = 4
	},
	
	{id = "mc_bar03",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Containers",
	group = "Hickory",
	taskTime = 4
	},
	
	{id = "mc_bar04",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Containers",
	group = "Hickory",
	taskTime = 4
	},
	
	{id = "mc_bar05",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Containers",
	group = "Hickory",
	taskTime = 4
	},
	
	{id = "mc_Rbar01",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Containers",
	group = "Hickory",
	taskTime = 5
	},
	
	{id = "mc_Rbar02",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Containers",
	group = "Hickory",
	taskTime = 5
	},
	
	{id = "mc_Rbar03",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Containers",
	group = "Hickory",
	taskTime = 5
	},
	
	{id = "mc_Rbar04",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Containers",
	group = "Hickory",
	taskTime = 5
	},
	
	{id = "mc_Rbar05",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Containers",
	group = "Hickory",
	taskTime = 5
	},
	
	{id = "mc_bar06",
	ingreds = {
		{ id = "mc_log_cypress", count = 5 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Cypress",
	taskTime = 4
	},
	
	{id = "mc_bar07",
	ingreds = {
		{ id = "mc_log_cypress", count = 5 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Cypress",
	taskTime = 4
	},
	
	{id = "mc_bar08",
	ingreds = {
		{ id = "mc_log_cypress", count = 4 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Cypress",
	taskTime = 4
	},
	
	{id = "mc_bar09",
	ingreds = {
		{ id = "mc_log_cypress", count = 5 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Cypress",
	taskTime = 4
	},
	
	{id = "mc_bar10",
	ingreds = {
		{ id = "mc_log_cypress", count = 5 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Cypress",
	taskTime = 4
	},
	
	{id = "mc_barrel01",
	ingreds = {
		{ id = "mc_log_ash", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Containers",
	group = "Ash",
	taskTime = 3
	},
	
	{id = "mc_barrel02",
	ingreds = {
		{ id = "mc_log_oak", count = 3 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Containers",
	group = "Oak",
	taskTime = 3.5
	},

	{id = "mc_Rbarrel01",
	ingreds = {
		{ id = "mc_log_ash", count = 3 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Containers",
	group = "Ash",
	taskTime = 4
	},

	{id = "mc_Rbarrel02",
	ingreds = {
		{ id = "mc_log_oak", count = 4 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Containers",
	group = "Oak",
	taskTime = 4.5
	},

	{id = "mc_barrel05e",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Containers",
	group = "Oak",
	taskTime = 1
	},

	{id = "mc_barrel06",
	ingreds = {
		{ id = "mc_log_pine", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Containers",
	group = "Pine",
	taskTime = 3
	},

	{id = "mc_barrel07",
	ingreds = {
		{ id = "mc_log_cypress", count = 3 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Containers",
	group = "Cypress",
	taskTime = 3
	},

	{id = "mc_barrel08",
	ingreds = {
		{ id = "mc_log_hickory", count = 3 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Containers",
	group = "Hickory",
	taskTime = 3.5
	},
	
	{id = "mc_crate01",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Containers",
	group = "Scrapwood",
	taskTime = 1
	},
	
	{id = "mc_crate02",
	ingreds = {
		{ id = "mc_log_ash", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Containers",
	group = "Ash",
	taskTime = 1
	},
	
	{id = "mc_crate03",
	ingreds = {
		{ id = "mc_log_scrap", count = 3 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Containers",
	group = "Scrapwood",
	taskTime = 1
	},
	
	{id = "mc_crate_01_long",
	ingreds = {
		{ id = "mc_log_ash", count = 3 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Containers",
	group = "Ash",
	taskTime = 1.5
	},

	{id = "mc_crate04",
	ingreds = {
		{ id = "mc_log_parasol", count = 2 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Containers",
	group = "Parasol",
	taskTime = 1.5
	},

	{id = "mc_crate05",
	ingreds = {
		{ id = "mc_log_parasol", count = 1 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Containers",
	group = "Parasol",
	taskTime = 0.5
	},

	{id = "mc_crate06",
	ingreds = {
		{ id = "mc_log_parasol", count = 1 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Containers",
	group = "Parasol",
	taskTime = 0.5
	},

	{id = "mc_crate07",
	ingreds = {
		{ id = "mc_log_scrap", count = 2 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Containers",
	group = "Scrapwood",
	taskTime = 2
	},

	{id = "mc_crate08",
	ingreds = {
		{ id = "mc_log_ash", count = 2 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Containers",
	group = "Ash",
	taskTime = 2
	},

	{id = "mc_crate09",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Containers",
	group = "Swirlwood",
	taskTime = 4
	},

	{id = "mc_crate10",
	ingreds = {
		{ id = "mc_log_parasol", count = 2 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Containers",
	group = "Parasol",
	taskTime = 2
	},
	
	{id = "mc_chest01",
	ingreds = {
		{ id = "mc_log_ash", count = 2 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Containers",
	group = "Ash",
	taskTime = 3
	},
	
	{id = "mc_chest02",
	ingreds = {
		{ id = "mc_log_oak", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Containers",
	group = "Oak",
	taskTime = 3.5
	},

	{id = "mc_Rchest02",
	ingreds = {
		{ id = "mc_log_oak", count = 3 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Oak",
	taskTime = 4
	},
	
	{id = "mc_chest03",
	ingreds = {
		{ id = "mc_log_pine", count = 2 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Containers",
	group = "Pine",
	taskTime = 2.5
	},
	
	{id = "mc_chest04",
	ingreds = {
		{ id = "mc_log_ash", count = 2 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Containers",
	group = "Ash",
	taskTime = 3
	},
	
	{id = "mc_chest05",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 75,
	class = "Containers",
	group = "Swirlwood",
	taskTime = 5
	},

	{id = "mc_Rchest05",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 3 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 85,
	class = "Containers",
	group = "Swirlwood",
	taskTime = 6
	},
	
	{id = "mc_chest06",
	ingreds = {
		{ id = "mc_log_oak", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Containers",
	group = "Oak",
	taskTime = 5
	},

	{id = "mc_Rchest06",
	ingreds = {
		{ id = "mc_log_oak", count = 3 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Containers",
	group = "Oak",
	taskTime = 6
	},
	
	{id = "mc_chest07",
	ingreds = {
		{ id = "mc_log_parasol", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_chest10",
	ingreds = {
		{ id = "mc_log_parasol", count = 2 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Containers",
	group = "Parasol",
	taskTime = 2
	},

	{id = "mc_chest11",
	ingreds = {
		{ id = "mc_log_parasol", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Containers",
	group = "Parasol",
	taskTime = 3
	},

	{id = "mc_chest12",
	ingreds = {
		{ id = "mc_log_parasol", count = 4 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Containers",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_chest13",
	ingreds = {
		{ id = "mc_log_parasol", count = 24 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Containers",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_chest14",
	ingreds = {
		{ id = "mc_log_parasol", count = 5 },
		{id = "mc_iron_ingot", count = 4}
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Containers",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_chest15",
	ingreds = {
		{ id = "mc_log_parasol", count = 3 },
		{id = "mc_iron_ingot", count = 2}
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Containers",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_chest16",
	ingreds = {
		{ id = "mc_log_scrap", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Containers",
	group = "Scrapwood",
	taskTime = 3.5
	},

	{id = "mc_chest17",
	ingreds = {
		{ id = "mc_log_scrap", count = 5 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Containers",
	group = "Scrapwood",
	taskTime = 3.5
	},

	{id = "mc_chest18",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 7 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 75,
	class = "Containers",
	group = "Swirlwood",
	taskTime = 4.5
	},

	{id = "mc_chest19",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Containers",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_chest20",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Containers",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_chest21",
	ingreds = {
		{ id = "mc_log_scrap", count = 2 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Containers",
	group = "Scrapwood",
	taskTime = 2
	},

	{id = "mc_chest22",
	ingreds = {
		{ id = "mc_log_scrap", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Containers",
	group = "Scrapwood",
	taskTime = 3
	},

	{id = "mc_chest23",
	ingreds = {
		{ id = "mc_log_pine", count = 2 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Containers",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_chest24",
	ingreds = {
		{ id = "mc_log_parasol", count = 3 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Containers",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_chest25",
	ingreds = {
		{ id = "mc_log_parasol", count = 4 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Containers",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_chest26",
	ingreds = {
		{ id = "mc_log_pine", count = 3 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Containers",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_chest27",
	ingreds = {
		{ id = "mc_log_parasol", count = 6 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Containers",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_chest28",
	ingreds = {
		{ id = "mc_log_ash", count = 2 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Containers",
	group = "Ash",
	taskTime = 2
	},

	{id = "mc_chest29",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 },
		{ id = "mc_iron_ingot", count = 4 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Containers",
	group = "Hickory",
	taskTime = 5
	},

	{id = "mc_chest30",
	ingreds = {
		{ id = "mc_log_pine", count = 2 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Containers",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_chest32",
	ingreds = {
		{ id = "mc_log_parasol", count = 2 },
		{ id = "mc_iron_ingot", count = 10 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Containers",
	group = "Parasol",
	taskTime = 6
	},

	{id = "mc_chest33",
	ingreds = {
		{ id = "mc_log_parasol", count = 1 },
		{ id = "mc_iron_ingot", count = 5 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Containers",
	group = "Parasol",
	taskTime = 6
	},

	{id = "mc_chest34",
	ingreds = {
		{ id = "mc_log_parasol", count = 1 },
		{ id = "mc_iron_ingot", count = 5 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Containers",
	group = "Parasol",
	taskTime = 6
	},

	{id = "mc_chest35",
	ingreds = {
		{ id = "mc_log_parasol", count = 5 },
		{ id = "mc_clay", count = 4},
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Containers",
	group = "Parasol",
	taskTime = 6
	},

	{id = "mc_chest_small01",
	ingreds = {
		{ id = "mc_log_ash", count = 1 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Containers",
	group = "Ash",
	taskTime = 3
	},

	{id = "mc_chest_small02",
	ingreds = {
		{ id = "mc_log_hickory", count = 1 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Containers",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_chest_small03",
	ingreds = {
		{ id = "mc_log_ash", count = 1 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Containers",
	group = "Ash",
	taskTime = 3
	},

	{id = "mc_chest_small04",
	ingreds = {
		{ id = "mc_log_hickory", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_chest_small05",
	ingreds = {
		{ id = "mc_log_hickory", count = 1 },
		{id = "ingred_boar_leather", count = 1}
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Containers",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_chest_small06",
	ingreds = {
		{ id = "mc_log_hickory", count = 1 },
		{id = "ingred_boar_leather", count = 1}
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_chest_small07",
	ingreds = {
		{ id = "mc_log_parasol", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Parasol",
	taskTime = 3
	},
	
	{id = "mc_coatofarms05",
	ingreds = {
		{ id = "mc_log_pine", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Decorations",
	group = "Pine",
	taskTime = 0.5
	},
	
	{id = "mc_coatofarms03",
	ingreds = {
		{ id = "mc_log_pine", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Decorations",
	group = "Pine",
	taskTime = 0.5
	},
	
	{id = "mc_coatofarms01",
	ingreds = {
		{ id = "mc_log_pine", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Decorations",
	group = "Pine",
	taskTime = 0.5
	},
	
	{id = "mc_coatofarms04",
	ingreds = {
		{ id = "mc_log_pine", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Decorations",
	group = "Pine",
	taskTime = 0.5
	},
	
	{id = "mc_coatofarms02",
	ingreds = {
		{ id = "mc_log_pine", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Decorations",
	group = "Pine",
	taskTime = 0.5
	},
	
	{id = "mc_bar_door01",
	alias = "Hickory Bar Door",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Furniture",
	group = "Hickory",
	taskTime = 2
	},
	
	{id = "mc_bar_door02",
	alias = "Cypress Bar Door",
	ingreds = {
		{ id = "mc_log_cypress", count = 2 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Furniture",
	group = "Cypress",
	taskTime = 2
	},
	
	{id = "mc_lecturn01",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 5 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Furniture",
	group = "Swirlwood",
	taskTime = 3
	},
	
	{id = "mc_lecturn02",
	ingreds = {
		{ id = "mc_log_cypress", count = 5 }
		},
	yieldCount = 1,
	difficulty = 26,
	class = "Furniture",
	group = "Cypress",
	taskTime = 2
	},

	{id = "mc_lecturn03",
	ingreds = {
		{ id = "mc_log_oak", count = 4 }
		},
	yieldCount = 1,
	difficulty = 38,
	class = "Furniture",
	group = "Oak",
	taskTime = 2
	},

	{id = "mc_lecturn04",
	ingreds = {
		{ id = "mc_log_oak", count = 10 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Furniture",
	group = "Oak",
	taskTime = 3
	},

	{id = "mc_lecturn05",
	ingreds = {
		{ id = "mc_log_oak", count = 12 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Containers",
	group = "Oak",
	taskTime = 3
	},

	{id = "mc_basine",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 6 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Furniture",
	group = "Swirlwood",
	taskTime = 4
	},

	{id = "mc_bathe",
	ingreds = {
		{ id = "mc_log_hickory", count = 6 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 74,
	class = "Furniture",
	group = "Hickory",
	taskTime = 6
	},

	{id = "mc_bath01e",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Furniture",
	group = "Oak",
	taskTime = 1
	},

	{id = "mc_bath02e",
	ingreds = {
		{ id = "mc_log_hickory", count = 1 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Furniture",
	group = "Hickory",
	taskTime = 1
	},
	
	{id = "mc_divider01",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Furniture",
	group = "Hickory",
	taskTime = 3
	},
	
	{id = "mc_divider02",
	ingreds = {
		{ id = "mc_log_hickory", count = 3 },
		{ id = "mc_prepared_cloth", count = 3 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Furniture",
	group = "Hickory",
	taskTime = 3.5
	},
	
	{id = "mc_divider03",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 },
		{ id = "ingred_guar_hide_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Furniture",
	group = "Hickory",
	taskTime = 1
	},
	
	{id = "mc_divider04",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Furniture",
	group = "Hickory",
	taskTime = 3.5
	},
	
	{id = "mc_divider05",
	ingreds = {
		{ id = "mc_log_cypress", count = 7 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Furniture",
	group = "Cypress",
	taskTime = 3
	},

	{id = "mc_divider06",
	ingreds = {
		{ id = "mc_log_oak", count = 4 },
		{ id = "mc_prepared_cloth", count = 4 }
		},
	yieldCount = 1,
	difficulty = 75,
	class = "Furniture",
	group = "Oak",
	taskTime = 3.5
	},

	{id = "mc_divider07",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "ingred_boar_leather", count = 6 }
		},
	yieldCount = 1,
	difficulty = 85,
	class = "Furniture",
	group = "Hickory",
	taskTime = 4
	},
	
	{id = "misc_com_broom_01",
	ingreds = {
		{ id = "mc_log_pine", count = 1 },
		{ id = "mc_straw", count = 2 }
		},
	yieldCount = 1,
	difficulty = 2,
	class = "Kitchen",
	group = "Pine",
	taskTime = 0.25
	},
	
	{id = "misc_com_bucket_01",
	ingreds = {
		{ id = "mc_log_pine", count = 1 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 7,
	class = "Kitchen",
	group = "Pine",
	taskTime = 1
	},
	
	{id = "misc_com_wood_bowl_02",
	ingreds = {
		{ id = "mc_log_ash", count = 1 }
		},
	yieldCount = 2,
	difficulty = 3,
	class = "Kitchen",
	group = "Ash",
	taskTime = 0.25
	},
	
	{id = "mc_cupboard01",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Kitchen",
	group = "Hickory",
	taskTime = 4
	},

	{id = "mc_cupboard02",
	ingreds = {
		{ id = "mc_log_hickory", count = 6 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Kitchen",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_cupboard03",
	ingreds = {
		{ id = "mc_log_hickory", count = 8 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Kitchen",
	group = "Hickory",
	taskTime = 3.5
	},

	{id = "mc_cupboard04",
	ingreds = {
		{ id = "mc_log_oak", count = 5 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Kitchen",
	group = "Oak",
	taskTime = 3.5
	},

	{id = "mc_cupboard05",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_iron_ingot", count = 3 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Kitchen",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_cupboard06",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 7 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Kitchen",
	group = "Swirlwood",
	taskTime = 3
	},
		
	{id = "misc_com_wood_knife",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 6,
	difficulty = 2,
	class = "Kitchen",
	group = "Oak",
	taskTime = 0.25
	},
	
	{id = "misc_com_wood_fork",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	yieldCount = 6,
	difficulty = 2,
	class = "Kitchen",
	group = "Oak",
	taskTime = 0.1
	},
	
	{id = "misc_com_wood_spoon_01",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	yieldCount = 6,
	difficulty = 1,
	class = "Kitchen",
	group = "Oak",
	taskTime = 0.1
	},
	
	{id = "Misc_Com_Wood_Bowl_01",
	ingreds = {
		{ id = "mc_log_hickory", count = 1 }
		},
	yieldCount = 2,
	difficulty = 5,
	class = "Kitchen",
	group = "Hickory",
	taskTime = 0.25
	},
	
	{id = "misc_com_wood_bowl_04",
	ingreds = {
		{ id = "mc_log_hickory", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Kitchen",
	group = "Hickory",
	taskTime = 0.25
	},
	
	{id = "Misc_Com_Wood_Bowl_05",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Kitchen",
	group = "Oak",
	taskTime = 0.25
	},
	
	{id = "misc_com_wood_spoon_02",
	alias = "Mixing Spoon",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	yieldCount = 2,
	difficulty = 4,
	class = "Kitchen",
	group = "Oak",
	taskTime = 0.2
	},
	
	{id = "misc_com_wood_bowl_03",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	yieldCount = 2,
	difficulty = 3,
	class = "Kitchen",
	group = "Oak",
	taskTime = 0.1
	},
	
	{id = "misc_rollingpin_01",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 }
		},
	yieldCount = 1,
	difficulty = 3,
	class = "Kitchen",
	group = "Scrapwood",
	taskTime = 0.1
	},
	
	{id = "misc_com_wood_cup_01",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 }
		},
	yieldCount = 2,
	difficulty = 5,
	class = "Kitchen",
	group = "Scrapwood",
	taskTime = 0.25
	},
	
	{id = "misc_com_wood_cup_02",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 }
		},
	yieldCount = 2,
	difficulty = 5,
	class = "Kitchen",
	group = "Scrapwood",
	taskTime = 0.25
	},
	
	{id = "mc_tray",
	ingreds = {
		{ id = "mc_log_pine", count = 1 }
		},
	yieldCount = 1,
	difficulty = 3,
	class = "Kitchen",
	group = "Pine",
	taskTime = 0.25
	},

	{id = "mc_cutting_board",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_metalworking_kit", count = 1, consumed = false },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Kitchen",
	group = "Oak",
	taskTime = 2
	},

	{id = "mc_easel01",
	ingreds = {
		{id = "mc_log_oak", count = 5}
		},
	yieldCount = 1,
	difficulty = 40,
	class ="Miscellaneous",
	group = "Oak",
	taskTime = 3
	},
	
	{id = "mc_stool02",
	ingreds = {
		{ id = "mc_log_pine", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Pine",
	taskTime = 1.5
	},

	{id = "mc_stool08",
	ingreds = {
		{ id = "mc_log_parasol", count = 3 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Parasol",
	taskTime = 1.5
	},

	{id = "mc_stool09",
	ingreds = {
		{ id = "mc_log_cypress", count = 3 }
		},
	yieldCount = 1,
	difficulty = 34,
	class = "Seating",
	group = "Cypress",
	taskTime = 2
	},

	{id = "mc_stool10",
	ingreds = {
		{ id = "mc_log_ash", count = 3 }
		},
	yieldCount = 1,
	difficulty = 28,
	class = "Seating",
	group = "Ash",
	taskTime = 1.5
	},

	{id = "mc_stool11",
	ingreds = {
		{ id = "mc_log_ash", count = 1 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Seating",
	group = "Ash",
	taskTime = 2
	},

	{id = "mc_stool12",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Hickory",
	taskTime = 1
	},

	{id = "mc_stool13",
	ingreds = {
		{ id = "mc_log_oak", count = 2 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Seating",
	group = "Oak",
	taskTime = 2
	},

	{id = "mc_stool14",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Seating",
	group = "Hickory",
	taskTime = 1
	},

	{id = "mc_stool15",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Seating",
	group = "Hickory",
	taskTime = 0.5
	},

	{id = "mc_bench07",
	ingreds = {
		{ id = "mc_log_pine", count = 3 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Seating",
	group = "Pine",
	taskTime = 1
	},

	{id = "mc_bench08",
	ingreds = {
		{ id = "mc_log_parasol", count = 4 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Seating",
	group = "Parasol",
	taskTime = 1
	},
	
	{id = "mc_bench04",
	ingreds = {
		{ id = "mc_log_scrap", count = 2 }
		},
	yieldCount = 1,
	difficulty = 7,
	class = "Seating",
	group = "Scrapwood",
	taskTime = 0.5
	},

	{id = "mc_bench03",
	ingreds = {
		{ id = "mc_log_ash", count = 3 }
		},
	yieldCount = 1,
	difficulty = 12,
	class = "Seating",
	group = "Ash",
	taskTime = .75
	},

	{id = "mc_bench11",
	ingreds = {
		{ id = "mc_log_hickory", count = 3 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Seating",
	group = "Hickory",
	taskTime = 1
	},

	{id = "mc_bench12",
	ingreds = {
		{ id = "mc_log_hickory", count = 3 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Hickory",
	taskTime = 1
	},

	{id = "mc_bench13",
	ingreds = {
		{ id = "mc_log_hickory", count = 3 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Hickory",
	taskTime = 1.5
	},

	{id = "mc_bench14",
	ingreds = {
		{ id = "mc_log_oak", count = 5 },
		{id = "mc_iron_ingot", count = 3}
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Seating",
	group = "Hickory",
	taskTime = 1
	},

	{id = "mc_bench15",
	ingreds = {
		{ id = "mc_log_oak", count = 7 },
		{id = "mc_iron_ingot", count = 4}
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Seating",
	group = "Oak",
	taskTime = 1
	},

	{id = "mc_bench16",
	ingreds = {
		{ id = "mc_log_oak", count = 8 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Seating",
	group = "Oak",
	taskTime = 3
	},

	{id = "mc_bench17",
	ingreds = {
		{ id = "mc_log_oak", count = 6 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Seating",
	group = "Oak",
	taskTime = 2
	},

	{id = "mc_bin01",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 },
		{id = "mc_iron_ingot", count = 3}
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Furniture",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_bin02",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{id = "mc_iron_ingot", count = 2}
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Furniture",
	group = "Hickory",
	taskTime = 2
	},
	
	{id = "mc_bin03",
	ingreds = {
		{ id = "mc_log_hickory", count = 6 },
		{id = "mc_iron_ingot", count = 3}
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Furniture",
	group = "Hickory",
	taskTime = 1.5
	},

	{id = "mc_bin04",
	ingreds = {
		{ id = "mc_log_hickory", count = 3 },
		{id = "mc_iron_ingot", count = 2}
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Furniture",
	group = "Hickory",
	taskTime = 1.5
	},
	
	{id = "mc_chair02",
	ingreds = {
		{ id = "mc_log_cypress", count = 1 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Seating",
	group = "Cypress",
	taskTime = 1.5
	},

	{id = "mc_chair06",
	ingreds = {
		{ id = "mc_log_parasol", count = 4 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Seating",
	group = "Parasol",
	taskTime = 1.5
	},

	{id = "mc_chair08",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 4 }
		},
	yieldCount = 1,
	difficulty = 72,
	class = "Seating",
	group = "Swirlwood",
	taskTime = 4
	},

	{id = "mc_chair09",
	ingreds = {
		{ id = "mc_log_ash", count = 2 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 12,
	class = "Seating",
	group = "Ash",
	taskTime = 1
	},

	{id = "mc_chair10",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Seating",
	group = "Hickory",
	taskTime = 1.5
	},

	{id = "mc_chair11",
	ingreds = {
		{ id = "mc_log_hickory", count = 10 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Seating",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_chair12",
	ingreds = {
		{ id = "mc_log_hickory", count = 12 },
		{id = "ingred_guard_hide_01", count = 2}
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Seating",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_stool04",
	ingreds = {
		{ id = "mc_log_scrap", count = 2 }
		},
	yieldCount = 1,
	difficulty = 10,
	class = "Seating",
	group = "Scrapwood",
	taskTime = 0.5
	},
	
	{id = "mc_chair04",
	ingreds = {
		{ id = "mc_log_cypress", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Seating",
	group = "Cypress",
	taskTime = 2.5
	},
	
	{id = "mc_chair01",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_chair13",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_chair14",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_chair15",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_chair16",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_chair17",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_prepared_cloth", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Seating",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_chair18",
	ingreds = {
		{ id = "mc_log_parasol", count = 5 },
		{ id = "mc_prepared_cloth", count = 4 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Seating",
	group = "Parasol",
	taskTime = 2
	},

	{id = "mc_chair19",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_prepared_cloth", count = 2 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Seating",
	group = "Hickory",
	taskTime = 3.5
	},

	{id = "mc_chair20",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 },
		{ id = "mc_prepared_cloth", count = 2 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Seating",
	group = "Hickory",
	taskTime = 3.5
	},
	
	{id = "mc_bench06",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 2 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Seating",
	group = "Swirlwood",
	taskTime = 2
	},
	
	{id = "mc_chair05",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 5 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Seating",
	group = "Swirlwood",
	taskTime = 3.5
	},
	
	{id = "mc_stool05",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 2 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Seating",
	group = "Swirlwood",
	taskTime = 2.5
	},
	
	{id = "mc_bench02",
	ingreds = {
		{ id = "mc_log_oak", count = 2 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Seating",
	group = "Oak",
	taskTime = 1
	},
	
	{id = "mc_stool03",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Seating",
	group = "Oak",
	taskTime = 2
	},
	
	{id = "mc_bench01",
	ingreds = {
		{ id = "mc_log_pine", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Seating",
	group = "Pine",
	taskTime = 0.5
	},
	
	{id = "mc_stool01",
	ingreds = {
		{ id = "mc_log_pine", count = 1 }
		},
	yieldCount = 1,
	difficulty = 15,
	class = "Seating",
	group = "Pine",
	taskTime = 1
	},
	
	{id = "mc_chair03",
	ingreds = {
		{ id = "mc_log_scrap", count = 2 }
		},
	yieldCount = 1,
	difficulty = 15,
	class = "Seating",
	group = "Scrapwood",
	taskTime = 1
	},
	
	{id = "mc_bench05",
	ingreds = {
		{ id = "mc_log_scrap", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Seating",
	group = "Scrapwood",
	taskTime = 0.5
	},
	
	{id = "mc_bookshelf03",
	ingreds = {
		{ id = "mc_log_scrap", count = 4 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Shelving",
	group = "Scrapwood",
	taskTime = 1
	},
	
	{id = "mc_bookshelf02",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Shelving",
	group = "Hickory",
	taskTime = 2.25
	},

	{id = "mc_bookshelf12",
	ingreds = {
		{ id = "mc_log_hickory", count = 10 },
		{id = "mc_iron_ingot", count = 6},
		{id = "ingred_boar_leather", count = 4}
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Shelving",
	group = "Hickory",
	taskTime = 2.25
	},

	{id = "mc_bookshelf13",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 },
		{id = "mc_iron_ingot", count = 4},
		{id = "ingred_boar_leather", count = 3}
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Shelving",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_bookshelf14",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{id = "mc_iron_ingot", count = 3},
		{id = "ingred_boar_leather", count = 2}
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Shelving",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_bookshelf15",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Shelving",
	group = "Hickory",
	taskTime = 1
	},

	{id = "mc_bookshelf16",
	ingreds = {
		{ id = "mc_log_parasol", count = 8 },
		{id = "mc_iron_ingot", count = 6}
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Shelving",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_bookshelf17",
	ingreds = {
		{ id = "mc_log_parasol", count = 15 },
		{id = "mc_iron_ingot", count = 8}
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Shelving",
	group = "Parasol",
	taskTime = 6
	},

	{id = "mc_bookshelf18",
	ingreds = {
		{ id = "mc_log_oak", count = 30 }
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Shelving",
	group = "Oak",
	taskTime = 3
	},

	{id = "mc_bookshelf19",
	ingreds = {
		{ id = "mc_log_oak", count = 22 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Shelving",
	group = "Oak",
	taskTime = 2.5
	},

	{id = "mc_bookshelf20",
	ingreds = {
		{ id = "mc_log_oak", count = 17 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Shelving",
	group = "Oak",
	taskTime = 2
	},

	{id = "mc_bookshelf21",
	ingreds = {
		{ id = "mc_log_oak", count = 12 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Shelving",
	group = "Oak",
	taskTime = 2.5
	},

	{id = "mc_bookshelf22",
	ingreds = {
		{ id = "mc_log_scrap", count = 7 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Shelving",
	group = "Scrapwood",
	taskTime = 1
	},

	{id = "mc_bookshelf23",
	ingreds = {
		{ id = "mc_log_scrap", count = 5 }
		},
	yieldCount = 1,
	difficulty = 22,
	class = "Shelving",
	group = "Scrapwood",
	taskTime = 1
	},

	{id = "mc_bookshelf24",
	ingreds = {
		{ id = "mc_log_scrap", count = 3 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Shelving",
	group = "Scrapwood",
	taskTime = 0.5
	},

	{id = "mc_bookshelf25",
	ingreds = {
		{ id = "mc_log_scrap", count = 4 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Shelving",
	group = "Scrapwood",
	taskTime = 1
	},
	
	{id = "mc_bookshelf26",
	ingreds = {
		{ id = "mc_log_scrap", count = 7 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Shelving",
	group = "Hickory",
	taskTime = 3
	},
	
	{id = "mc_winerack03",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 }
		},
	yieldCount = 1,
	difficulty = 85,
	class = "Shelving",
	group = "Hickory",
	taskTime = 6
	},

	{id = "mc_shelf01",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 2 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Shelving",
	group = "Swirlwood",
	taskTime = 2
	},

	{id = "mc_shelf02",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Shelving",
	group = "Oak",
	taskTime = 1.5
	},

	{id = "mc_shelf03",
	ingreds = {
		{ id = "mc_log_oak", count = 2 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Shelving",
	group = "Oak",
	taskTime = 2
	},

	{id = "mc_shelf04",
	ingreds = {
		{ id = "mc_log_pine", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Shelving",
	group = "Pine",
	taskTime = 0.5
	},
	
	{id = "mc_shelf05",
	ingreds = {
		{ id = "mc_log_pine", count = 2 }
		},
	yieldCount = 1,
	difficulty = 15,
	class = "Shelving",
	group = "Pine",
	taskTime = 2
	},
	
	{id = "mc_shelf06",
	ingreds = {
		{ id = "mc_log_ash", count = 2 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Shelving",
	group = "Ash",
	taskTime = 0.5
	},
	
	{id = "mc_shelf07",
	ingreds = {
		{ id = "mc_log_ash", count = 3 }
		},
	yieldCount = 1,
	difficulty = 10,
	class = "Shelving",
	group = "Ash",
	taskTime = 1
	},

	{id = "mc_shelf08",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 }
		},
	yieldCount = 1,
	difficulty = 12,
	class = "Shelving",
	group = "Hickory",
	taskTime = 0.5
	},

	{id = "mc_shelf09",
	ingreds = {
		{ id = "mc_log_parasol", count = 3 }
		},
	yieldCount = 1,
	difficulty = 12,
	class = "Shelving",
	group = "Parasol",
	taskTime = 0.5
	},

	{id = "mc_shelf10",
	ingreds = {
		{ id = "mc_log_oak", count = 4 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Shelving",
	group = "Oak",
	taskTime = 1
	},

	{id = "mc_shelf11",
	ingreds = {
		{ id = "mc_log_hickory", count = 2 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Shelving",
	group = "Hickory",
	taskTime = 2
	},

	{id = "mc_shelf12",
	ingreds = {
		{ id = "mc_log_hickory", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Shelving",
	group = "Hickory",
	taskTime = 1
	},

	{id = "mc_shelf13",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 7 },
		{id = "mc_iron_ingot", count = 2}
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Shelving",
	group = "Swirlwood",
	taskTime = 4
	},

	{id = "mc_shelf14",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Shelving",
	group = "Oak",
	taskTime = 1
	},
	
	{id = "mc_bookshelf04",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 8 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Shelving",
	group = "Swirlwood",
	taskTime = 4
	},

	{id = "mc_bookshelf06",
	ingreds = {
		{ id = "mc_log_parasol", count = 13 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Shelving",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_bookshelf07",
	ingreds = {
		{ id = "mc_log_pine", count = 60 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Shelving",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_bookshelf08",
	ingreds = {
		{ id = "mc_log_pine", count = 25 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Shelving",
	group = "Pine",
	taskTime = 1.5
	},

	{id = "mc_bookshelf09",
	ingreds = {
		{ id = "mc_log_pine", count = 21 }
		},
	yieldCount = 1,
	difficulty = 28,
	class = "Shelving",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_bookshelf10",
	ingreds = {
		{ id = "mc_log_pine", count = 21 }
		},
	yieldCount = 1,
	difficulty = 23,
	class = "Shelving",
	group = "Pine",
	taskTime = 1.5
	},
	
	{id = "mc_winerack02",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 8 }
		},
	yieldCount = 1,
	difficulty = 95,
	class = "Shelving",
	group = "Swirlwood",
	taskTime = 6
	},
	
	{id = "mc_bookshelf01",
	ingreds = {
		{ id = "mc_log_oak", count = 8 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Shelving",
	group = "Oak",
	taskTime = 2.25
	},
	
	{id = "mc_winerack01",
	ingreds = {
		{ id = "mc_log_oak", count = 7 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Shelving",
	group = "Oak",
	taskTime = 6
	},

	{id = "mc_scrollrack01",
	ingreds = {
		{ id = "mc_log_cypress", count = 8 }
		},
	yieldCount = 1,
	difficulty = 85,
	class = "Shelving",
	group = "Cypress",
	taskTime = 6
	},

	{id = "mc_scrollrack02",
	ingreds = {
		{ id = "mc_log_cypress", count = 7 }
		},
	yieldCount = 1,
	difficulty = 85,
	class = "Shelving",
	group = "Cypress",
	taskTime = 6
	},

	{id = "mc_scrollrack03",
	ingreds = {
		{ id = "mc_log_parasol", count = 8 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Shelving",
	group = "Parasol",
	taskTime = 5
	},

	{id = "mc_scrollrack04",
	ingreds = {
		{ id = "mc_log_parasol", count = 7 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Shelving",
	group = "Parasol",
	taskTime = 6
	},

	{id = "mc_scrollrack05",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 8 }
		},
	yieldCount = 1,
	difficulty = 100,
	class = "Shelving",
	group = "Swirlwood",
	taskTime = 7
	},

	{id = "mc_scrollrack06",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 7 }
		},
	yieldCount = 1,
	difficulty = 100,
	class = "Shelving",
	group = "Swirlwood",
	taskTime = 7
	},

	{id = "mc_weaponrack02",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	yieldCount = 1,
	difficulty = 10,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 0.5
	},

	{id = "mc_weaponrack03",
	ingreds = {
		{id = "mc_log_swirlwood", count = 5},
		{id = "mc_rope", count = 1},
		{id = "mc_iron_ingot", count = 6}
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Miscellaneous",
	group = "Swirlwood",
	taskTime = 4
	},

	{id = "mc_weaponrack04",
	ingreds = {
		{id = "mc_log_scrap", count = 6}
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Miscellaneous",
	group = "Scrapwood",
	taskTime = 2
	},

	{id = "mc_weaponrack05",
	ingreds = {
		{id = "mc_log_hickory", count = 4}
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Miscellaneous",
	group = "Hickory",
	taskTime = 2
	},
	
	{id = "mc_table13",
	ingreds = {
		{ id = "mc_log_scrap", count = 2 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Tables",
	group = "Scrapwood",
	taskTime = 1
	},

	{id = "mc_table20",
	ingreds = {
		{ id = "mc_log_cypress", count = 10 }
		},
	yieldCount = 1,
	difficulty = 58,
	class = "Tables",
	group = "Cypress",
	taskTime = 3
	},

	{id = "mc_table21",
	ingreds = {
		{ id = "mc_log_parasol", count = 10 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Tables",
	group = "Parasol",
	taskTime = 3
	},

	{id = "mc_table22",
	ingreds = {
		{ id = "mc_log_parasol", count = 11 }
		},
	yieldCount = 1,
	difficulty = 62,
	class = "Tables",
	group = "Parasol",
	taskTime = 3.25
	},

	{id = "mc_table23",
	ingreds = {
		{ id = "mc_log_parasol", count = 7 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Tables",
	group = "Parasol",
	taskTime = 2
	},
	
	{id = "mc_desk01",
	ingreds = {
		{ id = "mc_log_cypress", count = 8 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Furniture",
	group = "Cypress",
	taskTime = 6
	},

	{id = "mc_desk02",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 8 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Tables",
	group = "Swirlwood",
	taskTime = 5
	},

	{id = "mc_desk03",
	ingreds = {
		{ id = "mc_log_parasol", count = 7 }
		},
	yieldCount = 1,
	difficulty = 75,
	class = "Furniture",
	group = "Parasol",
	taskTime = 5.75
	},

	{id = "mc_desk05",
	ingreds = {
		{ id = "mc_log_oak", count = 20 },
		{id = "mc_iron_ingot", count = 3}
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Furniture",
	group = "Oak",
	taskTime = 6
	},

	{id = "mc_desk06",
	ingreds = {
		{ id = "mc_log_oak", count = 21 },
		{id = "mc_iron_ingot", count = 3}
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Furniture",
	group = "Oak",
	taskTime = 8
	},

	{id = "mc_desk07",
	ingreds = {
		{ id = "mc_log_parasol", count = 25 },
		{id = "mc_iron_ingot", count = 12}
		},
	yieldCount = 1,
	difficulty = 100,
	class = "Furniture",
	group = "Parasol",
	taskTime = 10
	},

	{id = "mc_desk08",
	ingreds = {
		{ id = "mc_log_Hickory", count = 8 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Tables",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_desk09",
	ingreds = {
		{ id = "mc_log_Hickory", count = 12 },
		{id = "mc_iron_ingot", count = 3}
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Tables",
	group = "Hickory",
	taskTime = 4
	},

	{id = "mc_desk10",
	ingreds = {
		{ id = "mc_log_Hickory", count = 18 },
		{id = "mc_iron_ingot", count = 8}
		},
	yieldCount = 1,
	difficulty = 75,
	class = "Tables",
	group = "Hickory",
	taskTime = 5
	},

	{id = "mc_desk11",
	ingreds = {
		{ id = "mc_log_parasol", count = 8 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Tables",
	group = "Parasol",
	taskTime = 4
	},

	{id = "mc_displaycase01",
	ingreds = {
		{ id = "mc_log_oak", count = 25 },
		{id = "mc_iron_ingot", count = 2},
		{id = "mc_sand", count = 10}
		},
	yieldCount = 1,
	difficulty = 95,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 4
	},
	
	{id = "mc_table01",
	ingreds = {
		{ id = "mc_log_cypress", count = 3 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Tables",
	group = "Cypress",
	taskTime = 2
	},
	
	{id = "mc_table11",
	ingreds = {
		{ id = "mc_log_scrap", count = 8 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Tables",
	group = "Scrapwood",
	taskTime = 1.5
	},
	
	{id = "mc_table02",
	ingreds = {
		{ id = "mc_log_cypress", count = 4 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Tables",
	group = "Cypress",
	taskTime = 3
	},
	
	{id = "mc_table16",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 8 }
		},
	yieldCount = 1,
	difficulty = 95,
	class = "Tables",
	group = "Swirlwood",
	taskTime = 5
	},
	
	{id = "mc_table08",
	ingreds = {
		{ id = "mc_log_scrap", count = 5 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Tables",
	group = "Scrapwood",
	taskTime = 2.5
	},
	
	{id = "mc_table18",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 4 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Tables",
	group = "Swirlwood",
	taskTime = 3.5
	},
	
	{id = "mc_table04",
	ingreds = {
		{ id = "mc_log_oak", count = 13 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Tables",
	group = "Oak",
	taskTime = 3
	},
	
	{id = "mc_table06",
	ingreds = {
		{ id = "mc_log_oak", count = 6 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Tables",
	group = "Oak",
	taskTime = 3
	},
	
	{id = "mc_table19",
	ingreds = {
		{ id = "mc_log_hickory", count = 4 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Tables",
	group = "Hickory",
	taskTime = 4
	},
	
	{id = "mc_table15",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 7 }
		},
	yieldCount = 1,
	difficulty = 100,
	class = "Tables",
	group = "Swirlwood",
	taskTime = 6
	},
	
	{id = "mc_table03",
	ingreds = {
		{ id = "mc_log_pine", count = 5 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Tables",
	group = "Pine",
	taskTime = 1.5
	},
	
	{id = "mc_table09",
	ingreds = {
		{ id = "mc_log_cypress", count = 6 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Tables",
	group = "Cypress",
	taskTime = 3
	},
	
	{id = "mc_table17",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 6 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Tables",
	group = "Swirlwood",
	taskTime = 5
	},
	
	{id = "mc_table05",
	ingreds = {
		{ id = "mc_log_pine", count = 4 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Tables",
	group = "Pine",
	taskTime = 2
	},
	
	{id = "mc_table14",
	ingreds = {
		{ id = "mc_log_pine", count = 5 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Tables",
	group = "Pine",
	taskTime = 1.5
	},
	
	{id = "mc_table10",
	ingreds = {
		{ id = "mc_log_scrap", count = 4 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 10,
	class = "Tables",
	group = "Scrapwood",
	taskTime = 1
	},
	
	{id = "mc_table07",
	ingreds = {
		{ id = "mc_log_oak", count = 3 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Tables",
	group = "Oak",
	taskTime = 1.5
	},
	
	{id = "mc_table12",
	ingreds = {
		{ id = "mc_log_cypress", count = 6 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Tables",
	group = "Cypress",
	taskTime = 2.5
	},

	{id = "mc_table29",
	ingreds = {
		{ id = "mc_log_hickory", count = 7 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Tables",
	group = "Hickory",
	taskTime = 4
	},

	{id = "mc_table30",
	ingreds = {
		{ id = "mc_log_hickory", count = 8 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Tables",
	group = "Hickory",
	taskTime = 5
	},

	{id = "mc_table31",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Tables",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_table32",
	ingreds = {
		{ id = "mc_log_oak", count = 8 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Tables",
	group = "Oak",
	taskTime = 3
	},

	{id = "mc_table33",
	ingreds = {
		{ id = "mc_log_oak", count = 8 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Tables",
	group = "Oak",
	taskTime = 3
	},

	{id = "mc_table34",
	ingreds = {
		{ id = "mc_log_oak", count = 4 },
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Tables",
	group = "Oak",
	taskTime = 2
	},

	{id = "mc_table35",
	ingreds = {
		{id = "mc_log_hickory", count = 3},
		{id = "ingred_boar_leather", count = 2}
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Tables",
	group = "Hickory",
	taskTime = 3
	},

	{id = "mc_table36",
	ingreds = {
		{id = "mc_log_hickory", count = 4},
		{id = "ingred_boar_leather", count = 3}
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Tables",
	group = "Hickory",
	taskTime = 3.5
	},

	{id = "mc_table37",
	ingreds = {
		{id = "mc_log_hickory", count = 8},
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Tables",
	group = "Hickory",
	taskTime = 2.5
	},

	{id = "mc_table38",
	ingreds = {
		{id = "mc_log_hickory", count = 12},
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Tables",
	group = "Hickory",
	taskTime = 2.5
	},

	{id = "mc_table39",
	ingreds = {
		{id = "mc_log_hickory", count = 20},
		{id = "mc_iron_ingot", count = 2}
		},
	yieldCount = 1,
	difficulty = 70,
	class = "Tables",
	group = "Hickory",
	taskTime = 5
	},

	{id = "mc_table40",
	ingreds = {
		{id = "mc_log_hickory", count = 12},
		{id = "mc_iron_ingot", count = 3}
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Tables",
	group = "Hickory",
	taskTime = 2.5
	},

	{id = "mc_table41",
	ingreds = {
		{id = "mc_log_hickory", count = 3},
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Tables",
	group = "Hickory",
	taskTime = 1.5
	},

	{id = "mc_table42",
	ingreds = {
		{id = "mc_log_hickory", count = 3},
		{id = "mc_iron_ingot", count = 2}
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Tables",
	group = "Hickory",
	taskTime = 1.5
	},

	{id = "mc_table43",
	ingreds = {
		{id = "mc_log_hickory", count = 8}
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Tables",
	group = "Hickory",
	taskTime = 1
	},

	{id = "mc_table44",
	ingreds = {
		{id = "mc_log_cypress", count = 8}
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Tables",
	group = "Cypress",
	taskTime = 1
	},

	{id = "mc_table45",
	ingreds = {
		{id = "mc_log_pine", count = 8}
		},
	yieldCount = 1,
	difficulty = 18,
	class = "Tables",
	group = "Pine",
	taskTime = 1
	},

	{id = "mc_table46",
	ingreds = {
		{id = "mc_log_hickory", count = 4},
		{id = "mc_iron_ingot", count = 2}
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Tables",
	group = "Hickory",
	taskTime = 1.5
	},

	{id = "mc_table47",
	ingreds = {
		{id = "mc_log_hickory", count = 3},
		{id = "mc_iron_ingot", count = 1}
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Tables",
	group = "Hickory",
	taskTime = 1.5
	},

	{id = "mc_table48",
	ingreds = {
		{id = "mc_log_hickory", count = 6},
		{id = "mc_iron_ingot", count = 4}
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Tables",
	group = "Hickory",
	taskTime = 1.5
	},

	{id = "mc_table49",
	ingreds = {
		{ id = "mc_log_scrap", count = 4 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Tables",
	group = "Scrapwood",
	taskTime = 2
	},

	{id = "mc_table50",
	ingreds = {
		{ id = "mc_log_hickory", count = 5 },
		{id = "mc_iron_ingot", count = 4}
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Tables",
	group = "Hickory",
	taskTime = 3
	},
	
	{id = "mc_Cordagewheel",
	ingreds = {
		{ id = "mc_log_ash", count = 3 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Tools",
	group = "Ash",
	taskTime = 3
	},
	
	{id = "mc_kegstand",
	ingreds = {
		{ id = "mc_log_oak", count = 7 },
		{ id = "mc_barrel02", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Tools",
	group = "Oak",
	taskTime = 3
	},
	
	{id = "mc_loom",
	ingreds = {
		{ id = "mc_log_ash", count = 7 },
		{ id = "mc_iron_ingot", count = 4 }
		},
	yieldCount = 1,
	difficulty = 90,
	class = "Tools",
	group = "Ash",
	taskTime = 6
	},

	{id = "mc_loom01",
	ingreds = {
		{ id = "mc_log_parasol", count = 5 },
		{ id = "mc_iron_ingot", count = 2 }
		},
	yieldCount = 1,
	difficulty = 80,
	class = "Tools",
	group = "Parasol",
	taskTime = 4
	},
	
	{id = "mc_pottery_wheel",
	ingreds = {
		{ id = "mc_log_scrap", count = 7 },
		{ id = "mc_iron_ingot", count = 5 },
		{ id = "mc_block00", count = 1}
		},
	yieldCount = 1,
	difficulty = 75,
	class = "Tools",
	group = "Scrapwood",
	taskTime = 5
	},
	
	{id = "mc_spinningwheel",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Tools",
	group = "Scrapwood",
	taskTime = 3
	},

	{id = "mc_spinningwheel2",
	ingreds = {
		{ id = "mc_log_ash", count = 2 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Tools",
	group = "Ash",
	taskTime = 3
	},

	{id = "mc_board_oak01",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	alias = "Finished oak board",
	yieldCount = 1,
	difficulty = 30,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 0.25
	},

	{id = "mc_board_oak02",
	ingreds = {
		{ id = "mc_log_oak", count = 2 }
		},
	alias = "Finished long oak board",
	yieldCount = 1,
	difficulty = 35,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 0.4
	},

	{id = "mc_spool_empty",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 }
		},
	yieldCount = 10,
	difficulty = 1,
	class = "Miscellaneous",
	group = "Scrapwood",
	taskTime = 0.5
	},
	
	{id = "misc_de_lute_01_phat",
	ingreds = {
		{ id = "mc_log_pine", count = 2 },
		{ id = "Thread", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_ladder01",
	ingreds = {
		{ id = "mc_log_hickory", count = 15 }
		},
	yieldCount = 1,
	difficulty = 63,
	class = "Miscellaneous",
	group = "Hickory",
	taskTime = 4
	},

	{id = "mc_ladder02",
	ingreds = {
		{ id = "mc_log_oak", count = 15 }
		},
	yieldCount = 1,
	difficulty = 73,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 4.5
	},
	
	{id = "misc_de_fishing_pole",
	ingreds = {
		{ id = "mc_log_cypress", count = 1 },
		{ id = "Thread", count = 1 }
		},
	yieldCount = 1,
	difficulty = 3,
	class = "Miscellaneous",
	group = "Cypress",
	taskTime = 0.25
	},
	
	{id = "misc_de_drum_02",
	ingreds = {
		{ id = "mc_log_ash", count = 1 },
		{ id = "ingred_guar_hide_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 10,
	class = "Miscellaneous",
	group = "Ash",
	taskTime = 1
	},

	{id = "mc_lightpole01",
	ingreds = {
		{ id = "mc_log_ash", count = 1 }
		},
	yieldCount = 1,
	difficulty = 5,
	class = "Miscellaneous",
	group = "Ash",
	taskTime = 0.25
	},

	{id = "mc_lightpole02",
	ingreds = {
		{ id = "mc_log_ash", count = 4 }
		},
	yieldCount = 1,
	difficulty = 7,
	class = "Miscellaneous",
	group = "Ash",
	taskTime = 0.25
	},

	{id = "mc_statue_bear",
	ingreds = {
		{ id = "mc_log_pine", count = 18 }
		},
	yieldCount = 1,
	difficulty = 56,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 3
	},

	{id = "mc_statue_wolf",
	ingreds = {
		{ id = "mc_log_pine", count = 9 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 2.5
	},

	{id = "mc_mannequin_placeholder_f",
	ingreds = {
		{ id = "mc_log_oak", count = 11 }
		},
	yieldCount = 1,
	difficulty = 110,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 2
	},

	{id = "mc_mannequin_placeholder_m",
	ingreds = {
		{ id = "mc_log_oak", count = 11 }
		},
	yieldCount = 1,
	difficulty = 110,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 2
	},
	
	{id = "misc_de_bellows10",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 },
		{ id = "ingred_guar_hide_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 15,
	class = "Miscellaneous",
	group = "Scrapwood",
	taskTime = 0.5
	},

	{id = "mc_planter07",
	ingreds = {
		{ id = "mc_log_pine", count = 40 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_planter08",
	ingreds = {
		{ id = "mc_log_pine", count = 88 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 3
	},

	{id = "mc_planter09",
	ingreds = {
		{ id = "mc_log_pine", count = 90 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 3
	},

	{id = "mc_planter10",
	ingreds = {
		{ id = "mc_log_pine", count = 57 }
		},
	yieldCount = 1,
	difficulty = 40,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 3
	},

	{id = "mc_planter11",
	ingreds = {
		{ id = "mc_log_pine", count = 36 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 3
	},

	{id = "mc_planter13",
	ingreds = {
		{ id = "mc_log_pine", count = 12 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_planter14",
	ingreds = {
		{ id = "mc_log_pine", count = 16 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_planter17",
	ingreds = {
		{ id = "mc_log_pine", count = 2 },
		{id = "mc_iron_ingot", count = 2}
		},
	yieldCount = 1,
	difficulty = 10,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 1
	},
	
	{id = "misc_de_drum_01",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_prepared_cloth", count = 1 }
		},
	yieldCount = 1,
	difficulty = 20,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 2
	},
	
	{id = "misc_de_muck_shovel_01",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 }
		},
	yieldCount = 1,
	difficulty = 10,
	class = "Miscellaneous",
	group = "Scrapwood",
	taskTime = 0.5
	},

	{id = "mc_platform05",
	ingreds = {
		{ id = "mc_log_pine", count = 75 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 12	
	},

	{id = "mc_platform04",
	ingreds = {
		{ id = "mc_log_oak", count = 75 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 12	
	},
	
	{id = "mc_dummy",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 },
		{ id = "mc_prepared_cloth", count = 3 },
		{ id = "mc_straw", count = 20 }
		},
	yieldCount = 1,
	difficulty = 25,
	class = "Miscellaneous",
	group = "Scrapwood",
	taskTime = 1.5
	},

	{id = "mc_torch_256",
	ingreds = {
		{ id = "mc_log_scrap", count = 1 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 10,
	class = "Miscellaneous",
	group = "Scrapwood",
	taskTime = 0.15
	},
		
	{id = "mc_log_scrap",
	alias = "Convert Ash Log to Scrapwood",
	ingreds = {
		{ id = "mc_log_ash", count = 1 }
		},
	yieldCount = 1,
	difficulty = 0,
	class = "Miscellaneous",
	group = "Ash",
	taskTime = 0
	},
	
	{id = "mc_log_scrap",
	alias = "Convert Cypress Log to Scrapwood",
	ingreds = {
		{ id = "mc_log_cypress", count = 1 }
		},
	yieldCount = 1,
	difficulty = 0,
	class = "Miscellaneous",
	group = "Cypress",
	taskTime = 0
	},
	
	{id = "mc_log_scrap",
	alias = "Convert Hickory Log to Scrapwood",
	ingreds = {
		{ id = "mc_log_hickory", count = 1 }
		},
	yieldCount = 1,
	difficulty = 0,
	class = "Miscellaneous",
	group = "Hickory",
	taskTime = 0
	},
	
	{id = "mc_log_scrap",
	alias = "Convert swirlwood Log to Scrapwood",
	ingreds = {
		{ id = "mc_log_swirlwood", count = 1 }
		},
	yieldCount = 1,
	difficulty = 0,
	class = "Miscellaneous",
	group = "Swirlwood",
	taskTime = 0
	},
	
	{id = "mc_log_scrap",
	alias = "Convert Oak Log to Scrapwood",
	ingreds = {
		{ id = "mc_log_oak", count = 1 }
		},
	yieldCount = 1,
	difficulty = 0,
	class = "Miscellaneous",
	group = "Oak",
	taskTime = 0
	},
	
	{id = "mc_log_scrap",
	alias = "Convert Parasol Log to Scrapwood",
	ingreds = {
		{ id = "mc_log_parasol", count = 1 }
		},
	yieldCount = 1,
	difficulty = 0,
	class = "Miscellaneous",
	group = "Parasol",
	taskTime = 0
	},
	
	{id = "mc_log_scrap",
	alias = "Convert Pine Log to Scrapwood",
	ingreds = {
		{ id = "mc_log_pine", count = 1 }
		},
	yieldCount = 1,
	difficulty = 0,
	class = "Miscellaneous",
	group = "Pine",
	taskTime = 0
	},

	{id = "mc_tent",
	ingreds = {
		{ id = "mc_log_pine", count = 10 },
		{ id = "ingred_guar_hide_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Shelter",
	group = "Pine",
	taskTime = 2
	},

	{id = "mc_awning01",
	ingreds = {
		{ id = "mc_log_ash", count = 6 },
		{ id = "ingred_guar_hide_01", count = 6 },
		{ id = "mc_rope", count = 1 }
		},
	yieldCount = 1,
	difficulty = 28,
	class = "Shelter",
	group = "Ash",
	taskTime = 1.5
	},

	{id = "mc_awning02",
	ingreds = {
		{ id = "mc_log_ash", count = 9 },
		{ id = "ingred_guar_hide_01", count = 10 },
		{ id = "mc_rope", count = 1 }
		},
	yieldCount = 1,
	difficulty = 35,
	class = "Shelter",
	group = "Ash",
	taskTime = 2
	},

	{id = "mc_awning03",
	ingreds = {
		{ id = "mc_log_ash", count = 5 },
		{ id = "ingred_guar_hide_01", count = 5 },
		{ id = "mc_rope", count = 1 }
		},
	yieldCount = 1,
	difficulty = 32,
	class = "Shelter",
	group = "Ash",
	taskTime = 2
	},

	{id = "mc_awning04",
	ingreds = {
		{ id = "mc_log_scrap", count = 6 },
		{ id = "ingred_guar_hide_01", count = 4 },
		{ id = "mc_straw", count = 20 },
		{ id = "mc_rope", count = 1 }
		},
	yieldCount = 1,
	difficulty = 30,
	class = "Shelter",
	group = "Scrap",
	taskTime = 1.5
	},

	{id = "mc_awning05",
	ingreds = {
		{ id = "mc_log_ash", count = 9 },
		{ id = "ingred_guar_hide_01", count = 6 },
		{ id = "mc_rope", count = 1 }
		},
	yieldCount = 1,
	difficulty = 38,
	class = "Shelter",
	group = "Ash",
	taskTime = 2
	},

	{id = "mc_awning06",
	ingreds = {
		{ id = "mc_log_ash", count = 24 },
		{ id = "ingred_guar_hide_01", count = 12 },
		{ id = "mc_rope", count = 2 }
		},
	yieldCount = 1,
	difficulty = 48,
	class = "Shelter",
	group = "Ash",
	taskTime = 2.5
	},

	{id = "mc_awning07",
	ingreds = {
		{ id = "mc_log_ash", count = 28 },
		{ id = "ingred_guar_hide_01", count = 16 },
		{ id = "mc_rope", count = 3 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Shelter",
	group = "Ash",
	taskTime = 3
	},

	{id = "mc_awning08",
	ingreds = {
		{ id = "mc_log_ash", count = 34 },
		{ id = "ingred_guar_hide_01", count = 12 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Shelter",
	group = "Ash",
	taskTime = 5.25
	},

	{id = "mc_awning09",
	ingreds = {
		{ id = "mc_log_ash", count = 20 },
		{ id = "ingred_guar_hide_01", count = 9 },
		{ id = "mc_rope", count = 2 }
		},
	yieldCount = 1,
	difficulty = 65,
	class = "Shelter",
	group = "Ash",
	taskTime = 4
	},

	{id = "mc_awning10",
	ingreds = {
		{ id = "mc_log_scrap", count = 24 },
		{ id = "ingred_guar_hide_01", count = 4 },
		{ id = "mc_straw", count = 14 }
		},
	yieldCount = 1,
	difficulty = 45,
	class = "Shelter",
	group = "Scrap",
	taskTime = 3
	},

	{id = "mc_awning11",
	ingreds = {
		{ id = "mc_log_scrap", count = 28 },
		{ id = "ingred_guar_hide_01", count = 8 },
		{ id = "mc_straw", count = 26 }
		},
	yieldCount = 1,
	difficulty = 55,
	class = "Shelter",
	group = "Scrap",
	taskTime = 4
	},

	{id = "mc_awning12",
	ingreds = {
		{ id = "mc_log_scrap", count = 20 },
		{ id = "ingred_guar_hide_01", count = 4 },
		{ id = "mc_straw", count = 12 }
		},
	yieldCount = 1,
	difficulty = 42,
	class = "Shelter",
	group = "Scrap",
	taskTime = 3
	},

	{id = "mc_drawer01",
	ingreds = {
		{ id = "mc_log_oak", count = 2 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Oak",
	taskTime = 1
	},

    {id = "mc_drawer02",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Oak",
	taskTime = 1
	},

	{id = "mc_drawer03",
	ingreds = {
		{ id = "mc_log_oak", count = 1 },
		{ id = "mc_iron_ingot", count = 1 }
		},
	yieldCount = 1,
	difficulty = 60,
	class = "Containers",
	group = "Oak",
	taskTime = 1
	},

	{id = "mc_fletching_kit",
	ingreds = {
		{ id = "mc_log_oak", count = 2 },
		{ id = "mc_chitin_strips", count = 4 },
		{ id = "mc_chitin_glue", count = 1 },
		{ id = "misc_spool_01", count = 1 }
		},
	yieldCount = 1,
	difficulty = 50,
	class = "Tools",
	group = "Oak",
	taskTime = 2
	},

	{id = "mc_printpress01",
	ingreds = {
		{id = "mc_log_oak", count = 40},
		{id = "mc_chitin_glue", count = 8},
		{id = "ingred_boar_leather", count = 6},
		{id = "mc_iron_ingot", count = 20},
		{id = "mc_metalworking_kit", count = 1, consumed = false}
		},
	yieldCount = 1,
	difficulty = 110,
	class = "Tools",
	group = "Oak",
	taskTime = 22
	}
}

return makerlist
