local core = require('openmw.core')
local l10n = core.l10n('Bardcraft')
local vfs = require('openmw.vfs')

local drumChannelMappings = {
    [35] = 46,
    [36] = 47,
    [37] = 49,
    [38] = 48,
    [39] = 41,
    [40] = 51,
    [41] = 46,
    [42] = 38,
    [43] = 48,
    [44] = 37,
    [45] = 48,
    [46] = 37,
    [47] = 46,
    [48] = 47,
    [49] = 45,
    [50] = 48,
    [51] = 45,
    [52] = 44,
    [57] = 44,
}

local instrumentProfiles = {
    [1] = {
        name = "Lute",
        loop = false,
        sustain = true,
        transpose = true,
        polyphonic = true, 
        densityMod = 1.0,
        volume = 1.0,
    },
    [2] = {
        name = "BassFlute",
        loop = true,
        sustain = true,
        transpose = true,
        polyphonic = false,
        densityMod = 1.2,
        volume = 1.25,
    },
    [3] = {
        name = "Ocarina",
        loop = true,
        sustain = true,
        transpose = true,
        polyphonic = false,
        densityMod = 0.9,
        volume = 1.25,
    },
    [4] = {
        name = "Fiddle",
        loop = true,
        sustain = true,
        transpose = true,
        polyphonic = true,
        densityMod = 1.0,
        volume = 1,
    },
    [5] = {
        name = "Drum",
        loop = false,
        sustain = false,
        transpose = false,
        polyphonic = true,
        densityMod = 0.5,
        volume = 1,
    },
    [0] = {
        name = "None",
        loop = false,
        sustain = false,
        transpose = false,
        polyphonic = false,
        densityMod = 1.0,
        volume = 1,
    },
}

local instrumentMappings = {
    { instr = 1, low = 0, high = 15 }, -- Piano and Chromatic Percussion maps to Lute
    { instr = 3, low = 16, high = 23 }, -- Organ maps to Ocarina
    { instr = 1, low = 24, high = 39 }, -- Guitar and Bass maps to Lute
    { instr = 4, low = 40, high = 41 }, -- Violin and Viola maps to Fiddle
    { instr = 2, low = 42, high = 43 }, -- Cello and Contrabass maps to BassFlute
    { instr = 4, low = 44, high = 44 }, -- Tremolo Strings maps to Fiddle
    { instr = 1, low = 45, high = 45 }, -- Pizzicatto Strings maps to Lute
    { instr = 1, low = 46, high = 46 }, -- Harp maps to Lute
    { instr = 5, low = 47, high = 47 }, -- Timpani maps to Drum
    { instr = 4, low = 48, high = 51 }, -- String Ensemble and Synth Strings maps to Fiddle
    { instr = 3, low = 52, high = 54 }, -- Choir and Voice maps to Ocarina
    { instr = 1, low = 55, high = 55 }, -- Orchestra Hit maps to Lute
    { instr = 3, low = 56, high = 56 }, -- Trumpet maps to Ocarina
    { instr = 2, low = 57, high = 58 }, -- Trombone and Tuba maps to BassFlute
    { instr = 3, low = 59, high = 63 }, -- Rest of Brass maps to Ocarina
    { instr = 3, low = 64, high = 65 }, -- Soprano and Alto Sax maps to Ocarina
    { instr = 2, low = 66, high = 67 }, -- Tenor and Bari Sax maps to BassFlute
    { instr = 3, low = 68, high = 68 }, -- Oboe maps to Ocarina
    { instr = 2, low = 69, high = 70 }, -- English Horn and Bassoon maps to BassFlute
    { instr = 3, low = 71, high = 72 }, -- Clarinet and Piccolo maps to Ocarina
    { instr = 2, low = 73, high = 73 }, -- Flute maps to BassFlute
    { instr = 3, low = 74, high = 74 }, -- Recorder maps to Ocarina
    { instr = 2, low = 75, high = 77 }, -- Pan Flute, Blown Bottle and Shakuhachi maps to BassFlute
    { instr = 3, low = 78, high = 79 }, -- Whistle and Ocarina maps to Ocarina
    { instr = 1, low = 80, high = 87 }, -- Synth Lead maps to Lute
    { instr = 2, low = 88, high = 95 }, -- Synth Pad maps to BassFlute
    { instr = 0, low = 96, high = 103 }, -- Synth Effects maps to nothing (ignore them)
    { instr = 1, low = 104, high = 108 }, -- Ethnic Plucked maps to Lute
    { instr = 4, low = 109, high = 110 }, -- Bagpipe and Fiddle maps to Fiddle
    { instr = 3, low = 111, high = 111 }, -- Shanai maps to Ocarina
    { instr = 1, low = 112, high = 114 }, -- Percussion Pitched maps to Lute
    { instr = 5, low = 115, high = 119 }, -- Rest of Percussion maps to Drum
    { instr = 0, low = 120, high = 127 }, -- Sound Effects maps to nothing (ignore them)
}

