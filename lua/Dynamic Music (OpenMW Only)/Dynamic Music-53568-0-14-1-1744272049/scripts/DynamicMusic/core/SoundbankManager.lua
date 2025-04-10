local GameState = require('scripts.DynamicMusic.core.GameState')
local GlobalData = require('scripts.DynamicMusic.core.GlobalData')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local TableUtils = require('scripts.DynamicMusic.utils.TableUtils')
local Log = require('scripts.DynamicMusic.core.Logger')

local SOUNDBANKDB_SECTIONS = {
    ALLOWED_CELLS = "allowed_cells",
    ALLOWED_REGIONS = "ALLOWED_REGIONS",
    ALLOWED_ENEMIES = "allowed_enemies",
    ALLOWED_ENEMY_FACTIONS = "allowed_enemy_factions"
}

---@class SoundbankManager
---@field soundbanks [Soundbank]
---@field gameState GameState
---@field _soundbankDatabase any
local SoundbankManager = {}

---Creates a new SoundbankManager.
---@param soundbanks table<Soundbank>
---@param gameState GameState
---@return SoundbankManager
function SoundbankManager.Create(soundbanks, gameState)
    local soundbankManager = {}
    soundbankManager.gameState = gameState
    soundbankManager.addSoundbank = SoundbankManager.addSoundbank
    soundbankManager.isSoundbankAllowed = SoundbankManager.isSoundbankAllowed

    soundbankManager.soundbanks = soundbanks
    soundbankManager._soundbankDatabase = {}

    for _, soundbank in pairs(soundbanks) do
        soundbankManager:addSoundbank(soundbank)
    end

    return soundbankManager
end

---Adds a new soundbank to the manager.
---@param soundbank Soundbank
function SoundbankManager.addSoundbank(self, soundbank)
    local allowedCells = {}
    for _, cellName in pairs(GlobalData.cellNames) do
        if soundbank:isAllowedForCellName(cellName) then
            allowedCells[cellName] = true
        end
    end

    local allowedRegions = {}
    for _, region in pairs(GlobalData.regionNames) do
        if soundbank:isAllowedForRegion(region) then
            allowedRegions[region] = true
        end
    end

    local allowedEnemies = {}
    for _, enemy in pairs(soundbank:getEnemies()) do
        allowedEnemies[enemy] = true
    end

    local allowedEnemyFactions = {}
    for _, enemyFaction in pairs(soundbank:getEnemyFactions()) do
        allowedEnemyFactions[enemyFaction] = true
    end

    local dbEntry = {}
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES] = allowedEnemies
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_CELLS] = allowedCells
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_REGIONS] = allowedRegions
    dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMY_FACTIONS] = allowedEnemyFactions

    self._soundbankDatabase[soundbank] = dbEntry
end

---Checks if the soundbank is allowed to play for the current gamestate.
---@param self SoundbankManager
---@param soundbank Soundbank
---@return boolean
function SoundbankManager.isSoundbankAllowed(self, soundbank)
    if not soundbank then
        return false
    end

    if not soundbank:isAllowedForHourOfDay(self.gameState.hourOfDay.current) then
        return false
    end

    if soundbank.interiorOnly and self.gameState.exterior.current then
        return false
    end

    if soundbank.exteriorOnly and not self.gameState.exterior.current then
        return false
    end

    if self.gameState.playerState.current == PlayerStates.explore then
        if #soundbank.tracks == 0 then
            return false
        end
    end

    if self.gameState.playerState.current == PlayerStates.combat then
        if #soundbank.combatTracks == 0 then
            return false
        end
    end

    local dbEntry = self._soundbankDatabase[soundbank]
    if #soundbank.regions > 0 and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_REGIONS][self.gameState.regionName.current] then
        return false
    end

    if (#soundbank.cellNames > 0 or #soundbank.cellNamePatterns > 0) and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_CELLS][self.gameState.cellName.current] then
        return false
    end

    local firstHostile = TableUtils.getFirstElement(GlobalData.hostileActors)
    if #soundbank.enemies > 0 and firstHostile and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES][firstHostile.name] and not dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMIES][firstHostile.id]then
        return false
    end


    if firstHostile and firstHostile.factions and #soundbank.enemyFactions > 0 then
        local hostileFactionAllowed = false

        for _, faction in ipairs(firstHostile.factions) do
            Log.debug(string.format("check firstHostile faction: %s", faction))

            if dbEntry[SOUNDBANKDB_SECTIONS.ALLOWED_ENEMY_FACTIONS][faction] then
                hostileFactionAllowed = true
            end
        end

        return hostileFactionAllowed
    end

    if soundbank.id == "DEFAULT" then
        return false
    end

    return true
end

return SoundbankManager
