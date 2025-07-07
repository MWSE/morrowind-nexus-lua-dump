local recipes = {

	-- Weapons

    {
        id = "T_Dae_Regular_Bolt_01", -- bolts
        craftableId = "T_Dae_Regular_Bolt_01",
        category = "Daedric",
        soundId = "Repair",
        previewMesh = "tr\\w\\tr_w_daedra_bolt.nif",
        noResult = true,
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted. Crafts 12 bolts",
        materials = {
            { material = "hap_daedric", count = 5 },
            { material = "hap_plumes", count = 5 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Dae_Regular_Bolt_01", count = 12 })
                local skillId = tes3.skill.armorer
                local progress = 5
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Dae_Regular_Bolt_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_Broadsword_01", -- everything else
        craftableId = "T_Dae_Regular_Broadsword_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_Crossbow_01", -- bow
        craftableId = "T_Dae_Regular_Crossbow_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_GSword_01", -- everything else
        craftableId = "T_Dae_Regular_GSword_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_Halberd_01", -- everything else
        craftableId = "T_Dae_Regular_Halberd_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 20 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_Longspear_01", -- everything else
        craftableId = "T_Dae_Regular_Longspear_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_Longsword_01", -- everything else
        craftableId = "T_Dae_Regular_Longsword_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 16 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_Naginata_01", -- everything else
        craftableId = "T_Dae_Regular_Naginata_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_Saber_01", -- everything else
        craftableId = "T_Dae_Regular_Saber_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_Scimitar_01", -- everything else
        craftableId = "T_Dae_Regular_Scimitar_01",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 18 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 5
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_ThrowingKnife_01", -- knifes
        craftableId = "T_Dae_Regular_ThrowingKnife_01",
        category = "Daedric",
        soundId = "Repair",
        previewMesh = "tr\\w\\tr_w_dae_throwkinfe.nif",
        noResult = true,
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted. Crafts 10 knifes",
        materials = {
            { material = "hap_daedric", count = 6 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Dae_Regular_ThrowingKnife_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 5
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Dae_Regular_ThrowingKnife_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
        end
    },

    {
        id = "T_Dae_Regular_ThrowingStar_01", -- stars
        craftableId = "T_Dae_Regular_ThrowingStar_01",
        category = "Daedric",
        soundId = "Repair",
        previewMesh = "tr\\w\\tr_w_daedric_star.nif",
        noResult = true,
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted. Crafts 10 stars",
        materials = {
            { material = "hap_daedric", count = 5 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Dae_Regular_ThrowingStar_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 5
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Dae_Regular_ThrowingStar_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 115
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