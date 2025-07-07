local recipes = {

	-- Weapons

    {
        id = "T_De_Bonemold_Dart_01", -- everything else
        craftableId = "T_De_Bonemold_Dart_01",
        category = "Bonemold",
        soundId = "Repair",
        previewMesh = "tr\\w\\tr_w_bone_dart.nif",
        noResult = true,
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 10 darts.",
        materials = {
            { material = "hap_bonemeal", count = 2 },
            { material = "hap_resin", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Bonemold_Dart_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Bonemold_Dart_01 - invalid reference.")
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
        id = "T_De_Bonemold_ThrowStar_01", -- stars
        craftableId = "T_De_Bonemold_ThrowStar_01",
        category = "Bonemold",
        soundId = "Repair",
        previewMesh = "tr\\w\\tr_w_bonemold_star.nif",
        noResult = true,
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted. Crafts 10 stars.",
        materials = {
            { material = "hap_bonemeal", count = 2 },
            { material = "hap_resin", count = 2 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Bonemold_ThrowStar_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Bonemold_ThrowStar_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
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