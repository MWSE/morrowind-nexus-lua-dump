local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")


local drugs = {}


function drugs.createWindow(ref)
	--Initialize IDs
	drugs.id_menu = tes3ui.registerID("kl_drugs_menu")
	drugs.id_pane = tes3ui.registerID("kl_drugs_pane")
	drugs.id_ok = tes3ui.registerID("kl_drugs_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("Drugs menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")

	local modData = func.getModData(ref)
	local alchemy = ref.mobile:getSkillStatistic(tes3.skill.alchemy)
	drugs.alchemyText = tes3.findGMST(tes3.gmst.sSkillAlchemy).value
	drugs.sugar = tes3.getObject("ingred_moon_sugar_01")
	drugs.petal = tes3.getObject("ingred_fire_petal_01")
	drugs.flower = tes3.getObject("ingred_bc_coda_flower")
	drugs.kanet = tes3.getObject("ingred_gold_kanet_01")

	-- Create window and frame
	local menu = tes3ui.createMenu { id = drugs.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_drugs" }
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
	title_block:createLabel { text = "Skooma Synthesis" }

	-- TP Bar
	drugs.tp_bar = tp_block:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = drugs.id_tp_bar })
	func.configureBar(drugs.tp_bar, "small", "purple")
	drugs.tp_bar.borderLeft = 145

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_drugs" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- Pane Border
	local border = pane_block:createThinBorder { id = "kl_border_drugs" }
	border.positionX = 4
	border.positionY = -4
	border.width = 210
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4

	-- Material Border
	local border2 = pane_block:createThinBorder { id = "kl_border2_drugs" }
	border2.positionX = 202
	border2.positionY = 0
	border2.width = 308
	border2.height = 170
	border2.paddingAllSides = 4
	border2.wrapText = true
	border2.flowDirection = tes3.flowDirection.topToBottom

	----Populate-----------------------------------------------------------------------------------------------------

	--Materials
	local mTitle = border2:createLabel { text = "Materials", id = "kl_drugs_mTitle" }
	mTitle.wrapText = true
	mTitle.justifyText = tes3.justifyText.center
	mTitle.borderBottom = 20

	local mats = border2:createLabel { text = "", id = "kl_drugs_mats_0"}
	mats.wrapText = true
	mats.justifyText = tes3.justifyText.center

	drugs.mats = mats

	--Pane
	local pane = border:createVerticalScrollPane { id = drugs.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	--Populate Pane
	drugs.skooma = tes3.getObject("potion_skooma_01")
	drugs.quality = tes3.getObject("kl_potion_skooma_quality")
	drugs.exclusive = tes3.getObject("kl_potion_skooma_exclusive")
	drugs.red = tes3.getObject("kl_potion_skooma_red")
	drugs.blue = tes3.getObject("kl_potion_skooma_blue")
	drugs.gold = tes3.getObject("kl_potion_skooma_gold")

	if alchemy.current >= 25 then
		local s = pane:createTextSelect { text = "" .. drugs.skooma.name .. "", id = "kl_drugs_btn_0" }
		s:register("mouseClick", function(e) drugs.onSelect(s, drugs.skooma, 25, 1, 0.5) end)
	end

	if alchemy.current >= 50 then
		local q = pane:createTextSelect { text = "" .. drugs.quality.name .. "", id = "kl_drugs_btn_1" }
		q:register("mouseClick", function(e) drugs.onSelect(q, drugs.quality, 50, 2, 1) end)
	end

	if alchemy.current >= 75 then
		local ex = pane:createTextSelect { text = "" .. drugs.exclusive.name .. "", id = "kl_drugs_btn_2" }
		ex:register("mouseClick", function(e) drugs.onSelect(ex, drugs.exclusive, 75, 3, 1.5) end)
	end

	if alchemy.current >= 100 then
		local r = pane:createTextSelect { text = "" .. drugs.red.name .. "", id = "kl_drugs_btn_3" }
		r:register("mouseClick", function(e) drugs.onSelect(r, drugs.red, 100, 5, 2) end)

		local b = pane:createTextSelect { text = "" .. drugs.blue.name .. "", id = "kl_drugs_btn_4" }
		b:register("mouseClick", function(e) drugs.onSelect(b, drugs.blue, 100, 5, 2) end)
	end

	if alchemy.current >= 150 then
		local g = pane:createTextSelect { text = "" .. drugs.gold.name .. "", id = "kl_drugs_btn_5" }
		g:register("mouseClick", function(e) drugs.onSelect(g, drugs.gold, 150, 6, 3) end)
	end



	--Calculate Bonuses
	local modifier = alchemy.current
	if modifier > 200 then
		modifier = 200
	end

	drugs.timeReduction = math.round(modifier * 0.40)

	--Text Block
	local text_block = menu:createBlock { id = "text_block_drugs" }
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
	local base_title = base_block:createLabel({ text = "Base Time:", id = "kl_att_drugs" })
	base_title.color = { 1.0, 1.0, 1.0 }
	drugs.base_time = base_block:createLabel({ text = "", id = "kl_drugs_time" })

	--Enchantments
	local ench_title = ench_block:createLabel({ text = "Time Reduction:" })
	ench_title.color = { 1.0, 1.0, 1.0 }
	func.clTooltip(ench_title, "skill:16")
	ench_block:createLabel { text = "" .. drugs.timeReduction .. "%", id = "kl_drugs_time_e" }

	--Totals
	local total_title = total_block:createLabel({ text = "Total Time:" })
	total_title.color = { 1.0, 1.0, 1.0 }
	drugs.total_time = total_block:createLabel { text = "", id = "kl_drugs_time_t" }

	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	drugs.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		if alchemy.current < drugs.req then
			func.clMessageBox("" .. ref.object.name .. " is not skilled enough to refine " .. drugs.obj.name .. ".")
			return
		end

		if modData.tp_current < drugs.tp then
			func.clMessageBox("Not enough Technique Points!")
			return
		end

		local item
		local add
		local success = false

		--Check Materials
		if drugs.req == 25 then
			item = func.checkReq(true, drugs.sugar.id, 8, tes3.player)

			if item then
				item = func.checkReq(false, drugs.sugar.id, 8, tes3.player)
				success = true
			else
				item = func.checkReq(true, drugs.sugar.id, 8, ref)
				if item then
					item = func.checkReq(false, drugs.sugar.id, 8, ref)
					success = true
				end
			end
		elseif drugs.req == 50 then
			item = func.checkReq(true, drugs.sugar.id, 10, tes3.player)

			if item then
				item = func.checkReq(false, drugs.sugar.id, 10, tes3.player)
				success = true
			else
				item = func.checkReq(true, drugs.sugar.id, 10, ref)
				if item then
					item = func.checkReq(false, drugs.sugar.id, 10, ref)
					success = true
				end
			end
		elseif drugs.req == 75 then
			item = func.checkReq(true, drugs.sugar.id, 12, tes3.player)

			if item then
				item = func.checkReq(false, drugs.sugar.id, 12, tes3.player)
				success = true
			else
				item = func.checkReq(true, drugs.sugar.id, 12, ref)
				if item then
					item = func.checkReq(false, drugs.sugar.id, 12, ref)
					success = true
				end
			end
		elseif drugs.req == 100 then
			local ingred = drugs.petal.id
			if drugs.obj.name == "Balmora Blue Skooma" then
				ingred = drugs.flower.id
			end
			item = func.checkReq(true, drugs.sugar.id, 15, tes3.player)
			add = func.checkReq(true, ingred, 2, tes3.player)

			if item and add then
				item = func.checkReq(false, drugs.sugar.id, 15, tes3.player)
				add = func.checkReq(false, ingred, 2, tes3.player)
				success = true
			else
				item = func.checkReq(true, drugs.sugar.id, 15, ref)
				add = func.checkReq(true, ingred, 2, ref)
				if item and add then
					item = func.checkReq(false, drugs.sugar.id, 15, ref)
					add = func.checkReq(false, ingred, 2, ref)
					success = true
				end
			end
		elseif drugs.req == 150 then
			item = func.checkReq(true, drugs.sugar.id, 20, tes3.player)
			add = func.checkReq(true, drugs.kanet.id, 2, tes3.player)

			if item and add then
				item = func.checkReq(false, drugs.sugar.id, 20, tes3.player)
				add = func.checkReq(false, drugs.kanet.id, 2, tes3.player)
				success = true
			else
				item = func.checkReq(true, drugs.sugar.id, 20, ref)
				add = func.checkReq(true, drugs.kanet.id, 2, ref)
				if item and add then
					item = func.checkReq(false, drugs.sugar.id, 20, ref)
					add = func.checkReq(false, drugs.kanet.id, 2, ref)
					success = true
				end
			end
		end

		if success then
			--Pass Time
			local gameHour = tes3.getGlobal('GameHour')
			gameHour = (gameHour + drugs.timeCost)
			tes3.setGlobal('GameHour', gameHour)
			tes3.playSound({sound = "potion success"})

			--Spend TP
			modData.tp_current = modData.tp_current - drugs.tp
			drugs.tp_bar.widget.current = modData.tp_current

			--Synthesize Drugs
			tes3.addItem({ reference = tes3.player, item = drugs.obj, count = 1 })
			func.clMessageBox("" .. drugs.obj.name .. " refined.")
			tes3.triggerCrime({ type = tes3.crimeType.theft, value = drugs.obj.value })
			menu:updateLayout()
		else
			--Not Enough Materials
			func.clMessageBox("Not enough materials.")
		end
	end)

	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(drugs.id_menu)
