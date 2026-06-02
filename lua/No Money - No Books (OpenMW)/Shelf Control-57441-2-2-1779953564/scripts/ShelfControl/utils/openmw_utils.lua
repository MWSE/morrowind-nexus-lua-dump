local world = require("openmw.world")

require("scripts.ShelfControl.utils.consts")

function GetActiveActorByRecordId(recordId)
    for _, activeActor in ipairs(world.activeActors) do
        if activeActor.recordId == recordId then
            return activeActor
        end
    end
end

function GetRecord(obj)
    return obj.type.records[obj.recordId]
end

function IsSpellbook(recordId)
    return Spellbooks[recordId]
    -- support for The Spell Tomes - Magic Books of Morrowind to Study and Cast to
    -- https://www.nexusmods.com/morrowind/mods/57432
        or string.find(recordId, "^spelltome_")
end
