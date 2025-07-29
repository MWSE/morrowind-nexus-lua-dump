local recipes = {

	-- Armor

	{
        id = "common_amulet_01",
        craftableId = "common_amulet_01",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_resin", count = 1 },
            { material = "hap_gold", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "common_amulet_02",
        craftableId = "common_amulet_02",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 1 },
            { material = "hap_gold", count = 1 },
            { material = "hap_resin", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "common_amulet_03",
        craftableId = "common_amulet_03",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_bonemeal", count = 1 },
            { material = "hap_gold", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "common_amulet_04",
        craftableId = "common_amulet_04",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_amber", count = 1 },
            { material = "hap_gold", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "common_amulet_05",
        craftableId = "common_amulet_05",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 1 },
            { material = "hap_gold", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "expensive_amulet_01",
        craftableId = "expensive_amulet_01",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_firejade", count = 1 },
            { material = "hap_gold", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 3 }
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
        id = "expensive_amulet_02",
        craftableId = "expensive_amulet_02",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_topaz", count = 1 },
            { material = "hap_gold", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 3 }
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
        id = "expensive_amulet_03",
        craftableId = "expensive_amulet_03",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_silver", count = 1 },
            { material = "hap_gold", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 3 }
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
        id = "extravagant_amulet_01",
        craftableId = "extravagant_amulet_01",
		category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_sapphire", count = 1 },
            { material = "hap_gold", count = 1 },
            { material = "hap_firejade", count = 1 },
            { material = "hap_lapis", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "extravagant_amulet_02",
        craftableId = "extravagant_amulet_02",
		category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_ruby", count = 1 },
            { material = "hap_gold", count = 1 },
            { material = "hap_malachite", count = 1 }
		},
        toolRequirements = {
			{ tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "exquisite_amulet_01",
        craftableId = "exquisite_amulet_01",
		category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_ruby", count = 1 },
            { material = "hap_gold", count = 1 },
            { material = "hap_lapis", count = 1 },
            { material = "hap_sapphire", count = 1 },
            { material = "hap_emerald", count = 1 }
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