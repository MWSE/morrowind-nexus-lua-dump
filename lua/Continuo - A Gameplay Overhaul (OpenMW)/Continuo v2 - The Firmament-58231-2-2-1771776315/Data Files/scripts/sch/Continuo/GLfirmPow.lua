local world = require("openmw.world")
local util  = require("openmw.util")

-- distances (tweak as desired)
local FORWARD_DIST = 120
local SIDE_DIST    = 120
local REAR_DIST    = 120

-- small random jitter so it doesn't stack perfectly
local JITTER = 20

local function randJitter()
  return (math.random() * 2 - 1) * JITTER
end

local function pickOffset()
  -- 1) front, 2) side, 3) rear-side
  local roll = math.random(3)

  if roll == 1 then
    return 0, FORWARD_DIST
  elseif roll == 2 then
    local sign = (math.random(2) == 1) and -1 or 1
    return sign * SIDE_DIST, 0
  else
    local sign = (math.random(2) == 1) and -1 or 1
    return sign * REAR_DIST, -REAR_DIST
  end
end

return {
  eventHandlers = {
    SCH_SpawnAtPlayer = function(data)
      local player = world.players[1]
      if not player or not data or not data.recordId then return end

      local obj = world.createObject(data.recordId, 1)

      local ppos = player.position

      local ox, oy = pickOffset()
      ox = ox + randJitter()
      oy = oy + randJitter()

      local spawnPos = util.vector3(
        ppos.x + ox,
        ppos.y + oy,
        ppos.z
      )

      obj:teleport(player.cell, spawnPos)
    end
  }
}