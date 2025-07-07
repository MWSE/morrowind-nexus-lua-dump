local P = {}

local types = require("openmw.types")
local core = require("openmw.core")
local omwself = require("openmw.self")
local anim = require("openmw.animation")
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")
local util = require("openmw.util")
local time = require("openmw_aux.time")
local storage = require("openmw.storage")

local instrumentData = require('scripts.Bardcraft.instruments').Instruments
local animData = require('scripts.Bardcraft.instruments').AnimData
local Song = require('scripts.Bardcraft.util.song').Song
local configGlobal = require('scripts.Bardcraft.config.global')

--[[========
Performer Stats
============]]

P.stats = {
    knownSongs = {},
    performanceSkill = {
        level = 1,
        xp = 0,
        req = 10,
    },
    reputation = 0,
    bannedVenues = {},
    performedVenuesToday = {},
    practiceEfficiency = 1.0,
    performanceLogs = {},
    notesPlayed = {},
    sheathedInstrument = nil,
}

function P:onSave()
    local saveData = {
        BC_PerformerStats = self.stats,
    }
    return saveData
end

function P:sendPerformerInfo()
    local player = nearby.players[1]
    if player then
        player:sendEvent('BC_PerformerInfo', { actor = omwself, stats = self.stats })
    end
end

function P:onLoad(data)
    if not data then return end
    if data.BC_PerformerStats then
        self.stats = data.BC_PerformerStats
    end
    self:sendPerformerInfo()
end

local lastUpdate = nil

function P:onUpdate(dt)
    -- Check if new day
    local currentTime = core.getGameTime()
    local currentDay = math.floor(currentTime / time.day)
    local lastDay = lastUpdate and math.floor(lastUpdate / time.day) or nil
    local sendInfo = false
    if lastDay and currentDay ~= lastDay then
        self.stats.performedVenuesToday = {}
        self.stats.practiceEfficiency = util.clamp(math.pow(self.stats.practiceEfficiency, 0.2), 0.25, 1)
        sendInfo = true
    end
    lastUpdate = lastUpdate or currentTime
    if currentTime - lastUpdate > 1 then
        self:setSheatheVfx()
        if self.playing then
            self.resetVfx()
        end
        for _, actor in pairs(nearby.actors) do
            if actor.type == types.NPC then
                actor:sendEvent('BC_ResetVFX')
            end
        end
    end
    lastUpdate = currentTime
    for venue, banEndTime in pairs(self.stats.bannedVenues) do
        if currentTime >= banEndTime then
            self.stats.bannedVenues[venue] = nil
            sendInfo = true
        end
    end
    if sendInfo then
        self:sendPerformerInfo()
    end

    if self.playing then
        self.musicTime = self.musicTime + dt
    end
end

function P:getPerformanceXPRequired()
    return self.stats.performanceSkill.level * (10 + math.floor(self.stats.performanceSkill.level / 10) * 3)
end

function P:getPerformanceProgress()
    return self.stats.performanceSkill.xp / self:getPerformanceXPRequired()
end

function P:addPerformanceXP(xp)
    if self.stats.performanceSkill.level >= 100 then return 0 end
    self.stats.performanceSkill.xp = self.stats.performanceSkill.xp + xp
    local leveledUp = false
    local milestone = nil
    local levelGain = 0
    while self:getPerformanceProgress() >= 1 do
        leveledUp = true
        levelGain = levelGain + 1
        self.stats.performanceSkill.xp = self.stats.performanceSkill.xp - self:getPerformanceXPRequired()
        self.stats.performanceSkill.level = self.stats.performanceSkill.level + 1
        if self.stats.performanceSkill.level % 10 == 0 then
            milestone = self.stats.performanceSkill.level
        end
        if self.stats.performanceSkill.level == 100 then
            break
        end
    end
    if omwself.type == types.Player then
        omwself:sendEvent('BC_GainPerformanceXP', { leveledUp = leveledUp, milestone = milestone })
    end
    if leveledUp then
        self:sendPerformerInfo()
    end
    self.stats.performanceSkill.req = self:getPerformanceXPRequired()
    return levelGain
