local ssqn = include("SSQN.interop") --Must come before function calls

local function init() --Doesn't have to be an init function. The register icon function calls can go anywhere that will be consistently loaded.
    if (ssqn) then --Check to make sure SSQN is installed and skip the function calls if it's not installed
		ssqn.registerQIcon("My_Cavekill","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_Dalim","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("my_doppel","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("my_doppel2","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_Dreoram","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("my_dwijz","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_Hosh","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_Kill1","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_Kill2","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_Kubdul","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Piraten","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Qa","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_Serdam","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Sumak","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Tandores","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_TMA_1stBlade","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_TMA_2ndBlade","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_TMA_3th_Blade","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_TMA_Diamond","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_TMA_Elfen","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_TMA_Necro1","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_TMA_Necro2","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_TMA_Necro3","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_TMA_Party","\\Icons\\tm14_ssqn\\tmrtel.dds")
		ssqn.registerQIcon("My_TMA_Rians","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_TMEkaoss","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Va_Amulett","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Vampir_Quest","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Vampire","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Vampire2","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Vampire3","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Vampire4","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_VampireDagoth","\\Icons\\tm14_ssqn\\tmtm.dds")
		ssqn.registerQIcon("My_Witch","\\Icons\\tm14_ssqn\\tmtm.dds")
    end
end

event.register(tes3.event.initialized, init) --calls the init function when Morrowind is initialized. There are other events you could use. See MWSE docs for more