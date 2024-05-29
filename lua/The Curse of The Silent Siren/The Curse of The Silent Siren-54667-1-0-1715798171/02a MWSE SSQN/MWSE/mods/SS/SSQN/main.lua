local ssqn = include("SSQN.interop")

local function init()
    if (ssqn) then
	    ssqn.registerQIcon("SSMainQuest","\\Icons\\SS\\q\\quest_silentsiren.tga")
    end
end

event.register(tes3.event.initialized, init)