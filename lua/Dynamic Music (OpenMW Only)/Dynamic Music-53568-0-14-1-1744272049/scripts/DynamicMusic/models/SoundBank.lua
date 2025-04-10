local vfs = require('openmw.vfs')
local Playlist = require('scripts.DynamicMusic.core.Playlist')
local Track = require('scripts.DynamicMusic.models.Track')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')

---@class Soundbank
---@field cellNames [string]
---@field cellNamePatterns [string]
---@field cellNamePatternsExclude [string]
---@field combatTracks [Track]
---@field combatPlaylist any
---@field enemies [string]
---@field enemyFactions [string]
---@field exteriorOnly boolean
---@field explorePlaylist any
---@field hourOfDay [integer]
---@field id string
---@field interiorOnly boolean
---@field tracks [Track]
---@field regions [string]
---@field _hourOfDayDB table<integer,boolean>
---@
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
    soundbank.cellNamePatternsExclude = {}
    soundbank.enemies = {}
    soundbank.enemyFactions = {}
    soundbank.exteriorOnly = false
    soundbank.hourOfDay = {}
    soundbank.interiorOnly = false
    soundbank.regions = {}
    soundbank.tracks = {}
    soundbank.combatTracks = {}

    soundbank.countAvailableTracks = Soundbank.countAvailableTracks
    soundbank.getEnemies = Soundbank.getEnemies
    soundbank.getEnemyFactions = Soundbank.getEnemyFactions
    soundbank.isAllowedForEnemyName = Soundbank.isAllowedForEnemy
    soundbank.isAllowedForCellName = Soundbank.isAllowedForCellName
    soundbank.isAllowedForRegion = Soundbank.isAllowedForRegion
    soundbank.isAllowedForHourOfDay = Soundbank.isAllowedForHourOfDay
    soundbank.setCellNames = Soundbank.setCellNames
    soundbank.setCellNamePatterns = Soundbank.setCellNamePatterns
    soundbank.setCellNamePatternsExclude = Soundbank.setCellNamePatternsExclude
    soundbank.setEnemies = Soundbank.setEnemies
    soundbank.setEnemyFactions = Soundbank.setEnemyFactions
    soundbank.setExteriorOnly = Soundbank.setExteriorOnly
    soundbank.setCombatTracks = Soundbank.setCombatTracks
    soundbank.setHours = Soundbank.setHours
    soundbank.setInteriorOnly = Soundbank.setInteriorOnly
    soundbank.setRegions = Soundbank.setRegions
    soundbank.setTracks = Soundbank.setTracks

    return soundbank
end

---Returns the number of tracks of this soundbank that are actually playable.
---This means they must be reachable through the virtual filesystem..
---@param self Soundbank
---@return integer integer Number of available tracks.
function Soundbank.countAvailableTracks(self)
    local availableTracks = 0
    availableTracks = availableTracks + _countExistingTracks(self.tracks)
    availableTracks = availableTracks + _countExistingTracks(self.combatTracks)
    return availableTracks
end

---Returns the enemy names and/or Ids for which the soundbank is allowed.
---@param self Soundbank
---@return [string] allowedEnemies A list containing the allowed enemy IDs
function Soundbank.getEnemies(self)
    return self.enemies
end

---Returns the enemy faction IDs for which the soundbank is allowed.
---@param self Soundbank
---@return [string] allowedEnemyFactions A list containing the allowed enemy faction IDs.
function Soundbank.getEnemyFactions(self)
    return self.enemyFactions
end

---Returns if this soundbank is allowed to play for the given enemyname when in combat mode.
---@param self Soundbank
---@param enemy string The enemyname that should be checked.
---@return boolean bool
function Soundbank.isAllowedForEnemy(self, enemy)
    if #self.enemies == 0 then
        return false
    end

    for _, e in pairs(self.enemies) do
        if e == enemy then
            return true
        end
    end

    return false
end

---Returns if this soundbank is allowed to play for the given cellname.
---@param self Soundbank
---@param cellName string The cellname that should be checked.
---@return boolean bool
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

---Returns if this soundbank is allowed during the given ingame hour of day.
---@param self Soundbank
---@param hourOfDay integer The hour of the day (0-23) that should be checked.
---@return boolean bool
function Soundbank.isAllowedForHourOfDay(self, hourOfDay)
    local bool = not self._hourOfDayDB or self._hourOfDayDB[hourOfDay]
    return bool
end

---Returns if this soundbank is allowed to for a specific region
---@param self Soundbank
---@param region string The region ID that should be checked.
---@return boolean bool
function Soundbank.isAllowedForRegion(self, region)
    if not self.regions or TableUtils.countKeys(self.regions) == 0 then
        return true
    end

    for _, sbRegion in ipairs(self.regions) do
        if region == sbRegion then
            return true
        end
    end

    return false
end

---Sets the available exploration tracks for this soundbank.
---@param self Soundbank
---@param tracks table<Track> A list of tracks.
function Soundbank.setTracks(self, tracks)
    TableUtils.setAll(self.tracks, tracks)
    self.explorePlaylist = buildPlaylist(self.id .. "_explore", self.tracks)
