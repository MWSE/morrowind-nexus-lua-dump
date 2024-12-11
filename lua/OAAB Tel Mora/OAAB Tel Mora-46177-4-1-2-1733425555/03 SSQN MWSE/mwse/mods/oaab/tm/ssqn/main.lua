local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then
    	ssqn.registerQIcon("OAAB_TMora_AMonopolyOnSpies","\\Icons\\SSQN\\HT.dds")
        ssqn.registerQIcon("OAAB_TMora_Collections","\\Icons\\SSQN\\HT.dds")
        ssqn.registerQIcon("OAAB_TMora_ExpandedGarden","\\Icons\\SSQN\\HT.dds")
        ssqn.registerQIcon("OAAB_TMora_Healer_01","\\Icons\\SSQN\\TT.dds")
        ssqn.registerQIcon("OAAB_TMora_Healer_02","\\Icons\\SSQN\\TT.dds")
        ssqn.registerQIcon("OAAB_TMora_KillDratha","\\Icons\\SSQN\\HT.dds")
        ssqn.registerQIcon("OAAB_TMora_Lette","\\Icons\\SSQN\\TT.dds")
        ssqn.registerQIcon("OAAB_TMora_MasterEndar","\\Icons\\SSQN\\HT.dds")
        ssqn.registerQIcon("OAAB_TMora_RadrasCharity","\\Icons\\SSQN\\HT.dds")
        ssqn.registerQIcon("OAAB_TMora_TempleShrine","\\Icons\\SSQN\\TT.dds")
        ssqn.registerQIcon("OAAB_TMora_TempleShrine_A","\\Icons\\SSQN\\TT.dds")
        ssqn.registerQIcon("OAAB_TMora_VampireAttack","\\Icons\\SSQN\\HT.dds")
    end
end

event.register(tes3.event.initialized, init)