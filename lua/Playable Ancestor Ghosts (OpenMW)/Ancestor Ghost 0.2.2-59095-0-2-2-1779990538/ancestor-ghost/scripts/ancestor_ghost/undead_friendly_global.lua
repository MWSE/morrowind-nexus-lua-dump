-- GLOBAL: detect undead, track restore values, dispatch pacify to creature local scripts.
-- OpenMW 0.51 cannot write AI fight stats from global (unlike MWSE USkele mobile.fight = 0).

local types = require('openmw.types')
local world = require('openmw.world')

local M = {}

local pacifyEnabled = false
-- formId -> fight modifier before pacify (for restore)
local pacified = {}

local function isUndeadCreature(actor)
  if not actor or not actor:isValid() then return false end
  if not types.Creature.objectIsInstance(actor) then return false end
  if types.Actor.isDead(actor) then return false end
  local rec = types.Creature.record(actor)
  return rec ~= nil and rec.type == types.Creature.TYPE.Undead
end

local function requestPacify(actor)
  if not isUndeadCreature(actor) then return end

  local formId = actor.id
  if formId and pacified[formId] == nil then
    local ok, fight = pcall(function()
      return types.Actor.stats.ai.fight(actor)
    end)
    if ok and fight then
      pacified[formId] = fight.modifier
    end
  end

  actor:sendEvent('AG_PacifyUndead', {})
end

local function restoreAll()
  for formId, modifier in pairs(pacified) do
    pacified[formId] = nil
    local ok, actor = pcall(function()
      return world.getObjectByFormId(formId)
    end)
    if ok and actor and actor:isValid() then
      actor:sendEvent('AG_RestoreFight', { modifier = modifier })
    end
  end
end

local function pacifyActiveUndead()
  for _, actor in ipairs(world.activeActors) do
    requestPacify(actor)
  end
end

function M.tryPacifyActor(actor)
  if not pacifyEnabled then return end
  requestPacify(actor)
end

function M.applySync(data)
  local enabled = type(data) == 'table' and data.enabled == true
  if enabled == pacifyEnabled then
    if enabled then
      pacifyActiveUndead()
    end
    return
  end
  pacifyEnabled = enabled
  if enabled then
    pacifyActiveUndead()
  else
    restoreAll()
  end
end

return M
