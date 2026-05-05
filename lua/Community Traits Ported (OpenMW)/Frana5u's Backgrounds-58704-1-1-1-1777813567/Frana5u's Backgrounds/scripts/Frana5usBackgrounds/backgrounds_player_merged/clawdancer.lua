local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background
local raceCheckers = require("scripts.Frana5usBackgrounds.utils.raceGroups")

I.CharacterTraits.addTrait {
    id = "clawdancer",
    type = traitType,
    name = "Claw-Dancer",
    description = (
        "You have studied your people's martial arts in the monasteries in Elsweyr, and have grown skilled in them. " ..
        "However, because of this you have no skills in fighting in any kind of armor.\n" ..
        "\n" ..
        "Requirements: Khajiits only.\n" ..
        "\n" ..
        "+25 Hand-to-Hand, Unarmored, Acrobatics and Athletics\n" ..
        "+10 Speed and Agility\n" ..
        "> All your armor skills are set to 0\n" ..
        "> You start with an offensive Claw-Dance power"
    ),
    checkDisabled = function()
        return not raceCheckers.isKhajiit(self)
    end,
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfSkills.handtohand(self).base = selfSkills.handtohand(self).base + 25
        selfSkills.unarmored(self).base = selfSkills.unarmored(self).base + 25
        selfSkills.acrobatics(self).base = selfSkills.acrobatics(self).base + 25
        selfSkills.athletics(self).base = selfSkills.athletics(self).base + 25
        selfAttrs.speed(self).base = selfAttrs.speed(self).base + 10
        selfAttrs.agility(self).base = selfAttrs.agility(self).base + 10

        selfSkills.lightarmor(self).base = 0
        selfSkills.mediumarmor(self).base = 0
        selfSkills.heavyarmor(self).base = 0

        selfSpells:add("MB_claw_dance")
    end,
}
