local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "apprenticeGreybeard",
    type = traitType,
    name = "Apprentice Greybeard",
    description = (
        "You studied with the Greybeards at the Throat of the World. You learned many things and the cold made you hardy "..
        "and not easily paralyzed by its bite, but it also crept in your bones and the isolation didn't do your social skills much good.\n" ..
        "\n" ..
        "Requirements: Nords only.\n" ..
        "\n" ..
        "+20 Endurance\n" ..
        "+30 pt Paralysis Resistance\n" ..
        "-20 Agility, Speed, and Personality\n" ..
        "> Your Speechcraft is set to 0\n" ..
        "> You start with 6 shout-themed powers"
    ),
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        return self.type.records[self.recordId].race ~= "nord"
    end,
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base + 20

        selfAttrs.agility(self).base = selfAttrs.agility(self).base - 20
        selfAttrs.speed(self).base = selfAttrs.speed(self).base - 20
        selfAttrs.personality(self).base = selfAttrs.personality(self).base - 20

        selfSkills.speechcraft(self).base = 0

        selfSpells:add("MB_mountain")
        selfSpells:add("MB_breath_north")
        selfSpells:add("MB_scale_dragon")
        selfSpells:add("MB_shors_bones")
        selfSpells:add("MB_stormcrown")
        selfSpells:add("MB_thundering_voice")
        selfSpells:add("MB_voice_of_kyne")
    end,
}