end

function P:setPerformanceLevel(level)
    level = util.clamp(math.floor(level), 1, 100)
    self.stats.performanceSkill.level = level
    self.stats.performanceSkill.xp = 0
    self.stats.performanceSkill.req = self:getPerformanceXPRequired()
    self:sendPerformerInfo()
    print('Set performance level to ' .. level .. ' for ' .. omwself.recordId)
end

function P:modReputation(mod)
    self.stats.reputation = self.stats.reputation + mod
    self:sendPerformerInfo()
end

function P.getSongBySourceFile(sourceFile)
    -- Search songs/preset
    local bardData = storage.globalSection('Bardcraft')
    local storedSongs = bardData:get('songs/preset') or {}
    for _, song in pairs(storedSongs) do
        if song.sourceFile == sourceFile then
            return song
        end
    end
    return nil
end

function P:addKnownSong(song, confidences)
    if self.stats.knownSongs[song.id] then return end
    self.stats.knownSongs[song.id] = {
        partConfidences = {},
    }
    for _, part in ipairs(song.parts) do
        self.stats.knownSongs[song.id].partConfidences[part.instrument] = self.stats.knownSongs[song.id].partConfidences[part.instrument] or {}
        self.stats.knownSongs[song.id].partConfidences[part.instrument][part.numOfType] = (confidences and confidences[part.instrument] and confidences[part.instrument][part.numOfType]) or 0
    end
    self:sendPerformerInfo()
end

function P:teachSong(song)
    if not self.stats.knownSongs[song.id] then
        self.stats.knownSongs[song.id] = {
            partConfidences = {},
        }
        for _, part in ipairs(song.parts) do
            self.stats.knownSongs[song.id].partConfidences[part.instrument] = self.stats.knownSongs[song.id].partConfidences[part.instrument] or {}
            self.stats.knownSongs[song.id].partConfidences[part.instrument][part.numOfType] = 0
        end
        self:sendPerformerInfo()
        return true
    end
    return false
end

function P:forgetSong(id)
    if self.stats.knownSongs[id] then
        self.stats.knownSongs[id] = nil
        self:sendPerformerInfo()
        return true
    end
    return false
end

function P:teachAllSongs()
    local bardData = storage.globalSection('Bardcraft')
    local storedSongs = bardData:get('songs/preset') or {}
    for _, song in pairs(storedSongs) do
        self:addKnownSong(song)
    end
    self:sendPerformerInfo()
end

function P:modSongConfidence(songId, part, mod)
    self.stats.knownSongs[songId] = self.stats.knownSongs[songId] or { partConfidences = {} }
    self.stats.knownSongs[songId].partConfidences[part.instrument] = self.stats.knownSongs[songId].partConfidences[part.instrument] or {}
    local confidence = self.stats.knownSongs[songId].partConfidences[part.instrument][part.numOfType] or 0
    if confidence ~= confidence then confidence = 0 end
    if mod ~= mod then mod = 0 end
    confidence = util.clamp(confidence + mod, 0, 1)
    self.stats.knownSongs[songId].partConfidences[part.instrument][part.numOfType] = confidence
    self:sendPerformerInfo()
end

function P:resetAllStats()
    self.stats = {
        knownSongs = {},
        performanceSkill = {
            level = 1,
            xp = 0,
            req = 10,
        },
        reputation = 0,
        bannedVenues = {},
        performedVenuesToday = {},
        practiceEfficiency = 1.0,
        performanceLogs = {},
        notesPlayed = {},
    }
    self:sendPerformerInfo()
    print('Reset performer stats for ' .. omwself.recordId)
end

--[[========
Performance Data
============]]

