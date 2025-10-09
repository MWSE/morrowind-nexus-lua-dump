-- scripts/speechcraft_bribe/wealth.lua
-- OpenMW 0.49 “wealth” helpers for bribery logic.
-- Signals how “rich” an actor appears using:
--   • outfit value (equipped armor+clothing),
--   • weighted, capped personal-inventory value,
--   • weighted NPC barter gold (NpcRecord.baseGold) — solid proxy for merchants.
--
-- Public API:
--   local Wealth = require('scripts.speechcraft_bribe.wealth')
--   local wearOnly = Wealth.clothingModifier(npc)
--   local invRaw   = Wealth.inventoryValue(npc)
--   local total    = Wealth.totalWealth(npc)   -- clothing + weighted&capped inventory + baseGold term
--   local mul      = Wealth.multipliers(npc)   -- { costMult, dispMult, raw, mid }
--   local poorMult = Wealth.poorDispositionMultiplier(npc) -- >= 1.0; only boosts poor NPCs
--
-- Safe to require from global/local/menu scripts. No side-effects.

local types = require('openmw.types')

local Wealth = {}

-- Try to import settings from your mod (optional).
local function loadSettings()
  local try = {
    'scripts.speechcraft_bribe.settings', -- your mod namespace
    'settings',                            -- fallback if you keep everything flat
  }
  for _, name in ipairs(try) do
    local ok, t = pcall(require, name)
    if ok and type(t) == 'table' then return t end
  end
  return nil
end

-- Tunables (with safe defaults). If you expose them in Settings UI, put these keys into
-- scripts/speechcraft_bribe/settings.lua and they’ll be used automatically.
local function getOpts()
  local settings = loadSettings()
  local d = {
    -- Core curve (log-scaling around a midpoint) for COST
    wealthMidValue      = 120,   -- “neutral” wealth (set low so nobles land > 1.0)
    perDecadeCost       = 0.30,  -- +30% cost per 10× wealth
    maxCostBonus        = 0.25,  -- cap: at most 25% cheaper (poor easier)
    maxCostPenalty      = 0.60,  -- cap: up to 60% pricier (rich tougher)

    -- Vanilla parity knobs
    includeWeapons      = false, -- vanilla “PC Clothing Modifier” excludes weapons
    includeCarriedGold  = false, -- (for clothingModifier only) non-vanilla; usually keep false

    -- Inventory (personal) extensions
    includeInventory    = true,  -- include personal inventory in totalWealth()
    inventoryWeight     = 0.15,  -- contribution of personal inventory value
    inventoryCap        = 2000,  -- cap (AFTER weighting)
    excludeGold         = true,  -- ignore gold_001 stacks in personal inventory

    -- Merchant proxy (barter gold lives on the NPC record, not their backpack)
    includeBaseGold     = true,
    baseGoldWeight      = 1.25,  -- stronger merchant signal

    -- Poor-only disposition shaping (affects ONLY targets below wealthMidValue)
    poorDispPerDecade   = 1.5,   -- +150% per 10× poorer relative to mid (before gamma)
    poorDispGamma       = 1.1,   -- gentle nonlinearity for the very poor
    poorDispMax         = 3.0,   -- absolute cap on disposition bonus multiplier

    -- Optional debugging
    debugWealth         = false,
  }
  if type(settings) ~= 'table' then return d end
  for k, v in pairs(d) do
    local sv = settings[k]
    if type(sv) == type(v) then d[k] = sv end
  end
  return d
end

-- ---------- internals ----------

local function clamp(x, lo, hi)
  if x < lo then return lo elseif x > hi then return hi else return x end
end
local function log10(x) return math.log(x) / math.log(10) end

-- Sum value of a single equipped item if it’s armor/clothing (optionally weapon).
local function equippedItemValue(obj, includeWeapons)
  if not obj or not obj.isValid or not obj:isValid() then return 0 end
  if types.Armor.objectIsInstance(obj) then
    local rec = types.Armor.record(obj); return (rec and rec.value) or 0
  elseif types.Clothing.objectIsInstance(obj) then
    local rec = types.Clothing.record(obj); return (rec and rec.value) or 0
  elseif includeWeapons and types.Weapon.objectIsInstance(obj) then
    local rec = types.Weapon.record(obj);   return (rec and rec.value) or 0
  end
  return 0
end

-- Build a set of equipped object handles to skip when summing inventory.
local function equippedSet(actor)
  local set = {}
  local eq = types.Actor.getEquipment(actor) or {}        -- Actor.getEquipment() returns slot->GameObject
  for _, obj in pairs(eq) do
    if obj and obj.isValid and obj:isValid() then set[obj] = true end
  end
  return set
end

-- Generic record value from a GameObject (works for most item types).
local function objectValue(obj)
  if not obj or not obj.isValid or not obj:isValid() then return 0 end
  local t = obj.type; if not t or not t.record then return 0 end
  local ok, rec = pcall(t.record, obj)
  if not ok or not rec then return 0 end
  return rec.value or 0
end

-- ---------- public API ----------

