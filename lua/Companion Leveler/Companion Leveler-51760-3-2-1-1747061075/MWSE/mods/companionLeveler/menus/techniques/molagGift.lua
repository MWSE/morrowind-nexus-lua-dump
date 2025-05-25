local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")


local molag = {}


function molag.createWindow(ref)
    molag.id_menu = tes3ui.registerID("kl_molag_menu")
	molag.id_soulBar = tes3ui.registerID("kl_molag_soulBar")
	molag.id_swapBar = tes3ui.registerID("kl_molag_swapBar")
	molag.id_plus = tes3ui.registerID("kl_molag_plus")
	molag.id_interval = tes3ui.registerID("kl_molag_interval")
	molag.id_gemFill = tes3ui.registerID("kl_molag_menu_gemFill")

    log = logger.getLogger("Companion Leveler")
    log:debug("Soul Energy menu initialized.")

    molag.ref = ref
	molag.interval = 1
	molag.resource = "health"
	molag.cost = 3
	molag.tMod = 1
	molag.aMod = 3
	molag.modData = func.getModData(ref)

    molag.menu = tes3ui.createMenu { id = molag.id_menu, fixedFrame = true }
	molag.menu.alpha = 1.0


    --Content Block--------------------------------------------------------------------------------------------------------
	local molag_block = molag.menu:createBlock { id = "kl_molag_block" }
    molag_block.flowDirection = "top_to_bottom"
    molag_block.autoHeight = true
    molag_block.autoWidth = true
    molag_block.paddingLeft = 10
    molag_block.paddingRight = 10
    molag_block.widthProportional = 1.0
	molag_block.childAlignX = 0.5

	--Title
    local title = molag_block:createLabel { text = "" }
    local divider = molag_block:createDivider{}
    divider.borderBottom = 32

	--Soul Energy
    molag_block:createLabel { text = "Soul Energy" }
    molag.soulBar = molag_block:createFillBar({ current = molag.modData.soulEnergy, max = molag.modData.level * 100, id = molag.id_soulBar })
	func.configureBar(molag.soulBar, "standard", "azure")
    molag.soulBar.borderBottom = 40
	molag.soulBar.borderTop = 3
	
	--Controls
	local interval = molag_block:createButton {text = "Rate: 1pt", id = molag.id_interval}
	molag.info = molag_block:createLabel { text = "" .. molag.ref.object.name .. " will receive " .. molag.interval .. " " .. molag.resource .. " for " .. molag.cost .. " soul energy." }
	molag.info.borderBottom = 7
	molag.info.borderTop = 5
	local comPlus = molag_block:createButton {text = "+", id = molag.id_plus}

	--Cleric Values
    molag.pcLabel = molag_block:createLabel { text = "" .. molag.ref.object.name .. "" }
	molag.pcLabel.borderTop = 30
	molag.swapBar = molag_block:createFillBar({ current = molag.ref.mobile.health.current, max = molag.ref.mobile.health.base, id = molag.id_swapBar })
   	func.configureBar(molag.swapBar, "standard", "red")
    molag.swapBar.borderBottom = 12
	molag.swapBar.borderTop = 3


	--Attribute Swap
	local swapBlock = molag.menu:createBlock { id = "kl_swap_block" }
    swapBlock.autoHeight = true
    swapBlock.autoWidth = true
    swapBlock.paddingLeft = 10
    swapBlock.paddingRight = 10
    swapBlock.widthProportional = 1.0
	swapBlock.childAlignX = 0.5

	molag.hthBtn = swapBlock:createButton { id = "kl_hth_swap_btn", text = "" .. tes3.findGMST(tes3.gmst.sHealth).value .. "" }
	molag.hthBtn.widget.state = 4
	molag.mgkBtn = swapBlock:createButton { id = "kl_mgk_swap_btn", text = "" .. tes3.findGMST(tes3.gmst.sMagic).value .. "" }
	molag.fatBtn = swapBlock:createButton { id = "kl_fat_swap_btn", text = "" .. tes3.findGMST(tes3.gmst.sFatigue).value .. "" }
	molag.hthBtn:register("mouseClick", function() molag.onSwap("health") end)
	molag.mgkBtn:register("mouseClick", function() molag.onSwap("magicka") end)
	molag.fatBtn:register("mouseClick", function() molag.onSwap("fatigue") end)

	--Target Swap
	local targLabel = molag.menu:createLabel{ text = "Targets:"}
	targLabel.wrapText =true
	targLabel.justifyText = tes3.justifyText.center
	targLabel.borderBottom = 6
	targLabel.borderTop = 24
	local targetBlock = molag.menu:createBlock { id = "kl_target_block" }
	targetBlock.autoHeight = true
	targetBlock.autoWidth = true
	targetBlock.paddingLeft = 10
	targetBlock.paddingRight = 10
	targetBlock.widthProportional = 1.0
	targetBlock.childAlignX = 0.5

	molag.refBtn = targetBlock:createButton { id = "kl_ref_target_btn", text = "" .. ref.object.name .. "" }
	molag.refBtn.widget.state = 4
	molag.pcBtn = targetBlock:createButton { id = "kl_pc_target_btn", text = "" .. tes3.player.object.name .. "" }
	molag.gemBtn = targetBlock:createButton { id = "kl_gem_target_btn", text = "Soul Gem" }
	molag.refBtn:register("mouseClick", function() molag.onTarget(ref) end)
	molag.pcBtn:register("mouseClick", function() molag.onTarget(tes3.player) end)
	molag.gemBtn:register("mouseClick", function() molag.onGem() end)


	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = molag.menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 32

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }

	--Events
	interval:register("mouseClick", function() molag.onInterval() end)
	comPlus:register("mouseClick", function() molag.onPlus() end)
	button_ok:register("mouseClick", function() tes3ui.leaveMenuMode() molag.menu:destroy() tes3.playSound({sound = "mysticism cast"}) end)


    --Final setup
	title.text = "Soul Manipulation"

    molag.menu:updateLayout()
    tes3ui.enterMenuMode(molag.id_menu)
