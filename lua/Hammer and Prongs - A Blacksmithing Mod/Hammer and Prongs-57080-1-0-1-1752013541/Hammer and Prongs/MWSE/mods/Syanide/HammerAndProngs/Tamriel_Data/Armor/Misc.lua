local recipes = {

	-- Armor

    {
        id = "T_Nor_HornedLeather_Helm_01",
        craftableId = "T_Nor_HornedLeather_Helm_01",
        category = "Nordic",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
            { material = "hap_iron", count = 2 },
            { material = "hap_plumes", count = 3 }
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
        id = "T_Nor_Sabrecat_Helm_01",
        craftableId = "T_Nor_Sabrecat_Helm_01",
        category = "Fur",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_saberpelt", count = 1 },
            { material = "hap_sabertooth", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "mid_needle", count = 1, conditionPerUse = 3 }
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
        id = "T_Nor_Sabrecat_Helm_02",
        craftableId = "T_Nor_Sabrecat_Helm_02",
        category = "Fur",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_snowsaberpelt", count = 1 },
            { material = "hap_sabertooth", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "mid_needle", count = 1, conditionPerUse = 3 }
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
        id = "T_Nor_Wolf_Helm_Black_01",
        craftableId = "T_Nor_Wolf_Helm_Black_01",
        category = "Wolf",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_bwolf_pelt", count = 1 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "mid_needle", count = 1, conditionPerUse = 3 }
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
        id = "T_Nor_Wolf_Helm_Red_01",
        craftableId = "T_Nor_Wolf_Helm_Red_01",
        category = "Wolf",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_brwolf_pelt", count = 1 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "mid_needle", count = 1, conditionPerUse = 3 }
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
        id = "T_Nor_Wolf_Helm_White_01",
        craftableId = "T_Nor_Wolf_Helm_White_01",
        category = "Wolf",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_swolf_pelt", count = 1 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "mid_needle", count = 1, conditionPerUse = 3 }
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
        id = "T_Imp_Templar_ShieldTower_01",
        craftableId = "T_Imp_Templar_ShieldTower_01",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 5 },
            { material = "hap_bronze", count = 2 }
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
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 30
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Wood_ShieldTower_01",
        craftableId = "T_Imp_Wood_ShieldTower_01",
        category = "Wood",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_wood", count = 3 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Kha_Copper_Shield_01",
        craftableId = "T_Kha_Copper_Shield_01",
        category = "Copper",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_copper", count = 4 }
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
        id = "T_De_Caravaner_Helm_01",
        craftableId = "T_De_Caravaner_Helm_01",
        category = "Misc",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_netch_leather", count = 1 },
            { material = "hap_chitin", count = 1 },
            { material = "hap_resin", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Bre_BjoulsaeFur_Helm_01",
        craftableId = "T_Bre_BjoulsaeFur_Helm_01",
        category = "Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_fur", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "mid_needle", count = 1, conditionPerUse = 3 }
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
        id = "T_Bre_Mithril_Shield_01",
        craftableId = "T_Bre_Mithril_Shield_01",
        category = "Mithril",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_mithril", count = 8 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 4 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "T_Dwe_Regular_ShieldTower_01",
        craftableId = "T_Dwe_Regular_ShieldTower_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 6 }
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
        id = "T_Imp_ColGoatHide_Boots_01",
        craftableId = "T_Imp_ColGoatHide_Boots_01",
        category = "Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_goat", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_ColGoatHide_Greaves_01",
        craftableId = "T_Imp_ColGoatHide_Greaves_01",
        category = "Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_goat", count = 3 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_ColGoatHide_Helmet_01",
        craftableId = "T_Imp_ColGoatHide_Helmet_01",
        category = "Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_goat", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_BootsCol_01",
        craftableId = "T_Imp_Cm_BootsCol_01",
        category = "Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_BootsCol_02",
        craftableId = "T_Imp_Cm_BootsCol_02",
        category = "Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_BootsCol_03",
        craftableId = "T_Imp_Cm_BootsCol_03",
        category = "Fur",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_BootsCol_04",
        craftableId = "T_Imp_Cm_BootsCol_04",
        category = "Leather",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
        materials = {
            { material = "hap_leather", count = 2 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
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