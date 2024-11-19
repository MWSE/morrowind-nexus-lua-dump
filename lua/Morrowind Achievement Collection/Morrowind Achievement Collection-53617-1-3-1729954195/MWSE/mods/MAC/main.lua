local sb_achievements = require("sb_achievements.interop")
local pData = require("MAC.playerData")


local function init()
    local iconPath = "Icons\\MAC\\"
    local cats = {
        main = sb_achievements.registerCategory("Main Quest"),
        side = sb_achievements.registerCategory("Side Quest"),
        faction = sb_achievements.registerCategory("Faction"),
        misc = sb_achievements.registerCategory("Miscellaneous")
    }
    --Any Achievements noted with "SB" were created by SafetyBox and were part of The Achievement Framework Example code
    --Main Quest
    --SB
    sb_achievements.registerAchievement {
        id        = "A1_1_1",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A1_1_FindSpymaster" } >= 1
        end,
        icon      = iconPath .. "icn_A1_1_1.dds",
        colour    = pData.colours.bronze,
        title     = "Ah Yes, We've Been Expecting You", desc = "Complete the character generation.",
    }
    --SB
    sb_achievements.registerAchievement {
        id        = "A1_1_14",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A1_1_FindSpymaster" } >= 14
        end,
        icon      = iconPath .. "icn_A1_1_14.dds",
        colour    = pData.colours.bronze,
        title     = "By The Emperor", desc = "Begin the main quest.",
    }
    --SB
    sb_achievements.registerAchievement {
        id        = "A2_1_60",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A2_1_MeetSulMatuul" } >= 60
        end,
        icon      = iconPath .. "icn_A2_1_60.dds",
        colour    = pData.colours.bronze,
        title     = "Nerevar Rising", desc = "Get confirmation that you are not (yet) the Nerevarine.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    --SB
    sb_achievements.registerAchievement {
        id        = "A2_2_50",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A2_2_6thHouse" } >= 50
        end,
        icon      = iconPath .. "icn_A2_2_50.dds",
        colour    = pData.colours.bronze,
        title     = "Tribe Unmourned", desc = "Learn about the existence of House Dagoth, the former sixth house.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    --SB
    sb_achievements.registerAchievement {
        id        = "A2_3_40",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "A2_3_CorprusCure" } >= 40
        end,
        icon      = iconPath .. "icn_A2_3_40.dds",
        colour    = pData.colours.bronze,
        title     = "The Endling", desc = "Meet Yagrum Bagarn, the last of the Dwemer.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    --SB slightly modified. New Icon and conditions changed so you have to be hort of all three instead of any of the three
    sb_achievements.registerAchievement {
        id        = "B_Hortator",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "B5_RedoranHort" } >= 50 and tes3.getJournalIndex { id = "B6_HlaaluHort" } >= 50 and tes3.getJournalIndex { id = "B7_TelvanniHort" } >= 50
        end,
        icon      = iconPath .. "icn_Hort.dds",
        colour    = pData.colours.bronze,
        title     = "House Father", desc = "Become Hortator of House Redoran, House Hlaalu, and House Telvanni.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    --SB slightly modified. Conditions changed so you have to be Nerevarine of all three instead of any of the three
    sb_achievements.registerAchievement {
        id        = "B_Nerevarine",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "B1_UnifyUrshilaku" } >= 50 and tes3.getJournalIndex { id = "B2_AhemmusaSafe" } >= 50 and tes3.getJournalIndex { id = "B3_ZainabBride" } >= 50 and tes3.getJournalIndex {id = "B4_KillWarLovers"} >= 55
        end,
        icon      = iconPath .. "icn_B_Nerevarine.dds",
        colour    = pData.colours.bronze,
        title     = "Folk Hero", desc = "Be recognized as the Nerevarine by the Urshilaku, the Ahemmusa, the Zainab, and the Erabenimsun.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    --SB
    sb_achievements.registerAchievement {
        id        = "B8_MeetVivec_34",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "B8_MeetVivec" } >= 34
        end,
        icon      = iconPath .. "icn_B8_MeetVivec_34.dds",
        colour    = pData.colours.bronze,
        title     = "The Warrior Poet", desc = "Meet Vivec, head of the Tribunal.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "Tools",
        category  = cats.main,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            local myData = pData.getData()
            return tes3.getJournalIndex {id = "C0_Act_C"} == 15 and (tes3.getJournalIndex {id = "B8_MeetVivec"} >= 50 or tes3.getJournalIndex {id = "CX_BackPath"} >= 50) and pData.gotKeening()
        end,
        icon      = iconPath .. "icn_Tools.dds",
        colour    = pData.colours.silver,
        title     = "The Tools Of Godhood", desc = "Collect Wraithguard, Sunder, and Keening."
    }
    sb_achievements.registerAchievement {
        id        = "SecretPath",
        category  = cats.main,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
                return tes3.getJournalIndex {id = "CX_BackPath"} >= 50 and tes3.getJournalIndex {id = "C3_DestroyDagoth"} >= 20
        end,
        icon      = iconPath .. "icn_SecretPath.dds",
        colour    = pData.colours.plat,
        title     = "Doing It The Hard Way", desc = "Defeat Dagoth Ur using the Jury-Rigged Wraithguard."
    }
    --SB
    sb_achievements.registerAchievement {
        id        = "C3_DestroyDagoth_20",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "C3_DestroyDagoth" } >= 20
        end,
        icon      = iconPath .. "icn_C3_DestroyDagoth_20.dds",
        colour    = pData.colours.gold,
        title     = "Prophecy Fulfilled", desc = "Defeat Dagoth Ur, and destroy the Heart of Lorkhan.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "ToMournhold",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex {id = "TR_DBAttack"} >= 60
        end,
        icon      = iconPath .. "icn_ToMournhold.dds",
        colour    = pData.colours.bronze,
        title     = "City of Light, City of Magic", desc = "Travel to Mournhold on Morrowind's mainland."
    }
    sb_achievements.registerAchievement {
        id        = "HuntDB",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex {id = "TR_DBHunt"} >= 60
        end,
        icon      = iconPath .. "icn_HuntDB.dds",
        colour    = pData.colours.bronze,
        title     = "Hunted To Hunter", desc = "Find the clue that points to who hired the Dark Brotherhood.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "MHAttack",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex {id = "TR_MHAttack"} >= 110
        end,
        icon      = iconPath .. "icn_MHAttack.dds",
        colour    = pData.colours.bronze,
        title     = "Attack On Mournhold", desc = "Rid the Plaza of the strange creatures.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "TRBlade",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex {id = "TR_Blade"} >= 100
        end,
        icon      = iconPath .. "icn_TRBlade.dds",
        colour    = pData.colours.silver,
        title     = "Trueflame", desc = "Reforge the ancient blade of Indoril Nerevar.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "TRAlmaEnd",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex {id = "TR_SothaSil"} >= 100
        end,
        icon      = iconPath .. "icn_TRAlmaEnd.dds",
        colour    = pData.colours.gold,
        title     = "Almalexia's End", desc = "End Almalexia's madness.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "ToSolstheim",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "BM_Rumors" } >= 100
        end,
        icon      = iconPath .. "icn_ToSolstheim.dds",
        colour    = pData.colours.bronze,
        title     = "Island To The North", desc = "Arrive on the frigid island of Solstheim."
    }
    sb_achievements.registerAchievement {
        id        = "BM_MeetSkaal",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "BM_CariusGone" } >=30
        end,
        icon      = iconPath .. "icn_BM_MeetSkaal.dds",
        colour    = pData.colours.bronze,
        title     = "The Skaal", desc = "Find the Skaal village on Solstheim.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "BM_DefendSkaal",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "BM_SkaalAttack" } >=30
        end,
        icon      = iconPath .. "icn_BM_DefendSkaal.dds",
        colour    = pData.colours.bronze,
        title     = "Werewolf Attack", desc = "Defend Skaal village from the werewolf attackers.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "BM_Karstaag",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "BM_FrostGiant2" } >= 100 or tes3.getJournalIndex { id = "BM_FrostGiant1" } >= 100
        end,
        icon      = iconPath .. "icn_BM_Karstaag.dds",
        colour    = pData.colours.silver,
        title     = "Castle Karstaag", desc = "Investigate the goings-on at Castle Karstaag.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "BM_WildHunt",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "BM_WildHunt" } >= 100
        end,
        icon      = iconPath .. "icn_BM_WildHunt.dds",
        colour    = pData.colours.gold,
        title     = "The Wild Hunt", desc = "Defeat the aspect of Hircine and stop the Wild Hunt.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "AllMainQ",
        category  = cats.main,
        condition = function()
            return tes3.getJournalIndex { id = "C3_DestroyDagoth" } >= 20 and tes3.getJournalIndex { id = "TR_SothaSil" } >= 100 and tes3.getJournalIndex { id = "BM_WildHunt" } >= 100
        end,
        icon      = iconPath .. "icn_AllMainQ.dds",
        colour    = pData.colours.plat,
        title     = "The Nerevarine", desc = "Finish the Morrowind, Tribunal, and Bloodmoon main quests.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    --Side Quests
    --SB
    sb_achievements.registerAchievement {
        id        = "MS_FargothRing",
        category  = cats.side,
        condition = function()
            return tes3.getJournalIndex { id = "MS_FargothRing" } >= 100
        end,
        icon      = iconPath .. "icn_FargothsRing.dds",
        colour    = pData.colours.bronze,
        title     = "Thank You, Stranger", desc = "Return Fargoth's ring.",
    }
    sb_achievements.registerAchievement {
        id        = "Pilgrimages",
        category  = cats.side,
        condition = function()
            if (tes3.getJournalIndex { id = "TT_fieldsKummu" } >= 100 and tes3.getJournalIndex { id = "TT_StopMoon" } >= 100 and tes3.getJournalIndex { id = "TT_PalaceVivec" } >= 100 and tes3.getJournalIndex { id = "TT_PuzzleCanal" } >= 100 and tes3.getJournalIndex { id = "TT_MaskVivec" } >= 100 and tes3.getJournalIndex { id = "TT_RuddyMan" } >= 100 and tes3.getJournalIndex { id = "TT_GhostGate" } >= 100) then
                return true
            end
        end,
        icon      = iconPath .. "icn_Pilgrimages.dds",
        colour    = pData.colours.bronze,
        title     = "Pilgrim", desc = "Complete the Pilgrimages of the Seven Graces.",
    }
    sb_achievements.registerAchievement {
        id        = "MHActorQuest",
        category  = cats.side,
        condition = function()
            for npc in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                if (npc.baseObject.id == "meryn othralas") then
                    local Mcontext = npc.context
                    if (tes3.getJournalIndex { id = "MS_Performers" } == 120 and Mcontext.missCounter == 0.0 ) then
                        return true
                    end
                end
            end
        end,
        icon      = iconPath .. "icn_MHActorQuest.dds",
        colour    = pData.colours.silver,
        title     = "Thespian?", desc = "Flawlessly stand in for an ill actor.",
    }
    sb_achievements.registerAchievement {
        id        = "MHBBquest",
        category  = cats.side,
        condition = function()
            for npc in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                if (npc.baseObject.id == "ignatius_flaccus") then
                    local Mcontext = npc.context
                    if (tes3.getJournalIndex { id = "MS_BattleBots1" } == 80 and Mcontext.PCBotBet == 1000 ) then
                        return true
                    end
                end
            end
        end,
        icon      = iconPath .. "icn_MHBBquest.dds",
        colour    = pData.colours.silver,
        title     = "No Risk No Reward", desc = "Bet, and win, the maximum amount at the Robot Arena.",
    }
    sb_achievements.registerAchievement {
        id        = "ThirskChief",
        category  = cats.side,
        condition = function()
            return tes3.getJournalIndex { id = "BM_MeadHall" } == 100 and tes3.getJournalIndex { id = "BM_MeadHall_b" } == 20 and tes3.getJournalIndex { id = "BM_MeadHall_c" } == 20
        end,
        icon      = iconPath .. "icn_ThirskChief.dds",
        colour    = sb_achievements.colours.blue,
        title     = "Bring Me More Mead!", desc = "Complete all Thirsk Mead Hall business as it's Chieftain.",
    }
    sb_achievements.registerAchievement {
        id        = "NakedNords",
        category  = cats.side,
        condition = function()
            return tes3.getJournalIndex { id = "MV_AbusedHealer" } >= 75 and tes3.getJournalIndex { id = "MV_RecoverWidowmaker" } >= 70 and tes3.getJournalIndex { id = "MV_ParalyzedBarbarian" } >= 100
        end,
        icon      = iconPath .. "icn_NakedNords.dds",
        colour    = pData.colours.bronze,
        title     = "Why Are You Naked?", desc = "Complete the stories of Vvardenfell's naked Nords.",
    }
    sb_achievements.registerAchievement {
        id        = "GlimpseFuture",
        category  = cats.side,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            return tes3.getJournalIndex { id = "BM_SadSeer" } == 110
        end,
        icon      = iconPath .. "icn_GlimpseFuture.dds",
        colour    = pData.colours.silver,
        title     = "A Glimpse Of The Future", desc = "Hear of the coming Oblivion Crisis."
    }
    sb_achievements.registerAchievement {
        id        = "CureWere",
        category  = cats.side,
        condition = function()
            return tes3.getJournalIndex { id = "BM_WolfGiver" } >= 120 or tes3.getJournalIndex { id = "BM_WolfGiver_a" } >= 20
        end,
        icon      = iconPath .. "icn_CureWere.dds",
        colour    = pData.colours.silver,
        title     = "A Cure For Lycanthropy", desc = "Cure yourself of the werewolf disease.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "Lovers",
        category  = cats.side,
        condition = function()
            return tes3.getJournalIndex { id = "EB_Unrequited" } >= 110 and tes3.getJournalIndex { id = "MS_MatchMaker" } == 120 and tes3.getJournalIndex { id = "MV_MissingCompanion" } == 60 and (tes3.getJournalIndex { id = "MV_VictimRomance" } == 100 or tes3.getJournalIndex { id = "MV_VictimRomance" } == 105)
        end,
        icon      = iconPath .. "icn_lovers.dds",
        colour    = pData.colours.bronze,
        title     = "Softy At Heart", desc = "Help the residents of Morrowind find love.",
    }
    sb_achievements.registerAchievement {
        id        = "Daedrashrines",
        category  = cats.side,
        condition = function()
            return tes3.getJournalIndex { id = "DA_Azura" } >= 40 and tes3.getJournalIndex { id = "DA_Boethiah" } >= 70 and tes3.getJournalIndex { id = "DA_Malacath" } >= 70 and tes3.getJournalIndex { id = "DA_Mehrunes" } >= 40 and tes3.getJournalIndex { id = "DA_Mephala" } == 60 and tes3.getJournalIndex { id = "DA_MolagBal" } == 30 and tes3.getJournalIndex { id = "DA_Sheogorath" } == 70
        end,
        icon      = iconPath .. "icn_Daedrashrines.dds",
        colour    = pData.colours.bronze,
        title     = "Servant Of Oblivion", desc = "Complete the tasks of all the Daedra Princes of Morrowind.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "VampQuests",
        category  = cats.side,
        condition = function()
            return (tes3.getJournalIndex { id = "VA_VampChild" } >= 40 and tes3.getJournalIndex { id = "VA_VampHunter" } >= 70) or (tes3.getJournalIndex { id = "VA_VampBlood" } >= 70 and tes3.getJournalIndex { id = "VA_VampCountess" } >= 40) or (tes3.getJournalIndex { id = "VA_VampCult" } == 60 and tes3.getJournalIndex { id = "VA_VampAmulet" } == 30)
        end,
        icon      = iconPath .. "icn_VampQuests.dds",
        colour    = pData.colours.bronze,
        title     = "Clan Vampire", desc = "Complete your clan specific Vampire quests.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    --Faction
    sb_achievements.registerAchievement {
        id        = "GHJoined",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Telvanni").playerJoined or tes3.getFaction("Redoran").playerJoined or tes3.getFaction("Hlaalu").playerJoined
        end,
        icon      = iconPath .. "icn_GHJoined.dds",
        colour    = pData.colours.bronze,
        title     = "The Great Houses Of Morrowind", desc = "Become a member of a Dunmer Great House.",
    }
    sb_achievements.registerAchievement {
        id        = "GHLeader",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Telvanni").playerRank >= 9 or tes3.getFaction("Redoran").playerRank >= 9 or tes3.getFaction("Hlaalu").playerRank >= 9
        end,
        icon      = iconPath .. "icn_GHLeader.dds",
        colour    = pData.colours.silver,
        title     = "Great House Leader", desc = "Become leader of a Dunmer Great House.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "MGJoin",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Mages Guild").playerJoined
        end,
        icon      = iconPath .. "icn_MGJoin.dds",
        colour    = pData.colours.bronze,
        title     = "I Cast A Spell", desc = "Join the Mages Guild.",
    }
    sb_achievements.registerAchievement {
        id        = "MGArchmage",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Mages Guild").playerRank >= 9
        end,
        icon      = iconPath .. "icn_MGArchmage.dds",
        colour    = pData.colours.silver,
        title     = "Archmage", desc = "Become Archmage of the Mages Guild.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "TGJoin",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Thieves Guild").playerJoined
        end,
        icon      = iconPath .. "icn_TGJoin.dds",
        colour    = pData.colours.bronze,
        title     = "Band Of Thieves", desc = "Join the Thieves Guild.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "TGMasterThief",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Thieves Guild").playerRank >= 9
        end,
        icon      = iconPath .. "icn_TGMasterThief.dds",
        colour    = pData.colours.silver,
        title     = "Master Thief", desc = "Become Master Thief of the Thieves Guild.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "FGJoin",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Fighters Guild").playerJoined
        end,
        icon      = iconPath .. "icn_FGJoin.dds",
        colour    = pData.colours.bronze,
        title     = "Merc For Hire", desc = "Join the Fighters Guild.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "FGMaster",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Thieves Guild").playerRank >= 9
        end,
        icon      = iconPath .. "icn_FGMaster.dds",
        colour    = pData.colours.silver,
        title     = "Master", desc = "Become Master of the Fighters Guild.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "MTJoin",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Morag Tong").playerJoined
        end,
        icon      = iconPath .. "icn_MTJoin.dds",
        colour    = pData.colours.bronze,
        title     = "Blades In The Dark", desc = "Join the Morag Tong.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "MTGrandmaster",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Morag Tong").playerRank >= 9
        end,
        icon      = iconPath .. "icn_MTGrandmaster.dds",
        colour    = pData.colours.silver,
        title     = "Morag Tong Grandmaster", desc = "Become Grandmaster of the Morag Tong.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "ILJoin",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Imperial Legion").playerJoined
        end,
        icon      = iconPath .. "icn_ILJoin.dds",
        colour    = pData.colours.bronze,
        title     = "Suit Up Soldier", desc = "Join the Imperial Legion.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "ILDragKnight",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Imperial Legion").playerRank >= 9
        end,
        icon      = iconPath .. "icn_ILDragKnight.dds",
        colour    = pData.colours.silver,
        title     = "Knight Of The Imperial Dragon", desc = "Become Knight of the Imperial Dragon of the Imperial Legion.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "ICJoin",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Imperial Cult").playerJoined
        end,
        icon      = iconPath .. "icn_ICJoin.dds",
        colour    = pData.colours.bronze,
        title     = "Humanitarian Efforts", desc = "Join the Imperial Cult.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "ICPrimate",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Imperial Cult").playerRank >= 9
        end,
        icon      = iconPath .. "icn_ICPrimate.dds",
        colour    = pData.colours.silver,
        title     = "Primate", desc = "Become Primate of the Imperial Cult.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "TTJoin",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Temple").playerJoined
        end,
        icon      = iconPath .. "icn_TTJoin.dds",
        colour    = pData.colours.bronze,
        title     = "Temple Faithful", desc = "Join the Temple.",
        configDesc = sb_achievements.configDesc.showDesc,
    }
    sb_achievements.registerAchievement {
        id        = "TTPatriarch",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("Temple").playerRank >= 9
        end,
        icon      = iconPath .. "icn_TTPatriarch.dds",
        colour    = pData.colours.silver,
        title     = "Patriarch", desc = "Become Patriarch of the Temple.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "EECJoin",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("East Empire Company").playerJoined
        end,
        icon      = iconPath .. "icn_EECJoin.dds",
        colour    = pData.colours.bronze,
        title     = "Solstheim Mining Operation", desc = "Join the East Empire Company.",
    }
    sb_achievements.registerAchievement {
        id        = "EECFactor",
        category  = cats.faction,
        condition = function()
            return tes3.getFaction("East Empire Company").playerRank >= 8
        end,
        icon      = iconPath .. "icn_EECFactor.dds",
        colour    = pData.colours.silver,
        title     = "Factor", desc = "Become Factor of the East Empire Company.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "Stronghold",
        category  = cats.faction,
        condition = function()
                return tes3.getJournalIndex { id = "HH_Stronghold" } == 300 or tes3.getJournalIndex { id = "HR_Stronghold" } == 300 or tes3.getJournalIndex { id = "HT_Stronghold" } == 300
        end,
        icon      = iconPath .. "icn_stronghold.dds",
        colour    = pData.colours.silver,
        title     = "Great House Stronghold", desc = "Finish building your stronghold.",
    }
    --Miscellaneous
    --SB
    sb_achievements.registerAchievement {
        id        = "MudcrabMerchant",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            ---@param creature tes3creatureInstance
            for creature in tes3.player.cell:iterateReferences(tes3.objectType.creature) do
                if (creature.baseObject.id == "mudcrab_unique" and (creature.position:distance(tes3.player.position) < 512)) then
                    return true
                end
            end
            return false
        end,
        icon      = iconPath .. "icn_MudcrabMerchant.dds",
        colour    = pData.colours.gold,
        title     = "Talking. Mudcrab. Merchant.", desc = "Meet the mudcrab merchant.",
    }
    --SB
    sb_achievements.registerAchievement {
        id        = "CreeperMerchant",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            ---@param creature tes3creatureInstance
            for creature in tes3.player.cell:iterateReferences(tes3.objectType.creature) do
                if (creature.baseObject.id == "scamp_creeper" and (creature.position:distance(tes3.player.position) < 512)) then
                    return true
                end
            end
            return false
        end,
        icon      = iconPath .. "icn_Creeper.dds",
        colour    = pData.colours.bronze,
        title     = "What's A Scamp Gotta Do?", desc = "Meet Creeper.",
    }
   sb_achievements.registerAchievement {
        id        = "BigSoulCapture",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            local myData = pData.getData()
            if (myData["soulachieve"] == true) then
                event.unregister(tes3.event.filterSoulGemTarget, pData.soulFilter)
                return true
            end
        end,
        icon      = iconPath .. "icn_bigsoul.dds",
        colour    = pData.colours.gold,
        title     = "Big Soul Hunter", desc = "Capture a soul that only Azura's Star can hold.",
    }
    sb_achievements.registerAchievement {
        id        = "ContractedVamp",
        category  = cats.misc,
        condition = function()
            return tes3.mobilePlayer.hasVampirism == true
        end,
        icon      = iconPath .. "icn_vampfangs.dds",
        colour    = pData.colours.silver,
        title     = "Porphyric Hemophilia", desc = "Become a Vampire."
    }
    sb_achievements.registerAchievement {
        id        = "ContractedWere",
        category  = cats.misc,
        condition = function()
            return tes3.mobilePlayer.werewolf == true
        end,
        icon      = iconPath .. "icn_ContractedWere.dds",
        colour    = pData.colours.silver,
        title     = "Sanies Lupinus", desc = "Transform into a Werewolf for the first time."
    }
    sb_achievements.registerAchievement {
        id        = "Tarhielfall",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            local myData = pData.getData()
            return pData.calcFall()
        end,
        icon      = iconPath .. "icn_FallDamage.dds",
        colour    = pData.colours.silver,
        title     = "Tarhiel Impersonator", desc = "Survive a Tarhiel sized fall."
    }
    sb_achievements.registerAchievement {
        id        = "TarhielSavior",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            ---@param npc tes3npcInstance
            for npc in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                if (npc.baseObject.id == "agronian guy" and (npc.position:distance(tes3.player.position) < 128) and npc.isDead == false) then
                    return true
                end
            end
            return false
        end,
        icon      = iconPath .. "icn_TarhielSavior.dds",
        colour    = pData.colours.gold,
        title     = "Tarhiel's Savior", desc = "Save Tarhiel from his deadly fall."
    }
    sb_achievements.registerAchievement {
        id        = "Museum",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            ---@param npc tes3npcInstance
            for npc in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                if (npc.baseObject.id == "Torasa Aram") then
                    local Mcontext = npc.context
                    if (Mcontext.ringwarlock == 2  and Mcontext.eleidonsward == 2 and Mcontext.lordsmail == 2 and Mcontext.saviorshide == 2 and Mcontext.bootstenpace == 2 and Mcontext.ebonymail == 2 and Mcontext.bootsapostle == 2 and Mcontext.helmbloodworm == 2 and Mcontext.aurielshield == 2 and Mcontext.bootsblinding == 2 and Mcontext.bittermercy == 2 and Mcontext.umbrasword == 2 and Mcontext.chrysamere == 2 and Mcontext.daggerfang == 2 and Mcontext.aurielbow == 2 and Mcontext.velothjudgment == 2 and Mcontext.macemolagbal == 2 and Mcontext.bowshadows == 2 and Mcontext.dragonbone == 2 and Mcontext.goldbrand == 2 and Mcontext.helmbearclaw == 2 and Mcontext.iceblade == 2 and Mcontext.ringphynaster == 2 and Mcontext.skullcrusher == 2 and Mcontext.spellbreaker == 2 and Mcontext.staffhasedoki == 2 and Mcontext.staffmagnus == 2 and Mcontext.ringvampiric == 2 and Mcontext.maceslurring == 2 and Mcontext.bipolarblade == 2 and Mcontext.robelich == 2 and Mcontext.dagsym == 2) then
                        return true
                    end
                end
            end
        end,
        icon      = iconPath .. "icn_Museum.dds",
        colour    = pData.colours.plat,
        title     = "Museum Benefactor", desc = "Help the Mournhold Museum procure all 32 Artifacts."
    }
    sb_achievements.registerAchievement {
        id        = "Jailbird",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            local myData = pData.getData()
            if (tes3.mobilePlayer.inJail == true and myData["inJail"] == false) then
                myData["jail"] = myData["jail"] + 1
                myData["inJail"] = true
                event.register(tes3.event.menuExit, pData.onMenuExit)
            elseif (myData["jail"] == 5) then
                return true
            end
        end,
        icon      = iconPath .. "icn_jail.dds",
        colour    = pData.colours.silver,
        title     = "The Province Jails, They're Free", desc = "Get sent to jail 5 times."
    }
    sb_achievements.registerAchievement {
        id        = "KillTribunal",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            local vivec = tes3.getReference("vivec_god")
            if (vivec.isDead == true and tes3.getJournalIndex{ id = "TR_SothaSil"} >= 100) then
                return true
            end
        end,
        icon      = iconPath .. "icn_TribEnd.dds",
        colour    = pData.colours.gold,
        title     = "Tribunal's Judgment", desc = "The Tribunal ends as it began. With death."
    }
    sb_achievements.registerAchievement {
        id        = "GoodyTwoShoes",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            local myData = pData.getData()
            if (tes3.getJournalIndex{ id = "C3_DestroyDagoth"} >= 20 and tes3.getJournalIndex{ id = "TR_SothaSil"} >= 100 and tes3.getJournalIndex{ id = "BM_WildHunt"} >= 100 and myData["noBounty"]) then
                return true
            end
        end,
        icon      = iconPath .. "icn_GoodyTwoShoes.dds",
        colour    = pData.colours.plat,
        title     = "Lawful? Or Never Got Caught?", desc = "Complete all three main quests without (being caught) committing a crime."
    }
    sb_achievements.registerAchievement {
        id        = "MQDelayed",
        category  = cats.misc,
        configDesc = sb_achievements.configDesc.groupHidden,
        condition = function()
            if (tes3.getJournalIndex{ id = "A1_1_FindSpymaster"} <= 14 and tes3.getGlobal("DaysPassed") >=60) then
                return true
            end
        end,
        icon      = iconPath .. "icn_MQDelayed.dds",
        colour    = pData.colours.plat,
        title     = "What Main Quest?", desc = "Let 60 in days pass without starting the main quest."
    }
    sb_achievements.registerAchievement {
        id        = "daedrakill",
        category  = cats.misc,
        condition = function()
            local myData = pData.getData()
            if (myData["DaedraCount"]) == 11 then
                if (myData["DagothsCount"] == 47) then
                    event.unregister(tes3.event.death, pData.countKills)
                end
                return true
            end
        end,
        icon      = iconPath .. "icn_oblivion.dds",
        colour    = pData.colours.bronze,
        title     = "Send 'em Back To Oblivion", desc = "Kill one of each type of Daedra (Summons don't count)."
    }
    sb_achievements.registerAchievement {
        id        = "DwemerRuins",
        category  = cats.misc,
        condition = function()
            local myData = pData.getData()
            if (myData["DwemerRuinsCount"]) == 24 then
                event.unregister(tes3.event.cellChanged, pData.countDwem)
                return true
            end
        end,
        icon      = iconPath .. "icn_DwemerRuins.dds",
        colour    = pData.colours.silver,
        title     = "Only Spirits And Automatons Remain", desc = "Enter all 24 Dwemer ruins in Morrowind.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "DagothsKill",
        category  = cats.misc,
        condition = function()
            local myData = pData.getData()
            if (myData["DagothsCount"] == 47) then
                if (myData["DaedraCount"]) == 11 then
                    event.unregister(tes3.event.death, pData.countKills)
                end
                return true
            end
        end,
        icon      = iconPath .. "icn_DagothsKill.dds",
        colour    = pData.colours.gold,
        title     = "Reach Heaven Through Violence", desc = "Kill all named House Dagoth Leaders.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "Potion2",
        category  = cats.misc,
        condition = function()
            local myData = pData.getData()
            return myData["Potion"] >= 500
        end,
        icon      = iconPath .. "icn_potion2.dds",
        colour    = pData.colours.gold,
        title     = "Potion Afficionado", desc = "Create 500 potions",
    }
    sb_achievements.registerAchievement {
        id        = "Enchant2",
        category  = cats.misc,
        condition = function()
            local myData = pData.getData()
            if (myData["Enchant"] >= 100) then
                event.unregister(tes3.event.enchantedItemCreated, pData.countEnchantments)
                return true
            end
        end,
        icon      = iconPath .. "icn_Enchant2.dds",
        colour    = pData.colours.gold,
        title     = "Enchantment Afficionado", desc = "Create 100 enchanted items.",
    }
    sb_achievements.registerAchievement {
        id        = "Quests",
        category  = cats.misc,
        condition = function()
            local myData = pData.getData()
            if ( myData["Quests"] >= 50) then
                event.unregister(tes3.event.journal, pData.countQuests)
                return true
            end
        end,
        icon      = iconPath .. "icn_Quests.dds",
        colour    = pData.colours.gold,
        title     = "Finishing The job", desc = "Complete 50 quests.",
    }
    sb_achievements.registerAchievement {
        id        = "Armor150",
        category  = cats.misc,
        condition = function()
                return tes3.mobilePlayer.armorRating >= 150
        end,
        icon      = iconPath .. "icn_Armor150.dds",
        colour    = pData.colours.gold,
        title     = "Wall Of Defense", desc = "Reach an armor rating of at least 150.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "abolishionist",
        category  = cats.misc,
        condition = function()
                return tes3.getGlobal("FreedSlavesCounter") >= 50
        end,
        icon      = iconPath .. "icn_shackle.dds",
        colour    = pData.colours.plat,
        title     = "Abolitionist", desc = "Free 50 slaves in Morrowind.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "ordinator",
        category  = cats.misc,
        condition = function()
            local myData = pData.getData()
            return myData["Ordinator"]
        end,
        icon      = iconPath .. "icn_ordinator.dds",
        colour    = pData.colours.silver,
        title     = "Where Did You Get That?", desc = "Wear the holy armor of the Ordinators in front of one.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "Steal",
        category  = cats.misc,
        condition = function()
            local myData = pData.getData()
            if (myData["Stolen"] >= 100) then
                event.unregister(tes3.event.activate, pData.stealOrdActivate)
                return true
            end
        end,
        icon      = iconPath .. "icn_Steal.dds",
        colour    = pData.colours.silver,
        title     = "Sticky Fingers", desc = "Steal 100 items.",
    }
    sb_achievements.registerAchievement {
        id        = "ReadBooks",
        category  = cats.misc,
        condition = function()
            local myData = pData.getData()
            if (myData["BooksCount"] >= 50) then
                event.unregister(tes3.event.bookGetText, pData.countBooks)
                return true
            end
        end,
        icon      = iconPath .. "icn_ReadBooks.dds",
        colour    = pData.colours.silver,
        title     = "Lost In A Book", desc = "Read 50 different books.",
    }
end

local function initializedCallback(e)
    init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })
event.register(tes3.event.loaded, pData.initAchieveData)