local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("X32_MTM","\\Icons\\SSQN\\MT.dds") --using several underscores in quest ID
    	ssqn.registerQIcon("x32","\\Icons\\x32\\q\\quest_thegarden.tga") --using several underscores in quest ID
    end
end

event.register(tes3.event.initialized, init)