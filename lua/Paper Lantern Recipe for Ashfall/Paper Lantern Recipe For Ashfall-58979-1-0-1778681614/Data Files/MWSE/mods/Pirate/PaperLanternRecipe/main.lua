local i18n = mwse.loadTranslations("Pirate.PaperLanternRecipe")
local CraftingFramework = include("CraftingFramework")
local ashfall = include("mer.ashfall.interop")
local DyedPaper = require("Pirate.PaperLanternRecipe.DyedPaper")

local tamrielData = function()
					return tes3.isModActive("Tamriel_Data.esm")
					end
local jop = function()
			return tes3.isModActive("TheJoyOfPainting.esp")
			end
--materials
local materials = {
	{
	id = "candle",
	name = i18n("material.candle"),
	ids = {
		"mer_lntrn_candle",
		"light_de_candle_03",
		"light_de_candle_10",
		"light_de_candle_11",
		"light_de_candle_12",
		"light_de_candle_13",
		"light_de_candle_14",
		"Light_De_Candle_20",
		"Light_De_Candle_21",
		"Light_De_Candle_22",
		"light_de_candle_12_64",
		"light_de_candle_03_64",
		"light_de_candle_14_64",
		"light_de_candle_10_64",
		"light_de_candle_11_64",
		"light_de_candle_13_64",
		--"",
		--"",
		}
	},
	{
	id = "paper_blue",
	name = i18n("material.PaperBlue"),
	ids = {
		"T_Com_Paper_Blue_01",
		}
	},
	{
	id = "paper_green",
	name = i18n("material.PaperGreen"),
	ids = {
		"T_Com_Paper_Green_01",
		}
	},
	{
	id = "paper_purple",
	name = i18n("material.PaperPurple"),
	ids = {
		"T_Com_Paper_Purple_01",
		}
	},
	{
	id = "paper_red",
	name = i18n("material.PaperRed"),
	ids = {
		"T_Com_Paper_Red_01",
		}
	},
}
CraftingFramework.Material:registerMaterials(materials)

