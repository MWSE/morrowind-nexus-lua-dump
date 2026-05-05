local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "reveler",
    type = traitType,
    name = "Reveler",
    description = (
        "You were born in Sanguine's Realms of Revelry, and spent your life as a celebrant at the Prince's eternal parties." ..
        " You are fun to be around and can certainly hold your drink, but have no ability to resist temptation.\n" ..
        "\n" ..
        "+5 Personality, Endurance and Speechcraft\n" ..
        "-15 Willpower"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)

        selfAttrs.personality(self).base = selfAttrs.personality(self).base + 5
        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base + 5
        selfSkills.speechcraft(self).base = selfSkills.speechcraft(self).base + 5

        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base - 15
    end,
}
