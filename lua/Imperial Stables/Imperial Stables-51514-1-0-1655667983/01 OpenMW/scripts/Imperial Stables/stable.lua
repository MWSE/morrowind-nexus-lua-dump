local self = require('openmw.self')

local common = require('scripts.Imperial Stables.common')
local events = common.events
local activatorIds = common.activatorIds
if not activatorIds[self.recordId] then return end

local types = require('openmw.types')

local housed = nil

return {
  engineHandlers = {
    onActivated = function(obj)
      if not obj.type == types.Player then
        return
      end
      if housed and housed.active then
        housed.creature:sendEvent(events.Release)
        housed = nil
      else
        obj:sendEvent(events.Activated, {
          stable = self.object,
        })
      end
    end,
    onLoad = function(saved)
      if saved then
        housed = saved.housed
      end
    end,
    onSave = function()
      return {
        housed = housed,
      }
    end,
  },
  eventHandlers = {
    [events.House] = function(e)
      if not housed or not housed.active then
        housed = {
          creature = e.creature,
          active = true
        }
        housed.creature:sendEvent(events.Housed, {
          stable = self.object,
          owner = e.player,
        })
      end
    end,
    [events.CreatureStatus] = function(e)
      if housed and e.creature == housed.creature then
        housed.active = e.active
      else
        e.creature:sendEvent(events.Release)
      end
    end,
  }
}