local world = require("openmw.world")

return {
    eventHandlers = {
        NMIA_TeleportHome = function(data)
            local actor = data.actor
            if not actor or not actor:isValid() then return end
            actor:teleport(data.cell, data.position, { rotation = data.rotation })
        end,
    },
}