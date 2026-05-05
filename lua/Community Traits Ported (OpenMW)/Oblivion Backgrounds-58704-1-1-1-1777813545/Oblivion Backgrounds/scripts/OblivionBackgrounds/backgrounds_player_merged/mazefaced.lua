local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.OblivionBackgrounds.utils.traitTypes").background

local bgPicked = false

I.CharacterTraits.addTrait {
    id = "mazefaced",
    type = traitType,
    name = "Maze-Faced",
    description = (
        "You escaped the Labyrinth of Attribution's Share, Boethiah's domain. " ..
        "Your trials have hardened your resolve and skill in combat, " ..
        "but your scars are clearly worn. " ..
        "You no longer trust others in the pursuit of your own strength, " ..
        "and understand the gifts of deception.\n" ..
        "\n" ..
        "+5 Attack, Strength, and Endurance\n" ..
        "-10 Personality\n" ..
        "-5 Willpower\n" ..
        "> You start with a Chameleon and Sanctuary power\n" ..
        "> Training from NPCs is permanently disabled"
    ),
    doOnce = function()
        local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        local selfSpells = self.type.spells(self)
        
        selfAttrs.strength(self).base = selfAttrs.strength(self).base + 5
        selfAttrs.endurance(self).base = selfAttrs.endurance(self).base + 5

        selfAttrs.personality(self).base = selfAttrs.personality(self).base - 10
        selfAttrs.willpower(self).base = selfAttrs.willpower(self).base - 5

        selfSpells:add("lack_gg_boethianire")
        selfSpells:add("lack_gg_ebonShroud")
    end,
    onLoad = function()
        bgPicked = true
    end
}

local function blockTraining(data)
    if not (bgPicked and data.newMode == "Training") then return end
    I.UI.setMode(data.oldMode, data.arg)
end

return {
    eventHandlers = {
        UiModeChanged = blockTraining
    }
}
