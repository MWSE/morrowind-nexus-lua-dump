local recipes = {

	-- Armor

	{
        id = "T_We_Ep_Amulet_01",
        craftableId = "T_We_Ep_Amulet_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 1 },
            { material = "hap_pearl", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_We_Ep_Amulet_02",
        craftableId = "T_We_Ep_Amulet_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 1 },
            { material = "hap_jade", count = 2 },
            { material = "hap_amber", count = 2 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_We_Ep_Amulet_03",
        craftableId = "T_We_Ep_Amulet_03",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 3 },
            { material = "hap_steel", count = 2 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Yne_Cm_Amulet_01",
        craftableId = "T_Yne_Cm_Amulet_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_wicker", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Yne_Cm_Amulet_02",
        craftableId = "T_Yne_Cm_Amulet_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_stone", count = 2 },
            { material = "hap_wood", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Yne_Ep_Amulet_01",
        craftableId = "T_Yne_Ep_Amulet_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_wood", count = 1 },
            { material = "hap_gold", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Yne_Ep_Amulet_02",
        craftableId = "T_Yne_Ep_Amulet_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 2 },
            { material = "hap_wood", count = 1 },
            { material = "hap_paint", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Et_Amulet_01",
        craftableId = "T_Nor_Et_Amulet_01",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_sapphire", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_Nor_Et_Amulet_02",
        craftableId = "T_Nor_Et_Amulet_02",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_amethyst", count = 1 },
            { material = "hap_sapphire", count = 2 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_QyC_Com_Amulet_01",
        craftableId = "T_QyC_Com_Amulet_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 },
            { material = "hap_opal", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_QyC_Ep_Amulet_01",
        craftableId = "T_QyC_Ep_Amulet_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_onyx", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_QyC_Et_Amulet_01",
        craftableId = "T_QyC_Et_Amulet_01",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_pearl", count = 3 },
            { material = "hap_amethyst", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_QyC_Ex_Amulet_01",
        craftableId = "T_QyC_Ex_Amulet_01",
        category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_opal", count = 8 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_QyK_Ep_Amulet_01",
        craftableId = "T_QyK_Ep_Amulet_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_bpearl", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Rea_Cm_Necklace_01",
        craftableId = "T_Rea_Cm_Necklace_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_amber", count = 3 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Rea_Cm_Necklace_02",
        craftableId = "T_Rea_Cm_Necklace_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_plumes", count = 3 },
            { material = "hap_bone", count = 1 },
            { material = "hap_thread", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Rea_Ep_AmuletBone_01",
        craftableId = "T_Rea_Ep_AmuletBone_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_wicker", count = 2 },
            { material = "hap_bone", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Rea_Ep_AmuletBone_02",
        craftableId = "T_Rea_Ep_AmuletBone_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_plumes", count = 6 },
            { material = "hap_ratskull", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Rea_Ep_AmuletWood_01",
        craftableId = "T_Rea_Ep_AmuletWood_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_wood", count = num0 },
            { material = "hap_amber", count = num1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Ep_Amulet_01",
        craftableId = "T_Nor_Ep_Amulet_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Ep_Amulet_02",
        craftableId = "T_Nor_Ep_Amulet_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Ep_Amulet_03",
        craftableId = "T_Nor_Ep_Amulet_03",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Nor_Cm_AmuletStone_01",
        craftableId = "T_Nor_Cm_AmuletStone_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_stone", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Nor_Cm_AmuletStone_02",
        craftableId = "T_Nor_Cm_AmuletStone_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_stone", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Nor_Cm_Amulet_01",
        craftableId = "T_Nor_Cm_Amulet_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_steel", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Nor_Cm_Amulet_02",
        craftableId = "T_Nor_Cm_Amulet_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Nor_Cm_Amulet_03",
        craftableId = "T_Nor_Cm_Amulet_03",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Et_AmuletNib_01",
        craftableId = "T_Imp_Et_AmuletNib_01",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_turqouise", count = 1 },
            { material = "hap_emerald", count = 2 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_Imp_Et_AmuletNib_02",
        craftableId = "T_Imp_Et_AmuletNib_02",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_ametrine", count = num1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_Imp_Et_Amulet_01a",
        craftableId = "T_Imp_Et_Amulet_01a",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_ruby", count = 1 },
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_Imp_Et_Amulet_01b",
        craftableId = "T_Imp_Et_Amulet_01b",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_sapphire", count = 1 },
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_Imp_Et_Amulet_01c",
        craftableId = "T_Imp_Et_Amulet_01c",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_emerald", count = 1 },
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_Imp_Et_Amulet_01d",
        craftableId = "T_Imp_Et_Amulet_01d",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_topaz", count = 1 },
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_Imp_Et_Amulet_02",
        craftableId = "T_Imp_Et_Amulet_02",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_agate", count = 2 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_Imp_Ex_AmuletNib_01",
        craftableId = "T_Imp_Ex_AmuletNib_01",
        category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_sapphire", count = 1 },
            { material = "hap_amethyst", count = 1 },
            { material = "hap_ruby", count = 1 },
            { material = "hap_emerald", count = 1 },
            { material = "hap_topaz", count = 1 },
            { material = "hap_pearl", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ex_Amulet_01",
        craftableId = "T_Imp_Ex_Amulet_01",
        category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_sapphire", count = 1 },
            { material = "hap_amethyst", count = 1 },
            { material = "hap_ruby", count = 1 },
            { material = "hap_topaz", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ep_AmuletNib_01",
        craftableId = "T_Imp_Ep_AmuletNib_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_lapis", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
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
        id = "T_Imp_Ep_AmuletNib_02",
        craftableId = "T_Imp_Ep_AmuletNib_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_bone", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
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
        id = "T_Imp_Ep_AmuletNib_03",
        craftableId = "T_Imp_Ep_AmuletNib_03",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_amethyst", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
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
        id = "T_Imp_Ep_AmuletNib_04",
        craftableId = "T_Imp_Ep_AmuletNib_04",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_rosequartz", count = 1 },
            { material = "hap_gold", count = 1 },
            { material = "hap_gpearl", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
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
        id = "T_Imp_Ep_Amulet_01",
        craftableId = "T_Imp_Ep_Amulet_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_brass", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Imp_Ep_Amulet_02",
        craftableId = "T_Imp_Ep_Amulet_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_steel", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Imp_Ep_Amulet_03",
        craftableId = "T_Imp_Ep_Amulet_03",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_steel", count = 1 },
            { material = "hap_gold", count = 1 },
            { material = "hap_lapis", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_Imp_Cm_AmuletNib_01",
        craftableId = "T_Imp_Cm_AmuletNib_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 },
            { material = "hap_jade", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_AmuletNib_02",
        craftableId = "T_Imp_Cm_AmuletNib_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 },
            { material = "hap_lapis", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_AmuletNib_03a",
        craftableId = "T_Imp_Cm_AmuletNib_03a",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 },
            { material = "hap_smokyquartz", count = num1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_AmuletNib_03b",
        craftableId = "T_Imp_Cm_AmuletNib_03b",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 },
            { material = "hap_moonstone", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_AmuletNib_03c",
        craftableId = "T_Imp_Cm_AmuletNib_03c",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = num0 },
            { material = "hap_fireopal", count = num1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_AmuletNib_03d",
        craftableId = "T_Imp_Cm_AmuletNib_03d",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 },
            { material = "hap_smokyquartz", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_AmuletNib_04",
        craftableId = "T_Imp_Cm_AmuletNib_04",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_AmuletNib_05",
        craftableId = "T_Imp_Cm_AmuletNib_05",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_jade", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_Amulet_01",
        craftableId = "T_Imp_Cm_Amulet_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_stone", count = 1 },
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_Amulet_02",
        craftableId = "T_Imp_Cm_Amulet_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 },
            { material = "hap_obsidian", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_Amulet_03",
        craftableId = "T_Imp_Cm_Amulet_03",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 },
            { material = "hap_fireopal", count = num1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_Amulet_04",
        craftableId = "T_Imp_Cm_Amulet_04",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 2 },
            { material = "hap_fireopal", count = 2 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_Imp_Cm_Amulet_05",
        craftableId = "T_Imp_Cm_Amulet_05",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_cloth", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_He_Ex_Amulet_01",
        craftableId = "T_He_Ex_Amulet_01",
        category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_opal", count = 5 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Et_Amulet_01",
        craftableId = "T_He_Et_Amulet_01",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_ragate", count = 1 },
            { material = "hap_steel", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_He_Et_Amulet_02",
        craftableId = "T_He_Et_Amulet_02",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_turqoise", count = 1 },
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 4 }
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
        id = "T_He_Ep_Amulet_01",
        craftableId = "T_He_Ep_Amulet_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_paint", count = 2 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_He_Ep_Amulet_02",
        craftableId = "T_He_Ep_Amulet_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_malachite", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_He_Ep_Amulet_03",
        craftableId = "T_He_Ep_Amulet_03",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_emerald", count = 1 },
            { material = "hap_sapphire", count = 1 },
            { material = "hap_steel", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 3 }
        },
        craftCallback = function(self, e)
            local skillId = tes3.skill.armorer
            local progress = 2
            tes3.mobilePlayer:exerciseSkill(skillId, progress)
        end,
        knowledgeRequirement = function(self)
            local player = tes3.player
            if not player then return false end
            local skillValue = tes3.mobilePlayer.skills[tes3.skill.armorer + 1].base
            return skillValue >= 30
        end
    },

    {
        id = "T_De_Cm_AmuletInd_01",
        craftableId = "T_De_Cm_AmuletInd_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_obsidian", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_He_Cm_Amulet_05",
        craftableId = "T_He_Cm_Amulet_05",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_He_Cm_Amulet_04",
        craftableId = "T_He_Cm_Amulet_04",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_resin", count = 1 },
            { material = "hap_chitin", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_He_Cm_Amulet_03",
        craftableId = "T_He_Cm_Amulet_03",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_clay", count = 1 },
            { material = "hap_paint", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_He_Cm_Amulet_02",
        craftableId = "T_He_Cm_Amulet_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_amber", count = 1 },
            { material = "hap_chitin", count = num1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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
        id = "T_He_Cm_Amulet_01",
        craftableId = "T_He_Cm_Amulet_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_steel", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 2 }
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

event.register("AB_Misc_File:Registered", registerRecipes)