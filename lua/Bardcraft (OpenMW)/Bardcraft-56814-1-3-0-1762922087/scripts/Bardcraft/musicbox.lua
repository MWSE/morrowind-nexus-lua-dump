local self = require('openmw.self')
local anim = require('openmw.animation')
local types = require('openmw.types')
local core = require('openmw.core')
local storage = require('openmw.storage')
local nearby = require('openmw.nearby')
local util = require('openmw.util')

local Data = require('scripts.Bardcraft.data')
local Song = require('scripts.Bardcraft.util.song').Song

local STATE = {
    Idle = 0,
    Start = 1,
    Play = 2,
    Stop = 3,
}

local hasBeenPlayed = 0
local songId = 0
local song = nil
local playing = false
local playingTime = 0
local teachTime = 0
local state = STATE.Idle
local notifyNearbyTimer = 0
local valid = false
local playerPlaced = false

local function getSongBySourceFile(sourceFile)
    -- Search songs/preset
    local bardData = storage.globalSection('Bardcraft')
    local storedSongs = bardData:getCopy('songs/preset') or {}
    for _, song in pairs(storedSongs) do
        if song.sourceFile == sourceFile then
            return song
        end
    end
    return nil
end

local function getSongById(id)
    local sourceFile = Data.SongIds[id]
    if not sourceFile then return nil end
    return getSongBySourceFile(sourceFile)
end

local function sourceFileToSongId(sourceFile)
    for k, v in pairs(Data.SongIds) do
        if v == sourceFile then
            return k
        end
    end
end

