local interop = require("mer.characterBackgrounds.interop")
interop.addBackground{
    id = "bully",
    name = "Задира",
    description = (
        "Вы всегда были задирой, огромным и тупым. Грабеж и угрозы помогли вам развить силу (+10), " ..
        "однако выполненная другими учениками домашняя работа не способствовала развитию вашего интеллекта (-10). "
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength,
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence,
            value = -10
        })
    end
}