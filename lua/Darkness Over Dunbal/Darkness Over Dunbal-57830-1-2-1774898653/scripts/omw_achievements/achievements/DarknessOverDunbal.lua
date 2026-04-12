local AGBAchievements = {
    {
        type = "global_variable",
        name = "Hunt Down the Demon",
        description = "Destroy all four manifesations of Namira.",
        variable = "agb_bosseskilled",
        value = 4,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        enableProgress = true,
        icon = "Icons\\agb\\q\\v_boss.dds",
        bgColor = "blue",
        id = "AGBBosses",
        hidden = false
    },
    {
        type = "global_variable",
        name = "Fireflies When You're Having Fun",
        description = "Find all 7 fireflies on Dunbal.",
        variable = "AGB_Health_Charges_Max",
        value = 10,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        enableProgress = true,
        icon = "Icons\\agb\\q\\v_firefly.dds",
        bgColor = "green",
        id = "AGBFirefly",
        hidden = false
    },
    {
        type = "multi_quest",
        name = "Full House",
        description = "Bring all the survivors to Meridia's Temple.",
        journalID = { "AGB_Mist_Dorans",  "AGB_Mist_Idols", "AGB_Mist_Justice" },
        stage = { 40, 15, 15, 100 },
        operator = function(self, currentQuestStageTable)
            return currentQuestStageTable[1] >= self.stage[1] and
                   currentQuestStageTable[1] <= self.stage[4] and
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
        icon = "Icons\\agb\\q\\v_rescue.dds",
        bgColor = "blue",
        id = "AGBAllSafe",
        hidden = true
    }
}

return AGBAchievements