local config = require('mer.characterBackgrounds.config')
return {
    id = "inheritance",
    name = "Inheritance",
    description = function()
        return string.format(
            "You were orphaned as a young child and inherited a lot of money (+%s gold). The easy life has cost you a penalty to Willpower (-10).",
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