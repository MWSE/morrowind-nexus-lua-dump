---@diagnostic disable: assign-type-mismatch
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.SagesBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "ronin",
    type = traitType,
    name = "Ronin",
    description = (
        "Orphaned and taken as a slave in a bandit raid, you learned early on to move silently " ..
        "to avoid beatings, and rarely spoke to your captors. " ..
        "As you grew older, you were forced to take part in the gang's nefarious acts, " ..
        "learning the way of the blade. Eventually, you were able to slay the bandit leader " ..
        "and claim his prize possession - a blessed sword pilfered from a forgotten temple. Since then, you " ..
        "have wandered Tamriel, using that thrice-blessed blade to atone for the acts you were forced to commit " ..
        "while in servitude to the bandits.\n" ..
        "\n" ..
        "> You start with a thrice-blessed blade\n" ..
        "+10 Long Blade\n" ..
        "+5 Sneak, Agility\n" ..
        "-10 Speechcraft\n" ..
        "-5 Personality"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)

        selfSkills.longblade(self).base = selfSkills.longblade(self).base + 10
        selfSkills.sneak(self).base = selfSkills.sneak(self).base + 5
        selfAttrs.agility(self).base = selfAttrs.agility(self).base + 5

        selfSkills.speechcraft(self).base = selfSkills.speechcraft(self).base - 10
        selfAttrs.personality(self).base = selfAttrs.personality(self).base - 5

        core.sendGlobalEvent(
            "SagesBackgrounds_addItems",
            {
                {
                    player = self,
                    itemId = "vss_samblade",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "vss_CHN_ROBE4d",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "vss_GetaShoes",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "AB_a_WickerHelm02",
                    count = 1,
                    autoEquip = true,
                },
            }
        )
    end,
}
