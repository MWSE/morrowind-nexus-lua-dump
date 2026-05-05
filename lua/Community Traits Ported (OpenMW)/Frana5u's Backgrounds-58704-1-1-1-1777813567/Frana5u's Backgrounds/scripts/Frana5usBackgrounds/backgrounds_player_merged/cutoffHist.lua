---@diagnostic disable: missing-parameter
local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "cutoffHist",
    type = traitType,
    name = "Cut off from the Hist",
    description = (
        "Unlike the rest of your people, you have no connection to the Hist. This means you don't have the ancestral "..
        "resistance to disease and poison, but you seem somehow less connected to the Earthbones. Some days you think you "..
        "can just jump and never come down, but you haven't given in to temptation... yet.\n" ..
        "\n" ..
        "Requirements: Argonians only.\n" ..
        "\n" ..
        "+5 pt Jump\n" ..
        "> You no longer have Poison Immunity and Disease Resistance\n" ..
        "> You start with a Fortify Acrobatics power"
    ),
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        return self.type.records[self.recordId].race ~= "argonian"
    end,
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        -- local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)
        local selfActiveEffects = self.type.activeEffects(self)

        selfSpells:add("MB_release")
        selfSpells:add("MB_reach_stars")

        selfActiveEffects:remove("resistcommondisease")
        selfActiveEffects:remove("resistpoison")
    end,
}
