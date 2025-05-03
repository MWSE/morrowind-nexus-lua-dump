-- version 0.1 cleanup
local toCleanUp = {}
return {
    engineHandlers = {
        onLoad = function(data)
            if data and data.transporters then
                toCleanUp = data.transporters
            end
        end,
        onPlayerAdded = function()
            for actorId, lightObject in pairs(toCleanUp) do
                if lightObject:isValid() and lightObject.count > 0 then
                    lightObject:remove()
                end
            end
        end
    }
}
