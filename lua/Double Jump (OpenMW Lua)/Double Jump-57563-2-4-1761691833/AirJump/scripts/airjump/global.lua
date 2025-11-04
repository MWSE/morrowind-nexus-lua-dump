-- AirJump (GLOBAL) – persistent settings owner + pad controller (OpenMW 0.49/0.50)

local core    = require('openmw.core')
local world   = require('openmw.world')
local types   = require('openmw.types')
local async   = require('openmw.async')
local util    = require('openmw.util')
local I       = require('openmw.interfaces')
local storage = require('openmw.storage')

-- ---------- Settings (GLOBAL owns the persistent gameplay group) ----------
local PAGE_KEY    = 'AirJump'
local L10N        = 'AirJump'
local GROUP_KEY   = 'SettingsAirJump'
local K_EXTRA     = 'ExtraJumps'
local DEFAULT_VAL = 1

-- Ensure the page exists (idempotent if menu.lua also registers it)
pcall(function()
  I.Settings.registerPage {
    key = PAGE_KEY, l10n = L10N,
    name = 'AirJump_Page_Name',
    description = 'AirJump_Page_Desc',
  }
end)

-- Register the gameplay group + number row
pcall(function()
  I.Settings.registerGroup{
    key              = GROUP_KEY,
    page             = PAGE_KEY,
    l10n             = L10N,
    name             = 'AirJump_Gameplay_Group_Name', -- <- was "GroupName"
    description      = nil,                            -- <- hide group description to avoid width bloat
    permanentStorage = true,
    order            = 0,
    settings         = {
      {
        key         = K_EXTRA,
        renderer    = 'number',
        name        = 'AirJump_ExtraJumps_Name',       -- <- was "ExtraName"
        description = nil,                              -- <- no long description; shows a neat textbox
        default     = DEFAULT_VAL,
        argument    = { integer = true, min = 0, max = 10 },
      },
    },
  }
end)

local gSettings = storage.globalSection(GROUP_KEY)

local function currentExtra()
  local v = tonumber(gSettings and gSettings:get(K_EXTRA)) or DEFAULT_VAL
  if v < 0 then v = 0 end
  if v > 10 then v = 10 end
  return math.floor(v)
end

local function broadcastExtraJumps()
  core.sendGlobalEvent('AJ_ExtraJumpsChanged', { value = currentExtra() })
end

-- Broadcast when the value changes (covers UI edits and reloadlua)
if gSettings then
  gSettings:subscribe(async:callback(function(_, key)
    if (not key) or key == K_EXTRA then
      broadcastExtraJumps()
    end
  end))
end

-- Player can request the current value at init
local function onRequestExtraJumps()
  broadcastExtraJumps()
end

-- Optional migration hook from old storage
local function onSetGlobalExtraJumps(data)
  if not (data and data.value) then return end
  local v = tonumber(data.value)
  if not v then return end
  if v < 0 then v = 0 end
  if v > 10 then v = 10 end
  v = math.floor(v)
  if gSettings and gSettings:get(K_EXTRA) ~= v then
    gSettings:set(K_EXTRA, v)
  end
  broadcastExtraJumps()
end

-- ---------- Pad controller (unchanged from your version) ----------
local PAD_MODEL_PATH  = 'meshes/airjump/invis_pad.dae'
local PAD_RECORD_ID   = nil

local FAILSAFE_TTL_S  = 3.0
local RETRY_REMOVE_S  = 0.05
local MIN_MOVE_DIST2  = 0.01

local currentPad, frozen = nil, false

local function ensurePadRecordId()
  if PAD_RECORD_ID then return PAD_RECORD_ID end
  local draft = types.Activator.createRecordDraft({ name = 'AirJump Pad', model = PAD_MODEL_PATH })
  PAD_RECORD_ID = world.createRecord(draft).id
  return PAD_RECORD_ID
end

local function removeWithRetry(obj)
  if not (obj and obj.isValid and obj:isValid()) then return end
  local ok = pcall(function() obj:remove() end)
  if (not ok) and obj:isValid() then
    async:newUnsavableSimulationTimer(RETRY_REMOVE_S, function() removeWithRetry(obj) end)
  end
end

local function clearPad()
  local pad = currentPad
  currentPad, frozen = nil, false
  if pad and pad:isValid() then removeWithRetry(pad) end
end

local function spawnPad(data)
  if not data or not data.x or not data.y or not data.z then return end
  local player = world.players and world.players[1]
  if not (player and player:isValid() and player.cell) then return end

  clearPad()

  local id  = ensurePadRecordId()
  local obj = world.createObject(id, 1)
  if not (obj and obj:isValid()) then return end

  obj:teleport(player.cell, util.vector3(tonumber(data.x), tonumber(data.y), tonumber(data.z)))
  if data.scale then pcall(function() obj:setScale(tonumber(data.scale)) end) end

  currentPad, frozen = obj, false

  local thisPad = obj
  async:newUnsavableSimulationTimer(FAILSAFE_TTL_S, function()
    if currentPad == thisPad then clearPad() else removeWithRetry(thisPad) end
  end)
end

local function freezePad() frozen = true end

local function updatePadCenter(data)
  if frozen then return end
  if not (currentPad and currentPad.isValid and currentPad:isValid()) then return end
  if not (data and data.x and data.y and data.z) then return end
  local player = world.players and world.players[1]
  if not (player and player:isValid() and player.cell) then return end

  local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
  local p = currentPad.position
  local dx, dy, dz = x - p.x, y - p.y, z - p.z
  if (dx*dx + dy*dy + dz*dz) < MIN_MOVE_DIST2 then return end

  currentPad:teleport(player.cell, util.vector3(x, y, z))
end

return {
  interfaceName = 'AirJumpGlobal',
  interface     = {
    spawnPad        = spawnPad,
    updatePadCenter = updatePadCenter,
    clearPad        = clearPad,
    freezePad       = freezePad,
  },
  eventHandlers = {
    AJ_SpawnPad            = function(p) spawnPad(p) end,
    AJ_UpdatePadCenter     = function(p) updatePadCenter(p) end,
    AJ_FreezePad           = function()  freezePad() end,
    AJ_DespawnPad          = function()  clearPad() end,
    AJ_RequestExtraJumps   = function()  onRequestExtraJumps() end,
    AJ_SetGlobalExtraJumps = function(p) onSetGlobalExtraJumps(p) end,
  },
  engineHandlers = {
    onInit = function()  -- push a value immediately at startup
      broadcastExtraJumps()
    end,
    onPlayerAdded = function(_)
      broadcastExtraJumps()
    end,
  },
}
