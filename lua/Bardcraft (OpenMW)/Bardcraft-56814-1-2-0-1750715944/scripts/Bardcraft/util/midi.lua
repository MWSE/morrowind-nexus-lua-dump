-- Simple MIDI file parser
-- Supporting note on/off events, instrument changes, and pitch information

local vfs = require('openmw.vfs')

-- Basic bit operations since Lua 5.1 doesn't have them built-in
local bit = {}

function bit.lshift(x, by)
    return x * 2 ^ by
end

function bit.rshift(x, by)
    return math.floor(x / 2 ^ by)
end

function bit.band(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

function bit.bor(a, b)
    local result = 0
    local bitval = 1
    while a > 0 or b > 0 do
        if a % 2 == 1 or b % 2 == 1 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

-- MIDI Parser class
local MidiParser = {}
MidiParser.__index = MidiParser

MidiParser.sampleFolder = 'sound\\Bardcraft\\samples\\'
MidiParser.presetFolder = 'midi\\Bardcraft\\preset\\'
MidiParser.customFolder = 'midi\\Bardcraft\\custom\\'

function MidiParser.new(filename)
    local self = setmetatable({}, MidiParser)
    self.filename = filename
    self.tracks = {}
    self.format = 0
    self.numTracks = 0
    self.division = 0
    self.events = {}
    self.tempoEvents = {}
    self.timeSignatureEvents = {}
    self.instruments = {}
    return self
end

-- Read variable-length quantity from a string buffer
function MidiParser:readVLQ(content, cursor, contentLength)
    local value = 0
    if cursor > contentLength then return nil, cursor, "EOF before reading VLQ byte" end
    local byte = content:byte(cursor)
    cursor = cursor + 1
    value = bit.band(byte, 0x7F)

    while bit.band(byte, 0x80) ~= 0 do
        if cursor > contentLength then return nil, cursor, "EOF in VLQ continuation byte" end
        byte = content:byte(cursor)
        cursor = cursor + 1
        value = bit.lshift(value, 7)
        value = bit.bor(value, bit.band(byte, 0x7F))
    end

    return value, cursor
end

-- Read a specific number of bytes from string buffer and return as number
function MidiParser:readBytes(content, cursor, count, contentLength)
    if cursor + count - 1 > contentLength then
        return nil, cursor, "EOF trying to read " .. count .. " bytes"
    end

    local value = 0
    for i = 1, count do
        value = bit.lshift(value, 8)
        value = value + content:byte(cursor)
        cursor = cursor + 1
    end
    return value, cursor
end

-- Parse a MIDI file
function MidiParser:parse()
    if not vfs.fileExists(self.filename) then
        return false, "File does not exist: " .. self.filename
    end

    local file = vfs.open(self.filename)
    if not file then
        return false, "Could not open file: " .. self.filename
    end

    local content = file:read("*a") -- Read entire file content
    file:close()

    local contentLength = #content
    local cursor = 1
    local errMsg

    -- Read header chunk
    if cursor + 3 > contentLength then return false, "Unexpected EOF reading header chunk ID" end
    local headerChunk = content:sub(cursor, cursor + 3)
    cursor = cursor + 4
    if headerChunk ~= "MThd" then
        return false, "Not a valid MIDI file (header not found)"
    end

    -- Read header length
    local headerLength
    headerLength, cursor, errMsg = self:readBytes(content, cursor, 4, contentLength)
    if errMsg then return false, "Error reading header length: " .. errMsg end
    if headerLength ~= 6 then
        return false, "Invalid header length"
    end

    -- Read format type
    self.format, cursor, errMsg = self:readBytes(content, cursor, 2, contentLength)
    if errMsg then return false, "Error reading format type: " .. errMsg end

    -- Read number of tracks
    self.numTracks, cursor, errMsg = self:readBytes(content, cursor, 2, contentLength)
    if errMsg then return false, "Error reading number of tracks: " .. errMsg end

    -- Read time division
    self.division, cursor, errMsg = self:readBytes(content, cursor, 2, contentLength)
    if errMsg then return false, "Error reading time division: " .. errMsg end

    -- Process each track
    for trackNum = 1, self.numTracks do
        local track = { events = {} }

        -- Check for track header
        if cursor + 3 > contentLength then return false, "Unexpected EOF reading track header ID for track " .. trackNum end
        local trackHeader = content:sub(cursor, cursor + 3)
        cursor = cursor + 4
        if trackHeader ~= "MTrk" then
            return false, "Invalid track header in track " .. trackNum
        end

        -- Read track length
        local trackLength
        trackLength, cursor, errMsg = self:readBytes(content, cursor, 4, contentLength)
        if errMsg then return false, "Error reading track length for track " .. trackNum .. ": " .. errMsg end
        
        local trackDataStartCursor = cursor
        local trackEndLimit = trackDataStartCursor + trackLength

        local absoluteTime = 0
        local runningStatus = 0

        while cursor < trackEndLimit and cursor <= contentLength do
            local event = {}

            local deltaTime
            deltaTime, cursor, errMsg = self:readVLQ(content, cursor, contentLength)
            if errMsg then return false, "Error reading delta time in track " .. trackNum .. " at cursor " .. (cursor -1) .. ": " .. errMsg end
            absoluteTime = absoluteTime + deltaTime
            event.time = absoluteTime

            if cursor > contentLength then return false, "Unexpected EOF reading status byte in track " .. trackNum end
            local statusByte = content:byte(cursor)
            
            if statusByte < 0x80 then -- Running status
                if runningStatus == 0 then return false, "Invalid running status (0) with data byte in track " .. trackNum end
                -- Data byte, not status byte. Do not advance cursor for status byte.
                statusByte = runningStatus
            else -- New status byte
                cursor = cursor + 1 -- Advance cursor as we consumed the status byte
                runningStatus = statusByte
            end

            local eventType = bit.rshift(statusByte, 4)
            local channel = bit.band(statusByte, 0x0F)
            event.channel = channel

            if eventType == 0x8 then -- Note Off
                event.type = "noteOff"
                if cursor + 1 > contentLength then return false, "Unexpected EOF for Note Off data in track " .. trackNum end
                event.note = content:byte(cursor)
                event.velocity = content:byte(cursor + 1)
                cursor = cursor + 2
                table.insert(track.events, event)
            elseif eventType == 0x9 then -- Note On
                event.type = "noteOn"
                if cursor + 1 > contentLength then return false, "Unexpected EOF for Note On data in track " .. trackNum end
                event.note = content:byte(cursor)
                event.velocity = content:byte(cursor + 1)
                cursor = cursor + 2
                if event.velocity == 0 then event.type = "noteOff" end
                table.insert(track.events, event)
            elseif eventType == 0xC then -- Program Change
                event.type = "programChange"
                if cursor > contentLength then return false, "Unexpected EOF for Program Change data in track " .. trackNum end
                event.program = content:byte(cursor)
                cursor = cursor + 1
                table.insert(track.events, event)
                if not self.instruments[channel] then
                    self.instruments[channel] = event.program
                end
            elseif eventType == 0xF then -- Meta Event or System Exclusive
                if statusByte == 0xFF then -- Meta Event
                    if cursor > contentLength then return false, "Unexpected EOF for Meta Event type in track " .. trackNum end
                    local metaType = content:byte(cursor)
                    cursor = cursor + 1
                    
                    local metaLength
                    metaLength, cursor, errMsg = self:readVLQ(content, cursor, contentLength)
                    if errMsg then return false, "Error reading Meta Event length in track " .. trackNum .. ": " .. errMsg end

                    local metaDataStartCursor = cursor
                    if metaType == 0x2F then -- End of Track
                        cursor = metaDataStartCursor + metaLength -- Skip data
                        if cursor > contentLength + 1 then cursor = contentLength + 1 end
                        break -- End processing for this track
                    elseif metaType == 0x51 then -- Tempo Change
                        if metaLength == 3 then
                            if metaDataStartCursor + 2 > contentLength then return false, "Unexpected EOF for Tempo data in track " .. trackNum end
                            local tempoByte1 = content:byte(metaDataStartCursor)
                            local tempoByte2 = content:byte(metaDataStartCursor + 1)
                            local tempoByte3 = content:byte(metaDataStartCursor + 2)
                            local microsecondsPerQuarter = (tempoByte1 * 65536) + (tempoByte2 * 256) + tempoByte3
                            local bpm = 60000000 / microsecondsPerQuarter
                            bpm = math.floor(bpm * 1000 + 0.5) / 1000
                            table.insert(self.tempoEvents, {type = "setTempo", time = absoluteTime, track = trackNum, microsecondsPerQuarter = microsecondsPerQuarter, bpm = bpm})
                        end
                        cursor = metaDataStartCursor + metaLength
                    elseif metaType == 0x58 then -- Time Signature
                        if metaLength == 4 then
                            if metaDataStartCursor + 3 > contentLength then return false, "Unexpected EOF for Time Signature data in track " .. trackNum end
                            local numerator = content:byte(metaDataStartCursor)
                            local denominatorPower = content:byte(metaDataStartCursor + 1)
                            local clocksPerClick = content:byte(metaDataStartCursor + 2)
                            local thirtySecondNotesPerQuarter = content:byte(metaDataStartCursor + 3)
                            table.insert(self.timeSignatureEvents, {type = "timeSignature", time = absoluteTime, track = trackNum, numerator = numerator, denominator = 2 ^ denominatorPower, clocksPerClick = clocksPerClick, thirtySecondNotesPerQuarter = thirtySecondNotesPerQuarter})
                        end
                        cursor = metaDataStartCursor + metaLength
                    else -- Other meta events
                        cursor = metaDataStartCursor + metaLength
                    end
                    if cursor > contentLength + 1 then cursor = contentLength + 1 end
                elseif statusByte == 0xF0 or statusByte == 0xF7 then -- SysEx Event
                    local length
                    length, cursor, errMsg = self:readVLQ(content, cursor, contentLength) -- cursor is after status byte (0xF0/0xF7)
                    if errMsg then return false, "Error reading SysEx length in track " .. trackNum .. ": " .. errMsg end
                    cursor = cursor + length
                    if cursor > contentLength + 1 then cursor = contentLength + 1 end
                else
                    -- Don't handle 0xFx System Common/Real-Time messages (e.g., 0xF1, 0xF2, 0xF3, 0xF6, 0xF8-0xFE)
                end
            else -- Other event types (0xA, 0xB, 0xD, 0xE)
                if cursor + 1 > contentLength then return false, "Unexpected EOF for 2-byte skip event (type " .. string.format("%X", eventType) .. ") in track " .. trackNum end
                cursor = cursor + 2
            end
            -- Ensure cursor does not run away if track data is malformed
            if cursor > trackEndLimit then cursor = trackEndLimit end
            if cursor > contentLength + 1 then cursor = contentLength + 1 end
        end -- while events in track

        -- After processing events, or if EoT was hit, cursor might not be at trackEndLimit.
        -- The original parser would continue from wherever the file pointer was left.
        -- To ensure we start the next track chunk correctly, or finish parsing if this was the last track,
        -- we should advance the cursor to the end of the current track's declared length,
        -- but only if we haven't already passed it or the end of the file.
        if cursor < trackEndLimit and trackEndLimit <= contentLength +1 then
            cursor = trackEndLimit
        end
        -- Final safety clamp for cursor
        if cursor > contentLength + 1 then cursor = contentLength + 1 end

        table.insert(self.tracks, track)
    end -- for each track

    table.sort(self.tempoEvents, function(a, b) return a.time < b.time end)
    table.sort(self.timeSignatureEvents, function(a, b) return a.time < b.time end)

    return true
end

-- Get all notes from the MIDI file
function MidiParser:getNotes()
    local notes = {}

    for trackNum, track in ipairs(self.tracks) do
        for _, event in ipairs(track.events) do
            if event.type == "noteOn" or event.type == "noteOff" then
                table.insert(notes, {
                    type = event.type,
                    time = event.time,
                    track = trackNum,
                    channel = event.channel,
                    note = event.note,
                    velocity = event.velocity
                })
            end
        end
    end

    -- Sort notes by time
    table.sort(notes, function(a, b)
        if a.time == b.time then
            return (a.type == "noteOff" and b.type == "noteOn")
        end
        return a.time < b.time
    end)

    return notes
end

-- Get all program changes (instrument changes)
function MidiParser:getInstruments()
    local instruments = {}

    for trackNum, track in ipairs(self.tracks) do
        for _, event in ipairs(track.events) do
            if event.type == "programChange" then
                table.insert(instruments, {
                    time = event.time,
                    track = trackNum,
                    channel = event.channel,
                    program = event.program
                })
            end
        end
    end

    -- Sort instrument changes by time
    table.sort(instruments, function(a, b) return a.time < b.time end)

    return instruments
end

-- Get tempo information
function MidiParser:getTempoEvents()
    return self.tempoEvents
end

-- Get time signature information
function MidiParser:getTimeSignatureEvents()
    return self.timeSignatureEvents
end

-- Get the initial tempo (or default 120 BPM if none specified)
function MidiParser:getInitialTempo()
    if #self.tempoEvents > 0 then
        return self.tempoEvents[1].bpm
    else
        return 120 -- Default standard MIDI tempo is 120 BPM
    end
end

-- Get the initial time signature (or default 4/4 if none specified)
function MidiParser:getInitialTimeSignature()
    if #self.timeSignatureEvents > 0 then
        return self.timeSignatureEvents[1].numerator, self.timeSignatureEvents[1].denominator
    else
        return 4, 4 -- Default time signature is 4/4
    end
end

function MidiParser:printEverything()
    print("MIDI Format: " .. self.format)
    print("Number of tracks: " .. self.numTracks)
    print("Time division: " .. self.division .. " ticks per quarter note")

    -- Display time signature information
    local timeSignatureNum, timeSignatureDenom = self:getInitialTimeSignature()
    print(string.format("\nInitial Time Signature: %d/%d", timeSignatureNum, timeSignatureDenom))

    local timeSignatures = self:getTimeSignatureEvents()
    if #timeSignatures > 0 then
        print("\nTime Signature Events:")
        for i, ts in ipairs(timeSignatures) do
            print(string.format("Time: %d ticks, Time Signature: %d/%d",
                ts.time, ts.numerator, ts.denominator))
        end
    end

    -- Display tempo information
    local tempoEvents = self:getTempoEvents()
    if #tempoEvents > 0 then
        print("\nTempo Events:")
        for i, tempo in ipairs(tempoEvents) do
            print(string.format("Time: %d ticks, BPM: %.2f", tempo.time, tempo.bpm))
        end
        print("Initial Tempo: " .. self:getInitialTempo() .. " BPM")
    else
        print("\nNo tempo events found. Using default 120 BPM.")
    end

    print("\nInstrument Changes:")
    local instruments = self:getInstruments()
    for _, instrument in ipairs(instruments) do
        print(string.format("Time: %d, Track: %d, Channel: %d, Program: %d",
            instrument.time, instrument.track, instrument.channel, instrument.program))
    end
end

-- Usage example
function ParseMidiFile(filename)
    local parser = MidiParser.new(filename)
    local success, errorMsg = parser:parse()

    if not success then
        print("Error parsing MIDI file: " .. errorMsg)
        return
    end
    
    return parser
end

-- Return the module
return {
    MidiParser = MidiParser,
    ParseMidiFile = ParseMidiFile,
}
