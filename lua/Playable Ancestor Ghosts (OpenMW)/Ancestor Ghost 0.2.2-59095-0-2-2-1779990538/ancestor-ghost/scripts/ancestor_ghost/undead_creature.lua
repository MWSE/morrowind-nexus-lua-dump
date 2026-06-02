-- CREATURE local script: zero Fight on this actor when asked.
-- OpenMW only allows AI stat writes on the actor's own local script (not from global).

local types = require('openmw.types')
local self = require('openmw.self')

local function isUndeadSelf()
  if not types.Creature.objectIsInstance(self) then return false end
  if types.Actor.isDead(self) then return false end
  local rec = types.Creature.record(self)
  return rec ~= nil and rec.type == types.Creature.TYPE.Undead
end

local function pacifySelf()
  if not isUndeadSelf() then return end
  local fight = types.Actor.stats.ai.fight(self)
  if fight.modified <= 0 then return end
  fight.modifier = fight.modifier - fight.modified
  self:sendEvent('RemoveAIPackages', 'Combat')
end

return {
  eventHandlers = {
    AG_PacifyUndead = function()
      pacifySelf()
    end,

    AG_RestoreFight = function(data)
      if not isUndeadSelf() then return end
      local modifier = data and data.modifier
      if modifier == nil then return end
      types.Actor.stats.ai.fight(self).modifier = modifier
    end,
  },
}
