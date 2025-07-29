local recipes = {

	-- Weapons

	{
        id = "T_Dwe_Regular_Arrow_01",
        craftableId = "T_Dwe_Regular_Arrow_01",
        category = "Dwemer",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
        noResult = true,
        previewMesh = "TR\\w\\tr_w_dwrv_arrow.nif",
        materials = {
            { material = "hap_dwemer", count = 3 },
            { material = "hap_plumes", count = 3 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Dwe_Regular_Arrow_01", count = 24 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
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
        id = "T_Dwe_Regular_Bolt_01",
        craftableId = "T_Dwe_Regular_Bolt_01",
        category = "Dwemer",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 12 bolts.",
        noResult = true,
        previewMesh = "TR\\w\\tr_w_dwrv_bolt.nif",
        materials = {
            { material = "hap_dwemer", count = 2 },
            { material = "hap_plumes", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 2 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Dwe_Regular_Bolt_01", count = 12 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
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
        id = "T_Dwe_Regular_Broadsword_01",
        craftableId = "T_Dwe_Regular_Broadsword_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 6 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 6 }
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
        id = "T_Dwe_Regular_Club_01",
        craftableId = "T_Dwe_Regular_Club_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 4 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 4 }
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
        id = "T_Dwe_Regular_CrossbowFix_01",
        craftableId = "T_Dwe_Regular_CrossbowFix_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 8 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 8 }
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
        id = "T_Dwe_Regular_Dagger_01",
        craftableId = "T_Dwe_Regular_Dagger_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Dwe_Regular_Greatmace_01",
        craftableId = "T_Dwe_Regular_Greatmace_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 8 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 8 }
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
        id = "T_Dwe_Regular_Junkstar",
        craftableId = "T_Dwe_Regular_Junkstar",
        category = "Dwemer",
        previewMesh = "tr\\w\\tr_w_dwrv_junkstar.nif",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 10 stars.",
        noResult = true,
        materials = {
            { material = "hap_dwemer", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 2 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Dwe_Regular_Junkstar", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
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
        id = "T_Dwe_Regular_Knife_01",
        craftableId = "T_Dwe_Regular_Knife_01",
        category = "Dwemer",
        previewMesh = "tr\\w\\tr_w_dwemer_knife.nif",
        noResult = true,
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 10 knives.",
        materials = {
            { material = "hap_dwemer", count = 3 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Dwe_Regular_Knife_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
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
        id = "T_Dwe_Regular_Longbow_01",
        craftableId = "T_Dwe_Regular_Longbow_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 6 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 6 }
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
        id = "T_Dwe_Regular_Longspear_01",
        craftableId = "T_Dwe_Regular_Longspear_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 8 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 8 }
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
        id = "T_Dwe_Regular_Longsword_01",
        craftableId = "T_Dwe_Regular_Longsword_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 6 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 6 }
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
        id = "T_Dwe_Regular_Staff_01",
        craftableId = "T_Dwe_Regular_Staff_01",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 6 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 6 }
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
        id = "T_Dwe_Regular_Staff_02",
        craftableId = "T_Dwe_Regular_Staff_02",
        category = "Dwemer",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dwemer", count = 6 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 6 }
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
        id = "T_Dwe_Regular_Star_01",
        craftableId = "T_Dwe_Regular_Star_01",
        previewMesh = "tr\\w\\tr_w_dwemer_star.nif",
        category = "Dwemer",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 10 stars.",
        noResult = true,
        materials = {
            { material = "hap_dwemer", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 2 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Dwe_Regular_Star_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            end
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