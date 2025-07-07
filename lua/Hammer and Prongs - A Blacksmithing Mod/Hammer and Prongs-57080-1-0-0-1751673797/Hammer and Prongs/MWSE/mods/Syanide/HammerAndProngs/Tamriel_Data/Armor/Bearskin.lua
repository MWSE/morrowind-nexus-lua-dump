local recipes = {

    -- Armor
    {
        id = "Bearskin_helm",
        craftableId = "T_Nor_Bearskin_Helm_01",
		category = "Bearskin",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 2 },
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
        id = "Bearskin_p_right",
        craftableId = "T_Nor_Bearskin_PauldronR_01",
		category = "Bearskin",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 3 },
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
        id = "Bearskin_p_left",
        craftableId = "T_Nor_Bearskin_PauldronL_01",
		category = "Bearskin",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 3 },
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
        id = "Bearskin_g_right",
        craftableId = "T_Nor_Bearskin_BracerR_01",
		category = "Bearskin",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 2 },
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
        id = "Bearskin_g_left",
        craftableId = "T_Nor_Bearskin_BracerL_01",
		category = "Bearskin",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 2 },
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
        id = "Bearskin_greaves",
        craftableId = "T_Nor_Bearskin_Greaves_01",
		category = "Bearskin",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 3 },
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
        id = "Bearskin_boots",
        craftableId = "T_Nor_Bearskin_Boots_01",
		category = "Bearskin",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_bear_pelt", count = 2 },
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