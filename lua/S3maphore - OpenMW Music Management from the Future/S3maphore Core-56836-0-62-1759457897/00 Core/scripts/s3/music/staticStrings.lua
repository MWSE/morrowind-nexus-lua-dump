--- Log strings utilized across S3maphore.
--- These are not localized because I only speak English.
---@class S3maphoreStaticStrings
local Strings = {
    CantAutoAssignInterruptModeStr =
    'Invalid Playlist Priority: %s for playlist: %s, cannot automatically assign interrupt mode!',
    ChangingPlaylist = 'Setting playlist %s to %s',
    CombatTargetCacheStr = '%s%s',
    FailedToLoadPlaylist = 'Failed to load playlist file: %s\nErr: %s',
    FallbackPlaylistDoesntExist =
    'Playlist %s requested to use tracks from backup playlist %s, but it isn\'t registered! Falling back to the default.',
    InitializationFinished = "[ S3MAPHORE ]: %d playlists loaded. Ready to play music!",
    InterruptModeFallthrough =
    'Playlist Interrupt Modes Fell Through!\nOld Playlist: %s Interrupt Mode: %s\nNew Playlist: %s InterruptMode: %s',
    InterruptModeNotProvided =
    'Interrupt mode was not provided when constructing the silenceManager!',
    InvalidLevelDifferenceRule =
    'Table %s for combatTargetLevelDifference rule does not contain either the relative OR absolute fields! You broke it!',
    InvalidPlaylistFields = "Can not register playlist: 'id' and 'priority' are mandatory fields",
    LogFormatStr = '[ S3MAPHORE ]: %s',
    MusicStopped = 'Music stopped: %s',
    NextTrackIndexNil = 'Can not fetch track: nextTrackIndex is nil',
    NoTrackPath = 'Can not fetch track with index %s from playlist \'%s\'.',
    PlaylistNotRegistered = 'Playlist %s has not been registered!',
    PlaylistSkipFormatStr = [[Track Skip:
        Did Change Playlist: %s
        Transitioned from interior to exterior: %s
        Force transition for friendly cell: %s
        Force Transition for hostile cell: %s
        Force Overworld Transition: %s
        Cell is hostile: %s]],
    TrackChanged = 'Track changed! Current playlist is: %s Track: %s',
    WeatherChanged = 'Weather changed to %s',
}

return Strings
