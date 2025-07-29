local recipes = {

	-- Armor

	{
        id = "daedric arrow",
        craftableId = "daedric arrow",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
        materials = {
            { material = "hap_daedric", count = 6 },
            { material = "hap_plumes", count = 6 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "daedric arrow", count = 24 })
                -- Exercise Armorer skill
                local skillId = tes3.skill.armorer
                local progress = 5
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add daedric arrow - invalid reference.")
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
        id = "daedric battle axe",
        craftableId = "daedric battle axe",
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
        id = "daedric claymore",
        craftableId = "daedric claymore",
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
        id = "daedric club",
        craftableId = "daedric club",
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
        id = "daedric dagger",
        craftableId = "daedric dagger",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 12 }
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
        id = "daedric dai-katana",
        craftableId = "daedric dai-katana",
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
        id = "daedric dart",
        craftableId = "daedric dart",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted. Crafts 10 darts.",
        materials = {
            { material = "hap_daedric", count = 5 }
        },
        toolRequirements = {
            { tool = "secret_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "daedric dart", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 5
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add daedric dart - invalid reference.")
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
        id = "daedric katana",
        craftableId = "daedric katana",
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
        id = "daedric long bow",
        craftableId = "daedric long bow",
        category = "Daedric",
        soundId = "Repair",
        description = "Requires a Secret Master's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_daedric", count = 16 },
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
        id = "daedric longsword",
        craftableId = "daedric longsword",
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
        id = "daedric mace",
        craftableId = "daedric mace",
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
        id = "daedric shortsword",
        craftableId = "daedric shortsword",
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
        id = "daedric spear",
        craftableId = "daedric spear",
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
        id = "daedric staff",
        craftableId = "daedric staff",
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
        id = "daedric tanto",
        craftableId = "daedric tanto",
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
        id = "daedric wakizashi",
        craftableId = "daedric wakizashi",
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
        id = "daedric war axe",
        craftableId = "daedric war axe",
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
        id = "daedric warhammer",
        craftableId = "daedric warhammer",
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