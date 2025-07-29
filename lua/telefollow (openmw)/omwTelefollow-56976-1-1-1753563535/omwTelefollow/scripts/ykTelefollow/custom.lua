local getTargets = require('openmw.interfaces').AI.getTargets
local self = require('openmw.self')

local function isFollowing(actor)
   for _, target in ipairs(getTargets('Follow')) do
      if target == actor then
         return true
end end end

return {
   eventHandlers = {
      ykReqTelefollowStop = function(actor)
         if not isFollowing(actor) then
            actor:sendEvent('ykResTelefollowStop', self)
         end
      end,
   },
   engineHandlers = {
      onInit = function(actor)
         if isFollowing(actor) then actor:sendEvent('ykReqTelefollowStart', self)
         else require('openmw.core').sendGlobalEvent('ykResTelefollowStop', self)
         end
      end,
   },
}
