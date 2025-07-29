local recipes = {

	-- Weapons

	{
        id = "T_De_Corkbulb_Dart_01",
        craftableId = "T_De_Corkbulb_Dart_01",
        category = "Corkbulb",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
        previewMesh = "tr\\w\\tr_w_cork_dart.nif",
        noResult = true,
        materials = {
            { material = "hap_corkbulb", count = 2 },
            { material = "hap_plumes", count = 2 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Corkbulb_Dart_01", count = 12 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Corkbulb_Dart_01 - invalid reference.")
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
        id = "T_De_Corkbulb_Bow_01",
        craftableId = "T_De_Corkbulb_Bow_01",
        category = "Corkbulb",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_corkbulb", count = 2 },
            { material = "hap_thread", count = 2 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 6 }
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
        id = "T_De_Corkbulb_Staff_01",
        craftableId = "T_De_Corkbulb_Staff_01",
        category = "Corkbulb",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_corkbulb", count = 3 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 4 }
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