local types  = require('openmw.types')
local world  = require('openmw.world')            -- allowed in Global scripts
local time   = require('openmw_aux.time')
local acti   = require('openmw.interfaces').Activation
local core   = require('openmw.core')

-- ── Tunables ─────────────────────────────────────────────────────────
local SCALE_MIN  = 0.1   -- fully shrunken
local SCALE_MAX  = 1.0   -- normal height
local SCALE_RATE = 1.0   -- scale units per *second* (1.0 ⇒ ~0.9 s to fully shrink)
local TICK       = 0.01  -- how often we *look* at the player (seconds)

local SPELL_SHRINK  = 'detd_shrink_spell'        -- real shrink effect
local SPELL_MARKER  = 'detd_shrink_spell_init'   -- MUST be present for any scaling

-- ── Helpers ──────────────────────────────────────────────────────────
local function syncInventoryScale(player)
  local s = player.scale
  for _, item in ipairs(types.Actor.inventory(player):getAll()) do
    item:setScale(s)
  end
end

local function hasSpell(player, id)
  return types.Actor.activeSpells(player):isSpellActive(id)
end

-- ── Event: fix cell-change item scales (0.5 ⇒ 0.1) ───────────────────
local function detd_DSS_nearbyItems(data)
  for _, item in ipairs(data.nearbyItems) do
    local s = item.scale
    if s > 0.49 and s < 0.51 then -- the engine sometimes resets to 0.5
      item:setScale(SCALE_MIN)
    end
  end
end

-- ── Main update loop – time-based, FPS-independent ────────────────
local prevSim = core.getSimulationTime()

time.runRepeatedly(function()
  local player = world.players[1]
  if not player then return end

  -- NEW CONDITION ────────────────────────────────────────────────
  -- Do nothing unless the marker spell is active.
  if not hasSpell(player, SPELL_MARKER) then
    return
  end
  ----------------------------------------------------------------

  local nowSim = core.getSimulationTime()
  local dt     = nowSim - prevSim
  prevSim      = nowSim
  if dt <= 0 then return end

  -- Decide where we *want* to be
  local target = hasSpell(player, SPELL_SHRINK) and SCALE_MIN or SCALE_MAX
  local cur    = player.scale

  -- Already there?
  if math.abs(cur - target) < 1e-6 then return end

  -- Advance towards target at constant RATE (units per second)
  local delta     = SCALE_RATE * dt
  local newScale  = cur + ((target > cur) and delta or -delta)

  -- Clamp if we ran past the target this tick
  if (target > cur and newScale > target) or (target < cur and newScale < target) then
    newScale = target
  end

  player:setScale(newScale)
  syncInventoryScale(player)
end, TICK * time.second)

-- ── Activation filter: small player can’t use big objects ───────────
local function forbidActivate(object)
  local player = world.players[1]
  if not player then return end
  -- Block if: player is shrunk, trying to use a full-size object
  if player.scale < 0.8 and object.scale > 0.99 and 
     hasSpell(player, SPELL_SHRINK) then
    return false
  end
end

for _, t in ipairs {
  types.Miscellaneous, types.Potion, types.Book, types.Clothing, types.Container,
  types.Door, types.Light, types.Weapon, types.Armor, types.Ingredient,
} do
  acti.addHandlerForType(t, forbidActivate)
end
