local recipes = {

    -- Armor
    {
        id = "T_He_AltmerGlass_Boots_01",
        craftableId = "T_He_AltmerGlass_Boots_01",
        category = "Altmeri Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 9 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 75
        end
    },

    {
        id = "T_He_AltmerGlass_Cuirass_01",
        craftableId = "T_He_AltmerGlass_Cuirass_01",
        category = "Altmeri Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 30 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 75
        end
    },

    {
        id = "T_He_AltmerGlass_Greaves_01",
        craftableId = "T_He_AltmerGlass_Greaves_01",
        category = "Altmeri Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 18 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 75
        end
    },

    {
        id = "T_He_AltmerGlass_Helm_01",
        craftableId = "T_He_AltmerGlass_Helm_01",
        category = "Altmeri Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 75
        end
    },

    {
        id = "T_He_AltmerGlass_Helm_02",
        craftableId = "T_He_AltmerGlass_Helm_02",
        category = "Altmeri Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 75
        end
    },

    {
        id = "T_He_AltmerGlass_L_Bracer_01",
        craftableId = "T_He_AltmerGlass_L_Bracer_01",
        category = "Altmeri Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 75
        end
    },

    {
        id = "T_He_AltmerGlass_L_Pauldron_01",
        craftableId = "T_He_AltmerGlass_L_Pauldron_01",
        category = "Altmeri Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 75
        end
    },

    {
        id = "T_He_AltmerGlass_R_Bracer_01",
        craftableId = "T_He_AltmerGlass_R_Bracer_01",
        category = "Altmeri Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 75
        end
    },

    {
        id = "T_He_AltmerGlass_R_Pauldron_01",
        craftableId = "T_He_AltmerGlass_R_Pauldron_01",
        category = "Altmeri Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 75
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