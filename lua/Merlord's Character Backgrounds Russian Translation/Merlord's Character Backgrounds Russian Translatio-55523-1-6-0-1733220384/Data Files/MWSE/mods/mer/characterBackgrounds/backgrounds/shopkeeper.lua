return {
    id = "shopkeeper",
    name = "Ученик торговца",
    description = (
        "Проведя все детство в лавке, вы получили исключительный " ..
        "бонус к Торговле (+20), но ваша деловая хватка делает вас " ..
        "довольно неприятным типом (-10 к привлекательности)."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile,
            value = 20
        })

        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality,
            value = -10
        })
    end
}