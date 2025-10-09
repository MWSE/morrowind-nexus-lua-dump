---@type S3maphorePlaylistEnv
_ENV = _ENV

local async = require 'openmw.async'
local activePlaylistSettings = require 'openmw.storage'.playerSection('S3maphoreActivePlaylistSettings')

local defaultPlaylistStates, defaultPlaylistNames = {}, {
    'BattleActive',
    'ExploreActive'
}

for _, playlistName in ipairs(defaultPlaylistNames) do
    if activePlaylistSettings:get(playlistName) == nil then activePlaylistSettings:set(playlistName, true) end
end

local function updateDefaultPlaylistStates()
    for _, playlistName in ipairs(defaultPlaylistNames) do
        defaultPlaylistStates[playlistName] = activePlaylistSettings:get(playlistName)
    end
end

updateDefaultPlaylistStates()

activePlaylistSettings:subscribe(
    async:callback(
        updateDefaultPlaylistStates
    )
)

---@type S3maphorePlaylist[]
return {
    {
        id = "Explore",
        priority = PlaylistPriority.Explore,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat and defaultPlaylistStates.ExploreActive
        end,
    },
    {
        id = "Battle",
        priority = PlaylistPriority.BattleVanilla,
        randomize = true,

        isValidCallback = function()
            return Playback.state.isInCombat and defaultPlaylistStates.BattleActive
        end,
    },
    {
        id = 'Special',
        priority = PlaylistPriority.Special,
        playOneTrack = true,
        active = false,

        tracks = {},
    },
}
