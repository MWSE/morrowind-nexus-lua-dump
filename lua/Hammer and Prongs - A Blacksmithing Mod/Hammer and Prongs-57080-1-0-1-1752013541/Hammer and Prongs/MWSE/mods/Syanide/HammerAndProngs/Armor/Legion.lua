local recipes = {

	-- Armor

	{
        id = "imperial_chain_coif_helm",
        craftableId = "imperial_chain_coif_helm",
		category = "Legion",
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
        id = "imperial helmet armor",
        craftableId = "imperial helmet armor",
		category = "Legion",
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
        id = "templar_helmet_armor",
        craftableId = "templar_helmet_armor",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 3 },
            { material = "hap_bronze", count = 1 }
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
        id = "imperial_chain_cuirass",
        craftableId = "imperial_chain_cuirass",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 8 },
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
        id = "imperial cuirass_armor",
        craftableId = "imperial cuirass_armor",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 10 }
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
        id = "templar_cuirass",
        craftableId = "templar_cuirass",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 },
            { material = "hap_bronze", count = 2 },
            { material = "hap_cloth", count = 1 },
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
        id = "silver_dukesguard_cuirass",
        craftableId = "silver_dukesguard_cuirass",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_silver", count = 20 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 4 }
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
                    return skillValue >= 45
                end
            end
            return false
        end
	},

    {
        id = "imperial_chain_pauldron_left",
        craftableId = "imperial_chain_pauldron_left",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 }
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
        id = "imperial_chain_pauldron_right",
        craftableId = "imperial_chain_pauldron_right",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 }
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
        id = "imperial left pauldron",
        craftableId = "imperial left pauldron",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 }
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
        id = "imperial right pauldron",
        craftableId = "imperial right pauldron",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 }
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
        id = "templar_pauldron_left",
        craftableId = "templar_pauldron_left",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 4 },
            { material = "hap_bronze", count = 2 }
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
        id = "templar_pauldron_right",
        craftableId = "templar_pauldron_right",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 4 },
            { material = "hap_bronze", count = 2 }
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
        id = "imperial_greaves",
        craftableId = "imperial_greaves",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 }
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
        id = "templar_greaves",
        craftableId = "templar_greaves",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 4 },
            { material = "hap_bronze", count = 2 }
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
        id = "mperial_chain_greaves",
        craftableId = "imperial_chain_greaves",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 }
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
        id = "imperial boots",
        craftableId = "imperial boots",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 3 }
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
        id = "templar boots",
        craftableId = "templar boots",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 2 },
            { material = "hap_bronze", count = 1 }
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
        id = "imperial left gauntlet",
        craftableId = "imperial left gauntlet",
		category = "Legion",
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
        id = "imperial right gauntlet",
        craftableId = "imperial right gauntlet",
		category = "Legion",
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
        id = "templar bracer left",
        craftableId = "templar bracer left",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 2 },
            { material = "hap_bronze", count = 2 }
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
        id = "templar bracer right",
        craftableId = "templar bracer right",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 2 },
            { material = "hap_bronze", count = 2 }
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
        id = "imperial shield",
        craftableId = "imperial shield",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 }
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