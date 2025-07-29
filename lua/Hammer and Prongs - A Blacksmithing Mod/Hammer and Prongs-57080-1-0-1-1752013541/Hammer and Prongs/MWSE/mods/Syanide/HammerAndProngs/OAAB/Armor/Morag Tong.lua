local recipes = {

    -- Cloth

    {
        id = "AB_a_MoragTongHelm01",
        craftableId = "AB_a_MoragTongHelm01",
		category = "Morag Tong",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather", count = 3 },
            { material = "hap_cloth", count = 1 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isMoragTong() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 30
                end
            end
            return false
        end
	},

    {
        id = "AB_a_MoragTongHelm02",
        craftableId = "AB_a_MoragTongHelm02",
		category = "Morag Tong",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_cloth", count = 4 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isMoragTong() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 30
                end
            end
            return false
        end
	},

    {
        id = "AB_a_MoragTongHelm03",
        craftableId = "AB_a_MoragTongHelm03",
		category = "Morag Tong",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_netch_leather_boiled", count = 3 },
            { material = "hap_cloth", count = 1 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isMoragTong() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 30
                end
            end
            return false
        end
	},

    {
        id = "AB_a_MoragTongHelm04",
        craftableId = "AB_a_MoragTongHelm04",
		category = "Morag Tong",
        soundId = "Item Clothes Up",
        description = "Requires a Journeyman's Armorer's Needle or greater to be crafted.",
		materials = {
			{ material = "hap_chitin", count = 3 },
            { material = "hap_resin", count = 1 },
            { material = "hap_cloth", count = 1 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
			{ tool = "mid_needle", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then 
                return false
            else
                if factions.isMoragTong() then
                    local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
                    return skillValue >= 30
                end
            end
            return false
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