local core = require('openmw.core')
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')
local menu = require('openmw.menu')

local MIDI = require('scripts.Bardcraft.util.midi')
local Song = require('scripts.Bardcraft.util.song').Song

local function parseAllCustom()
    local bardData = storage.playerSection('Bardcraft')
    local storedSongs = bardData:getCopy('songs/drafts') or {}

    local midiSongs = {}
    for filePath in vfs.pathsWithPrefix(MIDI.MidiParser.customFolder) do
        if filePath:sub(-4) == ".mid" then
            local fileName = string.match(filePath, "([^/]+)$")

            local alreadyParsed = false
            for _, song in pairs(storedSongs) do
                if song.sourceFile == fileName then
                    alreadyParsed = true
                    break
                end
            end

            if not alreadyParsed then
                local parser = MIDI.ParseMidiFile(filePath)
                if parser then
                    local song = Song.fromMidiParser(parser)
                    midiSongs[fileName] = song
                end
            end
        end
    end

    for _, song in pairs(midiSongs) do
        table.insert(storedSongs, song)
    end

    bardData:set('songs/drafts', storedSongs)
end

return {
    engineHandlers = {
        onStateChanged = function() 
            if menu.getState() == menu.STATE.Running then
                core.sendGlobalEvent('BC_ParseMidis')
                parseAllCustom()
                core.sendGlobalEvent('BC_SetCreationTime')
            end
        end,
    }
}