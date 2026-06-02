local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "lucky",
    type = traitType,
    name = "Lucky",
    description = (
        "You have always been incredibly lucky. Unfortunately this has left you to coast by on your luck alone and " ..
        "neglect everything else.\n" ..
        "\n" ..
        "> Your Luck is set to 100\n" ..
        "> Your all other attributes are set to 10\n" ..
        "> All your skills are set to 5"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)

        for attrName, attrHandler in pairs(selfAttrs) do
            if attrName == "luck" then
                attrHandler(self).base = 100
            else
                attrHandler(self).base = 10
            end
        end

        for _, skillHandler in pairs(selfSkills) do
            skillHandler(self).base = 5
        end
    end,
}
