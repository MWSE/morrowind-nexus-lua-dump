---@diagnostic disable: assign-type-mismatch
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.SagesBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "cultBorn",
    type = traitType,
    name = "Raised by Cultists",
    description = (
        "Your formative years could be described as less than normal. Raised in a communal cult dedicated " ..
        "to an obscure daedric lord, you learned the arts of persuasion at a young age " ..
        "to proselytize and bring in converts. As you grew older, you learned the blade was effective " ..
        "to fend off persecution. Unfortunately, the indoctrination left you more susceptible " ..
        "to the influence of others.\n" ..
        "\n" ..
        "> You start with a ceremonial dagger\n" ..
        "+10 Speechcraft\n" ..
        "+5 Short Blade\n" ..
        "-10 Willpower"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)
        
        selfSkills.speechcraft(self).base = selfSkills.speechcraft(self).base + 10
        selfSkills.shortblade(self).base = selfSkills.shortblade(self).base + 5
        
        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base - 10

        selfSpells:add("vss_careful_whspr")
        
        core.sendGlobalEvent(
            "SagesBackgrounds_addItems",
            {
                {
                    player = self,
                    itemId = "vss_RBCcerem_dagger",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "AB_c_CommonRobeBlack",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "AB_c_CommonHoodBlack",
                    count = 1,
                    autoEquip = true,
                },
                {
                    player = self,
                    itemId = "bk_reflectionsoncultworship...",
                    count = 1,
                    autoEquip = false,
                },
                {
                    player = self,
                    itemId = "vss_RbCring1",
                    count = 1,
                    autoEquip = true,
                },
            }
        )
    end,
}
