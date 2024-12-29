local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")


local daedra = {}


function daedra.createWindow(ref)
	--Initialize IDs
	daedra.id_menu = tes3ui.registerID("kl_daedra_menu")
	daedra.id_pane = tes3ui.registerID("kl_daedra_pane")
	daedra.id_ok = tes3ui.registerID("kl_daedra_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("daedra menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")

	local conjuration = ref.mobile:getSkillStatistic(13)
	local intelligence = ref.mobile.attributes[2]
	local modData = func.getModData(ref)
	daedra.limit = 1

	-- Create window and frame
	local menu = tes3ui.createMenu { id = daedra.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_daedra" }
	head_block.autoWidth = true
	head_block.autoHeight = true
	head_block.borderBottom = 5

	--Title/TP Bar Blocks
	local title_block = head_block:createBlock{}
	title_block.width = 265
	title_block.autoHeight = true

	local tp_block = head_block:createBlock{}
	tp_block.width = 265
	tp_block.autoHeight = true

	-- Title
	title_block:createLabel { text = "Call which daedra?" }

	-- Magicka Bar
	daedra.mgk_bar = tp_block:createFillBar({ current = ref.mobile.magicka.current, max = ref.mobile.magicka.base, id = daedra.id_mgk_bar })
	func.configureBar(daedra.mgk_bar, "small", "blue")
	daedra.mgk_bar.borderLeft = 20

	-- TP Bar
	daedra.tp_bar = tp_block:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = daedra.id_tp_bar })
	func.configureBar(daedra.tp_bar, "small", "purple")
	daedra.tp_bar.borderLeft = 5

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_daedra" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- Pane Border
	local border = pane_block:createThinBorder { id = "kl_border_daedra" }
	border.positionX = 4
	border.positionY = -4
	border.width = 210
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4

	-- Material Border
	local border2 = pane_block:createThinBorder { id = "kl_border2_daedra" }
	border2.positionX = 202
	border2.positionY = 0
	border2.width = 308
	border2.height = 170
	border2.paddingAllSides = 4
	border2.wrapText = true
	border2.flowDirection = tes3.flowDirection.topToBottom

	----Populate-----------------------------------------------------------------------------------------------------

	local mats = border2:createLabel { text = "", id = "kl_daedra_mats_0"}
	mats.wrapText = true
	mats.justifyText = tes3.justifyText.center
	mats.borderTop = 12

	daedra.mats = mats

	--Pane
	local pane = border:createVerticalScrollPane { id = daedra.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	--Populate Pane
	local scamp = tes3.getObject("scamp")
	local fear = tes3.getObject("clannfear")
	local flame = tes3.getObject("atronach_flame")
	local frost = tes3.getObject("atronach_frost")
	local storm = tes3.getObject("atronach_storm")
	local hunger = tes3.getObject("hunger")
	local daedroth = tes3.getObject("daedroth")
	local ogrim = tes3.getObject("ogrim")
	local twilight = tes3.getObject("winged twilight")
	local saint = tes3.getObject("golden saint")
	local demon = tes3.getObject("dremora")

	daedra.total = 0

	if conjuration.current > 25 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Scamp", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, scamp, 3, 40) end)
	end

	if conjuration.current >= 30 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Clannfear", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, fear, 4, 50) end)
	end

	if conjuration.current >= 40 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Flame Atronach", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, flame, 5, 70) end)
	end

	if conjuration.current >= 55 and modData.level > 5 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Frost Atronach", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, frost, 7, 90) end)
	end

	if conjuration.current >= 60 and modData.level > 6 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Hunger", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, hunger, 8, 110) end)
	end

	if conjuration.current >= 65 and modData.level > 7 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Ogrim", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, ogrim, 8, 120) end)
	end

	if conjuration.current >= 70 and modData.level > 9 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Winged Twilight", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, twilight, 9, 140) end)
	end

	if conjuration.current >= 75 and modData.level > 9 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Storm Atronach", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, storm, 10, 160) end)
	end

	if conjuration.current >= 85 and modData.level > 10 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Daedroth", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, daedroth, 12, 190) end)
	end

	if conjuration.current >= 95 and modData.level > 11 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Dremora", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, demon, 15, 225) end)
	end

	if conjuration.current >= 100 and modData.level > 14 then
		daedra.total = daedra.total + 1
		local a = pane:createTextSelect { text = "Golden Saint", id = "kl_daedra_btn_" .. daedra.total .. "" }
		a:register("mouseClick", function(e) daedra.onSelect(a, saint, 20, 300) end)
	end

	--Calculate Bonuses
	local modifier = math.round(intelligence.current + (conjuration.current / 4))
	if modifier > 350 then
		modifier = 350
	end

	local modifier2 = math.round(conjuration.current + (intelligence.current / 4))
	if modifier2 > 250 then
		modifier2 = 250
	end
	daedra.mgkReduction = math.round(modifier2 * 0.25)

	daedra.hthBonus = math.round(modifier * 0.30)
	daedra.mgkBonus = math.round(modifier * 0.30)
	daedra.fatBonus = math.round(modifier * 0.50)
	daedra.strBonus = math.round(modifier * 0.12)

	--Text Block
	local text_block = menu:createBlock { id = "text_block_daedra" }
	text_block.width = 490
	text_block.height = 112
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local base_block = text_block:createBlock {}
	base_block.width = 175
	base_block.height = 112
	base_block.borderAllSides = 4
	base_block.flowDirection = "top_to_bottom"

	local ench_block = text_block:createBlock {}
	ench_block.width = 175
	ench_block.height = 112
	ench_block.borderAllSides = 4
	ench_block.flowDirection = "top_to_bottom"
	ench_block.wrapText = true

	local total_block = text_block:createBlock {}
	total_block.width = 175
	total_block.height = 112
	total_block.borderAllSides = 4
	total_block.flowDirection = "top_to_bottom"
	total_block.wrapText = true

	--Base Statistics
	local base_title = base_block:createLabel({ text = "Base Statistics:", id = "kl_att_daedra" })
	base_title.color = { 1.0, 1.0, 1.0 }
	daedra.base_hth = base_block:createLabel({ text = "Health: ", id = "kl_daedra_hth" })
	daedra.base_mgk = base_block:createLabel({ text = "Magicka: ", id = "kl_daedra_mgk" })
	daedra.base_fat = base_block:createLabel({ text = "Fatigue: ", id = "kl_daedra_fat" })
	daedra.base_str = base_block:createLabel({ text = "Strength: ", id = "kl_daedra_str" })
	daedra.base_cost = base_block:createLabel({ text = "Magicka Cost: ", id = "kl_daedra_cost" })

	--Enchantments
	local ench_title = ench_block:createLabel({ text = "Enhancements:" })
	ench_title.color = { 1.0, 1.0, 1.0 }
	func.clTooltip(ench_title, "att:1")
	ench_block:createLabel { text = "Health: +" .. daedra.hthBonus .. "", id = "kl_daedra_hth_e" }
	ench_block:createLabel { text = "Magicka: +" .. daedra.mgkBonus .. "", id = "kl_daedra_mgk_e" }
	ench_block:createLabel { text = "Fatigue: +" .. daedra.fatBonus .. "", id = "kl_daedra_fat_e" }
	ench_block:createLabel { text = "Strength: +" .. daedra.strBonus .. "", id = "kl_daedra_str_e" }
	local reduc = ench_block:createLabel { text = "Reduction: " .. daedra.mgkReduction .. "%", id = "kl_daedra_cost_e" }
	func.clTooltip(reduc, "skill:13")

	--Totals
	local total_title = total_block:createLabel({ text = "Total Statistics:" })
	total_title.color = { 1.0, 1.0, 1.0 }
	daedra.total_hth = total_block:createLabel { text = "Health: ", id = "kl_daedra_hth_t" }
	daedra.total_mgk = total_block:createLabel { text = "Magicka: ", id = "kl_daedra_mgk_t" }
	daedra.total_fat = total_block:createLabel { text = "Fatigue: ", id = "kl_daedra_fat_t" }
	daedra.total_str = total_block:createLabel { text = "Strength: ", id = "kl_daedra_str_t" }
	daedra.total_cost = total_block:createLabel { text = "Total Cost: ", id = "kl_daedra_cost_t" }

	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 12

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	daedra.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		if ref.mobile.magicka.current < daedra.mgkCost then
			tes3.messageBox("Not enough magicka!")
			return
		end

		if modData.tp_current < daedra.tp then
			tes3.messageBox("Not enough Technique Points!")
			return
		end

		local thralls = 0

		for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
			if (mobileActor.reference.object.objectType == tes3.objectType.creature) and mobileActor.reference.object.type == 1
			and string.startswith(mobileActor.reference.object.name, "Summoned") == false then
				thralls = thralls + 1
				if thralls >= daedra.limit then
					tes3.messageBox("Your party cannot summon more than one empowered daedra at a time.")
					return
				end
			end
		end

		--Spend TP
		modData.tp_current = modData.tp_current - daedra.tp
		
		--Spend Magicka
		tes3.modStatistic({ reference = ref, name = "magicka", current = (daedra.mgkCost * -1) })

		--Summon Daedra
		local minion = tes3.createReference({ object = daedra.obj, position = tes3.getCameraPosition(), orientation = tes3.player.orientation:copy(), cell = tes3.player.cell })
		tes3.createVisualEffect({ object = "VFX_DefaultHit", lifespan = 3, reference = minion })
		tes3.playSound({ sound = "conjuration hit", reference = minion })
		minion.mobile.fight = 40
		tes3.setAIFollow({ reference = minion, target = ref })


		--Apply Bonuses
		tes3.modStatistic({ name = "health", value = daedra.hthBonus, reference = minion })
		tes3.modStatistic({ name = "magicka", value = daedra.mgkBonus, reference = minion })
		tes3.modStatistic({ name = "fatigue", value = daedra.fatBonus, reference = minion })
		tes3.modStatistic({ attribute = tes3.attribute.strength, value = daedra.strBonus, reference = minion })

		menu:destroy()
		tes3ui.leaveMenuMode()
	end)
	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(daedra.id_menu)
