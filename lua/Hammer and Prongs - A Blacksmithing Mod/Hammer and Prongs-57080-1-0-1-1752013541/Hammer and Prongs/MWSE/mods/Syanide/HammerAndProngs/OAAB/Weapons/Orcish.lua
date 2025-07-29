local recipes = {

	-- Weapons

    {
        id = "AB_w_OrcishMace",
        craftableId = "AB_w_OrcishMace",
		category = "Orcish",
        soundId = "Repair",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted.",
		materials = {
			{ material = "hap_orc", count = 6 }
		},
        toolRequirements = {
			{ tool = "master_hammer", count = 1, conditionPerUse = 4 }
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
        id = "AB_w_OrcishArrow",
        craftableId = "AB_w_OrcishArrow",
        category = "Orcish",
        description = "Requires a Master's Armorer's Hammer or greater to be crafted. Crafts 24 arrows.",
        previewMesh = "OAAB\\w\\w_orcish_arrow.nif",
        noResult = true,
        materials = {
            { material = "hap_orc", count = 4 },
            { material = "hap_plumes", count = 4 }
        },
        toolRequirements = {
            { tool = "master_hammer", count = 1, conditionPerUse = 4 }
        },
        craftCallback = function()
            local ref = tes3.player and tes3.player.reference or tes3.getReference("player")
            if ref then
                tes3.addItem({ reference = ref, item = "AB_w_OrcishArrow", count = 24 })
                local skillId = tes3.skill.armorer
                local progress = 2
                tes3.mobilePlayer:exerciseSkill(skillId, progress)
            else
                mwse.log("[HammerAndProngs] Could not add AB_w_OrcishArrow - invalid reference.")
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