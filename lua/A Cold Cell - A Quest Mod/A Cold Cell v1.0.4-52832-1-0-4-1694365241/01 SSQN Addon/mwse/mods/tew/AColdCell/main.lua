local function init()
    -- Custom Icon for Skyrim Style Quest Notifications
    local ssqn = include("SSQN.interop")
    if (ssqn)  then
        ssqn.registerQIcon("tew_acoldcell","\\Icons\\tew\\acoldcell\\quest_acoldcell.tga")
    end
end

event.register(tes3.event.initialized, init)
