local self = require('openmw.self')
local types = require('openmw.types')

-- for activating books in the worldspace
local function onActivated(activatingActor)
    if types.Book.objectIsInstance(self.object) then
        activatingActor:sendEvent('openmwBooksEnhancedBookActivated', { activatedBookObject = self.object })
    end
end

return
{
    engineHandlers = { onActivated = onActivated }
}
