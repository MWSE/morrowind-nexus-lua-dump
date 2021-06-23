local common = require("mer.bardicInspiration.common")
local Song = require("mer.bardicInspiration.Song")
local songList = require("mer.bardicInspiration.data.songList")

local this = {}

--[[
    Params:
    name:
        Name of the song
    path:
        path to sound file, relative to Data Files/Music
    buffId (optional):
        id of ability added when travel playing.
        Default: "mer_bard_inspiration"
    difficulty (optional):
        How hard the song is to play
        options: 'beginner', 'intermediate', 'advanced'
]]
function this.addSong(data)
    assert(data.name, "No song name provided")
    assert(data.path, "No path to sound file provided")
    data.difficulty = data.difficulty or 'beginner'
    assert(common.staticData.difficulties[data.difficulty], "Invalid difficulty provided")
    table.insert(songList[data.difficulty], Song:new(data))
end

return this