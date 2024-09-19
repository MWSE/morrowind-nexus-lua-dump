return {
    id = "noble",
    name = "Adopted by Nobles",
    description = (
        "Adopted by a noble family at a very young age, you lived a life of comfort and luxury. " ..
        "You had a formal education where you learned to read and speak with manners " ..
        "(+5 Intelligence, +10 Speechcraft). However, being waited on hand and foot has left " ..
        "you with a lack of Willpower (-10). You are provided with a set of expensive clothing, " ..
        "a gift from your adoptive parents. "
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