local Playlist = {}

function Playlist.Create(data)
    if not data.id then
        error("id not specified", 2)
    end

    if not data.tracks then
        error("tracks not specified", 2)
    end

    local playlist = {}

    playlist.id = data.id
    playlist.tracks = data.tracks

    playlist.trackForPath = Playlist.trackForPath

    return playlist
end

function Playlist.trackForPath(self, path)
    for _, track in pairs(self.tracks) do
        if track.path == path then
            return track
        end
    end
end

return Playlist
