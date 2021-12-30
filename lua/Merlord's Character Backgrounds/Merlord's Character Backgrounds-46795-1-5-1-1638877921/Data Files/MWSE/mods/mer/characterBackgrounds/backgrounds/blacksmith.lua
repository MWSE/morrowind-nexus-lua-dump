return {
    id = "blacksmith",
    name = "Apprenticed to a Blacksmith",
    description = (
        "Your master is a hard man. You gain a bonus to Strength (+5) " ..
        "and a bonus to your Armorer skill (+15), but you suffer a penalty " ..
        "to Agility (-10) due to the strenuous and repetitive hard labor."
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