local recipes = {

	-- Weapons

	{
        id = "AB_w_GlassBattleAxe",
        craftableId = "AB_w_GlassBattleAxe",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 12 }
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
        id = "AB_w_GlassScepter",
        craftableId = "AB_w_GlassScepter",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 10 }
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
        id = "AB_w_GlassMace",
        craftableId = "AB_w_GlassMace",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 8 }
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
        id = "AB_w_GlassTanto",
        craftableId = "AB_w_GlassTanto",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 8 }
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
        id = "AB_w_GlassWakizashi",
        craftableId = "AB_w_GlassWakizashi",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 10 }
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
        id = "AB_w_GlassSaber",
        craftableId = "AB_w_GlassSaber",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 12 }
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
        id = "AB_w_GlassDkatana",
        craftableId = "AB_w_GlassDkatana",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 12 }
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
        id = "AB_w_GlassKatana",
        craftableId = "AB_w_GlassKatana",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 12 }
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
        id = "AB_w_GlassSpear",
        craftableId = "AB_w_GlassSpear",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 14 }
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
        id = "AB_w_GlassShortbow",
        craftableId = "AB_w_GlassShortbow",
		category = "Glass",
        soundId = "Repair",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass", count = 8 },
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
        id = "AB_w_GlassDart",
        craftableId = "AB_w_GlassDart",
        category = "Glass",
        description = "Requires a Grandmaster's Armorer's Hammer or greater to be crafted. Crafts 10 darts.",
        previewMesh = "OAAB\\w\\w_dart_glass.nif",
        noResult = true,
        materials = {
            { material = "hap_glass", count = 4 },
            { material = "hap_plumes", count = 4 }
        },
        toolRequirements = {
            { tool = "grand_master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "AB_w_GlassDart", count = 10 })
                local skillId = tes3.skill.armorer
                local progress = 4
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add AB_w_GlassDart - invalid reference.")
            end
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