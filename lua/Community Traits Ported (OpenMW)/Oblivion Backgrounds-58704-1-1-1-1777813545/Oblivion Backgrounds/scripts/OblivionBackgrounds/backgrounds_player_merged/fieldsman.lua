local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "fieldsman",
    type = traitType,
    name = "Fieldsman",
    description = (
        "You were born in the Fields of Regret, the Plane of Clavicus Vile. " ..
        "You are adept at convincing others to take questionable deals , " ..
        "but you struggle to resist making a dodgy bargain yourself.\n" ..
        "\n" ..
        "+5 Mercantile and Speechcraft\n" ..
        "-10 Willpower"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)
        
        selfSkills.mercantile(self).base = selfSkills.mercantile(self).base + 5
        selfSkills.speechcraft(self).base = selfSkills.speechcraft(self).base + 5

        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base - 10
    end,
}
