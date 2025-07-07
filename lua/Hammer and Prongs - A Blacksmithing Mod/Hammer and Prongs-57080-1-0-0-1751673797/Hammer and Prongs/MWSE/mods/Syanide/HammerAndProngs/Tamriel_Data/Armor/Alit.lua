local recipes = {

	-- Armor

	{
        id = "T_De_AlitHide_Helm_01",
        craftableId = "T_De_AlitHide_Helm_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 4 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_HelmOpen_01",
        craftableId = "T_De_AlitHide_HelmOpen_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 4 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_Cuirass_01",
        craftableId = "T_De_AlitHide_Cuirass_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 10 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_PauldronL_01",
        craftableId = "T_De_AlitHide_PauldronL_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 6 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_PauldronR_01",
        craftableId = "T_De_AlitHide_PauldronR_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 6 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_Greaves_01",
        craftableId = "T_De_AlitHide_Greaves_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 6 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_Boots_01",
        craftableId = "T_De_AlitHide_Boots_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 3 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_BracerL_01",
        craftableId = "T_De_AlitHide_BracerL_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 4 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_BracerR_01",
        craftableId = "T_De_AlitHide_BracerR_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 4 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_Shield_01",
        craftableId = "T_De_AlitHide_Shield_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 4 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_AlitHide_TowerShield_01",
        craftableId = "T_De_AlitHide_TowerShield_01",
		category = "Alit",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_alit", count = 6 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 5 }
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