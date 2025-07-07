local recipes = {

	-- Armor

    {
        id = "T_Nor_Toadscale_Boots_01",
        craftableId = "T_Nor_Toadscale_Boots_01",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Boots_02",
        craftableId = "T_Nor_Toadscale_Boots_02",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Cuirass_01",
        craftableId = "T_Nor_Toadscale_Cuirass_01",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 10 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Cuirass_02",
        craftableId = "T_Nor_Toadscale_Cuirass_02",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 10 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_GauntletL_01",
        craftableId = "T_Nor_Toadscale_GauntletL_01",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_GauntletL_02",
        craftableId = "T_Nor_Toadscale_GauntletL_02",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_GauntletR_01",
        craftableId = "T_Nor_Toadscale_GauntletR_01",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_GauntletR_02",
        craftableId = "T_Nor_Toadscale_GauntletR_02",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Greaves_01",
        craftableId = "T_Nor_Toadscale_Greaves_01",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 6 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Greaves_02",
        craftableId = "T_Nor_Toadscale_Greaves_02",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 6 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Helm_01",
        craftableId = "T_Nor_Toadscale_Helm_01",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Helm_02",
        craftableId = "T_Nor_Toadscale_Helm_02",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Helm_03",
        craftableId = "T_Nor_Toadscale_Helm_03",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Helm_04",
        craftableId = "T_Nor_Toadscale_Helm_04",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_PauldL_01",
        craftableId = "T_Nor_Toadscale_PauldL_01",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 6 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_PauldL_02",
        craftableId = "T_Nor_Toadscale_PauldL_02",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 6 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_PauldR_01",
        craftableId = "T_Nor_Toadscale_PauldR_01",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 6 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_PauldR_02",
        craftableId = "T_Nor_Toadscale_PauldR_02",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 6 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Shield_01",
        craftableId = "T_Nor_Toadscale_Shield_01",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Toadscale_Shield_02",
        craftableId = "T_Nor_Toadscale_Shield_02",
        category = "Toadscale",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
            { material = "hap_red_dye", count = 1 },
            { material = "hap_chalk", count = 1 },
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