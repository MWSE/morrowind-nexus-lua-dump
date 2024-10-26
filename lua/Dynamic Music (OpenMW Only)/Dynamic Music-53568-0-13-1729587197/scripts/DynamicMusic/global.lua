local core = require('openmw.core')
local world = require('openmw.world')

local Globals = require('scripts.DynamicMusic.core.Globals')

local initialized = false
local players = {}

local function sendGlobalData(player)
  print("send global data to player: " ..player.id)
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

if core.API_REVISION < Globals.LUA_API_REVISION_MIN then
  print("Unable to load Dynamic Music")
  print(string.format("At least Lua api revision %s is required. Current Lua api revision is %s", Globals.LUA_API_REVISION_MIN, core.API_REVISION))
  return nil
end

return {
  engineHandlers = {
    onUpdate = onUpdate
  }
}
