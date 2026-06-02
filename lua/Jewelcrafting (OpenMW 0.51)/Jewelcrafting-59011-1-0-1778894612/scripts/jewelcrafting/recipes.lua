-- fields already applied:
-- r.qualityFunc = "jc_quality"
-- r.craftingEvent = "Jewelcrafting_craftItem"
-- r.hidden = "discovery"
-- r.profession = "Jewelcrafting"
-- r.skill = "jewelcrafting"
-- r.types = "Clothing"
-- r.tools = {
-- 	{ id = "jc_jewelpliers" },
-- }

local list = {
	-- =====================================================================
	-- COMMON RINGS
	-- =====================================================================
	{
		id = "common_ring_05",
		nameOpt = "Common Engraved Ring", -- known by default
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 2,
		ingredients = {
			{ id = "t_ingmine_oreiron_01", count = 1 },
		},
		craftingTime = 4,
		hidden = false,
		disabled = nil,
	},
	{
		id = "common_ring_01",
		nameOpt = "Common Slate Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 5,
		ingredients = {
			{ id = "t_ingmine_oreiron_01", count = 1 },
			{ id = "t_ingmine_coal_01", count = 1 },
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_Bre_Cm_Ring_03",
		nameOpt = "Common Turtle Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 5,
		ingredients = {
			{ id = "t_ingmine_oreiron_01", count = 1 },
			{ id = "ingred_scrap_metal_01", count = 1 },
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_He_Cm_Ring_05",
		nameOpt = "Common Smokey Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 5,
		ingredients = {
			{ id = "t_ingmine_oreiron_01", count = 1 },
			{ id = "Agate or Quartz", count = 1 }, -- wildcard Agate or Quartz
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_Imp_Cm_RingCol_01",
		nameOpt = "Common Studded Silver Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 5,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_Imp_Cm_RingNib_03",
		nameOpt = "Common Floret Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 5,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "Topaz or Jade", count = 1 }, -- wildcards Topaz or Jade
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_He_Cm_Ring_02",
		nameOpt = "Common Grand Gold Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 10,
		ingredients = {
			{ id = "Agate", count = 1 },
			{ id = "t_ingmine_oregold_01", count = 1 },
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_Imp_Cm_RingNib_05b",
		nameOpt = "Common Gilded Snake Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "ingred_pearl_01", count = 1 },
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_He_Cm_Ring_01",
		nameOpt = "Common Moonlit Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_moonstone_01", count = 1 }, -- wildcard Opal/khajiit eye
			{ id = "t_ingmine_oresilver_01", count = 1 },
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_He_Cm_Ring_03",
		nameOpt = "Common Tempered Pearl Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_oreiron_01", count = 1 },
			{ id = "ingred_pearl_01", count = 1 },
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_Imp_Cm_RingNib_01",
		nameOpt = "Common Engraved Silver Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_We_Cm_Ring_01",
		nameOpt = "Common Enchanter's Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "misc_soulgem_lesser", count = 1 },
		},
		craftingTime = 5,
		disabled = "jc_rs_com_ring",
	},
	{
		id = "T_Rga_Cm_Ring_03",
		nameOpt = "Common Winding Serpent Ring",
		userData = { tier = "com", kind = "ring" },
		craftingCategory = "Common Rings",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 2 },
		},
		craftingTime = 4,
		disabled = "jc_rs_com_ring",
	},

	-- =====================================================================
	-- COMMON AMULETS
	-- =====================================================================
	{
		id = "T_Nor_Cm_Amulet_01",
		nameOpt = "Common Nordic Amulet",
		userData = { tier = "com", kind = "necklace" },
		craftingCategory = "Common Amulets",
		level = 5,
		ingredients = {
			{ id = "t_ingmine_oreiron_01", count = 1 },
			{ id = "ingred_racer_plumes_01", count = 1 },
		},
		craftingTime = 5,
		disabled = "jc_rs_com_necklace",
	},
	{
		id = "T_Yne_Cm_Amulet_01",
		nameOpt = "Common Tribal Amulet",
		userData = { tier = "com", kind = "necklace" },
		craftingCategory = "Common Amulets",
		level = 5,
		ingredients = {
			{ id = "t_ingmine_oreiron_01", count = 1 },
			{ id = "ingred_racer_plumes_01", count = 4 },
		},
		craftingTime = 5,
		disabled = "jc_rs_com_necklace",
	},
	{
		id = "T_Imp_Cm_AmuletNib_02",
		nameOpt = "Common Gold Sapphire Amulet",
		userData = { tier = "com", kind = "necklace" },
		craftingCategory = "Common Amulets",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "Sapphire", count = 1 }, -- Wildcard Sapphire
		},
		craftingTime = 5,
		disabled = "jc_rs_com_necklace",
	},
	{
		id = "T_Imp_Cm_AmuletNib_03a",
		nameOpt = "Common Lunar Gloom Amulet",
		userData = { tier = "com", kind = "necklace" },
		craftingCategory = "Common Amulets",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "t_ingmine_moonstone_01", count = 1 },
		},
		craftingTime = 5,
		disabled = "jc_rs_com_necklace",
	},
	{
		id = "T_Imp_Cm_AmuletNib_03d",
		nameOpt = "Common Nostalgic Amulet",
		userData = { tier = "com", kind = "necklace" },
		craftingCategory = "Common Amulets",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "Opal or Agate", count = 1 }, -- Wildcard Opal or Agate
		},
		craftingTime = 5,
		disabled = "jc_rs_com_necklace",
	},
	{
		id = "T_Nor_Cm_Amulet_02",
		nameOpt = "Common Nordic Wayseer Amulet",
		userData = { tier = "com", kind = "necklace" },
		craftingCategory = "Common Amulets",
		level = 10,
		ingredients = {
			{ id = "Quartz", count = 1 }, -- wildcard Quartz
			{ id = "t_ingmine_oresilver_01", count = 1 },
		},
		craftingTime = 5,
		disabled = "jc_rs_com_necklace",
	},
	{
		id = "T_Imp_Cm_AmuletNib_03b",
		nameOpt = "Common Imperial Amulet",
		userData = { tier = "com", kind = "necklace" },
		craftingCategory = "Common Amulets",
		level = 10,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "ingred_racer_plumes_01", count = 1 },
		},
		craftingTime = 5,
	},
	{
		id = "T_Imp_Cm_AmuletNib_04",
		nameOpt = "Alchemical Amulet",
		userData = { tier = "com", kind = "necklace" },
		craftingCategory = "Common Amulets",
		level = 15,
		ingredients = {
			{ id = "t_ingmine_oreiron_01", count = 4 },
			{ id = "t_ingmine_oresilver_01", count = 2 },
			{ id = "t_ingmine_oregold_01", count = 1 },
		},
		craftingTime = 7,
		disabled = "jc_rs_com_necklace",
	},

	-- =====================================================================
	-- EXPENSIVE RINGS
	-- =====================================================================
	{
		id = "T_Imp_Ep_RingCol_01a",
		nameOpt = "Expensive Colovian Ruby Ring",
		userData = { tier = "exp", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 15,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "ingred_ruby_01", count = 1 },
		},
		craftingTime = 6,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "T_Bre_Ep_Ring_01",
		nameOpt = "Expensive Dusky Jade Ring",
		userData = { tier = "exp", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 15,
		ingredients = {
			{ id = "t_ingmine_coal_01", count = 1 },
			{ id = "ingred_emerald_01", count = 1 },
		},
		craftingTime = 6,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "T_Bre_Ep_Ring_02",
		nameOpt = "Expensive Gold Amethyst Ring",
		userData = { tier = "exp", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 15,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "Amethyst", count = 1 }, -- wildcard Amethyst
		},
		craftingTime = 6,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "expensive_ring_02",
		nameOpt = "Silver Expensive Ring",
		userData = { tier = "exp", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 15,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "t_ingmine_onyx_01", count = 1 },
		},
		craftingTime = 6,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "T_Nor_Ep_Ring_02",
		nameOpt = "Expensive Nordic Signant Ring",
		userData = { tier = "exp", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 15,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "t_ingmine_oreiron_01", count = 1 },
		},
		craftingTime = 6,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "T_He_Ep_Ring_03b",
		nameOpt = "Expensive Ebony Sunrise Ring",
		userData = { tier = "exp", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 25,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "Amethyst", count = 1 }, -- wildcard Amethyst
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "T_He_Ep_Ring_03a",
		nameOpt = "Expensive Dwemer Ebony Ring",
		userData = { tier = "exp", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 25,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "ingred_scrap_metal_01", count = 1 },
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "T_Nor_Ep_Ring_03",
		nameOpt = "Expensive Engraved Nordic Ring",
		userData = { tier = "exp", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 30,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "t_ingmine_oreiron_01", count = 1 },
			{ id = "Agate", count = 1 }, -- wildcard Agate
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "T_Rga_Ep_Ring_01",
		nameOpt = "Expensive Grand Silver Ring",
		userData = { tier = "exp", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 30,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 2 },
			{ id = "Any Diamond", count = 1 }, -- wildcard Diamond
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "T_He_Ep_Ring_01",
		nameOpt = "Expensive Gilded Ebony Ring",
		userData = { tier = "ext", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 35,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "Any Diamond", count = 1 }, -- wildcard Any Diamond
		},
		craftingTime = 8,
		disabled = "jc_rs_exp_ring",
	},
	{
		id = "T_Imp_Ep_RingCol_01b",
		nameOpt = "Expensive Colovian Diamond Ring",
		userData = { tier = "ext", kind = "ring" },
		craftingCategory = "Expensive Rings",
		level = 35,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "Any Diamond", count = 1 }, -- wildcard Any Diamond
		},
		craftingTime = 8,
		disabled = "jc_rs_exp_ring",
	},	

	-- =====================================================================
	-- EXPENSIVE AMULETS
	-- =====================================================================
	{
		id = "T_Nor_Ep_Amulet_03",
		nameOpt = "Expensive Nordic Rune Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 15,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "t_ingmine_oresilver_01", count = 1 },
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_QyC_Ep_Amulet_01",
		nameOpt = "Expensive Tribal Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 15,
		ingredients = {
			{ id = "t_ingmine_oreiron_01", count = 1 },
			{ id = "ingred_racer_plumes_01", count = 4 },
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_Yne_Ep_Amulet_02",
		nameOpt = "Expensive Tribal Bone Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 20,
		ingredients = {
			{ id = "ingred_bonemeal_01", count = 2 },
			{ id = "ingred_racer_plumes_01", count = 1 },
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_He_Ep_Amulet_01",
		nameOpt = "Expensive Bejewelled Butterfly Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 20,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 2 },
			{ id = "ingred_emerald_01", count = 1 },
			{ id = "Garnet", count = 1 }, -- wildcard Garnet
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_We_Ep_Amulet_03",
		nameOpt = "Expensive Skeletal Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 20,
		ingredients = {
			{ id = "ingred_racer_plumes_01", count = 2 },
			{ id = "ingred_bonemeal_01", count = 2 },
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_Nor_Ep_Amulet_01",
		nameOpt = "Expensive Nordic Knot Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 20,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 2 },
			{ id = "t_ingmine_oreiron_01", count = 1 },
			{ id = "ingred_racer_plumes_01", count = 1 },
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_He_Ep_Amulet_02",
		nameOpt = "Expensive Azure Mosaic Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 20,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 2 },
			{ id = "Sapphire", count = 1 }, -- wildcard
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_Nor_Ep_Amulet_02",
		nameOpt = "Expensive Engraved Nautical Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 20,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "ingred_racer_plumes_01", count = 1 },
			{ id = "Topaz", count = 1 }, -- wildcard Topaz
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_QyK_Ep_Amulet_01",
		nameOpt = "Expensive Silver Agate Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 20,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 2 },
			{ id = "t_ingmine_agate_03", count = 1 },
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_We_Ep_Amulet_01",
		nameOpt = "Expensive Bone Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 20,
		ingredients = {
			{ id = "ingred_racer_plumes_01", count = 4 },
			{ id = "ingred_bonemeal_01", count = 2 },
		},
		craftingTime = 7,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_Imp_Ep_AmuletNib_04",
		nameOpt = "Expensive Gilded Raindrop Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 30,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 2 },
			{ id = "ingred_ruby_01", count = 1 },
		},
		craftingTime = 8,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_Yne_Ep_Amulet_01",
		nameOpt = "Expensive Grand Ebony Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 30,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 2 },
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "Any Diamond", count = 1 }, -- wildcard Any Diamond
		},
		craftingTime = 8,
		disabled = "jc_rs_exp_necklace",
	},
	{
		id = "T_Imp_Ep_AmuletNib_01",
		nameOpt = "Expensive Azure Minotaur Amulet",
		userData = { tier = "exp", kind = "necklace" },
		craftingCategory = "Expensive Amulets",
		level = 35,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "adamantium ore", count = 1 },
			{ id = "t_ingmine_lapislazuli_01", count = 1 },
			{ id = "racer plumes", count = 1 },
		},
		craftingTime = 9,
		disabled = "jc_rs_exp_necklace",
	},	

	-- =====================================================================
	-- EXTRAVAGANT RINGS
	-- =====================================================================
	{
		id = "extravagant_ring_01",
		nameOpt = "Extravagant Amethyst Ring",
		userData = { tier = "ext", kind = "ring" },
		craftingCategory = "Extravagant Rings",
		level = 35,
		ingredients = {
			{ id = "Amethyst", count = 1 }, -- wildcard Amethyst
			{ id = "t_ingmine_oresilver_01", count = 1 },
		},
		craftingTime = 8,
		disabled = "jc_rs_ext_ring",
	},
	{
		id = "T_Bre_Et_Ring_02",
		nameOpt = "Extravagant Studded Sapphire Ring",
		userData = { tier = "ext", kind = "ring" },
		craftingCategory = "Extravagant Rings",
		level = 35,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "Sapphire", count = 1 }, -- wildcard Sapphire
		},
		craftingTime = 8,
		disabled = "jc_rs_ext_ring",
	},
	{
		id = "T_He_Et_Ring_01",
		nameOpt = "Extravagant Midnight Ebony Ring",
		userData = { tier = "ext", kind = "ring" },
		craftingCategory = "Extravagant Rings",
		level = 35,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "t_ingmine_agate_03", count = 1 },
		},
		craftingTime = 8,
		disabled = "jc_rs_ext_ring",
	},
	{
		id = "T_He_Et_Ring_02",
		nameOpt = "Extravagant Tribunal Ebony Ring",
		userData = { tier = "ext", kind = "ring" },
		craftingCategory = "Extravagant Rings",
		level = 35,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "ingred_pearl_01", count = 1 },
		},
		craftingTime = 8,
		disabled = "jc_rs_ext_ring",
	},
	{
		id = "T_Bre_Et_Ring_01",
		nameOpt = "Extravagant Grand Ring",
		userData = { tier = "ext", kind = "ring" },
		craftingCategory = "Extravagant Rings",
		level = 35,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 2 },
			{ id = "ingred_ruby_01", count = 1 },
		},
		craftingTime = 8,
		disabled = "jc_rs_ext_ring",
	},
	{
		id = "T_Rga_Et_Ring_01",
		nameOpt = "Extravagant Foyada Ring",
		userData = { tier = "ext", kind = "ring" },
		craftingCategory = "Extravagant Rings",
		level = 40,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "t_ingmine_bloodstone_01", count = 1 },
		},
		craftingTime = 9,
		disabled = "jc_rs_ext_ring",
	},
	{
		id = "T_Rga_Et_Ring_02",
		nameOpt = "Extravagant Elegant Sapphire Ring",
		userData = { tier = "ext", kind = "ring" },
		craftingCategory = "Extravagant Rings",
		level = 40,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "t_ingmine_oresilver_01", count = 1 },
			{ id = "Sapphire", count = 1 }, -- wildcard Sapphire
		},
		craftingTime = 9,
		disabled = "jc_rs_ext_ring",
	},
	-- =====================================================================
	-- EXTRAVAGANT AMULETS
	-- =====================================================================
	{
		id = "T_QyC_Et_Amulet_01",
		nameOpt = "Extravagant Grand Pearl Amulet",
		userData = { tier = "ext", kind = "necklace" },
		craftingCategory = "Extravagant Amulets",
		level = 35,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "ingred_pearl_01", count = 1 },
			{ id = "ingred_racer_plumes_01", count = 1 },
		},
		craftingTime = 9,
		disabled = "jc_rs_ext_necklace",
	},
	{
		id = "T_Nor_Et_Amulet_02",
		nameOpt = "Extravagant Nordic Knot Amulet",
		userData = { tier = "ext", kind = "necklace" },
		craftingCategory = "Extravagant Amulets",
		level = 35,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 2 },
			{ id = "Sapphire", count = 1 }, -- wildcard Sapphire
			{ id = "ingred_racer_plumes_01", count = 1 },
		},
		craftingTime = 9,
		disabled = "jc_rs_ext_necklace",
	},
	{
		id = "T_Imp_Et_AmuletNib_02",
		nameOpt = "Extravagant Carved Agate Amulet",
		userData = { tier = "ext", kind = "necklace" },
		craftingCategory = "Extravagant Amulets",
		level = 35,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 2 },
			{ id = "t_ingmine_agate_03", count = 1 },
			{ id = "ingred_racer_plumes_01", count = 1 },
		},
		craftingTime = 9,
		disabled = "jc_rs_ext_necklace",
	},
	{
		id = "T_Nor_Et_Amulet_01",
		nameOpt = "Extravagant Astral Wizard Amulet",
		userData = { tier = "ext", kind = "necklace" },
		craftingCategory = "Extravagant Amulets",
		level = 35,
		ingredients = {
			{ id = "t_ingmine_oresilver_01", count = 2 },
			{ id = "Sapphire", count = 1 }, -- wildcard Sapphire
			{ id = "ingred_racer_plumes_01", count = 1 },
		},
		craftingTime = 9,
		disabled = "jc_rs_ext_necklace",
	},

	-- =====================================================================
	-- EXQUISITE
	-- =====================================================================
	{
		id = "exquisite_ring_01",
		nameOpt = "Silver and Black Exquisite Ring",
		userData = { tier = "exq", kind = "ring" },
		craftingCategory = "Exquisite",
		level = 45,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 3 },
			{ id = "ingred_adamantium_ore_01", count = 1 },
		},
		craftingTime = 12,
