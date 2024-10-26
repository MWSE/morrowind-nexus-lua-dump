local ambient = require('openmw.ambient')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local core = require('openmw.core')

local Globals = require('scripts.DynamicMusic.core.Globals')
local PlayerStates = require('scripts.DynamicMusic.core.PlayerStates')
local GameState = require('scripts.DynamicMusic.core.GameState')
local DynamicMusic = require('scripts.DynamicMusic.core.DynamicMusic')
local Settings = require('scripts.DynamicMusic.core.Settings')

local hostileActors = {}
local initialized = false

local function isCombatState()
  if not Settings.getValue(Settings.KEYS.COMBAT_PLAY_COMBAT_MUSIC) then
    return false
  end

  local playerLevel = types.Actor.stats.level(self).current
  local minLevelEnemy = Settings.getValue(Settings.KEYS.COMBAT_MIN_ENEMY_LEVEL)
  local minLevelDifference = Settings.getValue(Settings.KEYS.COMBAT_MIN_LEVEL_DIFFERENCE)
  local respectMinLevelDifference = Settings.getValue(Settings.KEYS.COMBAT_ENEMIES_IGNORE_RESPECT_LEVEL_DIFFERENCE)

  for _, hostile in pairs(hostileActors) do
    local actor = hostile.actor
    local hostileLevel = types.Actor.stats.level(actor).current
    local playerLevelAdvantage = playerLevel - hostileLevel
    local inProcessingRange = types.Actor.isInActorsProcessingRange(actor)

    if not inProcessingRange then
      break
    end

    if DynamicMusic.includeEnemies[hostile.refId] then
      return true
    end

    if DynamicMusic.ignoreEnemies[hostile.refId] then
      if respectMinLevelDifference and playerLevelAdvantage < minLevelDifference then
        return true
      end

      break
    end

    if playerLevelAdvantage < minLevelDifference then
      return true
    end

    if hostileLevel >= minLevelEnemy then
      return true
    end
  end

  return false
end

local function getPlayerState()
  if isCombatState() then
    return PlayerStates.combat
  end

  return PlayerStates.explore
end

local function hasGameStateChanged()
  if GameState.playerState.previous ~= GameState.playerState.current then
    -- print("change playerState: " ..gameState.playerState.current)
    return true
  end

  if not ambient.isMusicPlaying() then
    return true
  end

  if GameState.regionName.current ~= GameState.regionName.previous then
    -- print("change regionName")
    return true
  end

  if GameState.cellName.current ~= GameState.cellName.previous then
    -- print("change celName")
    return true
  end

  if GameState.hourOfDay.current ~= GameState.hourOfDay.previous then
--    print(string.format("hour of day changed from %i to %i", GameState.hourOfDay.previous, GameState.hourOfDay.current))
    return true
  end

  return false
end

local function initialize()
  if not initialized then
    initialized = true

    local omwMusicSettings = storage.playerSection('SettingsOMWMusic')
    if omwMusicSettings then
      print("changing built in openmw combat music setting to false")
      omwMusicSettings:set("CombatMusicEnabled", false)
    end
  end
end

local function onFrame(dt)
  if not DynamicMusic.initialized then
    return
  end

  if not initialized then
    initialize()
  end

  local hourOfDay = math.floor((core.getGameTime() / 3600) % 24)

  GameState.exterior.current = self.cell and self.cell.isExterior
  GameState.cellName.current = self.cell and self.cell.name or ""
  GameState.playtime.current = os.time()
  GameState.regionName.current = self.cell and self.cell.region or ""
  GameState.playerState.current = getPlayerState()
  GameState.hourOfDay.current = hourOfDay

  if hasGameStateChanged() then
    DynamicMusic.newMusic()
  end

  DynamicMusic.update(dt)

  GameState.exterior.previous = GameState.exterior.current
  GameState.cellName.previous = GameState.cellName.current
  GameState.playtime.previous = GameState.playtime.current
  GameState.playerState.previous = GameState.playerState.current
  GameState.regionName.previous = GameState.regionName.current
  GameState.soundbank.previous = GameState.soundbank.current
  GameState.hourOfDay.previous = GameState.hourOfDay.current
end

local function engaging(eventData)
  if (not eventData.actor) then
    return
  end

  if not eventData.targetActor or eventData.targetActor.id ~= self.id then
    return
  end

  hostileActors[eventData.actor.id] = eventData;
  --  print("engaging: " ..eventData.actor.id .." - " ..eventData.actor.recordId ..eventData.name)
end

local function disengaging(eventData)
  if (not eventData.actor) then return end;

  hostileActors[eventData.actor.id] = nil;
end

local function globalDataCollected(eventData)
  local data = eventData.data

  DynamicMusic.initialize(data.cellNames, data.regionNames, hostileActors)

--  DynamicMusic.info()
  data = nil
end

if core.API_REVISION < Globals.LUA_API_REVISION_MIN then
  return nil
end

return {
  engineHandlers = {
    onFrame = onFrame
  },
  eventHandlers = {
    engaging = engaging,
    disengaging = disengaging,
    globalDataCollected = globalDataCollected
  },
}
