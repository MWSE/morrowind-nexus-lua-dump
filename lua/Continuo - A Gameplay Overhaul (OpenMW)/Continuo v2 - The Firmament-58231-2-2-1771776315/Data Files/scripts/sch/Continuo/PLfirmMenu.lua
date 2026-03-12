local self = require('openmw.self')
local types = require('openmw.types')
local Actor = types.Actor

local StarAttunementUI = require('scripts.sch.continuo.UIfirmAttune')

-- NEW: require roller tables
local Roller = require('scripts.sch.continuo.SYSfirmAttunementRoll')

-- Dwemer receptacle record id (lowercase safest)
local RECEPTACLE_ID = 'sch_contfirm_cl_starring'

local lastEquipped = false

-- =========================
-- Build Firmament Spell Set
-- =========================

local FIRMAMENT_SPELLS = {}

-- collect positives
for _, list in pairs(Roller.POSITIVE_ABILITIES) do
  for _, id in ipairs(list) do
    FIRMAMENT_SPELLS[id] = true
  end
end

-- collect negatives
for _, id in pairs(Roller.NEGATIVE_ABILITIES) do
  FIRMAMENT_SPELLS[id] = true
end

-- collect powers
for _, id in pairs(Roller.POWER_TABLE) do
  FIRMAMENT_SPELLS[id] = true
end

-- =========================
-- Helpers
-- =========================

local function isReceptacleEquipped()
  local equip = Actor.getEquipment(self)
  for _, item in pairs(equip) do
    if item and item.recordId == RECEPTACLE_ID then
      return true
    end
  end
  return false
end

local function playerHasFirmamentSpell()
  local active = Actor.activeSpells(self)
  if not active then return false end

  for spellId in pairs(FIRMAMENT_SPELLS) do
    if active:isSpellActive(spellId) then
      return true
    end
  end

  return false
end

-- =========================
-- Engine
-- =========================

return {
  engineHandlers = {
    onUpdate = function()

      -- HARD BLOCK: if player already attuned, never open
      if playerHasFirmamentSpell() then
        if StarAttunementUI.isOpen() then
          StarAttunementUI.close()
        end
        lastEquipped = false
        return
      end

      local equipped = isReceptacleEquipped()

      if equipped and not lastEquipped then
        StarAttunementUI.open()
      elseif (not equipped) and lastEquipped then
        StarAttunementUI.close()
      end

      lastEquipped = equipped
    end,
  },
}