local function persuasionChance(e)
	local fPersMod = tes3.findGMST(1150).value	-- the gmst related to personality modifier
	local fLuckMod = tes3.findGMST(1151).value
	local fRepMod = tes3.findGMST(1152).value
	local fFatigueBase = tes3.findGMST(1006).value
	local fFatigueMult = tes3.findGMST(1007).value
	local fLevelMod = tes3.findGMST(1153).value
	local fBribe10Mod = tes3.findGMST(1154).value
	local fBribe100Mod = tes3.findGMST(1155).value
	local fBribe1000Mod = tes3.findGMST(1156).value
	local iPerMinChance = tes3.findGMST(1159).value		-- by default iPerMinChance is 5, i.e., there is 5% min chance of success
			
	local persTerm = tes3.mobilePlayer.personality.current/fPersMod
	
	local luckTerm = tes3.mobilePlayer.luck.current/fLuckMod
	
	local repTerm =	tes3.player.object.factionIndex * fRepMod

	local levelTerm = tes3.player.object.level * fLevelMod
	-- fatigueTerm is 1.25 at full fatigue and 0.75 at 0 fatigue
	local fatigueTerm = fFatigueBase - fFatigueMult * (1 - tes3.mobilePlayer.fatigue.normalized)
	local playerRating1 = (repTerm + luckTerm + persTerm + tes3.mobilePlayer.speechcraft.current) * fatigueTerm
	local playerRating2 = playerRating1 + levelTerm
	local playerRating3 = (tes3.mobilePlayer.mercantile.current + luckTerm + persTerm) * fatigueTerm
	local npc = e.element:getPropertyObject("MenuPersuasion_Actor")
	local npcPersTerm = npc.reference.mobile.personality.current/fPersMod
	local npcLuckTerm = npc.reference.mobile.luck.current/fLuckMod
	local npcRepTerm = npc.object.factionIndex * fRepMod
	local npcLevelTerm = npc.object.level * fLevelMod
	local npcFatigueTerm = fFatigueBase - fFatigueMult * (1 - npc.reference.mobile.fatigue.normalized)
	local npcRating1 = (npcRepTerm + npcLuckTerm + npcPersTerm + npc.reference.mobile.speechcraft.current) * npcFatigueTerm
	local npcRating2 = npcRating1 + npcLevelTerm * npcFatigueTerm
	-- or local npcRating2 = (npcLevelTerm + npcRepTerm + npcLuckTerm + npcPersTerm + npc.reference.mobile.speechcraft.current) * npcFatigueTerm
	local npcRating3 = (npc.reference.mobile.mercantile.current + npcRepTerm + npcLuckTerm + npcPersTerm) * npcFatigueTerm
	local npcDisposition = npc.object.disposition
	local d = 1 - 0.02 * math.abs(npcDisposition - 50)
	local targets = {}
	targets[1] = d * (playerRating1 - npcRating1 + 50)		-- target1 is for both admire and taunt
	targets[3] = targets[1]
	targets[2] = d * (playerRating2 - npcRating2 + 50)
	local target3Min = d * (playerRating3 - npcRating3 + 50)
	targets[4], targets[5], targets[6] = target3Min + fBribe10Mod, target3Min + fBribe100Mod, target3Min + fBribe1000Mod
	for i=1,6 do
		targets[i] = math.max(iPerMinChance, targets[i])
	end
	local buttonList = e.element:findChild(tes3ui.registerID("MenuPersuasion_ServiceList"))
	for i, button in ipairs(buttonList.children) do
		if(i > 6) then
			break
		end
		button:register("help", function()
			local tooltip = tes3ui.createTooltipMenu()
			local t = tooltip:createBlock{}
			t.minWidth = 60
			t.autoHeight = true
			t.autoWidth = true
			local chanceText = t:createLabel{ text = "Chance  " .. tostring(math.round(targets[i], 1)) .. " %"}
		end)
	end	
end


local function initialized(e)
	event.register("uiActivated", persuasionChance, { filter = "MenuPersuasion" })
	print("Visible Persuasion Chances mod has initialized")
end

event.register("initialized", initialized)