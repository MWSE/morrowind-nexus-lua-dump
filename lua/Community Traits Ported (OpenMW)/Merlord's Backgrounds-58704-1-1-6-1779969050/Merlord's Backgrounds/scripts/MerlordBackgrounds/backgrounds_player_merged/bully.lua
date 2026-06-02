local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "bully",
    type = traitType,
    name = "Bully",
    description = (
        "You were the class bully, big and dumb. Extortion and intimidation have afforded you a bonus to strength, " ..
        "but getting people to do your homework for you leaves you with a deficiency in intelligence.\n" ..
        "\n" ..
        "+10 Strength\n" ..
        "-10 Intelligence"
    ),
    doOnce = function()
        local strength = self.type.stats.attributes.strength(self)
        strength.base = strength.base + 10

        local intelligence = self.type.stats.attributes.intelligence(self)
        intelligence.base = intelligence.base - 10
    end,
}