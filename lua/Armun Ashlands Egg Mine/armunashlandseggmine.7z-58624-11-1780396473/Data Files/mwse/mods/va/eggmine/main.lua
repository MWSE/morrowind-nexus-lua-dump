
local ssqn = include("SSQN.interop")

local function init() 
    if (ssqn) then
        -- The Egg Mine
		ssqn.registerQIcon("vaem_01_job","\\Icons\\ssqn\\M_kwama_egg.dds")
		ssqn.registerQIcon("vaem_02_potions","\\Icons\\ssqn\\M_kwama_egg.dds")
		ssqn.registerQIcon("vaem_03_partner","\\Icons\\ssqn\\M_kwama_egg.dds")
		ssqn.registerQIcon("vaem_04_recruit","\\Icons\\ssqn\\M_kwama_egg.dds")
		ssqn.registerQIcon("vaem_05_exports","\\Icons\\ssqn\\M_kwama_egg.dds")
		ssqn.registerQIcon("vaem_06_guards","\\Icons\\ssqn\\M_kwama_egg.dds")
		ssqn.registerQIcon("vaem_07_transport","\\Icons\\ssqn\\M_kwama_egg.dds")
		ssqn.registerQIcon("vaem_08_tomb","\\Icons\\ssqn\\M_kwama_egg.dds")
		ssqn.registerQIcon("vaem_09_retirement","\\Icons\\ssqn\\M_kwama_egg.dds")
		ssqn.registerQIcon("vaem_x_mining","\\Icons\\ssqn\\M_kwama_egg.dds")
		
    end
end

event.register(tes3.event.initialized, init)

event.register(tes3.event.initialized, function()
	local ashfall = include("mer.ashfall.interop")
	if ashfall then
		
		local types = {
			egg = "egg",
		}

		ashfall.registerActivators{

		ashfall.registerFoods{
			vaem_kwamaegg_ing = types.egg,
		}
		}
		
	end
end)