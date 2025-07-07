local recipes = {
    {
        id = "Nordic Leather_helm",
        craftableId = "T_Nor_Leather1_Helm_01",
		category = "Nordic Leather",
        soundId = "Item Clothes Up",
        description = "Requires thread to be crafted.",
		materials = {
			{ material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "Nordic Leather_cuirass",
        craftableId = "T_Nor_Leather1_Cuirass_01",
		category = "Nordic Leather",
        soundId = "Item Clothes Up",
        description = "Requires thread to be crafted.",
		materials = {
			{ material = "hap_leather", count = 5 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "Nordic Leather_p_right",
        craftableId = "T_Nor_Leather1_PauldR_01",
		category = "Nordic Leather",
        soundId = "Item Clothes Up",
        description = "Requires thread to be crafted.",
		materials = {
			{ material = "hap_leather", count = 3 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "Nordic Leather_p_left",
        craftableId = "T_Nor_Leather1_PauldL_01",
		category = "Nordic Leather",
        soundId = "Item Clothes Up",
        description = "Requires thread to be crafted.",
		materials = {
			{ material = "hap_leather", count = 3 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "Nordic Leather_g_right",
        craftableId = "T_Nor_Leather1_BarcerR_01",
		category = "Nordic Leather",
        soundId = "Item Clothes Up",
        description = "Requires thread to be crafted.",
		materials = {
			{ material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "Nordic Leather_g_left",
        craftableId = "T_Nor_Leather1_BarcerL_01",
		category = "Nordic Leather",
        soundId = "Item Clothes Up",
        description = "Requires thread to be crafted.",
		materials = {
			{ material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "Nordic Leather_greaves",
        craftableId = "T_Nor_Leather1_Greaves_01",
		category = "Nordic Leather",
        soundId = "Item Clothes Up",
        description = "Requires thread to be crafted.",
		materials = {
			{ material = "hap_leather", count = 3 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "Nordic Leather_boots",
        craftableId = "T_Nor_Leather1_Boots_01",
		category = "Nordic Leather",
        soundId = "Item Clothes Up",
        description = "Requires thread to be crafted.",
		materials = {
			{ material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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