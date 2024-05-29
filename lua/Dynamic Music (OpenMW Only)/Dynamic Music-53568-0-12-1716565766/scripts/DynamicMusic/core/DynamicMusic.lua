local vfs = require('openmw.vfs')
local GameState = require('scripts.DynamicMusic.core.GameState')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local IndexBox = require('scripts.DynamicMusic.core.IndexBox')
local SoundBank = require('scripts.DynamicMusic.core.SoundBank')
local Music = require('openmw.interfaces').Music

local DynamicMusic = {}

DynamicMusic.initialized = false
DynamicMusic.soundBanks = {}
DynamicMusic.sondBanksPath = "scripts/DynamicMusic/soundBanks"

local DEFAULT_SOUNDBANK = require('scripts.DynamicMusic.core.DefaultSoundBank')

local function collectSoundBanks()
    print("collecting soundBanks from: " .. DynamicMusic.sondBanksPath)

    local soundBanks = {}
    for file in vfs.pathsWithPrefix(DynamicMusic.sondBanksPath) do
        file = file.gsub(file, ".lua", "")
        local soundBank = require(file)

        if not soundBank.id then
            soundBank.id = file
        end

        soundBank = SoundBank.CreateFromTable(soundBank)

        if soundBank:countAvailableTracks() > 0 then
            table.insert(soundBanks, soundBank)
            print(string.format("loaded soundbank: %s", file))
        end
    end

    return soundBanks
end

local _cellNameIndex = nil
local _regionNameIndex = nil
local _enemyRecordIdIndex = nil
local _hostileActors = {}

local function _count(table)
    local cnt = 0
    for _, e in pairs(table) do
        cnt = cnt + 1
    end
    return cnt
end

local function _getFirstElement(table)
    for _, e in pairs(table) do
        return e
    end
end

function DynamicMusic._collectEnemyNames()
    local enemyNames = {}
    for _, sb in pairs(DynamicMusic.soundBanks) do
        if sb.enemyNames and #sb.enemyNames > 0 then
            for _, e in pairs(sb.enemyNames) do
                if not enemyNames[e] then
                    enemyNames[e] = e
                end
            end
        end
    end

    return enemyNames
end

function DynamicMusic.initialize(cellNames, regionNames, hostileActors)
    if DynamicMusic.initialized then
        return
    end

    _hostileActors = hostileActors
    DynamicMusic.soundBanks = collectSoundBanks()
    local enemyNames = DynamicMusic._collectEnemyNames()

    _cellNameIndex = IndexBox.Create(cellNames, DynamicMusic.soundBanks, DynamicMusic.isSoundBankAllowedForCellName)
    _regionNameIndex = IndexBox.Create(regionNames, DynamicMusic.soundBanks, DynamicMusic
        .isSoundBankAllowedForRegionName)
    _enemyRecordIdIndex = IndexBox.Create(enemyNames, DynamicMusic.soundBanks,
        DynamicMusic.isSoundBankAllowedForEnemyName)

    DynamicMusic.initialized = true
end

function DynamicMusic.isSoundBankAllowed(soundBank)
    if not soundBank then
        return false
    end

    if soundBank.interiorOnly and GameState.exterior.current then
        return false
    end

    if soundBank.exteriorOnly and not GameState.exterior.current then
        return false
    end

    if GameState.playerState.current == PlayerStates.explore then
        if not soundBank.tracks or #soundBank.tracks == 0 then
            return false
        end
    end

    if GameState.playerState.current == PlayerStates.combat then
        if not soundBank.combatTracks or #soundBank.combatTracks == 0 then
            return false
        end

        local firstHostile = _getFirstElement(_hostileActors)

        if soundBank.enemyNames and not DynamicMusic.isSoundBankAllowedForEnemyName(firstHostile.name, soundBank) then
            return false
        end
    end

    if (soundBank.cellNames or soundBank.cellNamePatterns) and not DynamicMusic.isSoundBankAllowedForCellName(GameState.cellName.current, soundBank) then
        return false
    end

    if soundBank.regionNames and not DynamicMusic.isSoundBankAllowedForRegionName(GameState.regionName.current, soundBank) then
        return false
    end

    -- not needed but still leave this here in case of old DEFAULT soundbank is still present for some users
    if soundBank.id == "DEFAULT" then
        return false
    end

    return true
end

function DynamicMusic.isSoundBankAllowedForEnemyName(enemyName, soundBank)
    if _enemyRecordIdIndex then
        return _enemyRecordIdIndex:contains(enemyName, soundBank)
    end

    if not soundBank.enemyNames then
        return false
    end

    for _, e in pairs(soundBank.enemyNames) do
        if e == enemyName then
            return true
        end
    end

    return false
end

function DynamicMusic.isSoundBankAllowedForCellName(cellName, soundBank)
    if _cellNameIndex then
        return _cellNameIndex:contains(cellName, soundBank)
    end

    if soundBank.cellNamePatternsExclude then
        for _, cellNameExcludePattern in ipairs(soundBank.cellNamePatternsExclude) do
            if string.find(cellName, cellNameExcludePattern) then
                return false
            end
        end
    end

    if soundBank.cellNames then
        for _, allowedCellName in ipairs(soundBank.cellNames) do
            if cellName == allowedCellName then
                return true
            end
        end
    end

    if soundBank.cellNamePatterns then
        for _, cellNamePattern in ipairs(soundBank.cellNamePatterns) do
            if string.find(cellName, cellNamePattern) then
                return true
            end
        end
    end
end

function DynamicMusic.isSoundBankAllowedForRegionName(regionName, soundBank)
    if not soundBank.regionNames then
        return false
    end

    if _regionNameIndex then
        return _regionNameIndex:contains(regionName, soundBank) -- [regionName] and _regionNameIndex[regionName][soundBank]
    end

    for _, allowedRegionName in ipairs(soundBank.regionNames) do
        if regionName == allowedRegionName then
            return true
        end
    end

    return false
end

local function fetchSoundbank()
    local soundbank = nil

    for index = #DynamicMusic.soundBanks, 1, -1 do
        if DynamicMusic.isSoundBankAllowed(DynamicMusic.soundBanks[index]) then
            soundbank = DynamicMusic.soundBanks[index]
            break
        end
    end

    if not soundbank then
        soundbank = DEFAULT_SOUNDBANK
    end

    return soundbank
end

function DynamicMusic.newMusic()
    print("new music requested")

    local soundBank = fetchSoundbank()
    local newPlaylist = nil

    if GameState.playerState.current == PlayerStates.explore and soundBank.explorePlaylist then
        newPlaylist = soundBank.explorePlaylist
    end

    if GameState.playerState.current == PlayerStates.combat and soundBank.combatPlaylist then
        newPlaylist = soundBank.combatPlaylist
    end

    if newPlaylist then
        if GameState.playlist.current then
            Music.setPlaylistActive(GameState.playlist.current.id, false)
        end

        print("activating playlist: " .. newPlaylist.id)

        Music.setPlaylistActive(newPlaylist.id, true)
        GameState.soundBank.current = soundBank
        GameState.playlist.current = newPlaylist
        return
    end
end

return DynamicMusic
