local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("MD_AshGem","\\Icons\\md_ashgem\\q\\quest_bensamsi.tga") --using several underscores in quest ID
    end
end

event.register(tes3.event.initialized, init)