local ambient = require('openmw.ambient')
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

local PlaylistSkipFormatStr = [[Track Skip:
        Did Change Playlist: %s
        Transitioned from interior to exterior: %s
        Force transition for friendly cell: %s
        Force Transition for hostile cell: %s
        Force Overworld Transition: %s
        Cell is hostile: %s]]

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

local helpers = require('scripts.omw.music.helpers')
local PlaylistFileList = helpers.getPlaylistFilePaths()

local playlistsTracksOrder = helpers.getStoredTracksOrder()

---@alias FightingActors table<string, boolean>
local fightingActors = {}

local registrationOrder = 0

local currentPlaylist = nil
local currentTrack = nil

local battlePriority = 200
local explorePriority = 1000

---@type table<string, function>
local L10nCache = {}

---@param playlistId string
local function initPlaylistL10n(playlistId)
    if L10nCache[playlistId] then return true end

    local l10nContextName = ('S3maphoreTracks_%s'):format(playlistId:gsub('/', '_'))

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
---@field cellHasCombatTargets boolean
---@field isUnderwater boolean
---@field combatTargets FightingActors a read-only table of combat targets, where keys are actor IDs and values are booleans indicating if the actor is currently fighting
---@field staticList userdata[]? a read-only list of static objects in the cell, if the cell is not exterior. If the static list is not yet valid, is an empty table. Nil for "true" exteriors.
---@field weather WeatherType
local PlaylistState = {
    self = self,
    combatTargets = fightingActors,
    staticList = {},
    cellIsExterior = (
        self.cell.isExterior or self.cell:hasTag('QuasiExterior')
    ),
}

--- Updates the playlist state for this frame, before it is actively used in playlist selection
local function updatePlaylistState()
    PlaylistState.playlistTimeOfDay = MusicManager.playlistTimeOfDay()

    PlaylistState.isUnderwater = self.type.isSwimming(self) and (
        self.position.z + (self:getBoundingBox().halfSize.z * 2) < (self.cell.waterLevel or 0)
    )
end

---@type PlaylistRules
local PlaylistRules = require 'scripts.s3.music.playlistRules' (PlaylistState)
MusicManager.Rules = util.makeReadOnly(PlaylistRules)

---@class Playback
---@field state PlaylistState
---@field rules PlaylistRules
local Playback = {
    rules = PlaylistRules,
    state = PlaylistState,
}

---@class QueuedEvent
---@field name string the name of the event to send
---@field data any the data to send with the event

---@type QueuedEvent?
local queuedEvent

---@alias ValidPlaylistCallback fun(playback: Playback): boolean? a function that returns true if the playlist is valid for the current context. If not provided, the playlist will always be valid.

---@class S3maphorePlaylist
---@field id string name of the playlist
---@field priority number priority of the playlist, lower value means higher priority
---@field tracks string[]? list of tracks in the playlist. If not provided, tracks will be loaded from the music/ subdirectory with the same name as the playlist ID.
---@field randomize boolean? if true, tracks will be played in random order. Defaults to false.
---@field active boolean? if true, the playlist is active and will be played. Defaults to false
---@field cycleTracks boolean? if true, the playlist will cycle through tracks. Defaults to true
---@field playOneTrack boolean? if true, the playlist will play only one track and then deactivate. Defaults to false
---@field registrationOrder number? the order in which the playlist was registered, used for sorting playlists by priority. Do not provide in the playlist definition, it will be assigned automatically.
---@field deactivateAfterEnd boolean? if true, the playlist will be deactivated after the current track ends. Defaults to false.
---@field interruptMode InterruptMode? whether a given playlist should be interrupted by others or interrupt others. By default, Explore playlists can be interrupted, battle playlists will interrupt other playlists, and Special playlists will never be interrupted.
---@field isValidCallback ValidPlaylistCallback?

---@class S3maphoreStateChangeEventData
---@field playlistId string
---@field trackName string VFS path of the track being played
---@field reason S3maphoreStateChangeReason

--- initialize any missing playlist fields and assign track order for the playlist, and global registration order.
---@param playlist S3maphorePlaylist
function MusicManager.registerPlaylist(playlist)
    helpers.initMissingPlaylistFields(playlist, MusicManager.INTERRUPT)
    initPlaylistL10n(playlist.id)

    local existingOrder = playlistsTracksOrder[playlist.id]

    if not existingOrder or next(existingOrder) == nil or math.max(unpack(existingOrder)) > #playlist.tracks then
        local newPlaylistOrder = helpers.initTracksOrder(playlist.tracks, playlist.randomize)
        playlistsTracksOrder[playlist.id] = newPlaylistOrder
        helpers.setStoredTracksOrder(playlist.id, newPlaylistOrder)
    else
        playlistsTracksOrder[playlist.id] = existingOrder
    end

    if registeredPlaylists[playlist.id] == nil then
        playlist.registrationOrder = registrationOrder
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

local aux_util = require 'openmw_aux.util'

