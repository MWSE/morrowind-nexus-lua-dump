local recipes = {

	-- Weapons

    {
        id = "tr_steel_longspear",
        craftableId = "T_Com_Steel_Longspear_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 8 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_broadsword",
        craftableId = "T_Com_Steel_Broadsword_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 6 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_dagger",
        craftableId = "T_Com_Steel_Dagger_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_dagger_02",
        craftableId = "T_Com_Steel_Dagger_02",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_knife",
        craftableId = "T_Com_Steel_Knife_01",
        category = "Steel",
        previewMesh = "w\\w_steel_knife.nif",
        noResult = true,
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 10 knives.",
        materials = {
            { material = "hap_steel", count = 3 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Steel_Knife_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Steel_Knife_01 - invalid reference.")
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
        id = "tr_steel_longhammer",
        craftableId = "T_Com_Steel_Longhammer_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 8 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_morningstar",
        craftableId = "T_Com_Steel_Morningstar_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 4 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_naginata",
        craftableId = "T_Com_Steel_Naginata_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 8 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_rapier",
        craftableId = "T_Com_Steel_Rapier_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 6 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_scimitar",
        craftableId = "T_Com_Steel_Scimitar_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 8 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_shortsword",
        craftableId = "T_Com_Steel_Shortsword_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 4 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_shortsword_02",
        craftableId = "T_Com_Steel_Shortsword_02",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 4 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_truncheon",
        craftableId = "T_Com_Steel_Truncheon_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 4 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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
        id = "tr_steel_warpick",
        craftableId = "T_Com_Steel_Warpick_01",
        category = "Steel",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 4 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
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