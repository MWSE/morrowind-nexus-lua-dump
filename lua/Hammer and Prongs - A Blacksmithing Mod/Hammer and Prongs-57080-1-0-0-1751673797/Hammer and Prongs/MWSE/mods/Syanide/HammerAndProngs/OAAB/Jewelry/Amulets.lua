local recipes = {

	-- Armor

	{
        id = "AB_c_CommonAmulet01",
        craftableId = "AB_c_CommonAmulet01",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_resin", count = 1 },
            { material = "hap_silver", count = 1 },
            { material = "hap_bonemeal", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "AB_c_CommonAmulet02",
        craftableId = "AB_c_CommonAmulet02",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 1 },
            { material = "hap_bonemeal", count = 1 },
            { material = "hap_resin", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "AB_c_ExpensiveAmulet01",
        craftableId = "AB_c_ExpensiveAmulet01",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_silver", count = 1 },
            { material = "hap_diamond", count = 1 },
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "AB_c_ExtravagantAmulet01",
        craftableId = "AB_c_ExtravagantAmulet01",
		category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_glass", count = 1 },
            { material = "hap_gold", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "AB_c_ExquisiteAmulet01",
        craftableId = "AB_c_ExquisiteAmulet01",
		category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_diamond", count = 1 },
            { material = "hap_silver", count = 2 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 5 }
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

event.register("AB_Misc_File:Registered", registerRecipes)