local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("ABpom_Journal","\\Icons\\oaab\\q\\quest_pomegranates.tga")
    end
end

event.register(tes3.event.initialized, init)