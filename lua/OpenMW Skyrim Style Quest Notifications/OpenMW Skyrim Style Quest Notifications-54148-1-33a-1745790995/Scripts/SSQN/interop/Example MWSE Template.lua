local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then

	-- add commands to register an SSQN icon

    	-- ssqn.registerQIcon("PC_m1_AFP01","\\Icons\\pc\\q\\PC_m1_AFP.dds")
    	-- ssqn.registerQIcon("PC_m1_AFP02","\\Icons\\pc\\q\\PC_m1_AFP.dds")

    end
    if (ssqn) and (ssqn.blockQBanner) then

        -- add commands to block a journal ID from showing banner notifications

        -- ssqn.blockQBanner("PC_m1_Anv_GoldenrodBR")
        -- ssqn.blockQBanner("PC_m1_Anv_GoldenrodDR")

    end
    if (ssqn) and (ssqn.addQComment) then

        -- add commands to show a message banner when a journal stage is triggered

        -- ssqn.addQComment("ms_lookout", 10, "Find Fargoths' secret gold")
        -- ssqn.addQComment("ms_lookout", 20, "Watch from the top of the lighthouse at night")

    end
end

event.register(tes3.event.initialized, init)


