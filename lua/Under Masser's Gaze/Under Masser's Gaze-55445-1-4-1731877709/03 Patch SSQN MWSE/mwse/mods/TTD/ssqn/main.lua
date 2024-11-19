local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("TTD","\\Icons\\TTD\\q\\TTD.dds") --using several underscores in quest ID
	ssqn.registerQIcon("ttd","\\Icons\\TTD\\q\\TTD.dds") --using several underscores in quest ID
    end
end

event.register(tes3.event.initialized, init)