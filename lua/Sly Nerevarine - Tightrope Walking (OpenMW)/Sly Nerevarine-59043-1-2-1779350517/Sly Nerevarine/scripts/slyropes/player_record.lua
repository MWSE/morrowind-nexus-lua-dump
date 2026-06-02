local playerCore = require('scripts.slyropes.player_core')
local detector = require('scripts.slyropes.detector_record')
local settings = require('scripts.slyropes.settings')

-- Register in the player script context, matching the storage section used at runtime.
settings.register('player-script-load')
settings.refresh()

return {
    engineHandlers = playerCore.makeHandlers(detector, 'record/model'),
}
