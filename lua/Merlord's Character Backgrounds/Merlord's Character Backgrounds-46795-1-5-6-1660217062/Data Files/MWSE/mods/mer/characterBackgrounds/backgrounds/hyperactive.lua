return {
    id = "hyperactive",
    name = "Hyperactive",
    description = (
        "You are constantly busy. Your Speed is higher than normal (+10), but most " ..
        "people find you annoying, and your Personality suffers (-10). "
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed,
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality,
            value = -10
        })
    end
}