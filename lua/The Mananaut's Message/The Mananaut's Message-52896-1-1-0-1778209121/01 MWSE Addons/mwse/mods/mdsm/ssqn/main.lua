local ssqn = include("SSQN.interop")

local function init()
    if (ssqn) then
	    ssqn.registerQIcon("mdSM_Journal","\\Icons\\mdsm\\q\\quest_mananaut.tga") --using several underscores in quest ID
    end
end

event.register(tes3.event.initialized, init)