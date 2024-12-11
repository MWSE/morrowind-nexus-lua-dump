local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("md_ABC_journal","\\Icons\\md_ABC\\q\\quest_abc.tga") --using several underscores in quest ID
    end
end

event.register(tes3.event.initialized, init)