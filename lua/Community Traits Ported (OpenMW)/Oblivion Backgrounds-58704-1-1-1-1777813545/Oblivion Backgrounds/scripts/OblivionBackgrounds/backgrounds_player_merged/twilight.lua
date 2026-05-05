local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "twilight",
    type = traitType,
    name = "Bathed in Twilight",
    description = (
        "You were born in the painted shades of Moonshadow, the garden of Azura. " ..
        "As like art, you are shaped in beauty and wonder. " ..
        "Your experience in the overwhelming sea painted in Her image lets you see beyond surfaces. " ..
        "The constant perfume and song has hazed your mind and weakened your fist. " ..
        "Despite your absence, Azura still sees you as a light in her garden, and eagerly awaits your return.\n" ..
        "\n" ..
        "+10 Personality\n" ..
        "+5 Willpower, Mysticism and Conjuration\n" ..
        "-5 Intelligence, Strength and Agility\n" ..
        "> You start with a Detect power\n" ..
        "> You cannot use any religious shrines"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)
        
        selfAttrs.personality(self).base = selfAttrs.personality(self).base + 10
        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base + 5
        selfSkills.mysticism(self).base = selfSkills.mysticism(self).base + 5
        selfSkills.conjuration(self).base = selfSkills.conjuration(self).base + 5

        selfAttrs.intelligence(self).base = selfAttrs.intelligence(self).base - 5
        selfAttrs.strength(self).base = selfAttrs.strength(self).base - 5
        selfAttrs.agility(self).base = selfAttrs.agility(self).base - 5

        selfSpells:add("lack_gg_liminalsight")
    end,
    onLoad = function()
        core.sendGlobalEvent("OblivionBackgrounds_registerTwilight", self.id)
    end
}
