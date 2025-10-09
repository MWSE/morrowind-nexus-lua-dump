
---Agent of Change SSQN Icon

local ssqn = include("SSQN.interop")

local function init() 
    if (ssqn) then
        -- Agent of Change
		ssqn.registerQIcon("vawm_01","\\Icons\\va\\vawm_ssqn_icon.dds")
		ssqn.registerQIcon("vawm_02","\\Icons\\va\\vawm_ssqn_icon.dds")
		ssqn.registerQIcon("vawm_03","\\Icons\\va\\vawm_ssqn_icon.dds")
		ssqn.registerQIcon("vawm_04","\\Icons\\va\\vawm_ssqn_icon.dds")
		ssqn.registerQIcon("vawm_05","\\Icons\\va\\vawm_ssqn_icon.dds")
		ssqn.registerQIcon("vawm_06","\\Icons\\va\\vawm_ssqn_icon.dds")
		ssqn.registerQIcon("vawm_07","\\Icons\\va\\vawm_ssqn_icon.dds")
		ssqn.registerQIcon("vawm_08","\\Icons\\va\\vawm_ssqn_icon.dds")
		ssqn.registerQIcon("vawm_09","\\Icons\\va\\vawm_ssqn_icon.dds")
    end
end

event.register(tes3.event.initialized, init)