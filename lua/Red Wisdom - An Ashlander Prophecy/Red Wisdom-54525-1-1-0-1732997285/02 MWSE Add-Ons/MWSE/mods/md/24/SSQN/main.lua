local ssqn = include("SSQN.interop")

local function init()
    if (ssqn) then
	    ssqn.registerQIcon("md24_j_redwisdom","\\Icons\\md24\\q\\quest_redwisdom.dds")
        ssqn.registerQIcon("md24_j_guarhide","\\Icons\\md24\\q\\quest_redwisdom.dds")
    end
end

event.register(tes3.event.initialized, init)