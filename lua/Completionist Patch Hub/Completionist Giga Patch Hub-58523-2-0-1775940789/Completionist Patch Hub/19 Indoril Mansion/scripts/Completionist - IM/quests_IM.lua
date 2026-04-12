local self = require('openmw.self')
local quests = {
    {
        id = "AAkarIndorilMansionQuest",
        name = "Trouble in the City of Light",
        category = "Miscellaneous",
        subcategory = "Mournhold",
        master = "Indoril Mansion",
        text = "Investigate reports of a fugitive necromancer beneath Mournhold Temple."
    },
}

local hasSent = false
return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                self:sendEvent("Completionist_RegisterPack", quests)
                hasSent = true
            end
        end
    }
}

-- Quest count: 1
