local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local time = require("openmw_aux.time")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

local period = 1

local function isFullMoon()
    local currTime = core.getGameTime()
    local day = math.floor(currTime / (24 * 60 * 60))
    return day % 8 == 1
end

I.CharacterTraits.addTrait {
    id = "shivering",
    type = traitType,
    name = "Shivering Islander",
    description = (
        "You were born in the Madgod's Realm. You can still hear Sheogorath's voice at certain times, " ..
        "and other people have a hard time understanding your disordered thoughts. " ..
        "You can share your madness with others, " ..
        "and the constant hallucinations have made you relatively apt at discerning reality from the Madgod's visions.\n" ..
        "\n" ..
        "+10 Willpower\n" ..
        "-10 Speechcraft\n" ..
        "+15 pt Sound during the full moon\n" ..
        "> You start with a Frenzy power"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base + 10
        selfSkills.speechcraft(self).base = selfSkills.speechcraft(self).base - 10

        selfSpells:add("lack_gg_InfectiousInsanity")
    end,
    onLoad = function()
        local selfSpells = self.type.spells(self)
        time.runRepeatedly(
            function()
                local fullMoon = isFullMoon()
                if fullMoon and not selfSpells["lack_gg_SheoWhispers"] then
                    selfSpells:add("lack_gg_SheoWhispers")
                    self:sendEvent("ShowMessage", { message = "You begin to hear voices..." })
                elseif not fullMoon and selfSpells["lack_gg_SheoWhispers"] then
                    selfSpells:remove("lack_gg_SheoWhispers")
                    self:sendEvent("ShowMessage", { message = "The shadowed moons quiet the voices..." })
                end
            end,
            period
        )
    end
}
