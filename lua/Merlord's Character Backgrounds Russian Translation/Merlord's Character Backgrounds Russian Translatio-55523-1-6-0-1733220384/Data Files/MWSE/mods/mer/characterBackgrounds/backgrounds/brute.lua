local interop = require("mer.characterBackgrounds.interop")
interop.addBackground{
    id = "brute",
    name = "Здоровяк",
    description = (
        "Должно быть, в ваших жилах течет кровь великанов! Вы возвышаетесь над окружающими, " ..
        "обладаете изрядной силой (+10), но из-за своих размеров довольно неуклюжи (-10 к ловкости). "
    ),
    doOnce = function()
        tes3.player.scale = tes3.player.scale * 1.05
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength,
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility,
            value = -10
        })
    end,
}