local self = require('openmw.self')
local types = require("openmw.types")
local core = require('openmw.core')
local time = require('openmw_aux.time')
local smellyYawChangeCounter = 0
local endsmellyevent = 0
local isPickpocketing = false -- New flag to track pickpocket context

---@param integer a Degrees
---@param integer b Degrees
local function angle_difference(a, b)
  b = b - math.rad(180)
  local diff = b - a
  return math.atan2(math.sin(diff), math.cos(diff))
end

return {
  engineHandlers = {
    onActivated = function(activatingActor)
      if types.Actor.stats.dynamic.health(self).current == 0 then return end
      -- Reset counter and flag
      smellyYawChangeCounter = 0
      isPickpocketing = true -- Assume pickpocketing until proven otherwise (e.g., dialogue starts)
      stopFn = time.runRepeatedly(function()
        if smellyYawChangeCounter > 40 then
          endsmellyevent = 1
          stopFn() 
          print 'counter fulfilled'
          smellyYawChangeCounter = 0
          core.sendGlobalEvent('Pause')
          -- Unpause if this was pickpocketing, not dialogue
          if isPickpocketing then
            print 'Unpausing after pickpocket'
            core.sendGlobalEvent('Unpause')
          end
          return
        end
        local smellyYawChange = angle_difference(self.rotation:getYaw(), activatingActor.rotation:getYaw())
        local smellyYawChangepart = smellyYawChange / 6
        self.controls.yawChange = smellyYawChangepart
        smellyYawChangeCounter = (smellyYawChangeCounter + 1)
        print (smellyYawChangeCounter)
      end,
      0.001 * time.second )
    end,
  },
  eventHandlers = {
    SMELLY_INTERRUPTTURNING = function()
      if stopFn then
        print 'event received'
        stopFn()
        stopFn = nil
        isPickpocketing = false -- Dialogue likely triggered this, so it’s not pickpocketing
        core.sendGlobalEvent('Unpause')
      end
    end,
  }
}