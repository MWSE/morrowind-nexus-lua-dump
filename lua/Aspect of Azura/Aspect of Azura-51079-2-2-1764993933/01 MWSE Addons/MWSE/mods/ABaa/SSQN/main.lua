local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("ABaa","\\Icons\\ABaa\\q\\quest_azura.tga") --using several underscores in quest ID
    end
end

event.register(tes3.event.initialized, init)