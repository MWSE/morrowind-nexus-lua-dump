local apartmentsOfMorrowind = {
    {
        type = "multi_quest",
        name = "Make Yourself At Home",
        description = "Buy all houses in Vvardenfell.",
        journalID = { "AOV_Baladas",
            "AOV_Balmora_Balyn",
            "AOV_Balmora_Dura",
            "AOV_Balmora_Hlaalo",
            "AOV_Balmora_Vorar",
            "AOV_Drinar",
            "AOV_Hanarai",
            "AOV_MH_Vacant",
            "AOV_MH_Velas",
            "AOV_Seyda_Neen",
            "AOV_Seyda_Vod",
            "AOV_Tashpi",
            "AOV_Vivec_Delin",
            "AOV_Vivec_Delin_Temple",
            "AOV_Vivec_Olms",
            "HT_Stronghold",
            "HR_Stronghold",
            "HH_Stronghold"
        },
        stage = { 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 10, 100, 300, 300, 300 },
        operator = function(self, currentQuestStageTable)
                return (currentQuestStageTable[1] >= self.stage[1]) and
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
                ((currentQuestStageTable[16] >= self.stage[16]) or (currentQuestStageTable[17] >= self.stage[17]) or
                (currentQuestStageTable[18] >= self.stage[18]))
        end,
        progressOperator = function(self, currentQuestStageTable)

            local progress = 0
            local progressMax = 16

            for i = 1, 15 do
                if currentQuestStageTable[i] ~= nil then
                    if currentQuestStageTable[i] >= self.stage[i] then
                        progress = progress + 1
                    end
                end
            end

            if currentQuestStageTable[16] >= self.stage[16] or 
            currentQuestStageTable[17] >= self.stage[17] or
            currentQuestStageTable[18] >= self.stage[18] then
                progress = progress + 1
            end

            return {progress, progressMax}
            
        end,
        icon = "Icons\\MAC\\icn_APofM.dds",
        bgColor = "purple",
        id = "apofm_01",
        hidden = false
    }
}

return apartmentsOfMorrowind