---@diagnostic disable: assign-type-mismatch
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.SagesBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "slayer",
    type = traitType,
    name = "Slayer",
    description = (
        "Into every generation, a Slayer is born: one being in all the world, " ..
        "a chosen one. They alone will weild the strength and skill to fight " ..
        "the vampires, daedra, and forces of darkness; to stop the spread of their " ..
        "evil and the swell of their number. You are the Slayer. " ..
        "Bearing both a blessing and a curse, " ..
        "you carry your blessed stake and tome of " ..
        "knowledge into battle.\n" ..
        "\n" ..
        "> You start with a blessed stake and a tome of knowledge\n" ..
        "+5 Agility, Strength and Speed\n" ..
        "+10% Weakness to Magicka"
    ),
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        -- local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfSpells:add("vss_buffyblood")

        core.sendGlobalEvent(
            "SagesBackgrounds_addItems",
            {
                {
                    player = self,
                    itemId = "vss_buffystake",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "vss_buffybk1",
                    count = 1,
                    autoEquip = false,
                },
            }
        )
    end,
}
