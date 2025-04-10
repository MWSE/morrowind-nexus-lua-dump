local vfs = require('openmw.vfs')

---@class Track
---@field path string Path to the audiofile
---@field pathLower string Path in lowercase
---@field length? integer Expected lenght of the track in seconds
local Track = {}

function Track.Create(path)
    if not path then
        error("path not specified", 2)
    end

    local track = {}
    track.length = -1

    track.exists = Track.exists
    track.setLength = Track.setLength
    track.setPath = Track.setPath

    track:setPath(path)

    return track
end

function Track.exists(self)
    return vfs.fileExists(self.path)
end

function Track.setLength(self, length)
    self.length = length
end

---comment
---@param self Track
---@param path string
function Track.setPath(self, path)
    self.path = path
    self.pathLower = string.lower(path)
end

Track.Decoder = {
    fromTable = function(dataTable)
        if not dataTable.path then
            error("path not specified")
        end

        local track = Track.Create(dataTable.path)

        if dataTable.length then
            track:setLength(dataTable.length)
        end

        return track
    end
}

return Track
