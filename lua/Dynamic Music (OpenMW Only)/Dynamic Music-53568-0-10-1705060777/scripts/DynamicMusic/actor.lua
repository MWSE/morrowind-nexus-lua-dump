local nearby = require('openmw.nearby')
local self = require('openmw.self')
local AI = require('openmw.interfaces').AI
local types = require('openmw.types')

local combatState = false

local function emitEvent(eventName)
  for _, actor in ipairs(nearby.actors) do
    if actor.type == types.Player then
      actor:sendEvent(eventName, { actor = self });
    end
  end
end

local function onActive()

end

local function onInactive()
  if combatState then
    combatState = false
    emitEvent('disengaging');
  end
end

local function onUpdate(dt)
  local activePackage = AI.getActivePackage()

  if not combatState and activePackage and activePackage.type == "Combat" and types.Actor.stats.dynamic.health(self).current > 0 then
    combatState = true
    emitEvent('engaging')
  end

--print("health " ..types.Actor.stats.dynamic.health(self).current)

  if combatState and (not activePackage or activePackage.type ~= "Combat" or types.Actor.stats.dynamic.health(self).current <= 0) then
    combatState = false
    emitEvent('disengaging');
  end
end

return {
  engineHandlers = {
    onActive = onActive,
    onInactive = onInactive,
    onUpdate = onUpdate
  }
}
