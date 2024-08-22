local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local nearby = require('openmw.nearby')

local function onActive()
  local nearbyItems = nearby.items
  core.sendGlobalEvent("detd_DSS_nearbyItems", { nearbyItems = nearbyItems})
end

   return {
  engineHandlers = {
    onActive = onActive,
         }
          }
