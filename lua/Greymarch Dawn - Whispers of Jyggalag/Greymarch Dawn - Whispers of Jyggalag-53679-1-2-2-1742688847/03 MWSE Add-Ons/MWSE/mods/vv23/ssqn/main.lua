local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("vv23_tg","\\Icons\\SSQN\\TG.dds") --using several underscores in quest ID
    	ssqn.registerQIcon("vv23","\\Icons\\vv23\\q\\jyggalag.dds") --using several underscores in quest ID
    end
end

event.register(tes3.event.initialized, init)