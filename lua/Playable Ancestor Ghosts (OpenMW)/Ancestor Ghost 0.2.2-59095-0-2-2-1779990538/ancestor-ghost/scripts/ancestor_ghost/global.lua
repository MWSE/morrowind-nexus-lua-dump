-- GLOBAL script: equipment slot enforcement for ancestor_ghost race.

local types = require('openmw.types')
local world = require('openmw.world')
local undeadFriendly = require('scripts.ancestor_ghost.undead_friendly_global')

local RACE_ID = 'ancestor_ghost'

local S = types.Actor.EQUIPMENT_SLOT
local LOCKED_SLOTS = {
  S.Helmet,
  S.Cuirass,
  S.Greaves,
  S.Boots,
  S.LeftPauldron,
  S.RightPauldron,
  S.LeftGauntlet,
  S.RightGauntlet,
  S.Shirt,
  S.Pants,
  S.Skirt,
  S.Robe,
  S.CarriedLeft,
  S.CarriedRight,
  S.Ammunition,
}

local CHECK_INTERVAL = 0.25
local timeSinceCheck = 0

local function getPlayerRace(player)
  local rec = types.NPC.record(player)
  return rec and rec.race or ''
end

local function enforceSlots(player)
  for _, slot in ipairs(LOCKED_SLOTS) do
    local item = types.Actor.getEquipment(player, slot)
    if item then
      player:sendEvent('Unequip', { slot = slot })
      player:sendEvent('AG_EquipBlocked', {})
    end
  end
end

return {
  engineHandlers = {
    onActorActive = function(actor)
      undeadFriendly.tryPacifyActor(actor)
    end,

    onUpdate = function(dt)
      timeSinceCheck = timeSinceCheck + dt
      if timeSinceCheck >= CHECK_INTERVAL then
        timeSinceCheck = 0
        for _, player in ipairs(world.players) do
          if getPlayerRace(player) == RACE_ID then
            enforceSlots(player)
          end
        end
      end
    end,
  },

  eventHandlers = {
    AG_UndeadFriendlySync = function(data)
      undeadFriendly.applySync(data)
    end,
  },
}
