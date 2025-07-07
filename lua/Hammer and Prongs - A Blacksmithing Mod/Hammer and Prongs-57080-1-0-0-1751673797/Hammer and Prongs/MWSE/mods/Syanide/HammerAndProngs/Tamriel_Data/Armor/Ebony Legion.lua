local recipes = {

	{
        id = "T_Imp_Ebony_Boots",
        craftableId = "T_Imp_Ebony_Boots",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 9 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_BracerL",
        craftableId = "T_Imp_Ebony_BracerL",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_BracerR",
        craftableId = "T_Imp_Ebony_BracerR",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_Cuirass",
        craftableId = "T_Imp_Ebony_Cuirass",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 30 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_Helmet_01",
        craftableId = "T_Imp_Ebony_Helmet_01",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_Helmet_02",
        craftableId = "T_Imp_Ebony_Helmet_02",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_Helmet_02b",
        craftableId = "T_Imp_Ebony_Helmet_02b",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_Helmet_03",
        craftableId = "T_Imp_Ebony_Helmet_03",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_Helmet_03b",
        craftableId = "T_Imp_Ebony_Helmet_03b",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_PauldronL",
        craftableId = "T_Imp_Ebony_PauldronL",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 21 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_PauldronR",
        craftableId = "T_Imp_Ebony_PauldronR",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 21 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
        end
    },

    {
        id = "T_Imp_Ebony_ShieldTower_01",
        craftableId = "T_Imp_Ebony_ShieldTower_01",
        category = "Legion",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 18 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 4
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isImperialLegion() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 90
                end
            end
            return false
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