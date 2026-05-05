local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.SagesBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "catDad",
    type = traitType,
    name = "Raised by a Khajiit",
    description = (
        "As a foundling raised by a mad khajiit hermit, you have learned to" ..
        "defend yourself with only your fists and " ..
        "to move with purpose and grace. " ..
        "Unfortunately, your isolated upbringing has had a detrimental effect on your personality, " ..
        "and left you less well-spoken.\n" ..
        "\n" ..
        "+10 Hand to Hand\n" ..
        "+5 Acrobatics, Sneak, Agility\n" ..
        "-10 Speechcraft\n" ..
        "-5 Personality"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)

        selfSkills.handtohand(self).base = selfSkills.handtohand(self).base + 10
        selfSkills.acrobatics(self).base = selfSkills.acrobatics(self).base + 5
        selfSkills.sneak(self).base = selfSkills.sneak(self).base + 5
        selfAttrs.agility(self).base = selfAttrs.agility(self).base + 5

        selfSkills.speechcraft(self).base = selfSkills.speechcraft(self).base - 10
        selfAttrs.personality(self).base = selfAttrs.personality(self).base - 5
    end,
}
