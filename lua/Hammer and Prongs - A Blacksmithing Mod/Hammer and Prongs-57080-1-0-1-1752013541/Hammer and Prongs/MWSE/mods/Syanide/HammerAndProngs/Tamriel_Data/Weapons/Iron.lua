local recipes = {

	-- Weapons

	{
        id = "T_Com_Iron_Warpick_01",
        craftableId = "T_Com_Iron_Warpick_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Truncheon_01",
        craftableId = "T_Com_Iron_Truncheon_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Morningstar_01",
        craftableId = "T_Com_Iron_Morningstar_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 3 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_GreatMace_01",
        craftableId = "T_Com_Iron_GreatMace_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 3 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Warhammer_01",
        craftableId = "T_Com_Iron_Warhammer_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Staff_01",
        craftableId = "T_Com_Iron_Staff_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 3 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Longhammer_01",
        craftableId = "T_Com_Iron_Longhammer_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Dagger_01",
        craftableId = "T_Com_Iron_Dagger_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Dagger_02",
        craftableId = "T_Com_Iron_Dagger_02",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Dagger_03",
        craftableId = "T_Com_Iron_Dagger_03",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Tanto_01",
        craftableId = "T_Com_Iron_Tanto_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Tanto_02",
        craftableId = "T_Com_Iron_Tanto_02",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Tanto_03",
        craftableId = "T_Com_Iron_Tanto_03",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Tanto_04",
        craftableId = "T_Com_Iron_Tanto_04",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Broadsword_01",
        craftableId = "T_Com_Iron_Broadsword_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 3 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Broadsword_02",
        craftableId = "T_Com_Iron_Broadsword_02",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 3 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Broadsword_03",
        craftableId = "T_Com_Iron_Broadsword_03",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 3 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Rapier_01",
        craftableId = "T_Com_Iron_Rapier_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 3 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Saber_01",
        craftableId = "T_Com_Iron_Saber_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Saber_02",
        craftableId = "T_Com_Iron_Saber_02",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Saber_03",
        craftableId = "T_Com_Iron_Saber_03",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Scimitar_01",
        craftableId = "T_Com_Iron_Scimitar_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_katana_01",
        craftableId = "T_Com_Iron_katana_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 4 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_GSword_01",
        craftableId = "T_Com_Iron_GSword_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 5 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Daikatana_01",
        craftableId = "T_Com_Iron_Daikatana_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 5 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Longspear_01",
        craftableId = "T_Com_Iron_Longspear_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 5 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Naginata_01",
        craftableId = "T_Com_Iron_Naginata_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 5 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Shortbow_01",
        craftableId = "T_Com_Iron_Shortbow_01",
		category = "Iron",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron", count = 2 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 2 }
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
        id = "T_Com_Iron_Dart_01",
        craftableId = "T_Com_Iron_Dart_01",
        category = "Iron",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 10 darts.",
        previewMesh = "tr\\w\\tr_w_iron_dart.nif",
        noResult = true,
        materials = {
            { material = "hap_iron", count = 2 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Iron_Dart_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Iron_Dart_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
    },

    {
        id = "T_Com_Iron_Star_01",
        craftableId = "T_Com_Iron_Star_01",
        category = "Iron",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 10 stars.",
        previewMesh = "tr\\w\\tr_w_iron_star.nif",
        noResult = true,
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Iron_Star_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Iron_Star_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
    },

    {
        id = "T_Com_Iron_ThrowingKnife_01",
        craftableId = "T_Com_Iron_ThrowingKnife_01",
        category = "Iron",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 10 knives.",
        previewMesh = "w\\w_knife_iron.nif",
        noResult = true,
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Iron_ThrowingKnife_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Iron_ThrowingKnife_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
    },

    {
        id = "T_Com_Iron_ThrowingKnife_02",
        craftableId = "T_Com_Iron_ThrowingKnife_02",
        category = "Iron",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 10 knives.",
        previewMesh = "TR\\w\\TR_w_iron_tknife_02.nif",
        noResult = true,
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Iron_ThrowingKnife_02", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Iron_ThrowingKnife_02 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 15
        end
    },

    {
        id = "T_Com_Iron_Javelin_01",
        craftableId = "T_Com_Iron_Javelin_01",
        category = "Iron",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 3 Javelins.",
        previewMesh = "tr\\w\\tr_w_iron_javelin_01.nif",
        noResult = true,
        materials = {
            { material = "hap_iron", count = 5 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 2 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Iron_Javelin_01", count = 3 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Iron_Javelin_01 - invalid reference.")
            end
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