end

function molag.onPlus()
	local menu = tes3ui.findMenu(molag.id_menu)

	if menu then
		local pcValue = molag.ref.mobile.health
		local msg = "" .. molag.ref.object.name .. " drew " .. molag.interval .. " " .. molag.resource .. " from their Soul Energy!"

		if molag.resource == "magicka" then
			pcValue = molag.ref.mobile.magicka
		elseif molag.resource == "fatigue" then
			pcValue = molag.ref.mobile.fatigue
		end

		if ((pcValue.current  + molag.interval) <= pcValue.base and molag.modData.soulEnergy >= molag.cost) then
			--Success
			tes3.modStatistic({ name = molag.resource, reference = molag.ref, current = molag.interval })
			molag.swapBar.widget.current = pcValue.current
			molag.updateEnergy(molag.cost)
			tes3.playSound({ sound = "restoration area" })
			log:trace(msg)
		else
			--Failure
			tes3.playSound({ sound = "Spell Failure Mysticism" })
		end
	end
end

function molag.onInterval()
	local menu = tes3ui.findMenu(molag.id_menu)

	if menu then
		local button = menu:findChild(molag.id_interval)

		if string.match(button.text, "1pt") then
            button.text = string.gsub(button.text, "1pt", "5pts")
            molag.interval = 5
        elseif string.match(button.text, "5pts") then
            button.text = string.gsub(button.text, "5pts", "10pts")
            molag.interval = 10
		elseif string.match(button.text, "10pts") then
			button.text = string.gsub(button.text, "10pts", "50pts")
            molag.interval = 50
		elseif string.match(button.text, "50pts") then
			button.text = string.gsub(button.text, "50pts", "100pts")
            molag.interval = 100
		elseif string.match(button.text, "100pts") then
			button.text = string.gsub(button.text, "100pts", "1pt")
			molag.interval = 1
		end

		molag.cost = math.round((molag.interval * molag.aMod) * molag.tMod)
		molag.info.text = "" .. molag.ref.object.name .. " will receive " .. molag.interval .. " " .. molag.resource .. " for " .. molag.cost .. " soul energy."
		menu:updateLayout()
	end
end

function molag.onSwap(resource)
	local menu = tes3ui.findMenu(molag.id_menu)
	if menu then
		molag.resource = resource

		if resource == "health" then
			molag.aMod = 3
			molag.hthBtn.widget.state = 4
			molag.mgkBtn.widget.state = 1
			molag.fatBtn.widget.state = 1
			molag.swapBar.widget.current = molag.ref.mobile.health.current
			molag.swapBar.widget.max = molag.ref.mobile.health.base
			func.configureBar(molag.swapBar, "standard", "red")
		elseif resource == "magicka" then
			molag.aMod = 5
			molag.hthBtn.widget.state = 1
			molag.mgkBtn.widget.state = 4
			molag.fatBtn.widget.state = 1
			molag.swapBar.widget.current = molag.ref.mobile.magicka.current
			molag.swapBar.widget.max = molag.ref.mobile.magicka.base
			func.configureBar(molag.swapBar, "standard", "blue")
		else
			molag.aMod = 0.2
			molag.hthBtn.widget.state = 1
			molag.mgkBtn.widget.state = 1
			molag.fatBtn.widget.state = 4
			molag.swapBar.widget.current = molag.ref.mobile.fatigue.current
			molag.swapBar.widget.max = molag.ref.mobile.fatigue.base
			func.configureBar(molag.swapBar, "standard", "green")
		end

		molag.cost = math.round((molag.interval * molag.aMod) * molag.tMod)
		if molag.cost < 1 then
			molag.cost = 1
		end
		molag.info.text = "" .. molag.ref.object.name .. " will receive " .. molag.interval .. " " .. molag.resource .. " for " .. molag.cost .. " soul energy."
		menu:updateLayout()
	end
