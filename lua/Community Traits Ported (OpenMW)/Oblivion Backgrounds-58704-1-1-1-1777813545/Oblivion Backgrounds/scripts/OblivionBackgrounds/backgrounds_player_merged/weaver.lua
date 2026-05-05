local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "weaver",
    type = traitType,
    name = "Weaver",
    description = (
        "You were formed in the treacherous Spiral Skein, the dominion of Mephala. " ..
        "Swathed in falsehoods, your movements are as hidden as your intentions. " ..
        "Your strikes are venomous and made in anonymity. " ..
        "Webs beget webs, and your seat within the plots of others has scarred you. " ..
        "You persist still, holding onto the knowledge of plots and survival.\n" ..
        "\n" ..
        "+10 Sneak\n" ..
        "+5 Alchemy\n" ..
        "+50% Poison Resist\n" ..
        "-10 Willpower and Endurance\n" ..
        "> You start with a Charm power"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)
        
        selfSkills.sneak(self).base = selfSkills.sneak(self).base + 10
        selfSkills.alchemy(self).base = selfSkills.alchemy(self).base + 5
        
        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base - 10
        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base - 10

        selfSpells:add("lack_gg_mephalanvenom")
        selfSpells:add("lack_gg_temptingwhisper")
    end,
}
