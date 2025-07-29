local recipes = {

	-- Armor

	{
        id = "Domina_Helm",
        craftableId = "Domina_Helm",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 4 },
            { material = "hap_purple_dye", count = 1 },
            { material = "thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Domina_cuirass",
        craftableId = "Domina_cuirass",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 10 },
            { material = "hap_purple_dye", count = 1 },
            { material = "thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Domina_pauldron_L",
        craftableId = "Domina_pauldron_L",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 6 },
            { material = "hap_purple_dye", count = 1 },
            { material = "thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Domina_pauldron_R",
        craftableId = "Domina_pauldron_R",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 6 },
            { material = "hap_purple_dye", count = 1 },
            { material = "thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Domina_greaves",
        craftableId = "Domina_greaves",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 6 },
            { material = "hap_purple_dye", count = 1 },
            { material = "thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Domina_boots",
        craftableId = "Domina_boots",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 3 },
            { material = "hap_purple_dye", count = 1 },
            { material = "thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Domina_gauntlet_L",
        craftableId = "Domina_gauntlet_L",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 4 },
            { material = "hap_purple_dye", count = 1 },
            { material = "thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Domina_gauntlet_R",
        craftableId = "Domina_gauntlet_R",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 4 },
            { material = "hap_purple_dye", count = 1 },
            { material = "thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Gold1_Armor_helm",
        craftableId = "Gold1_Armor_helm",
		category = "Gold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_gold", count = 4 }
		},
        toolRequirements = {
			{ tool = "mid_hammer", count = 1, conditionPerUse = 3 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Gold1_Armor_cuirass",
        craftableId = "Gold1_Armor_cuirass",
		category = "Gold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_gold", count = 10 }
		},
        toolRequirements = {
			{ tool = "mid_hammer", count = 1, conditionPerUse = 3 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Gold1_Armor_pauldron_L",
        craftableId = "Gold1_Armor_pauldron_L",
		category = "Gold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_gold", count = 6 }
		},
        toolRequirements = {
			{ tool = "mid_hammer", count = 1, conditionPerUse = 3 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	},

    {
        id = "Gold1_Armor_pauldron_R",
        craftableId = "Gold1_Armor_pauldron_R",
		category = "Gold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_gold", count = 6 }
		},
        toolRequirements = {
			{ tool = "mid_hammer", count = 1, conditionPerUse = 3 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
	}
}

local function registerRecipes(e)
    ---@type CraftingFramework.MenuActivator
    if e.menuActivator then
        for _, recipe in ipairs(recipes) do
            e.menuActivator:registerRecipe(recipe)
        end
    end
end

event.register("HammerAndProngs:OpenMenu:Registered", registerRecipes)