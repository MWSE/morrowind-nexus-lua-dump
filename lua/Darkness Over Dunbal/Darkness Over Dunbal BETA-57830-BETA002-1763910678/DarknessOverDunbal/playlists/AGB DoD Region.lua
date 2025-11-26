---@type S3maphorePlaylistEnv
_ENV = _ENV

---@type S3maphorePlaylist[]
return {
    {
        id = 'ms/region/AGB_Dunbal',
        priority = PlaylistPriority.Region,
        randomize = true,

        isValidCallback = function()
            return not Playback.state.isInCombat
                and Playback.state.cellIsExterior
                and Playback.state.nearestRegion == 'agb dunbal region'
        end,
    },
}
