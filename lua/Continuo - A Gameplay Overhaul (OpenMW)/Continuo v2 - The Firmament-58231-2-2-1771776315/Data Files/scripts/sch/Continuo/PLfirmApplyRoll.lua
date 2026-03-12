
local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')

local Actor = types.Actor

local playerSection = storage.playerSection('sch_contfirm')

-- Optional: lightweight persistence to avoid re-applying same roll if event re-fired
local function wasApplied(key)
  return playerSection:get(key) == true
end

local function markApplied(key)
  playerSection:set(key, true)
end

local function safeAddSpell(spellId)
  if type(spellId) ~= 'string' or spellId == '' then return false end
  local spells = self.type.spells(self)
  if not spells or not spells.add then return false end

  -- Many OpenMW spell stores tolerate duplicates; still keep it safe.
  local ok = pcall(function()
    spells:add(spellId)
  end)
  return ok
end

local function applyRoll(roll)
  if type(roll) ~= 'table' then return end

  local abilities = roll.abilities
  local power = roll.power

  -- Build a stable idempotency key for this exact outcome
  local a1 = (type(abilities) == 'table' and abilities[1]) or ''
  local a2 = (type(abilities) == 'table' and abilities[2]) or ''
  local a3 = (type(abilities) == 'table' and abilities[3]) or ''
  local p  = (type(power) == 'string' and power) or ''
  local key = ("applied:%s|%s|%s|%s"):format(a1, a2, a3, p)

  if wasApplied(key) then
    return
  end

  -- Apply abilities
  if type(abilities) == 'table' then
    for i = 1, 3 do
      safeAddSpell(abilities[i])
    end
  end

  -- Apply power
  safeAddSpell(power)

  markApplied(key)
end

return {
  eventHandlers = {
    SCH_ContFirmApplyRoll = function(data)
      -- Ensure event is meant for THIS player
      if type(data) ~= 'table' then return end
      if data.actor and data.actor ~= (self.object or self) then return end

      applyRoll(data.roll)
    end,
  },
}