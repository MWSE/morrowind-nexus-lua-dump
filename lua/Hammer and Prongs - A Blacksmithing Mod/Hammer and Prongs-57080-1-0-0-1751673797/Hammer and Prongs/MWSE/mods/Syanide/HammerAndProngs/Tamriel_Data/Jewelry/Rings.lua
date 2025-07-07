local recipes = {

	-- Armor

    {
        id = "T_Bre_Cm_Ring_01",
        craftableId = "T_Bre_Cm_Ring_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_leather", count = 1 },
            { material = "hap_obsidian", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Cm_Ring_02",
        craftableId = "T_Bre_Cm_Ring_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Cm_Ring_03",
        craftableId = "T_Bre_Cm_Ring_03",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Cm_Ring_04",
        craftableId = "T_Bre_Cm_Ring_04",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_wood", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Cm_Ring_05",
        craftableId = "T_Bre_Cm_Ring_05",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Ep_Ring_01",
        craftableId = "T_Bre_Ep_Ring_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_turquoise", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Ep_Ring_02",
        craftableId = "T_Bre_Ep_Ring_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_amethyst", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Ep_Ring_03",
        craftableId = "T_Bre_Ep_Ring_03",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_emerald", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Et_Ring_01",
        craftableId = "T_Bre_Et_Ring_01",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_ruby", count = num0 },
            { material = "hap_gold", count = num1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Et_Ring_02",
        craftableId = "T_Bre_Et_Ring_02",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_sapphire", count = 4 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Bre_Ex_Ring_01",
        craftableId = "T_Bre_Ex_Ring_01",
        category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_emerald", count = 3 },
            { material = "hap_gold", count = 1 }
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
        id = "T_He_Cm_Ring_01",
        craftableId = "T_He_Cm_Ring_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_clay", count = 1 },
            { material = "hap_paint", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Cm_Ring_02",
        craftableId = "T_He_Cm_Ring_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_clay", count = 1 },
            { material = "hap_paint", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Cm_Ring_03",
        craftableId = "T_He_Cm_Ring_03",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 },
            { material = "hap_opal", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Cm_Ring_04",
        craftableId = "T_He_Cm_Ring_04",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_clay", count = 1 },
            { material = "hap_paint", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Cm_Ring_05",
        craftableId = "T_He_Cm_Ring_05",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_steel", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Ep_Ring_01",
        craftableId = "T_He_Ep_Ring_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 },
            { material = "hap_opal", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Ep_Ring_02",
        craftableId = "T_He_Ep_Ring_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 },
            { material = "hap_pearl", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Ep_Ring_03a",
        craftableId = "T_He_Ep_Ring_03a",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 },
            { material = "hap_topaz", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Ep_Ring_03b",
        craftableId = "T_He_Ep_Ring_03b",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 },
            { material = "hap_ruby", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Et_Ring_01",
        craftableId = "T_He_Et_Ring_01",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 },
            { material = "hap_amethyst", count = 3 },
            { material = "hap_diamond", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Et_Ring_02",
        craftableId = "T_He_Et_Ring_02",
        category = "Extravagant",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 },
            { material = "hap_gold", count = 1 },
            { material = "hap_ruby", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_He_Ex_Ring_01",
        craftableId = "T_He_Ex_Ring_01",
        category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_pearl", count = 2 },
            { material = "hap_ruby", count = 1 },
            { material = "hap_emerald", count = 1 }
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
        id = "T_Imp_Cm_RingColKey_01",
        craftableId = "T_Imp_Cm_RingColKey_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingColKey_02",
        craftableId = "T_Imp_Cm_RingColKey_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingCol_01",
        craftableId = "T_Imp_Cm_RingCol_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingCol_02",
        craftableId = "T_Imp_Cm_RingCol_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingCol_03",
        craftableId = "T_Imp_Cm_RingCol_03",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_steel", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingNib_01",
        craftableId = "T_Imp_Cm_RingNib_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingNib_02",
        craftableId = "T_Imp_Cm_RingNib_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingNib_03",
        craftableId = "T_Imp_Cm_RingNib_03",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_leather", count = 1 },
            { material = "hap_bronze", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingNib_04",
        craftableId = "T_Imp_Cm_RingNib_04",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingNib_05a",
        craftableId = "T_Imp_Cm_RingNib_05a",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 1 },
            { material = "hap_ruby", count = 2 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Cm_RingNib_05b",
        craftableId = "T_Imp_Cm_RingNib_05b",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_wood", count = num0 },
            { material = "hap_topaz", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ep_RingCol_01a",
        craftableId = "T_Imp_Ep_RingCol_01a",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 },
            { material = "hap_ruby", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ep_RingCol_01b",
        craftableId = "T_Imp_Ep_RingCol_01b",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 },
            { material = "hap_opal", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ep_RingCol_01c",
        craftableId = "T_Imp_Ep_RingCol_01c",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bronze", count = 1 },
            { material = "hap_topaz", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ep_RingNib_01",
        craftableId = "T_Imp_Ep_RingNib_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_opal", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ep_RingNib_02",
        craftableId = "T_Imp_Ep_RingNib_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_opal", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ep_RingNib_03",
        craftableId = "T_Imp_Ep_RingNib_03",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_opal", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ep_RingNib_04",
        craftableId = "T_Imp_Ep_RingNib_04",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = num0 },
            { material = "hap_ruby", count = num1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Imp_Ex_RingNib_01",
        craftableId = "T_Imp_Ex_RingNib_01",
        category = "Exquisite",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_emerald", count = 1 },
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
        id = "T_Nor_Cm_Ring_01",
        craftableId = "T_Nor_Cm_Ring_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Nor_Cm_Ring_02",
        craftableId = "T_Nor_Cm_Ring_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_steel", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Nor_Ep_Ring_01",
        craftableId = "T_Nor_Ep_Ring_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Nor_Ep_Ring_02",
        craftableId = "T_Nor_Ep_Ring_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Nor_Ep_Ring_03",
        craftableId = "T_Nor_Ep_Ring_03",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_jade", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Nor_Ep_Ring_04",
        craftableId = "T_Nor_Ep_Ring_04",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_rosequartz", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Nor_Ep_Ring_05",
        craftableId = "T_Nor_Ep_Ring_05",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_jade", count = 3 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Nor_Ep_Ring_06",
        craftableId = "T_Nor_Ep_Ring_06",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Rga_Cm_Ring_01",
        craftableId = "T_Rga_Cm_Ring_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_steel", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Rga_Cm_Ring_02",
        craftableId = "T_Rga_Cm_Ring_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Rga_Cm_Ring_03",
        craftableId = "T_Rga_Cm_Ring_03",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_copper", count = num0 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Rga_Cm_Ring_04",
        craftableId = "T_Rga_Cm_Ring_04",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Rga_Cm_Ring_05",
        craftableId = "T_Rga_Cm_Ring_05",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_iron", count = 1 },
            { material = "hap_wood", count = 1 },
            { material = "hap_rosequartz", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Rga_Ep_Ring_01",
        craftableId = "T_Rga_Ep_Ring_01",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Rga_Ep_Ring_02",
        craftableId = "T_Rga_Ep_Ring_02",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_silver", count = 1 },
            { material = "hap_paint", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_Rga_Ep_Ring_03",
        craftableId = "T_Rga_Ep_Ring_03",
        category = "Expensive",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_gold", count = 1 },
            { material = "hap_paint", count = 1 },
            { material = "hap_obsidian", count = 2 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_We_Cm_Ring_01",
        craftableId = "T_We_Cm_Ring_01",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 1 },
            { material = "hap_lapis", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_We_Cm_Ring_02",
        craftableId = "T_We_Cm_Ring_02",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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
        id = "T_We_Cm_Ring_03",
        craftableId = "T_We_Cm_Ring_03",
        category = "Common",
        soundId = "Repair",
        description = "Requires Jewelry Tongs to be crafted.",
        materials = {
            { material = "hap_bone", count = 1 },
            { material = "hap_amber", count = 1 }
        },
        toolRequirements = {
            { tool = "tongs", count = 1, conditionPerUse = 5 }
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