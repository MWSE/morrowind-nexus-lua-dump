-- scripts/speechcraft_bribe/bribe_core.lua
-- Core math/logic for the Speechcraft Bribe minigame (pure Lua; OpenMW interaction only via args.npc).
-- OpenMW 0.49 compatible.

local settings = require('scripts.speechcraft_bribe.settings')

-- Optional external helper; if unavailable we fall back to neutral multipliers.
local okWealth, Wealth = pcall(require, 'scripts.speechcraft_bribe.wealth')
if not okWealth or type(Wealth) ~= 'table' then Wealth = nil end

local Core = {}

-- -------------------- helpers --------------------

local function clamp(v, lo, hi)
  if lo ~= nil and v < lo then return lo end
  if hi ~= nil and v > hi then return hi end
  return v
end

local function round(x)
  if x >= 0 then return math.floor(x + 0.5) else return math.ceil(x - 0.5) end
end

-- -------------------- thresholds / classification --------------------

local function thresholdsFor(playerStats, npcStats)
  local t = settings.thresholds or {}
  local ds = (playerStats.speechcraft or 0) - (npcStats.speechcraft or 0)
  local dp = (playerStats.personality or 0) - (npcStats.personality or 0)

  -- Range scale: lower (easier) when player is better; higher (tighter) when player is worse.
  local scale = 1
  if settings.speechcraftRangeScale or settings.personalityRangeScale then
    scale = 1
      - (settings.speechcraftRangeScale or 0) * ds
      - (settings.personalityRangeScale or 0) * dp
    scale = clamp(scale, settings.rangeScaleMin or 0.7, settings.rangeScaleMax or 1.5)
  end

  return {
    insulting = (t.insulting or 0.25) * scale,
    low       = (t.low       or 0.75) * scale,
    close     = (t.close     or 0.95) * scale,
    success   = (t.success   or 1.05) * scale,
    critical  = (t.critical  or 1.35) * scale,
  }
end

local function classifyRatio(ratio, th)
  if ratio < th.insulting then return 'insulting' end
  if ratio < th.low       then return 'low'       end
  if ratio < th.close     then return 'close'     end
  if ratio < th.success   then return 'success'   end
  if ratio < th.critical  then return 'critical'  end
  return 'overpay'
end

-- -------------------- requirement --------------------

local function mercantileMult(playerMerc, npcMerc)
  local d = (playerMerc or 0) - (npcMerc or 0)
  local mult = 1 - (settings.mercantileDeltaScale or 0.01) * d
  return clamp(mult, settings.mercantileMultMin or 0.5, settings.mercantileMultMax or 1.5)
end

local function resistanceAdd(playerStats, npcStats)
  local speechDis = math.max(0, (npcStats.speechcraft or 0) - (playerStats.speechcraft or 0))
  local persoDis  = math.max(0, (npcStats.personality or 0) - (playerStats.personality or 0))
  local wS = settings.resistSpeechWeight or 0.8
  local wP = settings.resistPersonalityWeight or 0.2
  return (wS * speechDis + wP * persoDis)
end

local function requiredGold(inflationMult, playerStats, npcStats, wealthMult)
  local base = (settings.baseFloor or 25)
  base = base + (settings.resistWeight or 0.5) * resistanceAdd(playerStats, npcStats)
  local mMult = mercantileMult(playerStats.mercantile, npcStats.mercantile)
  local wMult = wealthMult or 1.0
  local req = base * (inflationMult or 1.0) * mMult * wMult
  return math.max(1, round(req))
end

-- -------------------- evaluation --------------------

-- Evaluate an attempted bribe.
-- args = {
--   offer = <number>,
--   inflation = <number>,
--   playerStats = { speechcraft, mercantile, personality },
--   npcStats    = { speechcraft, mercantile, personality },
--   npc         = <GameObject NPC> (optional; enables Wealth multipliers),
-- }
-- Returns {
--   requirement, ratio, zone,
--   goldTaken, dispDelta, triesConsumed, inflationDelta,
-- }
function Core.evaluateAttempt(args)
  args = args or {}
  local offer       = math.max(0, math.floor(args.offer or 0))
  local inflation   = args.inflation or settings.inflationStart or 1.0
  local pstats      = args.playerStats or {}
  local nstats      = args.npcStats or {}

  -- Wealth multipliers (if NPC handle provided AND Wealth module is available)
  local wealthCostMult = 1.0
  if args.npc and args.npc.isValid and args.npc:isValid() and Wealth and Wealth.multipliers then
    local m = Wealth.multipliers(args.npc)
    if m and m.costMult then wealthCostMult = m.costMult end
  end

  local requirement = requiredGold(inflation, pstats, nstats, wealthCostMult)
  local ratio = (requirement > 0) and (offer / requirement) or 0.0
  local th = thresholdsFor(pstats, nstats)
  local zone = classifyRatio(ratio, th)

  local disp = settings.disposition or {}
  local dispDelta =
      (zone == 'insulting' and (disp.insulting or -1))
   or (zone == 'low'       and (disp.low       or  0))
   or (zone == 'close'     and (disp.close     or  0))
   or (zone == 'success'   and (disp.success   or  5))
   or (zone == 'critical'  and (disp.critical  or 10))
   or (zone == 'overpay'   and (disp.overpay   or  6))
   or 0

  local accepted = (zone == 'success' or zone == 'critical' or zone == 'overpay')
  local goldTaken = accepted and offer or 0

  local triesConsumed = true
  if zone == 'close' and settings.closeNoTry then
    triesConsumed = false
  end

  local inflationDelta = 0.0
  if accepted then
    if zone == 'critical' then
      inflationDelta = settings.inflationAddCritical or 0.20
    elseif zone == 'overpay' then
      inflationDelta = settings.inflationAddOverpay or 0.15
    else
      inflationDelta = settings.inflationAddSuccess or 0.10
    end
  end

  return {
    requirement    = requirement,
    ratio          = ratio,
    zone           = zone,
    goldTaken      = goldTaken,
    dispDelta      = dispDelta,
    triesConsumed  = triesConsumed,
    inflationDelta = inflationDelta,
  }
end

-- -------------------- messages --------------------

function Core.formatZoneMessage(zone)
  if zone == 'insulting' then return "Insulting offer." end
  if zone == 'low'       then return "Too low." end
  if zone == 'close'     then return "Close... you're almost there." end
  if zone == 'success'   then return "Success!" end
  if zone == 'critical'  then return "Perfect offer!" end
  return "Overpaying... generosity noted."
end

return Core
