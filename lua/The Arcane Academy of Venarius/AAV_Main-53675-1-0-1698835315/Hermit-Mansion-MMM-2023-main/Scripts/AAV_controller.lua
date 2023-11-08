local async = require('openmw.async')
local core = require('openmw.core')
local storage = require("openmw.storage")
local types = require("openmw.types")
local world = require("openmw.world")


local Books = require("Scripts.books")
local crassyStorage = storage.globalSection('crassyStorage')

local function addToInventory(targets)
  local player = targets.player
  local object = targets.object

  object:moveInto(types.Actor.inventory(player))
end

local function getDeathBookSpawned()
  return crassyStorage:get("spawnedDeathBook")
end

local function getBooks()
  return Books
end

local function onSave()
  crassyStorage:set("remainingBooks", Books)
end

local function onLoad()
  local tempBooks = crassyStorage:asTable("remainingBooks")

  if tempBooks then Books = tempBooks.remainingBooks return end

end

local function canReplace(recordId)
  local originRecord = types.Book.record(recordId)

  return not originRecord.isScroll and originRecord.skill == nil
end

local function replaceObject(origin, replaceId)
  if not replaceId or not origin then return end

  world.createObject(replaceId, 1)
    :teleport(origin.cell.name, origin.position, origin.rotation)

  origin.enabled = false
end

local function spawnDeathBook(origin)
  if not canReplace(origin.recordId) or getDeathBookSpawned == 1 then return end

  print("Spawning death book...")

  replaceObject(origin, "aav_deathbook")

  crassyStorage:set("spawnedDeathBook", 1)
end

local function spawnCrassy(origin)
  if #Books == 0 then return end

  if not canReplace(origin.recordId) then return end

  print("Crassifying...")

  replaceObject(origin, table.remove(Books, math.random(1, #Books)))

end

local function checkTR(player)
  local globals = world.mwscript.getGlobalVariables(player)
  if core.contentFiles.has("TR_Mainland.esm") then
    globals.AAV_hasTR = 1
  else
    globals.AAV_hasTR = 0
  end
end

return {

  interfaceName = "aav_controller",
  interface = {
    Books = getBooks,
    deathBookSpawned = getDeathBookSpawned,
  },

  engineHandlers = {
    onSave = onSave,
    onLoad = onLoad,
    onNewGame = function()
      crassyStorage:reset()
    end,
    onPlayerAdded = function(player)
      checkTR(player)
    end,
    onItemActive = function(item)
      -- if item.recordId == "aav_deathbook" then
        -- print(item.cell.name)
      -- end
    end
  },

  eventHandlers = {
    spawnCrassy = spawnCrassy,
    spawnDeathBook = spawnDeathBook,
    addDeathBook = addToInventory,
    spawnGil = function(data)
      if not data.gil or not replaceObject then return end
      async:newUnsavableGameTimer(120, replaceObject(data.gil, "aav_gilgindil"))
    end,
  }
}
