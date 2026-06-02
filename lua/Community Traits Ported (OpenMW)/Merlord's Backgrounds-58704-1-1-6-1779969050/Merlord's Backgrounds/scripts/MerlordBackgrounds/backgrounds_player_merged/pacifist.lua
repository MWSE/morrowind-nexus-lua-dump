local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background

I.CharacterTraits.addTrait {
    id = "pacifist",
    type = traitType,
    name = "Pacifist",
    description = (
        "You have dedicated your life to the pursuit of peace.\n" ..
        "\n" ..
        "+10 to all non-combat skills\n" ..
        "-10 to all other skills"
    ),
    doOnce = function()
        local combatSkills = {
            "axe",
            "block",
            "bluntweapon",
            "conjuration",
            "destruction",
            "handtohand",
            "heavyarmor",
            "lightarmor",
            "longblade",
            "marksman",
            "mediumarmor",
            "shortblade",
            "spear",
        }
        local passiveSkills = {
            "acrobatics",
            "alchemy",
            "alteration",
            "armorer",
            "athletics",
            "enchant",
            "illusion",
            "mercantile",
            "mysticism",
            "restoration",
            "security",
            "sneak",
            "speechcraft",
            "unarmored",
        }

        for _, skillId in ipairs(combatSkills) do
            local skill = self.type.stats.skills[skillId](self)
            skill.base = skill.base - 10
        end
        for _, skillId in ipairs(passiveSkills) do
            local skill = self.type.stats.skills[skillId](self)
            skill.base = skill.base + 10
        end
    end,
}
