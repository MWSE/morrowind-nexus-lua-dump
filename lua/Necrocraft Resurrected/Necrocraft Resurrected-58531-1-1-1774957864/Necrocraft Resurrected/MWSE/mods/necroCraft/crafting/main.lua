local crafting = include("craftingFramework.interop")
local materials = require("necroCraft.crafting.materials")
local recipes = require("necroCraft.crafting.recipes")

if crafting then

	crafting.registerMaterials(materials)
	crafting.registerRecipes(recipes)


	local bonepilesCrafting = crafting.registerMenuActivator{
		id = "Necrocraft:BonepilesCreation",
		name = "Corpse Preparation",
		type = "event",
		recipes = recipes.bonepiles,
		defaultFilter = "all",
        defaultSort = "skill",
	}

	local corpsesCrafting = crafting.registerMenuActivator{
		id = "Necrocraft:CorpsePreparation",
		name = "Corpse Preparation",
		type = "event",
		recipes = recipes.corpses,
		defaultFilter = "all",
        defaultSort = "skill",
	}
end
