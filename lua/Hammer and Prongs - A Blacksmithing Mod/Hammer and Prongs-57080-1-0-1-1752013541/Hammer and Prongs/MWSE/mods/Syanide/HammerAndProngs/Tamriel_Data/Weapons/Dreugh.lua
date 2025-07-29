local recipes = {

	-- Weapons

    {
        id = "T_De_Dreugh_Arrow_01",
        craftableId = "T_De_Dreugh_Arrow_01",
        category = "Dreugh",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
        previewMesh = "tr\\w\\tr_w_dreugh_arrow.nif",
        noResult = true,
        materials = {
            { material = "hap_dreugh", count = 4 },
            { material = "hap_resin", count = 3 },
            { material = "hap_plumes", count = 4 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 4 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Dreugh_Arrow_01", count = 24 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Dreugh_Arrow_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
    },

    {
        id = "T_De_Dreugh_Bolt_01",
        craftableId = "T_De_Dreugh_Bolt_01",
        category = "Dreugh",
        previewMesh = "tr\\w\\tr_w_dreugh_bolt.nif",
        noResult = true,
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 12 bolts.",
        materials = {
            { material = "hap_dreugh", count = 3 },
            { material = "hap_resin", count = 3 },
            { material = "hap_plumes", count = 4 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 4 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Dreugh_Bolt_01", count = 12 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Dreugh_Bolt_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
    },

    {
        id = "T_De_Dreugh_Dagger_01",
        craftableId = "T_De_Dreugh_Dagger_01",
        category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dreugh", count = 4 },
            { material = "hap_resin", count = 3 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 4 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
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
        id = "T_De_Dreugh_Halberd",
        craftableId = "T_De_Dreugh_Halberd",
        category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dreugh", count = 12 },
            { material = "hap_resin", count = 3 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 4 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
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
        id = "T_De_Dreugh_Mace_01",
        craftableId = "T_De_Dreugh_Mace_01",
        category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dreugh", count = 6 },
            { material = "hap_resin", count = 3 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 4 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
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
        id = "T_De_Dreugh_Waraxe_01",
        craftableId = "T_De_Dreugh_Waraxe_01",
        category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_dreugh", count = 6 },
            { material = "hap_resin", count = 3 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 4 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 3
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
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