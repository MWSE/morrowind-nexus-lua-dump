local types = require("openmw.types")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local util = require("openmw.util")
local core = require("openmw.core")
local storage = require("openmw.storage")
local crassyStorage = storage.globalSection('crassyStorage')

doOnce = false

local function getNearestPlayer()

  for _, actor in ipairs(nearby.actors) do
    if actor.type == types.Player then return actor end
  end

  return nil
end

local function getDistance(target)
  return (self.object.position - target.position):length()
end

local function spawnDeathBook()
  if math.random(1, 200) ~= 1 or crassyStorage:get("spawnedDeathBook") == 1 then return end
  core.sendGlobalEvent("spawnDeathBook", self.object)
end

local function checkReplace()

  if not self.object.cell or
    self.object.cell.name ~= "The Arcane Academy of Venarius" or
    string.find(self.object.recordId, "aav_") or
    doOnce then return end

  if getDistance(player) > 150 then return end

  doOnce = true

  if math.random(1, 100) <= 10 then
    core.sendGlobalEvent("spawnCrassy", self.object)
  end
end

return {
  engineHandlers = {
    onUpdate = checkReplace,
    onActive = function ()
      player = getNearestPlayer()
      spawnDeathBook()
    end
  }
}
