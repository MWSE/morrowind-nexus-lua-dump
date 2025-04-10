local core = require('openmw.core')

local GlobalData = require('scripts.DynamicMusic.core.GlobalData')
local Log = require('scripts.DynamicMusic.core.Logger')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local Settings = require('scripts.DynamicMusic.core.Settings')
local types = require('openmw.types')

---@class GameState
---@field context Context
---@field hourOfDay any
---@field exterior any
---@field cellName any
---@field playtime any
---@field regionName any
---@field playerState any
local GameState = {}

---Creates a new GameState instance
---@param context Context
---@return GameState gameState A GameState instance.
function GameState.Create(context)
  local gameState = {}

  --fields
  gameState.context = context
  gameState.hourOfDay = {
    current = nil,
    previous = nil
  }
  gameState.exterior = {
    current = nil,
    previous = nil
  }
  gameState.cellName = {
    current = nil,
    previous = nil
  }
  gameState.playtime = {
    current = 0,
    previous = 0
  }
  gameState.regionName = {
    current = nil,
    previous = nil
  }
  gameState.playerState = {
    current = nil,
    previous = nil
  }

  --functions
  gameState.getPlayerState = GameState.getPlayerState
  gameState.hasGameStateChanged = GameState.hasGameStateChanged
  gameState.isCombatState = GameState.isCombatState
  gameState.update = GameState.update

  return gameState
end

function GameState.update(self, dt)
  local player = self.context:getPlayer()
  local hourOfDay = math.floor((core.getGameTime() / 3600) % 24)

  self.exterior.previous = self.exterior.current
  self.cellName.previous = self.cellName.current
  self.playtime.previous = self.playtime.current
  self.playerState.previous = self.playerState.current
  self.regionName.previous = self.regionName.current
  self.hourOfDay.previous = self.hourOfDay.current

  self.exterior.current = player.cell and player.cell.isExterior
  self.cellName.current = player.cell and player.cell.name or ""
  self.playtime.current = os.time()
  self.regionName.current = GameState._fetchRegion(self, self.exterior.current)
  self.playerState.current = self:getPlayerState()
  self.hourOfDay.current = hourOfDay
end

function GameState.hasGameStateChanged(self)
  if self.playerState.previous ~= self.playerState.current then
    Log.debug("change playerState: " .. self.playerState.current)
    return true
  end

  if not self.context.ambient.isMusicPlaying() then
    return true
  end

  if self.regionName.current ~= self.regionName.previous then
    Log.debug("change regionName ")
    if self.exterior.current and self.exterior.previous then
      return true
    end
  end

  if self.cellName.current ~= self.cellName.previous then
    Log.debug("change celName")
    return true
  end

  if self.hourOfDay.current ~= self.hourOfDay.previous then
    Log.debug(string.format("hour of day changed from %i to %i", self.hourOfDay.previous, self.hourOfDay.current))
    return true
  end

  return false
end

function GameState.isCombatState(self)
  if not Settings.getValue(Settings.KEYS.COMBAT_PLAY_COMBAT_MUSIC) then
    return false
  end

  local player = self.context:getPlayer()

  local playerLevel = types.Actor.stats.level(player).current
  local minLevelEnemy = Settings.getValue(Settings.KEYS.COMBAT_MIN_ENEMY_LEVEL)
  local minLevelDifference = Settings.getValue(Settings.KEYS.COMBAT_MIN_LEVEL_DIFFERENCE)
  local respectMinLevelDifference = Settings.getValue(Settings.KEYS.COMBAT_ENEMIES_IGNORE_RESPECT_LEVEL_DIFFERENCE)

  for _, hostile in pairs(GlobalData.hostileActors) do
    local actor = hostile.actor
    local hostileLevel = types.Actor.stats.level(actor).current
    local playerLevelAdvantage = playerLevel - hostileLevel
    local inProcessingRange = types.Actor.isInActorsProcessingRange(actor)

    if not inProcessingRange then
      goto continue
    end

    if self.context.includeEnemies[hostile.id] then
      return true
    end

    if self.context.ignoreEnemies[hostile.id] then
      if respectMinLevelDifference and playerLevelAdvantage < minLevelDifference then
        return true
      end

      goto continue
    end

    if playerLevelAdvantage < minLevelDifference then
      return true
    end

    if hostileLevel >= minLevelEnemy then
      return true
    end

    ::continue::
  end

  return false
end

function GameState.getPlayerState(self)
  if self:isCombatState() then
    return PlayerStates.combat
  end

  return PlayerStates.explore
end

function GameState._fetchRegion(self, current_exterior)
  local player = self.context:getPlayer()
  local interiorRegions = Settings.getValue(Settings.KEYS.GENERAL_INTERIOR_REGIONS)

  if not current_exterior and  interiorRegions then
    return self.regionName.previous
  end

  return player.cell and player.cell.region or ""
end

return GameState
