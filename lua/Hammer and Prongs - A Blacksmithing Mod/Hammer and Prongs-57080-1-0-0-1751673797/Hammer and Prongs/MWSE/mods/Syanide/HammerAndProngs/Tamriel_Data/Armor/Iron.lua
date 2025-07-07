local recipes = {

	-- Armor

    {
        id = "T_Com_IronSpike_Helm_01",
        craftableId = "T_Com_IronSpike_Helm_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_IronSpike_PauldronL_01",
        craftableId = "T_Com_IronSpike_PauldronL_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 3 }
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
        id = "T_Com_IronSpike_PauldronR_01",
        craftableId = "T_Com_IronSpike_PauldronR_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 3 }
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
        id = "T_Com_Iron_Boots_01",
        craftableId = "T_Com_Iron_Boots_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_Boots_02",
        craftableId = "T_Com_Iron_Boots_02",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_BracerL_01",
        craftableId = "T_Com_Iron_BracerL_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_BracerL_02",
        craftableId = "T_Com_Iron_BracerL_02",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_BracerR_01",
        craftableId = "T_Com_Iron_BracerR_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_BracerR_02",
        craftableId = "T_Com_Iron_BracerR_02",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_Cuirass_01",
        craftableId = "T_Com_Iron_Cuirass_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 5 }
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
        id = "T_Com_Iron_Cuirass_02",
        craftableId = "T_Com_Iron_Cuirass_02",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 5 }
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
        id = "T_Com_Iron_Greaves_01",
        craftableId = "T_Com_Iron_Greaves_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 3 }
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
        id = "T_Com_Iron_Greaves_02",
        craftableId = "T_Com_Iron_Greaves_02",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 3 }
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
        id = "T_Com_Iron_Helm_01",
        craftableId = "T_Com_Iron_Helm_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_Helm_02",
        craftableId = "T_Com_Iron_Helm_02",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_Helm_03",
        craftableId = "T_Com_Iron_Helm_03",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_Helm_04",
        craftableId = "T_Com_Iron_Helm_04",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_Helm_Open",
        craftableId = "T_Com_Iron_Helm_Open",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_Helm_Open_02",
        craftableId = "T_Com_Iron_Helm_Open_02",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 2 }
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
        id = "T_Com_Iron_PauldronL_01",
        craftableId = "T_Com_Iron_PauldronL_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 3 }
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
        id = "T_Com_Iron_PauldronL_02",
        craftableId = "T_Com_Iron_PauldronL_02",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 3 }
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
        id = "T_Com_Iron_PauldronR_01",
        craftableId = "T_Com_Iron_PauldronR_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 3 }
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
        id = "T_Com_Iron_PauldronR_02",
        craftableId = "T_Com_Iron_PauldronR_02",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 3 }
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