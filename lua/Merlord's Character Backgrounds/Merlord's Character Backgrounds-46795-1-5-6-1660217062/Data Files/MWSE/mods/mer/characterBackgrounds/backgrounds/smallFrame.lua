return {
    id = "smallFrame",
    name = "Small Frame",
    description = (
        "You were the runt of the litter. This makes you rather " ..
        "weak (-10 Strength), but your small stature does make you harder to hit (+10 Agility). "
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