--Create List of Recipes
local CraftingFramework = require("CraftingFramework")
if not CraftingFramework then return end

local recipes = {

    -- Cloth

    {
        id = "T_Com_MetalPieceIron_01",
        craftableId = "T_Com_MetalPieceIron_01",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires iron ore to be smelted.",
		materials = {
			{ material = "hap_iron_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

    {
        id = "T_Com_MetalPieceSteel_01",
        craftableId = "T_Com_MetalPieceSteel_01",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires iron and copper ore to be smelted.",
		materials = {
			{ material = "hap_iron_ore", count = 1 },
            { material = "hap_copper_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

    {
        id = "dwemer_ingot",
        craftableId = "hap_dwemer_ingot",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires dwemer metal to be smelted.",
		materials = {
			{ material = "hap_dwemer_ore", count = 1 }
		},
		toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

    {
        id = "orc",
        craftableId = "hap_orch_ingot",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires orichalcum ore to be smelted.",
		materials = {
			{ material = "hap_orc_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

    {
        id = "T_Com_MetalPieceBronze_01",
        craftableId = "T_Com_MetalPieceBronze_01",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires copper and tin to be smelted.",
		materials = {
			{ material = "hap_copper_ore", count = 1 },
            { material = "hap_tin", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

    {
        id = "boiled_leather_n",
        craftableId = "hap_boiled_leather_n",
		category = "Leather",
        soundId = "Repair",
        description = "Requires netch leather to be boiled.",
		materials = {
			{ material = "hap_netch_leather", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

    {
        id = "T_Com_MetalPieceGold_03",
        craftableId = "T_Com_MetalPieceGold_03",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires gold ore to be smelted.",
		materials = {
			{ material = "hap_gold_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

    {
        id = "ebony_ingot",
        craftableId = "hap_ebony_ingot",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires ebony ore to be smelted.",
		materials = {
			{ material = "hap_ebony_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

	{
        id = "T_Com_MetalPieceSilver_03",
        craftableId = "T_Com_MetalPieceSilver_03",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires silver ore to be smelted.",
		materials = {
			{ material = "hap_silver_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

	{
        id = "tempered_glass",
        craftableId = "hap_tempered_glass",
		category = "Glass",
        soundId = "Repair",
        description = "Requires raw glass shards to be smelted.",
		materials = {
			{ material = "hap_glass_raw", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

	{
        id = "adamantium_ingot",
        craftableId = "hap_adamantium_ingot",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires adamantium ore to be smelted.",
		materials = {
			{ material = "hap_adamantium_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

	{
        id = "copper_ingot",
        craftableId = "hap_copper_ingot",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires copper ore to be smelted.",
		materials = {
			{ material = "hap_copper_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

	{
        id = "mithril_ingot",
        craftableId = "hap_mithril_ingot",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires silver and iron ore to be smelted.",
		materials = {
			{ material = "hap_silver_ore", count = 1 },
			{ material = "hap_iron_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},

	{
        id = "daedra_ingot",
        craftableId = "hap_daedric_ingot",
		category = "Ingot",
        soundId = "Repair",
        description = "Requires ebony ore and daedra essence to be smelted.",
		materials = {
			{ material = "hap_essence", count = 1 },
			{ material = "hap_ebony_ore", count = 1 }
		},
        toolRequirements = {
			{ tool = "prongs", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end
	},
}

return recipes