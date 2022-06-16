return {
    id = "bully",
    name = "Bully",
    description = (
        "You were the class bully, big and dumb. Extortion and intimidation have afforded you a bonus to Strength (+10), " ..
        "but getting people to do your homework for you leaves you with a deficiency in Intelligence (-10). "
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