end

function daedra.onSelect(elem, obj, tp, mgk)
	local menu = tes3ui.findMenu(daedra.id_menu)

	if menu then
		for i = 1, daedra.total do
			local btn = menu:findChild("kl_daedra_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4
		daedra.obj = obj
		daedra.tp = tp
		daedra.mgkCost = math.round(mgk * (1 - (daedra.mgkReduction * 0.01)))

		daedra.base_hth.text = "Health: " .. obj.health .. ""
		daedra.base_mgk.text = "Magicka: " .. obj.magicka .. ""
		daedra.base_fat.text = "Fatigue: " .. obj.fatigue .. ""
		daedra.base_str.text = "Strength: " .. obj.attributes[1] .. ""
		daedra.base_cost.text = "Base Cost: " .. mgk .. ""

		daedra.total_hth.text = "Health: " .. obj.health + daedra.hthBonus .. ""
		daedra.total_mgk.text = "Magicka: " .. obj.magicka + daedra.mgkBonus .. ""
		daedra.total_fat.text = "Fatigue: " .. obj.fatigue + daedra.fatBonus .. ""
		daedra.total_str.text = "Strength: " .. obj.attributes[1] + daedra.strBonus .. ""
		daedra.total_cost.text = "Total Cost: " .. daedra.mgkCost .. ""

		daedra.mats.text = "" .. obj.name .. "\n\nTP Cost: " .. tp .. ""

		daedra.ok.widget.state = 1
		daedra.ok.disabled = false

		menu:updateLayout()
	end
end


return daedra