local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "huntsman",
    type = traitType,
    name = "Huntsman",
    description = (
        "You were born in Hircine's Hunting Grounds, and spent your youth as quarry... and then, as predator. " ..
        "You can smell blood from yards away, none can escape your pursuit, " ..
        "and you are skilled in all the favored weaponry of huntsmen. " ..
        "Hircine's primal forests did little to prepare you for city life, however.\n" ..
        "\n" ..
        "+5 Speed, Spear and Marksman\n" ..
        "-10 Personality and Intelligence\n" ..
        "+25 pt Detect Creature"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfAttrs.speed(self).base = selfAttrs.speed(self).base + 5
        selfSkills.spear(self).base = selfSkills.spear(self).base + 5
        selfSkills.marksman(self).base = selfSkills.marksman(self).base + 5

        selfAttrs.personality(self).base = selfAttrs.personality(self).base - 10
        selfAttrs.intelligence(self).base = selfAttrs.intelligence(self).base - 10

        selfSpells:add("lack_gg_Huntsman")
    end,
}
