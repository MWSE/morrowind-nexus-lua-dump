local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local core = require("openmw.core")

local function onInit(actor)
    if(self.recordId == "zhac_destinationpicker") then
    for i, record in ipairs(nearby.actors) do --find the door with the cell we want
        if(record.type == types.Player) then
            record:sendEvent("addDestinationWindow")

        end
    end
    core.sendGlobalEvent("DaisyUtilsDelete",self)
    end
end

    return {
        engineHandlers = {
            onInit = onInit,
        }
    }