local vfs = require('openmw.vfs')
local Music = require('openmw.interfaces').Music

local Settings = require('scripts.DynamicMusic.core.Settings')

local SoundBank = {}

local function buildPlaylist(id, tracks)
    local playlistTracks = {}

    for _, track in pairs(tracks) do
        table.insert(playlistTracks, track.path)
    end

    local playlist = {
        id = id,
        priority = Settings.getValue(Settings.KEYS.GENERAL_PLAYLIST_PRIORITY),
        tracks = playlistTracks
    }

    return playlist
end

function SoundBank.CreateFromTable(data)
    local soundBank = data
    soundBank.countAvailableTracks = SoundBank.countAvailableTracks

    if soundBank.tracks then
        for _, t in ipairs(soundBank.tracks) do
            t.path = string.lower(t.path)
        end
    end

    if soundBank.combatTracks then
        for _, t in ipairs(soundBank.combatTracks) do
            t.path = string.lower(t.path)
        end
    end

    if soundBank.tracks and #soundBank.tracks > 0 then
        local explorePlaylist = buildPlaylist(soundBank.id .. "_explore", soundBank.tracks)
        soundBank.explorePlaylist = explorePlaylist
        Music.registerPlaylist(explorePlaylist)
    end

    if soundBank.combatTracks and #soundBank.combatTracks > 0 then
        local combatPlaylist = buildPlaylist(soundBank.id .. "_combat", soundBank.combatTracks)
        soundBank.combatPlaylist = combatPlaylist
        Music.registerPlaylist(combatPlaylist)
    end

    return soundBank
end

local function _countTracks(tracks)
    local availableTracks = 0

    if tracks then
        for _, track in ipairs(tracks) do
            if type(track) == "table" then
                track = track.path
            end

            if vfs.fileExists(track) then
                availableTracks = availableTracks + 1
            end
        end
    end

    return availableTracks
end

function SoundBank.countAvailableTracks(self)
    local availableTracks = 0

    availableTracks = availableTracks + _countTracks(self.tracks)
    availableTracks = availableTracks + _countTracks(self.combatTracks)

    return availableTracks
end

return SoundBank
