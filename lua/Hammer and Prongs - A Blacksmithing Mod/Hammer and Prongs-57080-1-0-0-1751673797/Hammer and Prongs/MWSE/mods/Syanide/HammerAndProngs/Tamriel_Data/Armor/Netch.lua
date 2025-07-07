local recipes = {

    -- Armor
    {
        id = "T_De_Netch_Helm_01",
        craftableId = "T_De_Netch_Helm_01",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 2 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Netch_Helm_02",
        craftableId = "T_De_Netch_Helm_02",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 2 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_NetchRogue_Helm_01",
        craftableId = "T_De_NetchRogue_Helm_01",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 2 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_NetchRogue_Helm_02",
        craftableId = "T_De_NetchRogue_Helm_02",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 2 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_NetchStalker_Helm_01",
        craftableId = "T_De_NetchStalker_Helm_01",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 2 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Netch_Cuirass_01",
        craftableId = "T_De_Netch_Cuirass_01",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 5 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Netch_Cuirass_02",
        craftableId = "T_De_Netch_Cuirass_02",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 5 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Netch_Cuirass_03",
        craftableId = "T_De_Netch_Cuirass_03",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 5 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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
        id = "T_De_NetchRogue_Cuirass_01",
        craftableId = "T_De_NetchRogue_Cuirass_01",
		category = "Netch",
        soundId = "Item Clothes Up",
        description = "Requires an Apprentice's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 5 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_needle", count = 1, conditionPerUse = 5 }
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