local recipes = {

	-- Weapons

    {
        id = "T_Orc_Regular_BattleAxe_01",
        craftableId = "T_Orc_Regular_BattleAxe_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 10 }
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
        id = "T_Orc_Regular_Waraxe_01",
        craftableId = "T_Orc_Regular_Waraxe_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 6 }
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
        id = "T_Orc_Regular_Bow_01",
        craftableId = "T_Orc_Regular_Bow_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 6 },
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
        id = "T_Orc_Regular_Claymore_01",
        craftableId = "T_Orc_Regular_Claymore_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 10 }
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
        id = "T_Orc_Regular_Dagger_01",
        craftableId = "T_Orc_Regular_Dagger_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 4 }
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
        id = "T_Orc_Regular_Dagger_02",
        craftableId = "T_Orc_Regular_Dagger_02",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 4 }
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
        id = "T_Orc_Regular_Crossbow_01",
        craftableId = "T_Orc_Regular_Crossbow_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 10 },
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
        id = "T_Orc_Regular_Halberd_01",
        craftableId = "T_Orc_Regular_Halberd_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 12 }
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
        id = "T_Orc_Regular_Longspear_01",
        craftableId = "T_Orc_Regular_Longspear_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 12 }
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
        id = "T_Orc_Regular_Spear_01",
        craftableId = "T_Orc_Regular_Spear_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 10 }
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
        id = "T_Orc_Regular_Spear_02",
        craftableId = "T_Orc_Regular_Spear_02",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 10 }
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
        id = "T_Orc_Regular_Mace_01",
        craftableId = "T_Orc_Regular_Mace_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 6 }
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
        id = "T_Orc_Regular_Staff_01",
        craftableId = "T_Orc_Regular_Staff_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 8 }
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
        id = "T_Orc_Regular_Longsword_01",
        craftableId = "T_Orc_Regular_Longsword_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 8 }
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
        id = "T_Orc_regular_club_01",
        craftableId = "T_Orc_regular_club_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 6 }
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
        id = "T_Orc_Regular_shortsword_01",
        craftableId = "T_Orc_Regular_shortsword_01",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 6 }
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
        id = "T_Orc_Orcish_Arrow",
        craftableId = "T_Orc_Orcish_Arrow",
        category = "Orcish",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
        previewMesh = "tr\\w\\tr_w_orcish_arrow.nif",
        noResult = true,
        materials = {
            { material = "hap_orc", count = 4 },
            { material = "hap_plumes", count = 4 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Orc_Orcish_Arrow", count = 24 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Orc_Orcish_Arrow - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
    },

    {
        id = "T_Orc_Regular_Dart_01",
        craftableId = "T_Orc_Regular_Dart_01",
        category = "Orcish",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 10 darts.",
        previewMesh = "tr\\w\\tr_w_orcish_dart.nif",
        noResult = true,
        materials = {
            { material = "hap_orc", count = 3 },
            { material = "hap_plumes", count = 3 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Orc_Regular_Dart_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Orc_Regular_Dart_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
    },

    {
        id = "T_Orc_Regular_ThrowingKnife_01",
        craftableId = "T_Orc_Regular_ThrowingKnife_01",
        category = "Orcish",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 10 knives.",
        previewMesh = "tr\\w\\tr_w_orcish_knife.nif",
        noResult = true,
        materials = {
            { material = "hap_orc", count = 4 },
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Orc_Regular_ThrowingKnife_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Orc_Regular_ThrowingKnife_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
        end
    },

    {
        id = "T_Orc_Regular_ThrowingStar_01",
        craftableId = "T_Orc_Regular_ThrowingStar_01",
        category = "Orcish",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 10 stars.",
        previewMesh = "tr\\w\\tr_w_orcish_star.nif",
        noResult = true,
        materials = {
            { material = "hap_orc", count = 3 },
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Orc_Regular_ThrowingStar_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Orc_Regular_ThrowingStar_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 60
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