local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local time = require("openmw_aux.time")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

local period = 1
local nightPoint = 18 * time.hour
local dayPoint = 6 * time.hour

local function isNight()
    local clockTime = math.fmod(core.getGameTime(), time.day)
    return dayPoint > clockTime or clockTime >= nightPoint
end

I.CharacterTraits.addTrait {
    id = "voidwalker",
    type = traitType,
    name = "Voidwalker",
    description = (
        "You were born in Namira's dark plane of Oblivion. You never saw daylight until you arrived on Nirn, " ..
        "nor did you ever converse with anyone but dark skittering things. " ..
        " You know how to walk in darkness, and can befriend vermin and other wretched things .\n" ..
        "\n" ..
        "-10 Personality and Speechcraft\n" ..
        "+10 pt Blind when outdoors at daytime\n" ..
        "> You start with a Chameleon power\n" ..
        "> You start with a Calm Creature power"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfAttrs.personality(self).base = selfAttrs.personality(self).base - 10
        selfSkills.speechcraft(self).base = selfSkills.speechcraft(self).base - 10

        selfSpells:add("lack_gg_CalmCreature")
        selfSpells:add("lack_gg_ChameleonPower")
    end,
    onLoad = function()
        local selfSpells = self.type.spells(self)
        time.runRepeatedly(
            function()
                local night = isNight()
                local inside = self.cell and not (self.cell.isExterior or self.cell.isQuasiExterior)
                if (night or inside) and selfSpells["lack_gg_Dayblind"] then
                    selfSpells:remove("lack_gg_Dayblind")
                    self:sendEvent("ShowMessage", { message = "The darkness feels less oppressive..." })
                elseif not (night or inside) and not selfSpells["lack_gg_Dayblind"] then
                    selfSpells:add("lack_gg_Dayblind")
                    self:sendEvent("ShowMessage", { message = "The daylight blinds you..." })
                end
            end,
            period
        )
    end
}