end

function molag.onTarget(ref)
	local menu = tes3ui.findMenu(molag.id_menu)
	if menu then
		molag.ref = ref
		molag.pcLabel.text = "" .. ref.object.name .. ""
		if molag.ref == tes3.player then
			molag.tMod = 2
			molag.pcBtn.widget.state = 4
			molag.refBtn.widget.state = 1
		else
			molag.tMod = 1
			molag.pcBtn.widget.state = 1
			molag.refBtn.widget.state = 4
		end

		if molag.resource == "health" then
			molag.swapBar.widget.current = molag.ref.mobile.health.current
			molag.swapBar.widget.max = molag.ref.mobile.health.base
		elseif molag.resource == "magicka" then
			molag.swapBar.widget.current = molag.ref.mobile.magicka.current
			molag.swapBar.widget.max = molag.ref.mobile.magicka.base
		else
			molag.swapBar.widget.current = molag.ref.mobile.fatigue.current
			molag.swapBar.widget.max = molag.ref.mobile.fatigue.base
		end

		molag.cost = math.round((molag.interval * molag.aMod) * molag.tMod)
		if molag.cost < 1 then
			molag.cost = 1
		end
		molag.info.text = "" .. molag.ref.object.name .. " will receive " .. molag.interval .. " " .. molag.resource .. " for " .. molag.cost .. " soul energy."
		menu:updateLayout()
	end
end

