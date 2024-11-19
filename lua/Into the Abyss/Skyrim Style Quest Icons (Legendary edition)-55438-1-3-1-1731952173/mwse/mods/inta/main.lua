local ssqn = include("SSQN.interop")

local function init() 
    if (ssqn) then
		ssqn.registerQIcon("INTA_03_GoblinQ","\\Icons\\INTA\\ic_q_goblin.dds")
		ssqn.registerQIcon("INTA_03_SpiderQ","\\Icons\\INTA\\ic_q_goblin.dds")
		ssqn.registerQIcon("INTA_03_GoblinQ","\\Icons\\INTA\\ic_q_goblin.dds")
		ssqn.registerQIcon("INTA_Artifact_For_Jooh","\\Icons\\INTA\\ic_q_bust.dds")
		ssqn.registerQIcon("INTA_Crabman","\\Icons\\INTA\\ic_q_crab.dds")
		ssqn.registerQIcon("INTA_Crystal_Hunt","\\Icons\\INTA\\ic_q_crystal.dds")
		ssqn.registerQIcon("INTA_Lost_Brother","\\Icons\\INTA\\ic_q_brother.dds")
		ssqn.registerQIcon("INTA_MQ","\\Icons\\INTA\\ic_q_mq.dds")
		ssqn.registerQIcon("INTA_MG1_Sunken_Amulet","\\Icons\\INTA\\ic_q_amulet.dds")
		ssqn.registerQIcon("INTA_MG2_Cursed_Bosmer","\\Icons\\INTA\\ic_q_curse.dds")
		ssqn.registerQIcon("INTA_MG3_The_Soul_Anchor","\\Icons\\INTA\\ic_q_anchor.dds")
    end
end

event.register(tes3.event.initialized, init)