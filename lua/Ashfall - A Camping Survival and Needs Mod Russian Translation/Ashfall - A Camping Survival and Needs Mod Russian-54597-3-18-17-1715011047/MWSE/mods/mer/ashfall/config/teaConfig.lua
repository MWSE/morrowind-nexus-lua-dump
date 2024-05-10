local this = {}
local config = require("mer.ashfall.config").config
local conditions = require("mer.ashfall.conditions.conditionConfig")

this.tooltipColor = {
    138 / 255,
    201 / 255,
    71 / 225
}
this.teaTypes = {}
--West Gash, Ashlands
this.teaTypes["ingred_bittergreen_petals_01"] = {
    teaName = "Чай из Горьколистника",
    teaDescription = "Навязчивый аромат чая из Горьколистника помогает очистить разум от отвлекающих мыслей.",
    effectDescription = "Увеличение магии на 20 п.",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_bittergreen",
        effects = {
            {
                id = tes3.effect.fortifyMagicka,
                amount = 20
            }
        }
    }
}

--Ascadian Isles, Azura's Coast
this.teaTypes["ingred_black_anther_01"] = {
    teaName = "Чай из Черного пыльника",
    teaDescription = "Популярный напиток среди светских людей и тех, кто хочет выделиться, чай Черный пыльник придает коже здоровый, сияющий блеск.",
    effectDescription = "Свет 5 п.",
    priceMultiplier = 5.0,
    duration = 2,
    spell = {
        id = "ashfall_tea_anther",
        effects = {
            {
                id = tes3.effect.light,
                amount = 5
            }
        }
    }
}

--West Gash
this.teaTypes["ingred_chokeweed_01"] = {
    teaName = "Чай из Удушайки",
    teaDescription = "Употребление чая из Удушайки помогает укрепить иммунитет. Как и любое хорошее лекарство, он ужасен на вкус.",
    effectDescription = "Сопротивление обычным болезням 30 п.",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_chokeweed",
        effects = {
            {
                id = tes3.effect.resistCommonDisease,
                amount = 30
            }
        }
    }
}


--Ascadian Isles, Azura's Coast
this.teaTypes["ingred_gold_kanet_01"] = {
    teaName = "Чай Золотой Канет",
    teaDescription = "Чай, заваренный из цветка золотого канета, известен тем, что придает силы.",
    effectDescription = "Улучшение силы 5 п.",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_goldKanet",
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.strength,
                amount = 5
            }
        }
    }
}


--Ascadian Isles
this.teaTypes["ingred_heather_01"] = {
    teaName = "Чай из Вереска",
    teaDescription = "Вересковый чай - это расслабляющий напиток, который придает легкость.",
    effectDescription = "Светоч 5 п.",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_heather_v2",
        effects = {
            {
                id = tes3.effect.sanctuary,
                amount = 5
            }
        }
    }
}

--West Gash, Ascadian Isles, Azura's Coast, Sheogorad
this.teaTypes["ingred_stoneflower_petals_01"] = {
    teaName = "Чай из Каменевки",
    teaDescription = "Приятный цветочный аромат чая из Каменевки надолго освежает дыхание.",
    effectDescription = "Увеличение красноречия 10 п.",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_stoneflower",
        effects = {
            {
                id = tes3.effect.fortifySkill,
                skill = tes3.skill.speechcraft,
                amount = 10
            }
        }
    }
}


--Solstheim
this.teaTypes["ingred_belladonna_01"] = {
    teaName = "Чай из Белладонны",
    teaDescription = "Из ягод белладонны получается слегка горьковатый чай, который обеспечивает устойчивость к магии.",
    effectDescription = "Сопротивление магии 15 п.",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_bella",
        effects = {
            {
                id = tes3.effect.resistMagicka,
                amount = 15
            }
        }
    }
}

--Solstheim
this.teaTypes["ingred_belladonna_02"] = {
    teaName = "Чай из Белладонны",
    teaDescription = "Из ягод белладонны получается слегка горьковатый чай, который обеспечивает устойсивость к магии. Недозрелые ягоды имеют более слабое действие.",
    effectDescription = "Сопротивление магии 10 п.",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_bella",
        effects = {
            {
                id = tes3.effect.resistMagicka,
                amount = 10
            }
        }
    }
}

