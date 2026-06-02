local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.mercenarymerc.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "mercenary",
    type = traitType,
    name = "Mercenary",
    description = (
        "Working for scraps was never your style. Ever since leaving home, you've chased your fortune as a mercenary. " ..
        "All those countless questionable jobs and fallen comrades have eroded your moral compass and left you unable to connect with others again.\n" ..
        "\n" ..
	"+10 Mercantile\n" ..
        "+5 Endurance, Athletics, Blunt Weapons, Axe, Spear and Medium Armor\n" ..
        "-15 Willpower\n" ..
	"-10 Personality"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)
        
        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base + 5
        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base - 15
	selfAttrs.personality(self).base = selfAttrs.personality(self).base - 10

        selfSkills.mercantile(self).base = selfSkills.mercantile(self).base + 10
	selfSkills.athletics(self).base = selfSkills.athletics(self).base + 5
        selfSkills.heavyarmor(self).base = selfSkills.mediumarmor(self).base + 5
        selfSkills.bluntweapon(self).base = selfSkills.bluntweapon(self).base + 5
        selfSkills.spear(self).base = selfSkills.spear(self).base + 5
	selfSkills.axe(self).base = selfSkills.axe(self).base + 5
    end,
}

