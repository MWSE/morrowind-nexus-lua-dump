local I = require("openmw.interfaces")

local U = require("scripts.WretchedAndWeird.utils.utils")
local deps = require("scripts.WretchedAndWeird.utils.dependencies")

deps.checkAll("The Wretched and The Weird", { {
    plugin = "CharacterTraitsFramework.omwscripts",
    interface = I.CharacterTraits,
} })

local folderPath = "scripts/WretchedAndWeird/backgrounds_player_merged/"

return U.mergeAllHandlers(folderPath)
