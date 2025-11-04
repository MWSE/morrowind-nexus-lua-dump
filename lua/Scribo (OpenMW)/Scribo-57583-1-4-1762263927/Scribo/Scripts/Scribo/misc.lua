local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local cmn = require('Scripts.Scribo.common')

local function onActivated(actor)
    -- print('scribo: misc activated from world')
    local miscModel = types.Miscellaneous.record(self).model

    if miscModel == cmn.bookTemplates[3].model then
        actor:sendEvent("ProcessingItem", {
            misc = self,
            inventory = false
        })
    end
end

return {
    engineHandlers = {
        onActivated = onActivated
    }
}