local function getInstrumentMapping(instrument)
    instrument = instrument or 0
    -- Use binary search
    local low, high = 1, #instrumentMappings
    while low <= high do
        local mid = math.floor((low + high) / 2)
        local mapping = instrumentMappings[mid]
        if instrument < mapping.low then
            high = mid - 1
        elseif instrument > mapping.high then
            low = mid + 1
        else
            return mapping.instr
        end
    end
    return 0
end

local function mapDrumNote(note)
    local mappedNote = drumChannelMappings[note]
    if mappedNote then
        return mappedNote
    end
    return 46
end

local Part = {}
Part.__index = Part
Part.__eq = function(a, b)
    return a.index == b.index and a.instrument == b.instrument and a.title == b.title
end

function Part.new(index, instrument, title)
    local self = setmetatable({}, Part)
    self.index = index
    self.instrument = instrument
    self.title = title or (l10n('Instr_' .. instrumentProfiles[instrument].name) .. (index > 1 and (' ' .. index) or ''))
    self.numOfType = 1
    return self
end

local Song = {}
Song.__index = Song

Song.Note = { "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B" }
-- Create index lookup for notes
Song.NoteIndex = {}
for i, note in ipairs(Song.Note) do
    Song.NoteIndex[note] = i
end

Song.Mode = {
    "Major",  -- Major (W W H W W W H)
    "Minor", -- Natural Minor (W H W W H W W)
    "Velothi", --  Phrygian Dominant (H WH H W H W W)
    "Ysgramoric", -- Dorian (W H W W W H W)
    "Alessian", -- Lydian Dominant/Acoustic (W W W H W H W)
    "Remanite", -- Dorian #4 (W H WH H W H W)
    "Marukhic", -- Locrian nat6 (H W W H WH H W)
    "Frandaric", -- Double Harmonic Minor (W H WH H H WH H)
    "Ryainic", -- Harmonic Major (W W H W H WH H)
    "Aurielic", -- Lydian Augmented (W W W W H W H)
    "Yffreic", -- Mixolydian (W W H W W H W)
    "Wrothgarian", -- Minor Pentatonic (WH W W WH W)
    "Histic", -- Whole Tone (W W W W W W W)
    "Rajhinic", -- Hirajoshi (W H WW H WW)
    "Dwemeri", -- Octatonic (H W H W H W H W)
    "Mehrunic", -- Ultralocrian (H W H W W WW)
}
-- Create index lookup for scales
Song.ModeIndex = {}
for i, scale in ipairs(Song.Mode) do
    Song.ModeIndex[scale] = i
end

Song.Tags = {
    Culture = {
        "Dunmer",
        "Ashlander",
        "Imperial",
        "Nordic",
        "Breton",
        "Redguard",
        "Orcish",
        "Altmer",
        "Bosmer",
        "Argonian",
        "Khajiit",
        "Dwemer",
        "Daedric",
    },
    Mood = {
        "Cheerful",
        "Solemn",
        "Mournful",
        "Wistful",
        "Reflective",
        "Spiritual",
        "Festive",
        "Epic",
        "Heroic",
        "Tragic",
        "Martial",
        "Comedic",
        "Romantic",
        "Courtly",
        "Bawdy",
        "Ominous",
    },
    Pace = {
        "Rapid",
        "Lively",
        "Relaxed",
        "Plodding",
    },
    Genre = {
        "Ballad",
        "Folk Tune",
        "Drinking Song",
        "Sea Shanty",
        "Dance",
        "Hymn",
        "Lullaby",
        "March",
        "Lament",
        "Exercise",
        "Drum Cadence",
    },
    Faction = {
        "Redoran",
        "Hlaalu",
        "Telvanni",
        "Temple",
        "Legion",
        "Imperial Cult",
    },
}

Song.PerformanceType = {
    Perform = 0,
    Tavern = 1,
    Street = 2,
    Practice = 3,
    Ambient = 4,
    NPCTeaching = 5,
}

Song.playbackTickPrev = 0
Song.playbackTickCurr = 0
Song.playbackNoteIndex = 1
Song.tempoChangeIndex = 1
Song.lyricIndex = 1
Song.currentBPM = Song.tempo
Song.loopCount = 0

