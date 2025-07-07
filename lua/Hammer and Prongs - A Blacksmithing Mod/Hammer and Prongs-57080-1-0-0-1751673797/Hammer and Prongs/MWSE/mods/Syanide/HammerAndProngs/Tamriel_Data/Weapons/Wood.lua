local recipes = {

	-- Weapons

    {
        id = "T_De_Wooden_Staff_01",
        craftableId = "T_De_Wooden_Staff_01",
		category = "Wood",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_wood", count = 3 }
		},
        toolRequirements = {
			{ tool = "mid_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Wooden_Staff_02",
        craftableId = "T_De_Wooden_Staff_02",
		category = "Wood",
        soundId = "Repair",
        description = "Requires a Journeyman's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_wood", count = 3 }
		},
        toolRequirements = {
			{ tool = "mid_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_Com_Wood_Mace_01",
        craftableId = "T_Com_Wood_Mace_01",
		category = "Wood",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_wood", count = 2 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_Com_Wood_Club_01",
        craftableId = "T_Com_Wood_Club_01",
		category = "Wood",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_wood", count = 2 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_Com_Wood_Crossbow_01",
        craftableId = "T_Com_Wood_Crossbow_01",
		category = "Wood",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_wood", count = 4 },
            { material = "hap_thread", count = 1 }
		},
        toolRequirements = {
			{ tool = "low_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_Com_Wood_Arrow_01",
        craftableId = "T_Com_Wood_Arrow_01",
        category = "Wood",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
        previewMesh = "w\\w_arrow01.nif",
        noResult = true,
        materials = {
            { material = "hap_wood", count = 3 },
            { material = "hap_plumes", count = 3 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Wood_Arrow_01", count = 24 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Wood_Arrow_01 - invalid reference.")
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
        id = "T_Com_Wood_Bolt_01",
        craftableId = "T_Com_Wood_Bolt_01",
        category = "Wood",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 12 bolts.",
        previewMesh = "w\\w_bolt01.nif",
        noResult = true,
        materials = {
            { material = "hap_wood", count = 2 },
            { material = "hap_plumes", count = 3 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_Com_Wood_Bolt_01", count = 12 })
                local skillId = tes3.skill.armorer
                local progress = 1
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_Com_Wood_Bolt_01 - invalid reference.")
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