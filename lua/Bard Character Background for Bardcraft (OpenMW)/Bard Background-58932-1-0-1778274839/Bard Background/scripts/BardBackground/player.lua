local I = require("openmw.interfaces")
local self = require("openmw.self")
local ui = require("openmw.ui")
local core = require("openmw.core")

local deps = require("scripts.BardBackground.dependencies")

deps.checkAll("Bard Background", { {
    plugin = "CharacterTraitsFramework.omwscripts", 
    plugin = "Bardcraft.omwscripts",
    interface = I.CharacterTraits,
} })

I.CharacterTraits.addTrait {
    id = "bard",
    type = "background",
    name = "Bard College Graduate",
    description = (
        "You have freshly graduated from the College of Bards and are ready to take on the larger world of performance. " ..
        "On your person you have your trusty instrument and a song book with your favourite piece.\n" ..
        "\n" ..
        "+20 to Bardcraft skill\n" ..
        "+10 to Personality\n" ..
        "You start with an instrument and a song book."
    ),

    doOnce = function()
        core.sendGlobalEvent("CharacterTraits_selectedBardBackground", self)
        local personality = self.type.stats.attributes.personality(self)
        personality.base = personality.base + 10
        local bardcraft = I.SkillFramework.getSkillStat("bardcraft")
        bardcraft.base = bardcraft.base + 20
        local opt = {
            showInDialogue=false
        }
        ui.showMessage("Show the soul of your song to the world!", opt)
    end
}