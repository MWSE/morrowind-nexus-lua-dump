local recipes = {

	-- Armor

    {
        id = "T_Rga_Iron_Boots_01",
        craftableId = "T_Rga_Iron_Boots_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 4 },
            { material = "hap_leather", count = 2 }
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
        id = "T_Rga_Iron_BracerL_01",
        craftableId = "T_Rga_Iron_BracerL_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 4 },
            { material = "hap_leather", count = 2 }
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
        id = "T_Rga_Iron_BracerR_01",
        craftableId = "T_Rga_Iron_BracerR_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 4 },
            { material = "hap_leather", count = 2 }
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
        id = "T_Rga_Iron_Cuirass_01",
        craftableId = "T_Rga_Iron_Cuirass_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 10 },
            { material = "hap_leather", count = 2 }
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
        id = "T_Rga_Iron_Greaves_01",
        craftableId = "T_Rga_Iron_Greaves_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 6 },
            { material = "hap_leather", count = 2 }
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
        id = "T_Rga_Iron_Helm_01",
        craftableId = "T_Rga_Iron_Helm_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 4 },
            { material = "hap_leather", count = 2 }
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
        id = "T_Rga_Iron_PauldronL_01",
        craftableId = "T_Rga_Iron_PauldronL_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 6 },
            { material = "hap_leather", count = 2 }
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
        id = "T_Rga_Iron_PauldronR_01",
        craftableId = "T_Rga_Iron_PauldronR_01",
        category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_iron", count = 6 },
            { material = "hap_leather", count = 2 }
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