local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "coldharbor",
    type = traitType,
    name = "Spawn of Coldharbor",
    description = (
        "Much of your life was spent in Coldharbor, the plane of the Prince of Domination. " ..
        "The dismal realm left its scars on your body, but you have learned how to dominate the weak.\n" ..
        "\n" ..
        "+25% Resist Frost\n" ..
        "+100% Weakness to Fire\n" ..
        "> You start with a Burden and Frost Damage power"
    ),
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        -- local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfSpells:add("lack_gg_ColdHarborChains")
        selfSpells:add("lack_gg_ColdHarborElements")
    end,
}
