local recipes = {

	-- Ebony Weapons

    {
        id = "tr_ebony_battleaxe",
        craftableId = "T_De_Ebony_Battleaxe_01",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 12 }
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
            return skillValue >= 90
        end
	},

    {
        id = "tr_ebony_bolt",
        craftableId = "T_De_Ebony_Bolt_01",
		category = "Ebony",
        soundId = "Repair",
        previewMesh = "tr\\w\\tr_w_ebony_bolt.nif",
        noResult = true,
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted. Crafts 12 bolts.",
		materials = {
			{ material = "hap_ebony", count = 4 },
            { material = "hap_plumes", count = 4 }
		},
        toolRequirements = {
			{ tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Ebony_Bolt_01", count = 12 })
                local skillId = tes3.skill.armorer
                local progress = 4
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Ebony_Bolt_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },


    {
        id = "tr_ebony_bow",
        craftableId = "T_De_Ebony_Bow_01",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 10 },
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
            return skillValue >= 90
        end
	},

    {
        id = "tr_ebony_claymore",
        craftableId = "T_De_Ebony_Claymore_01",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 12 }
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
            return skillValue >= 90
        end
	},

    {
        id = "tr_ebony_club",
        craftableId = "T_De_Ebony_Club_01",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 8 }
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
            return skillValue >= 90
        end
	},

    {
        id = "tr_ebony_crossbow",
        craftableId = "T_De_Ebony_Crossbow_01",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 12 },
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
            return skillValue >= 90
        end
	},

    {
        id = "tr_ebony_dagger",
        craftableId = "T_De_Ebony_Dagger_01",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 6 }
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
            return skillValue >= 90
        end
	},
    
    {
        id = "tr_ebony_daikatana",
        craftableId = "T_De_Ebony_DaiKatana_01",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 12 }
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
            return skillValue >= 90
        end
	},

    {
        id = "tr_ebony_halberd",
        craftableId = "T_De_Ebony_Halberd_01",
		category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_ebony", count = 14 }
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
            return skillValue >= 90
        end
	},

    {
        id = "tr_ebony_halberd_2",
        craftableId = "T_De_Ebony_Halberd_02",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 14 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_katana",
        craftableId = "T_De_Ebony_Katana_01",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_longspear",
        craftableId = "T_De_Ebony_Longspear_01",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_naginata",
        craftableId = "T_De_Ebony_Naginata_01",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_pickaxe",
        craftableId = "T_De_Ebony_Pickaxe_01",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 10 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_saber",
        craftableId = "T_De_Ebony_Saber_01",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_scythe",
        craftableId = "T_De_Ebony_Scythe",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_shortsword",
        craftableId = "T_De_Ebony_Shortsword_02",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 8 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_tanto",
        craftableId = "T_De_Ebony_Tanto_01",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 8 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_throwingknife",
        craftableId = "T_De_Ebony_ThrowingKnife_01",
        category = "Ebony",
        previewMesh = "tr\\w\\tr_w_ebony_knife.nif",
        noResult = true,
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted. Crafts 10 knives.",
        materials = {
            { material = "hap_ebony", count = 5 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Ebony_ThrowingKnife_01", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 4
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Ebony_ThrowingKnife_01 - invalid reference.")
            end
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_wakizashi",
        craftableId = "T_De_Ebony_Wakizashi_01",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 10 }
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
            return skillValue >= 90
        end
    },

    {
        id = "tr_ebony_warhammer",
        craftableId = "T_De_Ebony_Warhammer_01",
        category = "Ebony",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
        materials = {
            { material = "hap_ebony", count = 12 }
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

event.register("HammerAndProngs:OpenMenu:Registered", registerRecipes)