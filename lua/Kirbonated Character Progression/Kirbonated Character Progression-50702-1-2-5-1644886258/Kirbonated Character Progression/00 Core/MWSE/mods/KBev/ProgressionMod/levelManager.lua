common = require("KBev.ProgressionMod.common")
mcm = require("KBev.ProgressionMod.mcm")
kcp = require("KBev.ProgressionMod.interop")
player = kcp.playerData

local page

local ID_kb_MenuLevelUp = {
	introPage = tes3ui.registerID("kb_MenuLevelUp_start"),
	statsPage = tes3ui.registerID("kb_MenuLevelUp_stats"),
	perksPage = tes3ui.registerID("kb_MenuLevelUp_perks"),
}

local levelUpMessage = {
	[2] = "You realize that all your life you have been coasting along as if you were in a dream. Suddenly, facing the trials of the last few days, you have come alive.",
	[3] = "You realize that you are catching on to the secret of success. It's just a matter of concentration.",
	[4] = "It's all suddenly obvious to you. You just have to concentrate. All the energy and time you've wasted -- it's a sin. But without the experience you've gained, taking risks, taking responsibility for failure, how could you have understood?",
	[5] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
	[6] = "You sense yourself more aware, more open to new ideas. You've learned a lot about Morrowind. It's hard to believe how ignorant you were -- but now you have so much more to learn.",
	[7] = "You resolve to continue pushing yourself. Perhaps there's more to you than you thought.",
	[8] = "The secret does seem to be hard work, yes, but it's also a kind of blind passion, an inspiration.",
	[9] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
	[10] = "You woke today with a new sense of purpose. You're no longer afraid of failure. Failure is just an opportunity to learn something new.",
	[11] = "Being smart doesn't hurt. And a little luck now and then is nice. But the key is patience and hard work. And when it pays off, it's SWEET!",
	[12] = "You can't believe how easy it is. You just have to go... a little crazy. And then, suddenly, it all makes sense, and everything you do turns to gold.",
	[13] = "It's the most amazing thing. Yesterday it was hard, and today it is easy. Just a good night's sleep, and yesterday's mysteries are today's masteries.",
	[14] = "Today you wake up, full of energy and ideas, and you know, somehow, that overnight everything has changed. What a difference a day makes.",
	[15] = "Today you suddenly realized the life you've been living, the punishment your body has taken -- there are limits to what the body can do, and perhaps you have reached them. You've wondered what it's like to grow old. Well, now you know.",
	[16] = "You've been trying too hard, thinking too much. Relax. Trust your instincts. Just be yourself. Do the little things, and the big things take care of themselves.",
	[17] = "Life isn't over. You can still get smarter, or cleverer, or more experienced, or meaner -- but your body and soul just aren't going to get any younger.",
	[18] = "The challenge now is to stay at the peak as long as you can. You may be as strong today as any mortal who has ever walked the earth, but there's always someone younger, a new challenger.",
	[19] = "You're really good. Maybe the best. And that's why it's so hard to get better. But you just keep trying, because that's the way you are.",
	[20] = "You'll never be better than you are today. If you are lucky, by superhuman effort, you can avoid slipping backwards for a while. But sooner or later, you're going to lose a step, or drop a beat, or miss a detail -- and you'll be gone forever.",
	[21] = "The results of hard work and dedication always look like luck to saps. But you know you've earned every ounce of your success.",

}

local nextLevel = 1


local function getPlayerClassImage()
	playerClass = tes3.player.baseObject.class
	if tes3.getFileExists("textures\\levelup\\" .. string.lower(playerClass.name .. ".dds")) then
		return ("textures\\levelup\\" .. string.lower(playerClass.name .. ".dds"))
	elseif playerClass.specialization == tes3.specialization.magic then
		return "textures\\levelup\\mage.dds"
	elseif playerClass.specialization == tes3.specialization.stealth then
		return "textures\\levelup\\thief.dds"
	else return "textures\\levelup\\warrior.dds" 
	end
end

local function finalizeChanges(atr, skl, prk)
	for i, t in ipairs(atr) do
		if t.pointsSpent > 0 then
			tes3.modStatistic{reference = tes3.player, attribute = i-1, value = t.pointsSpent}
		end
	end
	for i, t in ipairs(skl) do
		if t.pointsSpent > 0 then
			tes3.modStatistic({reference = tes3.player, skill = i-1, value = t.pointsSpent})
		end
	end
	for i, t in pairs(prk) do
		if t.chosen then 
			player.grantPerk(i) 
			tes3.player.data.KBProgression.levelPoints.prk = tes3.player.data.KBProgression.levelPoints.prk - 1
		end
	end
	--HP code
	tes3.setStatistic({reference = tes3.mobilePlayer, name = "health", value = (tes3.mobilePlayer.strength.base + (tes3.mobilePlayer.endurance.base * nextLevel)) / 2})
	mwscript.setLevel({reference = tes3.player, level = nextLevel})
	if tes3.player.data.KBProgression.xp < player.calcXPReq(nextLevel) then
		tes3.mobilePlayer.levelUpProgress = 0
	end
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    local elem = menu:findChild(tes3ui.registerID("MenuStat_level"))
    elem.text = tostring(nextLevel)
    menu:updateLayout()
