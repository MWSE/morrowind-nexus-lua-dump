local settings = require('scripts.AutoZoom.settings')
local zoom = require('scripts.AutoZoom.zoom')

settings.register()

return {
    engineHandlers = {
        onFrame = zoom.onFrame,
    },
}