function Song.new(title, desc, tempo, timeSig)
    local self = setmetatable({}, Song)
    self.title = title or l10n('UI_Song_NewSong')
    self.desc = desc or l10n('UI_Song_NoDescription')
    self.tempo = tempo or 120
    self.tempoEvents = {}
    self.scale = {
        root = 1,
        mode = 1,
    }
    self.timeSig = timeSig or {4, 4}
    self.notes = {}
    self.parts = {}
    self.lengthBars = 4
    self.loopBars = {0, 4}
    self.resolution = 96
    self.id = self.title .. '_' .. os.time() + math.random(10000)
    self.noteIdCounter = 1
    self.tempoMod = 1
    self.loopTimes = 1
    self.texture = "generic"
    self.difficulty = "custom"
    return self
end

function Song.copy(song)
    local newSong = Song.new(l10n('UI_Song_CopyOf'):gsub("%%{title}", song.title), song.desc, song.tempo, song.timeSig)
    newSong.scale.root = song.scale.root
    newSong.scale.mode = song.scale.mode
    newSong.resolution = song.resolution
    newSong.id = song.id .. '_copy'
    newSong.parts = {}
    for _, part in ipairs(song.parts) do
        table.insert(newSong.parts, {
            index = part.index,
            instrument = part.instrument,
            title = part.title,
            numOfType = part.numOfType,
        })
    end
    newSong.notes = {}
    for _, note in ipairs(song.notes) do
        table.insert(newSong.notes, {
            id = note.id,
            type = note.type,
            note = note.note,
            velocity = note.velocity,
            part = note.part,
            time = note.time,
        })
    end
    newSong.lengthBars = song.lengthBars
    newSong.loopBars = {table.unpack(song.loopBars)}
    newSong.loopTimes = song.loopTimes
    newSong.tempoMod = song.tempoMod
    newSong.tempoEvents = {}
    for _, event in ipairs(song.tempoEvents) do
        table.insert(newSong.tempoEvents, {time = event.time, bpm = event.bpm})
    end
    newSong.lyrics = {}
    for _, lyric in ipairs(song.lyrics) do
        table.insert(newSong.lyrics, {tick = lyric.tick, text = lyric.text})
    end

    return newSong
end

function Song:getPartByIndex(index)
    for _, part in ipairs(self.parts) do
        if part.index == index then
            return part
        end
    end
    return nil
end

function Song:getPartByInstrument(instrument, numOfType)
    for _, part in ipairs(self.parts) do
        if part.instrument == instrument and part.numOfType == numOfType then
            return part
        end
    end
    return nil
end

function Song:getPartsOfInstrument(instrument)
    local parts = {}
    for _, part in ipairs(self.parts) do
        if part.instrument == instrument then
            table.insert(parts, part)
        end
    end
    return parts
end

function Song:noteEventsToNoteMap(noteEvents)
    if not noteEvents then return end
    -- In this function, we will go through the list of note starts and note ends, and pair them up
    local map = {}
    local activeNotes = {}

    self.noteIdCounter = 1

    for _, event in ipairs(noteEvents) do
        if event.type == 'noteOn' and event.velocity > 0 then
            local key = event.note .. '_' .. event.part
            activeNotes[key] = activeNotes[key] or {}
            table.insert(activeNotes[key], {
                start = event.time,
                velocity = event.velocity,
                id = event.id,
            })
        elseif (event.type == 'noteOff') or (event.type == 'noteOn' and event.velocity == 0) then
            local key = event.note .. '_' .. event.part
            if activeNotes[key] and #activeNotes[key] > 0 then
                local noteStart = table.remove(activeNotes[key], 1)
                local duration = event.time - noteStart.start
                if duration > 0 then
                    local noteData = {
                        id = noteStart.id,
                        note = event.note,
                        velocity = noteStart.velocity,
                        part = event.part,
                        time = noteStart.start,
                        duration = duration,
                    }
                    map[noteData.id] = noteData
                    self.noteIdCounter = math.max(self.noteIdCounter, noteData.id + 1)
                end
            end
        end
    end
    return map
end

