return {
    id = "hyperactive",
    name = "Гиперактивный",
    description = (
        "Вы все время заняты. Ваша скорость выше обычного (+10), но вы раздражаете " ..
        "большинство людей, что отразилось на вашей привлекательности (-10). "
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