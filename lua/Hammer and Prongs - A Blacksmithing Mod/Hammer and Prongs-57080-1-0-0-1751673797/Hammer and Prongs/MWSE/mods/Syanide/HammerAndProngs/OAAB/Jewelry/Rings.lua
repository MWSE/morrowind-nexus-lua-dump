local recipes = {

	-- Armor

	{
        id = "AB_c_CommonRing01",
        craftableId = "AB_c_CommonRing01",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 1 }
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
        id = "AB_c_CommonRing02",
        craftableId = "AB_c_CommonRing02",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
            { material = "hap_netch_leather", count = 1 }
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
        id = "AB_c_ExpensiveRing01",
        craftableId = "AB_c_ExpensiveRing01",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 },
            { material = "hap_bronze", count = 1 }
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
        id = "AB_c_ExpensiveRing02",
        craftableId = "AB_c_ExpensiveRing02",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_ruby", count = 3 },
            { material = "hap_ebony", count = 1 }
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
        id = "AB_c_ExpensiveRing03",
        craftableId = "AB_c_ExpensiveRing03",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 1 },
            { material = "hap_gold", count = 1 }
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
        id = "AB_c_ExtravagantRing01",
        craftableId = "AB_c_ExtravagantRing01",
		category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_ruby", count = 1 },
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
        id = "AB_c_ExtravagantRing02",
        craftableId = "AB_c_ExtravagantRing02",
		category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_silver", count = 1 },
            { material = "hap_emerald", count = 1 }
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
        id = "AB_c_ExquisiteRing01",
        craftableId = "AB_c_ExquisiteRing01",
		category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_tourmaline", count = 1 },
            { material = "hap_silver", count = 1 }
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