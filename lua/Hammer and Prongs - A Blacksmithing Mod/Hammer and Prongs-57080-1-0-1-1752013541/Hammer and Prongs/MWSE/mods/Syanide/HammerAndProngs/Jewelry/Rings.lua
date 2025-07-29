local recipes = {

	-- Armor

	{
        id = "common_ring_01",
        craftableId = "common_ring_01",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 }
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
        id = "common_ring_02",
        craftableId = "common_ring_02",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
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
        id = "common_ring_03",
        craftableId = "common_ring_03",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 1 },
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
        id = "common_ring_04",
        craftableId = "common_ring_04",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_bronze", count = 1 }
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
        id = "common_ring_05",
        craftableId = "common_ring_05",
		category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_copper", count = 1 },
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
        id = "expensive_ring_01",
        craftableId = "expensive_ring_01",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_emerald", count = 1 },
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
        id = "expensive_ring_02",
        craftableId = "expensive_ring_02",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_sapphire", count = 1 },
            { material = "hap_silver", count = 1 }
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
        id = "expensive_ring_03",
        craftableId = "expensive_ring_03",
		category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_ruby", count = 1 },
            { material = "hap_steel", count = 1 }
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
        id = "extravagant_ring_01",
        craftableId = "extravagant_ring_01",
		category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_amethyst", count = 1 },
            { material = "hap_silver", count = 1 }
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
        id = "extravagant_ring_02",
        craftableId = "extravagant_ring_02",
		category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_khajiiteye", count = 1 },
            { material = "hap_dreugh", count = 1 }
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
        id = "exquisite_ring_01",
        craftableId = "exquisite_ring_01",
		category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
		materials = {
			{ material = "hap_stardiopside", count = 3 },
            { material = "hap_silver", count = 1 }
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