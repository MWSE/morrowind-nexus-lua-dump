local config = require("OEA.OEA10 Fresh.config")

local H = {}

function H.updateMenuMulti()
	local amount = mwscript.getItemCount({ reference = tes3.player, item = "Gold_001" })
	local label = tes3ui.findMenu(tes3ui.registerID("MenuMulti")):findChild(tes3ui.registerID("OEA10_MoneyCount"))
	label.text = string.format("%u", amount)
	label:updateLayout()

	if (config.Money == true) then
		tes3.modStatistic({
			reference = tes3.mobilePlayer,
			name = "health",
			base = (amount - tes3.mobilePlayer.health.base)
		})
		tes3.modStatistic({
			reference = tes3.mobilePlayer,
			name = "health",
			current = (amount - tes3.mobilePlayer.health.current)
		})
	end
end

local function createMulti(e)
	local block
	local image
	local label
	local multiMenu

	local GoldBlock = tes3ui.registerID("OEA10_BlockOfGold")
	local ImageID = tes3ui.registerID("OEA10_CoinImage")
	local TextID = tes3ui.registerID("OEA10_MoneyCount")
	local HUDMenuID = tes3ui.registerID("MenuMulti")

	if (e.element == nil) then
		multiMenu = tes3ui.findMenu(HUDMenuID)
	else
		multiMenu = e.element
	end

	if (multiMenu == nil) then
		return
	end

	local bar = multiMenu:findChild(tes3ui.registerID("MenuStat_health_fillbar"))
	if (bar ~= nil) then
		bar.visible = false
	end

	local timedText = multiMenu:findChild(tes3ui.registerID("MenuMulti_weapon_magic_notify"))
	timedText.borderBottom = 30

	local enemyHealth = multiMenu:findChild(tes3ui.registerID("MenuMulti_npc_health_bar"))
	enemyHealth.borderBottom = 30

	if (multiMenu:findChild(GoldBlock) ~= nil) then
		block = multiMenu:findChild(GoldBlock)
	else
		block = multiMenu:createBlock{ id = GoldBlock }
	end
	block.flowDirection = "left_to_right"

	block.positionX = 0
	block.positionY = 0
	block.autoWidth = true
	block.autoHeight = true

        block.absolutePosAlignX = 0.02
        block.absolutePosAlignY = 0.895

	if (block:findChild(ImageID) ~= nil) then
		image = block:findChild(ImageID)
	else
		image = block:createImage{ id = ImageID, path = "Icons\\gold.dds" }
	end
	image.imageScaleX = 1.5
	image.imageScaleY = 1.5

	local amount = mwscript.getItemCount({ reference = tes3.player, item = "Gold_001" })
	if (block:findChild(TextID) ~= nil) then
		label = block:findChild(TextID)
	else
		label = block:createLabel{ id = TextID }
	end
	label.text = string.format("%u", amount)
	label.font = 1

	if (config.Money == true) then
		tes3.modStatistic({
			reference = tes3.mobilePlayer,
			name = "health",
			base = (amount - tes3.mobilePlayer.health.base)
		})
		tes3.modStatistic({
			reference = tes3.mobilePlayer,
			name = "health",
			current = (amount - tes3.mobilePlayer.health.current)
		})
	end

	image.visible = true
	label.visible = true
	block.visible = true
	
	label:updateLayout()
	block:updateLayout()
	multiMenu:updateLayout()
end

local function createStats(e)
	local block2
	local image2
	local label2
	local statsMenu

	local ImageID2 = tes3ui.registerID("OEA10_CoinImage_2")
	local TextID2 = tes3ui.registerID("OEA10_MoneyCount_2")
	local StatsMenuID = tes3ui.registerID("MenuStat")

	if (e.element == nil) then
		statsMenu = tes3ui.findMenu(StatsMenuID)
	else
		statsMenu = e.element
	end

	if (statsMenu == nil) then
		return
	end

	local block2 = statsMenu:findChild(tes3ui.registerID("MenuStat_health_layout"))
	if (block2 ~= nil) then
		for _, child in pairs(block2.children) do
			child.visible = false
		end
	end

	if (block2:findChild(ImageID2) ~= nil) then
		image2 = block2:findChild(ImageID2)
	else
		image2 = block2:createImage{ id = ImageID2, path = "Icons\\gold.dds" }
	end
	image2.imageScaleX = 1.5
	image2.imageScaleY = 1.5

	local amount2 = mwscript.getItemCount({ reference = tes3.player, item = "Gold_001" })
	if (block2:findChild(TextID2) ~= nil) then
		label2 = block2:findChild(TextID2)
	else
		label2 = block2:createLabel{ id = TextID2 }
	end
	label2.text = string.format("%u", amount2)
	label2.font = 1

	image2.visible = true
	label2.visible = true
	block2.visible = true
	
	label2:updateLayout()
	block2:updateLayout()
	statsMenu:updateLayout()
end

