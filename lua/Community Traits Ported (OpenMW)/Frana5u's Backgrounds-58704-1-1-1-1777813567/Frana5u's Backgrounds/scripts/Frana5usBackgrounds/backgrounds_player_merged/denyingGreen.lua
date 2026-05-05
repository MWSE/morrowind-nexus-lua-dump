---@diagnostic disable: missing-parameter
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "denyingGreen",
    type = traitType,
    name = "Denying the Green",
    description = (
        "You were born far from Valenwood, and you think the Green Pact is superstitious nonsense. You like "..
        "vegetables, and anyways, plants are useful for alchemy. You're certainly not more susceptible to disease than your "..
        "fellow Wood Elves and it is just coincidence that otherwise peaceful animals keep attacking you.\n" ..
        "\n" ..
        "Requirements: Wood Elves only.\n" ..
        "\n" ..
        "+10 Alchemy\n" ..
        "> Your Resistance to Common Diseases is replaced with 25 pt Weakness to them\n" ..
        "> You start with a Reflect spell\n" ..
        "> You start with a Frenzy power\n" ..
        "> All Guars and Scribs turn hostile"
    ),
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        return self.type.records[self.recordId].race ~= "wood elf"
    end,
    doOnce = function()
        local selfSkills = self.type.stats.skills
        -- local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)
        local selfActiveEffects = self.type.activeEffects(self)

        selfSkills.alchemy(self).base = selfSkills.alchemy(self).base + 10

        selfSpells:add("MB_denial")
        selfSpells:add("MB_sceptic")

        selfActiveEffects:remove("resistcommondisease")
    end,
    onLoad = function()
        core.sendGlobalEvent("Frana5usBackgrounds_registerDenyingGreen", self)
    end,
}
