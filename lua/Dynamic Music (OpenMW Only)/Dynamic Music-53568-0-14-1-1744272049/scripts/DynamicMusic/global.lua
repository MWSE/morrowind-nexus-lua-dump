local Globals = require('scripts.DynamicMusic.core.Globals')
local Log = require('scripts.DynamicMusic.core.Logger')

local core = require('openmw.core')

if core.API_REVISION < Globals.LUA_API_REVISION_MIN then
  Log.fatal("Unable to load Dynamic Music")
  Log.fatal(string.format("At least Lua api revision %s is required. Current Lua api revision is %s", Globals.LUA_API_REVISION_MIN, core.API_REVISION))
  return nil
end

local world = require('openmw.world')
local players = {}

local function sendGlobalData(player)
  Log.info("send global data to player: " ..player.id)
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

return {
  engineHandlers = {
    onUpdate = onUpdate
  }
}
