local recipes = {

	-- Armor

	{
        id = "DV_bonemold_armun-an_helm",
        craftableId = "DV_bonemold_armun-an_helm",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_bonemeal", count = 4 },
            { material = "hap_resin", count = 1 }
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
        id = "DV_bonemold_chuzei_helm_arg",
        craftableId = "DV_bonemold_chuzei_helm_arg",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_bonemeal", count = 4 },
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
        id = "DV_bonemold_chuzei_wra_helm_arg",
        craftableId = "DV_bonemold_chuzei_wra_helm_arg",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_bonemeal", count = 4 },
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
        id = "DV_bonemold_chuzei_wra_helm_reg",
        craftableId = "DV_bonemold_chuzei_wra_helm_reg",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_bonemeal", count = 4 },
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
        id = "DV_bonemold_gah-julan_helm_arg",
        craftableId = "DV_bonemold_gah-julan_helm_arg",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_bonemeal", count = 2 },
            { material = "hap_resin", count = 2 },
            { material = "hap_cloth", count = 1 }
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
        id = "DV_bonemold_helm_arg",
        craftableId = "DV_bonemold_helm_arg",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_bonemeal", count = 4 },
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
        id = "DV_cephalopod_helm",
        craftableId = "DV_cephalopod_helm",
		category = "Cephalopod",
        soundId = "Repair",
        description = "Requires a Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_cephalopod", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "DV_cephalopod_helm_eyes",
        craftableId = "DV_cephalopod_helm_eyes",
		category = "Cephalopod",
        soundId = "Repair",
        description = "Requires a Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_cephalopod", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "DV_cephalopod_helm_horns",
        craftableId = "DV_cephalopod_helm_horns",
		category = "Cephalopod",
        soundId = "Repair",
        description = "Requires a Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_cephalopod", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "DV_chitin_helm_arg",
        craftableId = "DV_chitin_helm_arg",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 2 },
            { material = "hap_resin", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "DV_morag_tong_helm",
        craftableId = "DV_morag_tong_helm",
		category = "Morag Tong",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 4 },
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
            if not player then 
                return false
            else
                if factions.isMoragTong() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 30
                end
            end
            return false
        end
	},

    {
        id = "DV_dust_adept_helm",
        craftableId = "DV_dust_adept_helm",
		category = "Telvanni Dust Adept",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 2 },
            { material = "hap_resin", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "DV_mole_crab_helm",
        craftableId = "DV_mole_crab_helm",
		category = "Telvanni Mole Crab",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_crab", count = 2 },
            { material = "hap_resin", count = 1 }
        },
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "DV_watchman_helm",
        craftableId = "DV_watchman_helm",
		category = "Redoran Watchman",
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
        id = "DV_ebony_closed_helm",
        craftableId = "DV_ebony_closed_helm",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 12 }
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
            return skillValue >= 90
        end
	},

    {
        id = "DV_iron_helmet_arg",
        craftableId = "DV_iron_helmet_arg",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "DV_netch_leather_boiled_helm",
        craftableId = "DV_netch_leather_boiled_helm",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather_boiled", count = 2 },
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
        id = "DV_netch_leather_boiled_helm_h",
        craftableId = "DV_netch_leather_boiled_helm_h",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather_boiled", count = 2 },
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
        id = "DV_orcish_helm_arg_horns",
        craftableId = "DV_orcish_helm_arg_horns",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 4 }
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
        id = "DV_steel_helm_arg",
        craftableId = "DV_steel_helm_arg",
		category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 4 }
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
        id = "DV_steel_helm_arg_horns",
        craftableId = "DV_steel_helm_arg_horns",
		category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 4 }
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