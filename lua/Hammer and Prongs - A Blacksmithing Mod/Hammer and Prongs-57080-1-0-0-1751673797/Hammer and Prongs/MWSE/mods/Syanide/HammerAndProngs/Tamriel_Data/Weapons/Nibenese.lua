local recipes = {

	-- Weapons

    {
        id = "T_Imp_Nibenese_Daikatana_01", -- everything else
        craftableId = "T_Imp_Nibenese_Daikatana_01",
        category = "Nibenese",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 8 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Nibenese_Katana_01", -- everything else
        craftableId = "T_Imp_Nibenese_Katana_01",
        category = "Nibenese",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_steel", count = 6 }
        },
        toolRequirements = {
            { tool = "mid_hammer", count = 1, conditionPerUse = 5 }
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