end

local function checkPerkConditions(perkID, atrTable, skillTable, prkTable)
	local checkPerk = common.perkList[perkID]
	
	
	if not checkPerk then
		common.err("Attempted to read conditions of unregistered perkID \"" .. perkID .. "\"")
		return false
	end
	
	if (checkPerk.perkExclude)  then 
		for i, p in ipairs(checkPerk.perkExclude) do
			if common.perkList[p] and  (player.hasPerk(p) or(prkTable[p] and prkTable[p].chosen)) then
				return false
			end
		end 
	end
	
	if checkPerk.lvlReq > nextLevel then 
		return false
	end
	
	if (checkPerk.attributeReq) then
		for a, c in pairs(checkPerk.attributeReq) do
			if ((tes3.mobilePlayer[a].base + atrTable[tes3.attribute[a]+1].pointsSpent) < c) then 
				return false
			end
		end
	end 
	
	
	if (checkPerk.skillReq) then
		for a, c in pairs(checkPerk.skillReq) do
			if ((tes3.mobilePlayer[a].base + skillTable[tes3.skill[a]+1].pointsSpent) < c) then
				return false
			end
		end 
	end 
	
	if (checkPerk.werewolfReq and (tes3.getGlobal("PCWerewolf") ~= 1)) then 
		return false
	end
	
	if(checkPerk.vampireReq and (tes3.getGlobal("PCVampire") ~= 1)) then 
		return false
	end
	
	if checkPerk.perkReq then
		for i, p in ipairs(checkPerk.perkReq) do
			if not common.perkList[p] then
				return false
			end
			if not player.hasPerk(p) then 
				return false 
			end
		end
	end
	
	if checkPerk.customReq and not checkPerk.customReq() then return false end
	
	return true
end

local function asButtonScript(params)
	if params.type == "add" then
		if (params.tbl.base + params.tbl.pointsSpent < 100) and (tes3.player.data.KBProgression.levelPoints[params.points] > 0) and (params.tbl.pointsSpent < params.incMax) then
			params.tbl.pointsSpent = params.tbl.pointsSpent + 1
			tes3.player.data.KBProgression.levelPoints[params.points] = tes3.player.data.KBProgression.levelPoints[params.points] - 1 
		elseif (tes3.player.data.KBProgression.levelPoints[params.points] > 1) and (params.tbl.pointsSpent < params.incMax) then
			params.tbl.pointsSpent = params.tbl.pointsSpent + 1
			tes3.player.data.KBProgression.levelPoints[params.points] = tes3.player.data.KBProgression.levelPoints[params.points] - 2
		end
	end
	if params.type == "sub" then
		if (params.tbl.base + params.tbl.pointsSpent < 100) and (params.tbl.pointsSpent > 0) then
			tes3.player.data.KBProgression.levelPoints[params.points] = tes3.player.data.KBProgression.levelPoints[params.points] + 1
			params.tbl.pointsSpent = params.tbl.pointsSpent - 1
		elseif (params.tbl.pointsSpent > 0) then
			tes3.player.data.KBProgression.levelPoints[params.points] = tes3.player.data.KBProgression.levelPoints[params.points] + 2
			params.tbl.pointsSpent = params.tbl.pointsSpent - 1
		end
	end
	params.tbl.value.text = params.tbl.base + params.tbl.pointsSpent
	params.tbl.button_plus.visible = true
	params.tbl.button_minus.visible = true
end

--[[LEVEL UP UI]]
--[[
TODO:
-Implement Next/Prev buttons to navigate between pages
-Page 1 shows Class Image, "Advanced to Level %d", and normal level up message
-Page 2 shows Attribute Points and Skill points you have to spend
-Page 3 shows Perks
-Page 4 shows Review of choice made, also previews changes to health, magicka, and fatigue
-RE-REGISTER UI ACTIVATED EVENT


DEFAULT UI PROPERTIES
[KBEV UI TEST] Printing Level Up menu properties
[KBEV UI TEST] autoHeight is enabled
[KBEV UI TEST] autoWidth is enabled
[KBEV UI TEST] current height = 49
[KBEV UI TEST] current width = 270
[KBEV UI TEST] maxHeight = 1080
[KBEV UI TEST] maxWidth = 1920
[KBEV UI TEST] minHeight = 30
[KBEV UI TEST] minWidth = 30
[KBEV UI TEST] borderAllSides = 0
[KBEV UI TEST] paddingAllSides = 0
[KBEV UI TEST] childAlignX = 0
[KBEV UI TEST] childAlignY = 0
]]

