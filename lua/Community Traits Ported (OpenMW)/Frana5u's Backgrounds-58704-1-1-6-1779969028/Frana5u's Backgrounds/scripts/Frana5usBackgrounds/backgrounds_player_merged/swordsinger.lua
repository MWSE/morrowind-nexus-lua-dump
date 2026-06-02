local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "swordsinger",
    type = traitType,
    name = "Sword-Singer",
    description = (
        "You dedicated your life to the path of the Sword-Singer and have learnt to manifest your spirit sword. "..
        "However, this dedication to a singular path has left your other combat skills to atrophy.\n" ..
        "\n" ..
        "Requirements: Redguards only.\n" ..
        "\n" ..
        "+20 Long Blade and Agility\n" ..
        "> All other weapon and block skills are set to 0\n" ..
        "> You start with an offensive Spirit Sword power"
    ),
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        return self.type.records[self.recordId].race ~= "redguard"
    end,
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfSkills.longblade(self).base = selfSkills.longblade(self).base + 20
        selfAttrs.agility(self).base = selfAttrs.agility(self).base + 20

        selfSkills.axe(self).base = 0
        selfSkills.bluntweapon(self).base = 0
        selfSkills.handtohand(self).base = 0
        selfSkills.marksman(self).base = 0
        selfSkills.spear(self).base = 0
        selfSkills.shortblade(self).base = 0
        selfSkills.block(self).base = 0

        selfSpells:add("MB_spirit_sword")
    end,
}
