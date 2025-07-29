local recipes = {

	-- Armor

	{
        id = "AB_a_BugGreenHelm",
        craftableId = "AB_a_BugGreenHelm",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 4 },
            { material = "hap_resin", count = 2 }
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
        id = "AB_a_BugGreenCuirass",
        craftableId = "AB_a_BugGreenCuirass",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 10 },
            { material = "hap_resin", count = 2 }
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
        id = "AB_a_BugGreenPldLeft",
        craftableId = "AB_a_BugGreenPldLeft",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 6 },
            { material = "hap_resin", count = 2 }
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
        id = "AB_a_BugGreenPldRight",
        craftableId = "AB_a_BugGreenPldRight",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 6 },
            { material = "hap_resin", count = 2 }
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
        id = "AB_a_BugGreenGntLeft",
        craftableId = "AB_a_BugGreenGntLeft",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 4 },
            { material = "hap_resin", count = 2 }
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
        id = "AB_a_BugGreenGntRight",
        craftableId = "AB_a_BugGreenGntRight",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 4 },
            { material = "hap_resin", count = 2 }
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
        id = "AB_a_BugGreenBoots",
        craftableId = "AB_a_BugGreenBoots",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 3 },
            { material = "hap_resin", count = 2 }
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
        id = "AB_a_BugGreenGreaves",
        craftableId = "AB_a_BugGreenGreaves",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 6 },
            { material = "hap_resin", count = 2 }
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
        id = "AB_a_BugGreenShield",
        craftableId = "AB_a_BugGreenShield",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 4 },
            { material = "hap_resin", count = 2 }
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