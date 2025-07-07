local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("IEO","\\Icons\\md_IEO\\quest_IEO.dds")
    	ssqn.registerQIcon("IEO_SpreadingTheWord","\\Icons\\md_IEO\\quest_IEO.dds")
    end
end

event.register(tes3.event.initialized, init)