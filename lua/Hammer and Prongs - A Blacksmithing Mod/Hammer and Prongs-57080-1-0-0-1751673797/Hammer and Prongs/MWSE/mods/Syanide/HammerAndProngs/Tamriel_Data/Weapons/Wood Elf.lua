local recipes = {

	-- Weapons

    {
        id = "T_We_Wenbone_Arrow_01", -- arrows
        craftableId = "T_We_Wenbone_Arrow_01",
        category = "Wenbone",
        soundId = "Repair",
        previewMesh = "pc\\w\\pc_w_we_bone_arrow.nif",
        noResult = true,
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 24 arrows",
        materials = {
            { material = "hap_bone", count = 3 },
            { material = "hap_resin", count = 2 },
            { material = "hap_plumes", count = 3 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_We_Wenbone_Arrow_01", count = 24 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_We_Wenbone_Arrow_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_We_Wenbone_Bow_01", -- bow
        craftableId = "T_We_Wenbone_Bow_01",
        category = "Wenbone",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_bone", count = 4 },
            { material = "hap_resin", count = 2 },
            { material = "hap_thread", count = 1 }
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
        id = "T_We_Wenbone_Club_01", -- everything else
        craftableId = "T_We_Wenbone_Club_01",
        category = "Wenbone",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_bone", count = 4 },
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
        id = "T_We_Wenbone_Dagger_01", -- everything else
        craftableId = "T_We_Wenbone_Dagger_01",
        category = "Wenbone",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_bone", count = 2 },
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
        id = "T_We_Wenbone_Dart_01", -- everything else
        craftableId = "T_We_Wenbone_Dart_01",
        category = "Wenbone",
        soundId = "Repair",
        previewMesh = "va\\w\\va_w_wenbone_dart.nif",
        noResult = true,
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 10 darts.",
        materials = {
            { material = "hap_bone", count = 2 },
            { material = "hap_resin", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_We_Wenbone_Dart_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_We_Wenbone_Dart_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_We_Wenbone_Halberd_01", -- everything else
        craftableId = "T_We_Wenbone_Halberd_01",
        category = "Wenbone",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_bone", count = 10 },
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
        id = "T_We_Wenbone_Knife_01", -- knifes
        craftableId = "T_We_Wenbone_Knife_01",
        category = "Wenbone",
        soundId = "Repair",
        previewMesh = "va\\w\\va_w_wenbone_knife.nif",
        noResult = true,
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 10 knives.",
        materials = {
            { material = "hap_bone", count = 2 },
            { material = "hap_resin", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_We_Wenbone_Knife_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_We_Wenbone_Knife_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_We_Wenbone_Longsword_01", -- everything else
        craftableId = "T_We_Wenbone_Longsword_01",
        category = "Wenbone",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_bone", count = 6 },
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
        id = "T_We_Wenbone_Shortsword_01", -- everything else
        craftableId = "T_We_Wenbone_Shortsword_01",
        category = "Wenbone",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_bone", count = 4 },
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
        id = "T_We_Wenbone_Spear_01", -- everything else
        craftableId = "T_We_Wenbone_Spear_01",
        category = "Wenbone",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_bone", count = 8 },
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
        id = "T_We_Wenbone_Staff_01", -- everything else
        craftableId = "T_We_Wenbone_Staff_01",
        category = "Wenbone",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_bone", count = 6 },
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
        id = "T_We_Wenbone_Star_01", -- stars
        craftableId = "T_We_Wenbone_Star_01",
        category = "Wenbone",
        soundId = "Repair",
        previewMesh = "va\\w\\va_w_wenbone_star.nif",
        noResult = true,
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 10 stars.",
        materials = {
            { material = "hap_bone", count = 2 },
            { material = "hap_resin", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_We_Wenbone_Star_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_We_Wenbone_Star_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_We_Wenbone_Waraxe_01", -- everything else
        craftableId = "T_We_Wenbone_Waraxe_01",
        category = "Wenbone",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_bone", count = 4 },
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