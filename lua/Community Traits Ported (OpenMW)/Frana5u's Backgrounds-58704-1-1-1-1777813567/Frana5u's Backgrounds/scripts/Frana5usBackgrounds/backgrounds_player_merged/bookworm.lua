local I = require("openmw.interfaces")
local self = require("openmw.self")
local storage = require("openmw.storage")

local traitType = require("scripts.Frana5usBackgrounds.utils.traitTypes").background

local buffType = I.ReadingIsGood
    and "> You get 2% more skill gain from reading skill books"
    or "> You get double skills from skill books"
local recursionAlarm = false

I.CharacterTraits.addTrait {
    id = "bookworm",
    type = traitType,
    name = "Bookworm",
    description = (
        "You have spent your life inside with your nose in a book. This made you physically weak, but lets you learn better " ..
        "from books.\n" ..
        "\n" ..
        "-10 Strength and Endurance\n" ..
        buffType
    ),
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)

        selfAttrs.strength(self).base = selfAttrs.strength(self).base - 10
        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base - 10
    end,
    onLoad = function()
        I.SkillProgression.addSkillLevelUpHandler(
            function(skillid, source, options)
                if source ~= "book" or recursionAlarm then
                    recursionAlarm = false
                    return
                end

                if I.ReadingIsGood then
                    local settings = storage.playerSection("SettingsReadingIsGood")
                    local bookBoost = settings:get("BOOK_BOOST")
                    I.ReadingIsGood.modExpMult(skillid, bookBoost / 2)
                else
                    recursionAlarm = true
                    I.SkillProgression.skillLevelUp(skillid, "book")
                end
            end
        )
    end
}
