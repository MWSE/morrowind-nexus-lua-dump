local I = require("openmw.interfaces")
local self = require("openmw.self")

local traitType = require("scripts.WretchedAndWeird.utils.traitTypes").background

local bgPicked = false

I.CharacterTraits.addTrait {
    id = "autodidact",
    type = traitType,
    name = "Autodidact",
    description = (
        "You are entirely self-taught. Your independent way of thinking has sharpened your mind, " ..
        "but you find it nearly impossible to learn from others.\n" ..
        "\n" ..
        "+10 Intelligence\n" ..
        "> Training from NPCs is permanently disabled"
    ),
    doOnce = function()
        -- local selfSkills = self.type.stats.skills
        local selfAttrs = self.type.stats.attributes
        -- local selfSpells = self.type.spells(self)

        selfAttrs.intelligence(self).base = selfAttrs.intelligence(self).base + 10
    end,
    onLoad = function()
        bgPicked = true
    end
}

local function uiModeChanged(data)
    if not (bgPicked and data.newMode == "Training") then return end
    I.UI.setMode(data.oldMode, data.arg)
end

return {
    eventHandlers = {
        UiModeChanged = uiModeChanged
    }
}
