return {
    id = "smallFrame",
    name = "Кроха",
    description = (
        "Вы были самым хилым из детей. Вы довольно " ..
        "слабы (-10 к силе), но благодаря вашей миниатюрности по вам трудно попасть (+10 к ловкости). "
    ),
    doOnce = function()
        tes3.player.scale = tes3.player.scale * 0.95
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength,
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility,
            value = 10
        })
    end
}