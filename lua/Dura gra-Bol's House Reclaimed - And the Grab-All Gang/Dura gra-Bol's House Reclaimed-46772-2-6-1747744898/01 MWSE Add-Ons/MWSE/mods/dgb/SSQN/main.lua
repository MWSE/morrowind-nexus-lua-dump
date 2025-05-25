local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("dgb_journal","\\Icons\\dgb\\q\\quest_graball.dds")
    end
end

event.register(tes3.event.initialized, init)