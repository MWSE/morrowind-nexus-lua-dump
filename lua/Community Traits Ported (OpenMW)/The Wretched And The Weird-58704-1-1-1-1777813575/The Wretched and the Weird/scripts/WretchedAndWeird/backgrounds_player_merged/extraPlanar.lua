local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.WretchedAndWeird.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "extraPlanar",
    type = traitType,
    name = "Born on Another Plane",
    description = (
        "Mundus was not the first world you laid eyes upon. " ..
        "You were born in another dimension, and some of your youth was spent in a foreign reality. " ..
        "This has given you an innate talent in communicating across the planes, " ..
        "but you never quite got used to the physics of Nirn.\n" ..
        "\n" ..
        "+10 Conjuration\n" ..
        "-5 Acrobatics and Alteration"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        -- local selfAttrs = self.type.stats.attributes

        selfSkills.conjuration(self).base = selfSkills.conjuration(self).base + 10

        selfSkills.acrobatics(self).base = selfSkills.acrobatics(self).base - 5
        selfSkills.alteration(self).base = selfSkills.alteration(self).base - 5
    end,
}
