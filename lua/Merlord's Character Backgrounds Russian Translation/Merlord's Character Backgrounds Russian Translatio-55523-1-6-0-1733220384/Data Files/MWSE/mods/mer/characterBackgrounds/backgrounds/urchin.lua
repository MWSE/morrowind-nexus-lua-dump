return {
    id = "urchin",
    name = "Беспризорник",
    description = (
        "Вы выросли на улицах, в нищете и одиночестве. За вами никто не присматривал " ..
        "и не заботился о вас, поэтому, чтобы выжить, вам пришлось научиться лжи, мошенничеству и воровству. " ..
        "Вы получаете +10 к Скрытности, Безопасности и Красноречию. Однако годы, " ..
        "проведенные в нищете, дурно отразились на вашем физическом состоянии. Вы получаете -5 в силе и выносливости. "
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