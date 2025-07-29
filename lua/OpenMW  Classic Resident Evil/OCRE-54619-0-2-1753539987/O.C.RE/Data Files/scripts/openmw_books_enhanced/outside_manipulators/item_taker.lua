local core = require('openmw.core')
local types = require('openmw.types')
local ui = require('openmw.ui')
local self = require('openmw.self')

local IT = {}

function IT.takeItem(activatedBookObject)
    if not activatedBookObject.enabled then
        return
    end

    local isStolen =
        activatedBookObject.owner.recordId
        or
        (activatedBookObject.owner.factionId and types.NPC.getFactionRank(self, activatedBookObject.owner.factionId) == 0)
        or
        (activatedBookObject.owner.factionId and types.NPC.getFactionRank(self, activatedBookObject.owner.factionId) < activatedBookObject.owner.factionRank)

    core.sendGlobalEvent(
        "openmwBooksEnhancedBookTaken",
        { player = self, bookObject = activatedBookObject, isStolen = isStolen })
end

function IT.handleCrimeHackCleanup(data)
    core.sendGlobalEvent(
        "openmwBooksEnhancedBookStolenSoRemoveTempObjectsNowThatTickHasPassed",
        data)
end

return IT
