local world = require('openmw.world')

local initialized = false

local function globalDataCollected(data)
  for _,player in ipairs(world.players) do
    player:sendEvent("globalDataCollected", { data = data });
  end
end

local function initialize()
  if initialized then
    return
  end

  print("initializing global script")
  local cellNames = {}
  local regionNames = {}
  local regionNamesSet = {}

  for _,cell in ipairs(world.cells) do
    if cell.name ~= '' then
      --   print("addingCell: " ..cell.name)
      table.insert(cellNames,cell.name)
      regionNamesSet[cell.region] = true
    end
  end

  for regionName,_ in pairs(regionNamesSet) do
    table.insert(regionNames, regionName)
  end

  globalDataCollected({
    cellNames = cellNames,
    regionNames = regionNames
  })
  initialized = true
end

local function onLoad()
  initialize()
end

local function onInit()
  initialize()
end

return {
  engineHandlers = {
    onInit = onInit,
    onLoad = onLoad
  }
}
