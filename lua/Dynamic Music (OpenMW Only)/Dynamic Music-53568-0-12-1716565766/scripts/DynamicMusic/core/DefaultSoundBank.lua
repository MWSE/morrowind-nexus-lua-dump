local SoundBank = require('scripts.DynamicMusic.core.SoundBank')
local vfs = require('openmw.vfs')

local data = {}

data.id = "DYNAMIC_MUSIC_DEFAULT_SOUNDBANK"
data.tracks = {}
data.combatTracks = {}

for file in vfs.pathsWithPrefix("music/explore") do
    table.insert(data.tracks, { path = file })
end

for file in vfs.pathsWithPrefix("music/battle") do
    table.insert(data.combatTracks, { path = file })
end

return SoundBank.CreateFromTable(data)
