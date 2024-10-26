local vfs = require('openmw.vfs')
local GameState = require('scripts.DynamicMusic.core.GameState')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local Soundbank = require('scripts.DynamicMusic.models.Soundbank')
local MusicPlayer = require('scripts.DynamicMusic.core.MusicPlayer')
local Settings = require('scripts.DynamicMusic.core.Settings')
local Property = require('scripts.DynamicMusic.core.Property')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')
local StringUtils = require('scripts.DynamicMusic.utils.StringUtils')
local SoundbankManager = require('scripts.DynamicMusic.core.SoundbankManager')
local ambient = require('openmw.ambient')

local DEFAULT_SOUNDBANK = require('scripts.DynamicMusic.core.DefaultSoundbank')

local DynamicMusic = {}
DynamicMusic.sounbankdb = {}
DynamicMusic.playlistProperty = Property.Create()
DynamicMusic.initialized = false
DynamicMusic.soundbanks = {}
DynamicMusic.sondBanksPath = "scripts/DynamicMusic/soundbanks"
DynamicMusic.ignoreEnemies = {}
DynamicMusic.includeEnemies = {}

local function collectSoundbanks()
    print("collecting soundbanks from: " .. DynamicMusic.sondBanksPath)

    local soundbanks = {}
    for file in vfs.pathsWithPrefix(DynamicMusic.sondBanksPath) do
        file = file.gsub(file, ".lua", "")


        local soundbank = require(file)

        if not soundbank.id or soundbank.id ~= "DEFAULT" then
            soundbank.id = file.gsub(file, DynamicMusic.sondBanksPath, "")

            soundbank = Soundbank.Decoder.fromTable(soundbank)

            if soundbank:countAvailableTracks() > 0 then
                table.insert(soundbanks, soundbank)
                print("soundbank loaded: " .. file)
            else
                print('no tracks available: ' .. file)
            end
        end
    end

    return soundbanks
end

local function fetchSoundbank()
    local soundbank = nil

    for index = #DynamicMusic.soundbanks, 1, -1 do
        if DynamicMusic.isSoundbankAllowed(DynamicMusic.soundbanks[index]) then
            soundbank = DynamicMusic.soundbanks[index]
            break
        end
    end

    local useDefaultSoundbank = false
    useDefaultSoundbank = Settings.getValue(Settings.KEYS.GENERAL_USE_DEFAULT_SOUNDBANK)

    if not soundbank and useDefaultSoundbank then
        print("using DEFAULT soundbank")
        soundbank = DEFAULT_SOUNDBANK
    end

    return soundbank
end

function DynamicMusic.initialize(cellNames, regionNames, hostileActors)
    if DynamicMusic.initialized then
        return
    end

    DynamicMusic.soundbanks = collectSoundbanks()
    DynamicMusic.soundbankManager = SoundbankManager.Create(DynamicMusic.soundbanks, cellNames, regionNames,  hostileActors)

    local ignoredEnemies = Settings.getValue(Settings.KEYS.COMBAT_ENEMIES_IGNORE)
    for _, enemyId in pairs(StringUtils.split(ignoredEnemies, ",")) do
        DynamicMusic.ignoreEnemies[enemyId] = enemyId
    end

    local includedEnemies = Settings.getValue(Settings.KEYS.COMBAT_ENEMIES_INCLUDE)
    for _, enemyId in pairs(StringUtils.split(includedEnemies, ",")) do
        DynamicMusic.includeEnemies[enemyId] = enemyId
    end

    DynamicMusic.initialized = true
end

function DynamicMusic.isSoundbankAllowed(soundbank)
    return DynamicMusic.soundbankManager:isSoundbankAllowed(soundbank)
end

function DynamicMusic.newMusic(options)
    print("new music requested")

    local force = options and options.force or not ambient.isMusicPlaying()
    local soundbank = fetchSoundbank()
    local newPlaylist = nil

    if not soundbank then
        print("no matching soundbank found")
        ambient.streamMusic('')
        return
    end

    if GameState.playerState.current == PlayerStates.explore and soundbank.explorePlaylist then
        newPlaylist = soundbank.explorePlaylist
    end

    if GameState.playerState.current == PlayerStates.combat and soundbank.combatPlaylist then
        newPlaylist = soundbank.combatPlaylist
    end

    if not force and newPlaylist == DynamicMusic.playlistProperty:getValue() then
        print("playlist already playing so continue with current")
        return
    end

    if newPlaylist then
        print("activating playlist: " .. newPlaylist.id)
        MusicPlayer.playPlaylist(newPlaylist, { force = force })
        GameState.soundbank.current = soundbank
        DynamicMusic.playlistProperty:setValue(newPlaylist)
        return
    end
end

function DynamicMusic.info()
    local soundbanks = 0
    if DynamicMusic.soundbanks then
        soundbanks = #DynamicMusic.soundbanks
    end

    print("=== DynamicMusic Info ===")
    print("soundbanks: " .. soundbanks)
    for _, sb in ipairs(DynamicMusic.soundbanks) do
        print("soundbank.id: " .. tostring(sb.id))
        if sb.combatTracks then
            print("soundbank.combatTracks: " .. #sb.combatTracks)
        end

        if (sb.cellNamePatterns) then
            print("sondbank.cellNamePatterns: " .. TableUtils.countKeys(sb.cellNamePatterns))
        end
    end
end

function DynamicMusic.update(deltaTime)
    MusicPlayer.update(deltaTime)
end

return DynamicMusic