-- Vanilla-equivalent “PC Clothing Modifier”: sum of EQUIPPED armor+clothing (optional weapon),
-- plus optional carried gold (off by default for parity).
function Wealth.clothingModifier(actor, opts)
  opts = opts or getOpts()
  if not actor or not actor.isValid or not actor:isValid() then return 0 end
  local equip = types.Actor.getEquipment(actor) or {}
  local sum = 0
  for _, obj in pairs(equip) do
    sum = sum + equippedItemValue(obj, opts.includeWeapons)
  end

  if opts.includeCarriedGold then
    local inv = types.Actor.inventory(actor)
    if inv then
      if inv.isResolved and not inv:isResolved() and inv.resolve then inv:resolve() end -- ensure list is stable
      local coins = inv.countOf and (inv:countOf('gold_001') or 0) or 0
      sum = sum + coins -- gold_001 value is 1 per coin
    end
  end

  return sum
end

-- Raw PERSONAL inventory market value (excludes equipped items).
function Wealth.inventoryValue(actor, opts)
  opts = opts or getOpts()
  if not actor or not actor.isValid or not actor:isValid() then return 0 end
  local inv = types.Actor.inventory(actor); if not inv then return 0 end

  -- Resolve leveled items to make the list permanent before iterating.
  if inv.isResolved and not inv:isResolved() and inv.resolve then inv:resolve() end

  local skip = equippedSet(actor)
  local total = 0

  -- 0.49: Inventory:getAll([type]) — omitting type returns *all* items.
  local list = inv.getAll and inv:getAll() or nil
  if not list then return 0 end

  for _, obj in ipairs(list) do
    if not skip[obj] then
      local rid = obj.recordId or ''
      if not (opts.excludeGold and rid == 'gold_001') then
        local val = objectValue(obj)
        local count = (obj.count or 1)          -- stacks: GameObject.count
        total = total + val * count
      end
    end
  end
  return total
end

-- clothing + weighted&capped personal inventory + weighted baseGold
function Wealth.totalWealth(actor, opts)
  opts = opts or getOpts()
  local wear = Wealth.clothingModifier(actor, opts)

  local invTerm = 0
  if opts.includeInventory then
    local invRaw = Wealth.inventoryValue(actor, opts)
    local weighted = (opts.inventoryWeight or 0) * invRaw
    invTerm = clamp(weighted, 0, math.max(0, opts.inventoryCap or math.huge))
  end

  local baseGoldTerm = 0
  if opts.includeBaseGold and types.NPC and types.NPC.objectIsInstance(actor) then
    local rec = types.NPC.record(actor)                   -- NpcRecord
    local bg = (rec and rec.baseGold) or 0               -- barter gold
    baseGoldTerm = (opts.baseGoldWeight or 1.0) * bg
  end

  return wear + invTerm + baseGoldTerm
end

-- Map wealth to bribe cost & (symmetric) disposition multipliers.
-- Returns { costMult, dispMult, raw, mid }.
function Wealth.multipliers(actor, opts)
  opts = opts or getOpts()
  local raw = Wealth.totalWealth(actor, opts)
  local mid = math.max(0, opts.wealthMidValue or 120)

  -- log-scale (per decade) around mid
  local decades = log10((raw + 1) / (mid + 1))
  local cost = 1 + (opts.perDecadeCost or 0.30) * decades
  cost = clamp(cost, 1 - (opts.maxCostBonus or 0.25), 1 + (opts.maxCostPenalty or 0.60))

  -- symmetric disposition: opposite of cost on a gentle curve
  local disp = 1 / math.sqrt(cost)

  if opts.debugWealth then
    local name = ""
    if actor and actor.object and actor.object.name then
      name = tostring(actor.object.name)
    elseif actor and actor.recordId then
      name = tostring(actor.recordId)
    end
    print(string.format("[Wealth] %s raw=%.1f mid=%.1f cost=%.3f disp=%.3f",
      name, raw, mid, cost, disp))
  end

  return { costMult = cost, dispMult = disp, raw = raw, mid = mid }
end

-- Poor-only disposition multiplier: never below 1.0.
-- Uses a dedicated “decades poorer than mid” curve; does NOTHING for raw >= mid.
function Wealth.poorDispositionMultiplier(actor, opts)
  opts = opts or getOpts()
  local m   = Wealth.multipliers(actor, opts)
  local raw = m.raw
  local mid = m.mid
  if raw >= mid then
    return 1.0, m
  end
  -- decades poorer than midpoint
  local decadesPoor = log10((mid + 1) / (raw + 1))
  local perDec = opts.poorDispPerDecade or 1.5
  local gamma  = opts.poorDispGamma or 1.1
  local cap    = opts.poorDispMax or 3.0
  local mult = (1 + perDec * decadesPoor)
  if gamma and gamma ~= 1 then mult = mult ^ gamma end
  mult = clamp(mult, 1.0, cap)

  if opts.debugWealth then
    local name = ""
    if actor and actor.object and actor.object.name then
      name = tostring(actor.object.name)
    elseif actor and actor.recordId then
      name = tostring(actor.recordId)
    end
    print(string.format("[WealthPoor] %s raw=%.1f mid=%.1f decades=%.3f poorMult=%.3f",
      name, raw, mid, decadesPoor, mult))
  end
  return mult, m
end

return Wealth
