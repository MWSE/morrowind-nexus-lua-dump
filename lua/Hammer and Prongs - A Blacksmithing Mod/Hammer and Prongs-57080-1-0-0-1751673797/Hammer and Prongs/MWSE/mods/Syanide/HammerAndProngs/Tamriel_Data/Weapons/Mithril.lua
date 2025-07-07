local recipes = {

	-- Weapons

    {
        id = "T_Bre_Mithril_Claymore_01", -- everything else
        craftableId = "T_Bre_Mithril_Claymore_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 10 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_Dagger_01", -- everything else
        craftableId = "T_Bre_Mithril_Dagger_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 4 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_DaiKatana_01", -- everything else
        craftableId = "T_Bre_Mithril_DaiKatana_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 10 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_Halberd_01", -- everything else
        craftableId = "T_Bre_Mithril_Halberd_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 12 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_Katana_01", -- everything else
        craftableId = "T_Bre_Mithril_Katana_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 10 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_Longsword_01", -- everything else
        craftableId = "T_Bre_Mithril_Longsword_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 8 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_Mace_01", -- everything else
        craftableId = "T_Bre_Mithril_Mace_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 8 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_Shortsword_01", -- everything else
        craftableId = "T_Bre_Mithril_Shortsword_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 6 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_Tanto_01", -- everything else
        craftableId = "T_Bre_Mithril_Tanto_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 6 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_ThrowKnife_01", -- knifes
        craftableId = "T_Bre_Mithril_ThrowKnife_01",
        category = "Mithril",
        soundId = "Repair",
        previewMesh = "tr\\w\\tr_w_mithril_knife.nif",
        noResult = true,
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 10 knives.",
        materials = {
            { material = "hap_mithril", count = 4 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Bre_Mithril_ThrowKnife_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Bre_Mithril_ThrowKnife_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
    },

    {
        id = "T_Bre_Mithril_Wakizashi_01", -- everything else
        craftableId = "T_Bre_Mithril_Wakizashi_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 8 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
            return skillValue >= 60
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