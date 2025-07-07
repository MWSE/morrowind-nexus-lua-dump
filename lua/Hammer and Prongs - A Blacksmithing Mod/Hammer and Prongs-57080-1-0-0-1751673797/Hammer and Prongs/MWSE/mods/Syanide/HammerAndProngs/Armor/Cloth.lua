local recipes = {

    -- Cloth

    {
        id = "cloth bracer right",
        craftableId = "cloth bracer right",
		category = "Cloth",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_cloth", count = 2 },
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
        id = "cloth bracer left",
        craftableId = "cloth bracer left",
		category = "Cloth",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_cloth", count = 2 },
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
        id = "fur_colovian_helm",
        craftableId = "fur_colovian_helm",
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
        id = "fur_colovian_helm_white",
        craftableId = "fur_colovian_helm_white",
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
        id = "morag_tong_helm",
        craftableId = "morag_tong_helm",
		category = "Morag Tong",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 4 },
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
        id = "dust_adept_helm",
        craftableId = "dust_adept_helm",
		category = "Telvanni Dust Adept",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 2 },
            { material = "hap_resin", count = 1 }
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
        id = "mole_crab_helm",
        craftableId = "mole_crab_helm",
		category = "Telvanni Mole Crab",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_crab", count = 2 },
            { material = "hap_resin", count = 1 }
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
        id = "chitin_watchman_helm",
        craftableId = "chitin_watchman_helm",
		category = "Redoran Watchman",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 4 },
            { material = "hap_resin", count = 2 }
        },
        toolRequirements = {
			{ tool = "mid_hammer", count = 1, conditionPerUse = 5 }
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
        id = "gondolier_helm",
        craftableId = "gondolier_helm",
		category = "Misc",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 2 },
            { material = "hap_resin", count = 1 },
            { material = "hap_netch_leather_boiled", count = 1 }
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