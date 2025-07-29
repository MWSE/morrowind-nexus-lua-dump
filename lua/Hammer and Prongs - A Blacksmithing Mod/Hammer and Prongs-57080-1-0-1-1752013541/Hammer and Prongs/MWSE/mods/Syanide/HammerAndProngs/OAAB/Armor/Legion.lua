local recipes = {

	-- Armor

	{
        id = "AB_a_ImpBmHelm",
        craftableId = "AB_a_ImpBmHelm",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 4 },
            { material = "hap_cloth", count = 4 }
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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 60
                end
            end
            return false
        end
	},

    {
        id = "AB_a_ImpBmCuirass",
        craftableId = "AB_a_ImpBmCuirass",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 10 },
            { material = "hap_leather", count = 5 },
            { material = "hap_cloth", count = 5 }
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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 60
                end
            end
            return false
        end
	},

    {
        id = "AB_a_ImpBmPldLeft",
        craftableId = "AB_a_ImpBmPldLeft",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 12 }
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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 60
                end
            end
            return false
        end
	},

    {
        id = "AB_a_ImpBmPldRight",
        craftableId = "AB_a_ImpBmPldRight",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 12 }
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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 60
                end
            end
            return false
        end
	},

    {
        id = "AB_a_ImpBmGreaves",
        craftableId = "AB_a_ImpBmGreaves",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 },
            { material = "hap_leather", count = 4 },
            { material = "hap_cloth", count = 2 }

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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 60
                end
            end
            return false
        end
	},

    {
        id = "AB_a_ImpBmBoots",
        craftableId = "AB_a_ImpBmBoots",
		category = "Legion",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_leather", count = 3 },
            { material = "hap_cloth", count = 3 }
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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 60
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