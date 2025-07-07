local recipes = {

	-- Weapons

    {
        id = "AB_w_DaedricScepter", -- everything else
        craftableId = "AB_w_DaedricScepter",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 14 }
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
        id = "AB_w_DaedricShortbow", -- bow
        craftableId = "AB_w_DaedricShortbow",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 14 },
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
        id = "AB_w_DaedricRapier", -- everything else
        craftableId = "AB_w_DaedricRapier",
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
        id = "AB_w_DaedricStar", -- stars
        craftableId = "AB_w_DaedricStar",
        category = "Daedric",
        soundId = "Repair",
        previewMesh = "OAAB\\w\\daedric_star.nif",
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
                tes3.addItem({ reference = ref, item = "AB_w_DaedricStar", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 5
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add AB_w_DaedricStar - invalid reference.")
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