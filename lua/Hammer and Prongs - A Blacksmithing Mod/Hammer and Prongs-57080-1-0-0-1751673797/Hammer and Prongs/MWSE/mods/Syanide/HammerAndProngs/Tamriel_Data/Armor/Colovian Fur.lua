local recipes = {

    -- Armor
    {
        id = "T_Imp_ColFur_HelmR_01",
        craftableId = "T_Imp_ColFur_HelmR_01",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_red_dye", count = 1 }
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
        id = "T_Imp_ColFur_HelmTiger_01",
        craftableId = "T_Imp_ColFur_HelmTiger_01",
        category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_fur", count = 2 },
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
        id = "T_Imp_ColFur_HelmBl_01",
        craftableId = "T_Imp_ColFur_HelmBl_01",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
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
        id = "T_Imp_ColFur_HelmEx_01",
        craftableId = "T_Imp_ColFur_HelmEx_01",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_plumes", count = 1 },
            { material = "hap_ruby", count = 1 },
            { material = "hap_gold", count = 1 }
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
        id = "T_Imp_ColFur_Cuirass_01",
        craftableId = "T_Imp_ColFur_Cuirass_01",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 5 },
            { material = "hap_thread", count = 1 },
            { material = "hap_yellow_dye", count = 1 }
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
        id = "T_Imp_ColFur_GauntL_01",
        craftableId = "T_Imp_ColFur_GauntL_01",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_yellow_dye", count = 1 }
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
        id = "T_Imp_ColFur_GauntR_01",
        craftableId = "T_Imp_ColFur_GauntR_01",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_yellow_dye", count = 1 }
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
        id = "T_Imp_ColFur_Boots_01",
        craftableId = "T_Imp_ColFur_Boots_01",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_yellow_dye", count = 1 }
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
        id = "T_Imp_ColFur_Cuirass_02",
        craftableId = "T_Imp_ColFur_Cuirass_02",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 5 },
            { material = "hap_thread", count = 1 },
            { material = "hap_white_dye", count = 1 }
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
        id = "T_Imp_ColFur_GauntL_02",
        craftableId = "T_Imp_ColFur_GauntL_02",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_white_dye", count = 1 }
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
        id = "T_Imp_ColFur_GauntR_02",
        craftableId = "T_Imp_ColFur_GauntR_02",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_white_dye", count = 1 }
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
        id = "T_Imp_ColFur_Boots_02",
        craftableId = "T_Imp_ColFur_Boots_02",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_white_dye", count = 1 }
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
        id = "T_Imp_ColFur_Cuirass_03",
        craftableId = "T_Imp_ColFur_Cuirass_03",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 5 },
            { material = "hap_thread", count = 1 },
            { material = "hap_red_dye", count = 1 }
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
        id = "T_Imp_ColFur_GauntL_03",
        craftableId = "T_Imp_ColFur_GauntL_03",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_red_dye", count = 1 }
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
        id = "T_Imp_ColFur_GauntR_03",
        craftableId = "T_Imp_ColFur_GauntR_03",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_red_dye", count = 1 }
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
        id = "T_Imp_ColFur_Boots_03",
        craftableId = "T_Imp_ColFur_Boots_03",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_red_dye", count = 1 }
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
        id = "T_Imp_ColFur_Cuirass_04",
        craftableId = "T_Imp_ColFur_Cuirass_04",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 5 },
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
        id = "T_Imp_ColFur_GauntL_04",
        craftableId = "T_Imp_ColFur_GauntL_04",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
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
        id = "T_Imp_ColFur_GauntR_04",
        craftableId = "T_Imp_ColFur_GauntR_04",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
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
        id = "T_Imp_ColFur_Boots_04",
        craftableId = "T_Imp_ColFur_Boots_04",
		category = "Colovian Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_fur", count = 2 },
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