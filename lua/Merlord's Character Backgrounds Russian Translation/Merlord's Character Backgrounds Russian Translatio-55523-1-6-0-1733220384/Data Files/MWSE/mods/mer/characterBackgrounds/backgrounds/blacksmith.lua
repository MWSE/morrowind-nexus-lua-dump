local interop = require('mer.characterBackgrounds.interop')

interop.addBackground{
    id = "blacksmith",
    name = "Ученик кузнеца",
    description = (
        "У вашего учителя был тяжелый нрав. Вы получаете бонус к силе (+5) " ..
        "и бонус к навыку Кузнеца (+15), однако ваша " ..
        "ловкость снижена (-10) из-за тяжелой однообразной работы."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer,
            value = 15
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength,
            value = 5
        })

        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility,
            value = -10
        })
    end,
}