--Bitter Coast
this.teaTypes["ingred_bc_coda_flower"] = {
    teaName = "Чай из цветка Коды",
    teaDescription = "Чай из цветка коды обладает легким психотропным эффектом, позволяющим чувствовать ближайшие формы жизни.",
    effectDescription = "Заметить сущность 50 п.",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_coda",
        effects = {
            {
                id = tes3.effect.detectAnimal,
                amount = 50
            }
        }
    }
}

--Survival effects---------------


--Azura's Coast, West Gash, Sheogorad
this.teaTypes["ingred_kresh_fiber_01"] = {
    teaName = "Чай из Креш-травы",
    teaDescription = "Чай из Креш-травы мощное слабительное, что делает его эффективным средством от пищевых отравлений.",
    effectDescription = "Лечение пищевых отравлений",
    priceMultiplier = 5.0,
    onCallback = function()
        conditions.foodPoison:setValue(conditions.foodPoison:getValue() - 50)
    end
}

--West Gash - exclusively
this.teaTypes["ingred_roobrush_01"] = {
    teaName = "Чай из Рубраша",
    teaDescription = "Чай Рубраша имеет мягкий, слегка ореховый вкус и используется как лекарство от дизентерии.",
    effectDescription = "Лечение дизентерии",
    priceMultiplier = 5.0,
    onCallback = function()
        conditions.dysentery:setValue(conditions.dysentery:getValue() - 50)
    end
}

--Ascadian Isles - exclusively - used for alcohol
this.teaTypes["ingred_comberry_01"] = {
    teaName = "Чай из Комуники",
    teaDescription = "Чай, заваренный из ягод Комуники, является известным домашним средством от гриппа.",
    effectDescription = "Лечение грипа",
    priceMultiplier = 5.0,
    onCallback = function()
        conditions.flu:setValue(conditions.flu:getValue() - 50)
    end,
}

--Ashlands, dry regions
this.teaTypes["ingred_scathecraw_01"] = {
    teaName = "Чай из Вредозобника",
    teaDescription = "Чай из Вредозобника обеспечивает умеренную устойчивость к Мору.",
    effectDescription = "Сопротивление моровым болезням 40 п.",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_scathecraw",
        effects = {
            {
                id = tes3.effect.resistBlightDisease,
                amount = 40
            }
        }
    }
}


--Ashlands, Molar Amur
this.teaTypes["ingred_fire_petal_01"] = {
    teaName = "Чай из Огненного лепестка",
    teaDescription = "Чай из Огненного лепестка - это пряный напиток, который поможет согреться холодными ночами.",
    effectDescription = "Уменьшение воздействия холодной погоды 20%",
    priceMultiplier = 5.0,
    duration = 4,
    onCallback = function()
        tes3.player.data.Ashfall.firePetalTeaEffect = 0.80
    end,
    offCallback = function()
        tes3.player.data.Ashfall.firePetalTeaEffect = nil
    end,
}

--Solstheim
this.teaTypes["ingred_holly_01"] = {
    teaName = "Чай из ягод Падуба",
    teaDescription = "Сладкий, ароматный чай, который часто подают в Солстхейме за его способность спасать от холода.",
    effectDescription = "Уменьшение воздействия холодной погоды 10%",
    priceMultiplier = 5.0,
    duration = 4,
    onCallback = function()
        tes3.player.data.Ashfall.hollyTeaEffect = 0.9
    end,
    offCallback = function()
        tes3.player.data.Ashfall.hollyTeaEffect = nil
    end,
}



--Grazelands
this.teaTypes["ingred_hackle-lo_leaf_01"] = {
    teaName = "Чай из Хакльлоу",
    teaDescription = "Чай Хакльлоу повышает энергию, позволяя человеку дольше бодрствовать.",
    effectDescription = "Уменьшение усталости 25%",
    priceMultiplier = 5.0,
    duration = 5,
    onCallback = function()
        tes3.player.data.Ashfall.hackloTeaEffect = 0.75
    end,
    offCallback = function()
        tes3.player.data.Ashfall.hackloTeaEffect = nil
    end
}

