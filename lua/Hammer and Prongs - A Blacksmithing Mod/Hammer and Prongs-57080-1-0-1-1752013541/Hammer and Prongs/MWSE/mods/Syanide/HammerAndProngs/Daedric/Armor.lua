local recipes = {

	-- Armor

	{
        id = "daedric_cuirass",
        craftableId = "daedric_cuirass",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 40 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_pauldron_left",
        craftableId = "daedric_pauldron_left",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 21 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_pauldron_right",
        craftableId = "daedric_pauldron_right",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 21 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_gauntlet_left",
        craftableId = "daedric_gauntlet_left",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_gauntlet_right",
        craftableId = "daedric_gauntlet_right",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_greaves",
        craftableId = "daedric_greaves",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 21 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_boots",
        craftableId = "daedric_boots",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 12 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_shield",
        craftableId = "daedric_shield",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_fountain_helm",
        craftableId = "daedric_fountain_helm",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_terrifying_helm",
        craftableId = "daedric_terrifying_helm",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_god_helm",
        craftableId = "daedric_god_helm",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "daedric_towershield",
        craftableId = "daedric_towershield",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 21 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
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