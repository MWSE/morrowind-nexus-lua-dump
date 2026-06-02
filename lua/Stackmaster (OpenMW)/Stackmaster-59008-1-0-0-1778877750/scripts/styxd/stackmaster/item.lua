local self = require'openmw.self'
local types = require'openmw.types'

local events = require'scripts.styxd.stackmaster.events'
local StackInfo = require'scripts.styxd.stackmaster.StackInfo'

local M = {}

M.engineHandlers = {}

-- NOTE: Contrary to documentation, as of 0.50.0,
-- onActivated receives the count of the stack that was picked up,
-- instead of 0.
-- I'm not sure if there are further implications of that.
-- But for now it works.
function M.engineHandlers.onActivated(actor)
    if types.Player.objectIsInstance(actor) then
        events.PlayerActivatedStack.sendEvent{
            player = actor,
            stackInfoProps = StackInfo.propsFromGameObject(self.object)
        }
    end
end

return M