--Ashlands, Molag Amur,
this.teaTypes["ingred_trama_root_01"] = {
    teaName = "Чай из Корень трамы",
    teaDescription = "Чай из Корня трамы темный и горький. Эшлендеры пьют этот чай из-за его успокаивающего действия.",
    effectDescription = "Продуктивность сна 1.5x",
    priceMultiplier = 5.0,
    duration = 8,
    onCallback = function()
        tes3.player.data.Ashfall.tramaRootTeaEffect = 1.5
    end,
    offCallback = function()
        tes3.player.data.Ashfall.tramaRootTeaEffect = nil
    end
}

this.teaTypes["ingred_moon_sugar_01"] = {
    teaName = "Кофе с лунным сахаром",
    teaDescription = "Хотя кофе, приготовленный с лунным сахаром, и не такой крепкий, как Skooma, он придаст бодрости. Однако имейте в виду, что, когда эффект пройдет, вы можете почувствовать себя утомленным.",
    effectDescription = "Бодрящий эфект",
    priceMultiplier = 5.0,
    duration = 4,
    onCallback = function()
        local currentTiredness = conditions.tiredness:getValue()
        tes3.player.data.Ashfall.coffeePrevTiredness = currentTiredness
        conditions.tiredness:setValue(0)
    end,
    offCallback = function()
        local previousTiredness = tes3.player.data.Ashfall.coffeePrevTiredness
        if previousTiredness then
            local sleepLossRate = config.loseSleepRate
            local penalty = sleepLossRate * tes3.player.data.Ashfall.teaBuffTimeLeft * 0.8
            conditions.tiredness:setValue( previousTiredness + penalty)
            tes3.player.data.Ashfall.coffeePrevTiredness = nil
        end
    end
}


--Mournhold teas----------------

--Mournhold
this.teaTypes["ingred_golden_sedge_01"] = {
    teaName = "Чай из Золотой осоки",
    teaDescription = "Любимый воинами чай из золотой осоки повышает силу атаки.",
    effectDescription = "Улучшение атаки 10 п",
    priceMultiplier = 5.0,
    duration = 3,
    spell = {
        id = "ashfall_tea_goldSedge",
        effects = {
            {
                id = tes3.effect.fortifyAttack,
                amount = 10
            }
        }
    }
}

--Mournhold
this.teaTypes["ingred_meadow_rye_01"] = {
    teaName = "Чай из Луговой ржи",
    teaDescription = "Чай, из луговой ржи - это мощный стимулятор, повышающий скорость передвижения.",
    effectDescription = "Улучшение скорости 5 п.",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_meadowRye",
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.speed,
                amount = 5
            }
        }
    }
}

--Mournhold
this.teaTypes["ingred_noble_sedge_01"] = {
    teaName = "Чай из Осоки благородной",
    teaDescription = "Редкий, ценимый среди акробатов, чай из осоки благородной улучшает ловкость.",
    effectDescription = "улучшение ловкости 10 п.",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_nobleSedge",
        effects = {
            {
                id = tes3.effect.fortifyAttribute,
                attribute = tes3.attribute.agility,
                amount = 10
            }
        }
    }
}

--Mournhold
this.teaTypes["ingred_timsa-come-by_01"] = {
    teaName = "Чай из Тимсовых цветов",
    teaDescription = "Чай, заваренный из этого редкого растения, делает человека устойчивым к параличу.",
    effectDescription = "Сопротивление параличу 40 п.",
    priceMultiplier = 5.0,
    duration = 4,
    spell = {
        id = "ashfall_tea_timsa",
        effects = {
            {
                id = tes3.effect.resistParalysis,
                amount = 40
            }
        }
    }
}


this.validTeas = {}
for ingredId, _ in pairs(this.teaTypes) do
    --if tes3.getObject(ingredId) then
        table.insert(this.validTeas, ingredId)
    --end
end



return this