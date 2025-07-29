local recipes = {

	-- Armor

	{
        id = "BM_NordicMail_Helmet",
        craftableId = "BM_NordicMail_Helmet",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 },
            { material = "hap_silver", count = 6 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 100
        end
	},

    {
        id = "BM_NordicMail_cuirass",
        craftableId = "BM_NordicMail_cuirass",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 15 },
            { material = "hap_silver", count = 15 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 100
        end
	},

    {
        id = "BM_NordicMail_PauldronL",
        craftableId = "BM_NordicMail_PauldronL",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 11 },
            { material = "hap_silver", count = 10 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 100
        end
	},

    {
        id = "BM_NordicMail_PauldronR",
        craftableId = "BM_NordicMail_PauldronR",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 11 },
            { material = "hap_silver", count = 10 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 100
        end
	},

    {
        id = "BM_NordicMail_gauntletL",
        craftableId = "BM_NordicMail_gauntletL",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 },
            { material = "hap_silver", count = 6 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 100
        end
	},

    {
        id = "BM_NordicMail_gauntletR",
        craftableId = "BM_NordicMail_gauntletR",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 },
            { material = "hap_silver", count = 6 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 100
        end
	},

    {
        id = "BM_NordicMail_Boots",
        craftableId = "BM_NordicMail_Boots",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 5 },
            { material = "hap_silver", count = 4 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 100
        end
	},

    {
        id = "BM_NordicMail_greaves",
        craftableId = "BM_NordicMail_greaves",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 9 },
            { material = "hap_silver", count = 9 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 100
        end
	},

    {
        id = "BM_NordicMail_Shield",
        craftableId = "BM_NordicMail_Shield",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 },
            { material = "hap_silver", count = 6 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
		knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 100
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