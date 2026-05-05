local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "legionnaire",
    type = traitType,
    name = "Ex-Legionnaire",
    description = (
        "Long marches and fighting in a shield-wall have honed your skills and made you tough. "..
        "Unfortunately, a lifetime of following orders has critically impacted your decison-making skills.\n" ..
        "\n" ..
        "+10 Endurance, Athletics, Block, Heavy Armor and Long Blade\n" ..
        "-20 Willpower"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)
        
        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base + 10
        selfSkills.athletics(self).base = selfSkills.athletics(self).base + 10
        selfSkills.block(self).base = selfSkills.block(self).base + 10
        selfSkills.heavyarmor(self).base = selfSkills.heavyarmor(self).base + 10
        selfSkills.longblade(self).base = selfSkills.longblade(self).base + 10

        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base - 20
    end,
}
