local self = require('openmw.self')
local types = require('openmw.types')


return {
  engineHandlers = {
    onActivated = function(actor)
      if self.recordId == "aav_deathbook" then
        actor:sendEvent('kill', self.object)
      end
    end,
  }
}
