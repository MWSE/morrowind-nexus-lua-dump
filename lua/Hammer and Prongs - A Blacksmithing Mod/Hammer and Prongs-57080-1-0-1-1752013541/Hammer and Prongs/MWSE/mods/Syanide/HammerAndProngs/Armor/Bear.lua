local recipes = {

	-- Armor

	{
        id = "BM Bear Helmet",
        craftableId = "BM Bear Helmet",
		category = "Bear",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 4 },
            { material = "hap_thread", count = 1 }
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
        id = "BM bear cuirass",
        craftableId = "BM bear cuirass",
		category = "Bear",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 10 },
            { material = "hap_thread", count = 1 }
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
        id = "BM Bear left Pauldron",
        craftableId = "BM Bear left Pauldron",
		category = "Bear",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 6 },
            { material = "hap_thread", count = 1 }
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
        id = "BM bear right pauldron",
        craftableId = "BM bear right pauldron",
		category = "Bear",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 6 },
            { material = "hap_thread", count = 1 }
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
        id = "bm bear left gauntlet",
        craftableId = "bm bear left gauntlet",
		category = "Bear",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 4 },
            { material = "hap_thread", count = 1 }
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
        id = "BM bear right gauntlet",
        craftableId = "BM bear right gauntlet",
		category = "Bear",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 4 },
            { material = "hap_thread", count = 1 }
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
        id = "BM bear boots",
        craftableId = "BM bear boots",
		category = "Bear",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 3 },
            { material = "hap_thread", count = 1 }
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
        id = "BM bear greaves",
        craftableId = "BM bear greaves",
		category = "Bear",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 6 },
            { material = "hap_thread", count = 1 }
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
        id = "BM bear shield",
        craftableId = "BM bear shield",
		category = "Bear",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 4 },
            { material = "hap_thread", count = 1 }
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