P.bpm = 0
P.musicTime = -1
P.currentSong = nil
P.currentPart = nil
P.playing = false
P.performanceType = nil

P.wasMoving = false
P.idleTimer = nil
P.instrument = nil
P.instrumentProfile = nil
P.instrumentItem = nil

P.lastNoteTime = nil
P.noteIntervals = {}
P.currentDensity = 0
P.currentConfidence = 0
P.maxConfidence = 0
P.maxHistory = 24

P.xpGain = 0
P.levelGain = 0

P.maxConfidenceGrowth = 0
P.overallNoteEvents = {}
P.playingNotes = {}

local function getXpMult(type)
    if type == Song.PerformanceType.Tavern then
        return configGlobal.options.fTavernXpMult
    elseif type == Song.PerformanceType.Street then
        return configGlobal.options.fStreetXpMult
    elseif type == Song.PerformanceType.Practice then
        return configGlobal.options.fPracticeXpMult * (configGlobal.options.bEnablePracticeEfficiency == true and P.stats.practiceEfficiency or 1)
    end
    return 0.0
end

local easyDensity = 1.0
local hardDensity = 6.0

local function getBpmConstant()
    local animFps = 24
    local animFramesPerBeat = 20
    local animBpm = animFps * 60 / animFramesPerBeat
    return P.bpm / animBpm
end

local function getAnimStartPoint(timeOffset)
    if timeOffset == -1 then
        return 0
    end
    local songBeatLength = 1 / (P.bpm / 60)
    local animBeatLength = 1 / (24 / 20)
    local adjustedTimeOffset = timeOffset / (animBeatLength / songBeatLength)
    local animTime = adjustedTimeOffset / (animBeatLength * 16) -- from 0 to 1
    return animTime
end

function P.hasAnim()
    return omwself and anim.hasAnimation(omwself)
end

