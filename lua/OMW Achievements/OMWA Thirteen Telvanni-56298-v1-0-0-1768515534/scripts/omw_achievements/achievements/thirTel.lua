local thirTelAchievements = {
    {
        type = "global_variable",
        name = "Thirteen Telvanni",
        description = "Win a game of Thirteen Telvanni.",
        variable = "Game_ThirTel_glb_Winner",
        value = 1,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        icon = "Icons\\MAC\\icn_thirTel.dds",
        bgColor = "aqua",
        id = "thirtel_01",
        hidden = false
    },
}

return thirTelAchievements