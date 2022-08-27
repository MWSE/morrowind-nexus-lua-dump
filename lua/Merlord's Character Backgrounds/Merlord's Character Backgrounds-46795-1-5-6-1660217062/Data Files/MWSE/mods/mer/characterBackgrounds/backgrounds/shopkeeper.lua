return {
    id = "shopkeeper",
    name = "Apprenticed to a Shopkeeper",
    description = (
        "Spending your whole childhood inside a shop, you gain an exceptional " ..
        "bonus to Mercantile(+20), but your shrewd business practices makes you " ..
        "rather unlikeable (-10 Personality)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile,
            value = 20
        })

        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality,
            value = -10
        })
    end
}