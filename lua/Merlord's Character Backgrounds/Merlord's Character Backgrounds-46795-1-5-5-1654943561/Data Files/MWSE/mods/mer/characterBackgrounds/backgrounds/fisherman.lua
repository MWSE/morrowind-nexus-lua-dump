return {
    id = "fisherman",
    name = "Raised in a Fishing Village",
    description = (
        "You grew up in the quiet bustle of a remote fishing village. " ..
        "You never had got much of a formal education, but you " ..
        "know how to swim, harpoon and gut fish better than anybody. " ..
        "You receive a -10 penalty to Intelligence, and a +5 to Spear and Short Blade skills. " ..
        "You also gain a 25pt Swift Swim Ability."
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