local I = require("openmw.interfaces")

local U = require("scripts.OblivionBackgrounds.utils.utils")
local deps = require("scripts.OblivionBackgrounds.utils.dependencies")

deps.checkAll("Oblivion Backgrounds", { {
    plugin = "CharacterTraitsFramework.omwscripts",
    interface = I.CharacterTraits,
} })

local folderPath = "scripts/OblivionBackgrounds/backgrounds_player_merged/"

return U.mergeAllHandlers(folderPath)
