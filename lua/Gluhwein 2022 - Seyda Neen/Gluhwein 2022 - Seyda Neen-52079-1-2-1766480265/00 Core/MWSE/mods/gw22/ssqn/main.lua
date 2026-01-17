local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("GW22","\\Icons\\GW22\\q\\GW22.dds") --using several underscores in quest ID
    end
end

event.register(tes3.event.initialized, init)