function P.startAnim(animKey)
    if not P.hasAnim() then return end
    local enabled = configGlobal.options.bEnableAnimations

    local priority = {
        [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Hit,
        [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Hit,
        [anim.BONE_GROUP.Torso] = anim.PRIORITY.Hit,
        [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.WeaponLowerBody
    }

    I.AnimationController.playBlendedAnimation(animKey, {
        loops = 100000000,
        priority = priority,
        blendMask = enabled and anim.BLEND_MASK.All or anim.BLEND_MASK.UpperBody,
        startPoint = getAnimStartPoint(P.musicTime) % 1,
        speed = enabled and getBpmConstant() or 0,
    })
end

function P.resyncAnim(animKey)
    if not P.hasAnim() then return end
    if anim.isPlaying(omwself, animKey) then
        anim.cancel(omwself, animKey)
        P.startAnim(animKey)
    end
end

function P.resetVfx()
    if not P.hasAnim() then return end
    if not P.instrumentItem then
        anim.removeVfx(omwself, 'BO_Instrument')
        return
    end
    local modelName = P.instrumentItem.model
    -- Convert to our vfx directory path
    modelName = modelName:match("([^/]+)$")
    modelName = 'meshes/bardcraft/vfx/play/' .. modelName
    if instrumentData[P.instrument] then
        anim.removeVfx(omwself, 'BO_Instrument')
        if not anim.hasBone(omwself, instrumentData[P.instrument].boneName) then
            return
        end
        anim.addVfx(omwself, modelName, {
            boneName = instrumentData[P.instrument].boneName,
            vfxId = 'BO_Instrument',
            loop = true,
            useAmbientLight = false
        })
        -- Attach extra models if specified
        if instrumentData[P.instrument].attachExtra then
            for _, extra in ipairs(instrumentData[P.instrument].attachExtra) do
                if anim.hasBone(omwself, extra.boneName) then
                    anim.addVfx(omwself, extra.path, {
                        boneName = extra.boneName,
                        vfxId = 'BO_Instrument',
                        loop = true,
                        useAmbientLight = false
                    })
                end
            end
        end
    end
end

function P.resetAnim()
    if not P.hasAnim() then return end
    if instrumentData[P.instrument] then
        anim.cancel(omwself, instrumentData[P.instrument].anim)
        P.startAnim(instrumentData[P.instrument].anim)
    end
end

function P.playNote(note, velocity)
    local success = true
    local pitch = 1.0
    local volume = velocity * (1 + math.random() * 0.2 - 0.1)
    if math.random() > P.getNoteAccuracy() then
        if not configGlobal.options.bJamMode then
            pitch = 1.0 + (math.random() * 0.2 - 0.1) -- Random pitch shift between -10% and +10%
            volume = volume * 0.5 + math.random() * (volume)
        end
        success = false
    end
    local noteName = Song.noteNumberToName(note)
    local filePath = 'sound\\Bardcraft\\samples\\' .. P.instrument .. '\\' .. P.instrument .. '_' .. noteName .. '.flac'
    core.sound.playSoundFile3d(filePath, omwself, { volume = volume * configGlobal.options.fInstrumentVolume, pitch = pitch, })
    P.playingNotes[note] = P.playingNotes[note] and P.playingNotes[note] + 1 or 1
    return success
end

function P.stopNote(note)
    P.playingNotes[note] = P.playingNotes[note] and P.playingNotes[note] - 1 or 0
    if P.playingNotes[note] > 0 then
        return
    end
    local noteName = Song.noteNumberToName(note)
    local filePath = 'sound\\Bardcraft\\samples\\' .. P.instrument .. '\\' .. P.instrument .. '_' .. noteName .. '.flac'
    core.sound.stopSoundFile3d(filePath, omwself)
end

function P.stopAllNotes()
    for note = 0, 127 do
        P.stopNote(note)
    end
end

function P.handlePerformEvent(data)
    local song = data.song
    P.musicTime = data.time + (core.getRealTime() - data.realTime)
    P.bpm = song.tempo * song.tempoMod
    P.performanceType = data.perfType

    -- Check if time sig is compound and if so, adjust BPM so animation matches
    if song.timeSig[1] % 3 == 0 and song.timeSig[1] > 3 then
        P.bpm = P.bpm * 4 / 3
    end

    local iData = instrumentData[data.instrument]
    if not iData then return end
    P.instrument = data.instrument
    P.instrumentProfile = Song.getInstrumentProfile(Song.getInstrumentNumber(data.instrument))
    P.instrumentItem = types.Miscellaneous.record(data.item)
    P.resetVfx()
    P.resetAnim()
    if P.instrumentProfile.sustain then
        P.stopAllNotes()
    end

    local songInfo = P.stats.knownSongs[song.id]
    if not songInfo then
        P:addKnownSong(song)
    end

    P.maxConfidence = P.stats.knownSongs[song.id].partConfidences[data.part.instrument] and P.stats.knownSongs[song.id].partConfidences[data.part.instrument][data.part.numOfType] or 0
    if P.maxConfidence ~= P.maxConfidence then
        P.maxConfidence = 0 -- NaN check
    end
    P.maxConfidenceGrowth = (1 - math.pow(P.maxConfidence, 1/3)) * 0.8 -- Fast growth at low confidence, slow growth at high confidence

    if not P.playing then
        P.currentConfidence = P.maxConfidence
        P.currentDensity = 0
        P.noteIntervals = {}
        P.overallNoteEvents = {}
        P.lastNoteTime = nil
        P.xpGain = 0
        P.levelGain = 0
    end

    P.playing = true
    P.playingNotes = {}
    P.currentSong = song
    P.currentPart = data.part
end

function P.handleStopEvent(data)
    P.stopAllNotes()
    if P.hasAnim() then
        anim.removeVfx(omwself, 'BO_Instrument')
        anim.cancel(omwself, instrumentData[P.instrument].anim)
        if animData[P.instrument] then
            for a, _ in pairs(animData[P.instrument]) do 
                anim.cancel(omwself, a)
            end
        end
    end
    P.playing = false
    P.instrument = nil
    P.instrumentItem = nil

    if P.performanceType == Song.PerformanceType.Ambient then 
        P.currentSong = nil
        P.currentPart = nil
        return 
    end

    local successCount = 0
    for _, success in ipairs(P.overallNoteEvents) do
        if success then
            successCount = successCount + 1
        end
    end
    local successRate = math.pow(successCount / #P.overallNoteEvents, 2)
    local diff = successRate - P.maxConfidence
    local maxGrowth = util.clamp(P.maxConfidenceGrowth * data.completion, 0, P.maxConfidenceGrowth)
    local oldConfidence = P.maxConfidence
    local mod = util.clamp(diff, -maxGrowth, maxGrowth)

    if P.performanceType == Song.PerformanceType.Practice then
        mod = mod * (configGlobal.options.bEnablePracticeEfficiency == true and P.stats.practiceEfficiency or 1)
        local practiceMod = math.pow(0.9, (#P.overallNoteEvents / 300))
        P.stats.practiceEfficiency = util.clamp(P.stats.practiceEfficiency * practiceMod, 0.125, 1)
        if omwself then
            omwself:sendEvent('BC_PracticeEfficiency', { efficiency = P.stats.practiceEfficiency })
        end
    elseif P.performanceType == Song.PerformanceType.Tavern then
        local currentDay = math.floor(core.getGameTime() / time.day)
        local performanceDay = math.floor((data.startTime or 0) / time.day)
        if currentDay == performanceDay then
            if type(P.stats.performedVenuesToday[data.cell]) == 'boolean' then P.stats.performedVenuesToday[data.cell] = 1 end
            P.stats.performedVenuesToday[data.cell] = (P.stats.performedVenuesToday[data.cell] or 0) + 1
        end
    end
    P:modSongConfidence(P.currentSong.id, P.currentPart, mod)
    if omwself and omwself.type == types.Player then
        omwself:sendEvent('BC_GainConfidence', { songTitle = P.currentSong.title, partTitle = P.currentPart.title, oldConfidence = oldConfidence, newConfidence = P.stats.knownSongs[P.currentSong.id].partConfidences[P.currentPart.instrument][P.currentPart.numOfType] })
        core.sendGlobalEvent('BC_PlayerPerfSkillLog', { xpGain = P.xpGain, levelGain = P.levelGain, level = P.stats.performanceSkill.level, xpCurr = P.stats.performanceSkill.xp, xpReq = P:getPerformanceXPRequired() })
    end
    
    P.currentSong = nil
    P.currentPart = nil
end

function P.handleTempoEvent(data)
    if not P.playing then return end
    if data.bpm then
        P.bpm = data.bpm * P.currentSong.tempoMod
        if P.currentSong.timeSig[1] % 3 == 0 and P.currentSong.timeSig[1] > 3 then
            P.bpm = P.bpm * 4 / 3
        end
        if P.hasAnim() then
            anim.setSpeed(omwself, instrumentData[P.instrument].anim, getBpmConstant())
        end
    end
end

function P.getNoteAccuracy()
    local density = P.currentDensity

    local difficultyFactor = util.clamp((density - easyDensity) / (hardDensity - easyDensity), 0, 1) - 0.3
    local accuracy = math.pow(P.stats.performanceSkill.level / 100, 1/2) * 1.1 - (difficultyFactor * 0.7) + (math.pow(P.currentConfidence, 1/2) * 0.5)

    return util.clamp(accuracy, 0, 1)
end

function P.handleNoteEvent(data)
    if omwself.type.isDead(omwself) then return false end
    local intervalBase = 1 / P.instrumentProfile.densityMod
    local interval = intervalBase
    local weight = 1.0
    
    if P.lastNoteTime then
        interval = interval * (data.time - P.lastNoteTime)
        if interval < 0.075 then
            weight = weight * 0.25
        end
        table.insert(P.noteIntervals, { interval = interval, weight = weight })
        if #P.noteIntervals > P.maxHistory then
            table.remove(P.noteIntervals, 1)
        end

        -- Calculate moving average density (notes per second)
        local totalInterval = 0
        local totalWeight = 0
        for _, v in ipairs(P.noteIntervals) do
            totalInterval = totalInterval + v.interval * v.weight
            totalWeight = totalWeight + v.weight
        end
        local avgInterval = totalInterval / totalWeight
        P.currentDensity = 1 / avgInterval
    end
    P.lastNoteTime = data.time
    local success = P.playNote(data.note, data.velocity)
    if P.performanceType ~= Song.PerformanceType.Ambient then
        if success then
            local gain = (P.maxConfidence - P.currentConfidence) / P.maxConfidence * 0.04
            P.currentConfidence = math.min(P.currentConfidence + gain, P.maxConfidence)
            local xp = configGlobal.options.fBaseXpPerNote * getXpMult(P.performanceType) / intervalBase
            P.levelGain = P.levelGain + P:addPerformanceXP(xp)
            P.xpGain = P.xpGain + xp
        else
            local loss = P.currentConfidence / P.maxConfidence * 0.04
            P.currentConfidence = math.max(P.currentConfidence - loss, 0)
        end
        table.insert(P.overallNoteEvents, success)
        P.stats.notesPlayed = P.stats.notesPlayed or {}
        P.stats.notesPlayed[P.instrument] = (P.stats.notesPlayed[P.instrument] or 0) + 1
        core.sendGlobalEvent('BC_PerformerNoteHandled', { success = success, performer = omwself, mod = 1 / intervalBase * weight })
    else
        P.currentConfidence = P.maxConfidence
    end
    return success
end

function P.handleConductorEvent(data)
    local success
    if data.type == 'PerformStart' then
        P.handlePerformEvent(data)
    elseif data.type == 'PerformStop' and P.playing then
        P.handleStopEvent(data)
    elseif data.type == 'TempoEvent' and P.playing then
        P.handleTempoEvent(data)
    elseif data.type == 'NoteEvent' then
        success = P.handleNoteEvent(data)
    elseif data.type == 'NoteEndEvent' and data.stopSound then
        P.stopNote(data.note)
    end
    if P.instrument and instrumentData[P.instrument] and instrumentData[P.instrument].eventHandler then
        data.time = core.getRealTime()
        instrumentData[P.instrument].eventHandler(data)
    end
    P:setSheatheVfx()
    return success
end

function P:onFrame()
end

function P:setSheatheVfx()
    if not P.hasAnim() then return end
    anim.removeVfx(omwself, 'BC_BackInstrument')
    if not self.stats.sheathedInstrument then return end
    local record = types.Miscellaneous.record(self.stats.sheathedInstrument)
    if record and self:verifySheathedInstrument() and (not self.instrumentItem or record.id ~= self.instrumentItem.id) then
        local modelName = record.model
        modelName = 'meshes/bardcraft/vfx/sheathe/' .. modelName:match("([^/]+)$")
        if not anim.hasBone(omwself, 'Bip01 BOInstrumentBack') then 
            return 
        end
        anim.addVfx(omwself, modelName, {
            vfxId = 'BC_BackInstrument',
            boneName = 'Bip01 BOInstrumentBack',
            loop = true,
            useAmbientLight = false,
        })
    end
end

function P:setSheathedInstrument(recordId, force)
    if self.stats.sheathedInstrument == recordId and not force then
        self.stats.sheathedInstrument = nil
    else
        self.stats.sheathedInstrument = recordId
    end
    self:setSheatheVfx()
end

function P:verifySheathedInstrument()
    if self.stats.sheathedInstrument then
        local inventory = omwself.type.inventory(omwself)
        return inventory:find(self.stats.sheathedInstrument) ~= nil
    end
    return false
end

return P