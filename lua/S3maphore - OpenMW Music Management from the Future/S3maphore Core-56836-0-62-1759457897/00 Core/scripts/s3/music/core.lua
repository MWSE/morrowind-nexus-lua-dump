require 'doc.s3maphoreTypes'

local ambient = require('openmw.ambient')
local aux_util = require 'openmw_aux.util'
local async = require 'openmw.async'
local core = require('openmw.core')
local input = require 'openmw.input'
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local util = require 'openmw.util'
local vfs = require 'openmw.vfs'

local I = require 'openmw.interfaces'

local MusicBanner = require 'scripts.s3.music.banner'

local musicSettings = storage.playerSection('SettingsS3Music')

local activePlaylistSettings = storage.playerSection('S3maphoreActivePlaylistSettings')
activePlaylistSettings:setLifeTime(storage.LIFE_TIME.GameSession)

local registeredPlaylists = {}

local forceSkip = false
local BattleEnabled = musicSettings:get('BattleEnabled')
local ForceFinishTrack = musicSettings:get('ForceFinishTrack')

local ForcePlaylistChangeOnFriendlyExteriorTransition = musicSettings:get(
    'ForcePlaylistChangeOnFriendlyExteriorTransition')

local ForcePlaylistChangeOnHostileExteriorTransition = musicSettings:get(
    'ForcePlaylistChangeOnHostileExteriorTransition')

local OverworldSkip = musicSettings:get('ForcePlaylistChangeOnOverworldTransition')

local FadeOutDuration = musicSettings:get('FadeOutDuration')

local Strings = require 'scripts.s3.music.staticStrings'
local helpers = require 'scripts.omw.music.helpers' (Strings)

--- Catches changes to the hidden storage group managing playlist activation and sets the corresponding playlist's active state to match
--- In other words, this is the bit that responds to changes from the settings menu
activePlaylistSettings:subscribe(
    async:callback(
        function(_, key)
            if not key then return end
            local playlistAssignedState = activePlaylistSettings:get(key)
            local playlistName = key:gsub('Active$', '')

            if not I.S3maphore then return end

            local targetPlaylist = registeredPlaylists[playlistName]

            if not targetPlaylist then return end

            if targetPlaylist.active ~= playlistAssignedState then
                targetPlaylist.active = playlistAssignedState
            end
        end
    )
)

local PlaylistFileList = helpers.getPlaylistFilePaths()

local playlistsTracksOrder = helpers.getStoredTracksOrder()

---@alias FightingActors table<string, boolean>
local fightingActors = {}

local registrationOrder = 0

local currentPlaylist = nil
local currentTrack = nil

---@type table<string, function>
local L10nCache = {}

---@param playlistId string
local function initPlaylistL10n(playlistId)
    if L10nCache[playlistId] then return true end

    local l10nContextName = ('S3maphoreTracks_%s'):format(playlistId:gsub('/', '_'))

    if not vfs.pathsWithPrefix('l10n/' .. l10nContextName)() then return end

    local ok, maybeTranslations = pcall(function() return core.l10n(l10nContextName) end)

    if ok then
        L10nCache[playlistId] = maybeTranslations
        helpers.debugLog('Cached translations for playlist', playlistId)
    end

    return ok
end


---@class MusicManager
---@field Rules PlaylistRules
local MusicManager = {
    ---@enum S3maphoreStateChangeReason
    STATE = util.makeReadOnly {
        Died = 'DIED',
        Disabled = 'DSBL',
        NoPlaylist = 'NPLS',
        SpecialTrackPlaying = 'SPTR',
    },
    --- Meant to be used in conjunction with the output of MusicManager.playlistTimeOfDay OR PlaylistState.playlistTimeOfDay
    ---@enum TimeMap
    TIME_MAP = util.makeReadOnly {
        [0] = 'night',
        [1] = 'morning',
        [2] = 'afternoon',
        [3] = 'evening',
    },
    ---@enum InterruptMode
    INTERRUPT = util.makeReadOnly {
        Me = 0,    -- Explore
        Other = 1, -- Battle
        Never = 2, -- Special
    },
}

