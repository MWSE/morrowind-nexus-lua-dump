local core = require('openmw.core')
local l10n = core.l10n('OmwAchievements')

local baseAchievements = {
    {
        type = "single_quest",
        name = l10n('mq_01_name'),
        description = l10n('mq_01_description'),
        journalID = "a1_1_findspymaster",
        stage = 1,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_A1_1_1.dds",
        bgColor = "yellow",
        id = "mq_01",
        hidden = false
    },
    {
        type = "single_quest",
        name = l10n('mq_02_name'),
        description = l10n('mq_02_description'),
        journalID = "a1_1_findspymaster",
        stage = 14,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_A1_1_14.dds",
        bgColor = "yellow",
        id = "mq_02",
        hidden = false
    },
    {
        type = "single_quest",
        name = l10n('mq_03_name'),
        description = l10n('mq_03_description'),
        journalID = "a2_1_meetsulmatuul",
        stage = 60,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_A2_1_60.dds",
        bgColor = "yellow",
        id = "mq_03",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_04_name'),
        description = l10n('mq_04_description'),
        journalID = "a2_2_6thhouse",
        stage = 50,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_A2_2_50.dds",
        bgColor = "yellow",
        id = "mq_04",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_05_name'),
        description = l10n('mq_05_description'),
        journalID = "a2_3_corpruscure",
        stage = 40,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_A2_3_40.dds",
        bgColor = "yellow",
        id = "mq_05",
        hidden = true
    },
    {
        type = "multi_quest",
        name = l10n('mq_06_name'),
        description = l10n('mq_06_description'),
        journalID = { "b5_redoranhort",  "b6_hlaaluhort", "b7_telvannihort" },
        stage = { 50, 50, 50 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] and currentQuestStageTable[2] >= self.stage[2] and currentQuestStageTable[3] >= self.stage[3]
        end,
        icon = "Icons\\MAC\\icn_Hort.dds",
        bgColor = "yellow",
        id = "mq_06",
        hidden = true
    },
    {
        type = "multi_quest",
        name = l10n('mq_07_name'),
        description = l10n('mq_07_description'),
        journalID = { "b1_unifyurshilaku",  "b2_ahemmusasafe", "b3_zainabbride", "b4_killwarlovers" },
        stage = { 50, 50, 50, 55 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] and currentQuestStageTable[2] >= self.stage[2] and currentQuestStageTable[3] >= self.stage[3] and currentQuestStageTable[4] >= self.stage[4]
        end,
        icon = "Icons\\MAC\\icn_B_Nerevarine.dds",
        bgColor = "yellow",
        id = "mq_07",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_08_name'),
        description = l10n('mq_08_description'),
        journalID = "b8_meetvivec",
        stage = 34,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_B8_MeetVivec_34.dds",
        bgColor = "yellow",
        id = "mq_08",
        hidden = true
    },
    {
        type = "multi_quest",
        name = l10n('mq_09_name'),
        description = l10n('mq_09_description'),
        journalID = { "cx_backpath",  "c3_destroydagoth" },
        stage = { 50, 20 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] and currentQuestStageTable[2] >= self.stage[2]
        end,
        icon = "Icons\\MAC\\icn_SecretPath.dds",
        bgColor = "yellow",
        id = "mq_09",
        hidden = true
    },
    {
        type = "unique",
        name = l10n('dayspassed_01_name'),
        description = l10n('dayspassed_01_description'),
        icon = "Icons\\MAC\\icn_MQDelayed.dds",
        bgColor = "purple",
        id = "dayspassed_01"
    },
    {
        type = "single_quest",
        name = l10n('mq_10_name'),
        description = l10n('mq_10_description'),
        journalID = "c3_destroydagoth",
        stage = 20,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_C3_DestroyDagoth_20.dds",
        bgColor = "yellow",
        id = "mq_10",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_13_name'),
        description = l10n('mq_13_description'),
        journalID = "tr_mhattack",
        stage = 110,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_MHAttack.dds",
        bgColor = "yellow",
        id = "mq_13",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_14_name'),
        description = l10n('mq_14_description'),
        journalID = "tr_blade",
        stage = 100,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_TRBlade.dds",
        bgColor = "yellow",
        id = "mq_14",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_15_name'),
        description = l10n('mq_15_description'),
        journalID = "tr_sothasil",
        stage = 100,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_TRAlmaEnd.dds",
        bgColor = "yellow",
        id = "mq_15",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_17_name'),
        description = l10n('mq_17_description'),
        journalID = "BM_CariusGone",
        stage = 30,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_BM_MeetSkaal.dds",
        bgColor = "yellow",
        id = "mq_17",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_18_name'),
        description = l10n('mq_18_description'),
        journalID = "bm_skaalattack",
        stage = 30,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_BM_DefendSkaal.dds",
        bgColor = "yellow",
        id = "mq_18",
        hidden = true
    },
    {
        type = "multi_quest",
        name = l10n('mq_19_name'),
        description = l10n('mq_19_description'),
        journalID = { "BM_FrostGiant2",  "BM_FrostGiant1" },
        stage = { 100, 100 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] or currentQuestStageTable[2] >= self.stage[2]
        end,
        icon = "Icons\\MAC\\icn_BM_Karstaag.dds",
        bgColor = "yellow",
        id = "mq_19",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_20_name'),
        description = l10n('mq_20_description'),
        journalID = "bm_wildhunt",
        stage = 100,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_BM_WildHunt.dds",
        bgColor = "yellow",
        id = "mq_20",
        hidden = true
    },
    {
        type = "multi_quest",
        name = l10n('mq_21_name'),
        description = l10n('mq_21_description'),
        journalID = { "c3_destroydagoth", "tr_sothasil", "bm_wildhunt"},
        stage = { 20, 100, 100 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] and currentQuestStageTable[2] >= self.stage[2] and currentQuestStageTable[3] >= self.stage[3]
        end,
        icon = "Icons\\MAC\\icn_AllMainQ.dds",
        bgColor = "yellow",
        id = "mq_21",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('sq_01_name'),
        description = l10n('sq_01_description'),
        journalID = "ms_fargothring",
        stage = 100,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_FargothsRing.dds",
        bgColor = "red",
        id = "sq_01",
        hidden = false
    },
    {
        type = "multi_quest",
        name = l10n('sq_02_name'),
        description = l10n('sq_02_description'),
        journalID = { "tt_fieldskummu", "tt_stopmoon", "tt_palacevivec", "tt_puzzlecanal", "tt_maskvivec", "tt_ruddyman", "tt_ghostgate" },
        stage = { 100, 100, 100, 100, 100, 100, 100 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] and currentQuestStageTable[2] >= self.stage[2] and currentQuestStageTable[3] >= self.stage[3] and currentQuestStageTable[4] >= self.stage[4] and currentQuestStageTable[5] >= self.stage[5] and currentQuestStageTable[6] >= self.stage[6] and currentQuestStageTable[7] >= self.stage[7]
        end,
        icon = "Icons\\MAC\\icn_Pilgrimages.dds",
        bgColor = "red",
        id = "sq_02",
        hidden = false
    },
    {
        type = "multi_quest",
        name = l10n('sq_03_name'),
        description = l10n('sq_03_description'),
        journalID = { "mv_abusedhealer", "mv_recoverwidowmaker", "mv_paralyzedbarbarian" },
        stage = { 75, 70, 100 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] and currentQuestStageTable[2] >= self.stage[2] and currentQuestStageTable[3] >= self.stage[3]
        end,
        icon = "Icons\\MAC\\icn_NakedNords.dds",
        bgColor = "red",
        id = "sq_03",
        hidden = false
    },
    {
        type = "single_quest",
        name = l10n('sq_04_name'),
        description = l10n('sq_04_description'),
        journalID = "bm_sadseer",
        stage = 110,
        operator = function(self, givenStage)
            return givenStage == self.stage
        end,
        icon = "Icons\\MAC\\icn_GlimpseFuture.dds",
        bgColor = "red",
        id = "sq_04",
        hidden = false
    },
    {
        type = "multi_quest",
        name = l10n('sq_05_name'),
        description = l10n('sq_05_description'),
        journalID = { "EB_Unrequited", "MS_MatchMaker", "MV_MissingCompanion", "MV_VictimRomance", "MV_VictimRomance" },
        stage = { 110, 120, 60, 100, 105 },
        operator = function(self, currentQuestStageTable)
            return((currentQuestStageTable[1] >= self.stage[1]) and (currentQuestStageTable[2] == self.stage[2]) and (currentQuestStageTable[3] == self.stage[3]) and (currentQuestStageTable[4] == self.stage[4]) and ((currentQuestStageTable[5]) == self.stage[5] or (currentQuestStageTable[6] == self.stage[6])))
        end,
        icon = "Icons\\MAC\\icn_lovers.dds",
        bgColor = "red",
        id = "sq_05",
        hidden = false
    },
    {
        type = "unique",
        name = l10n('werewolf_01_name'),
        description = l10n('werewolf_01_description'),
        icon = "Icons\\MAC\\icn_ContractedWere.dds",
        bgColor = "purple",
        id = "werewolf_01",
        hidden = false
    },
    {
        type = "multi_quest",
        name = l10n('sq_06_name'),
        description = l10n('sq_06_description'),
        journalID = { "BM_WolfGiver", "BM_WolfGiver_a" },
        stage = { 120, 20 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] or currentQuestStageTable[2] >= self.stage[2]
        end,
        icon = "Icons\\MAC\\icn_CureWere.dds",
        bgColor = "red",
        id = "sq_06",
        hidden = true
    },
    {
        type = "multi_quest",
        name = l10n('sq_07_name'),
        description = l10n('sq_07_description'),
        journalID = { "DA_Azura", "DA_Boethiah", "DA_Malacath", "DA_Mehrunes", "DA_Mephala", "DA_MolagBal", "DA_Sheogorath" },
        stage = { 40, 70, 70, 40, 60, 30, 70 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] and currentQuestStageTable[2] >= self.stage[2] and currentQuestStageTable[3] >= self.stage[3] and currentQuestStageTable[4] >= self.stage[4] and currentQuestStageTable[5] == self.stage[5] and currentQuestStageTable[6] == self.stage[6] and currentQuestStageTable[7] == self.stage[7]
        end,
        icon = "Icons\\MAC\\icn_Daedrashrines.dds",
        bgColor = "red",
        id = "sq_07",
        hidden = true
    },
    {
        type = "single_quest",
        name = l10n('mq_11_name'),
        description = l10n('mq_11_description'),
        journalID = "tr_dbattack",
        stage = 60,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_ToMournhold.dds",
        bgColor = "yellow",
        id = "mq_11",
        hidden = false
    },
    {
        type = "single_quest",
        name = l10n('mq_16_name'),
        description = l10n('mq_16_description'),
        journalID = "bm_rumors",
        stage = 100,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_ToSolstheim.dds",
        bgColor = "yellow",
        id = "mq_16",
        hidden = false
    },
    {
        type = "single_quest",
        name = l10n('mq_12_name'),
        description = l10n('mq_12_description'),
        journalID = "tr_dbhunt",
        stage = 60,
        operator = function(self, givenStage)
            return givenStage >= self.stage
        end,
        icon = "Icons\\MAC\\icn_HuntDB.dds",
        bgColor = "yellow",
        id = "mq_12",
        hidden = true
    },
    {
        type = "multi_quest",
        name = l10n('sq_08_name'),
        description = l10n('sq_08_description'),
        journalID = { "VA_VampChild", "VA_VampHunter", "VA_VampBlood", "VA_VampCountess", "VA_VampCult", "VA_VampAmulet" },
        stage = { 40, 70, 70, 40, 60, 30 },
        operator = function(self, currentQuestStageTable)
            return(
                ((currentQuestStageTable[1] >= self.stage[1]) and (currentQuestStageTable[2] >= self.stage[2])) or
                ((currentQuestStageTable[3] >= self.stage[3]) and (currentQuestStageTable[4] >= self.stage[4])) or
                ((currentQuestStageTable[5] >= self.stage[5]) and (currentQuestStageTable[6] >= self.stage[6]))
            )
        end,
        icon = "Icons\\MAC\\icn_VampQuests.dds",
        bgColor = "red",
        id = "sq_08",
        hidden = true
    },
    {
        type = "unique",
        name = l10n('book_01_name'),
        description = l10n('book_01_description'),
        icon = "Icons\\MAC\\icn_ReadBooks.dds",
        bgColor = "purple",
        id = "book_01",
        hidden = false
    },
    {
        type = "talkto",
        name = l10n('tt_01_name'),
        description = l10n('tt_01_description'),
        recordId = "scamp_creeper",
        icon = "Icons\\MAC\\icn_Creeper.dds",
        bgColor = "blue",
        id = "tt_01",
        hidden = false
    },
    {
        type = "talkto",
        name = l10n('tt_01_description'),
        description = l10n('tt_02_description'),
        recordId = "mudcrab_unique",
        icon = "Icons\\MAC\\icn_MudcrabMerchant.dds",
        bgColor = "blue",
        id = "tt_02",
        hidden = false
    },
    {
        type = "talkto",
        name = l10n('tt_03_name'),
        description = l10n('tt_03_description'),
        recordId = "agronian guy",
        icon = "Icons\\MAC\\icn_TarhielSavior.dds",
        bgColor = "blue",
        id = "tt_03",
        hidden = false
    },
    {
        type = "talkto",
        name = l10n('tt_04_name'),
        description = l10n('tt_04_description'),
        recordId = "m'aiq",
        icon = "Icons\\MAC\\icn_theLiar.dds",
        bgColor = "blue",
        id = "tt_04",
        hidden = true
    },
    {
        type = "unique",
        name = l10n('killtribunal_01_name'),
        description = l10n('killtribunal_01_description'),
        icon = "Icons\\MAC\\icn_TribEnd.dds",
        bgColor = "purple",
        id = "killtribunal_01",
        hidden = true
    },
    {
        type = "join_faction",
        name = l10n('fc_01_name'),
        description = l10n('fc_01_description'),
        factionId = "mages guild",
        icon = "Icons\\MAC\\icn_MGJoin.dds",
        bgColor = "green",
        id = "fc_01",
        hidden = false
    },
    {
        type = "join_faction",
        name = l10n('fc_02_name'),
        description = l10n('fc_02_description'),
        factionId = "thieves guild",
        icon = "Icons\\MAC\\icn_TGJoin.dds",
        bgColor = "green",
        id = "fc_02",
        hidden = false
    },
    {
        type = "join_faction",
        name = l10n('fc_03_name'),
        description = l10n('fc_03_description'),
        factionId = "fighters guild",
        icon = "Icons\\MAC\\icn_FGJoin.dds",
        bgColor = "green",
        id = "fc_03",
        hidden = false
    },
    {
        type = "join_faction",
        name = l10n('fc_04_name'),
        description = l10n('fc_04_description'),
        factionId = "morag tong",
        icon = "Icons\\MAC\\icn_MTJoin.dds",
        bgColor = "green",
        id = "fc_04",
        hidden = false
    },
    {
        type = "join_faction",
        name = l10n('fc_05_name'),
        description = l10n('fc_05_description'),
        factionId = "imperial legion",
        icon = "Icons\\MAC\\icn_ILJoin.dds",
        bgColor = "green",
        id = "fc_05",
        hidden = false
    },
    {
        type = "join_faction",
        name = l10n('fc_06_name'),
        description = l10n('fc_06_description'),
        factionId = "imperial cult",
        icon = "Icons\\MAC\\icn_ICJoin.dds",
        bgColor = "green",
        id = "fc_06",
        hidden = false
    },
    {
        type = "join_faction",
        name = l10n('fc_07_name'),
        description = l10n('fc_07_description'),
        factionId = "temple",
        icon = "Icons\\MAC\\icn_TTJoin.dds",
        bgColor = "green",
        id = "fc_07",
        hidden = false
    },
    {
        type = "join_faction",
        name = l10n('fc_08_name'),
        description = l10n('fc_08_description'),
        factionId = "east empire company",
        icon = "Icons\\MAC\\icn_EECJoin.dds",
        bgColor = "green",
        id = "fc_08",
        hidden = false
    },
    {
        type = "join_faction",
        name = l10n('fc_09_name'),
        description = l10n('fc_09_description'),
        factionId = { "telvanni", "redoran", "hlaalu" },
        icon = "Icons\\MAC\\icn_GHJoined.dds",
        bgColor = "green",
        id = "fc_09",
        hidden = false
    },
    {
        type = "rank_faction",
        name = l10n('fc_10_name'),
        description = l10n('fc_10_description'),
        factionId = "mages guild",
        rank = 10,
        icon = "Icons\\MAC\\icn_MGArchmage.dds",
        bgColor = "aqua",
        id = "fc_10",
        hidden = true
    },
    {
        type = "rank_faction",
        name = l10n('fc_11_name'),
        description = l10n('fc_11_description'),
        factionId = "thieves guild",
        rank = 10,
        icon = "Icons\\MAC\\icn_TGMasterThief.dds",
        bgColor = "aqua",
        id = "fc_11",
        hidden = true
    },
    {
        type = "rank_faction",
        name = l10n('fc_12_name'),
        description = l10n('fc_12_description'),
        factionId = "fighters guild",
        rank = 10,
        icon = "Icons\\MAC\\icn_FGMaster.dds",
        bgColor = "aqua",
        id = "fc_12",
        hidden = true
    },
    {
        type = "rank_faction",
        name = l10n('fc_13_name'),
        description = l10n('fc_13_description'),
        factionId = "morag tong",
        rank = 10,
        icon = "Icons\\MAC\\icn_MTGrandmaster.dds",
        bgColor = "aqua",
        id = "fc_13",
        hidden = true
    },
    {
        type = "rank_faction",
        name = l10n('fc_14_name'),
        description = l10n('fc_14_description'),
        factionId = "imperial legion",
        rank = 10,
        icon = "Icons\\MAC\\icn_ILDragKnight.dds",
        bgColor = "aqua",
        id = "fc_14",
        hidden = true
    },
    {
        type = "rank_faction",
        name = l10n('fc_15_name'),
        description = l10n('fc_15_description'),
        factionId = "imperial cult",
        rank = 10,
        icon = "Icons\\MAC\\icn_ICPrimate.dds",
        bgColor = "aqua",
        id = "fc_15",
        hidden = true
    },
    {
        type = "rank_faction",
        name = l10n('fc_16_name'),
        description = l10n('fc_16_description'),
        factionId = "temple",
        rank = 10,
        icon = "Icons\\MAC\\icn_TTPatriarch.dds",
        bgColor = "aqua",
        id = "fc_16",
        hidden = true
    },
    {
        type = "rank_faction",
        name = l10n('fc_17_name'),
        description = l10n('fc_17_description'),
        factionId = "east empire company",
        rank = 9,
        icon = "Icons\\MAC\\icn_EECFactor.dds",
        bgColor = "aqua",
        id = "fc_17",
        hidden = true
    },
    {
        type = "multi_quest",
        name = l10n('fc_18_name'),
        description = l10n('fc_18_description'),
        journalID = { "HH_Stronghold", "HR_Stronghold", "HT_Stronghold" },
        stage = { 300, 300, 300 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] == self.stage[1] or currentQuestStageTable[2] == self.stage[2] or currentQuestStageTable[3] == self.stage[3]
        end,
        icon = "Icons\\MAC\\icn_stronghold.dds",
        bgColor = "aqua",
        id = "fc_18",
        hidden = false
    }
}

return baseAchievements