end

---Sets the available combat tracks for this soundbank.
---@param self Soundbank
---@param tracks table<Track> A list of tracks.
function Soundbank.setCombatTracks(self, tracks)
    TableUtils.setAll(self.combatTracks, tracks)
    self.combatPlaylist = buildPlaylist(self.id .. "_combat", self.combatTracks)
end

---Sets the cellnames in which this soundbank is allowed to play.
---@param self Soundbank
---@param cellNames table<string> A list of cellnames.
function Soundbank.setCellNames(self, cellNames)
    TableUtils.setAll(self.cellNames, cellNames)
end

---Sets the cellname patterns in which this soundbank is allowed to play.
---@param self Soundbank
---@param cellNamePatterns table<string> A list of cellname patterns.
function Soundbank.setCellNamePatterns(self, cellNamePatterns)
    TableUtils.setAll(self.cellNamePatterns, cellNamePatterns)
end

---Sets the cellname patterns for which this soundbank should be excluded.
---@param self Soundbank
---@param cellNamePatternsExclude table<string> A list of cellname patterns.
function Soundbank.setCellNamePatternsExclude(self, cellNamePatternsExclude)
    TableUtils.setAll(self.cellNamePatternsExclude, cellNamePatternsExclude)
end

---Sets the enemynames for which this soundbank is allowed to play when in combat state.
---@param self Soundbank
---@param enemies table<string> A list of enemynames.
function Soundbank.setEnemies(self, enemies)
    TableUtils.setAll(self.enemies, enemies)
end

---Sets the enemy faction IDs for which this soundbank is allowed to play when in combat state.
---@param self Soundbank
---@param enemyFactions table<string> A list of faction IDs.
function Soundbank.setEnemyFactions(self, enemyFactions)
    TableUtils.setAll(self.enemyFactions, enemyFactions)
end

---Sets if this soundbank is only allowed to play in exterior cells.
---@param self Soundbank
---@param exteriorOnly boolean
function Soundbank.setExteriorOnly(self, exteriorOnly)
    self.exteriorOnly = exteriorOnly
end

---Sets the ingame hours of day when this soundbank is allowed to play..
---@param self Soundbank
---@param hours table<integer> Allowed hours of day (0-23).
function Soundbank.setHours(self, hours)
    TableUtils.setAll(self.hourOfDay, hours)
    self._hourOfDayDB = nil

    if #self.hourOfDay == 0 then
        return
    end

    self._hourOfDayDB = {}
    for _, hour in pairs(self.hourOfDay) do
        self._hourOfDayDB[hour] = true
    end
end

---Sets if this soundbank is only allowed to play in interior cells.
---@param self Soundbank
---@param interiorOnly boolean
function Soundbank.setInteriorOnly(self, interiorOnly)
    self.interiorOnly = interiorOnly
end

---Sets the regions where this soundbank is allowed to play.
---@param self Soundbank
---@param regions table<string> A list of region IDs patterns.
function Soundbank.setRegions(self, regions)
    TableUtils.setAll(self.regions, regions)
end

Soundbank.Decoder = {
    fromTable = function(soundbankData)
        local id = soundbankData.id
        local start = string.find(id, "/[^/]*$")

        if start then
            id = string.sub(id, start + 1)
        end

        local regions = {}
        if soundbankData.regionNames then
            TableUtils.addAll(regions, soundbankData.regionNames)
        end
        if soundbankData.regions then
            TableUtils.addAll(regions, soundbankData.regions)
        end

        local enemies = {}
        if soundbankData.enemyNames then
            TableUtils.addAll(enemies, soundbankData.enemyNames)
        end
        if soundbankData.enemies then
            TableUtils.addAll(enemies, soundbankData.enemies)
        end

        local enemyFactions = {}
        if soundbankData.enemyFactions then
            TableUtils.addAll(enemyFactions, soundbankData.enemyFactions)
        end

        local soundbank = Soundbank.Create(id)
        soundbank:setTracks(TableUtils.map(soundbankData.tracks or {}, Track.Decoder.fromTable))
        soundbank:setCombatTracks(TableUtils.map(soundbankData.combatTracks or {}, Track.Decoder.fromTable))
        soundbank:setExteriorOnly(soundbankData.exteriorOnly or false)
        soundbank:setCellNames(soundbankData.cellNames or {})
        soundbank:setCellNamePatterns(soundbankData.cellNamePatterns or {})
        soundbank:setCellNamePatternsExclude(soundbankData.cellNamePatternsExclude or {})
        soundbank:setEnemies(enemies)
        soundbank:setEnemyFactions(enemyFactions)
        soundbank:setHours(soundbankData.hourOfDay or {})
        soundbank:setInteriorOnly(soundbankData.interiorOnly or false)
        soundbank:setRegions(regions)
        return soundbank
    end
}

return Soundbank
