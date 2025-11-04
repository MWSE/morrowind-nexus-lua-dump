local I = require('openmw.interfaces')
local types = require('openmw.types')

I.ItemUsage.addHandlerForType(types.Book, function(item, actor)
    actor:sendEvent("readBook", {
        book = item
    })
end)