local function pickRandomSong()
    local boxData = Data.MusicBoxes[self.recordId]
    local songChoices = {}

    if boxData.songs then
        songChoices = boxData.songs
    elseif boxData.pools then
        local seen = {}
        for _, poolId in ipairs(boxData.pools) do
            local pool = Data.SongPools[poolId]
            if pool then
                for _, songId in ipairs(pool) do
                    if not seen[songId] then
                        table.insert(songChoices, songId)
                        seen[songId] = true
                    end
                end
            end
        end
    end

    if not songChoices or #songChoices == 0 then return end
    local song = songChoices[math.random(#songChoices)]
    return song
end

local function isValid()
    return self.recordId:sub(1, 12) == 'r_bc_musbox_'
end

local function calcAnimSpeed()
    if not song then return end
    local loopLengthFrames = 640
    local animFps = 24
    local loopLengthSeconds = loopLengthFrames / animFps
    local songLengthSeconds = song:lengthInSecondsWithLoops()
    return loopLengthSeconds / songLengthSeconds
end

local function notifyNearbyPlayers()
    for _, player in pairs(nearby.players) do
        player:sendEvent('BC_NearbyPlaying')
    end
end

local function teachNearbyPlayers()
    if not song then return end
    local songData = {
        id = song.id,
        title = song.title,
        parts = song.parts,
    }
    for _, player in pairs(nearby.players) do
        player:sendEvent('BC_TeachSong', { song = songData, })
    end
end


local function startPlaying()
    if not valid then return end
    if self.type ~= types.Activator then return end
    if not song then return end
    if state ~= STATE.Play then
        state = STATE.Start
        anim.clearAnimationQueue(self, true)
        anim.playQueued(self, 'musboxstart')
        core.sound.playSoundFile3d('sound/Bardcraft/musbox-start.wav', self)
        playing = true
        playingTime = 0
        teachTime = util.clamp(song:lengthInSecondsWithLoops() - 5, 0, 10)
        song:resetPlayback()
        song.loopCount = song.loopTimes
        notifyNearbyTimer = 0
    end
end

local function tickState(dt)
    if self.type ~= types.Activator then return end
    if state == STATE.Idle then return end
    if state == STATE.Start then
        if not anim.isPlaying(self, 'musboxstart') then
            state = STATE.Play
            anim.playQueued(self, 'musboxloop', {
                speed = calcAnimSpeed(),
            })
            core.sound.playSoundFile3d('sound/Bardcraft/musbox-loop.wav', self, {
                volume = 0.25,
                loop = true,
            })
        end
    end
    if state == STATE.Play then
        local lastPlayingTime = playingTime
        playingTime = playingTime + dt
        if lastPlayingTime <= teachTime and playingTime > teachTime then
            teachNearbyPlayers()
        end
        if not song:tickPlayback(dt,
        function(filePath, velocity, instrument, note, part, id)
            if Song.getInstrumentProfile(instrument).name == 'Drum' then return end
            velocity = velocity / 127
            filePath = 'sound/Bardcraft/samples/MusicBox/MusicBox_' .. Song.noteNumberToName(note) .. '.flac'
            core.sound.playSoundFile3d(filePath, self, {
                volume = velocity * 2,
            })
        end,
        function()
        end) then
            state = STATE.Stop
            anim.clearAnimationQueue(self, true)
            anim.playQueued(self, 'musboxstop')
            core.sound.stopSoundFile3d('sound/Bardcraft/musbox-loop.wav', self)
            playing = false
        end

        if notifyNearbyTimer <= 0 then
            notifyNearbyTimer = 5
            notifyNearbyPlayers()
        else
            notifyNearbyTimer = notifyNearbyTimer - dt
        end
    end
    if state == STATE.Stop then
        if not anim.isPlaying(self, 'musboxstop') then
            state = STATE.Idle
        end
    end
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            if dt == 0 then return end
            if not valid then return end
            if state ~= STATE.Idle then
                tickState(dt)
            end
        end,
        onSave = function()
            if not valid then return end
            return {
                BC_HasBeenPlayed = hasBeenPlayed,
                BC_SongId = songId,
                BC_PlayerPlaced = playerPlaced,
            }
        end,
        onLoad = function(data)
            if not data then return end
            hasBeenPlayed = data.BC_HasBeenPlayed or 0
            songId = data.BC_SongId or 0
            playerPlaced = data.BC_PlayerPlaced or false
        end,
        onActivated = function(actor)
            if not valid then return end
            if self.type == types.Activator then
                if actor.type == types.Player then
                    actor:sendEvent('BC_MusicBoxActivate', { object = self, songName = hasBeenPlayed == 1 and getSongById(songId).title or nil })
                end
            end
        end,
        onActive = function()
            valid = isValid()
            if not valid then return end
            if self.type == types.Miscellaneous then
                core.sendGlobalEvent('BC_ReplaceMusicBox', { object = self })
            else
                --anim.playQueued(self, 'musboxidle')
                if not playerPlaced then
                    core.sendGlobalEvent('BC_PruneMusicBox', { object = self })
                end
            end
        end,
    },
    eventHandlers = {
        BC_MusicBoxInit = function(data)
            hasBeenPlayed = data.hasBeenPlayed or 0
            songId = data.songId or 0
            playerPlaced = data.playerPlaced or false
        end,
        BC_MusicBoxPickup = function(data)
            if not valid then return end
            core.sound.stopSoundFile3d('sound/Bardcraft/musbox-loop.wav', self)
            core.sendGlobalEvent('BC_MusicBoxPickup', {
                object = self,
                hasBeenPlayed = hasBeenPlayed,
                songId = songId,
                actor = data.actor,
            })
        end,
        BC_MusicBoxToggle = function(data)
            if not valid then return end
            if self.type == types.Activator then
                if data.actor.type == types.Player then
                    playing = not playing
                    if playing then
                        if hasBeenPlayed == 0 then
                            hasBeenPlayed = 1
                            songId = data.prefSong and sourceFileToSongId(data.prefSong) or pickRandomSong()
                        end
                        song = getSongById(songId)
                        setmetatable(song, Song)
                        startPlaying()
                    else
                        state = STATE.Stop
                        anim.clearAnimationQueue(self, true)
                        anim.playQueued(self, 'musboxstop')
                        core.sound.stopSoundFile3d('sound/Bardcraft/musbox-loop.wav', self)
                        playing = false
                    end
                end
            end
        end,
    },
}