---@class S3maphorePlaylistEnv
local PlaylistEnvironment = {
    playSpecialTrack = MusicManager.playSpecialTrack,
    skipTrack = MusicManager.skipTrack,
    setPlaylistActive = MusicManager.setPlaylistActive,
    timeOfDay = MusicManager.playlistTimeOfDay,
    INTERRUPT = MusicManager.INTERRUPT,
    PlaylistPriority = require 'doc.playlistPriority',
    Playback = Playback,
    ---@type table <string, any>
    I = I,
    require = require,
    math = math,
    string = string,
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
            print(string.format("Failed to load playlist file: %s\nErr: %s", file, result))
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
        print(("[ S3MAPHORE ]: %d playlists loaded. Ready to play music!"):format(playlistCount))
        return true
    end
end

local CombatTargetCacheKey
local function onCombatTargetsChanged(eventData)
    if eventData.actor == nil then return end

    if next(eventData.targets) ~= nil then
        fightingActors[eventData.actor.id] = eventData.actor
    else
        fightingActors[eventData.actor.id] = nil
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

local function switchPlaylist(newPlaylist)
    local newPlaylistOrder = playlistsTracksOrder[newPlaylist.id]
    local nextTrackIndex = table.remove(newPlaylistOrder)

    if nextTrackIndex == nil then
        error("Can not fetch track: nextTrackIndex is nil")
    end

    -- If there are no tracks left, fill playlist again.
    if next(newPlaylistOrder) == nil then
        newPlaylistOrder = helpers.initTracksOrder(newPlaylist.tracks, newPlaylist.randomize)

        if not newPlaylist.cycleTracks then
            newPlaylist.deactivateAfterEnd = true
        end

        -- If next track for randomized playist will be the same as one we want to play, swap it with random track.
        if newPlaylist.randomize and #newPlaylistOrder > 1 and newPlaylistOrder[1] == nextTrackIndex then
            local index = math.random(2, #newPlaylistOrder)
            newPlaylistOrder[1], newPlaylistOrder[index] = newPlaylistOrder[index], newPlaylistOrder[1]
        end

        playlistsTracksOrder[newPlaylist.id] = newPlaylistOrder
    end

    helpers.setStoredTracksOrder(newPlaylist.id, newPlaylistOrder)

    local trackPath = newPlaylist.tracks[nextTrackIndex]
    if trackPath == nil then
        error(string.format("Can not fetch track with index %s from playlist '%s'.", nextTrackIndex, newPlaylist.id))
    else
        currentTrack = trackPath
        ambient.streamMusic(trackPath, newPlaylist.fadeOut or FadeOutDuration)

        if newPlaylist.playOneTrack then
            newPlaylist.deactivateAfterEnd = true
        end
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
        ('Playlist Interrupt Modes Fell Through!\nOld Playlist: %s Interrupt Mode: %s\nNew Playlist: %s InterruptMode: %s')
        :format(
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
            PlaylistSkipFormatStr:format(
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

if activePlaylistSettings:get('BattleActive') == nil then activePlaylistSettings:set("BattleActive", true) end
if activePlaylistSettings:get('ExploreActive') == nil then activePlaylistSettings:set("ExploreActive", true) end

MusicManager.registerPlaylist {
    id = "Battle",
    priority = battlePriority,
    randomize = true,

    isValidCallback = function(playback)
        return playback.state.isInCombat and activePlaylistSettings:get("BattleActive")
    end,
}

MusicManager.registerPlaylist {
    id = "Explore",
    priority = explorePriority,
    randomize = true,

    isValidCallback = function(playback)
        return not playback.state.isInCombat and activePlaylistSettings:get("ExploreActive")
    end,
}

MusicManager.registerPlaylist {
    id = 'Special',
    priority = 50,
    playOneTrack = true,
    active = false,

    tracks = {},
}

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
                forceSkip = true
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
                ('Setting playlist %s to %s'):format(eventData.playlist, eventData.state)
            )

            MusicManager.setPlaylistActive(eventData.playlist, eventData.state)
        end,

        ---@param eventData S3maphoreStateChangeEventData
        S3maphoreMusicStopped = function(eventData)
            helpers.debugLog("Music stopped:", eventData.reason)

            MusicManager.updateBanner()
        end,

        ---@param eventData S3maphoreStateChangeEventData
        S3maphoreTrackChanged = function(eventData)
            helpers.debugLog("Track changed! Current playlist is:", eventData.playlistId, "Track:", eventData.trackName)

            MusicManager.updateBanner()
        end,

        ---@param hasCombatTargets boolean
        S3maphoreCombatTargetsUpdated = function(hasCombatTargets)
            PlaylistState.cellHasCombatTargets = hasCombatTargets
        end,

        S3maphoreCellDataUpdated = function(cellChangeData)
            PlaylistState.cellHasCombatTargets = cellChangeData.hasCombatTargets
            PlaylistState.staticList = cellChangeData.staticList

            local shouldUseName = self.cell.name ~= nil and self.cell.name ~= ''

            PlaylistState.cellIsExterior = self.cell.isExterior or self.cell:hasTag('QuasiExterior')
            PlaylistState.cellName = shouldUseName and self.cell.name:lower() or self.cell.id:lower()

            awaitingUpdate = false
        end,

        S3maphoreWeatherChanged = function(weatherName)
            helpers.debugLog(('weather changed to %s'):format(weatherName))

            PlaylistState.weather = weatherName
        end,
    }
}
