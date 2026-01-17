local world = require("openmw.world")

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