local function kb_menuLevelUp(e)
	if  (not e.newlyCreated) or (not e.element) then return end
	frame = e.element
	frame:destroyChildren() --destroy vanilla ui components. we only want the parent element
	frame.flowDirection = "top_to_bottom"
	frame.childAlignX = -1
	
	page = 0 --initialize to page 0
	introPage = frame:createThinBorder(ID_kb_MenuLevelUp.introPage)
	introPage.flowDirection = "top_to_bottom"
	introPage.autoHeight = true
	introPage.autoWidth = true
	introPage.minWidth = 512
	introPage.childAlignX = 0.5
	introPage.childAlignY = 0
	introPage.visible = (page == 0)
	classBanner_layout = introPage:createThinBorder()
	classBanner_layout.paddingAllSides = 5
	classBanner_layout.autoWidth = true
	classBanner_layout.autoHeight = true
	classBanner_layout.visible = true
	classBanner = classBanner_layout:createImage({path = getPlayerClassImage()})
	classBanner.imageScaleX = 1.5
	classBanner.imageScaleY = 1.5
	classBanner.visible = true
	classBanner_layout.borderBottom = 10
	b_Flavor = introPage:createThinBorder()
	b_Flavor.widthProportional = 1
	b_Flavor.borderAllSides = 10
	b_Flavor.paddingAllSides = 5
	b_Flavor.autoHeight = true
	FlavorText = b_Flavor:createLabel({text = (levelUpMessage[nextLevel] or levelUpMessage[21 - (math.random() % 6)])})
	FlavorText.justifyText = "center"
	FlavorText.wrapText = true

	--stats page starts here
	atr = {}
	skl = {}
	statsPage = frame:createBlock(ID_kb_MenuLevelUp.statsPage)
	statsPage.visible = (page == 1)
	statsPage.flowDirection = "left_to_right"
	statsPage.autoHeight = true
	statsPage.autoWidth = true
	statsPage.minHeight = 512
	statsPage.minWidth = 1024
	
	statsPage.childAlignX = 0
	statsPage.childAlignY = 0
	statsPage_left = statsPage:createBlock()
	statsPage_left.visible = true
	statsPage_left.autoHeight = true
	statsPage_left.widthProportional = 1.0
	statsPage_left.heightProportional = 1.0
	statsPage_left.flowDirection = "top_to_bottom"
	
	statsPage_right = statsPage:createBlock()
	statsPage_right.visible = true
	statsPage_right.autoHeight = true
	statsPage_right.widthProportional = 1.0
	statsPage_right.heightProportional = 1.0
	
		hmf_border = statsPage_left:createThinBorder()
		hmf_border.visible = true
		hmf_border.autoHeight = true
		hmf_border.widthProportional = 1.0
			hmf_layout = hmf_border:createBlock()
			hmf_layout.visible = true
			hmf_layout.autoHeight = true
			hmf_layout.widthProportional = 1.0
			hmf_layout.flowDirection = "top_to_bottom"
			hmf_layout.paddingAllSides = 5
	
				hmf_health = hmf_layout:createBlock()
				hmf_health.borderBottom = 5
				hmf_health.visible = true
				hmf_health.flowDirection = "left_to_right"
				hmf_health.widthProportional = 1.0
				hmf_health.autoHeight = true
				hmf_health.childAlignX = -1
					hmf_healthText = hmf_health:createLabel({text = "Health"})
					hmf_healthText.visible = true
					hmf_healthBar = hmf_health:createFillBar({current = (tes3.mobilePlayer.strength.base + (tes3.mobilePlayer.endurance.base * nextLevel)) / 2, max = (tes3.mobilePlayer.strength.base + (tes3.mobilePlayer.endurance.base * nextLevel)) / 2})
					hmf_healthBar.widget.fillColor = tes3ui.getPalette("health_color")
					hmf_healthBar.visible = true
	
				hmf_magicka = hmf_layout:createBlock()
				hmf_magicka.visible = true
				hmf_magicka.flowDirection = "left_to_right"
				hmf_magicka.widthProportional = 1.0
				hmf_magicka.autoHeight = true
				hmf_magicka.childAlignX = -1
					hmf_magickaText = hmf_magicka:createLabel({text = "Magicka"})
					hmf_magickaText.visible = true
					hmf_magickaBar = hmf_magicka:createFillBar({current = tes3.mobilePlayer.intelligence.base * (1 + (tes3.mobilePlayer.magickaMultiplier.current / 10)), max = tes3.mobilePlayer.intelligence.base * (1 + (tes3.mobilePlayer.magickaMultiplier.current / 10))})
					hmf_magickaBar.widget.fillColor = tes3ui.getPalette("magic_color")
					hmf_magickaBar.visible = true
				
				hmf_fatigue = hmf_layout:createBlock()
				hmf_fatigue.borderTop = 5
				hmf_fatigue.visible = true
				hmf_fatigue.flowDirection = "left_to_right"
				hmf_fatigue.widthProportional = 1.0
				hmf_fatigue.autoHeight = true
				hmf_fatigue.childAlignX = -1
					hmf_fatigueText = hmf_fatigue:createLabel({text = "Fatigue"})
					hmf_fatigueText.visible = true
					hmf_fatigueBar = hmf_fatigue:createFillBar({current = tes3.mobilePlayer.strength.base + tes3.mobilePlayer.willpower.base + tes3.mobilePlayer.agility.base + tes3.mobilePlayer.endurance.base, max = tes3.mobilePlayer.strength.base + tes3.mobilePlayer.willpower.base + tes3.mobilePlayer.agility.base + tes3.mobilePlayer.endurance.base})
					hmf_fatigueBar.widget.fillColor = tes3ui.getPalette("fatigue_color")
					hmf_fatigueBar.visible = true

	
	b_atr = statsPage_left:createThinBorder()
	b_atr.visible = true
	b_atr.flowDirection = "top_to_bottom"
	atrLabel = b_atr:createLabel({text = "Attributes"})
	atrLabel.color = tes3ui.getPalette("header_color")
	atrRemPoints = b_atr:createLabel({text = "Remaining Attribute Points: " .. tes3.player.data.KBProgression.levelPoints.atr})
	atrRemPoints.color = tes3ui.getPalette("header_color")
	atr_layout = b_atr:createBlock()
	atr_layout.flowDirection = "top_to_bottom"
	atr_layout.autoHeight = true
	atr_layout.width = 512
	atr_layout.visible = true
	
	local function updateHMFBars()
		local netStrength = atr[tes3.attribute.strength + 1].base + atr[tes3.attribute.strength + 1].pointsSpent
		local netEndurance = atr[tes3.attribute.endurance + 1].base + atr[tes3.attribute.endurance + 1].pointsSpent
		local netIntelligence = atr[tes3.attribute.intelligence + 1].base + atr[tes3.attribute.intelligence + 1].pointsSpent
		local netWillpower = atr[tes3.attribute.willpower + 1].base + atr[tes3.attribute.willpower + 1].pointsSpent
		local netAgility = atr[tes3.attribute.agility + 1].base + atr[tes3.attribute.agility + 1].pointsSpent
		
		hmf_healthBar.widget.max = (netStrength + (netEndurance * nextLevel)) / 2
		hmf_healthBar.widget.current = (netStrength + (netEndurance * nextLevel)) / 2
		
		hmf_magickaBar.widget.max = netIntelligence * (1 + (tes3.mobilePlayer.magickaMultiplier.current / 10))
		hmf_magickaBar.widget.current = netIntelligence * (1 + (tes3.mobilePlayer.magickaMultiplier.current / 10))
		
		hmf_fatigueBar.widget.max = netStrength + netWillpower + netAgility + netEndurance
		hmf_fatigueBar.widget.current = netStrength + netWillpower + netAgility + netEndurance
		
		hmf_layout:updateLayout()
	end
	
	local function updateASButtons(tbl, typ)
		for i, data in pairs(tbl) do
			if (tes3.player.data.KBProgression.levelPoints[typ] > 0) and (data.pointsSpent < mcm[typ .. "IncMax"]) and ((data.base + data.pointsSpent < 100) or tes3.player.data.KBProgression.levelPoints[typ] > 1) then
				data.button_plus.widget.state = 1
			else data.button_plus.widget.state = 2 end
			if (data.pointsSpent > 0) then data.button_minus.widget.state = 1
			else data.button_minus.widget.state = 2 end
		end
	end
	
	local function createStat(tbl, nam, val, bl, typ)
		tbl.base = val
		tbl.pointsSpent = 0
		tbl.block = bl:createBlock()
		tbl.block.flowDirection = "left_to_right"
		tbl.block.childAlignX = -1
		tbl.block.autoWidth = true
		tbl.block.autoHeight = true
		tbl.block.visible = true
		tbl.label = tbl.block:createLabel({text = nam})
		tbl.label.visible = true
		tbl.button_minus = tbl.block:createButton()
		tbl.button_minus.text = "-"
		tbl.button_minus.widget.pressed = tes3ui.getPalette("normal_pressed_color")
		tbl.button_minus.widget.idleDisabled = tes3ui.getPalette("disabled_color")
		tbl.button_minus.widget.pressedDisabled = tes3ui.getPalette("disabled_pressed_color")
		tbl.button_minus.visible = true
		tbl.button_plus = tbl.block:createButton()
		tbl.button_plus.text = "+"
		tbl.button_plus.widget.pressed = tes3ui.getPalette("normal_pressed_color")
		tbl.button_plus.widget.idleDisabled = tes3ui.getPalette("disabled_color")
		tbl.button_plus.widget.pressedDisabled = tes3ui.getPalette("disabled_pressed_color")
		tbl.button_plus.visible = true
		tbl.value = tbl.block:createLabel({text = tostring(tbl.base + tbl.pointsSpent)})
		tbl.value.visible = true
	end
	
	for i, a in pairs(tes3.mobilePlayer.attributes) do
		atr[i] = {}
		local maxInc = function()
			if (mcm.atrLvlCap - a.base < mcm.atrIncMax) then return mcm.atrLvlCap - a.base end
			return mcm.atrIncMax
		end
		createStat(atr[i], tes3.getAttributeName(i - 1), a.base, atr_layout, "atr")
		atr[i].button_minus:register("mouseClick", 
			function ()
				asButtonScript({type = "sub", tbl = atr[i], points = "atr", incMax = maxInc()})
				atrRemPoints.text = "Remaining Attribute Points: " .. tes3.player.data.KBProgression.levelPoints.atr
				updateHMFBars()
				updateASButtons(atr, "atr")
				b_atr:updateLayout()
			end
		)
		atr[i].button_plus:register("mouseClick", 
			function ()
				asButtonScript({type = "add", tbl = atr[i], points = "atr", incMax = maxInc()})
				atrRemPoints.text = "Remaining Attribute Points: " .. tes3.player.data.KBProgression.levelPoints.atr 
				updateHMFBars()
				updateASButtons(atr, "atr")
				b_atr:updateLayout()
			end
		)
	end
	updateASButtons(atr, "atr")
	b_atr:updateLayout()
	
	b_skl = statsPage_right:createThinBorder()
	b_skl.flowDirection = "top_to_bottom"
	b_skl.widthProportional = 1
	b_skl.heightProportional = 1
	v_skl = b_skl:createVerticalScrollPane()
	v_skl.minHeight = 512
	sklLabel = v_skl:createLabel({text = "Skills"})
	
	
	skl_layout = v_skl:createBlock()
	skl_layout.flowDirection = "top_to_bottom"
	skl_layout.autoHeight = true
	skl_layout.widthProportional = 1
	
	mjr = skl_layout:createBlock()
	mjr.flowDirection = "top_to_bottom"
	mjr.autoHeight = true
	mjr.widthProportional = 1
	mjr.visible = true
	mjr_pointsRem = mjr:createLabel({text = "Remaining Major Skill Points: " .. tes3.player.data.KBProgression.levelPoints.mjr})
	
	mnr = skl_layout:createBlock()
	mnr.flowDirection = "top_to_bottom"
	mnr.autoHeight = true
	mnr.widthProportional = 1
	mnr.visible = true
	mnr_pointsRem = mnr:createLabel({text = "Remaining Minor Skill Points: " .. tes3.player.data.KBProgression.levelPoints.mnr})
	
	msc = skl_layout:createBlock()
	msc.flowDirection = "top_to_bottom"
	msc.autoHeight = true
	msc.widthProportional = 1
	msc.visible = true
	msc_pointsRem = msc:createLabel({text = "Remaining Misc Skill Points: " .. tes3.player.data.KBProgression.levelPoints.msc})
	
	for i, sk in ipairs(tes3.mobilePlayer.skills) do
		skl[i] = {}
		local skType
		if sk.type == tes3.skillType.major then
			skType = "mjr"
		elseif sk.type == tes3.skillType.minor then
			skType = "mnr"
		else skType = "msc"
		end
		local maxInc = function()
			if (mcm[skType .. "LvlCap"] - sk.base < mcm[skType .. "IncMax"]) then return mcm[skType .. "LvlCap"] - sk.base end
			return mcm[skType .. "IncMax"]
		end
		if (sk.type == tes3.skillType.major) then
			createStat(skl[i], tes3.getSkillName(i-1), sk.base, mjr, "mjr")
			skl[i].button_minus:register("mouseClick", 
				function ()
					asButtonScript({type = "sub", tbl = skl[i], points = "mjr", incMax = maxInc()})
					mjr_pointsRem.text = "Remaining Major Skill Points: " .. tes3.player.data.KBProgression.levelPoints.mjr
					updateASButtons(skl, "mjr")
					b_skl:updateLayout()
				end
			)
			skl[i].button_plus:register("mouseClick", 
				function ()
					asButtonScript({type = "add", tbl = skl[i], points = "mjr", incMax = maxInc()})
					mjr_pointsRem.text = "Remaining Major Skill Points: " .. tes3.player.data.KBProgression.levelPoints.mjr
					updateASButtons(skl, "mjr")
					b_skl:updateLayout()
				end
			)
		elseif (sk.type == tes3.skillType.minor) then
			createStat(skl[i], tes3.getSkillName(i-1), sk.base, mnr, "mnr")
			skl[i].button_minus:register("mouseClick", 
				function ()
					asButtonScript({type = "sub", tbl = skl[i], points = "mnr", incMax = maxInc()})
					mnr_pointsRem.text = "Remaining Minor Skill Points: " .. tes3.player.data.KBProgression.levelPoints.mnr
					updateASButtons(skl, "mnr")
					b_skl:updateLayout()
				end
			)
			skl[i].button_plus:register("mouseClick", 
				function ()
					asButtonScript({type = "add", tbl = skl[i], points = "mnr", incMax = maxInc()})
					mnr_pointsRem.text = "Remaining Minor Skill Points: " .. tes3.player.data.KBProgression.levelPoints.mnr
					updateASButtons(skl, "mnr")
					b_skl:updateLayout()
				end
			)
		elseif (sk.type == tes3.skillType.misc) then
			createStat(skl[i], tes3.getSkillName(i-1), sk.base, msc, "msc")
			skl[i].button_minus:register("mouseClick", 
				function ()
					asButtonScript({type = "sub", tbl = skl[i], points = "msc", incMax = maxInc()})
					msc_pointsRem.text = "Remaining Misc Skill Points: " .. tes3.player.data.KBProgression.levelPoints.msc
					updateASButtons(skl, "msc")
					b_skl:updateLayout()
				end
			)
			skl[i].button_plus:register("mouseClick", 
				function ()
					asButtonScript({type = "add", tbl = skl[i], points = "msc", incMax = maxInc()})
					msc_pointsRem.text = "Remaining Misc Skill Points: " .. tes3.player.data.KBProgression.levelPoints.msc
					updateASButtons(skl, "msc")
					b_skl:updateLayout()
				end
			)
		end
	end
	mjr:createDivider()
	mnr:createDivider()
	b_atr:updateLayout()
	

	--perks page starts here
	perksSelected = 0
	perksPage = frame:createThinBorder(ID_kb_MenuLevelUp.perksPage)
	perksPage.visible = page == 2
	perksPage.flowDirection = "left_to_right"
	perksPage.autoHeight = true
	perksPage.autoWidth = true
	perksPage.minHeight = 512
	perksPage.minWidth = 1024
	perksPage.childAlignX = -1
	perksPage.childAlignY = 0
	
	perksPage_borderL = perksPage:createThinBorder()
	perksPage_borderL.flowDirection = "top_to_bottom"
	perksPage_borderL.widthProportional = 1
	perksPage_borderR = perksPage:createThinBorder()
	perksPage_borderR.flowDirection = "top_to_bottom"
	perksPage_borderR.widthProportional = 1
	
	perksPage_perksRem = perksPage_borderL:createLabel({text = "Perk Points:  " .. tes3.player.data.KBProgression.levelPoints.prk - perksSelected})
	
	perksPage_borderL_vScroll = perksPage_borderL:createVerticalScrollPane()
	perksPage_borderR_vScroll = perksPage_borderR:createVerticalScrollPane()
	
	perksPage_borderL_vScroll.minHeight = 512
	perksPage_borderR_vScroll.minHeight = 512
	
	perksPage_borderL_layout = perksPage_borderL_vScroll:createBlock()
	perksPage_borderL_layout.flowDirection = "top_to_bottom"
	perksPage_borderL_layout.visible = true
	perksPage_borderL_layout.autoHeight = true
	perksPage_borderL_layout.autoWidth = true
	perksPage_borderR_layout = perksPage_borderR_vScroll:createBlock()
	perksPage_borderR_layout.flowDirection = "top_to_bottom"
	perksPage_borderR_layout.autoHeight = true
	perksPage_borderR_layout.widthProportional = 1.0
	perksPage_availablePerks = perksPage_borderL_layout:createBlock()
	perksPage_availablePerks.flowDirection = "top_to_bottom"
	perksPage_availablePerks.autoHeight = true
	perksPage_availablePerks.autoWidth = true
	perksPage_availablePerks.visible = true
	perksPage_blockedPerks = perksPage_borderL_layout:createBlock()
	perksPage_blockedPerks.flowDirection = "top_to_bottom"
	perksPage_blockedPerks.autoHeight = true
	perksPage_blockedPerks.autoWidth = true
	perksPage_blockedPerks.visible = true
	
	perksPage_perkInfo_Name = perksPage_borderR_layout:createLabel()
	perksPage_borderR_vScroll:createDivider()
	perksPage_perkInfo_Cond = perksPage_borderR_layout:createLabel()
	perksPage_perkInfo_Desc = perksPage_borderR_layout:createLabel()
	perksPage_perkInfo_Name.widthProportional = 1.0
	perksPage_perkInfo_Name.wrapText = true
	perksPage_perkInfo_Cond.widthProportional = true
	perksPage_perkInfo_Cond.wrapText = true
	perksPage_perkInfo_Desc.widthProportional = true
	perksPage_perkInfo_Desc.wrapText = true
	
	local prk = {}
	
	local function updatePerkState()
		for id, data in pairs(prk) do
			if data.chosen then 
				data.element.widget.state = 4
				data.blockedElement.widget.state = 4
			elseif not(checkPerkConditions(id, atr, skl, prk)) then 
				data.element.widget.state = 2 
				data.blockedElement.widget.state = 2
			else 
				data.element.widget.state = 1 
				data.blockedElement.widget.state = 1
			end
			data.element.visible = checkPerkConditions(id, atr, skl, prk)
			
			if common.perkList[id].hideInMenu then data.blockedElement.visible = false 
			else data.blockedElement.visible = (not checkPerkConditions(id, atr, skl, prk))
			end
		end
		perksPage_perksRem.text = "Perk Points:  " .. tes3.player.data.KBProgression.levelPoints.prk - perksSelected
	end
	
	for id, perkData in pairs(common.perkList) do
		if (player.hasPerk(id)) then prk[id] = nil
		else
		prk[id] = {
			chosen = false, 
			element = perksPage_availablePerks:createTextSelect({text = perkData.name,	state = 1}), 
			blockedElement = perksPage_blockedPerks:createTextSelect({text = perkData.name,	state = 1}),
		}
		prk[id].element.widget.over = tes3ui.getPalette("normal_over_color")
		prk[id].element.widget.pressed = tes3ui.getPalette("normal_pressed_color")
		prk[id].element.widget.idleDisabled = tes3ui.getPalette("disabled_color")
		prk[id].element.widget.overDisabled = tes3ui.getPalette("disabled_over_color")
		prk[id].element.widget.pressedDisabled = tes3ui.getPalette("disabled_over_color")
		prk[id].element.widget.idleActive = tes3ui.getPalette("active_color")
		prk[id].element.widget.overActive = tes3ui.getPalette("active_over_color")
		prk[id].element.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
		prk[id].blockedElement.widget.over = tes3ui.getPalette("normal_over_color")
		prk[id].blockedElement.widget.pressed = tes3ui.getPalette("normal_pressed_color")
		prk[id].blockedElement.widget.idleDisabled = tes3ui.getPalette("disabled_color")
		prk[id].blockedElement.widget.overDisabled = tes3ui.getPalette("disabled_over_color")
		prk[id].blockedElement.widget.pressedDisabled = tes3ui.getPalette("disabled_over_color")
		prk[id].blockedElement.widget.idleActive = tes3ui.getPalette("active_color")
		prk[id].blockedElement.widget.overActive = tes3ui.getPalette("active_over_color")
		prk[id].blockedElement.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
		
		prk[id].element:register("mouseOver", function()
			local condition = "Requirements:\n"
			if perkData.lvlReq then condition = (condition .. "Level " .. perkData.lvlReq .. ",\n") end
			if perkData.attributeReq then
				for a, v in pairs(perkData.attributeReq) do
					condition = (condition .. tes3.getAttributeName(tes3.attribute[a]) .. " " .. v .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.skillReq then
				for a, v in pairs(perkData.skillReq) do
					condition = (condition .. tes3.getSkillName(tes3.skill[a]) .. " " .. v .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.perkReq then
				for i, v in ipairs(perkData.perkReq) do
					condition = (condition .. common.perkList[v].name .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.werewolfReq or perkData.vampireReq then
				if not perkData.vampireReq then condition = (condition .. "Lycanthropy, \n")
				elseif not perkData.werewolfReq then condition = (condition .. "Vampirism, \n")
				else condition = (condition .. "Vampire/Lycanthropy hybrid, \n")
				end
				condition = (condition .. "\n")
			end
			if perkData.customReqText then condition = (condition .. perkData.customReqText .. "\n") end
			perksPage_perkInfo_Name.text = perkData.name
			perksPage_perkInfo_Cond.text = condition
			perksPage_perkInfo_Desc.text = perkData.description
			perksPage_borderR_vScroll:updateLayout()
		end)
		prk[id].blockedElement:register("mouseOver", function()
			local condition = "Requirements:\n"
			if perkData.lvlReq then condition = (condition .. "Level " .. perkData.lvlReq .. ",\n") end
			if  perkData.attributeReq then
				for a, v in pairs(perkData.attributeReq) do
					condition = (condition .. tes3.getAttributeName(tes3.attribute[a]) .. " " .. v .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.skillReq then
				for a, v in pairs(perkData.skillReq) do
					condition = (condition .. tes3.getSkillName(tes3.skill[a]) .. " " .. v .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.perkReq then
				for i, v in ipairs(perkData.perkReq) do
					condition = (condition .. common.perkList[v].name .. ", ")
				end
				condition = (condition .. "\n")
			end
			if perkData.werewolfReq or perkData.vampireReq then
				if not perkData.vampireReq then condition = (condition .. "Lycanthropy,")
				elseif not perkData.werewolfReq then condition = (condition .. "Vampirism,")
				else condition = (condition .. "Vampire/Lycanthropy hybrid,")
				end
				condition = (condition .. "\n")
			end
			if perkData.customReqText then condition = (condition .. perkData.customReqText .. "\n") end
			perksPage_perkInfo_Name.text = perkData.name
			perksPage_perkInfo_Cond.text = condition
			perksPage_perkInfo_Desc.text = perkData.description
			perksPage_borderR_vScroll:updateLayout()
		end)
		prk[id].element:register("mouseClick", function()
			if prk[id].element.widget.state == 2 then return end
			if prk[id].chosen then 
				prk[id].chosen = false
				perksSelected = perksSelected - 1
			elseif (perksSelected < math.floor(tes3.player.data.KBProgression.levelPoints.prk / 1)) then --floors perkpoints because perk point can be a fraction
				prk[id].chosen = true
				perksSelected = perksSelected + 1
			end
			updatePerkState()
		end)
		end
		updatePerkState()
	end

	--container for the next and back buttons
	frameButtons = frame:createThinBorder()
	frameButtons.autoHeight = true
	frameButtons.widthProportional = 1.0
	frameButtons.visible = true
	frameButtons.childAlignX = 1
	buttonBack = frameButtons:createButton()
	buttonBack.text = "Back"
	buttonBack.widget.pressed = tes3ui.getPalette("normal_pressed_color")
	buttonBack.visible = (page ~= 0)
	
	buttonNext = frameButtons:createButton()
	buttonNext.text = "Next"
	buttonNext.widget.pressed = tes3ui.getPalette("normal_pressed_color")
	buttonNext.widget.idleActive = tes3ui.getPalette("active_color")
	buttonNext.widget.pressedActive = tes3ui.getPalette("active_pressed_color")
	
	local getLevelUpComplete =  function()
		for i, rem in pairs(tes3.player.data.KBProgression.levelPoints) do
			if rem > 0 then return false end
		end
		return true 
	end
	local function updatePageVis()
		introPage.visible = (page == 0)
		statsPage.visible = (page == 1)
		perksPage.visible = (page == 2)
		buttonBack.visible = (page ~= 0)
		if (page == 2) or ((page == 1) and (tes3.player.data.KBProgression.levelPoints.prk == 0)) then buttonNext.text = "Finish"
		else buttonNext.text = "Next" end
	end
	
	--"back" button code
	buttonBack:register("mouseClick", 
		function()
			if page > 2 then
				page = 2
				frame:updateLayout()
			elseif (page > 0) then
				page = page - 1
				frame:updateLayout()
			else
				page = 0
				frame:updateLayout()
			end
			updatePageVis()
		end
	)
	--"next" button code
	buttonNext.visible = true
	buttonNext:register("mouseClick", 
	function()
		if page < 0 then 
			page = 0 
		elseif ((page == 1) and (tes3.player.data.KBProgression.levelPoints.prk == 0)) then
			finalizeChanges(atr, skl, prk)
			event.trigger("levelUp", {level = nextLevel})
			frame.visible = false
			tes3ui.leaveMenuMode((frame:getTopLevelMenu()).id)
			frame:getTopLevelMenu():destroy()
		elseif (page < 2) then
			page = page + 1
		elseif page == 2 then --insert skill change finalization here
			finalizeChanges(atr, skl, prk)
			event.trigger("levelUp", {level = nextLevel})
			frame.visible = false
			tes3ui.leaveMenuMode((frame:getTopLevelMenu()).id)
			frame:getTopLevelMenu():destroy()

		else 
			page = 2
		end
		if frame.visible then
			updatePageVis()
			frame:updateLayout()
		end
	end
	)
	
	updatePageVis()
	frame:updateLayout()
	
end
event.register("uiActivated", kb_menuLevelUp, {filter = "MenuLevelUp"})

local function setUpLevel(e) 
	nextLevel = e.level
	common.info("Player is advancing to level " .. nextLevel)
	
	player.givePerkPoints(tes3.player.data.KBProgression.incPoints.prk)
	if not (nextLevel % mcm.prkLvlInterval > 0) then
		player.givePerkPoints(mcm.prkLvlMult * tes3.player.data.KBProgression.pntMult.prk)
	end
	
	player.giveAttributePoints(tes3.player.data.KBProgression.incPoints.atr)
	if not (nextLevel % mcm.atrLvlInterval > 0) then
		player.giveAttributePoints(mcm.atrLvlMult * tes3.player.data.KBProgression.pntMult.atr)
	end
	
	player.giveMajorSkillPoints(tes3.player.data.KBProgression.incPoints.mjr)
	if mcm.xpEnabled and not (nextLevel % mcm.mjrLvlInterval > 0) then
		player.giveMajorSkillPoints(mcm.mjrLvlMult * tes3.player.data.KBProgression.pntMult.mjr)
	end
	
	player.giveMinorSkillPoints(tes3.player.data.KBProgression.incPoints.mnr)
	if mcm.xpEnabled and not (nextLevel % mcm.mnrLvlInterval > 0) then
		player.giveMinorSkillPoints(mcm.mnrLvlMult * tes3.player.data.KBProgression.pntMult.mnr)
	end
	
	player.giveMiscSkillPoints(tes3.player.data.KBProgression.incPoints.msc)
	if mcm.xpEnabled and not (nextLevel % mcm.mscLvlInterval > 0) then
		player.giveMiscSkillPoints(mcm.mscLvlMult * tes3.player.data.KBProgression.pntMult.msc)
	end
end
event.register("preLevelUp", setUpLevel)