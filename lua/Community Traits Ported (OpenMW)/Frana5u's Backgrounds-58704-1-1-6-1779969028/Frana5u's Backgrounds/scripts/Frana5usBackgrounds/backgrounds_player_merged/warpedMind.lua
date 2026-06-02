local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "warpedmind",
    type = traitType,
    name = "Warped Mind",
    description = (
        "You witnessed the Warp in the West. All times of it. This has driven you irrevocably insane. " ..
        "You have strange knowledge, but neither the will, nor the ability to express it.\n" ..
        "\n" ..
        "Requirements: Bretons only.\n" ..
        "\n" ..
        "+40 Intelligence and Mysticism\n" ..
        "-25 Personality, Willpower and Speechcraft\n" ..
        "> You start with a Detect spell"
    ),
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        return self.type.records[self.recordId].race ~= "breton"
    end,
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfAttrs.intelligence(self).base = selfAttrs.intelligence(self).base + 40
        selfSkills.mysticism(self).base = selfSkills.mysticism(self).base + 40
        
        selfAttrs.personality(self).base = selfAttrs.personality(self).base -25
        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base -25
        selfSkills.speechcraft(self).base = selfSkills.speechcraft(self).base -25

        selfSpells:add("MB_mad_sight")
    end,
}
