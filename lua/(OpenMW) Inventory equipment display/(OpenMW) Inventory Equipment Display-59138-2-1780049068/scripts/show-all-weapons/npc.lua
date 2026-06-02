local self   = require('openmw.self')
local common = require('scripts.show-all-weapons.common')

return {
    engineHandlers = {
        onUpdate = common.makeUpdateHandler(self),
    }
}
