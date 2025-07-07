local recipes = {

    -- Glass Weapons

    {
        id = "T_De_Glass_BattleAxe_01",
        craftableId = "T_De_Glass_BattleAxe_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 8 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Bolt_01",
        craftableId = "T_De_Glass_Bolt_01",
        category = "Glass",
        previewMesh = "tr\\w\\tr_w_glass_bolt.nif",
        noResult = true,
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted. Crafts 12 bolts.",
        materials = {
            { material = "hap_glass", count = 4 },
            { material = "hap_plumes", count = 4 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Glass_Bolt_01", count = 12 })
                local skillId = tes3.skill.armorer
                local progress = 4
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Glass_Bolt_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Bow_01",
        craftableId = "T_De_Glass_Bow_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 10 },
            { material = "hap_thread", count = 1 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Broadsword_01",
        craftableId = "T_De_Glass_Broadsword_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 10 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Club_01",
        craftableId = "T_De_Glass_Club_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 8 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_DaiKatana_01",
        craftableId = "T_De_Glass_DaiKatana_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Dart_01",
        craftableId = "T_De_Glass_Dart_01",
        category = "Glass",
        previewMesh = "tr\\w\\tr_w_glass_dart.nif",
        noResult = true,
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted. Crafts 10 darts.",
        materials = {
            { material = "hap_glass", count = 4 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Glass_Dart_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 4
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Glass_Dart_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Katana_01",
        craftableId = "T_De_Glass_Katana_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Longspear_01",
        craftableId = "T_De_Glass_Longspear_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Mace_01",
        craftableId = "T_De_Glass_Mace_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 8 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Naginata_01",
        craftableId = "T_De_Glass_Naginata_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Shortsword_01",
        craftableId = "T_De_Glass_Shortsword_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 8 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Shortsword_02",
        craftableId = "T_De_Glass_Shortsword_02",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 8 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Wakizashi_01",
        craftableId = "T_De_Glass_Wakizashi_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 10 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "T_De_Glass_Warhammer_01",
        craftableId = "T_De_Glass_Warhammer_01",
        category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_glass", count = 12 }
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
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
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