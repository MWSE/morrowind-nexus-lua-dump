local ssqn = include("SSQN.interop")

local function init() 
    if (ssqn) then
		ssqn.registerQIcon("INTA","\\Icons\\INTA\\ic_q_default.dds")
    end
end

event.register(tes3.event.initialized, init)