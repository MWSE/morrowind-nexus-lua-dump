local recipes = {

	-- Armor

    {
        id = "T_Imp_ColLeather_Boots_01",
        craftableId = "T_Imp_ColLeather_Boots_01",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
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
        id = "T_Imp_ColLeather_Boots_02",
        craftableId = "T_Imp_ColLeather_Boots_02",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
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
        id = "T_Imp_ColLeather_BracerL_01",
        craftableId = "T_Imp_ColLeather_BracerL_01",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
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
        id = "T_Imp_ColLeather_BracerL_02",
        craftableId = "T_Imp_ColLeather_BracerL_02",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
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
        id = "T_Imp_ColLeather_BracerR_01",
        craftableId = "T_Imp_ColLeather_BracerR_01",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
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
        id = "T_Imp_ColLeather_BracerR_02",
        craftableId = "T_Imp_ColLeather_BracerR_02",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
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
        id = "T_Imp_ColLeather_Cuirass_01",
        craftableId = "T_Imp_ColLeather_Cuirass_01",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 5 },
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
        id = "T_Imp_ColLeather_Cuirass_02",
        craftableId = "T_Imp_ColLeather_Cuirass_02",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 5 },
            { material = "hap_thread", count = 1 },
            { material = "hap_iron", count =1 },
            { material = "hap_material3", count = num2 }
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
        id = "T_Imp_ColLeather_Greaves_01",
        craftableId = "T_Imp_ColLeather_Greaves_01",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 3 },
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
        id = "T_Imp_ColLeather_Greaves_02",
        craftableId = "T_Imp_ColLeather_Greaves_02",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 3 },
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
        id = "T_Imp_ColLeather_Helm_01",
        craftableId = "T_Imp_ColLeather_Helm_01",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_iron", count = 2 }
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
        id = "T_Imp_ColLeather_Helm_02",
        craftableId = "T_Imp_ColLeather_Helm_02",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 },
            { material = "hap_iron", count = 2 }
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
        id = "T_Imp_ColLeather_PauldronL_01",
        craftableId = "T_Imp_ColLeather_PauldronL_01",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 3 },
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
        id = "T_Imp_ColLeather_PauldronL_02",
        craftableId = "T_Imp_ColLeather_PauldronL_02",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 3 },
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
        id = "T_Imp_ColLeather_PauldronR_01",
        craftableId = "T_Imp_ColLeather_PauldronR_01",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 3 },
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
        id = "T_Imp_ColLeather_PauldronR_02",
        craftableId = "T_Imp_ColLeather_PauldronR_02",
        category = "Colovian Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 3 },
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