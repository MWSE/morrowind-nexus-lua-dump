local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local MusicPlayer = require('scripts.DynamicMusic.core.MusicPlayer')
local Settings = require('scripts.DynamicMusic.core.Settings')
local Log = require('scripts.DynamicMusic.core.Logger')
local Property = require('scripts.DynamicMusic.core.Property')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')
local StringUtils = require('scripts.DynamicMusic.utils.StringUtils')
local SoundbankManager = require('scripts.DynamicMusic.core.SoundbankManager')
local SoundbankUtils = require('scripts.DynamicMusic.utils.SoundbankUtils')

Log.info("loading DEFAULT soundbank")
local DEFAULT_SOUNDBANK = require('scripts.DynamicMusic.core.DefaultSoundbank')
Log.info(string.format("DEFAULT soundbank has %s available tracks", DEFAULT_SOUNDBANK:countAvailableTracks()))

local SOUNDBANK_DIRECTORY = "scripts/DynamicMusic/soundbanks"

---@class DynamicMusic
---@field context Context
---@field soundbanks table<Soundbank>
---@field playlistProperty Property A playlist property.
---@field initialized boolean
---@field soundbankManager SoundbankManager
---@field _delayTime number | nil
local DynamicMusic = {}

---Creates a new DynamicMusic instance
---@param context Context
---@return DynamicMusic DynamicMusic A DynamicMusic instance.
function DynamicMusic.Create(context)
    local dynamicMusic = {}

    --fields
    dynamicMusic.context = context
    dynamicMusic.sounbankdb = {}
    dynamicMusic.playlistProperty = Property.Create()
    dynamicMusic.initialized = false
    dynamicMusic.soundbanks = {}
    dynamicMusic.soundbankManager = nil
    dynamicMusic._delayTime = nil


    --functions
    dynamicMusic.initialize = DynamicMusic.initialize
    dynamicMusic.isSoundbankAllowed = DynamicMusic.isSoundbankAllowed
    dynamicMusic.fetchSoundbank = DynamicMusic.fetchSoundbank
    dynamicMusic.newMusic = DynamicMusic.newMusic
    dynamicMusic.update = DynamicMusic.update
    dynamicMusic._fetchDelayTime = DynamicMusic._fetchDelayTime



    return dynamicMusic
end

function DynamicMusic.fetchSoundbank(self)
    local soundbank = nil

    for index = #self.soundbanks, 1, -1 do
        if self:isSoundbankAllowed(self.soundbanks[index]) then
            soundbank = self.soundbanks[index]
            break
        end
    end

    local useDefaultSoundbank = false
    useDefaultSoundbank = Settings.getValue(Settings.KEYS.GENERAL_USE_DEFAULT_SOUNDBANK)

    if not soundbank and useDefaultSoundbank then
        Log.info("using DEFAULT soundbank")
        soundbank = DEFAULT_SOUNDBANK
    end

    return soundbank
end

function DynamicMusic.initialize(self)
    if self.initialized then
        return
    end

    Log.info("DynamicMusic Settings")
    for _, v in pairs(Settings.KEYS) do
        Log.info(v .. ": " .. tostring(Settings.getValue(v)))
    end

    self.soundbanks = SoundbankUtils.collectSoundbanks(SOUNDBANK_DIRECTORY)
    self.soundbankManager = SoundbankManager.Create(self.soundbanks, self.context.gameState)

    local ignoredEnemies = Settings.getValue(Settings.KEYS.COMBAT_ENEMIES_IGNORE)
    for _, enemyId in pairs(StringUtils.split(ignoredEnemies, ",")) do
        self.context.ignoreEnemies[enemyId] = enemyId
    end

    local includedEnemies = Settings.getValue(Settings.KEYS.COMBAT_ENEMIES_INCLUDE)
    for _, enemyId in pairs(StringUtils.split(includedEnemies, ",")) do
        self.context.includeEnemies[enemyId] = enemyId
    end

    self.initialized = true
end

function DynamicMusic.isSoundbankAllowed(self, soundbank)
    return self.soundbankManager:isSoundbankAllowed(soundbank)
end

function DynamicMusic.newMusic(self, options)
    Log.info("new music requested")

    local force = options and options.force or not self.context.ambient.isMusicPlaying()
    local soundbank = self:fetchSoundbank()
    local newPlaylist = nil

    if not soundbank then
        Log.info("no matching soundbank found")
        self.context.ambient.streamMusic('')
        return
    end

    if self.context.gameState.playerState.current == PlayerStates.explore and soundbank.explorePlaylist then
        newPlaylist = soundbank.explorePlaylist
    end

    if self.context.gameState.playerState.current == PlayerStates.combat and soundbank.combatPlaylist then
        newPlaylist = soundbank.combatPlaylist
    end

    if not force and newPlaylist == self.playlistProperty:getValue() then
        Log.info("playlist already playing so continue with current")
        return
    end

    if newPlaylist then
        Log.info("activating playlist: " .. newPlaylist.id)
        MusicPlayer.playPlaylist(newPlaylist, { force = force })
        self.playlistProperty:setValue(newPlaylist)
        return
    end
end

function DynamicMusic.info(self)
    local soundbanks = 0
    if self.soundbanks then
        soundbanks = #self.soundbanks
    end

    Log.info("=== DynamicMusic Info ===")
    Log.info("soundbanks: " .. soundbanks)
    for _, sb in ipairs(self.soundbanks) do
        Log.info("soundbank.id: " .. tostring(sb.id))
        Log.info("soundbank.combatTracks: " .. #sb.combatTracks)
        Log.info("sondbank.cellNamePatterns: " .. TableUtils.countKeys(sb.cellNamePatterns))
        Log.info("soundbank,regions: " .. TableUtils.countKeys(sb.regions))
    end
end

function DynamicMusic.update(self, dt)
    MusicPlayer.update(dt)
    local gameState = self.context.gameState

    if self._delayTime and self._delayTime <= 0 then
        self._delayTime = nil
        self:newMusic()
        return
    end

    if self._delayTime then
        self._delayTime = self._delayTime - dt
    end

    if gameState:hasGameStateChanged() then
        self._delayTime = self:_fetchDelayTime()

        if self._delayTime then
            Log.info(string.format("delaying new music for %d seconds", self._delayTime))
            return
        end

        self:newMusic()
    end
end

function DynamicMusic._fetchDelayTime(self)
    local gameState = self.context.gameState

    -- no delay if we are not in an exterior cell
    if not gameState.exterior.current then
        return nil
    end

    -- no delay if we are/were in a combat state.
    if gameState.playerState.current == PlayerStates.combat or gameState.playerState.previous == PlayerStates.combat then
        return nil
    end

    -- no delay if we switched between exterior to interior and vice versa.
    if gameState.exterior.previous ~= gameState.exterior.current then
        return nil
    end

    local delay = Settings.getValue(Settings.KEYS.GENERAL_EXTERIOR_DELAY)
    if delay > 0 then
        return delay
    end

    return nil
end

return DynamicMusic
