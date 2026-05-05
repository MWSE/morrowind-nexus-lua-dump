---@diagnostic disable: missing-parameter
local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background
local raceCheckers = require("scripts.Frana5usBackgrounds.utils.raceGroups")

local period = 1

I.CharacterTraits.addTrait {
    id = "trinimacEchoes",
    type = traitType,
    name = "Echoes of Trinimac",
    description = (
        "From a young age echoes of the Ancestral Warrior God whispered to you, strengthening your convictions "..
        "and guarding your honor. You have denounced the skills of the dishonorable and intend to make your way as a noble warrior. "..
        "Though you know that should you falter on your path Trinimac will forsake you.\n" ..
        "\n" ..
        "Requirements: Orcs only.\n" ..
        "\n" ..
        "+10 Willpower\n" ..
        "+5 to all Weapon and Armor skills\n" ..
        "> Sneak, Security, and Illusion are set to 0\n" ..
        "> You start with a Bound Shield and Shield spell\n" ..
        "> You start with a small Fortify Attack ability\n" ..
        "> Both spell and ability are lost permanently on bounty of 40 or higher"
    ),
    checkDisabled = function()
        return not raceCheckers.isOrc(self)
    end,
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)

        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base + 10

        selfSkills.axe(self).base = selfSkills.axe(self).base + 5
        selfSkills.bluntweapon(self).base = selfSkills.bluntweapon(self).base + 5
        selfSkills.marksman(self).base = selfSkills.marksman(self).base + 5
        selfSkills.spear(self).base = selfSkills.spear(self).base + 5
        selfSkills.shortblade(self).base = selfSkills.shortblade(self).base + 5
        selfSkills.block(self).base = selfSkills.block(self).base + 5
        selfSkills.lightarmor(self).base = selfSkills.lightarmor(self).base + 5
        selfSkills.mediumarmor(self).base = selfSkills.mediumarmor(self).base + 5
        selfSkills.heavyarmor(self).base = selfSkills.heavyarmor(self).base + 5

        selfSkills.sneak(self).base = 0
        selfSkills.security(self).base = 0
        selfSkills.illusion(self).base = 0

        selfSpells:add("MB_shield_of_honor")
        selfSpells:add("MB_Tr_Favor")
    end,
    onLoad = function()
        local selfSpells = self.type.spells(self)
        local stopChecks
        stopChecks = time.runRepeatedly(
            function()
                if not selfSpells["MB_shield_of_honor"] then
                    stopChecks()
                    return
                end
                if self.type.getCrimeLevel(self) >= 40 then
                    selfSpells:remove("MB_shield_of_honor")
                    selfSpells:remove("MB_Tr_Favor")
                end
            end,
            period
        )
    end
}
