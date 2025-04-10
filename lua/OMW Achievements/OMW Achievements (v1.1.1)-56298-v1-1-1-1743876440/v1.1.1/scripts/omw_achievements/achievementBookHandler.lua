local types = require('openmw.types')
local self = require('openmw.self')

local function onActivated(actor)
    local book_id = types.Book.record(self.object).id
    actor:sendEvent("bookRead", {
        id = types.Book.record(self.object).id
    })
end

return {
    engineHandlers = {
        onActivated = onActivated
    }
}
