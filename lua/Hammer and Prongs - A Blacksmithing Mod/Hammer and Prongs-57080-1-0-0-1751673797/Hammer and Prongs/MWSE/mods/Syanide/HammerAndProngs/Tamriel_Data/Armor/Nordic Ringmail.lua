local recipes = {
	{
        id = "T_Nor_Ringmail_Helm_Closed",
        craftableId = "T_Nor_Ringmail_Helm_Closed",
		category = "Nordic Ringmail",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 },
            { material = "hap_leather", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
	},

    	{
        id = "T_Nor_Ringmail_Helmet_02",
        craftableId = "T_Nor_Ringmail_Helmet_02",
		category = "Nordic Ringmail",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 },
            { material = "hap_leather", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
	},

    {
        id = "T_Nor_Ringmail_PauldronL_02",
        craftableId = "T_Nor_Ringmail_PauldronL_02",
		category = "Nordic Ringmail",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 },
            { material = "hap_leather", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
	},

    {
        id = "T_Nor_Ringmail_PauldronR_02",
        craftableId = "T_Nor_Ringmail_PauldronR_02",
		category = "Nordic Ringmail",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 },
            { material = "hap_leather", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
	},

    {
        id = "T_Nor_Ringmail_BracerL_02",
        craftableId = "T_Nor_Ringmail_BracerL_02",
		category = "Nordic Ringmail",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 },
            { material = "hap_leather", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
	},

    {
        id = "T_Nor_Ringmail_BracerR_02",
        craftableId = "T_Nor_Ringmail_BracerR_02",
		category = "Nordic Ringmail",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 },
            { material = "hap_leather", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
	},

    {
        id = "T_Nor_Ringmail_Boots_02",
        craftableId = "T_Nor_Ringmail_Boots_02",
		category = "Nordic Ringmail",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 },
            { material = "hap_leather", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
	},

    {
        id = "T_Nor_Ringmail_Greaves_02",
        craftableId = "T_Nor_Ringmail_Greaves_02",
		category = "Nordic Ringmail",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 },
            { material = "hap_leather", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 1
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
	},
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