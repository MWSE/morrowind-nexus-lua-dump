local recipes = {

	-- Armor

    {
        id = "T_Orc_Leather_Boots_01",
        craftableId = "T_Orc_Leather_Boots_01",
        category = "Leather",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle  or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
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
        id = "T_Orc_Leather_Cuirass_01",
        craftableId = "T_Orc_Leather_Cuirass_01",
        category = "Leather",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle  or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 10 },
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
        id = "T_Orc_Leather_GauntletL_01",
        craftableId = "T_Orc_Leather_GauntletL_01",
        category = "Leather",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle  or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
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
        id = "T_Orc_Leather_GauntletR_01",
        craftableId = "T_Orc_Leather_GauntletR_01",
        category = "Leather",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle  or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
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
        id = "T_Orc_Leather_Greaves_01",
        craftableId = "T_Orc_Leather_Greaves_01",
        category = "Leather",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle  or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 6 },
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
        id = "T_Orc_Leather_Helm_01",
        craftableId = "T_Orc_Leather_Helm_01",
        category = "Leather",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle  or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 4 },
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
        id = "T_Orc_Leather_PauldronL_01",
        craftableId = "T_Orc_Leather_PauldronL_01",
        category = "Leather",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle  or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 6 },
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
        id = "T_Orc_Leather_PauldronR_01",
        craftableId = "T_Orc_Leather_PauldronR_01",
        category = "Leather",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle  or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 6 },
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