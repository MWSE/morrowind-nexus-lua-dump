local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "urchin",
    type = traitType,
    name = "Street Urchin",
    description = (
        "You grew up on the streets, alone and poor. You had no one to watch over you "..
        "or to provide for you, so you learned to lie, cheat and steal just to get by. "..
        "However, years of poverty has left your body weak.\n" ..
        "\n" ..
        "+10 Sneak, Security and Speechcraft\n" ..
        "-5 Endurance and Strength"
    ),
    doOnce = function()
        local endurance = self.type.stats.attributes.endurance(self)
        endurance.base = endurance.base - 5

        local strength = self.type.stats.attributes.strength(self)
        strength.base = strength.base - 5

        local sneak = self.type.stats.skills.sneak(self)
        sneak.base = sneak.base + 10

        local security = self.type.stats.skills.security(self)
        security.base = security.base + 10

        local speechcraft = self.type.stats.skills.speechcraft(self)
        speechcraft.base = speechcraft.base + 10
    end,
}