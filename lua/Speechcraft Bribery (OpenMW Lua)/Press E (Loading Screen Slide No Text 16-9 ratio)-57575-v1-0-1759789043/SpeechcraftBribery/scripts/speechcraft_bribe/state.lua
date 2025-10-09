-- Per-save per-NPC state: tries, cooldown, inflation (OpenMW 0.49)
-- Stored via player.lua's engineHandlers.onSave/onLoad.
local core     = require('openmw.core')
local settings = require('scripts.speechcraft_bribe.settings')

local M = {}

-- In-memory per-save state. This whole table is serialized into the save.
-- Shape: { entries = { ["npc:<id>"] = { triesLeft, lastRefillHour, inflation, lastUpdate } } }
local PS = { entries = {} }

-- --- Helpers ---------------------------------------------------------------

-- Game time in **hours** (core.getGameTime() returns seconds per 0.49 docs)
local function gameHour()
  return (core.getGameTime() or 0) / 3600
end

-- Unique per-instance key (uses GameObject.id, not recordId)
local function keyForNpc(npc)
  if not npc or not npc.isValid or not npc:isValid() then return nil end
  return ('npc:%s'):format(npc.id)
end

local function defaultEntry(now)
  return {
    triesLeft      = settings.triesMax or 3,
    lastRefillHour = now,                      -- for tries cooldown
    inflation      = settings.inflationStart or 1.0,
    lastUpdate     = now,                      -- for inflation decay
  }
end

local function getEntry(npc)
  local key = keyForNpc(npc)
  if not key then return nil, nil end
  local e = PS.entries[key]
  if type(e) ~= 'table' then
    e = defaultEntry(gameHour())
    PS.entries[key] = e
  end
  return e, key
end

-- Seconds→hours migration guard & general healing (defensive)
local function heal(entry, now)
  local cd = settings.cooldownHours or 24
  entry.triesLeft      = math.max(0, math.floor(tonumber(entry.triesLeft or (settings.triesMax or 3))))
  entry.inflation      = tonumber(entry.inflation or (settings.inflationStart or 1.0))
  entry.lastRefillHour = tonumber(entry.lastRefillHour or now)
  entry.lastUpdate     = tonumber(entry.lastUpdate or now)

  -- If timestamps look like seconds (way in the future vs hours), convert.
  if entry.lastRefillHour > now + cd * 4 then entry.lastRefillHour = entry.lastRefillHour / 3600 end
  if entry.lastUpdate     > now + cd * 4 then entry.lastUpdate     = entry.lastUpdate     / 3600 end

  -- Clamp future skew
  if entry.lastRefillHour > now then entry.lastRefillHour = now - cd end
  if entry.lastUpdate     > now then entry.lastUpdate     = now end

  -- Clamp tries to [0, triesMax]
  local mx = settings.triesMax or 3
  if entry.triesLeft > mx then entry.triesLeft = mx end
end

-- Additive decay in "multiplier units per day" (e.g., 0.01 ≈ 1%/day)
local function maybeDecayInflation(entry, now)
  local perDay = settings.inflationDecayPerDay or 0
  if perDay <= 0 then
    entry.lastUpdate = now
    return
  end
  local hours = math.max(0, now - (entry.lastUpdate or now))
  if hours <= 0 then return end
  local decayed = (entry.inflation or (settings.inflationStart or 1.0)) - (perDay / 24) * hours
  if decayed < 1.0 then decayed = 1.0 end
  local cap = settings.inflationCap or math.huge
  entry.inflation  = math.min(cap, decayed)
  entry.lastUpdate = now
end

-- Always top up tries after cooldown has passed, regardless of current triesLeft.
local function maybeRefillTries(entry, now)
  local cd = settings.cooldownHours or 24
  if now - (entry.lastRefillHour or now) >= cd then
    entry.triesLeft      = settings.triesMax or 3
    entry.lastRefillHour = now
  end
end

-- --- Public API ------------------------------------------------------------

--- Read (and maintain) the state for an NPC.
function M.read(npc)
  local now = gameHour()
  local entry = getEntry(npc)
  if not entry then
    -- No valid NPC: return a volatile default (not stored)
    local tmp = defaultEntry(now)
    tmp._volatile = true
    return tmp
  end
  heal(entry, now)
  maybeDecayInflation(entry, now)
  maybeRefillTries(entry, now)
  return entry
end

--- Consume one try (after checking for daily refill)
function M.consumeTry(npc)
  local now = gameHour()
  local entry = getEntry(npc)
  if not entry then return defaultEntry(now) end
  heal(entry, now)
  maybeRefillTries(entry, now)
  if entry.triesLeft > 0 then
    entry.triesLeft = entry.triesLeft - 1
  end
  return entry
end

--- Apply success inflation bump.
function M.onSuccess(npc, inflationAdd)
  local now = gameHour()
  local entry = getEntry(npc)
  if not entry then return defaultEntry(now) end
  heal(entry, now)
  maybeRefillTries(entry, now)
  local add = inflationAdd or 0
  local cap = settings.inflationCap or math.huge
  entry.inflation  = math.min(cap, (entry.inflation or (settings.inflationStart or 1.0)) + add)
  entry.lastUpdate = now
  return entry
end

-- Debug / recovery helpers
function M.resetNpc(npc)
  local now = gameHour()
  local e, key = getEntry(npc)
  if not key then return defaultEntry(now) end
  local fresh = defaultEntry(now)
  PS.entries[key] = fresh
  return fresh
end

function M.resetAll()
  PS.entries = {}
end

-- --- Save/Load bridge (called by player.lua engineHandlers) ---------------
function M.serialize()
  -- return a deep-ish copy to be safe
  local out = { entries = {} }
  for k, v in pairs(PS.entries) do
    if type(v) == 'table' then
      local t = {}
      for kk, vv in pairs(v) do t[kk] = vv end
      out.entries[k] = t
    end
  end
  return out
end

function M.deserialize(data)
  if type(data) == 'table' and type(data.entries) == 'table' then
    PS = { entries = {} }
    for k, v in pairs(data.entries) do
      if type(k) == 'string' and type(v) == 'table' then
        PS.entries[k] = {
          triesLeft      = v.triesLeft,
          lastRefillHour = v.lastRefillHour,
          inflation      = v.inflation,
          lastUpdate     = v.lastUpdate,
        }
      end
    end
  else
    PS = { entries = {} }
  end
end

return M