local function createStatReview(e)
	local block3
	local image3
	local label3
	local statReviewMenu

	local ImageID3 = tes3ui.registerID("OEA10_CoinImage_3")
	local TextID3 = tes3ui.registerID("OEA10_MoneyCount_3")
	local StatReviewMenuID = tes3ui.registerID("MenuStatReview")

	if (e.element == nil) then
		statReviewMenu = tes3ui.findMenu(StatReviewMenuID)
	else
		statReviewMenu = e.element
	end

	if (statReviewMenu == nil) then
		return
	end

	local block3 = statReviewMenu:findChild(tes3ui.registerID("MenuStatReview_health_layout"))
	if (block3 ~= nil) then
		for _, child in pairs(block3.children) do
			child.visible = false
		end
	end

	if (block3:findChild(ImageID3) ~= nil) then
		image3 = block3:findChild(ImageID3)
	else
		image3 = block3:createImage{ id = ImageID3, path = "Icons\\gold.dds" }
	end
	image3.imageScaleX = 1.5
	image3.imageScaleY = 1.5

	local amount3 = mwscript.getItemCount({ reference = tes3.player, item = "Gold_001" })
	if (block3:findChild(TextID3) ~= nil) then
		label3 = block3:findChild(TextID3)
	else
		label3 = block3:createLabel{ id = TextID3 }
	end
	label3.text = string.format("%u", amount3)
	label3.font = 1

	image3.visible = true
	label3.visible = true
	block3.visible = true
	
	label3:updateLayout()
	block3:updateLayout()
	statReviewMenu:updateLayout()
end

local function Damaged(e)
	if (e.reference ~= tes3.player) then
		return
	end

	tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = math.abs(e.damage) })
	createMulti(e)
end

local function OnTick(e)
	if (e.effectInstance.target == nil) or (e.effectInstance.target ~= tes3.player) then
		return
	end

	local change = e.effectInstance.magnitude

	if (e.sourceInstance.state == tes3.spellState.beginning) then
		if (e.effectId == tes3.effect.drainHealth) then
			tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = math.abs(change) })
			createMulti(e)
			createStats(e)
		end
	elseif (e.sourceInstance.state == tes3.spellState.working) then
		if (e.effectInstance.timeActive == 0) and (e.effectId == tes3.effect.fortifyHealth) then
			local guess = (e.effect.min + ((e.effect.max - e.effect.min) / 2))
			tes3.addItem({ reference = tes3.player, item = "Gold_001", count = guess })
			createMulti(e)
			createStats(e)
		end
	elseif (e.sourceInstance.state == tes3.spellState.ending) then
		if (e.effectId == tes3.effect.fortifyHealth) then
			createMulti(e)
			createStats(e)
		elseif (e.effectId == tes3.effect.drainHealth) then
			tes3.addItem({ reference = tes3.player, item = "Gold_001", count = math.abs(change) })
			createMulti(e)
			createStats(e)
		end
	end
end

local function MenuExit(e)
	createMulti(e)

	if (config.Tick == true) then
		event.unregister("spellTick", OnTick)
		event.register("spellTick", OnTick)
	elseif (config.Tick == false) then
		event.unregister("spellTick", OnTick)
	end
end

local function MenuEnter(e)
	createStats(e)
end

local function OnLoaded(e)
	if (e.newGame == true) and (tes3.player ~= nil) then
		if (config.Money == true) and (config.AltStart == false) then
			tes3.addItem({ reference = tes3.player, item = "Gold_001", count = 1 })
		end
	end

	event.unregister("uiActivated", createMulti, { filter = "MenuMulti" })
	event.unregister("uiActivated", createStats, { filter = "MenuStat" })
	event.unregister("uiActivated", createStatReview, { filter = "MenuStatReview" })
	event.unregister("spellTick", OnTick)
	event.unregister("damaged", Damaged)
	event.unregister("menuExit", MenuExit)
	event.unregister("menuEnter", MenuEnter)

	if (config.Money == true) then	
		event.register("uiActivated", createMulti, { filter = "MenuMulti" })
		event.register("uiActivated", createStats, { filter = "MenuStat" })
		event.register("uiActivated", createStatReview, { filter = "MenuStatReview" })
		if (config.Tick == true) then
			event.register("spellTick", OnTick)
		end
		event.register("damaged", Damaged)
		event.register("menuExit", MenuExit)
		event.register("menuEnter", MenuEnter)
	else
		local HUDMenuID = tes3ui.registerID("MenuMulti")
		local multiMenu = tes3ui.findMenu(HUDMenuID)
		local bar = multiMenu:findChild(tes3ui.registerID("MenuStat_health_fillbar"))
		bar.visible = true
		local block = multiMenu:findChild(tes3ui.registerID("OEA10_BlockOfGold"))
		if (block ~= nil) then
			block.visible = false
		end
		local timedText = multiMenu:findChild(tes3ui.registerID("MenuMulti_weapon_magic_notify"))
		timedText.borderBottom = nil
		local enemyHealth = multiMenu:findChild(tes3ui.registerID("MenuMulti_npc_health_bar"))
		enemyHealth.borderBottom = nil

		local StatsMenuID = tes3ui.registerID("MenuStat")
		local statsMenu = tes3ui.findMenu(StatsMenuID)
		local block2 = statsMenu:findChild(tes3ui.registerID("MenuStat_health_layout"))
		local ImageID2 = tes3ui.registerID("OEA10_CoinImage_2")	
		local image2 = block2:findChild(ImageID2)
		if (block2 ~= nil) and (image2 ~= nil) then
			for _, child in pairs(block2.children) do
				if (child.visible == true) then
					child.visible = false
				elseif (child.visible == false) then
					child.visible = true
				end
			end
			local bar = block2:findChild(tes3ui.registerID("MenuStat_health_fillbar"))
			bar.absolutePosAlignX = 1
		end
	end
end
event.register("loaded", OnLoaded)

return H