local I = require("openmw.interfaces")

local U = require("scripts.MerlordBackgrounds.utils.utils")
local deps = require("scripts.MerlordBackgrounds.utils.dependencies")

deps.checkAll("Merlord's Backgrounds", { {
    plugin = "CharacterTraitsFramework.omwscripts",
    interface = I.CharacterTraits,
} })

local folderPath = "scripts/MerlordBackgrounds/backgrounds_player_merged/"

return U.mergeAllHandlers(folderPath)
