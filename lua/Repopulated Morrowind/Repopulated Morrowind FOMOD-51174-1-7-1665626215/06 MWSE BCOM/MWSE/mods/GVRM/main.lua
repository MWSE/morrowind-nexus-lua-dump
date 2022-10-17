-- The function to call on the loadedCallback event.
local function loadedCallback(e) -- 1.
    --tes3.messageBox("Game loaded.") -- 2.
	local netchAd2Loaded = tes3.isModActive("Netch Adamantium Armor II_RP.esp")
	
	--NPC leveled lists
	local netchAdNPCs = tes3.getObject("GVRM_Dun_NtchAd_Wand_All")
	local netchAdNPCs2 = tes3.getObject("GVRM_MercSit_Dun_NtAd")
	
	--Alter leveled creatures
	for leveledCreatureList in tes3.iterateObjects(1129727308) do
		if (leveledCreatureList.id == "GVRM_MercWand_Dun" and not netchAd2Loaded) 
		then
			local netchAdRemoved = leveledCreatureList:remove(netchAdNPCs, 1)
			--tes3.messageBox("Remove Netch Ad successful? "..tostring(netchAdRemoved).." ")
		end
		if (leveledCreatureList.id == "GVRM_MercSit_Dun" and not netchAd2Loaded) 
		then
			local netchAdRemoved2 = leveledCreatureList:remove(netchAdNPCs2, 1)
			--tes3.messageBox("Remove Netch Ad successful? "..tostring(netchAdRemoved).." ")
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