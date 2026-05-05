
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local types = require("openmw.types")

if not self.globalVariable then return end

local function setIsRented(state)
    if state then
        if self.type == types.Door then
            
        end

    end

end

return {
    interfaceName = "ZS_InnOverhaul",
    interface = {
    },
    engineHandlers = {
    },
    eventHandlers = {
    }
}
