local world = require("openmw.world")
local types = require("openmw.types")

local Actor = types.Actor

-- =========================
-- CONFIG
-- =========================

local CAMP_ITEM_ID = ("sch_continuo_mi_campsup"):lower()
local CAMP_BED_ID  = ("sch_continuo_ac_campbed"):lower()
local DIE_SPELL_ID = "sch_continuo_sp_die"

-- =========================
-- Gold Loss on Death
-- =========================

local function halveGold(player)
  local inv = Actor.inventory(player)
  if not inv then return end

  local goldCount = inv:countOf("gold_001") or 0
  if goldCount <= 0 then return end

  local div = math.random(5, 10) -- removes between 1/5 and 1/10
  local n = math.floor(goldCount / div)

  if n > 0 then
    local gold = inv:find("gold_001")
    if gold then
      gold:remove(n)
    end
  end
end

-- =========================
-- Remove Death Spell
-- =========================

local function removeDeathSpell(player)
  if not player then return end

  local spells = player.type.spells(player)
  if not spells then return end

  pcall(function()
    spells:remove(DIE_SPELL_ID)
  end)
end

-- Apply consequences (shared)
local function applyDeathConsequences(player)
  halveGold(player)
  removeDeathSpell(player)
end

-- =========================
-- Replace Dropped Camping Supply With Bed
-- =========================

local function onObjectActive(obj)
  if not obj or obj.recordId ~= CAMP_ITEM_ID then
    return
  end

  local cell = obj.cell
  local pos  = obj.position
  local rot  = obj.rotation

  -- Create camp bed activator
  local bed = world.createObject(CAMP_BED_ID, 1)
  bed:teleport(cell, pos, rot)

  -- Remove dropped camping supplies
  obj:remove()
end

-- =========================
-- Event Handlers
-- =========================

return {
  engineHandlers = {
    onObjectActive = onObjectActive
  },

  eventHandlers = {

    -- NEW: Used by intervention branch (no teleport)
    Continuo_ApplyDeathConsequences = function(_data)
      local player = world.players[1]
      if not player then return end
      applyDeathConsequences(player)
    end,

    -- Teleport branch: teleport + consequences
    Continuo_TeleportPlayer = function(data)
      local player = world.players[1]
      if not player then return end
      if not data or not data.cell or not data.pos then return end

      player:teleport(data.cell, data.pos)
      applyDeathConsequences(player)
    end,
  }
}