function Song:noteMapToNoteEvents(noteMap)
    if not noteMap then return {} end
    -- This converts the merged note map back to a list of on/off note events
    local noteEvents = {}
    for _, noteData in pairs(noteMap) do
        if noteData then
            local noteOnEvent = {
                id = noteData.id,
                type = 'noteOn',
                note = noteData.note,
                velocity = noteData.velocity,
                part = noteData.part,
                time = noteData.time,
            }
            table.insert(noteEvents, noteOnEvent)

            local noteOffEvent = {
                id = noteData.id,
                type = 'noteOff',
                note = noteData.note,
                velocity = 0,
                part = noteData.part,
                time = noteData.time + noteData.duration,
            }
            table.insert(noteEvents, noteOffEvent)
        end
    end
    table.sort(noteEvents, function(a, b)
        if a.time == b.time then
            return (a.type == "noteOff" and b.type == "noteOn")
        end
        return a.time < b.time
    end)
    return noteEvents
end

function Song.fromMidiParser(parser, metadata)
    -- Save the original filename (full VFS path)
    local midiVfsPath = parser.filename
    parser.filename = string.match(parser.filename, "([^/]+)$")
    local fileName = string.match(parser.filename, "([^\\]+)%.mid$")
    local title = (metadata and metadata.title) or fileName:gsub("%f[%a].", string.upper)
    local desc = (metadata and metadata.description) or l10n('UI_Song_Imported')
    local self = Song.new(
        title,
        desc,
        parser:getInitialTempo(),
        {parser:getInitialTimeSignature()}
    )
    if metadata and metadata.scale then
        self.scale.root = Song.NoteIndex[metadata.scale.root] or 1
        self.scale.mode = Song.ModeIndex[metadata.scale.mode] or 1
    end
    self.resolution = parser.division or 96
    self.sourceFile = string.match(parser.filename, "([^\\]+)$")
    self.id = self.sourceFile
    local id = 1

    local partIndex = {}
    for _, note in ipairs(parser:getNotes()) do
        if note.channel == 9 then
            note.note = mapDrumNote(note.note)
        end

        if not parser.instruments[note.channel] then
            parser.instruments[note.channel] = 1
        end
        local instrument = (note.channel == 9 and 5) or getInstrumentMapping(parser.instruments[note.channel])
        if not metadata then
            note.track = 1
        end
        if instrument ~= 0 then
            if not partIndex[instrument] or not partIndex[instrument][note.track] then
                partIndex[instrument] = partIndex[instrument] or {}
                local index = #self.parts + 1
                local countOfType = #self:getPartsOfInstrument(instrument)
                local title = l10n('Instr_' .. instrumentProfiles[instrument].name) .. (countOfType > 0 and (' ' .. (countOfType + 1)) or '')
                local part = Part.new(index, instrument, title)
                part.numOfType = countOfType + 1
                if metadata and metadata.partOverrides and metadata.partOverrides[part.title] then
                    part.title = metadata.partOverrides[part.title]
                end
                table.insert(self.parts, part)
                partIndex[instrument][note.track] = index
            end
            local noteData = {
                id = id,
                type = note.type,
                note = note.note,
                velocity = note.velocity,
                part = partIndex[instrument][note.track],
                time = note.time,
            }
            id = id + 1
            table.insert(self.notes, noteData)
        end
    end
    local lastNoteTime = (#self.notes > 0) and self.notes[#self.notes].time / self.resolution or 0
    local quarterNotesPerBar = self.timeSig[1] * (4 / self.timeSig[2])
    local barCount = math.ceil(lastNoteTime / quarterNotesPerBar)
    self.lengthBars = barCount
    self.loopBars = (metadata and metadata.loopBars) or {0, barCount}
    self.loopTimes = (metadata and metadata.loopCount) or 0
    self.tempoMod = (metadata and metadata.tempoMod) or 1
    self.texture = (metadata and metadata.texture) or "generic"
    self.difficulty = (metadata and metadata.difficulty) or "custom"
    self.tempoEvents = parser:getTempoEvents()
    self.notes = self:noteMapToNoteEvents(self:noteEventsToNoteMap(self.notes))
    self.lyrics = {}

    -- Lyrics system with phrase support
    do
        local lang = "en" -- hardcoded for now
        -- Get the folder of the midi file
        local folder = midiVfsPath:match("^(.*)[/\\][^/\\]+%.mid$")
        if folder then
            local lyricsPath = folder .. "/lyrics/" .. fileName .. "_" .. lang .. ".txt"
            if vfs.fileExists(lyricsPath) then
                local phrases = {}
                local currentPhrase = {}
                local f = vfs.open(lyricsPath)
                for line in f:lines() do
                    if line:match("^%s*%-%-%-%s*$") then
                        if #currentPhrase > 0 then
                            table.insert(phrases, currentPhrase)
                            currentPhrase = {}
                        end
                    else
                        local bar, beat, text = line:match("^(%d+)%s+([%d%.]+)%s*(.*)$")
                        if bar and beat then
                            bar = tonumber(bar)
                            beat = tonumber(beat)
                            text = text or ""
                            -- Strip newlines from text
                            text = text:gsub("[\r\n]", "")
                            -- Convert bar/beat to ticks
                            -- bar is 1-indexed, beat is 1-indexed (can be decimal)
                            local beatsPerBar = self.timeSig[1]
                            local ticksPerBeat = self.resolution * (4 / self.timeSig[2])
                            local tick = ((bar - 1) * beatsPerBar + (beat - 1)) * ticksPerBeat
                            table.insert(currentPhrase, {tick = tick, text = text})
                        end
                    end
                end
                f:close()
                if #currentPhrase > 0 then
                    table.insert(phrases, currentPhrase)
                end
                self.lyrics = phrases
            end
        end
    end

    return self
end

function Song:setTitle(title)
    self.title = title
end
function Song:setDescription(desc)
    self.desc = desc
end
function Song:setTempo(tempo)
    self.tempo = tempo
end
function Song:setTimeSignature(timeSig)
    self.timeSig = timeSig
end

local restart = false

function Song:resetPlayback()
    self.playbackTickPrev = 0
    self.playbackTickCurr = 0
    self.playbackNoteIndex = 1
    self.tempoChangeIndex = 1
    self.lyricIndex = 1
    self.currentBPM = self.tempo
    self.loopCount = self.loopTimes
    restart = false
end

function Song.getInstrumentProfile(instrument)
    local profile = instrumentProfiles[instrument]
    if not profile then
        return {
            name = "Lute",
            loop = false,
            sustain = false,
            transpose = true,
            polyphonic = true, 
            densityMod = 1.0,
            volume = 1.0,
        }
    end
    return profile
end

function Song.getInstrumentProfiles()
    return instrumentProfiles
end

function Song.getInstrumentNumber(instrumentName)
    for i, mapping in ipairs(instrumentMappings) do
        if instrumentProfiles[mapping.instr].name == instrumentName then
            return mapping.instr
        end
    end
    return 0
end

function Song:createNewPart()
    local instrument = 1
    local highestIndex = 0
    for _, part in ipairs(self.parts) do
        if part.index > highestIndex then
            highestIndex = part.index
        end
    end
    local countOfType = #self:getPartsOfInstrument(instrument)
    local title = l10n('Instr_' .. instrumentProfiles[instrument].name) .. ' ' .. (countOfType + 1)
    local part = Part.new(highestIndex + 1, instrument, title)
    part.numOfType = countOfType + 1
    table.insert(self.parts, part)
    return part
end

function Song:removePart(index)
    for i, part in pairs(self.parts) do
        if part.index == index then
            table.remove(self.parts, i)
            break
        end
    end
    local notesToRemove = {}
    for i, note in pairs(self.notes) do
        if note.part == index then
            table.insert(notesToRemove, i)
        end
    end
    table.sort(notesToRemove, function(a, b) return a > b end)
    for _, i in ipairs(notesToRemove) do
        table.remove(self.notes, i)
    end
end

function Song:secondsToTicks(seconds)
    -- Converts seconds to ticks, accounting for variable tempo
    if not self.tempoEvents or #self.tempoEvents == 0 then
        local ticksPerSecond = (self.resolution * self.tempo) / 60
        return seconds * ticksPerSecond
    end

    local ticks = 0
    local timePassed = 0
    local events = self.tempoEvents
    local i = 1

    while i <= #events do
        local bpm = events[i].bpm
        local nextTick = (events[i + 1] and events[i + 1].time) or math.huge
        local ticksPerSecond = (self.resolution * bpm) / 60
        local ticksInSegment = nextTick - events[i].time
        local secondsInSegment = ticksInSegment / ticksPerSecond

        if timePassed + secondsInSegment >= seconds then
            -- Only need part of this segment
            local remaining = seconds - timePassed
            ticks = ticks + remaining * ticksPerSecond
            break
        else
            ticks = ticks + ticksInSegment
            timePassed = timePassed + secondsInSegment
        end
        i = i + 1
    end

    return ticks
end

function Song:dtToTicks(start, dt)
    -- Returns the number of ticks that would elapse over dt seconds, starting at tick 'start',
    -- accounting for tempo changes that may occur during the interval.
    if not self.tempoEvents or #self.tempoEvents == 0 then
        local ticksPerSecond = (self.resolution * self.tempo) / 60
        return dt * ticksPerSecond
    end

    local ticks = 0
    local timePassed = 0
    local events = self.tempoEvents
    local i = 1

    -- Find the first tempo event at or before 'start'
    while i <= #events and events[i].time <= start do
        i = i + 1
    end
    i = i - 1
    if i < 1 then i = 1 end

    local tickPos = start
    while timePassed < dt do
        local bpm = events[i].bpm
        local nextTick = (events[i + 1] and events[i + 1].time) or math.huge
        
        -- Handle multiple tempo events on the same tick
        while events[i + 1] and events[i + 1].time == events[i].time do
            i = i + 1
            bpm = events[i].bpm
            nextTick = (events[i + 1] and events[i + 1].time) or math.huge
        end
        
        local ticksPerSecond = (self.resolution * bpm) / 60

        local ticksToNextEvent = nextTick - tickPos
        local secondsToNextEvent = ticksToNextEvent / ticksPerSecond
        local remainingDt = dt - timePassed

        if secondsToNextEvent >= remainingDt then
            -- All remaining dt fits in this tempo segment
            ticks = ticks + remainingDt * ticksPerSecond
            break
        else
            -- Only part of dt fits before next tempo event
            ticks = ticks + ticksToNextEvent
            timePassed = timePassed + secondsToNextEvent
            tickPos = nextTick
            i = i + 1
            if not events[i] then break end
        end
    end

    return ticks
end

function Song:ticksToSeconds(ticks)
    -- Converts ticks to seconds, accounting for variable tempo
    if not self.tempoEvents or #self.tempoEvents == 0 then
        local ticksPerSecond = (self.resolution * self.tempo) / 60
        return ticks / ticksPerSecond
    end

    local seconds = 0
    local tickPassed = 0
    local events = self.tempoEvents
    local i = 1

    while i <= #events do
        local bpm = events[i].bpm
        local nextTick = (events[i + 1] and events[i + 1].time) or math.huge
        local ticksInSegment = math.min(ticks - tickPassed, nextTick - events[i].time)
        if ticksInSegment <= 0 then break end
        local ticksPerSecond = (self.resolution * bpm) / 60
        seconds = seconds + (ticksInSegment / ticksPerSecond)
        tickPassed = tickPassed + ticksInSegment
        if tickPassed >= ticks then break end
        i = i + 1
    end

    return seconds
end

function Song:tickToBeat(tick)
    local beatsPerQuarterNote = 4 / self.timeSig[2]
    local ticksPerQuarterNote = self.resolution
    local ticksPerBeat = ticksPerQuarterNote * beatsPerQuarterNote
    local beat = (tick - 1) / ticksPerBeat
    return beat
end

function Song:beatToTick(beat)
    local beatsPerQuarterNote = 4 / self.timeSig[2]
    local ticksPerQuarterNote = self.resolution
    local ticksPerBeat = ticksPerQuarterNote * beatsPerQuarterNote
    local tick = math.floor(beat * ticksPerBeat)
    return tick
end

function Song:barToTick(bar)
    return bar * self.resolution * 4 * (self.timeSig[1] / self.timeSig[2])
end

function Song:lengthInSeconds()
    local lengthInTicks = self.lengthBars * self.resolution * 4 * (self.timeSig[1] / self.timeSig[2])
    return self:ticksToSeconds(lengthInTicks)
end

function Song:lengthInSecondsWithLoops()
    local lengthInTicks = self.lengthBars * self.resolution * 4 * (self.timeSig[1] / self.timeSig[2])
    local loopEnd = self:barToTick(self.loopBars[2])
    if self.loopTimes > 0 then
        lengthInTicks = lengthInTicks + (loopEnd - self:barToTick(self.loopBars[1])) * self.loopTimes
    end
    return self:ticksToSeconds(lengthInTicks)
end

function Song.noteNumberToName(noteNumber)
    local octave = math.floor(noteNumber / 12) - 1
    local noteName = Song.Note[(noteNumber % 12) + 1]
    return noteName .. octave
end

function Song:tickPlayback(dt, noteOnHandler, noteOffHandler, tempoChangeHandler, loopHandler, lyricHandler)
    self.playbackTickPrev = self.playbackTickCurr
    local bpm = self.currentBPM or self.tempo
    local ticksPerSecond = (self.resolution * bpm) / 60
    self.playbackTickCurr = self.playbackTickCurr + dt * ticksPerSecond

    local bars = self.lengthBars
    local lengthInTicks = self:barToTick(bars)
    local loopEnd = self:barToTick(self.loopBars[2])

    if restart then
        restart = false
        if self.loopCount > 0 then
            self.loopCount = self.loopCount - 1
            local loopStart = self.loopBars[1] * self.resolution * 4 * (self.timeSig[1] / self.timeSig[2])
            self.playbackNoteIndex = 1
            self.tempoChangeIndex = 1
            self.lyricIndex = 1
            self.playbackTickCurr = loopStart
            self.playbackTickPrev = self.playbackTickCurr
            self.currentBPM = self.tempo
            if loopHandler then
                loopHandler()
            end
            return true
        else
            return false
        end
    end

    if (self.playbackTickCurr > loopEnd and self.loopCount > 0) or self.playbackTickCurr > lengthInTicks then
        restart = true
    end

    -- Handle tempo change events
    local lastTempoEvent = nil
    while self.tempoChangeIndex <= #self.tempoEvents do
        local tempoEvent = self.tempoEvents[self.tempoChangeIndex]
        if tempoEvent.time > self.playbackTickCurr then
            break
        end
        if tempoEvent.time >= self.playbackTickPrev then
            lastTempoEvent = tempoEvent
        end
        self.tempoChangeIndex = self.tempoChangeIndex + 1
    end
    if lastTempoEvent then
        if tempoChangeHandler then
            tempoChangeHandler(lastTempoEvent.bpm)
        end
        self.currentBPM = lastTempoEvent.bpm
    end

    -- Handle lyric events with phrase support
    local lastLyricEvent = nil
    local lastPhraseIndex = nil
    local lastSyllableIndex = nil
    if self.lyrics and #self.lyrics > 0 then
        for phraseIndex = self.lyricIndex, #self.lyrics do
            local phrase = self.lyrics[phraseIndex]
            for syllableIndex = 1, #phrase do
                local lyricEvent = phrase[syllableIndex]
                if lyricEvent.tick > self.playbackTickCurr then
                    break
                end
                if lyricEvent.tick >= self.playbackTickPrev then
                    lastLyricEvent = lyricEvent
                    lastPhraseIndex = phraseIndex
                    lastSyllableIndex = syllableIndex
                end
            end
            if lastLyricEvent then
                self.lyricIndex = phraseIndex
                break
            end
        end
    end
    if lastLyricEvent then
        if lyricHandler then
            local newPhrase = (lastSyllableIndex == 1)
            if newPhrase then
                lyricHandler(true, lastPhraseIndex)
            end
            lyricHandler(false, lastSyllableIndex)
        end
    end

    local noteEvents = self.notes
    while self.playbackNoteIndex <= #noteEvents do
        local event = noteEvents[self.playbackNoteIndex]
        if event.time > self.playbackTickCurr then
            break
        end
        if event.time >= self.playbackTickPrev then
            local noteNumber = event.note + 1
            local noteName = self.noteNumberToName(noteNumber - 1)
            local instrument = self:getPartByIndex(event.part).instrument
            local profile = self.getInstrumentProfile(instrument)
            local filePath = 'sound\\Bardcraft\\samples\\' .. profile.name .. '\\' .. profile.name .. '_' .. noteName .. '.flac'
            if event.type == 'noteOn' and event.velocity > 0 and not restart then
                noteOnHandler(filePath, event.velocity, instrument, event.note, event.part, event.id)
            elseif event.type == 'noteOff' or (event.type == 'noteOn' and event.velocity == 0) then
                noteOffHandler(filePath, instrument, event.note, event.part, event.id)
            end
        end
        self.playbackNoteIndex = self.playbackNoteIndex + 1
    end

    return true
end

-- Song serialization and deserialization

function Song:encode()
	-- Table to JSON
	local function jsonEncode(tbl)
		local function escapeStr(s)
			return '"' .. s:gsub('[%z\1-\31\\"]', function(c)
				return string.format('\\u%04x', c:byte())
			end) .. '"'
		end

		local function encode(val)
			if type(val) == "string" then return escapeStr(val)
			elseif type(val) == "number" or type(val) == "boolean" then return tostring(val)
			elseif type(val) == "table" then
				local isArray = #val > 0
				local out = {}
				if isArray then
					for _, v in ipairs(val) do table.insert(out, encode(v)) end
					return "[" .. table.concat(out, ",") .. "]"
				else
					for k, v in pairs(val) do
						table.insert(out, escapeStr(k) .. ":" .. encode(v))
					end
					return "{" .. table.concat(out, ",") .. "}"
				end
			else
				error("unsupported type in jsonEncode: " .. type(val))
			end
		end

		return encode(tbl)
	end

	-- String to Base64
	local function toBase64(data)
		local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		return ((data:gsub('.', function(x)
			local r, b = '', x:byte()
			for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0') end
			return r
		end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
			if #x < 6 then return '' end
			local c = 0
			for i = 1, 6 do c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0) end
			return b:sub(c+1, c+1)
		end) .. ({ '', '==', '=' })[#data % 3 + 1])
	end

    local noteStrings = {}
    for _, note in ipairs(self.notes) do
        table.insert(noteStrings, string.format('%d|%s|%d|%d|%d|%d|%d', note.id, note.type, note.note, note.velocity, note.part, note.time))
    end
    local notesString = table.concat(noteStrings, ',')

	local songData = {
        id = self.id,
		title = self.title,
		desc = self.desc,
		tempo = self.tempo,
		timeSig = self.timeSig,
		lengthBars = self.lengthBars,
		loopBars = self.loopBars,
		resolution = self.resolution,
		notes = notesString,
        parts = self.parts,
	}

	return toBase64(jsonEncode(songData))
end

function Song.decode(encoded)
	-- Base64 to string
	local function fromBase64(data)
		local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		data = string.gsub(data, '[^'..b..'=]', '')
		return (data:gsub('.', function(x)
			if x == '=' then return '' end
			local r, f = '', (b:find(x) - 1)
			for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
			return r
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if #x ~= 8 then return '' end
			local c = 0
			for i = 1, 8 do c = c + (x:sub(i,i) == '1' and 2^(8-i) or 0) end
			return string.char(c)
		end))
	end

	-- JSON to table
	local function jsonDecode(str)
		local pos = 1
		local function skip() while str:sub(pos,pos):match('%s') do pos = pos + 1 end end
		local function parse()
			skip()
			local c = str:sub(pos,pos)
			if c == '"' then
				pos = pos + 1
				local s, out = "", ""
				while true do
					local ch = str:sub(pos, pos)
					if ch == '"' then pos = pos + 1 return out
					elseif ch == '\\' then
						local esc = str:sub(pos+1, pos+1)
						local map = { ['"']='"', ['\\']='\\', ['/']='/', b='\b', f='\f', n='\n', r='\r', t='\t' }
						out = out .. (map[esc] or esc)
						pos = pos + 2
					else
						out = out .. ch
						pos = pos + 1
					end
				end
			elseif c == '{' then
				pos = pos + 1
				local obj = {}
				skip()
				if str:sub(pos,pos) == '}' then pos = pos + 1 return obj end
				while true do
					skip()
					local key = parse()
					skip()
					pos = pos + 1 -- skip :
					obj[key] = parse()
					skip()
					local nextChar = str:sub(pos,pos)
					if nextChar == '}' then pos = pos + 1 return obj
					else pos = pos + 1 end
				end
			elseif c == '[' then
				pos = pos + 1
				local arr = {}
				skip()
				if str:sub(pos,pos) == ']' then pos = pos + 1 return arr end
				while true do
					table.insert(arr, parse())
					skip()
					local nextChar = str:sub(pos,pos)
					if nextChar == ']' then pos = pos + 1 return arr
					else pos = pos + 1 end
				end
			elseif c:match('[%d%-]') then
				local start = pos
				while str:sub(pos,pos):match('[%d%+%-eE%.]') do pos = pos + 1 end
				return tonumber(str:sub(start, pos - 1))
			elseif str:sub(pos,pos+3) == "true" then pos = pos + 4 return true
			elseif str:sub(pos,pos+4) == "false" then pos = pos + 5 return false
			elseif str:sub(pos,pos+3) == "null" then pos = pos + 4 return nil
			else error("Bad JSON at " .. pos) end
		end

		return parse()
	end

	local decoded = fromBase64(encoded)
	local data = jsonDecode(decoded)

    local notes = {}
    for noteString in string.gmatch(data.notes, '([^,]+)') do
        local id, type, note, velocity, part, time = noteString:match('(%d+)|([^|]+)|(%d+)|(%d+)|(%d+)|(%d+)')
        table.insert(notes, {
            id = tonumber(id),
            type = type,
            note = tonumber(note),
            velocity = tonumber(velocity),
            part = tonumber(part),
            time = tonumber(time),
        })
    end

	local song = Song.new(data.title, data.desc, data.tempo, data.timeSig)
    song.id = data.id
	song.lengthBars = data.lengthBars
	song.loopBars = data.loopBars
	song.resolution = data.resolution
	song.notes = notes
    song.parts = data.parts

	return song
end

return {
    Song = Song,
    Part = Part,
}