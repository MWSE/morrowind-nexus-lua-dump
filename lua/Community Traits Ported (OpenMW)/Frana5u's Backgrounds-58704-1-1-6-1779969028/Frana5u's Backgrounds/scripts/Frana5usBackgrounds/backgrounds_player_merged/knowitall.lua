local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "knowitall",
    type = traitType,
    name = "Know-It-All",
    description = (
        "You are the smartest person in the room, and you're not afraid to let people know it. " ..
        "Somehow, this doesn't endear you to them.\n" ..
        "\n" ..
        "+30 Intelligence\n" ..
        "-30 Personality"
    ),
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)

        selfAttrs.intelligence(self).base = selfAttrs.intelligence(self).base + 30

        selfAttrs.personality(self).base = selfAttrs.personality(self).base - 30
    end,
}
