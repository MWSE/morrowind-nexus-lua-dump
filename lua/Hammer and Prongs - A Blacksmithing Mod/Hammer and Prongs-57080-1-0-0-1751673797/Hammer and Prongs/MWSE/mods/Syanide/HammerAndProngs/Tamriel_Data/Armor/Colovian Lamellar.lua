local recipes = {

	-- Armor

{
    id = "T_Imp_ColLamellar_Boots_01",
    craftableId = "T_Imp_ColLamellar_Boots_01",
    category = "Lamellar",
    soundId = "Repair",
    description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
    materials = {
        { material = "hap_steel", count = 3 },
        { material = "hap_fur", count = 2 }
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
        id = "T_Imp_ColLamellar_BracerL_01",
        craftableId = "T_Imp_ColLamellar_BracerL_01",
        category = "Lamellar",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 4 },
            { material = "hap_fur", count = 2 }
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
        id = "T_Imp_ColLamellar_BracerR_01",
        craftableId = "T_Imp_ColLamellar_BracerR_01",
        category = "Lamellar",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 4 },
            { material = "hap_fur", count = 2 }
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
        id = "T_Imp_ColLamellar_Cuirass_01",
        craftableId = "T_Imp_ColLamellar_Cuirass_01",
        category = "Lamellar",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 10 },
            { material = "hap_fur", count = 2 }
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
        id = "T_Imp_ColLamellar_Greaves_01",
        craftableId = "T_Imp_ColLamellar_Greaves_01",
        category = "Lamellar",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 6 },
            { material = "hap_fur", count = 2 }
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
        id = "T_Imp_ColLamellar_HelmOpen_01",
        craftableId = "T_Imp_ColLamellar_HelmOpen_01",
        category = "Lamellar",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 4 },
            { material = "hap_fur", count = 2 }
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
        id = "T_Imp_ColLamellar_Helm_01",
        craftableId = "T_Imp_ColLamellar_Helm_01",
        category = "Lamellar",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 4 },
            { material = "hap_fur", count = 2 },
            { material = "hap_cloth", count = 1 }
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
        id = "T_Imp_ColLamellar_PauldronL_01",
        craftableId = "T_Imp_ColLamellar_PauldronL_01",
        category = "Lamellar",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 6 },
            { material = "hap_fur", count = 2 }
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
        id = "T_Imp_ColLamellar_PauldronR_01",
        craftableId = "T_Imp_ColLamellar_PauldronR_01",
        category = "Lamellar",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 6 },
            { material = "hap_fur", count = 2 }
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