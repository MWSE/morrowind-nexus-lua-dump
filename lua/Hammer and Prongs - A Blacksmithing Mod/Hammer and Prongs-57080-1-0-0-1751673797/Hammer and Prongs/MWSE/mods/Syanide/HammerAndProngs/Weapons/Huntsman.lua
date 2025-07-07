local recipes = {

	-- Weapons

	{
        id = "BM huntsman axe",
        craftableId = "BM huntsman axe",
		category = "Huntsman",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron_ore", count = 2 },
            { material = "hap_wood", count = 1 }
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
        id = "BM huntsman war axe",
        craftableId = "BM huntsman war axe",
		category = "Huntsman",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron_ore", count = 4 },
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
        id = "BM huntsman longsword",
        craftableId = "BM huntsman longsword",
		category = "Huntsman",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron_ore", count = 3 },
            { material = "hap_wood", count = 1 }
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
        id = "BM huntsman spear",
        craftableId = "BM huntsman spear",
		category = "Huntsman",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron_ore", count = 5 },
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
        id = "BM huntsman crossbow",
        craftableId = "BM huntsman crossbow",
		category = "Huntsman",
        soundId = "Repair",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_iron_ore", count = 4 },
            { material = "hap_thread", count = 1 },
            { material = "hap_wood", count = 1 }
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
        id = "BM huntsmanbolt",
        craftableId = "BM huntsmanbolt",
        category = "Huntsman",
        description = "Requires an Apprentice's Armorer's Hammer or greater to be crafted. Crafts 12 bolts.",
        previewMesh = "w\\W_Huntsman_bolt.nif",
        noResult = true,
        materials = {
            { material = "hap_iron_ore", count = 1 },
            { material = "hap_plumes", count = 1 },
            { material = "hap_wood", count = 1 }
        },
        toolRequirements = {
            { tool = "low_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "wood bolt", count = 12 })
            else
                mwse.log("[HammerAndProngs] Could not add wood bolt - invalid reference.")
            end
        end,
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