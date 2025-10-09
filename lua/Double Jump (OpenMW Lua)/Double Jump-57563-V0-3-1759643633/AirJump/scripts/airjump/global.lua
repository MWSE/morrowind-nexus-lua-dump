-- AirJump (GLOBAL) – robust per-object despawn & safe repositioning.
-- OpenMW 0.49 API only.

local world = require('openmw.world')
local types = require('openmw.types')
local async = require('openmw.async')
local util  = require('openmw.util')

-- Path to your invisible collision mesh (OpenMW COLLADA export with a "Collision" node)
local PAD_MODEL_PATH = 'meshes/airjump/invis_pad.dae'

-- Cache the runtime record id once per session
local PAD_RECORD_ID = nil
local function ensurePadRecordId()
  if PAD_RECORD_ID then return PAD_RECORD_ID end
  local draft = types.Activator.createRecordDraft({
    name  = 'AirJump Pad',
    model = PAD_MODEL_PATH,
  })
  local rec = world.createRecord(draft)
  PAD_RECORD_ID = rec.id
  return PAD_RECORD_ID
end

-- Keep only one actively tracked pad (the one the player is currently using)
local currentPad   = nil
local currentScale = 1.0

local function safeRemove(obj)
  if obj and obj:isValid() then
    pcall(function() obj:remove() end)
  end
end

local function spawnPad(data)
  if not data or not data.x or not data.y or not data.z then return false end

  local player = world.players and world.players[1]
  if not (player and player:isValid() and player.cell) then return false end
  local cell = player.cell

  -- Clean up any previous tracked pad immediately
  safeRemove(currentPad)
  currentPad = nil

  local recordId = ensurePadRecordId()
  local obj = world.createObject(recordId, 1)
  if not (obj and obj:isValid()) then return false end

  obj:teleport(cell, util.vector3(tonumber(data.x), tonumber(data.y), tonumber(data.z)))

  currentScale = tonumber(data.scale) or 1.0
  if currentScale ~= 1.0 then obj:setScale(currentScale) end

  currentPad = obj

  -- Capture THIS object in the timer
  local thisPad = obj
  local life = math.max(50, tonumber(data.lifeMs) or 600)
  async:newUnsavableSimulationTimer(life / 1000.0, function()
    safeRemove(thisPad)
    if currentPad == thisPad then
      currentPad = nil
    end
  end)

  return true
end

-- Reposition the tracked pad next simulation tick (avoid double-teleport same frame)
local function updatePadCenter(data)
  if not (currentPad and currentPad:isValid()) then return end
  if not (data and data.x and data.y and data.z) then return end

  local player = world.players and world.players[1]
  if not (player and player:isValid() and player.cell) then return end
  local cell = player.cell

  local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
  async:newUnsavableSimulationTimer(0.0, function()
    if currentPad and currentPad:isValid() then
      currentPad:teleport(cell, util.vector3(x, y, z))
    end
  end)
end

local function clearPad()
  local pad = currentPad
  currentPad = nil
  safeRemove(pad)
end

return {
  interfaceName = 'AirJumpGlobal',
  interface     = { spawnPad = spawnPad, updatePadCenter = updatePadCenter, clearPad = clearPad },
  eventHandlers = {
    AJ_SpawnPad        = function(payload) spawnPad(payload) end,
    AJ_UpdatePadCenter = function(payload) updatePadCenter(payload) end,
    AJ_ClearPad        = function() clearPad() end,
  },
}