local silenceManager = require 'scripts.s3.music.silenceManager' (MusicManager.INTERRUPT, Strings, helpers)

musicSettings:subscribe(
    async:callback(
        function(_, key)
            if not key or key == 'BattleEnabled' then
                BattleEnabled = musicSettings:get('BattleEnabled')
            end

            if not key or key == 'ForceFinishTrack' then
                ForceFinishTrack = musicSettings:get('ForceFinishTrack')
            end

            if not key or key == 'BannerEnabled' then
                MusicManager.updateBanner()
            end

            if not key or key == 'FadeOutDuration' then
                FadeOutDuration = musicSettings:get('FadeOutDuration')
            end

            if not key or key == 'ForcePlaylistChangeOnFriendlyExteriorTransition' then
                ForcePlaylistChangeOnFriendlyExteriorTransition = musicSettings:get(
                    'ForcePlaylistChangeOnFriendlyExteriorTransition')
            end

            if not key or key == 'ForcePlaylistChangeOnHostileExteriorTransition' then
                ForcePlaylistChangeOnHostileExteriorTransition = musicSettings:get(
                    'ForcePlaylistChangeOnHostileExteriorTransition')
            end

            if not key or key == 'ForcePlaylistChangeOnOverworldTransition' then
                OverworldSkip = musicSettings:get('ForcePlaylistChangeOnOverworldTransition')
            end
        end
    )
)

---@class PlaylistState
---@field self userdata the player actor
---@field playlistTimeOfDay TimeMap the time of day for the current playlist
---@field isInCombat boolean whether the player is in combat or not
---@field cellIsExterior boolean whether the player is in an exterior cell or not (includes fake exteriors such as starwind)
---@field cellName string lowercased name of the cell the player is in
---@field cellId string engine-level identifier for cells. Should generally not be used in favor of cellNames as the only way to determine cell ids is to check in-engine using `cell.id`. It is made available in PlaylistState mostly for caching purposes, but may be used regardless.
---@field cellHasCombatTargets boolean
---@field isUnderwater boolean
---@field combatTargets FightingActors a read-only table of combat targets, where keys are actor IDs and values are booleans indicating if the actor is currently fighting
---@field staticList StaticList
---@field weather WeatherType
---@field nearestRegion string? The current region the player is in. This is determined by either checking the current region of the player's current cell, OR, reading all load door's target cell's regions in the current cell. The first cell which is found to have a region will match and be assigned to the PlaylistState.
---@field currentGrid ExteriorGrid? The current exterior cell grid. Nil if not in an actual exterior.
local PlaylistState = {
    self = self,
    combatTargets = fightingActors,
    staticList = {
        recordIds = {},
        contentFiles = {},
    },
    cellIsExterior = false,
}

--- Updates the playlist state for this frame, before it is actively used in playlist selection
local function updatePlaylistState()
    PlaylistState.playlistTimeOfDay = MusicManager.playlistTimeOfDay()

    PlaylistState.isUnderwater = self.type.isSwimming(self) and (
        self.position.z + (self:getBoundingBox().halfSize.z * 2) < (self.cell.waterLevel or 0)
    )
end

---@type PlaylistRules
local PlaylistRules = require 'scripts.s3.music.playlistRules' (PlaylistState, Strings)
MusicManager.Rules = util.makeReadOnly(PlaylistRules)

---@class Playback
---@field state PlaylistState
---@field rules PlaylistRules
local Playback = {
    rules = PlaylistRules,
    state = PlaylistState,
}

---@type QueuedEvent?
local queuedEvent

