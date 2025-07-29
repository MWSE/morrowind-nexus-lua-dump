local framework = require("OperatorJack.MagickaExpanded")

local weatherSpellIds = {
    weatherBlizzard = "OJ_ME_WeatherBlizzard",
    weatherSnow = "OJ_ME_WeatherSnow",
    weatherThunder = "OJ_ME_WeatherThunder",
    weatherAsh = "OJ_ME_WeatherAsh",
    weatherBlight = "OJ_ME_WeatherBlight",
    weatherClear = "OJ_ME_WeatherClear",
    weatherCloudy = "OJ_ME_WeatherCloudy",
    weatherFoggy = "OJ_ME_WeatherFoggy",
    weatherOvercast = "OJ_ME_WeatherOvercast",
    weatherRain = "OJ_ME_WeatherRain",

    conjureLightning = "OJ_ME_ConjureLightning",
    conjureAshShell = "OJ_ME_ConjureAshShell",
    conjureAshShellParalysis = "OJ_ME_ConjureAshShellParalysis"
}

local weatherTomes = {
    {id = "OJ_ME_TomeLightning", spellId = weatherSpellIds.conjureLightning},
    {id = "OJ_ME_TomeAshShell", spellid = weatherSpellIds.conjureAshShell}, {
        id = "OJ_ME_TomeWeatherBlizzard",
        spellId = weatherSpellIds.weatherBlizzard,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeWeatherSnow",
        spellId = weatherSpellIds.weatherSnow,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeWeatherThunder",
        spellId = weatherSpellIds.weatherThunder,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeWeatherAsh",
        spellId = weatherSpellIds.weatherAsh,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeWeatherBlight",
        spellId = weatherSpellIds.weatherBlight,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeWeatherClear",
        spellId = weatherSpellIds.weatherClear,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeWeatherCloudy",
        spellId = weatherSpellIds.weatherCloudy,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeWeatherFoggy",
        spellId = weatherSpellIds.weatherFoggy,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeWeatherOvercast",
        spellId = weatherSpellIds.weatherOvercast,
        list = "OJ_ME_LeveledList_Rare"
    }, {
        id = "OJ_ME_TomeWeatherRain",
        spellId = weatherSpellIds.weatherRain,
        list = "OJ_ME_LeveledList_Rare"
    }
}

event.register(tes3.event.initialized, function()
    require("OperatorJack.MagickaExpanded-WeatherMagicPack.effects")

    for _, tome in pairs(weatherTomes) do
        if (tome.list) then
            local item = tes3.getObject(tome.id)
            local list = tes3.getObject(tome.list) --[[@as tes3leveledItem]]
            list:insert(item, 1)
        end
    end
end)

local function registerSpells()
    local spell = framework.spells.createBasicSpell({
        id = weatherSpellIds.conjureAshShellParalysis,
        name = "Паралич пепельного панциря",
        effect = tes3.effect.paralyze,
        rangeType = tes3.effectRange.self
    })
    spell.castType = tes3.spellType.disease

    framework.spells.createBasicSpell({
        id = weatherSpellIds.conjureAshShell,
        name = "Пепельный панцирь",
        distribute = true,
        effect = tes3.effect.conjureAshShell,
        rangeType = tes3.effectRange.self,
        duration = 5

    })

    framework.spells.createBasicSpell({
        id = weatherSpellIds.conjureLightning,
        name = "Удар молнии",
        distribute = true,
        effect = tes3.effect.conjureLightning,
        rangeType = tes3.effectRange.target
    })

    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherBlizzard,
        name = "Объятия зимы",
        effect = tes3.effect.weatherBlizzard,
        rangeType = tes3.effectRange.self
    })
    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherSnow,
        name = "Прикосновение зимы",
        effect = tes3.effect.weatherSnow,
        rangeType = tes3.effectRange.self
    })
    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherThunder,
        name = "Ярость Кин",
        effect = tes3.effect.weatherThunderstorm,
        rangeType = tes3.effectRange.self
    })
    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherAsh,
        name = "Пепельный ветер",
        effect = tes3.effect.weatherAsh,
        rangeType = tes3.effectRange.self
    })
    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherBlight,
        name = "Владения Дагота",
        effect = tes3.effect.weatherBlight,
        rangeType = tes3.effectRange.self
    })
    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherClear,
        name = "Ясное небо",
        effect = tes3.effect.weatherClear,
        rangeType = tes3.effectRange.self
    })
    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherCloudy,
        name = "Тень Кин",
        effect = tes3.effect.weatherCloudy,
        rangeType = tes3.effectRange.self
    })
    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherFoggy,
        name = "Мутная завеса",
        effect = tes3.effect.weatherFoggy,
        rangeType = tes3.effectRange.self
    })
    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherOvercast,
        name = "Серая пелена",
        effect = tes3.effect.weatherOvercast,
        rangeType = tes3.effectRange.self
    })
    framework.spells.createBasicSpell({
        id = weatherSpellIds.weatherRain,
        name = "Слезы Велота",
        effect = tes3.effect.weatherRain,
        rangeType = tes3.effectRange.self
    })

    framework.tomes.registerTomes(weatherTomes)
end

event.register("MagickaExpanded:Register", registerSpells)

local function onLoaded()
    local globalDoOnceId = "OJ_ME_WeatherMagicDoOnce"
    local doOnce = tes3.getGlobal(globalDoOnceId)

    if (doOnce == 0) then
        tes3.addItem({reference = "dagoth endus", item = "OJ_ME_TomeWeatherBlight", count = 1})

        tes3.addItem({reference = "berapli ashumallit", item = "OJ_ME_TomeWeatherAsh", count = 1})
        tes3.addItem({reference = "pilu shilansour", item = "OJ_ME_TomeWeatherAsh", count = 1})

        tes3.addSpell({
            actor = "fevyn ralen",
            reference = nil,
            spell = weatherSpellIds.weatherOvercast
        })

        tes3.addItem({reference = "lloros sarano", item = "OJ_ME_TomeWeatherRain", count = 1})
        tes3.addItem({reference = "salen ravel", item = "OJ_ME_TomeWeatherRain", count = 1})

        tes3.setGlobal(globalDoOnceId, 1)
    end
end

event.register(tes3.event.loaded, onLoaded)
