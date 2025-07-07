local recipes = {

	-- Weapons

	{
        id = "T_De_Ashlander_Dagger_01",
        craftableId = "T_De_Ashlander_Dagger_01",
		category = "Ashlander",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass_raw", count = 6 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Ashlander_Staff_01",
        craftableId = "T_De_Ashlander_Staff_01",
		category = "Ashlander",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass_raw", count = 10 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Ashlander_Club_01",
        craftableId = "T_De_Ashlander_Club_01",
		category = "Ashlander",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass_raw", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Ashlander_ShortSword_01",
        craftableId = "T_De_Ashlander_ShortSword_01",
		category = "Ashlander",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass_raw", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Ashlander_Spear_01",
        craftableId = "T_De_Ashlander_Spear_01",
		category = "Ashlander",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass_raw", count = 12 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Ashlander_Waraxe_01",
        craftableId = "T_De_Ashlander_Waraxe_01",
		category = "Ashlander",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_glass_raw", count = 8 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 5 }
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
        id = "T_De_Ashlander_Arrow_01",
        craftableId = "T_De_Ashlander_Arrow_01",
        category = "Ashlander",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
        previewMesh = "tr\\w\\tr_w_rawglass_arrow.nif",
        noResult = true,
        materials = {
            { material = "hap_glass_raw", count = 5 },
            { material = "hap_plumes", count = 5 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 5 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "T_De_Ashlander_Arrow_01", count = 24 })
                local skillId = tes3.skill.armorer
                local progress = 4
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add T_De_Ashlander_Arrow_01 - invalid reference.")
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