end

function drugs.onSelect(elem, obj, req, tp, time)
	local menu = tes3ui.findMenu(drugs.id_menu)

	if menu then
		for i = 0, 5 do
			local btn = menu:findChild("kl_drugs_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4
		drugs.obj = obj
		drugs.tp = tp
		drugs.req = req
		drugs.time = time
		drugs.timeCost = time * (1 - (drugs.timeReduction * 0.01))

		drugs.base_time.text = "" .. math.round(time * 60) .. " minutes"

		drugs.total_time.text = "" .. math.round(drugs.timeCost * 60, 1) .. " minutes"

		if req == 25 then
			drugs.mats.text = "" .. drugs.sugar.name .. ": 8\nTime: 30 minutes\n" .. drugs.alchemyText .. " Required: 25\nTP: " .. tp .. ""
		elseif req == 50 then
			drugs.mats.text = "" .. drugs.sugar.name .. ": 10\nTime: 1 hour\n" .. drugs.alchemyText .. " Required: 50\nTP: " .. tp .. ""
		elseif req == 75 then
			drugs.mats.text = "" .. drugs.sugar.name .. ": 12\nTime: 1.5 hours\n" .. drugs.alchemyText .. " Required: 75\nTP: " .. tp .. ""
		elseif req == 100 then
			if obj.name == "Vvardenfell Red Skooma" then
				drugs.mats.text = "" .. drugs.sugar.name .. ": 15\n" .. drugs.petal.name .. ": 2\nTime: 2 hours\n" .. drugs.alchemyText .. " Required: 100\nTP: " .. tp .. ""
			else
				drugs.mats.text = "" .. drugs.sugar.name .. ": 15\n" .. drugs.flower.name .. ": 2\nTime: 2 hours\n" .. drugs.alchemyText .. " Required: 100\nTP: " .. tp .. ""
			end
		elseif req == 150 then
			drugs.mats.text = "" .. drugs.sugar.name .. ": 20\n" .. drugs.kanet.name .. ": 2\nTime: 3 hours\n" .. drugs.alchemyText .. " Required: 150\nTP: " .. tp .. ""
		end

		drugs.ok.widget.state = 1
		drugs.ok.disabled = false

		menu:updateLayout()
	end
end


return drugs