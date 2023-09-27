local function init()
    -- Custom Icon for Skyrim Style Quest Notifications
    local ssqn = include("SSQN.interop")
    if (ssqn)  then
        ssqn.registerQIcon("tew_ach_main","\\Icons\\tew\\ashchi\\quest_ashchirps.tga")
        ssqn.registerQIcon("tew_ach_nudunir","\\Icons\\tew\\ashchi\\quest_ashchirps_nudunir.tga")
    end
end

event.register(tes3.event.initialized, init)
