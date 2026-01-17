local core = require('openmw.core')
local l10n = core.l10n('OmwAchievements')
local types = require('openmw.types')

local slot = types.Actor.EQUIPMENT_SLOT

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
            return currentQuestStageTable[1] >= self.stage[1] and
            currentQuestStageTable[2] >= self.stage[2] and
            currentQuestStageTable[3] >= self.stage[3]
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 3

            for i = 1, 3 do
                if currentQuestStageTable[i] ~= nil then
                    if currentQuestStageTable[i] >= self.stage[i] then
                        progress = progress + 1
                    end
                end
            end

            return {progress, progressMax}
            
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
            return currentQuestStageTable[1] >= self.stage[1] and
            currentQuestStageTable[2] >= self.stage[2] and
            currentQuestStageTable[3] >= self.stage[3] and
            currentQuestStageTable[4] >= self.stage[4]
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 4

            for i = 1, 4 do
                if currentQuestStageTable[i] ~= nil then
                    if currentQuestStageTable[i] >= self.stage[i] then
                        progress = progress + 1
                    end
                end
            end

            return {progress, progressMax}
            
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
            return currentQuestStageTable[1] >= self.stage[1] and
            currentQuestStageTable[2] >= self.stage[2]
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 2

            if currentQuestStageTable[1] >= self.stage[1] then
                progress = progress + 1
            end

            if currentQuestStageTable[2] >= self.stage[2] then
                progress = progress + 1
            end

            return {progress, progressMax}

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
            return currentQuestStageTable[1] >= self.stage[1] or
            currentQuestStageTable[2] >= self.stage[2]
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
            return currentQuestStageTable[1] >= self.stage[1] and
            currentQuestStageTable[2] >= self.stage[2] and
            currentQuestStageTable[3] >= self.stage[3]
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 3

            for i = 1, 3 do
                if currentQuestStageTable[i] ~= nil then
                    if currentQuestStageTable[i] >= self.stage[i] then
                        progress = progress + 1
                    end
                end
            end

            return {progress, progressMax}
            
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
            return currentQuestStageTable[1] >= self.stage[1] and
            currentQuestStageTable[2] >= self.stage[2] and
            currentQuestStageTable[3] >= self.stage[3] and
            currentQuestStageTable[4] >= self.stage[4] and
            currentQuestStageTable[5] >= self.stage[5] and
            currentQuestStageTable[6] >= self.stage[6] and
            currentQuestStageTable[7] >= self.stage[7]
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 7

            for i = 1, 7 do
                if currentQuestStageTable[i] ~= nil then
                    if currentQuestStageTable[i] >= self.stage[i] then
                        progress = progress + 1
                    end
                end
            end

            return {progress, progressMax}
            
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
            return currentQuestStageTable[1] >= self.stage[1] and
            currentQuestStageTable[2] >= self.stage[2] and
            currentQuestStageTable[3] >= self.stage[3]
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 3

            for i = 1, 3 do
                if currentQuestStageTable[i] ~= nil then
                    if currentQuestStageTable[i] >= self.stage[i] then
                        progress = progress + 1
                    end
                end
            end

            return {progress, progressMax}
            
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
            return currentQuestStageTable[1] >= self.stage[1] and
            currentQuestStageTable[2] == self.stage[2] and
            currentQuestStageTable[3] == self.stage[3] and
            ((currentQuestStageTable[4] == self.stage[4]) or (currentQuestStageTable[5] == self.stage[5]))
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 4

            if currentQuestStageTable[1] >= self.stage[1] then
                progress = progress + 1
            end

            if currentQuestStageTable[2] == self.stage[2] then
                progress = progress + 1
            end

            if currentQuestStageTable[3] == self.stage[3] then
                progress = progress + 1
            end

            if currentQuestStageTable[4] == self.stage[4] or currentQuestStageTable[5] == self.stage[5] then
                progress = progress + 1
            end

            return {progress, progressMax}
            
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
            return currentQuestStageTable[1] >= self.stage[1] and
            currentQuestStageTable[2] >= self.stage[2] and
            currentQuestStageTable[3] >= self.stage[3] and
            currentQuestStageTable[4] >= self.stage[4] and
            currentQuestStageTable[5] == self.stage[5] and
            currentQuestStageTable[6] == self.stage[6] and
            currentQuestStageTable[7] == self.stage[7]
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 7

            for i = 1, 7 do
                if currentQuestStageTable[i] ~= nil then
                    if currentQuestStageTable[i] >= self.stage[i] then
                        progress = progress + 1
                    end
                end
            end

            return {progress, progressMax}
            
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
            return ((currentQuestStageTable[1] >= self.stage[1]) and (currentQuestStageTable[2] >= self.stage[2])) or
                ((currentQuestStageTable[3] >= self.stage[3]) and (currentQuestStageTable[4] >= self.stage[4])) or
                ((currentQuestStageTable[5] >= self.stage[5]) and (currentQuestStageTable[6] >= self.stage[6]))
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 2

            if currentQuestStageTable[1] >= self.stage[1] and currentQuestStageTable[2] < self.stage[2] then
                progress = progress + 1
            end

            if currentQuestStageTable[3] >= self.stage[3] and currentQuestStageTable[4] < self.stage[4] then
                progress = progress + 1
            end
            
            if currentQuestStageTable[5] >= self.stage[5] and currentQuestStageTable[6] < self.stage[6] then
                progress = progress + 1
            end

            return {progress, progressMax}
            
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
        name = l10n('tt_02_name'),
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
        type = "visit_all",
        name = l10n('vall_01_name'),
        description = l10n('vall_01_description'),
        cells = {
            "aleft",
            "arkngthand, hall of centrifuge",
            "arkngthunch-sturdumz",
            "gnisis, bethamez",
            "bthanchend",
            "bthuand",
            "bthungthumz",
            "dagoth ur, outer facility",
            "druscashti, upper level",
            "endusal, kagrenac's study",
            "galom daeus, entry",
            "mudan, lost dwemer checkpoint",
            "mzahnch",
            "mzanchend",
            "mzuleft",
            "nchardahrk",
            "nchardumz",
            "nchuleft",
            "nchuleftingth, upper levels",
            "nchurdamz",
            "odrosal, dwemer training academy",
            "tureynulal, kagrenac's library",
            "vemynal, outer fortress",
            "bamz-amschend, hearthfire hall"
        },
        icon = "Icons\\MAC\\icn_DwemerRuins.dds",
        bgColor = "blue",
        id = "vall_01",
        hidden = false
    },
    {
        type = "visit_all",
        name = l10n('vall_02_name'),
        description = l10n('vall_02_description'),
        cells = {
            "lleran ancestral tomb",
            "othrelas ancestral tomb",
            "sandas ancestral tomb",
            "sarano ancestral tomb",
            "aryon ancestral tomb",
            "dareleth ancestral tomb",
            "drath ancestral tomb",
            "drinith ancestral tomb",
            "fadathram ancestral tomb",
            "helas ancestral tomb",
            "indaren ancestral tomb",
            "llando ancestral tomb",
            "omalen ancestral tomb",
            "rothan ancestral tomb",
            "salvel ancestral tomb",
            "sandus ancestral tomb",
            "saren ancestral tomb",
            "thalas ancestral tomb",
            "andalen ancestral tomb",
            "arano ancestral tomb",
            "arenim ancestral tomb",
            "arys ancestral tomb",
            "baram ancestral tomb",
            "beran ancestral tomb",
            "dreloth ancestral tomb",
            "hlaalu ancestral tomb",
            "hlervi ancestral tomb",
            "hlervu ancestral tomb",
            "marvani ancestral tomb",
            "omaren ancestral tomb",
            "ravel ancestral tomb",
            "raviro ancestral tomb",
            "redas ancestral tomb",
            "releth ancestral tomb",
            "sadryon ancestral tomb",
            "savel ancestral tomb",
            "verelnim ancestral tomb",
            "andrano ancestral tomb",
            "andrethi ancestral tomb",
            "heran ancestral tomb",
            "norvayn ancestral tomb",
            "samarys ancestral tomb",
            "sarys ancestral tomb",
            "thelas ancestral tomb",
            "andalor ancestral tomb",
            "aralen ancestral tomb",
            "favel ancestral tomb",
            "ienith ancestral tomb",
            "nerano ancestral tomb",
            "sethan ancestral tomb",
            "thiralas ancestral tomb",
            "venim ancestral tomb",
            "alas ancestral tomb",
            "andas ancestral tomb",
            "andules ancestral tomb",
            "aran ancestral tomb",
            "arethan ancestral tomb",
            "dulo ancestral tomb",
            "gimothran ancestral tomb",
            "helan ancestral tomb",
            "maren ancestral tomb",
            "serano ancestral tomb",
            "vandus ancestral tomb",
            "velas ancestral tomb",
            "andavel ancestral tomb",
            "dralas ancestral tomb",
            "drethan ancestral tomb",
            "nelas ancestral tomb",
            "orethi ancestral tomb",
            "sarethi ancestral tomb",
            "senim ancestral tomb",
            "alen ancestral tomb",
            "falas ancestral tomb",
            "ginith ancestral tomb",
            "heleran ancestral tomb",
            "hleran ancestral tomb",
            "indalen ancestral tomb",
            "llervu ancestral tomb",
            "randas ancestral tomb",
            "reloth ancestral tomb",
            "rethandus ancestral tomb",
            "salothan ancestral tomb",
            "salothran ancestral tomb",
            "seran ancestral tomb",
            "telvayn ancestral tomb",
            "tharys ancestral tomb",
            "uveran ancestral tomb",
            "veloth ancestral tomb"
        },
        icon = "Icons\\MAC\\icn_echoOfThePast.dds",
        bgColor = "blue",
        id = "vall_02",
        hidden = false
    },
    {
        type = "visit_all",
        name = l10n('vall_03_name'),
        description = l10n('vall_03_description'),
        cells = {
            "caldera mine",
            "elith-pal mine",
            "mausur caverns",
            "sudanit mine",
            "vassir-didanat cave",
            "yanemus mine",
            "dissapla mine",
            "dunirai caverns",
            "halit mine",
            "massama cave",
            "yassu mine",
            "abaelun mine",
            "abaesen-pulu egg mine",
            "abebaal egg mine",
            "ahallaraddon egg mine",
            "ahanibi-malmus egg mine",
            "akimaes-ilanipu egg mine",
            "asha-ahhe egg mine",
            "ashimanu egg mine",
            "band egg mine",
            "eluba-addon egg mine",
            "eretammus-sennammu egg mine",
            "gnisis, eggmine",
            "hairat-vassamsi egg mine",
            "hawia egg mine",
            "inanius egg mine",
            "madas-zebba egg mine",
            "maelu egg mine",
            "maesa-shammus egg mine",
            "matus-akin egg mine",
            "missir-dadalit egg mine",
            "mudan-mul egg mine",
            "panabanit-nimawia egg mine",
            "panud egg mine",
            "pudai egg mine",
            "sarimisun-assa egg mine",
            "setus egg mine",
            "shulk egg mine",
            "shurdan-raplay egg mine",
            "sinamusa egg mine",
            "sinarralit egg mine",
            "sur egg mine",
            "vansunalit egg mine",
            "zalkin-sul egg mine"
        },
        icon = "Icons\\MAC\\icn_underTheEmpire.dds",
        bgColor = "blue",
        id = "vall_03",
        hidden = false
    },
    {
        type = "visit_all",
        name = l10n('vall_04_name'),
        description = l10n('vall_04_description'),
        cells = {
            "andasreth",
            "berandas",
            "valenvaryon",
            "indoranyon",
            "kogoruhn",
            "marandus",
            "rotheran",
            "telasero",
            "falasmaryon",
            "falensarano",
            "hlormaren"
        },
        icon = "Icons\\MAC\\icn_dunmerStr.dds",
        bgColor = "blue",
        id = "vall_04",
        hidden = false
    },
    {
        type = "unique",
        name = l10n('museum_01_name'),
        description = l10n('museum_01_description'),
        icon = "Icons\\MAC\\icn_Museum.dds",
        bgColor = "purple",
        id = "museum_01",
        hidden = false
    },
    {
        type = "read_all",
        name = l10n('vivec_lessons_01_name'),
        description = l10n('vivec_lessons_01_description'),
        books = {
            "bookskill_athletics3",
            "bookskill_alchemy4",
            "bookskill_blunt weapon4",
            "bookskill_mysticism3",
            "bookskill_axe4",
            "bookskill_armorer3",
            "bookskill_block4",
            "bookskill_athletics4",
            "bookskill_blunt weapon5",
            "bookskill_short blade4",
            "bookskill_unarmored3",
            "bookskill_heavy armor5",
            "bookskill_alteration4",
            "bookskill_spear3",
            "bookskill_unarmored4",
            "bookskill_axe5",
            "bookskill_long blade3",
            "bookskill_alchemy5",
            "bookskill_enchant4",
            "bookskill_long blade4",
            "bookskill_light armor4",
            "bookskill_medium armor4",
            "bookskill_long blade5",
            "bookskill_spear4",
            "bookskill_armorer4",
            "bookskill_sneak5",
            "bookskill_speechcraft5",
            "bookskill_light armor5",
            "bookskill_armorer5",
            "bookskill_short blade5",
            "bookskill_athletics5",
            "bookskill_block5",
            "bookskill_medium armor5",
            "bookskill_unarmored5",
            "bookskill_spear5",
            "bookskill_mysticism4"
        },
        icon = "Icons\\MAC\\icn_vivecLessons.dds",
        bgColor = "purple",
        id = "vivec_lessons_01",
        hidden = false
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
        type = "unique",
        name = l10n('skooma_01_name'),
        description = l10n('skooma_01_description'),
        icon = "Icons\\MAC\\icn_skoomaDrink.dds",
        bgColor = "purple",
        id = "skooma_01",
        hidden = true
    },
    {
        type = "multi_quest",
        name = l10n('sq_09_name'),
        description = l10n('sq_09_description'),
        journalID = { "MT_S_BalancedArmor", "MT_S_DeepBiting", "MT_S_Denial", "MT_S_Fleetness", "MT_S_FluidEvasion", "MT_S_GlibSpeech", "MT_S_Golden", "MT_S_Green", "MT_S_Hewing", "MT_S_HornyFist", "MT_S_Impaling", "MT_S_Leaping", "MT_S_MartialCraft", "MT_S_NimbleArmor", "MT_S_Red", "MT_S_Safekeeping", "MT_S_Silver", "MT_S_Smiting", "MT_S_Stalking", "MT_S_StolidArmor", "MT_S_Sublime", "MT_S_Sureflight", "MT_S_Swiftblade", "MT_S_Transcendent", "MT_S_Transfiguring", "MT_S_Unseen" },
        stage = {
            100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
            100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
            100, 100, 100, 100, 100, 100
        },
        operator = function(self, currentQuestStageTable)
            return(
                (currentQuestStageTable[1] >= self.stage[1]) and
                (currentQuestStageTable[2] >= self.stage[2]) and
                (currentQuestStageTable[3] >= self.stage[3]) and
                (currentQuestStageTable[4] >= self.stage[4]) and
                (currentQuestStageTable[5] >= self.stage[5]) and
                (currentQuestStageTable[6] >= self.stage[6]) and
                (currentQuestStageTable[7] >= self.stage[7]) and
                (currentQuestStageTable[8] >= self.stage[8]) and
                (currentQuestStageTable[9] >= self.stage[9]) and
                (currentQuestStageTable[10] >= self.stage[10]) and
                (currentQuestStageTable[11] >= self.stage[11]) and
                (currentQuestStageTable[12] >= self.stage[12]) and
                (currentQuestStageTable[13] >= self.stage[13]) and
                (currentQuestStageTable[14] >= self.stage[14]) and
                (currentQuestStageTable[15] >= self.stage[15]) and
                (currentQuestStageTable[16] >= self.stage[16]) and
                (currentQuestStageTable[17] >= self.stage[17]) and
                (currentQuestStageTable[18] >= self.stage[18]) and
                (currentQuestStageTable[19] >= self.stage[19]) and
                (currentQuestStageTable[20] >= self.stage[20]) and
                (currentQuestStageTable[21] >= self.stage[21]) and
                (currentQuestStageTable[22] >= self.stage[22]) and
                (currentQuestStageTable[23] >= self.stage[23]) and
                (currentQuestStageTable[24] >= self.stage[24]) and
                (currentQuestStageTable[25] >= self.stage[25]) and
                (currentQuestStageTable[26] >= self.stage[26])
            )
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 26

            for i = 1, 26 do
                if currentQuestStageTable[i] ~= nil then
                    if currentQuestStageTable[i] >= self.stage[i] then
                        progress = progress + 1
                    end
                end
            end

            return {progress, progressMax}
            
        end,
        icon = "Icons\\MAC\\icn_webOfMephala.dds",
        bgColor = "red",
        id = "sq_09",
        hidden = false
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
        type = "equipment",
        name = l10n('eq_01_name'),
        description = l10n('eq_01_description'),
        equipment = {
            [slot.Boots] = "daedric_boots",
            [slot.Cuirass] = {"daedric_cuirass", "daedric_cuirass_htab"},
            [slot.Greaves] = {"daedric_greaves", "daedric_greaves_htab"},
            [slot.LeftGauntlet] = "daedric_gauntlet_left",
            [slot.RightGauntlet] = "daedric_gauntlet_right",
            [slot.LeftPauldron] = "daedric_pauldron_left",
            [slot.RightPauldron] = "daedric_pauldron_right",
            [slot.Helmet] = {"daedric_god_helm", "daedric_fountain_helm", "daedric_terrifying_helm"},
            [slot.CarriedLeft] = {"daedric_shield", "daedric_towershield"}
        },
        icon = "Icons\\MAC\\icn_daedricEq.dds",
        bgColor = "blue",
        id = "eq_01",
        hidden = false
    },
    {
        type = "equipment",
        name = l10n('eq_02_name'),
        description = l10n('eq_02_description'),
        equipment = {
            [slot.Boots] = "glass_boots",
            [slot.Cuirass] = "glass_cuirass",
            [slot.Greaves] = "glass_greaves",
            [slot.LeftGauntlet] = "glass_bracer_left",
            [slot.RightGauntlet] = "glass_bracer_right",
            [slot.LeftPauldron] = "glass_pauldron_left",
            [slot.RightPauldron] = "glass_pauldron_right",
            [slot.Helmet] = "glass_helm",
            [slot.CarriedLeft] = {"glass_shield", "glass_towershield"}
        },
        icon = "Icons\\MAC\\icn_glassEq.dds",
        bgColor = "blue",
        id = "eq_02",
        hidden = false
    },
    {
        type = "equipment",
        name = l10n('eq_03_name'),
        description = l10n('eq_03_description'),
        equipment = {
            [slot.Boots] = "adamantium boots",
            [slot.Cuirass] = "adamantium_cuirass",
            [slot.Greaves] = "adamantium_greaves",
            [slot.LeftGauntlet] = "adamantium_bracer_left",
            [slot.RightGauntlet] = "adamantium_bracer_right",
            [slot.LeftPauldron] = "adamantium_pauldron_left",
            [slot.RightPauldron] = "adamantium_pauldron_right",
            [slot.Helmet] = {"adamantium_helm", "addamantium_helm"}
        },
        icon = "Icons\\MAC\\icn_adamantiumEq.dds",
        bgColor = "blue",
        id = "eq_03",
        hidden = false
    },
    {
        type = "unique",
        name = l10n('ordinator_01_name'),
        description = l10n('ordinator_01_description'),
        icon = "Icons\\MAC\\icn_ordinator.dds",
        bgColor = "purple",
        id = "ordinator_01",
        hidden = true
    },
    {
        type = "unique",
        name = l10n('free_slaves_01_name'),
        description = l10n('free_slaves_01_description'),
        icon = "Icons\\MAC\\icn_shackle.dds",
        bgColor = "purple",
        id = "free_slaves_01",
        hidden = false
    },
    {
        type = "unique",
        name = l10n('orc_intelligence_01_name'),
        description = l10n('orc_intelligence_01_description'),
        icon = "Icons\\MAC\\icn_orcIntelligence.dds",
        bgColor = "purple",
        id = "orc_intelligence_01",
        hidden = false
    },
    {
        type = "unique",
        name = l10n('nord_speechcraft_01_name'),
        description = l10n('nord_speechcraft_01_description'),
        icon = "Icons\\MAC\\icn_nordSpeechcraft.dds",
        bgColor = "purple",
        id = "nord_speechcraft_01",
        hidden = false
    },
    {
        type = "unique",
        name = l10n('beast_nerevarine_01_name'),
        description = l10n('beast_nerevarine_01_description'),
        icon = "Icons\\MAC\\icn_beastNerevarine.dds",
        bgColor = "purple",
        id = "beast_nerevarine_01",
        hidden = true
    },
    {
        type = "unique",
        name = l10n('azurastar_01_name'),
        description = l10n('azurastar_01_description'),
        icon = "Icons\\MAC\\icn_bigsoul.dds",
        bgColor = "purple",
        id = "azurastar_01",
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
        type = "rank_faction",
        name = l10n('fc_19_name'),
        description = l10n('fc_19_description'),
        factionId = "telvanni",
        rank = 10,
        icon = "Icons\\MAC\\icn_rankTelvanni.dds",
        bgColor = "aqua",
        id = "fc_19",
        hidden = true
    },
    {
        type = "rank_faction",
        name = l10n('fc_20_name'),
        description = l10n('fc_20_description'),
        factionId = "hlaalu",
        rank = 10,
        icon = "Icons\\MAC\\icn_rankHlaalu.dds",
        bgColor = "aqua",
        id = "fc_20",
        hidden = true
    },
    {
        type = "rank_faction",
        name = l10n('fc_21_name'),
        description = l10n('fc_21_description'),
        factionId = "redoran",
        rank = 10,
        icon = "Icons\\MAC\\icn_rankRedoran.dds",
        bgColor = "aqua",
        id = "fc_21",
        hidden = true
    },
    {
        type = "unique",
        name = l10n('dayspassed_02_name'),
        description = l10n('dayspassed_02_description'),
        icon = "Icons\\MAC\\icn_stillaStranger.dds",
        bgColor = "purple",
        id = "dayspassed_02",
        hidden = false
    },
    {
        type = "multi_quest",
        name = l10n('fc_18_name'),
        description = l10n('fc_18_description'),
        journalID = { "HH_Stronghold", "HR_Stronghold", "HT_Stronghold" },
        stage = { 300, 300, 300 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] == self.stage[1] or
            currentQuestStageTable[2] == self.stage[2] or
            currentQuestStageTable[3] == self.stage[3]
        end,
        icon = "Icons\\MAC\\icn_stronghold.dds",
        bgColor = "aqua",
        id = "fc_18",
        hidden = false
    }
}

return baseAchievements