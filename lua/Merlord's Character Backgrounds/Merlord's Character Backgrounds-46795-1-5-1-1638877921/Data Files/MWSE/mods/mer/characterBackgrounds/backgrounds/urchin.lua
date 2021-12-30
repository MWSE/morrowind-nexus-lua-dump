return {
    id = "urchin",
    name = "Street Urchin",
    description = (
        "You grew up on the streets, alone and poor. You had no one to watch over you " ..
        "or to provide for you, so you learned to lie, cheat and steal just to get by. " ..
        "You gain a +10 bonus to Sneak, Security and Speechcraft. However, years " ..
        "of poverty has left your body weak. You receive a -5 penalty to Strength and Endurance. "
    ),
    doOnce = function()
        -- stat penalties
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance,
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength,
            value = -5
        })

        --Skill buffs
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak,
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security,


            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft,
            value = 10
        })
    end
}