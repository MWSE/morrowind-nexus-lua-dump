local recipes = {
	{
        id = "Studded Leather_helm",
        craftableId = "T_Imp_StuddedLeather_Helm_01",
		category = "Studded Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 4 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 2 }
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
        id = "Studded Leather pauldron - right",
        craftableId = "T_Imp_StuddedLeather_PauldrR_01",
		category = "Studded Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 7 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 2 }
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
        id = "Studded Leather pauldron - left",
        craftableId = "T_Imp_StuddedLeather_PauldrL_01",
		category = "Studded Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 7 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 2 }
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
        id = "Studded Leather gauntlet - right",
        craftableId = "T_Imp_StuddedLeather_BracerR_01",
		category = "Studded Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 4 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 2 }
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
        id = "Studded Leather gauntlet - left",
        craftableId = "T_Imp_StuddedLeather_BracerL_01",
		category = "Studded Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 4 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 2 }
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
        id = "Studded Leather boots",
        craftableId = "T_Imp_StuddedLeather_Boots_01",
		category = "Studded Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 3 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 2 }
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
        id = "Studded Leather greaves",
        craftableId = "T_Imp_StuddedLeather_Greaves_01",
		category = "Studded Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 6 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 2 }
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