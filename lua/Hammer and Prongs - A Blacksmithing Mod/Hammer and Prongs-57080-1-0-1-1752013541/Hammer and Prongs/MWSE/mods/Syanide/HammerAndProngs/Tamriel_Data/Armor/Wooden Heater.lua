local recipes = {

	-- Armor

    {
        id = "T_Bre_WoodenHeater_Shield_01",
        craftableId = "T_Bre_WoodenHeater_Shield_01",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_wood", count = 2 },
            { material = "hap_iron", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_02",
        craftableId = "T_Bre_WoodenHeater_Shield_02",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_03",
        craftableId = "T_Bre_WoodenHeater_Shield_03",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_04",
        craftableId = "T_Bre_WoodenHeater_Shield_04",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_05",
        craftableId = "T_Bre_WoodenHeater_Shield_05",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_06",
        craftableId = "T_Bre_WoodenHeater_Shield_06",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_07",
        craftableId = "T_Bre_WoodenHeater_Shield_07",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_08",
        craftableId = "T_Bre_WoodenHeater_Shield_08",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_09",
        craftableId = "T_Bre_WoodenHeater_Shield_09",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_10",
        craftableId = "T_Bre_WoodenHeater_Shield_10",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_11",
        craftableId = "T_Bre_WoodenHeater_Shield_11",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_12",
        craftableId = "T_Bre_WoodenHeater_Shield_12",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_13",
        craftableId = "T_Bre_WoodenHeater_Shield_13",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_14",
        craftableId = "T_Bre_WoodenHeater_Shield_14",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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
        id = "T_Bre_WoodenHeater_Shield_15",
        craftableId = "T_Bre_WoodenHeater_Shield_15",
        category = "Wood",
        soundId = "Repair",
        description = "Requires a wooden shield to be crafted.",
        materials = {
            { material = "hap_paint", count = 2 },
            { material = "hap_wood_shield", count = 1 },
            { material = "hap_paintbrush", count = 1 }
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