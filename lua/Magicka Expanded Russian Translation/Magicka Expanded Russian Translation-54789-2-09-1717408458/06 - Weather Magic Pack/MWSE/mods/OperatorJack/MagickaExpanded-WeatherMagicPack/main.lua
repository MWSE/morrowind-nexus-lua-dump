local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

require("OperatorJack.MagickaExpanded-WeatherMagicPack.effects.weatherEffectSet")
require("OperatorJack.MagickaExpanded-WeatherMagicPack.effects.thunderboltEffect")
require("OperatorJack.MagickaExpanded-WeatherMagicPack.effects.iceBarrageEffect")

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

  thunderboltEffect = "OJ_ME_ThunderboltEffect",
  thunderbolt = "OJ_ME_Thunderbolt",

  iceBarrageEffect = "OJ_ME_IceBarrageEffect",
  iceBarrage = "OJ_ME_IceBarrage",

  entombEffect = "OJ_ME_EntombEffect",
  entomb = "OJ_ME_Entomb"
}

local weatherTomes = {
  {
    id = "OJ_ME_TomeIceBarrage",
    spellId = weatherSpellIds.iceBarrage
  },
  {
    id = "OJ_ME_TomeThunderbolt",
    spellId = weatherSpellIds.thunderbolt
  },
  {
    id = "OJ_ME_TomeEntomb",
    spellid = weatherSpellIds.entomb
  },
  {
    id = "OJ_ME_TomeWeatherBlizzard",
    spellId = weatherSpellIds.weatherBlizzard,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeWeatherSnow",
    spellId = weatherSpellIds.weatherSnow,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeWeatherThunder",
    spellId = weatherSpellIds.weatherThunder,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeWeatherAsh",
    spellId = weatherSpellIds.weatherAsh,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeWeatherBlight",
    spellId = weatherSpellIds.weatherBlight,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeWeatherClear",
    spellId = weatherSpellIds.weatherClear,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeWeatherCloudy",
    spellId = weatherSpellIds.weatherCloudy,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeWeatherFoggy",
    spellId = weatherSpellIds.weatherFoggy,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeWeatherOvercast",
    spellId = weatherSpellIds.weatherOvercast,
    list = "OJ_ME_LeveledList_Rare"
  },
  {
    id = "OJ_ME_TomeWeatherRain",
    spellId = weatherSpellIds.weatherRain,
    list = "OJ_ME_LeveledList_Rare"
  }
}

local function addTomesToLists()
  for _, tome in pairs(weatherTomes) do
    mwscript.addToLevItem({
      list = tome.list,
      item = tome.id,
      level = 1
    })
  end
end
event.register("initialized", addTomesToLists)

local function registerSpells()
  framework.spells.createBasicSpell({
    id = weatherSpellIds.entomb,
    name = "Погребение",
    effect = tes3.effect.entomb,
    range = tes3.effectRange.target
  })
  framework.spells.createComplexSpell({
    id = weatherSpellIds.entombEffect,
    name = "Погребение",
    effects = {
      [1] = {
        id = tes3.effect.damageHealth,
        range = tes3.effectRange.touch,
        min = 15,
        max = 35,
        duration = 2,
        radius = 5
      },
      [2] = {
        id = tes3.effect.drainSpeed,
        range = tes3.effectRange.touch,
        min = 15,
        max = 35,
        duration = 1,
        radius = 5
      }
    }
  })

  framework.spells.createBasicSpell({
    id = weatherSpellIds.iceBarrage,
    name = "Ледяной шквал",
    effect = tes3.effect.iceBarrage,
    range = tes3.effectRange.target
  })
  framework.spells.createComplexSpell({
    id = weatherSpellIds.iceBarrageEffect,
    name = "Ледяной шквал",
    effects =
      {
        [1] = {
          id =tes3.effect.frostDamage,
          range = tes3.effectRange.touch,
          min = 25,
          max = 50,
          duration = 2,
          radius = 5
        },
        [2] = {
          id =tes3.effect.paralyze,
          range = tes3.effectRange.touch,
          duration = 1,
          radius = 5
        }
      }
  })

  framework.spells.createBasicSpell({
    id = weatherSpellIds.thunderbolt,
    name = "Удар молнии",
    effect = tes3.effect.thunderbolt,
    range = tes3.effectRange.target,
    radius = 5
  })
  framework.spells.createComplexSpell({
    id = weatherSpellIds.thunderboltEffect,
    name = "Удар молнии",
    effects =
      {
        [1] = {
          id =tes3.effect.shockDamage,
          range = tes3.effectRange.touch,
          min = 25,
          max = 50,
          duration = 2,
          radius = 5
        },
        [2] = {
          id =tes3.effect.paralyze,
          range = tes3.effectRange.touch,
          duration = 1,
          radius = 5
        }
      }
  })


  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherBlizzard,
    name = "Объятия зимы",
    effect = tes3.effect.weatherBlizzard,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherSnow,
    name = "Прикосновение зимы",
    effect = tes3.effect.weatherSnow,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherThunder,
    name = "Ярость Кин",
    effect = tes3.effect.weatherThunderstorm,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherAsh,
    name = "Пепельный ветер",
    effect = tes3.effect.weatherAsh,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherBlight,
    name = "Владения Дагота",
    effect = tes3.effect.weatherBlight,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherClear,
    name = "Ясное небо",
    effect = tes3.effect.weatherClear,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherCloudy,
    name = "Тень Кин",
    effect = tes3.effect.weatherCloudy,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherFoggy,
    name = "Мутная завеса",
    effect = tes3.effect.weatherFoggy,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherOvercast,
    name = "Серая пелена",
    effect = tes3.effect.weatherOvercast,
    range = tes3.effectRange.self
  })
  framework.spells.createBasicSpell({
    id = weatherSpellIds.weatherRain,
    name = "Слезы Велота",
    effect = tes3.effect.weatherRain,
    range = tes3.effectRange.self
  })
  
  framework.tomes.registerTomes(weatherTomes)
end

event.register("MagickaExpanded:Register", registerSpells)

local function onLoaded()
  local globalDoOnceId = "OJ_ME_WeatherMagicDoOnce"
  local doOnce = tes3.getGlobal(globalDoOnceId)

  if (doOnce == 0) then
    tes3.addItem({
      reference = "dagoth endus",
      item = "OJ_ME_TomeWeatherBlight",
      count = 1
    })

    tes3.addItem({
      reference = "berapli ashumallit",
      item = "OJ_ME_TomeWeatherAsh",
      count = 1
    })
    tes3.addItem({
      reference = "pilu shilansour",
      item = "OJ_ME_TomeWeatherAsh",
      count = 1
    })

    mwscript.addSpell({
      reference = "fevyn ralen",
      spell = weatherSpellIds.weatherOvercast
    })

    tes3.addItem({
      reference = "lloros sarano",
      item = "OJ_ME_TomeWeatherRain",
      count = 1
    })
    tes3.addItem({
      reference = "salen ravel",
      item = "OJ_ME_TomeWeatherRain",
      count = 1
    })


    tes3.setGlobal(globalDoOnceId, 1)
  end
end

event.register("loaded", onLoaded)