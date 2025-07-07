local recipes = {

	-- Weapons

    {
        id = "AB_w_DreughClaymore",
        craftableId = "AB_w_DreughClaymore",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 10 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughBattleAxe",
        craftableId = "AB_w_DreughBattleAxe",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 10 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughWarAxe",
        craftableId = "AB_w_DreughWarAxe",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 6 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughGreatmace",
        craftableId = "AB_w_DreughGreatmace",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 8 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughMace",
        craftableId = "AB_w_DreughMace",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 6 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughDagger",
        craftableId = "AB_w_DreughDagger",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 4 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughLongsword",
        craftableId = "AB_w_DreughLongsword",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 8 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughShortsword",
        craftableId = "AB_w_DreughShortsword",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 6 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughSpear",
        craftableId = "AB_w_DreughSpear",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 10 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughHalberd",
        craftableId = "AB_w_DreughHalberd",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 12 },
            { material = "hap_resin", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughShortbow",
        craftableId = "AB_w_DreughShortbow",
		category = "Dreugh",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_dreugh", count = 6 },
            { material = "hap_resin", count = 3 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "AB_w_DreughArrow",
        craftableId = "AB_w_DreughArrow",
        category = "Dreugh",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
        previewMesh = "OAAB\\w\\Dreugh_arrow.nif",
        noResult = true,
        materials = {
            { material = "hap_dreugh", count = 4 },
            { material = "hap_resin", count = 3 },
            { material = "hap_plumes", count = 4 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "AB_w_DreughArrow", count = 24 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add AB_w_DreughArrow - invalid reference.")
            end
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

event.register("HammerAndProngs:OpenMenu:Registered", registerRecipes)