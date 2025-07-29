local recipes = {

	-- Armor

    {
        id = "T_Nor_Wood_ShieldBuckler_01",
        craftableId = "T_Nor_Wood_ShieldBuckler_01",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Nor_Wood_ShieldBuckler_02",
        craftableId = "T_Nor_Wood_ShieldBuckler_02",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Nor_Wood_ShieldBuckler_03",
        craftableId = "T_Nor_Wood_ShieldBuckler_03",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Nor_Wood_ShieldBuckler_04",
        craftableId = "T_Nor_Wood_ShieldBuckler_04",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Nor_Wood_ShieldBuckler_05",
        craftableId = "T_Nor_Wood_ShieldBuckler_05",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Nor_Wood_ShieldBuckler_06",
        craftableId = "T_Nor_Wood_ShieldBuckler_06",
        category = "Wood",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_wood", count = 2 },
            { material = "hap_iron", count = 1 }
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
        id = "T_Nor_Wood_ShieldBuckler_07",
        craftableId = "T_Nor_Wood_ShieldBuckler_07",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Nor_Wood_ShieldBuckler_08",
        craftableId = "T_Nor_Wood_ShieldBuckler_08",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Nor_Wood_Shield_01",
        craftableId = "T_Nor_Wood_Shield_01",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Nor_Wood_Shield_02",
        craftableId = "T_Nor_Wood_Shield_02",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Nor_Wood_Shield_03",
        craftableId = "T_Nor_Wood_Shield_03",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden buckler to be crafted.",
        materials = {
            { material = "hap_wood_buckler", count = 1 },
            { material = "hap_paint", count = 2 },
            { material = "hap_paintbrush", count = 1 }
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