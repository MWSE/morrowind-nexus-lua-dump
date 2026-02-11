local gardenAchievements = {
    {
        type = "global_variable",
        name = "Молитва Белой Башни",
        description = "Откройте для себя все 9 святилищ на Белых Скалах в Саду.",
        variable = "x32_WhiteRuinShrineCounter",
        value = 9,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        enableProgress = true,
        icon = "Icons\\x32\\v\\achievement_shrine.tga",
        bgColor = "purple",
        id = "x32_shrines",
        hidden = false
    },
    {
        type = "global_variable",
        name = "Искусствовед",
        description = "Побывайте во всех 15 картинах в Оранжерее и Саду.",
        variable = "x32_PaintingTracker",
        value = 15,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        enableProgress = true,
        icon = "Icons\\x32\\v\\achievement_paintings.tga",
        bgColor = "purple",
        id = "x32_paintings",
        hidden = false
    },
    {
        type = "global_variable",
        name = "Герцогиня, Это Вы?",
        description = "Поговорить со всеми формами Герцогини.",
        variable = "x32_DuchessTalkTracker",
        value = 7,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        enableProgress = true,
        icon = "Icons\\x32\\v\\achievement_duchess.tga",
        bgColor = "purple",
        id = "x32_duchess",
        hidden = false
    },
    {
        type = "global_variable",
        name = "Дипломированный взломщик Оранжерей",
        description = "Соберите все 4 ключа от Оранжереи.",
        variable = "x32_FloralKeyTracker",
        value = 4,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        enableProgress = true,
        icon = "Icons\\x32\\v\\achievement_keys.tga",
        bgColor = "purple",
        id = "x32_keys",
        hidden = false
    },
    {
        type = "global_variable",
        name = "Контроль популяции",
        description = "Убить 20 кагиунов.",
        variable = "x32_KagiounKilledTracker",
        value = 20,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        enableProgress = true,
        icon = "Icons\\x32\\v\\achievement_kagioun.tga",
        bgColor = "purple",
        id = "x32_kagioun",
        hidden = false
    },
    {
        type = "global_variable",
        name = "Свет во тьме",
        description = "Зажгите жаровни в Башне в Саду, используя тайный узор.",
        variable = "x32_BrazierSecretComplete",
        value = 1,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        icon = "Icons\\x32\\v\\achievement_brazier.tga",
        bgColor = "purple",
        id = "x32_brazier",
        hidden = false
    },
    {
        type = "global_variable",
        name = "Знакомое лицо",
        description = "Поговорите с эльфом на вершине башни на Белых Скалах в Саду.",
        variable = "x32_TalkedToDEG",
        value = 1,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        icon = "Icons\\x32\\v\\achievement_deg.tga",
        bgColor = "purple",
        id = "x32_deg",
        hidden = true
    },
    {
        type = "global_variable",
        name = "Правильный инструмент для работы",
        description = "Убейте Неудачу Золотым Мечом.",
        variable = "x32_UsedGoldenSword",
        value = 1,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        icon = "Icons\\x32\\v\\achievement_sword.tga",
        bgColor = "purple",
        id = "x32_sword",
        hidden = true
    },
    {
        type = "global_variable",
        name = "Самозванец",
        description = "Поговорите с Мелвином в образе Мелвина.",
        variable = "x32_MelvinDisguiseTalkTracker",
        value = 1,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        icon = "Icons\\x32\\v\\achievement_melvin.tga",
        bgColor = "purple",
        id = "x32_melvin",
        hidden = true
    },
    {
        type = "global_variable",
        name = "Смотри в оба",
        description = "Найти жуткую статую в Кладовой Оранжереи.",
        variable = "x32_ScaredByStatue",
        value = 1,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        icon = "Icons\\x32\\v\\achievement_statue.tga",
        bgColor = "purple",
        id = "x32_statue",
        hidden = true
    },
}

return gardenAchievements