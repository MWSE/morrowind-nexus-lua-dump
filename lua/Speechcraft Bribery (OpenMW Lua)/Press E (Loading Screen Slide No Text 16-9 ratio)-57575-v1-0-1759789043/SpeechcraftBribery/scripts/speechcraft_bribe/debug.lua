-- scripts/speechcraft_bribe/debug.lua
-- Minimal logger for OpenMW 0.49 Lua (no filesystem writes; logs go to openmw.log via print()).
-- Toggle ENABLED to true while debugging, false for release builds.

local M = {}

-- === Toggle ===
local ENABLED = true  -- ← set to true when you want verbose logging

-- === Utility ===
local function now()
  -- os.date is allowed in OpenMW's sandbox (os.date/os.time/os.difftime). 
  -- Produces e.g. 2025-09-25 14:03:07
  local t = os.date("*t")
  return string.format("%04d-%02d-%02d %02d:%02d:%02d",
    t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local PREFIX = "[SpeechcraftBribe]"

function M.isEnabled()
  return ENABLED
end

function M.setEnabled(v)
  ENABLED = not not v
end

-- Basic printf-style logger
function M.log(fmt, ...)
  if not ENABLED then return end
  local msg = (select('#', ...) > 0) and string.format(fmt, ...) or tostring(fmt)
  print(("%s %s %s"):format(now(), PREFIX, msg))
end

-- Safe, shallow serialization (for small tables / numbers / strings)
local function kvdump(tbl)
  if type(tbl) ~= 'table' then return tostring(tbl) end
  local parts = {}
  for k, v in pairs(tbl) do
    local kk = tostring(k)
    local vv
    local tv = type(v)
    if tv == 'number' or tv == 'boolean' then vv = tostring(v)
    elseif tv == 'string' then vv = ("%q"):format(v)
    elseif tv == 'table' then vv = "<table>"
    else vv = "<"..tv..">"
    end
    parts[#parts+1] = kk .. "=" .. vv
  end
  table.sort(parts)
  return "{" .. table.concat(parts, ", ") .. "}"
end

-- Dump the full bribe math in consistent order
-- dbg: table collected by bribe_core with intermediates
-- res: final result table from evaluateAttempt(...)
function M.dumpAttempt(dbg, res)
  if not ENABLED then return end

  M.log("---- Bribe attempt ----")
  if dbg.player and dbg.npc then
    M.log("Actor: playerStats=%s | npcStats=%s", kvdump(dbg.player), kvdump(dbg.npc))
  end
  if dbg.npcId or dbg.npcName then
    M.log("Target: id=%s name=%s", tostring(dbg.npcId), tostring(dbg.npcName))
  end
  M.log("Offer=%d | Inflation=%.3f | WealthCostMult=%.3f", dbg.offer or -1, dbg.inflation or -1, dbg.wealthCostMult or 1.0)

  -- Requirement breakdown
  M.log("BaseFloor=%g + ResistWeight=%g * ResistIndex=%g  => Base=%g",
        dbg.baseFloor or 0, dbg.resistWeight or 0, dbg.resistIndex or 0, dbg.baseAfterResist or 0)
  M.log("Mercantile: dMerc=%d, scale=%.4f -> mercMult=%.3f (clamped %.2f..%.2f)",
        dbg.dMerc or 0, dbg.mercantileDeltaScale or 0, dbg.mercMult or 1,
        dbg.mercMin or 0, dbg.mercMax or 0)
  M.log("Required = round(Base * Inflation * mercMult * wealthCostMult) = %d", dbg.required or -1)

  -- Window
  M.log("Window: dSpeech=%d dPers=%d | w_raw=%.3f -> w=%.3f (clamped %.2f..%.2f)",
        dbg.dSpeech or 0, dbg.dPers or 0, dbg.w_raw or 0, dbg.w or 0, dbg.rangeMin or 0, dbg.rangeMax or 0)
  M.log("Scaled thresholds: insulting=%.3f low=%.3f close=%.3f success=%.3f critical=%.3f",
        dbg.th_ins or 0, dbg.th_low or 0, dbg.th_close or 0, dbg.th_succ or 0, dbg.th_crit or 0)

  -- Classification
  M.log("Ratio r = offer/required = %.3f -> zone=%s", dbg.ratio or 0, tostring(res and res.zone))

  -- Effects
  if res then
    M.log("Effects: goldTaken=%d dispDelta=%d triesConsumed=%s inflationDelta=%.3f",
          res.goldTaken or 0, res.dispDelta or 0, tostring(res.triesConsumed), res.inflationDelta or 0)
  end
  M.log("---- end bribe ----")
end

return M