--		disabled = "jc_rs_exquisite_ring_01",
	},
	{
		id = "exquisite_amulet_01",
		nameOpt = "Jeweled Exquisite Amulet",
		userData = { tier = "exq", kind = "necklace" },
		craftingCategory = "Exquisite",
		level = 45,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 1 },
			{ id = "ingred_ruby_01", count = 2 },
			{ id = "ingred_emerald_01", count = 1 },
		},
		craftingTime = 12,
--		disabled = "jc_rs_exquisite_amulet_01",
	},
	{
		id = "T_Imp_Ex_Amulet_01",
		nameOpt = "Exquisite Amulet of the Red Diamond",
		userData = { tier = "exq", kind = "necklace" },
		craftingCategory = "Exquisite",
		level = 50,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "ingred_ruby_01", count = 1 },
			{ id = "Red Diamond", count = 1 }, -- wildcard Red Diamond
		},
		craftingTime = 14,
		disabled = "journal:PC_m1_K1_HT5>=100|journal:PC_m1_K1_MC6>=100",
	},
	{
		id = "T_Rga_Eq_Ring_01",
		nameOpt = "Exquisite Ring of Arcane Elegance",
		userData = { tier = "exq", kind = "ring" },
		craftingCategory = "Exquisite",
		level = 50,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "ingred_emerald_01", count = 1 },
			{ id = "ingred_raw_glass_01", count = 1 },
			{ id = "Sapphire", count = 1 }, -- wildcard Sapphire
		},
		craftingTime = 14,
		disabled = "journal:HT_Archmagister>=100|journal:HT_WizardSpells>=100&skill:jewelcrafting>=60|journal:HT_Monopoly>=100&skill:jewelcrafting>=60",
	},
	{
		id = "T_He_Ex_Ring_01",
		nameOpt = "Exquisite Ring of Numidium's Legacy",
		userData = { tier = "exq", kind = "ring" },
		craftingCategory = "Exquisite",
		level = 50,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "Any Diamond", count = 2 }, -- Any Diamond
			{ id = "t_ingmine_onyx_01", count = 1 },
		},
		craftingTime = 14,
		disabled = "read:bk_Dagoth_Urs_Plans|read:bk_kagrenac'sjournal_excl",
	},
	{
		id = "T_Imp_Ex_AmuletNib_01",
		nameOpt = "Exquisite Ornate Ayem Amulet",
		userData = { tier = "exq", kind = "necklace" },
		craftingCategory = "Exquisite",
		level = 50,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 1 },
			{ id = "ingred_raw_glass_01", count = 1 },
			{ id = "ingred_daedras_heart_01", count = 1 },
			{ id = "t_ingmine_moonstone_01", count = 1 },
		},
		craftingTime = 14,
		disabled = "journal:TR_MazedBand>=100|journal:TR_m2_TT_1a>=10&skill:jewelcrafting>=60",
	},
	{
		id = "T_QyC_Ex_Amulet_01",
		nameOpt = "Exquisite Amulet of Vehk's Kiss",
		userData = { tier = "exq", kind = "necklace" },
		craftingCategory = "Exquisite",
		level = 50,
		ingredients = {
			{ id = "ingred_raw_ebony_01", count = 2 },
			{ id = "ingred_adamantium_ore_01", count = 1 },
			{ id = "ingred_daedras_heart_01", count = 1 },
			{ id = "t_ingmine_aquamarine_01", count = 1 },
		},
		craftingTime = 14,
		disabled = "journal:B8_MeetVivec>=50|TR_m7_Ns_TT_Chavana3>=100|journal:TR_m4_TT_ShrineBodrum>=10&skill:jewelcrafting>=60|journal:TR_m7_TT_PedestalMuatra>=10&skill:jewelcrafting>=60",
	}, 
	{
		id = "T_Imp_Ex_RingNib_01",
		nameOpt = "Exquisite Imperial Jeweled Ring",
		userData = { tier = "exq", kind = "ring" },
		craftingCategory = "Exquisite",
		level = 50,
		ingredients = {
			{ id = "t_ingmine_oregold_01", count = 2 },
			{ id = "ingred_emerald_01", count = 1 },
			{ id = "ingred_ruby_01", count = 1 },
			{ id = "Topaz", count = 1 }, -- wildcard
		},
		craftingTime = 14,
		disabled = "journal:IL_Grandmaster>=100|journal:IC30_Imperial_veteran>=1",
		-- Imperial legion, imperial cult
	},
}

for _, r in ipairs(list) do
	r.qualityFunc = "jc_quality"
	r.craftingSound = "forging"
	r.xpFunc = "jc_xp"
	r.statsFunc = "jc_stats"
	r.craftingEvent = "Jewelcrafting_craftItem"
	if r.hidden == nil then
		r.hidden = "discovery"
	end
	if r.profession == nil then
		r.profession = "Jewelcrafting"
	end
	if r.skill == nil then
		r.skill = "jewelcrafting"
	end
	if r.types == nil then
		r.types = "Clothing"
	end
	if r.tools == nil then
		r.tools = {
			{ id = "jc_jewelpliers" },
		}
	end
end

return list