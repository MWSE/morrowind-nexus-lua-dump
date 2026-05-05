local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "fisherman",
    type = traitType,
    name = "Raised in a Fishing Village",
    description = (
        "You grew up in the quiet bustle of a remote fishing village. " ..
        "You never had got much of a formal education, but you " ..
        "know how to swim, harpoon and gut fish better than anybody. " ..
        "You receive a -10 penalty to Intelligence, and a +5 to Spear and Short Blade skills. " ..
        "You also gain a 25pt Swift Swim Ability.\n" ..
        "\n" ..
        "+5 Spear\n" ..
        "+5 Short Blade\n" ..
        "-5 Intelligence\n" ..
        "+25 pts Swift Swim"
    ),
    doOnce = function()
        local intelligence = self.type.stats.attributes.intelligence(self)
        intelligence.base = intelligence.base - 10

        local spear = self.type.stats.skills.spear(self)
        spear.base = spear.base + 5

        local shortBlade = self.type.stats.skills.shortblade(self)
        shortBlade.base = shortBlade.base + 5

        local spells = self.type.spells(self)
        spells:add("mer_bg_fisher_feet")
    end,
}
