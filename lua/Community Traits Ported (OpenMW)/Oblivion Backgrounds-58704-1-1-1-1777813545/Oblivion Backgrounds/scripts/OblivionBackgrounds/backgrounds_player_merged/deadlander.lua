local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "deadlander",
    type = traitType,
    name = "Deadlander",
    description = (
        "You were born in the Deadlands, the hellish realm of Mehrunes Dagon. " ..
        "The torturous flames have tempered you into an instrument of death " ..
        "but you are cannot stand colder climes and are incapable of facial expressions beyond a cruel glower.\n" ..
        "\n" ..
        "+5 Destruction\n" ..
        "+25% Rests Fire\n" ..
        "-15 Personality\n" ..
        "+50% Weakness to Frost\n" ..
        "> You start with a Fire Shield power"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfSkills.destruction(self).base = selfSkills.destruction(self).base + 5
        selfAttrs.personality(self).base = selfAttrs.personality(self).base - 15

        selfSpells:add("lack_gg_Deadlander")
        selfSpells:add("lack_gg_DeadlanderFlames")
    end,
}
