local config = require('mer.characterBackgrounds.config')
return {
    id = "inheritance",
    name = "Наследник",
    description = function()
        return string.format(
            "В раннем детстве вы остались сиротой и унаследовали значительную сумму денег (+%s золотых). Беззаботная жизнь сделала вас слабовольным (-10).",
            config.mcm.inheritanceAmount
        )
    end,
    doOnce = function()
        --debuff willpower
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower,
            value = -10
        })
        --Add gold
        local amount = tonumber(config.mcm.inheritanceAmount)
        tes3.addItem{
            reference = tes3.player,
            item = "Gold_001",
            count = amount,
        }
    end
}