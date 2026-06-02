---@omw-context player
local I = require("openmw.interfaces")

local U = require("scripts.BoonsAndBurdens.utils.utils")
local deps = require("scripts.BoonsAndBurdens.utils.dependencies")

deps.checkAll("Boons and Burdens", {
    {
        plugin = "CharacterTraitsFramework.omwscripts",
        ---@diagnostic disable-next-line: undefined-field
        interface = I.CharacterTraits,
    },
    {
        plugin = "FollowerDetectionUtil.omwscripts",
        interface = true,
    }
})

local folderPath = "scripts/BoonsAndBurdens/backgrounds_player_merged/"

return U.mergeAllHandlers(folderPath)
