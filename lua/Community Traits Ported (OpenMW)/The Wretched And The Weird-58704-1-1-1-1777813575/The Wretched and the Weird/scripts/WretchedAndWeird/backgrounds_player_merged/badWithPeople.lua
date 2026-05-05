local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")

local traitType = require("scripts.WretchedAndWeird.utils.traitTypes").background

local period = 5 * time.second

I.CharacterTraits.addTrait {
    id = "badWithPeople",
    type = traitType,
    name = "Bad with People",
    description = (
        "People skills have never come naturally to you. " ..
        "Almost every social interaction feels like a struggle, " ..
        "but you have an affinity for working with inanimate objects.\n" ..
        "\n" ..
        "+10 Alchemy, Enchant, Security, and Armorer\n" ..
        "> Personality is set to 0 and cannot be increased with level or birthsign"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        -- local selfAttrs = self.type.stats.attributes

        selfSkills.alchemy(self).base = selfSkills.alchemy(self).base + 10
        selfSkills.enchant(self).base = selfSkills.enchant(self).base + 10
        selfSkills.security(self).base = selfSkills.security(self).base + 10
        selfSkills.armorer(self).base = selfSkills.armorer(self).base + 10
    end,
    onLoad = function()
        local personality = self.type.stats.attributes.personality(self)
        time.runRepeatedly(
            function()
                personality.base = 0
            end,
            period
        )
    end
}
