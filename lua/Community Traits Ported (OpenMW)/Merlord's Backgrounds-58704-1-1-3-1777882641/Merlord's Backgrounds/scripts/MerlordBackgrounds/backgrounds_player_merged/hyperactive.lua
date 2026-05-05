local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "hyperactive",
    type = traitType,
    name = "Hyperactive",
    description = (
        "You are constantly busy. Your run faster than normal, but most " ..
        "people find you annoying, and your personality suffers.\n" ..
        "\n" ..
        "+10 Speed\n" ..
        "-10 Personality"
    ),
    doOnce = function()
        local speed = self.type.stats.attributes.intelligence(self)
        speed.base = speed.base + 10

        local personality = self.type.stats.attributes.personality(self)
        personality.base = personality.base - 10
    end,
}