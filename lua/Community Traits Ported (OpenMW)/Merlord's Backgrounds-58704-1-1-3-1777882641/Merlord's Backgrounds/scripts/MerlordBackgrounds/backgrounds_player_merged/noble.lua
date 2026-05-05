---@diagnostic disable: assign-type-mismatch
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "noble",
    type = traitType,
    name = "Adopted by Nobles",
    description = (
        "Adopted by a noble family at a very young age, you lived a life of comfort and luxury. " ..
        "You had a formal education where you learned to read and speak with manners. " ..
        "However, being waited on hand and foot has left you with a lack of willpower. " ..
        "You are provided with a set of expensive clothing, a gift from your adoptive parents.\n" ..
        "\n" ..
        "+5 Intelligence\n" ..
        "+5 Speechcraft\n" ..
        "-10 Willpower\n" ..
        "> You start with a set of expensive clothing"
    ),
    doOnce = function()
        local intelligence = self.type.stats.attributes.intelligence(self)
        intelligence.base = intelligence.base + 5

        local speechcraft = self.type.stats.skills.speechcraft(self)
        speechcraft.base = speechcraft.base + 10

        local willpower = self.type.stats.attributes.willpower(self)
        willpower.base = willpower.base - 10

        core.sendGlobalEvent(
            "MerlordsTraits_addItems",
            {
                {
                    player = self,
                    itemId = "expensive_shirt_03",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "expensive_belt_03",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "expensive_pants_02",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "expensive_shoes_03",
                    count = 1,
                    autoEquip = true,
                },
            }
        )
    end,
}
