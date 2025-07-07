local recipes = {

	-- Adamantium Weapons

    {
        id = "adamantium_arrow",
        craftableId = "T_Com_Adamant_Arrow_01",
		category = "Adamantium",
        previewMesh = "tr\\w\\tr_w_adamant_arrow.nif",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
		materials = {
			{ material = "hap_adamantium", count = 4 },
            { material = "hap_plumes", count = 4 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Adamant_Arrow_01", count = 24 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Adamant_Arrow_01 - invalid reference.")
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
        id = "adamantium_bolt",
        craftableId = "T_Com_Adamant_Bolt_01",
		category = "Adamantium",
        previewMesh = "tr\\w\\tr_w_adamant_bolt.nif",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 12 bolts.",
		materials = {
			{ material = "hap_adamantium", count = 3 },
            { material = "hap_plumes", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Adamant_Bolt_01", count = 12 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Adamant_Bolt_01 - invalid reference.")
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
        id = "adamantium_bow",
        craftableId = "T_Com_Adamant_Bow_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 8 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_broadsword",
        craftableId = "T_Com_Adamant_Broadsword_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_club",
        craftableId = "T_Com_Adamant_Club_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 6 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_crossbow",
        craftableId = "T_Com_Adamant_Crossbow_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 10 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_dagger",
        craftableId = "T_Com_Adamant_Dagger_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 4 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_daikatana",
        craftableId = "T_Com_Adamant_DaiKatana_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 10 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_dart",
        craftableId = "T_Com_Adamant_Dart",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 10 darts.",
		materials = {
			{ material = "hap_adamantium", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
		craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Adamant_Dart", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Adamant_Dart - invalid reference.")
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
        id = "adamantium_doubleaxe_01",
        craftableId = "T_Com_Adamant_DoubleAxe_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 10 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_doubleaxe_02",
        craftableId = "T_Com_Adamant_DoubleAxe_02",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 10 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_gisern",
        craftableId = "T_Com_Adamant_Gisern",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 10 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_halberd",
        craftableId = "T_Com_Adamant_Halberd_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 12 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_katana",
        craftableId = "T_Com_Adamant_Katana_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 10 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_knife",
        craftableId = "T_Com_Adamant_Knife",
		category = "Adamantium",
        noResult = true,
        previewMesh = "tr\\w\\tr_w_adamantium_knife.nif",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 10 knives.",
		materials = {
			{ material = "hap_adamantium", count = 4 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Adamant_Knife", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Adamant_Knife - invalid reference.")
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
        id = "adamantium_longsword",
        craftableId = "T_Com_Adamant_Longsword_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_saber",
        craftableId = "T_Com_Adamant_Saber_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 10 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_scimitar",
        craftableId = "T_Com_Adamant_Scimitar_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 10 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_staff",
        craftableId = "T_Com_Adamant_Staff_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_star",
        craftableId = "T_Com_Adamant_Star",
		category = "Adamantium",
        previewMesh = "pc\\w\\pc_w_admnt_star.nif",
        noResult = true,
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 10 stars.",
		materials = {
			{ material = "hap_adamantium", count = 3 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Adamant_Star", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 3
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Adamant_Star - invalid reference.")
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
        id = "adamantium_tanto",
        craftableId = "T_Com_Adamant_Tanto_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 6 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_wakizashi",
        craftableId = "T_Com_Adamant_Wakizashi_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_waraxe",
        craftableId = "T_Com_Adamant_WarAxe_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 6 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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
        id = "adamantium_warhammer",
        craftableId = "T_Com_Adamant_Warhammer_01",
		category = "Adamantium",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_adamantium", count = 10 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
		},
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 15
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

event.register("HammerAndProngs:OpenMenu:Registered", registerRecipes)