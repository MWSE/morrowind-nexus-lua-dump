--[[

    The Ronin for Merlord's Character Backgrounds.
    A MWSE-lua mod for Morrowind

    Note: This mod requires "Merlord's Character Backgrounds."
           https://www.nexusmods.com/morrowind/mods/46795


    @version      v1.0
    @author       VvardenfellStormSage
    @last-update  Nov x, 2023

]]

local items = {
    { id = "vss_samblade", count = 1 },
    { id = "vss_CHN_ROBE4d", count = 1 },
    { id = "vss_GetaShoes", count = 1 },
    { id = "AB_a_WickerHelm02", count = 1 },
}

local skills = {
    { id = tes3.skill.sneak, value = 5 },
    { id = tes3.skill.longBlade, value = 10 },
    { id = tes3.skill.speechcraft, value = -10 }
}

local attributes = {
    { id = tes3.attribute.agility, value = 5 },
    { id = tes3.attribute.personality, value = -5 }
}

-- start the mod
local function onInit(e)
    local interop = require("mer.characterBackgrounds.interop")
    local theRoninBackground = {
        id = "theRonin",
        name = "The Ronin",
        description = (
                      "Orphaned and taken as a slave in a bandit raid, you learned early on to move silently " ..
                      "to avoid beatings (+5 Stealth, +5 Agility), and rarely spoke to your captors (-10 Speechcraft, " ..
                      "-5 personality). As you grew older, you were forced to take part in the gang's nefarious acts, " ..
                      "learning the way of the blade (+10 Long Blade). Eventually, you were able to slay the bandit leader " ..
                      "and claim his prize possession - a blessed sword pilfered from a forgotten temple. Since then, you " ..
                      "have wandered Tamriel, using that thrice-blessed blade to atone for the acts you were forced to commit " ..
                      "while in servitude to the bandits. "
        ),
        doOnce = function()
            for _, item in ipairs(items) do
                tes3.addItem({
                    reference = tes3.player,
                    item = item.id,
                    count = item.count
                })
            end
            for _, skill in ipairs(skills) do
                tes3.modStatistic({
                    reference = tes3.player,
                    skill = skill.id,
                    value = skill.value
                })
            end
            for _, attribute in ipairs(attributes) do
                tes3.modStatistic({
                    reference = tes3.player,
                    attribute = attribute.id,
                    value = attribute.value
                })
            end
        end
    }
    interop.addBackground(theRoninBackground)
end

event.register("initialized", onInit)
