local INTAAchievements = {
    {
        type = "visit_all",
        name = "Rock Bottom",
        description = "Reach the bottom of the Abyss.",
        cells = {"Abyss, 7th Layer: Abyss's End"},
        icon = "Icons\\INTA\\ic_v_mq.dds",
        bgColor = "green",
        id = "INTABottom",
        hidden = false
    },
--    {
--        type = "visit_all",                   --idk how to implement without a global...
--        name = "Curses Aren't Real",
--        description = "Reach the bottom of the Abyss...without getting cursed!",
--        cells = {"Abyss, 7th Layer: Abyss's End"},
--        icon = "Icons\\INTA\\ic_v_challenge.dds",
--        bgColor = "yellow",
--        id = "INTABottomChallenge",
--        hidden = true
--    }
    {
        type = "global_variable",
        name = "Public Transport",
        description = "Activate every Wayshrine in the Abyss.",
        variable = {"INTA_WayShrine_01", "INTA_WayShrine_02", "INTA_WayShrine_03", "INTA_WayShrine_04", "INTA_WayShrine_05", "INTA_WayShrine_06", "INTA_WayShrine_07"},
        value = 1,
        operator = function(self, givenValue)
            return (
                givenValue[1] == self.value and
                givenValue[2] == self.value and
                givenValue[3] == self.value and
                givenValue[4] == self.value and
                givenValue[5] == self.value and
                givenValue[6] == self.value and
                givenValue[7] == self.value
            )
        end,
        progressOperator = function(self, givenValue)
            local progress = 0
            local progressMax = 7

            for i = 1, 7 do
                if givenValue[i] ~= nil then
                    if givenValue[i] == self.value then
                        progress = progress + 1
                    end
                end
            end
            return {progress, progressMax}
        end,
        icon = "Icons\\INTA\\ic_v_shrine.dds",
        bgColor = "yellow",
        id = "INTAWayshrine",
        hidden = false
    },
}

return INTAAchievements
