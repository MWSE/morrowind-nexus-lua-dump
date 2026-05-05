local I = require("openmw.interfaces")

local U = require("scripts.Frana5usBackgrounds.utils.utils")
local deps = require("scripts.Frana5usBackgrounds.utils.dependencies")

deps.checkAll("Frana5u's Backgrounds", { {
    plugin = "CharacterTraitsFramework.omwscripts",
    interface = I.CharacterTraits,
} })

local folderPath = "scripts/Frana5usBackgrounds/backgrounds_player_merged/"

return U.mergeAllHandlers(folderPath)
