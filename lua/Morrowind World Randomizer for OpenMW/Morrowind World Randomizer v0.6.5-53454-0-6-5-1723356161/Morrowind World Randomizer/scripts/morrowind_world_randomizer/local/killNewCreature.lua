local self = require('openmw.self')
local async = require('openmw.async')
local core = require('openmw.core')
local Actor = require('openmw.types').Actor

Actor.stats.dynamic.health(self).current = 0
core.sendGlobalEvent("mwrbd_processDeathOfDisabled", {reference = self})

return {
    
}