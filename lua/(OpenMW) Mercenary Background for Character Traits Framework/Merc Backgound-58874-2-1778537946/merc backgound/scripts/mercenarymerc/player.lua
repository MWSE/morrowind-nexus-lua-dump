local I = require("openmw.interfaces")

local U = require("scripts.mercenarymerc.utils.utils")
local deps = require("scripts.mercenarymerc.utils.dependencies")

deps.checkAll("Merc Background", { {
    plugin = "CharacterTraitsFramework.omwscripts",
    interface = I.CharacterTraits,
} })

local folderPath = "scripts/mercenarymerc/backgrounds_player_merged/"

return U.mergeAllHandlers(folderPath)
