local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background
local period = 1

I.CharacterTraits.addTrait {
    id = "sixthscion",
    type = traitType,
    name = "Scion of the Sixth House",
    description = (
        "Unbeknownst to you, you are a descendant of a member of the Sixth House. " ..
        "You are more susceptible to blight disease, and people are instinctively wary of you, " ..
        "but you have incredible powers of manipulation.\n" ..
        "\n" ..
        "Requirements: Dark Elves only.\n" ..
        "\n" ..
        "+75 pt vulnerability to Blight\n" ..
        "> Your Personality is limited to 20\n" ..
        "> You start with 4 powers: Calm, Charm, Demoralize and Frenzy"
    ),
    checkDisabled = function()
        ---@diagnostic disable-next-line: undefined-field
        return self.type.records[self.recordId].race ~= "dark elf"
    end,
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        -- local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfSpells:add("MB_blighted")
        selfSpells:add("MB_scion_calm")
        selfSpells:add("MB_scion_charm")
        selfSpells:add("MB_scion_fear")
        selfSpells:add("MB_scion_frenzy")
    end,
    onLoad = function()
        local personality = self.type.stats.attributes.personality(self)
        time.runRepeatedly(
            function()
                personality.base = math.min(personality.base, 20)
            end,
            period
        )
    end
}
