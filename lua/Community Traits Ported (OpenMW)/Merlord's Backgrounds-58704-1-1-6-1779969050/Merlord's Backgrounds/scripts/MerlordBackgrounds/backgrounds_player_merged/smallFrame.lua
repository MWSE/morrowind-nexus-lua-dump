local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "smallFrame",
    type = traitType,
    name = "Small Frame",
    description = (
        "You were the runt of the litter. This makes you rather weak, "..
        "but your small stature does make you harder to hit.\n" ..
        "\n" ..
        "+10 Agility\n" ..
        "-10 Strength"
    ),
    doOnce = function()
        local agility = self.type.stats.attributes.agility(self)
        agility.base = agility.base + 10

        local strength = self.type.stats.attributes.strength(self)
        strength.base = strength.base - 10
    end,
}