local recipes = {

	-- Armor

	{
        id = "orcish_helm",
        craftableId = "orcish_helm",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
	},

    {
        id = "orcish_cuirass",
        craftableId = "orcish_cuirass",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 20 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
	},

    {
        id = "orcish_bracer_left",
        craftableId = "orcish_bracer_left",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
	},

    {
        id = "orcish_bracer_right",
        craftableId = "orcish_bracer_right",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
	},

    {
        id = "orcish_pauldron_left",
        craftableId = "orcish_pauldron_left",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 12 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
	},

    {
        id = "orcish_pauldron_right",
        craftableId = "orcish_pauldron_right",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 12 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
	},

    {
        id = "orcish_boots",
        craftableId = "orcish_boots",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 6 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
	},

    {
        id = "orcish_greaves",
        craftableId = "orcish_greaves",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 12 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
	},

    {
        id = "orcish_towershield",
        craftableId = "orcish_towershield",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
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