local workbenchRecipes = {
    --materialRecipes
    {
        id = "bushcraft:T_Com_Paper_Blue_01",
        craftableId = "T_Com_Paper_Blue_01",
        description = i18n("Recipes.PaperBlue.Desc"),
        name = i18n("material.PaperBlue"),
        materials = {
            { material = "paper", count = 1 }
        },
		skillRequirements = {
			{
				skill = "painting",
				requirement = 10,
				maxProgress = 10,
			},
		},
        category = i18n("category.materials"),
        soundType = "rope",
        knowledgeRequirement = jop,
        timeTaken = 10 / 60,
        customRequirements = DyedPaper.customRequirements,
        craftCallback = DyedPaper.craftCallback,
    },
    {
        id = "bushcraft:T_Com_Paper_Green_01",
        craftableId = "T_Com_Paper_Green_01",
        description = i18n("Recipes.PaperGreen.Desc"),
        name = i18n("material.PaperGreen"),
        materials = {
            { material = "paper", count = 1 }
        },
		skillRequirements = {
			{
				skill = "painting",
				requirement = 10,
				maxProgress = 10,
			},
		},
        category = i18n("category.materials"),
        soundType = "rope",
        knowledgeRequirement = jop,
        timeTaken = 10 / 60,
        customRequirements = DyedPaper.customRequirements,
        craftCallback = DyedPaper.craftCallback,
    },
    {
        id = "bushcraft:T_Com_Paper_Purple_01",
        craftableId = "T_Com_Paper_Purple_01",
        description = i18n("Recipes.PaperPurple.Desc"),
        name = i18n("material.PaperPurple"),
        materials = {
            { material = "paper", count = 1 }
        },
		skillRequirements = {
			{
				skill = "painting",
				requirement = 10,
				maxProgress = 10,
			},
		},
        category = i18n("category.materials"),
        soundType = "rope",
        knowledgeRequirement = jop,
        timeTaken = 10 / 60,
        customRequirements = DyedPaper.customRequirements,
        craftCallback = DyedPaper.craftCallback,
    },
    {
        id = "bushcraft:T_Com_Paper_Red_01",
        craftableId = "T_Com_Paper_Red_01",
        description = i18n("Recipes.PaperRed.Desc"),
        name = i18n("material.PaperRed"),
        materials = {
            { material = "paper", count = 1 }
        },
		skillRequirements = {
			{
				skill = "painting",
				requirement = 10,
				maxProgress = 10,
			},
		},
        category = i18n("category.materials"),
        soundType = "rope",
        knowledgeRequirement = jop,
        timeTaken = 10 / 60,
        customRequirements = DyedPaper.customRequirements,
        craftCallback = DyedPaper.craftCallback,
    },
    --recipes
	{
		id = "bushcraft:light_de_lantern_05",
		craftableId = "light_de_lantern_05",
		description = i18n("Recipe.PaperLantern.Desc"),
		materials = {
			{ material = "wood", count = 2 },
			{ material = "paper", count = 4 },
			{ material = "resin", count = 1 },
			{ material = "candle", count = 1 },
		},
		skillRequirements = {
			{
				skill = "Bushcrafting",
				requirement = 40,
				maxProgress = 30,
			},
		},
		toolRequirements = {
			{
				tool = "chisel",
				conditionPerUse = 30,
			},
			{
				tool = "knife",
				conditionPerUse = 10,
			},
		},
		category = i18n("category.light"),
		soundType = "wood",
		customRequirements = {ashfall.bushcrafting.customRequirements.workbenchNearby},
        timeTaken = 30 / 60,
	},
	{
		id = "bushcraft:light_de_lantern_14",
		craftableId = "light_de_lantern_14",
		description = i18n("Recipe.PaperLanternRed.Desc"),
		name = i18n("Recipe.PaperLanternRed.Name"),
		materials = {
			{ material = "wood", count = 2 },
			{ material = "paper_red", count = 4 },
			{ material = "resin", count = 1 },
			{ material = "candle", count = 1 },
		},
		skillRequirements = {
			{
				skill = "Bushcrafting",
				requirement = 40,
				maxProgress = 30,
			},
		},
		toolRequirements = {
			{
				tool = "chisel",
				conditionPerUse = 30,
			},
			{
				tool = "knife",
				conditionPerUse = 10,
			},
		},
		category = i18n("category.light"),
		soundType = "wood",
		customRequirements = {ashfall.bushcrafting.customRequirements.workbenchNearby},
		knowledgeRequirement = tamrielData,
        timeTaken = 30 / 60,
	},
	{
		id = "bushcraft:T_De_Var_LanternPurple04_256",
		craftableId = "T_De_Var_LanternPurple04_256",
		description = i18n("Recipe.PaperLanternPurple.Desc"),
		name = i18n("Recipe.PaperLanternPurple.Name"),
		materials = {
			{ material = "wood", count = 2 },
			{ material = "paper_purple", count = 4 },
			{ material = "resin", count = 1 },
			{ material = "candle", count = 1 },
		},
		skillRequirements = {
			{
				skill = "Bushcrafting",
				requirement = 40,
				maxProgress = 30,
			},
		},
		toolRequirements = {
			{
				tool = "chisel",
				conditionPerUse = 30,
			},
			{
				tool = "knife",
				conditionPerUse = 10,
			},
		},
		category = i18n("category.light"),
		soundType = "wood",
		customRequirements = {ashfall.bushcrafting.customRequirements.workbenchNearby},
		knowledgeRequirement = tamrielData,
        timeTaken = 30 / 60,
	},
	{
		id = "bushcraft:light_de_lantern_10",
		craftableId = "light_de_lantern_10",
		description = i18n("Recipe.PaperLanternBlue.Desc"),
		name = i18n("Recipe.PaperLanternBlue.Name"),
		materials = {
			{ material = "wood", count = 2 },
			{ material = "paper_blue", count = 4 },
			{ material = "resin", count = 1 },
			{ material = "candle", count = 1 },
		},
		skillRequirements = {
			{
				skill = "Bushcrafting",
				requirement = 40,
				maxProgress = 30,
			},
		},
		toolRequirements = {
			{
				tool = "chisel",
				conditionPerUse = 30,
			},
			{
				tool = "knife",
				conditionPerUse = 10,
			},
		},
		category = i18n("category.light"),
		soundType = "wood",
		customRequirements = {ashfall.bushcrafting.customRequirements.workbenchNearby},
		knowledgeRequirement = tamrielData,
		timeTaken = 30 / 60 ,
	},
	{
		id = "bushcraft:T_De_Var_LanternGreen04_256",
		craftableId = "T_De_Var_LanternGreen04_256",
		description = i18n("Recipe.PaperLanternGreen.Desc"),
		name = i18n("Recipe.PaperLanternGreen.Name"),
		materials = {
			{ material = "wood", count = 2 },
			{ material = "paper_green", count = 4 },
			{ material = "resin", count = 1 },
			{ material = "candle", count = 1 },
		},
		skillRequirements = {
			{
				skill = "Bushcrafting",
				requirement = 40,
				maxProgress = 30,
			},
		},
		toolRequirements = {
			{
				tool = "chisel",
				conditionPerUse = 30,
			},
			{
				tool = "knife",
				conditionPerUse = 10,
			},
		},
		category = i18n("category.light"),
		soundType = "wood",
		customRequirements = {ashfall.bushcrafting.customRequirements.workbenchNearby},
		knowledgeRequirement = tamrielData,
		timeTaken = 30 / 60 ,
	},
}

local function registerAshfallRecipes(e)
	---@type CraftingFramework.MenuActivator
	local workbenchActivator = e.menuActivator
	if workbenchActivator then
		for _, recipe in ipairs(workbenchRecipes) do
			workbenchActivator:registerRecipe(recipe)
		end
	end
end
event.register("Ashfall:ActivateWorkbench:Registered", registerAshfallRecipes)
event.register("Ashfall:ActivateBushcrafting:Registered", registerAshfallRecipes)
event.register("Ashfall:EquipChisel:Registered", registerAshfallRecipes)
