local recipes = {

	-- Armor

    {
        id = "adamantium_tail",
        craftableId = "adamantium_tail",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 6 },
            { material = "hap_leather", count = 3 }
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
        id = "armunan_tail",
        craftableId = "armunan_tail",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_resin", count = 3 },
            { material = "hap_chitin", count = 2 },
            { material = "hap_leather", count = 2 }
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
        id = "bonemold_tail",
        craftableId = "bonemold_tail",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_resin", count = 3 },
            { material = "hap_chitin", count = 2 },
            { material = "hap_leather", count = 2 }
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
        id = "chuzei_tail",
        craftableId = "chuzei_tail",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_resin", count = 3 },
            { material = "hap_chitin", count = 2 },
            { material = "hap_leather", count = 2 }
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
        id = "gahjulan_tail",
        craftableId = "gahjulan_tail",
		category = "Bonemold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_resin", count = 3 },
            { material = "hap_chitin", count = 2 },
            { material = "hap_leather", count = 2 }
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
        id = "dwemer_tail",
        craftableId = "dwemer_tail",
		category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dwemer", count = 3 },
            { material = "hap_leather", count = 2 }
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
        id = "chitin_tail",
        craftableId = "chitin_tail",
		category = "Chitin",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 2 },
            { material = "hap_resin", count = 1 },
            { material = "hap_leather", count = 2 }
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
        id = "domina_tail",
        craftableId = "domina_tail",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 3 },
            { material = "hap_purple_dye", count = 1 },
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
        id = "arg_domina",
        craftableId = "arg_domina",
		category = "Domina",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 10 },
            { material = "hap_purple_dye", count = 1 },
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
        id = "steel_tail",
        craftableId = "steel_tail",
		category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 3 },
            { material = "hap_leather", count = 2 }
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
        id = "golden_tail",
        craftableId = "golden_tail",
		category = "Gold",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_gold", count = 3 },
            { material = "hap_leather", count = 2 }
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
        id = "orc_tail",
        craftableId = "orc_tail",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 6 },
            { material = "hap_leather", count = 2 }
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
        id = "nordic_tail",
        craftableId = "nordic_tail",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 5 },
            { material = "hap_silver", count = 3 },
            { material = "hap_leather", count = 4 }
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
        id = "ebony_tail",
        craftableId = "ebony_tail",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 9 },
            { material = "hap_leather", count = 4 }
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
        id = "glass_tail",
        craftableId = "glass_tail",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 9 },
            { material = "hap_leather", count = 4 }
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
        id = "impsteel_tail",
        craftableId = "impsteel_tail",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 3 },
            { material = "hap_leather", count = 2 }
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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 30
                end
            end
            return false
        end
	},

    {
        id = "templar_tail",
        craftableId = "templar_tail",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 2 },
            { material = "hap_bronze", count = 1 },
            { material = "hap_leather", count = 2 }
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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 30
                end
            end
            return false
        end
	},

    {
        id = "chain_tail",
        craftableId = "chain_tail",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 3 },
            { material = "hap_leather", count = 2 }
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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 30
                end
            end
            return false
        end
	},

    {
        id = "netch_tail",
        craftableId = "netch_tail",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 5 },
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
        id = "iron_tail",
        craftableId = "iron_tail",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 },
            { material = "hap_leather", count = 1 }
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
        id = "dreugh_tail",
        craftableId = "dreugh_tail",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 6 },
            { material = "hap_resin", count = 3 },
            { material = "hap_leather", count = 2 }
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
        id = "ceph_tail",
        craftableId = "ceph_tail",
		category = "Cephalopod",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_cephalopod", count = 3 },
            { material = "hap_leather", count = 2 }
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
        id = "scale_tail",
        craftableId = "scale_tail",
		category = "Imperial Dragonscale",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 2 },
            { material = "hap_bronze", count = 1 },
            { material = "hap_leather", count = 2 }
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
        id = "mole_tail",
        craftableId = "mole_tail",
		category = "Telvanni Mole Crab",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_crab", count = 2 },
            { material = "hap_resin", count = 1 },
            { material = "hap_leather", count = 2 }
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
        id = "dust_tail",
        craftableId = "dust_tail",
		category = "Telvanni Dust Adept",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 2 },
            { material = "hap_resin", count = 1 },
            { material = "hap_leather", count = 2 }
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
        id = "watch_tail",
        craftableId = "watch_tail",
		category = "Redoran Watchman",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 3 },
            { material = "hap_resin", count = 2 },
            { material = "hap_leather", count = 2 }
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