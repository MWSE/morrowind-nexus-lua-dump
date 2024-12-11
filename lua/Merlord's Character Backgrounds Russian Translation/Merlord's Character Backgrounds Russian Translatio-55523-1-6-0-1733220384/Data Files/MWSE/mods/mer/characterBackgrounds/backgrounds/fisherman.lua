return {
    id = "fisherman",
    name = "Ребенок рыбаков",
    description = (
        "Вы выросли в захолустной рыбацкой деревушке. " ..
        "Вы не получили образования, зато прекрасно умеете " ..
        "плавать, метать гарпун и разделывать рыбу. " ..
        "Вы получаете -10 к интеллекту и +5 к Древковому оружию и Коротким клинкам. " ..
        "Также вы получаете способность Быстрое плавание 25 пунктов."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence,
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear,
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade,
            value = 5
        })
        tes3.addSpell{
            reference = tes3.player,
            spell = "mer_bg_fisher_feet"
        }
    end
}