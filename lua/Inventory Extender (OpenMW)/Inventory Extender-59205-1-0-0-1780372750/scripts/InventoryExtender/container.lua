local anim = require('openmw.animation')
local self = require('openmw.self')
local core = require('openmw.core')

local eventHandlers = {
    IE_ContainerClosed = function()
        anim.playBlended(self, 'containerclose', { priority = anim.PRIORITY.Scripted })
    end,
}
-- deprecated
eventHandlers.MI_ContainerClosed = eventHandlers.IE_ContainerClosed

return {
    engineHandlers = {
        onInactive = function()
            if self.recordId == 'stolen_goods' then
                core.sendGlobalEvent('IE_StolenChestInactive', self)
            end
        end
    },
    eventHandlers = eventHandlers,
}