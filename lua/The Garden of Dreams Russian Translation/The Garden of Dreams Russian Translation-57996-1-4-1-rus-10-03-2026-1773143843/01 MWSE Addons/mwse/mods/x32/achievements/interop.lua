local sb_achievements = include("sb_achievements.interop")

if sb_achievements == nil then
    return
end

local iconPath = "Icons\\x32\\v\\"

local cats = {
    garden = sb_achievements.registerCategory("Сад снов")
}

sb_achievements.registerAchievement {
    id = "x32_shrines",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.progressAmount,
    progress = function()
        return tes3.getGlobal("x32_WhiteRuinShrineCounter")
    end,
    progressMax = function()
        return 9
    end,
    icon = iconPath .. "achievement_shrine.tga",
    colour = sb_achievements.colours.yellow,
    title = "Молитва Белой Башни", desc = "Откройте для себя все 9 святилищ на Белых Скалах в Саду."
}

sb_achievements.registerAchievement {
    id = "x32_paintings",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.progressAmount,
    progress = function()
        return tes3.getGlobal("x32_PaintingTracker")
    end,
    progressMax = function()
        return 15
    end,
    icon = iconPath .. "achievement_paintings.tga",
    colour = sb_achievements.colours.yellow,
    title = "Искусствовед", desc = "Побывайте во всех 15 картинах в Оранжерее и Саду."
}

sb_achievements.registerAchievement {
    id = "x32_duchess",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.progressAmount,
    progress = function()
        return tes3.getGlobal("x32_DuchessTalkTracker")
    end,
    progressMax = function()
        return 7
    end,
    icon = iconPath .. "achievement_duchess.tga",
    colour = sb_achievements.colours.yellow,
    title = "Герцогиня, Это Вы?", desc = "Поговорить со всеми формами Герцогини."
}

sb_achievements.registerAchievement {
    id = "x32_keys",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.progressAmount,
    progress = function()
        return tes3.getGlobal("x32_FloralKeyTracker")
    end,
    progressMax = function()
        return 4
    end,
    icon = iconPath .. "achievement_keys.tga",
    colour = sb_achievements.colours.yellow,
    title = "Дипломированный взломщик Оранжерей", desc = "Соберите все 4 ключа от Оранжереи."
}

sb_achievements.registerAchievement {
    id = "x32_kagioun",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.progressAmount,
    progress = function()
        return tes3.getGlobal("x32_KagiounKilledTracker")
    end,
    progressMax = function()
        return 20
    end,
    icon = iconPath .. "achievement_kagioun.tga",
    colour = sb_achievements.colours.yellow,
    title = "Контроль популяции", desc = "Убить 20 кагиунов."
}

sb_achievements.registerAchievement {
    id = "x32_brazier",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.instant,
    condition = function()
        return tes3.getGlobal("x32_BrazierSecretComplete") == 1
    end,
    icon = iconPath .. "achievement_brazier.tga",
    colour = sb_achievements.colours.yellow,
    title = "Свет во тьме", desc = "Зажгите жаровни в Башне в Саду, используя тайный узор."
}

sb_achievements.registerAchievement {
    id = "x32_deg",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.instant,
    condition = function()
        return tes3.getGlobal("x32_TalkedToDEG") == 1
    end,
    icon = iconPath .. "achievement_deg.tga",
    colour = sb_achievements.colours.yellow,
    title = "Знакомое лицо", desc = "Поговорите с эльфом на вершине башни на Белых Скалах в Саду.",
    configDesc = sb_achievements.configDesc.hideDesc,
    lockedDesc = sb_achievements.lockedMessage.psHidden
}

sb_achievements.registerAchievement {
    id = "x32_sword",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.instant,
    condition = function()
        return tes3.getGlobal("x32_UsedGoldenSword") == 1
    end,
    icon = iconPath .. "achievement_sword.tga",
    colour = sb_achievements.colours.yellow,
    title = "Правильный инструмент для работы", desc = "Убейте Неудачу Золотым Мечом.",
    configDesc = sb_achievements.configDesc.hideDesc,
    lockedDesc = sb_achievements.lockedMessage.psHidden
}

sb_achievements.registerAchievement {
    id = "x32_melvin",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.instant,
    condition = function()
        return tes3.getGlobal("x32_MelvinDisguiseTalkTracker") == 1
    end,
    icon = iconPath .. "achievement_melvin.tga",
    colour = sb_achievements.colours.yellow,
    title = "Самозванец", desc = "Поговорите с Мелвином в образе Мелвина.",
    configDesc = sb_achievements.configDesc.hideDesc,
    lockedDesc = sb_achievements.lockedMessage.psHidden
}

sb_achievements.registerAchievement {
    id = "x32_statue",
    category = cats.garden,
    conditionType = sb_achievements.conditionType.instant,
    condition = function()
        return tes3.getGlobal("x32_ScaredByStatue") == 1
    end,
    icon = iconPath .. "achievement_statue.tga",
    colour = sb_achievements.colours.yellow,
    title = "Смотри в оба", desc = "Найти жуткую статую в Кладовой Оранжереи.",
    configDesc = sb_achievements.configDesc.hideDesc,
    lockedDesc = sb_achievements.lockedMessage.psHidden
}