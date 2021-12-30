return {
    id = "brute",
    name = "Brute",
    description = (
        "You must have giant's blood in you! You tower over your peers, " ..
        "and have increased Strength (+10), but your massive size makes your rather clumsy (-10 Agility). "
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
    end
}