function molag.onGem()
	tes3ui.showInventorySelectMenu({
		reference = tes3.player,
		title = "Choose a " .. tes3.findGMST(tes3.gmst.sSoulGem).value .. " to fill.",
		filter = function(e)
			if e.item.isSoulGem and not e.itemData then
				return true
			else
				return false
			end
		end,
		callback =
		function(e)
			if not e.item then return end

			local menu = tes3ui.createMenu { id = molag.id_gemFill, fixedFrame = true }
			menu.alpha = 1.0
			menu.absolutePosAlignY = 0.52 --shows bar beneath
			local fill_block = menu:createBlock { id = "kl_gemFill_block" }
			fill_block.flowDirection = "top_to_bottom"
			fill_block.autoHeight = true
			fill_block.autoWidth = true
			fill_block.paddingLeft = 10
			fill_block.paddingRight = 10
			fill_block.widthProportional = 1.0
			fill_block.autoHeight = true
			fill_block.childAlignX = 0.5

			local capacity = e.item.soulGemCapacity
			local capacityLabel = fill_block:createLabel{ text = "" .. e.item.name .. " Capacity: " .. capacity .. "" }
			capacityLabel.wrapText = true
			capacityLabel.justifyText = "center"
			capacityLabel.borderBottom = 12

			local btn1 = fill_block:createButton { id = "kl_soul_btn_1", text = "30pts: 30 Soul Energy" }
			if capacity < 30 or molag.modData.soulEnergy < 30 then
				btn1.widget.state = 2
				btn1.disabled = true
			end
			btn1:register("mouseClick", function() molag.updateEnergy(30) tes3.removeItem({ reference = tes3.player, item = e.item, count = 1, playSound = false }) tes3.addItem{ reference = tes3.player, item = e.item, soul = tes3.getObject("kl_petty_vestige") } tes3.messageBox("Molag Bal empowered the " .. e.item.name .. " with a petty soul.") tes3.playSound({ sound = "enchant success" }) menu:destroy() end)

			local btn2 = fill_block:createButton { id = "kl_soul_btn_2", text = "60pts: 80 Soul Energy" }
			if capacity < 60 or molag.modData.soulEnergy < 80 then
				btn2.widget.state = 2
				btn2.disabled = true
			end
			btn2:register("mouseClick", function() molag.updateEnergy(80) tes3.removeItem({ reference = tes3.player, item = e.item, count = 1, playSound = false }) tes3.addItem{ reference = tes3.player, item = e.item, soul = tes3.getObject("kl_lesser_vestige") } tes3.messageBox("Molag Bal empowered the " .. e.item.name .. " with a lesser soul.") tes3.playSound({ sound = "enchant success" }) menu:destroy() end)

			local btn3 = fill_block:createButton { id = "kl_soul_btn_3", text = "120pts: 150 Soul Energy" }
			if capacity < 120 or molag.modData.soulEnergy < 150 then
				btn3.widget.state = 2
				btn3.disabled = true
			end
			btn3:register("mouseClick", function() molag.updateEnergy(150) tes3.removeItem({ reference = tes3.player, item = e.item, count = 1, playSound = false }) tes3.addItem{ reference = tes3.player, item = e.item, soul = tes3.getObject("kl_common_vestige") } tes3.messageBox("Molag Bal empowered the " .. e.item.name .. " with a common soul.") tes3.playSound({ sound = "enchant success" }) menu:destroy() end)

			local btn4 = fill_block:createButton { id = "kl_soul_btn_4", text = "180pts: 250 Soul Energy" }
			if capacity < 180 or molag.modData.soulEnergy < 250 then
				btn4.widget.state = 2
				btn4.disabled = true
			end
			btn4:register("mouseClick", function() molag.updateEnergy(250) tes3.removeItem({ reference = tes3.player, item = e.item, count = 1, playSound = false }) tes3.addItem{ reference = tes3.player, item = e.item, soul = tes3.getObject("kl_greater_vestige") } tes3.messageBox("Molag Bal empowered the " .. e.item.name .. " with a greater soul.") tes3.playSound({ sound = "enchant success" }) menu:destroy() end)

			local btn5 = fill_block:createButton { id = "kl_soul_btn_5", text = "300pts: 400 Soul Energy" }
			if capacity < 300 or molag.modData.soulEnergy < 400 then
				btn5.widget.state = 2
				btn5.disabled = true
			end
			btn5:register("mouseClick", function() molag.updateEnergy(400) tes3.removeItem({ reference = tes3.player, item = e.item, count = 1, playSound = false }) tes3.addItem{ reference = tes3.player, item = e.item, soul = tes3.getObject("kl_grand_vestige") } tes3.messageBox("Molag Bal empowered the " .. e.item.name .. " with a grand soul.") tes3.playSound({ sound = "enchant success" }) menu:destroy() end)

			local btn6 = fill_block:createButton { id = "kl_soul_btn_6", text = "400pts: 600 Soul Energy" }
			if capacity < 400 or molag.modData.soulEnergy < 600 then
				btn6.widget.state = 2
				btn6.disabled = true
			end
			btn6:register("mouseClick", function() molag.updateEnergy(600) tes3.removeItem({ reference = tes3.player, item = e.item, count = 1, playSound = false }) tes3.addItem{ reference = tes3.player, item = e.item, soul = tes3.getObject("kl_powerful_vestige") } tes3.messageBox("Molag Bal empowered the " .. e.item.name .. " with a powerful soul.") tes3.playSound({ sound = "enchant success" }) menu:destroy() end)

			local btn7 = fill_block:createButton { id = "kl_soul_btn_7", text = "600pts: 2000 Soul Energy" }
			if capacity < 600 or molag.modData.soulEnergy < 2000 then
				btn7.widget.state = 2
				btn7.disabled = true
			end
			btn7:register("mouseClick", function() molag.updateEnergy(2000) tes3.removeItem({ reference = tes3.player, item = e.item, count = 1, playSound = false }) tes3.addItem{ reference = tes3.player, item = e.item, soul = tes3.getObject("kl_exceptional_vestige") } tes3.messageBox("Molag Bal empowered the " .. e.item.name .. " with an exceptionally powerful soul!") tes3.playSound({ sound = "enchant success" }) menu:destroy() end)

			local button_block = menu:createBlock {}
			button_block.widthProportional = 1.0
			button_block.autoHeight = true
			button_block.childAlignX = 0.5
			button_block.borderTop = 20
		
			local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }
			button_cancel:register("mouseClick", function() menu:destroy() end)

			tes3ui.enterMenuMode(molag.id_gemFill)
		end
	})
end

function molag.updateEnergy(cost)
	molag.modData.soulEnergy = molag.modData.soulEnergy - cost
	molag.soulBar.widget.current = molag.modData.soulEnergy
	molag.menu:updateLayout()
end

return molag