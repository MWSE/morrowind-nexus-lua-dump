local recipes = {

    -- Weapons

    {
        id = "T_De_Chitin_Bolt_01",
        craftableId = "T_De_Chitin_Bolt_01",
        category = "Chitin",
        previewMesh = "TR\\w\\tr_w_chitin_bolt.nif",
        noResult = true,
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 12 bolts.",
        materials = {
            { material = "hap_chitin", count = 1 },  -- Bolts = 2
            { material = "hap_resin", count = 1 },
            { material = "hap_plumes", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Chitin_Bolt_01", count = 12 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Chitin_Bolt_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
    },

    {
        id = "T_De_Chitin_Crossbow",
        craftableId = "T_De_Chitin_Crossbow",
        category = "Chitin",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_chitin", count = 8 },  -- Crossbow = 8
            { material = "hap_resin", count = 1 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Chitin_Dart_01",
        craftableId = "T_De_Chitin_Dart_01",
        category = "Chitin",
        previewMesh = "tr\\w\\tr_w_chitin_dart.nif",
        noResult = true,
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 10 darts.",
        materials = {
            { material = "hap_chitin", count = 1 },  -- Darts = 2
            { material = "hap_resin", count = 1 },
            { material = "hap_plumes", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Chitin_Dart_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Chitin_Dart_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
    },

    {
        id = "T_De_Chitin_Javelin_01",
        craftableId = "T_De_Chitin_Javelin_01",
        category = "Chitin",
        previewMesh = "tr\\w\\tr_w_chitin_javelin_01.nif",
        noResult = true,
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 3 javelins.",
        materials = {
            { material = "hap_chitin", count = 6 },  -- Javelin = 6
            { material = "hap_resin", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Chitin_Javelin_01", count = 3 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Chitin_Javelin_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
    },

    {
        id = "T_De_Chitin_Longsword_01",
        craftableId = "T_De_Chitin_Longsword_01",
        category = "Chitin",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_chitin", count = 6 },  -- Longswords = 6
            { material = "hap_resin", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Chitin_Mace_01",
        craftableId = "T_De_Chitin_Mace_01",
        category = "Chitin",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_chitin", count = 4 },  -- Club/Truncheon/Morningstar (Mace category) = 4
            { material = "hap_resin", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Chitin_Sickle_01",
        craftableId = "T_De_Chitin_Sickle_01",
        category = "Chitin",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_chitin", count = 1 },  -- No exact guide, same as original example uses 1
            { material = "hap_resin", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Chitin_Staff",
        craftableId = "T_De_Chitin_Staff",
        category = "Chitin",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_chitin", count = 6 },  -- Staff = 6
            { material = "hap_resin", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
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