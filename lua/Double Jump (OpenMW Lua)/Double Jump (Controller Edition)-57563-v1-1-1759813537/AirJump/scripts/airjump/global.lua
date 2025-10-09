-- AirJump (GLOBAL) – pad with hard TTL + removal retry + stray sweep.
-- OpenMW 0.49 API.

local world = require('openmw.world')
local types = require('openmw.types')
local async = require('openmw.async')
local util  = require('openmw.util')

-- Invisible collision mesh exported with "Collision" node
local PAD_MODEL_PATH = 'meshes/airjump/invis_pad.dae'

-- Cleanup knobs
local KILL_TTL_S           = 0.8     -- pad hard life time, independent of contact or updates
local KILL_RETRY_S         = 0.05    -- retry delay if remove() collides with a teleport
local WATCHDOG_INTERVAL_S  = 0.20    -- culling cadence (also sweeps for orphans)
local MAX_PLAYER_OFFSET    = 200.0   -- distance fail-safe

-- Runtime record id cache
local PAD_RECORD_ID
local function ensurePadRecordId()
  if PAD_RECORD_ID then return PAD_RECORD_ID end
  local draft = types.Activator.createRecordDraft({
    name  = 'AirJump Pad',
    model = PAD_MODEL_PATH,
  })
  PAD_RECORD_ID = world.createRecord(draft).id
  return PAD_RECORD_ID
end

-- Tracked instance
local currentPad         = nil
local lastPadCell        = nil
local secondsSinceUpdate = 0.0
local secondsSinceSpawn  = 0.0
local killingInProgress  = false

local function safeRemove(obj)
  if obj and obj.isValid and obj:isValid() then
    pcall(function() obj:remove() end)
  end
end

-- Robust removal with retry (handles "teleporting" race)
local function removeWithRetry(obj)
  if not (obj and obj.isValid and obj:isValid()) then return end
  local ok, err = pcall(function() obj:remove() end)
  if not ok and obj:isValid() then
    async:newUnsavableSimulationTimer(KILL_RETRY_S, function()
      removeWithRetry(obj)
    end)
  end
end

-- Sweep a cell for any activators that use our runtime record id
local function cullStrays(cell)
  if not (cell and PAD_RECORD_ID) then return end
  for _, o in ipairs(cell:getAll(types.Activator)) do
    if o and o:isValid() and o.recordId == PAD_RECORD_ID and o ~= currentPad then
      safeRemove(o)
    end
  end
end

local function clearPad()
  local pad = currentPad
  currentPad = nil
  killingInProgress = true
  if pad and pad:isValid() then
    removeWithRetry(pad)
  end
  secondsSinceUpdate, secondsSinceSpawn = 0.0, 0.0
  -- Sweep both the player's cell and the last pad cell (covers cell transitions)
  local player = world.players and world.players[1]
  if player and player:isValid() then
    cullStrays(player.cell)
  end
  if lastPadCell then
    cullStrays(lastPadCell)
  end
  killingInProgress = false
end

-- ===== SPAWN / MOVE =========================================================

local function spawnPad(data)
  if not data or not data.x or not data.y or not data.z then return false end

  local player = world.players and world.players[1]
  if not (player and player:isValid() and player.cell) then return false end

  -- Nuke anything old before spawning
  clearPad()

  local id  = ensurePadRecordId()
  local obj = world.createObject(id, 1)
  if not (obj and obj:isValid()) then return false end

  local pos = util.vector3(tonumber(data.x), tonumber(data.y), tonumber(data.z))
  obj:teleport(player.cell, pos)
  if data.scale then
    pcall(function() obj:setScale(tonumber(data.scale)) end)
  end

  currentPad         = obj
  lastPadCell        = obj.cell
  secondsSinceUpdate = 0.0
  secondsSinceSpawn  = 0.0

  -- Hard TTL: ALWAYS kill this instance after KILL_TTL_S, no conditions
  local thisPad = obj
  async:newUnsavableSimulationTimer(KILL_TTL_S, function()
    -- Decouple from currentPad pointer; just kill the object we spawned
    removeWithRetry(thisPad)
    if currentPad == thisPad then currentPad = nil end
  end)

  -- One sweep right after spawn (cleans any stale clones instantly)
  async:newUnsavableSimulationTimer(0.0, function()
    cullStrays(player.cell)
  end)

  return true
end

local function updatePadCenter(data)
  if killingInProgress then return end                       -- ignore while clearing
  if not (currentPad and currentPad:isValid()) then return end
  if not (data and data.x and data.y and data.z) then return end

  local player = world.players and world.players[1]
  if not (player and player:isValid() and player.cell) then return end

  local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
  async:newUnsavableSimulationTimer(0.0, function()
    if currentPad and currentPad:isValid() then
      currentPad:teleport(player.cell, util.vector3(x, y, z))
      secondsSinceUpdate = 0.0
      lastPadCell        = currentPad.cell
    end
  end)
end

-- ===== WATCHDOG =============================================================

local function watchdogTick()
  secondsSinceUpdate = secondsSinceUpdate + WATCHDOG_INTERVAL_S
  secondsSinceSpawn  = secondsSinceSpawn  + WATCHDOG_INTERVAL_S

  local player = world.players and world.players[1]
  if player and player:isValid() then
    cullStrays(player.cell)
  end
  if lastPadCell then
    cullStrays(lastPadCell)
  end

  local pad = currentPad
  if pad and pad:isValid() then
    -- Distance/cell fallbacks (in addition to hard TTL)
    local okPlayer = player and player:isValid()
    if (not okPlayer) or (pad.cell ~= player.cell) then
      clearPad()
    else
      local dx = pad.position.x - player.position.x
      local dy = pad.position.y - player.position.y
      local dz = pad.position.z - player.position.z
      if (dx*dx + dy*dy + dz*dz) > (MAX_PLAYER_OFFSET * MAX_PLAYER_OFFSET) then
        clearPad()
      end
    end
  end

  async:newUnsavableSimulationTimer(WATCHDOG_INTERVAL_S, watchdogTick)
end

async:newUnsavableSimulationTimer(WATCHDOG_INTERVAL_S, watchdogTick)

-- ===== PUBLIC ===============================================================

return {
  interfaceName = 'AirJumpGlobal',
  interface     = {
    spawnPad        = spawnPad,
    updatePadCenter = updatePadCenter,
    clearPad        = clearPad,
  },
  eventHandlers = {
    AJ_SpawnPad        = function(p) spawnPad(p) end,
    AJ_UpdatePadCenter = function(p) updatePadCenter(p) end,
    AJ_ClearPad        = function()  clearPad() end,
  },
}
