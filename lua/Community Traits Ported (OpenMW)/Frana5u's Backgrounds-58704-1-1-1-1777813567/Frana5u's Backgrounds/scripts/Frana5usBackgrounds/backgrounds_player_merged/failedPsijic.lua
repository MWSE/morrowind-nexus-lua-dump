local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "failedpsijic",
    type = traitType,
    name = "Failed Psijic",
    description = (
        "You were expelled from the Psijic Order for studying forbidden knowledge. You still have the knowledge, "..
        "but the shame of your expulsion weighs heavily on you.\n" ..
        "\n" ..
        "Requirements: High Elves only.\n" ..
        "\n" ..
        "+10 Intelligence, Mysticism and Conjuration\n" ..
        "-20 Willpower\n" ..
        "> You start with a Fortfy Intelligence and Mysticism spell\n" ..
        "> You start with a Summon Bonlord and Greater Bonewalker power"
    ),
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        return self.type.records[self.recordId].race ~= "high elf"
    end,
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfAttrs.intelligence(self).base = selfAttrs.intelligence(self).base + 10
        selfSkills.mysticism(self).base = selfSkills.mysticism(self).base + 10
        selfSkills.conjuration(self).base = selfSkills.conjuration(self).base + 10

        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base - 20

        selfSpells:add("MB_worm_king")
        selfSpells:add("MB_Psj")
    end,
}
