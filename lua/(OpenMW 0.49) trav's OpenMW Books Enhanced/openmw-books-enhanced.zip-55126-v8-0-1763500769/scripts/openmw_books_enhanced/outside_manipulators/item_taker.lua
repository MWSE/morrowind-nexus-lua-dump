local core = require('openmw.core')
local types = require('openmw.types')
local ui = require('openmw.ui')
local self = require('openmw.self')

local IT = {}

function IT.takeItem(activatedBookObject)
    if not activatedBookObject.enabled then
        return
    end

    local isStolen = activatedBookObject.owner.recordId;
    if (not isStolen) and (activatedBookObject.owner.factionId ~= nil) then
        local ownerFactionId = types.NPC.getFactionRank(self, activatedBookObject.owner.factionId)
        if ownerFactionId ~= nil then
            isStolen = (ownerFactionId == 0)
            if (not isStolen) and (activatedBookObject.owner.factionRank ~= nil) then
                isStolen = (ownerFactionId < activatedBookObject.owner.factionRank)
            end
        end
    end

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
