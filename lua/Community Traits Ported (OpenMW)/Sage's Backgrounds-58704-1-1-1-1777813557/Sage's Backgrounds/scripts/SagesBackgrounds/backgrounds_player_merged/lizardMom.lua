local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.SagesBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "lizardMom",
    type = traitType,
    name = "Raised by an Argonian",
    description = (
        "As a small child, you were found wandering Black Marsh by a kindly " ..
        "Argonian shaman, who raised you as her own. Through her tutelage, " ..
        "you learned the ways of the shaman. " ..
        "Growing up in the vast swamp also taught you to navigate it's bays and " ..
        "bayous nearly as well as a native Argonian. " ..
        "Unfortunately, your non-argonian physiology was not designed for life in the dark " ..
        "swamp, and your constitution suffers for it.\n" ..
        "\n" ..
        "+5 Mysticism, Illusion and Alchemy\n" ..
        "-5 Endurance and Strength\n" ..
        "> You start with Buoyancy and Water Breathing spells"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfSkills.mysticism(self).base = selfSkills.mysticism(self).base + 5
        selfSkills.illusion(self).base = selfSkills.illusion(self).base + 5
        selfSkills.alchemy(self).base = selfSkills.alchemy(self).base + 5

        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base - 5
        selfAttrs.strength(self).base = selfAttrs.strength(self).base - 5

        selfSpells:add("buoyancy")
        selfSpells:add("water breathing")
    end,
}
