local defaults = {
	mod = { id = "CraftingFrameworkWeaponExpansion", name = "Crafting Framework - Weapon Expansion Project" },
	weaponExpansionProject = { plugin = "Weapons Expansion Morrowind.esp" },
	logLevel = "INFO",
}
local config = mwse.loadConfig(defaults.mod.name, defaults)

local logging = require("logging.logger")
local logger = logging.new({ name = config.mod.name, logLevel = config.logLevel })
local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then
	logger:error("CraftingFramework not found")
	return
end
local ashfall = include("mer.ashfall.bushcrafting.config")
if not ashfall then
	logger:error("Ashfall bushcrafting config file not found")
	return
end

if not tes3.isModActive(config.weaponExpansionProject.plugin) then
	logger:error("Weapon Expansion Project plugin not active")
	return
end

local recipes = {
	{
		id = "jx_CorkbulbPot",
		craftableId = "jx_CorkbulbPot",
		description = "A pot made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 3 }, { material = "rope", count = 1 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		category = ashfall.categories.cutlery,
		soundType = "carve",
	},
	{
		id = "jx_CorkbulbFlask",
		craftableId = "jx_CorkbulbFlask",
		description = "A flask made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 3 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		category = ashfall.categories.cutlery,
		soundType = "carve",
	},
	{
		id = "jx_CorkbulbBowl",
		craftableId = "jx_CorkbulbBowl",
		description = "A bowl made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 2 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		category = ashfall.categories.cutlery,
		soundType = "carve",
	},
	{
		id = "jx_CorkbulbCup",
		craftableId = "jx_CorkbulbCup",
		description = "A cup made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 1 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		category = ashfall.categories.cutlery,
		soundType = "carve",
	},
	{
		id = "bushcraft:jx_Corkbulb staff",
		craftableId = "jx_Corkbulb staff",
		description = "A staff made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 4 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		category = ashfall.categories.weapons,
		soundType = "carve",
	},
	{
		id = "bushcraft:jx_Corkbulb spear",
		craftableId = "jx_Corkbulb spear",
		description = "A spear made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 4 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		category = ashfall.categories.weapons,
		soundType = "carve",
	},
	{
		id = "bushcraft:jx_Corkbulb dart",
		craftableId = "jx_Corkbulb dart",
		description = "A dart made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 5 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		resultAmount = 5,
		category = ashfall.categories.weapons,
		soundType = "carve",
	},
	{
		id = "bushcraft:corkbulb bolt",
		craftableId = "corkbulb bolt",
		description = "A bolt made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 5 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		resultAmount = 10,
		category = ashfall.categories.weapons,
		soundType = "carve",
	},
	{
		id = "bushcraft:corkbulb arrow",
		craftableId = "corkbulb arrow",
		description = "An arrow made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 5 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		resultAmount = 10,
		category = ashfall.categories.weapons,
		soundType = "carve",
	},
	{
		id = "bushcraft:jx_Corkulb short bow",
		craftableId = "jx_Corkulb short bow",
		description = "A short bow made from corkbulb root.",
		materials = { { material = "ingred_corkbulb_root_01", count = 3 }, { material = "rope", count = 1 } },
		skillRequirements = { ashfall.survivalTiers.novice },
		category = ashfall.categories.weapons,
		soundType = "carve",
	},
}

event.register("Ashfall:EquipChisel:Registered", function(e) e.menuActivator:registerRecipes(recipes) end)

---Register corkbulb as bushcrafting material
---@type CraftingFramework.Material.data
local corkbulbMaterial = {
	id = "corkbulb",
	name = "Corkbulb",
	ids = {
		"ingred_corkbulb_root_01"
	},
}

CraftingFramework.Material:registerMaterials{ corkbulbMaterial }
table.insert(ashfall.materials, corkbulbMaterial)
