local sb_achievements = require("sb_achievements.interop")

local function init()
    local iconPath = "Icons\\sb_achievements_example\\"

    local cats = {
        main = sb_achievements.registerCategory("Main Quest"),
        side = sb_achievements.registerCategory("Side"),
        misc = sb_achievements.registerCategory("Miscellaneous")
    }

    sb_achievements.registerAchievement {
        id        = "A1_1_1",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A1_1_FindSpymaster" } >= 1
        end,
        icon      = iconPath .. "icn_A1_1_1.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "Ah Yes, We've Been Expecting You", desc = "Complete the character generation."
    }

    sb_achievements.registerAchievement {
        id        = "A1_1_14",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A1_1_FindSpymaster" } >= 14
        end,
        icon      = iconPath .. "icn_A1_1_14.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "By The Emperor", desc = "Begin the main quest."
    }

    sb_achievements.registerAchievement {
        id        = "A2_1_60",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A2_1_MeetSulMatuul" } >= 60
        end,
        icon      = iconPath .. "icn_A2_1_60.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "Nerevar Rising", desc = "Get confirmation that you are not (yet) the Nerevar.",
        hideDesc  = true
    }

    sb_achievements.registerAchievement {
        id        = "A2_2_50",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A2_2_6thHouse" } >= 50
        end,
        icon      = iconPath .. "icn_A2_2_50.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "Tribe Unmourned", desc = "Learn about the existence of House Dagoth, the former sixth house.",
        hideDesc  = true
    }

    sb_achievements.registerAchievement {
        id        = "A2_3_40",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A2_3_CorprusCure" } >= 40
        end,
        icon      = iconPath .. "icn_A2_3_40.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "The Endling", desc = "Meet Yagrum Bagarn, the last of the Dwemer."
    }

    sb_achievements.registerAchievement {
        id        = "B_Hortator",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "B5_RedoranHort" } >= 50 or tes3.getJournalIndex { id = "B6_HlaaluHort" } >= 50 or tes3.getJournalIndex { id = "B7_TelvanniHort" } >= 50
        end,
        icon      = iconPath .. "icn_B_Hortator.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "House Father", desc = "Become Hortator of House Redoran, House Hlaalu, or House Telvanni.",
        hideDesc  = true
    }

    sb_achievements.registerAchievement {
        id        = "B_Nerevarine",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "B1_UnifyUrshilaku" } >= 50 or tes3.getJournalIndex { id = "B2_AhemmusaSafe" } >= 50 or tes3.getJournalIndex { id = "B3_ZainabBride" } >= 50
        end,
        icon      = iconPath .. "icn_B_Nerevarine.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "Folk Hero", desc = "Be recognised as the Nerevarine by the Urshilaku, the Ahemmusa, the Zainab, or the Erabenimsun.",
        hideDesc  = true
    }

    sb_achievements.registerAchievement {
        id        = "B8_MeetVivec_34",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "B8_MeetVivec" } >= 34
        end,
        icon      = iconPath .. "icn_B8_MeetVivec_34.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "The Warrior Poet", desc = "Meet Vivec, head of the Tribunal."
    }

    sb_achievements.registerAchievement {
        id        = "C3_DestroyDagoth_20",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "C3_DestroyDagoth" } >= 20
        end,
        icon      = iconPath .. "icn_C3_DestroyDagoth_20.tga",
        colour    = sb_achievements.colours.yellow,
        title     = "Prophecy Fulfilled", desc = "Defeat Dagoth Ur, and destroy the Heart of Lorkhan.",
        hideDesc  = true
    }

    sb_achievements.registerAchievement {
        id        = "MS_FargothRing",
        category  = cats.side,
        condition = function()
            return tes3.getJournalIndex { id = "MS_FargothRing" } >= 100
        end,
        icon      = iconPath .. "icn_FargothsRing.tga",
        colour    = sb_achievements.colours.blue,
        title     = "Thank You, Stranger", desc = "Return Fargoth's ring."
    }

    sb_achievements.registerAchievement {
        id        = "MudcrabMerchant",
        category  = cats.misc,
        condition = function()
            ---@param creature tes3creatureInstance
            for creature in tes3.player.cell:iterateReferences(tes3.objectType.creature) do
                if (creature.baseObject.id == "mudcrab_unique" and (creature.position:distance(tes3.player.position) < 512)) then
                    return true
                end
            end
            return false
        end,
        icon      = iconPath .. "icn_MudcrabMerchant.tga",
        colour    = sb_achievements.colours.violet,
        title     = "Talking. Mudcrab. Merchant.", desc = "Meet the mudcrab merchant."
    }

    sb_achievements.registerAchievement {
        id        = "CreeperMerchant",
        category  = cats.misc,
        condition = function()
            ---@param creature tes3creatureInstance
            for creature in tes3.player.cell:iterateReferences(tes3.objectType.creature) do
                if (creature.baseObject.id == "scamp_creeper" and (creature.position:distance(tes3.player.position) < 512)) then
                    return true
                end
            end
            return false
        end,
        icon      = iconPath .. "icn_Creeper.tga",
        colour    = sb_achievements.colours.violet,
        title     = "What's a scamp gotta do?", desc = "Meet Creeper."
    }
end

local function initializedCallback(e)
    init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })
