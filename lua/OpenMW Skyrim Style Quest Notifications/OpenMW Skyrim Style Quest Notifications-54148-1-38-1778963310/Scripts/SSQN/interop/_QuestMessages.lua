local ssqn = require("openmw.interfaces").SSQN

if not ssqn or not ssqn.registerQStageMessage then
	return
end

-- Unfinished, so disabled for now

--[[
ssqn.registerQStageMessage("ms_lookout", 10, "Find Fargoths' secret gold")
ssqn.registerQStageMessage("ms_lookout", 20, "Watch from the top of the lighthouse at night")

ssqn.registerQStageMessage("a1_1_findspymaster", 1, "Deliver a package to Caius Cosades in Balmora")
ssqn.registerQStageMessage("a1_1_findspymaster", 5, "Talk to Bacola Closcius")
ssqn.registerQStageMessage("a1_1_findspymaster", 10, "Find the home of Caius Cosades")
ssqn.registerQStageMessage("a1_1_findspymaster", 14, "Package delivered to Caius Cosades")

ssqn.registerQStageMessage("a1_2_antabolisinformant", 1, "Talk to Hasphat at the Fighters Guild")
ssqn.registerQStageMessage("a1_2_antabolisinformant", 5, "Recover the Dwemer Puzzle Box")
ssqn.registerQStageMessage("a1_2_antabolisinformant", 7, "Dwemer Puzzle Box found")
ssqn.registerQStageMessage("a1_2_antabolisinformant", 10, "Report to Caius Cosades")

ssqn.registerQStageMessage("a1_4_muzgobinformant", 1, "Talk to Sharn gra-Muzgob at the Mages Guild")
ssqn.registerQStageMessage("a1_4_muzgobinformant", 10, "Recover the skull of Llevule Andrano")
ssqn.registerQStageMessage("a1_4_muzgobinformant", 12, "Find Andrano Ancestral Tomb")
ssqn.registerQStageMessage("a1_4_muzgobinformant", 20, "Report to Caius Cosades")

ssqn.registerQStageMessage("a1_v_vivecinformants", 1, "Find the three informants in Vivec")

ssqn.registerQStageMessage("a1_10_mehramilo", 10, "Meet Mehra Milo at the back of the Vivec library")
ssqn.registerQStageMessage("a1_10_mehramilo", 50, "Find a copy of \"Progress of Truth\"")

ssqn.registerQStageMessage("a1_6_adhiranirrinformant", 5, "Search the Underworks for Addhiranirr")
ssqn.registerQStageMessage("a1_6_adhiranirrinformant", 45, "Report new information to Caius Cosades")

ssqn.registerQStageMessage("a1_7huleeyainformant", 1, "Escort Huleeya to Jobasha's Rare Books")
ssqn.registerQStageMessage("a1_7huleeyainformant", 50, "Deliver notes to Caius Cosades")

ssqn.registerQStageMessage("a1_11_zainsubaniinformant", 1, "Bring a gift for Hassour Zainsubani")

ssqn.registerQStageMessage("b8_meetvivec", 5, "Talk to the Archcanon")
ssqn.registerQStageMessage("b8_meetvivec", 30, "Meet Lord Vivec at his palace")
ssqn.registerQStageMessage("b8_meetvivec", 50, "Talk to Vivec about \"The Plan\"")
ssqn.registerQStageMessage("b8_meetvivec", 55, "Recover Sunder and Keening")

ssqn.registerQStageMessage("tr_dbattack", 10, "Inform a Guard about the attack")
ssqn.registerQStageMessage("tr_dbattack", 30, "Talk with Apelles Matius in Ebonheart")
ssqn.registerQStageMessage("tr_dbattack", 50, "Talk to Asciene Rane in the Grand Council Chambers")
ssqn.registerQStageMessage("tr_dbattack", 60, "Ask a Royal Guard about the Dark Brotherhood")
ssqn.registerQStageMessage("tr_dbattack", 100, "Find the Dark Brotherhood base")

ssqn.registerQStageMessage("bm_rumors",	10, "Ask about the island of Solstheim")
ssqn.registerQStageMessage("bm_rumors",	50, "Take a boat from Khuul to Fort Frostmoth")
ssqn.registerQStageMessage("bm_rumors", 60, "Talk to Basks-In-The-Sun")
ssqn.registerQStageMessage("bm_rumors", 100, "Talk with Captain Falx Carius")

ssqn.registerQStageMessage("bm_morale",	10, "Ask about the low morale at the Fort")
ssqn.registerQStageMessage("bm_morale",	20, "Investigate the unease amongst the troops")

ssqn.registerQStageMessage("mv_victimromance", 10, "Ask about the Mysterious Bandit")
ssqn.registerQStageMessage("mv_victimromance", 40, "Deliver Maurrie's glove to Nelos Onmar")
ssqn.registerQStageMessage("mv_victimromance", 60, "Give the note from Nelos to Maurrie")
ssqn.registerQStageMessage("mv_victimromance", 100, "Talk to Bernand Erelie in Tel Branora")
ssqn.registerQStageMessage("mv_victimromance", 105, "Talk to Emusette Bracques in Tel Aruhn")


--	Project Cyrodiil

ssqn.registerQStageMessage("pc_m1_k1_mc8", 10, "Rally support for Queen Millona")
ssqn.registerQStageMessage("pc_m1_k1_mc8", 20, "Report to Queen Millona")
ssqn.registerQStageMessage("pc_m1_k1_mc8", 30, "Stop the coup at Mischarstette")
ssqn.registerQStageMessage("pc_m1_k1_mc8", 31, "Stop the coup at Mischarstette")
ssqn.registerQStageMessage("pc_m1_k1_mc8", 40, "Report to Queen Millona")
ssqn.registerQStageMessage("pc_m1_k1_mc8", 45, "Report to Queen Millona")

ssqn.registerQStageMessage("pc_m1_k1_ht5", 10, "Overthrow Queen Millona")
ssqn.registerQStageMessage("pc_m1_k1_ht5", 50, "Talk to the Praetor of the Red Treasury")

ssqn.registerQStageMessage("pc_m1_ip_als4", 10, "Confront Uricalimo at Archad")

ssqn.registerQStageMessage("pc_m1_anv_bookclub", 10, "Talk to Breathes-Deep to join his book club")

--]]

