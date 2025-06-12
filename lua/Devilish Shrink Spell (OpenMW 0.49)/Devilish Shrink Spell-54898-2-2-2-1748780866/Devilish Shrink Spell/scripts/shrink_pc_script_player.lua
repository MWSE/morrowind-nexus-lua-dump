
local self   = require('openmw.self')         -- available only in local scripts
local nearby = require('openmw.nearby')       -- available only in local scripts
local core   = require('openmw.core')

-- Fires every frame on the object this script is attached to (the Player)
local function onActive()
  -- Send the current item list to the global manager
  core.sendGlobalEvent('detd_DSS_nearbyItems', { nearbyItems = nearby.items })
end

return {
  engineHandlers = { onActive = onActive },
}
