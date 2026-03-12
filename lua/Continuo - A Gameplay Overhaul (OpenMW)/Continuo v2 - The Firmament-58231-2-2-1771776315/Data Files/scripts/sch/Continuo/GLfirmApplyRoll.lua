
local types = require('openmw.types')

local storage = require('openmw.storage')
local core = require('openmw.core')

local firmStore = storage.globalSection('sch_contfirm')
local SEVEN_DAYS = 7 * 86400

local function safeAddSpell(actor, spellId)
  if not actor or type(spellId) ~= 'string' then return end

  local spells = actor.type.spells(actor)
  if not spells or not spells.add then return end

  pcall(function()
    spells:add(spellId)
  end)
end

local function applyRoll(actor, roll)
  if not actor or type(roll) ~= 'table' then return end

  local abilities = roll.abilities
  local power = roll.power

  if type(abilities) == 'table' then
    for i = 1, 3 do
      safeAddSpell(actor, abilities[i])
    end
  end

  safeAddSpell(actor, power)
  actor:sendEvent('SCH_ContFirmStarted', { days = 7 })

  local expiry = core.getGameTime() + SEVEN_DAYS
  firmStore:set('firmActive', true)
  firmStore:set('firmExpiryTime', core.getGameTime() + SEVEN_DAYS)

  -- optional: reset warning flag
  firmStore:set('firmWarned', false)
end

return {
  eventHandlers = {

    SCH_ContFirmApplyRoll = function(data)
      if type(data) ~= 'table' then return end

      local actor = data.actor
      local roll = data.roll

      if not actor or not roll then return end

      applyRoll(actor, roll)
    end,

  }
}