return {
    id = "noble",
    name = "Воспитанник знати",
    description = (
        "В юном возрасте вас усыновила знатная семья, и вы жили в роскоши и комфорте. " ..
        "Вы получили образование, научившись читать и учтиво разговаривать " ..
        "(+5 к интеллекту, +10 к Красноречию). Однако потакание вашим капризам " ..
        "не позволило закалиться вашей воле (-10). Вы получаете комплект дорогой одежды, " ..
        "подарок от вашей приемной семьи. "
    ),
    doOnce = function()
        --buffs
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence,
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft,
            value = 10
        })

        --debuffs
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower,
            value = -10
        })

        --Clothing
        local clothes = {
            "expensive_shirt_03",
            "expensive_belt_03",
            "expensive_pants_02",
            "expensive_shoes_03",
        }
        for _, id in ipairs(clothes) do
            tes3.addItem{ reference = tes3.player, item = id }
        end
        timer.delayOneFrame(
            function()
                for _, id in ipairs(clothes) do
                   tes3.mobilePlayer:equip{ item = id }
                end
            end
        )
    end
}