--- initialize any missing playlist fields and assign track order for the playlist, and global registration order.
---@param playlist S3maphorePlaylist
function MusicManager.registerPlaylist(playlist)
    helpers.initMissingPlaylistFields(playlist, MusicManager.INTERRUPT)
    initPlaylistL10n(playlist.id)

    local existingOrder = playlistsTracksOrder[playlist.id]

    if not existingOrder or next(existingOrder) == nil or math.max(unpack(existingOrder)) > #playlist.tracks then
        local fallback = playlist.fallback

        if fallback then
            local fallbackTracks = fallback.tracks

            if fallbackTracks and #fallbackTracks > 0 then
                for i = 1, #fallbackTracks do
                    playlist.tracks[#playlist.tracks + 1] = 'music/' .. fallbackTracks[i]
                end
            end
        end

        local newPlaylistOrder = helpers.initTracksOrder(playlist.tracks, playlist.randomize)
        playlistsTracksOrder[playlist.id] = newPlaylistOrder
        helpers.setStoredTracksOrder(playlist.id, newPlaylistOrder)
    else
        playlistsTracksOrder[playlist.id] = existingOrder
    end

    playlist.registrationOrder = registrationOrder
    if registeredPlaylists[playlist.id] == nil then
        registrationOrder = registrationOrder + 1
    end

    registeredPlaylists[playlist.id] = playlist

    local storedState = next(playlist.tracks) == nil and -1 or playlist.active

    local playlistActiveKey = playlist.id .. 'Active'

    if activePlaylistSettings:get(playlistActiveKey) ~= nil then
        helpers.debugLog('loaded playlist state from settings:', playlist.id)

        playlist.active = activePlaylistSettings:get(playlistActiveKey)
    else
        helpers.debugLog('stored playlist state in settings:', playlist.id, storedState)

        activePlaylistSettings:set(playlistActiveKey, storedState)
    end
end

--- Decides whether or not a playlist will be used at all, regardless of whether its context is valid.
--- Typically should be used to forcefully disable a playlist, as they default to active.
--- May also be used to reactivate a playlist that was deactivated by a script, or was inactive by default.
---@param id string the ID of the playlist to unregister
---@param state boolean whether or not the playlist should be active in the list of registered playlists
function MusicManager.setPlaylistActive(id, state)
    if id == nil then
        error("Playlist ID is nil")
    end

    local playlist = registeredPlaylists[id]
    if playlist then
        playlist.active = state
        activePlaylistSettings:set(playlist.id .. 'Active', playlist.active)
    else
        error(string.format("Playlist '%s' is not registered.", id))
    end
end

--- Returns the path of the currently playing track
---@return string?
function MusicManager.getCurrentTrack()
    return currentTrack
end

--- Returns l10n-localized playlist and track names for the current playlist. If a localization for the track does not exist, return nil
---@return string? playlistName, string? trackName
function MusicManager.getCurrentTrackInfo()
    if not currentPlaylist or not currentTrack then return end

    local playlistId = currentPlaylist.id

    if not L10nCache[playlistId] then return end

    local trackName = L10nCache[playlistId](currentTrack)

    if trackName ~= currentTrack then
        helpers.debugLog(
            ('Found S3maphore track translation %s for track %s:'):format(trackName, currentTrack)
        )

        return L10nCache[playlistId](playlistId), trackName
    else
        helpers.debugLog(
            ('No translations found for track %s'):format(currentTrack)
        )
    end
end

--- Returns a read-only copy of the current playlist, or nil
---@return userdata? readOnlyPlaylist
function MusicManager.getCurrentPlaylist()
    if not currentPlaylist then return end

    return util.makeReadOnly(currentPlaylist)
end

--- Returns a read-only list of read-only playlist structs for introspection. To modify playlists in any way, use other functions.
function MusicManager.getRegisteredPlaylists()
    local readOnlyPlaylists = {}

    for k, v in pairs(registeredPlaylists) do
        readOnlyPlaylists[k] = util.makeStrictReadOnly(v)
    end

    return util.makeReadOnly(readOnlyPlaylists)
end

--- Returns a read-only array of all recognized playlist files (files with the .lua extension under the VFS directory, Playlists/ )
---@return userdata playlistFiles
function MusicManager.listPlaylistFiles()
    return util.makeReadOnly(PlaylistFileList)
end

--- Stops the currently playing track, if any.
--- The onFrame handler will naturally switch to the next track or playlist
function MusicManager.skipTrack()
    forceSkip = forceSkip or ambient.isMusicPlaying()
end

--- Tells whether or not music playback is completely disabled
---@return boolean canPlayMusic
function MusicManager.getEnabled()
    return musicSettings:get("MusicEnabled")
end

function MusicManager.getState()
    return util.makeReadOnly(PlaylistState)
end

---@return number duration of current silence track
function MusicManager.silenceTime()
    return silenceManager.time
end

---@param enabled boolean
function MusicManager.overrideMusicEnabled(enabled)
    if enabled == nil then enabled = not musicSettings:get('MusicEnabled') end

    musicSettings:set("MusicEnabled", enabled)
end

--- Returns a string listing all the currently registered playlists, mapped to their (descending) priority.
--- Mostly intended to be used via the `luap` console.
---@return string
function MusicManager.listPlaylistsByPriority()
    local sortedPlaylists = {}
    for _, playlist in pairs(registeredPlaylists) do
        table.insert(sortedPlaylists, playlist)
    end

    table.sort(sortedPlaylists, function(a, b)
        return a.priority < b.priority or (a.priority == b.priority and a.registrationOrder < b.registrationOrder)
    end)

    local playlistsByName = ''

    for _, v in pairs(sortedPlaylists) do
        playlistsByName = string.format('%s%s: %s\n', playlistsByName, v.id, v.priority)
    end

    return playlistsByName
end

---@param trackPath string VFS path of the track to play
---@param reason S3maphoreStateChangeReason
function MusicManager.playSpecialTrack(trackPath, reason)
    if not vfs.fileExists(trackPath) then
        return print(('Requested track %s does not exist!'):format(trackPath))
    end

    helpers.debugLog(
        ('playing special track: %s'):format(trackPath)
    )

    registeredPlaylists.Special.tracks = { trackPath }
    playlistsTracksOrder.Special = { 1 }

    MusicManager.setPlaylistActive('Special', true)

    local fadeOut = currentPlaylist and currentPlaylist.fadeOut ~= nil and currentPlaylist.fadeOut or FadeOutDuration

    ambient.streamMusic(trackPath, fadeOut)

    self:sendEvent('S3maphoreTrackChanged',
        {
            playlistId = 'Special',
            trackName = trackPath,
            reason = reason or MusicManager.STATE.SpecialTrackPlaying
        })
end

---@return TimeMap
function MusicManager.playlistTimeOfDay()
    local dayPortion = math.floor(core.getGameTime() / 3600 % 24 / 6)
    return MusicManager.TIME_MAP[dayPortion]
end

function MusicManager.updateBanner()
    local playlist, track = MusicManager.getCurrentTrackInfo()

    if playlist and track and musicSettings:get('BannerEnabled') then
        MusicBanner.layout.props.visible = true
        MusicBanner.layout.content[1].props.text = ('%s\n\n%s'):format(playlist, track)
    else
        MusicBanner.layout.props.visible = false
    end

    MusicBanner:update()
end

---@class S3maphorePlaylistEnv
local PlaylistEnvironment = {
    playSpecialTrack = MusicManager.playSpecialTrack,
    skipTrack = MusicManager.skipTrack,
    setPlaylistActive = MusicManager.setPlaylistActive,
    timeOfDay = MusicManager.playlistTimeOfDay,
    INTERRUPT = MusicManager.INTERRUPT,
    ---@type PlaylistPriority
    PlaylistPriority = require 'doc.playlistPriority',
    Tilesets = require 'doc.tilesets',
    Playback = Playback,
    ---@type table <string, any>
    I = I,
    require = require,
    math = math,
    string = string,
    ipairs = ipairs,
    pairs = pairs,
    --- Takes any number of paramaters and deep prints them, if debug logging is enabled
    ---@param ... any
    print = function(...)
        helpers.debugLog(aux_util.deepToString({ ... }, 3))
    end,
}

local function playlistCoroutineLoader()
    local result, codeString

    for _, file in ipairs(PlaylistFileList) do
        helpers.debugLog('reading playlist file', file)
        --- open the file
        local ok, fileHandle = pcall(vfs.open, file)
        if not ok then goto fail end
        --- read all lines
        codeString = fileHandle:read('*a')
        --- util.loadCode it
        ok, result = pcall(util.loadCode, codeString, PlaylistEnvironment)
        if not ok or type(result) ~= 'function' then goto fail end
        --- call the resulting function to get the inner playlist array
        ok, result = pcall(result)
        if type(result) ~= 'table' then goto fail end
        helpers.debugLog(aux_util.deepToString(result, 3))


        for _, playlist in ipairs(result) do
            MusicManager.registerPlaylist(playlist)
            coroutine.yield(playlist)
        end

        ::fail::
        if not ok then
            print(
                Strings.FailedToLoadPlaylist:format(file, result)
            )
        else
            fileHandle:close()
        end
    end
end

-- Create the coroutine
local playlistLoaderCo = coroutine.create(playlistCoroutineLoader)
local playlistCount = 3

---@return boolean? canPlayback if true, loading has finished and playback can start
local function loadNextPlaylistStep()
    local status = coroutine.status(playlistLoaderCo)
    if status == 'dead' then return true end

    local ok, playlist = coroutine.resume(playlistLoaderCo)

    --- Explore, battle, special
    if ok and playlist then
        helpers.debugLog("Registered playlist:", playlist.id)
        playlistCount = playlistCount + 1
    elseif coroutine.status(playlistLoaderCo) == "dead" then
        print(
            Strings.InitializationFinished:format(playlistCount)
        )
        return true
    end
end

local CombatTargetCacheKey
---@param eventData CombatTargetChangedData
local function onCombatTargetsChanged(eventData)
    if eventData.actor == nil then return end

    if next(eventData.targets) ~= nil then
        fightingActors[eventData.actor.id] = eventData.actor
    else
        fightingActors[eventData.actor.id] = nil
        PlaylistRules.clearCombatCaches(eventData.actor.id)
    end

    core.sendGlobalEvent('S3maphoreUpdateCellHasCombatTargets', self)

    PlaylistState.isInCombat = BattleEnabled and helpers.isInCombat(fightingActors)

    if PlaylistState.isInCombat then
        CombatTargetCacheKey = tostring(fightingActors)

        for targetId, _ in pairs(fightingActors) do
            CombatTargetCacheKey = ('%s%s'):format(CombatTargetCacheKey, targetId)
        end

        PlaylistRules.combatTargetCacheKey = CombatTargetCacheKey
    else
        CombatTargetCacheKey, PlaylistRules.combatTargetCacheKey = nil, nil
    end
end

local function playerDied()
    MusicManager.playSpecialTrack('music/special/mw_death.mp3', MusicManager.STATE.Died)
end

--- If a set of fallback playlists is present, attempt to use them during track selection
--- It should be noted that, for fallback playlists, their `active` parameter is ignored currently.
---@param newPlaylist S3maphorePlaylist
local function getPlaylistIdForTrackSelection(newPlaylist)
    local fallbackData = newPlaylist.fallback
    if not fallbackData or not fallbackData.playlists then return newPlaylist.id end

    local useOtherPlaylist = math.random() <= (fallbackData.playlistChance or 0.5)

    if not useOtherPlaylist then return newPlaylist.id end

    for i = #fallbackData.playlists, 1, -1 do
        local playlistId = fallbackData.playlists[i]
        if not registeredPlaylists[playlistId] then table.remove(fallbackData.playlists, i) end
    end

    local numBackupPlaylists = #fallbackData.playlists
    local selectedPlaylistIndex = math.random(numBackupPlaylists)
    local selectedPlaylistId = fallbackData.playlists[selectedPlaylistIndex]

    if not registeredPlaylists[selectedPlaylistId] then
        if selectedPlaylistId then
            helpers.debugLog(
                Strings.FallbackPlaylistDoesntExist:format(newPlaylist.id, selectedPlaylistId)
            )
        end
        return newPlaylist.id
    end

    return selectedPlaylistId
end

---@param playlistId string name of a playlist stored in registeredPlaylists table
local function selectTrackFromPlaylist(playlistId)
    local playlist = registeredPlaylists[playlistId]

    assert(playlist, Strings.PlaylistNotRegistered:format(playlistId))

    local playlistOrder = playlistsTracksOrder[playlist.id]
    local nextTrackIndex = table.remove(playlistOrder)

    if nextTrackIndex == nil then
        error(Strings.NextTrackIndexNil)
    end

    -- If there are no tracks left, fill playlist again.
    if next(playlistOrder) == nil then
        playlistOrder = helpers.initTracksOrder(playlist.tracks, playlist.randomize)

        if not playlist.cycleTracks then
            playlist.deactivateAfterEnd = true
        end

        -- If next track for randomized playist will be the same as one we want to play, swap it with random track.
        if playlist.randomize and #playlistOrder > 1 and playlistOrder[1] == nextTrackIndex then
            local index = math.random(2, #playlistOrder)
            playlistOrder[1], playlistOrder[index] = playlistOrder[index], playlistOrder[1]
        end

        playlistsTracksOrder[playlist.id] = playlistOrder
    end

    helpers.setStoredTracksOrder(playlist.id, playlistOrder)

    local trackPath = playlist.tracks[nextTrackIndex]

    assert(
        trackPath,
        Strings.NoTrackPath:format(nextTrackIndex, playlist.id)
    )

    return trackPath
end

---@param newPlaylist S3maphorePlaylist
local function switchPlaylist(newPlaylist)
    local nextTrack = selectTrackFromPlaylist(
        getPlaylistIdForTrackSelection(newPlaylist)
    )

    if nextTrack ~= currentTrack then
        ambient.streamMusic(
            nextTrack,
            { fadeOut = newPlaylist.fadeOut or FadeOutDuration }
        )
        currentTrack = nextTrack
    end

    if newPlaylist.playOneTrack then
        newPlaylist.deactivateAfterEnd = true
    end

    if currentPlaylist and newPlaylist.id == currentPlaylist.id then
        silenceManager.updateSilenceParams(newPlaylist)
    end

    currentPlaylist = newPlaylist
end

---@param oldPlaylist S3maphorePlaylist?
---@param newPlaylist S3maphorePlaylist
---@return boolean canSwitchPlaylist
local function canSwitchPlaylist(oldPlaylist, newPlaylist)
    if not oldPlaylist then                                                                 --- No playlist, eg no music playing, means we can switch
        return true
    elseif oldPlaylist.interruptMode == MusicManager.INTERRUPT.Never then                   --- But never interrupt a playlist that specifies it can't be interrupted
        return false
    elseif ForceFinishTrack and oldPlaylist.interruptMode == newPlaylist.interruptMode then --- And also allow battle and explore playlist to flow nicely between themselves
        return false
    elseif oldPlaylist.interruptMode <= MusicManager.INTERRUPT.Other then                   --- And otherwise, if the interrupt mode changes then allow the new playlist
        return true
    end

    helpers.debugLog(
        Strings.InterruptModeFallthrough:format(
            oldPlaylist.id,
            oldPlaylist.interruptMode,
            newPlaylist.id,
            newPlaylist.interruptMode
        )
    )

    return false
end

local awaitingUpdate, didChangePlaylist = false, false

local inExteriorBeforeCellChange = PlaylistState.cellIsExterior

local previousCell

local function onFrame(dt)
    if not self.cell then return end

    if queuedEvent then
        self:sendEvent(queuedEvent.name, queuedEvent.data)
        queuedEvent = nil
    end

    if self.cell.id ~= previousCell then
        core.sendGlobalEvent('S3maphoreCellChanged', self)
        awaitingUpdate = true
        previousCell = self.cell.id
    end

    if not loadNextPlaylistStep() or not core.sound.isEnabled() or awaitingUpdate then return end

    -- Do not allow to switch playlists when player is dead
    local musicPlaying = ambient.isMusicPlaying()

    if not MusicManager.getEnabled() then
        if musicPlaying then
            ambient.stopMusic()
            currentPlaylist = nil
            currentTrack = nil
            queuedEvent = { name = 'S3maphoreMusicStopped', data = { reason = MusicManager.STATE.Disabled } }
        end

        return
    end

    if types.Actor.isDead(self) and musicPlaying then return end

    updatePlaylistState()

    local newPlaylist = helpers.getActivePlaylistByPriority(registeredPlaylists, Playback)

    if not newPlaylist then
        if musicPlaying then
            ambient.stopMusic()
            queuedEvent = { name = 'S3maphoreMusicStopped', data = { reason = MusicManager.STATE.NoPlaylist } }

            if currentPlaylist ~= nil then
                currentPlaylist.deactivateAfterEnd = nil
            end

            currentPlaylist = nil
            currentTrack = nil
        end

        return
    end

    if not musicPlaying and silenceManager.time > 0 then
        silenceManager.time = silenceManager.time - core.getRealFrameDuration()
        return
    end

    didChangePlaylist = didChangePlaylist or
        (
            currentPlaylist ~= nil
            and newPlaylist ~= nil
            and currentPlaylist ~= newPlaylist
        )

    local didTransition = inExteriorBeforeCellChange ~= PlaylistState.cellIsExterior

    forceSkip = forceSkip or didChangePlaylist
        and (
            didTransition and (
                (
                    (
                        ForcePlaylistChangeOnFriendlyExteriorTransition
                        and not PlaylistState.cellHasCombatTargets
                    ) or (
                        ForcePlaylistChangeOnHostileExteriorTransition
                        and PlaylistState.cellHasCombatTargets
                        and not self.cell.isExterior -- Only do this skip type for *real* interiors
                    )
                )
            ) or (
                OverworldSkip and inExteriorBeforeCellChange and PlaylistState.cellIsExterior
                and (
                    newPlaylist.priority < (currentPlaylist and currentPlaylist.priority or 1000)
                )
            )
        )

    if didTransition then
        -- if forceSkip then
        helpers.debugLog(
            Strings.PlaylistSkipFormatStr:format(
                didChangePlaylist,
                didTransition,
                ForcePlaylistChangeOnFriendlyExteriorTransition,
                ForcePlaylistChangeOnHostileExteriorTransition,
                OverworldSkip,
                PlaylistState.cellHasCombatTargets
            )
        )
        didChangePlaylist = false
    end

    --- Update this particular state value as it could change before other less-relevant ones are updated, making
    --- skip detection *potentially* less accurate
    inExteriorBeforeCellChange = PlaylistState.cellIsExterior

    -- If there's already a track running
    if musicPlaying
        and ((
            --- And the playlist hasn't actually changed
                newPlaylist == currentPlaylist
                --- or the interruptMode prevents changing playlists
                or not canSwitchPlaylist(currentPlaylist, newPlaylist)
            )
            --- but only if we didn't force a transition with F8, or the appropriate setting override
            and not forceSkip
        ) then
        return
    end

    forceSkip = false
    didChangePlaylist = false

    if newPlaylist and newPlaylist.deactivateAfterEnd then
        newPlaylist.deactivateAfterEnd = nil
        newPlaylist.active = false
        return
    end

    switchPlaylist(newPlaylist)

    queuedEvent = { name = 'S3maphoreTrackChanged', data = { playlistId = newPlaylist and newPlaylist.id, trackName = currentTrack } }
end

return {
    interfaceName = 'S3maphore',

    interface = MusicManager,

    engineHandlers = {

        onQuestUpdate = function()
            ---@diagnostic disable-next-line: invisible
            PlaylistRules.clearJournalCache()
        end,

        onKeyPress = function(key)
            if key.code == input.KEY.F8 then
                if key.withShift then
                    self:sendEvent('S3maphoreToggleMusic')
                else
                    self:sendEvent('S3maphoreSkipTrack')
                end
            elseif key.code == input.KEY.F4 then
            end
        end,

        onFrame = onFrame,

        onSave = function()
            local playlistStates = {}

            for playlistId, playlist in pairs(registeredPlaylists) do
                playlistStates[playlistId] = playlist.active
            end

            return {
                playlistStates = playlistStates,
            }
        end,

        onLoad = function(data)
            if not data then return end

            for playlistId, playlistState in pairs(data.playlistStates or {}) do
                activePlaylistSettings:set(playlistId .. 'Active', playlistState)
            end
        end
    },
    eventHandlers = {
        Died = playerDied,

        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,

        S3maphoreToggleMusic = MusicManager.overrideMusicEnabled,

        S3maphoreSkipTrack = MusicManager.skipTrack,

        S3maphoreSpecialTrack = MusicManager.playSpecialTrack,

        S3maphoreSetPlaylistActive = function(eventData)
            helpers.debugLog(
                Strings.ChangingPlaylist:format(eventData.playlist, eventData.state)
            )

            MusicManager.setPlaylistActive(eventData.playlist, eventData.state)
        end,

        ---@param eventData S3maphoreStateChangeEventData
        S3maphoreMusicStopped = function(eventData)
            helpers.debugLog(
                Strings.MusicStopped:format(eventData.reason)
            )

            MusicManager.updateBanner()
        end,

        ---@param eventData S3maphoreStateChangeEventData
        S3maphoreTrackChanged = function(eventData)
            helpers.debugLog(
                Strings.TrackChanged:format(eventData.playlistId, eventData.trackName)
            )

            MusicManager.updateBanner()
        end,

        ---@param hasCombatTargets boolean
        S3maphoreCombatTargetsUpdated = function(hasCombatTargets)
            PlaylistState.cellHasCombatTargets = hasCombatTargets
        end,

        ---@param cellChangeData S3maphoreCellChangeData
        S3maphoreCellDataUpdated = function(cellChangeData)
            PlaylistState.cellHasCombatTargets = cellChangeData.hasCombatTargets
            PlaylistState.staticList = cellChangeData.staticList
            if cellChangeData.nearestRegion then PlaylistState.nearestRegion = cellChangeData.nearestRegion end

            local thisCell = self.cell

            local shouldUseName = thisCell.name ~= nil and thisCell.name ~= ''

            PlaylistState.cellIsExterior = thisCell.isExterior or self.cell:hasTag('QuasiExterior')
            PlaylistState.cellName = shouldUseName and thisCell.name:lower() or self.cell.id:lower()
            PlaylistState.cellId = thisCell.id

            if thisCell.isExterior then
                PlaylistState.currentGrid = { x = thisCell.gridX, y = thisCell.gridY }
            else
                PlaylistState.currentGrid = nil
            end

            awaitingUpdate = false
        end,

        S3maphoreWeatherChanged = function(weatherName)
            helpers.debugLog(
                Strings.WeatherChanged:format(weatherName)
            )

            PlaylistState.weather = weatherName
        end,

        S3maphoreClearTargetCache = function()
            helpers.debugLog('clearing target cache for key', CombatTargetCacheKey)
            PlaylistRules.clearGlobalCombatTargetCache()
        end
    }
}
