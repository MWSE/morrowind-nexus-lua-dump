local vfs = require('openmw.vfs')
local Playlist = require('scripts.DynamicMusic.core.Playlist')
local Track = require('scripts.DynamicMusic.models.Track')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')

local Soundbank = {}

local function buildPlaylist(id, tracks)
    local playlistTracks = {}

    for _, track in pairs(tracks) do
        table.insert(playlistTracks, track)
    end

    local playlistData = {
        id = id,
        --        priority = Settings.getValue(Settings.KEYS.GENERAL_PLAYLIST_PRIORITY),
        tracks = playlistTracks
    }

    return Playlist.Create(playlistData)
end

local function _countExistingTracks(tracks)
    local existingTracks = 0
    for _, track in pairs(tracks) do
        if track:exists() then
            existingTracks = existingTracks + 1
        end
    end

    return existingTracks
end

function Soundbank.Create(id)
    if not id then
        error("id not specified", 2)
    end

    local soundbank = {}
    soundbank.id = id
    soundbank._hourOfDayDB = nil
    soundbank.cellNames = {}
    soundbank.cellNamePatterns = {}
    soundbank.enemyNames = {}
    soundbank.exteriorOnly = false
    soundbank.hourOfDay = {}
    soundbank.interiorOnly = false
    soundbank.regionNames = {}
    soundbank.tracks = {}
    soundbank.combatTracks = {}

    soundbank.countAvailableTracks = Soundbank.countAvailableTracks
    soundbank.isAllowedForEnemyName = Soundbank.isAllowedForEnemyName
    soundbank.isAllowedForCellName = Soundbank.isAllowedForCellName
    soundbank.isAllowedForRegionId = Soundbank.isAllowedForRegionId
    soundbank.isAllowedForHourOfDay = Soundbank.isAllowedForHourOfDay
    soundbank.setCellNames = Soundbank.setCellNames
    soundbank.setCellNamePatterns = Soundbank.setCellNamePatterns
    soundbank.setEnemyNames = Soundbank.setEnemyNames
    soundbank.setExteriorOnly = Soundbank.setExteriorOnly
    soundbank.setCombatTracks = Soundbank.setCombatTracks
    soundbank.setHours = Soundbank.setHours
    soundbank.setInteriorOnly = Soundbank.setInteriorOnly
    soundbank.setRegionNames = Soundbank.setRegionNames
    soundbank.setTracks = Soundbank.setTracks

    return soundbank
end

function Soundbank.countAvailableTracks(self)
    local availableTracks = 0
    availableTracks = availableTracks + _countExistingTracks(self.tracks)
    availableTracks = availableTracks + _countExistingTracks(self.combatTracks)
    return availableTracks
end

function Soundbank.isAllowedForEnemyName(self, enemyName)
    if #self.enemyNames == 0 then
        return false
    end

    for _, e in pairs(self.enemyNames) do
        if e == enemyName then
            return true
        end
    end

    return false
end

function Soundbank.isAllowedForCellName(self, cellName)
    if self.cellNamePatternsExclude then
        for _, cellNameExcludePattern in ipairs(self.cellNamePatternsExclude) do
            if string.find(cellName, cellNameExcludePattern) then
                return false
            end
        end
    end

    if self.cellNames then
        for _, allowedCellName in ipairs(self.cellNames) do
            if cellName == allowedCellName then
                return true
            end
        end
    end

    if self.cellNamePatterns and TableUtils.countKeys(self.cellNamePatterns) > 0 then
        for _, cellNamePattern in ipairs(self.cellNamePatterns) do
            if string.find(cellName, cellNamePattern) then
                return true
            end
        end
    end

    return false
end

function Soundbank.isAllowedForHourOfDay(self, hourOfDay)
    local bool = not self._hourOfDayDB or self._hourOfDayDB[hourOfDay]
    return bool
end

function Soundbank.isAllowedForRegionId(self, regionId)
    if not self.regionNames or TableUtils.countKeys(self.regionNames) == 0 then
        return true
    end

    for _, sbRegionId in ipairs(self.regionNames) do
        if regionId == sbRegionId then
            return true
        end
    end

    return false
end

function Soundbank.setTracks(self, tracks)
    TableUtils.setAll(self.tracks, tracks)
    self.explorePlaylist = buildPlaylist(self.id .. "_explore", self.tracks)
end

function Soundbank.setCombatTracks(self, tracks)
    TableUtils.setAll(self.combatTracks, tracks)
    self.combatPlaylist = buildPlaylist(self.id .. "_combat", self.combatTracks)
end

function Soundbank.setCellNames(self, cellNames)
    TableUtils.setAll(self.cellNames, cellNames)
end

function Soundbank.setCellNamePatterns(self, cellNamePatterns)
    TableUtils.setAll(self.cellNamePatterns, cellNamePatterns)
end

function Soundbank.setEnemyNames(self, enemyNames)
    TableUtils.setAll(self.enemyNames, enemyNames)
end

function Soundbank.setExteriorOnly(self, exteriorOnly)
    self.exteriorOnly = exteriorOnly
end

function Soundbank.setHours(self, hours)
    TableUtils.setAll(self.hourOfDay, hours)
    self._hourOfDayDB = nil

    if #self.hourOfDay ==0 then
        return
    end

    self._hourOfDayDB = {}
    for _, hour in pairs(self.hourOfDay) do
        self._hourOfDayDB[hour] = true
    end
end

function Soundbank.setInteriorOnly(self, interiorOnly)
    self.interiorOnly = interiorOnly
end

function Soundbank.setRegionNames(self, regionNames)
    TableUtils.setAll(self.regionNames, regionNames)
end

Soundbank.Decoder = {
    fromTable = function(soundbankData)
        local soundbank = Soundbank.Create(soundbankData.id)
        soundbank:setTracks(TableUtils.map(soundbankData.tracks or {}, Track.Decoder.fromTable))
        soundbank:setCombatTracks(TableUtils.map(soundbankData.combatTracks or {}, Track.Decoder.fromTable))
        soundbank:setExteriorOnly(soundbankData.exteriorOnly or false)
        soundbank:setCellNames(soundbankData.cellNames or {})
        soundbank:setCellNamePatterns(soundbankData.cellNamePatterns or {})
        soundbank:setEnemyNames(soundbankData.enemyNames or {})
        soundbank:setHours(soundbankData.hourOfDay or {})
        soundbank:setInteriorOnly(soundbankData.interiorOnly or false)
        soundbank:setRegionNames(soundbankData.regionNames or {})
        return soundbank
    end
}

return Soundbank
