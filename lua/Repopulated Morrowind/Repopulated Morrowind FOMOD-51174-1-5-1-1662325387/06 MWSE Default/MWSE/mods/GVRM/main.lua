-- The function to call on the loadedCallback event.
local function loadedCallback(e) -- 1.
    --tes3.messageBox("Game loaded.") -- 2.
	local netchAd2Loaded = tes3.isModActive("Netch Adamantium Armor II_RP.esp")
	local GVAXLoaded = tes3.isModActive("GV_ArmorsExpansion.ESP")
	
	--NPC leveled lists
	local netchAdNPCs = tes3.getObject("GVRM_Dun_NtchAd_Wand_All")
	local AshlANPCs = tes3.getObject("GVRM_Dun_Ashl_ShA_Wand")
	local AshlENPCs = tes3.getObject("GVRM_Dun_Ashl_ShE_Wand")
	local AshlNNPCs = tes3.getObject("GVRM_Dun_Ashl_ShN_Wand")
	local AshlUNPCs = tes3.getObject("GVRM_Dun_Ashl_ShU_Wand")
	local AshlZNPCs = tes3.getObject("GVRM_Dun_Ashl_ShZ_Wand")
	
	
	--Alter leveled creatures
	for leveledCreatureList in tes3.iterateObjects(1129727308) do
		if (leveledCreatureList.id == "GVRM_MercWand_Dun" and not netchAd2Loaded) 
		then
			local netchAdRemoved = leveledCreatureList:remove(netchAdNPCs, 1)
			--tes3.messageBox("Remove Netch Ad successful? "..tostring(netchAdRemoved).." ")
		end
		--Remove relevant NPCs if GVAX is not installed
		if (leveledCreatureList.id == "GVRM_Ashl_A_Dun" and not GVAXLoaded) 
		then
			local AshlANPCsRemoved = leveledCreatureList:remove(AshlANPCs, 1)
			--tes3.messageBox("GVAX NPCs removed successful? "..tostring(AshlANPCsRemoved).." ")
		end
		if (leveledCreatureList.id == "GVRM_Ashl_E_Dun" and not GVAXLoaded) 
		then
			local AshlENPCsRemoved = leveledCreatureList:remove(AshlENPCs, 1)
			--tes3.messageBox("GVAX NPCs removed successful? "..tostring(AshlENPCsRemoved).." ")
		end
		if (leveledCreatureList.id == "GVRM_Ashl_N_Dun" and not GVAXLoaded) 
		then
			local AshlNNPCsRemoved = leveledCreatureList:remove(AshlNNPCs, 1)
			--tes3.messageBox("GVAX NPCs removed successful? "..tostring(AshlNNPCsRemoved).." ")
		end
		if (leveledCreatureList.id == "GVRM_Ashl_U_Dun" and not GVAXLoaded) 
		then
			local AshlUNPCsRemoved = leveledCreatureList:remove(AshlUNPCs, 1)
			--tes3.messageBox("GVAX NPCs removed successful? "..tostring(AshlUNPCsRemoved).." ")
		end
		if (leveledCreatureList.id == "GVRM_Ashl_Z_Dun" and not GVAXLoaded) 
		then
			local AshlZNPCsRemoved = leveledCreatureList:remove(AshlZNPCs, 1)
			--tes3.messageBox("GVAX NPCs removed successful? "..tostring(AshlZNPCsRemoved).." ")
		end
	end	
end


-- The function to call on the initialized event.
local function initialized()
    -- Register our function to the weaponReadied event.
    event.register(tes3.event.loaded, loadedCallback) --3.

    -- Print a "Ready!" statement to the MWSE.log file.
    print("[MWSE Guide Demo: INFO] MWSE Guide Demo Initialized")
end

-- Register our initialized function to the initialized event.
event.register(tes3.event.initialized, initialized)