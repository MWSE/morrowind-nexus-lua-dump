local ambient = require('openmw.ambient')
local GameState = require('scripts.DynamicMusic.core.GameState')
local Property = require('scripts.DynamicMusic.core.Property')

local MusicPlayer = {}

local playlistProperty = Property.Create()
local trackProperty = Property.Create()

local playbackTimeProperty = {
    current = -1,
    previous = -1
}

local availableTracks = {}

function MusicPlayer.playPlaylist(playlist, options)
    local force = options and options.force

    if not force and playlistProperty:getValue() == playlist then
        error("playlist already playing",2)
    end

    playlistProperty:setValue(playlist)
    MusicPlayer._fillTracks()

    -- if the new playlists contains a track with the same path as the track currently playing then playback continues
    local currentTrack = trackProperty:getValue()
    if currentTrack then
        local currentTrackLength = currentTrack.length
        local sametrack = playlist:trackForPath(currentTrack.path)
        if not force and sametrack and playbackTimeProperty.current < currentTrackLength then
            trackProperty:setValue(sametrack)
            return
        end
    end

    MusicPlayer._playNewTrack()
end

function MusicPlayer._fillTracks()
    if not playlistProperty:getValue() then
        error("no playlist available", 2)
    end

    if not playlistProperty:getValue().tracks then
        error("playlist has no tracks", 2)
    end

    availableTracks = {}
    for _, t in pairs(playlistProperty:getValue().tracks) do
        table.insert(availableTracks, t)
    end
end

function MusicPlayer._removeAvailableTrack(track)
    local index = 0
    for _, t in pairs(availableTracks) do
        index = index +1
        if t == track then
            table.remove(availableTracks, index)
            return
        end
    end
end

function MusicPlayer._playNewTrack()
    if #availableTracks == 0 then
        MusicPlayer._fillTracks()
    end

    local track = MusicPlayer._fetchRandomTrack()

    if track then
        trackProperty:setValue(track)
        print("playing track: " ..track.path)
        ambient.streamMusic(track.path)
        playbackTimeProperty.current = 0
        MusicPlayer._removeAvailableTrack(track)
    end
end

function MusicPlayer._fetchRandomTrack()
    if not availableTracks then
        return
    end

    local random = math.random(1, #availableTracks)
    return availableTracks[random]
end

function MusicPlayer.update(deltaTime)
    if trackProperty:getValue() then
        if playbackTimeProperty.current > -1 then
            playbackTimeProperty.current = playbackTimeProperty.current +
                (GameState.playtime.current - GameState.playtime.previous)
        end

        if not ambient.isMusicPlaying() then
            print("no music playing: play new track from playlist")
            MusicPlayer._playNewTrack()
            return
        end

        if trackProperty:getValue().length then
            if playbackTimeProperty.current > -1 and playbackTimeProperty.current >= trackProperty:getValue().length then
                MusicPlayer._playNewTrack()
                return
            end
        end
    end
end

return MusicPlayer
