local recipes = {

	-- Weapons

    {
        id = "T_Dae_Alternate_Boots_01",
        craftableId = "T_Dae_Alternate_Boots_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Alternate_Buckler_01",
        craftableId = "T_Dae_Alternate_Buckler_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Alternate_Cuirass_01",
        craftableId = "T_Dae_Alternate_Cuirass_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Alternate_GauntletL_01",
        craftableId = "T_Dae_Alternate_GauntletL_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Alternate_GauntletR_01",
        craftableId = "T_Dae_Alternate_GauntletR_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Alternate_Greaves_01",
        craftableId = "T_Dae_Alternate_Greaves_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Alternate_HelmOpen_01",
        craftableId = "T_Dae_Alternate_HelmOpen_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Alternate_Helm_01",
        craftableId = "T_Dae_Alternate_Helm_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Alternate_PauldronL_01",
        craftableId = "T_Dae_Alternate_PauldronL_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Alternate_PauldronR_01",
        craftableId = "T_Dae_Alternate_PauldronR_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Regular_HelmAberration_01",
        craftableId = "T_Dae_Regular_HelmAberration_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Regular_HelmConsolat_01",
        craftableId = "T_Dae_Regular_HelmConsolat_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Regular_HelmHumiliat_02",
        craftableId = "T_Dae_Regular_HelmHumiliat_02",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Regular_HelmRebellion_01",
        craftableId = "T_Dae_Regular_HelmRebellion_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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
        id = "T_Dae_Regular_HelmRenewal_01",
        craftableId = "T_Dae_Regular_HelmRenewal_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer to be crafted.",
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