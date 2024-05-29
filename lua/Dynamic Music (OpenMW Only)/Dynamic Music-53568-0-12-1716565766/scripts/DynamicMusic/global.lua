local core = require('openmw.core')
local world = require('openmw.world')

local Globals = require('scripts.DynamicMusic.core.Globals')

local initialized = false
local players = {}

local function sendGlobalData(player)
  print("send global data to player: " .. player.id)
  local cellNames = {}
  local regionNames = {}
  local regionNamesSet = {}

  for _, cell in ipairs(world.cells) do
    if cell.name ~= '' then
      table.insert(cellNames, cell.name)
    end
    regionNamesSet[cell.region] = true
  end

  for regionName, _ in pairs(regionNamesSet) do
    table.insert(regionNames, regionName)
  end

  local data = {
    cellNames = cellNames,
    regionNames = regionNames
  }

  player:sendEvent("globalDataCollected", { data = data });
end

local function onUpdate()
  for _, player in ipairs(world.players) do
    if not players[player.id] then
      sendGlobalData(player)
      players[player.id] = true
    end
  end
end

if core.API_REVISION < Globals.MIN_API_REVISION then
  error(string.format("lua api version < %s detected: %s ", Globals.MIN_API_REVISION, core.API_REVISION), 2)
  return {}
end

return {
  engineHandlers = {
    onUpdate = onUpdate
  }
}
