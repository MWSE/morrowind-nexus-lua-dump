local recipes = {

	-- Weapons

    {
        id = "AB_w_NordicSilverBow",
        craftableId = "AB_w_NordicSilverBow",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 5 },
            { material = "hap_silver", count = 5 },
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
            return skillValue >= 100
        end
	},

    {
        id = "AB_w_NordicSilverSpear",
        craftableId = "AB_w_NordicSilverSpear",
		category = "Nordic",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_steel", count = 6 },
            { material = "hap_silver", count = 6 }
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
            return skillValue >= 100
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