local logger = require("logging.logger")
local config = require("companionLeveler.config")
local log = logger.getLogger("Companion Leveler")
local tables = require("companionLeveler.tables")
local func = require("companionLeveler.functions.common")


local beast = {}


function beast.createWindow(ref)
	--Initialize IDs
	beast.id_menu = tes3ui.registerID("kl_beast_menu")
	beast.id_pane = tes3ui.registerID("kl_beast_pane")
	beast.id_pane2 = tes3ui.registerID("kl_beast_pane2")
	beast.id_ok = tes3ui.registerID("kl_beast_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("Beast menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")

	local personality = ref.mobile.attributes[7] --reduces time spent training
	local willpower = ref.mobile.attributes[3] --allows training higher level attributes
	local modData = func.getModData(ref)

	beast.ratio = 7
	beast.amount = 1
	beast.efficiency = math.round(personality.current * 0.5)

	if beast.efficiency > 75 then
		beast.efficiency = 75
	end

	-- Create window and frame
	local menu = tes3ui.createMenu { id = beast.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_beast" }
	head_block.autoWidth = true
	head_block.autoHeight = true
	head_block.borderBottom = 5

	--Title/TP Bar Blocks
	local title_block = head_block:createBlock{}
	title_block.width = 275
	title_block.autoHeight = true

	local tp_block = head_block:createBlock{}
	tp_block.width = 275
	tp_block.autoHeight = true

	-- Title
	title_block:createLabel { text = "Train which creature?" }

	-- TP Bar
	beast.tp_bar = tp_block:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = beast.id_tp_bar })
	func.configureBar(beast.tp_bar, "small", "purple")
	beast.tp_bar.borderLeft = 155

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_beast" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- Beast Border
	local border = pane_block:createThinBorder { id = "kl_border_beast" }
	border.positionX = 4
	border.positionY = -4
	border.width = 267
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4

	-- Attribute Border
	local border2 = pane_block:createThinBorder { id = "kl_border2_beast" }
	border2.positionX = 202
	border2.positionY = 0
	border2.width = 267
	border2.height = 160
	border2.paddingAllSides = 4
	border2.borderAllSides = 4


	----Populate-----------------------------------------------------------------------------------------------------

	--Panes
	local pane = border:createVerticalScrollPane { id = beast.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	local pane2 = border2:createVerticalScrollPane { id = beast.id_pane2 }
	pane2.height = 148
	pane2.width = 210
	pane2.widget.scrollbarVisible = true

	--Populate Panes
	beast.total = 0

	for mobileActor in tes3.iterate(tes3.worldController.allMobileActors) do
		if (mobileActor.cell == tes3.getPlayerCell() and func.validCompanionCheck(mobileActor) and mobileActor.reference.object.objectType == tes3.objectType.creature) then
			local pos = mobileActor.reference.position
			local dist = pos:distance(tes3.player.position)
			log:debug("" .. mobileActor.reference.object.name .. "'s distance: " .. dist .. "")

			if dist < 1000 then
				beast.total = beast.total + 1

				local a = pane:createTextSelect { text = "" .. mobileActor.reference.object.name .. "", id = "kl_beast_btn_" .. beast.total .. ""}

				a:register("mouseClick", function(e) beast.onSelect(a, mobileActor.reference) end)
			end
		end
	end

	for i = 0, 7 do
		local a = pane2:createTextSelect { text = tables.capitalization[i],  id = "kl_beast_btn_" .. tables.capitalization[i] .. ""}
		a.widget.state = tes3.uiState.disabled
		a.disabled = true
		a:register("mouseClick", function(e) beast.onSelect2(a) end)
	end


	--Text Block
	local text_block = menu:createBlock { id = "text_block_beast" }
	text_block.autoWidth = true
	text_block.autoHeight = true
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local att_block = text_block:createBlock {}
	att_block.width = 174
	att_block.autoHeight = true
	att_block.borderAllSides = 4
	att_block.flowDirection = "top_to_bottom"

	local cost_block = text_block:createBlock {}
	cost_block.width = 174
	cost_block.autoHeight = true
	cost_block.borderAllSides = 4
	cost_block.flowDirection = "top_to_bottom"

	local time_block = text_block:createBlock {}
	time_block.width = 157
	time_block.autoHeight = true
	time_block.borderAllSides = 4
	time_block.flowDirection = "top_to_bottom"

	--Base Statistics
	local att_title = att_block:createLabel({ text = "Current Attributes:", id = "kl_att_beast" })
	att_title.color = tables.colors["white"]
	beast.base_atts = {}

	for i = 0, 7 do
		beast.base_atts[i] = att_block:createLabel({ text = "" .. tables.capitalization[i] .. ": ", id = "kl_beast_att_" .. i .. "" })
	end

	--TP Costs
	local cost_title = cost_block:createLabel({ text = "TP Costs:" })
	cost_title.color = tables.colors["white"]
	beast.tp_costs = {}

	for i = 0, 7 do
		beast.tp_costs[i] = cost_block:createLabel { text = "" .. tables.capitalization[i] .. ": ", id = "kl_beast_tp_cost_" .. i .. "" }
	end

	cost_block:createLabel { text = "" }
	beast.will_req = cost_block:createLabel { text = "Willpower Required: ", id = "kl_beast_will_req" }
	beast.per_bonus = cost_block:createLabel { text = "Time Efficiency: " .. beast.efficiency .. "%" , id = "kl_beast_per_bonus" }
	func.clTooltip(beast.per_bonus, "att:6")
	beast.sessions = cost_block:createLabel { text = "Session Limit: " .. modData.sessions_current .. "/" .. modData.sessions_max .. "" }

	--Time Costs
	local time_title = time_block:createLabel({ text = "Time Costs:" })
	time_title.color = tables.colors["white"]
	beast.time_costs = {}

	for i = 0, 7 do
		beast.time_costs[i] = time_block:createLabel { text = "" .. tables.capitalization[i] .. ": ", id = "kl_beast_time_cost_" .. i .. "" }
	end


	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 10

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	beast.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		local creModData = func.getModData(beast.ref)

		if willpower.current < beast.req then
			func.clMessageBox("" .. ref.object.name .. " is not skilled enough to train " .. beast.ref.object.name .. "'s " .. beast.attName ..".")
			return
		end

		if modData.tp_current < beast.tp then
			func.clMessageBox("Not enough Technique Points!")
			return
		end

		if modData.sessions_current >= modData.sessions_max then
			func.clMessageBox("" .. ref.object.name .. " can't train any more pupils until their next level.")
			return
		end

		if beast.amount == 0 then
			func.clMessageBox("" .. tes3.findGMST(tes3.gmst.sServiceTrainingWords).value .. "")
			return
		end

		--Spend TP
		modData.tp_current = modData.tp_current - beast.tp

		--Increase Sessions
		modData.sessions_current = modData.sessions_current + 1

		--Train Attribute
		tes3.modStatistic{ reference = beast.ref, attribute = beast.att, value = 1}
		creModData.att_gained[beast.att + 1] = creModData.att_gained[beast.att + 1] + 1
		tes3.playSound({ soundPath = "companionLeveler\\levelUP2.wav" })
		func.clMessageBox("" .. ref.object.name .. " trained " .. beast.ref.object.name .. "'s " .. beast.attName .. " to " .. beast.ref.mobile.attributes[beast.att + 1].base .. "!")

		--Pass Time
		local gameHour = tes3.getGlobal('GameHour')

		gameHour = gameHour + beast.time
		tes3.setGlobal('GameHour', gameHour)

		--Reset
		menu:destroy()
		tes3ui.leaveMenuMode()
		timer.delayOneFrame(function()
			beast.createWindow(ref)
		end)
	end)
	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(beast.id_menu)
end

function beast.onSelect(elem, ref)
	local menu = tes3ui.findMenu(beast.id_menu)

	if menu then
		local att = ref.mobile.attributes
		local modData = func.getModData(ref)


		for i = 1, beast.total do
			local btn = menu:findChild("kl_beast_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		for i = 0, 7 do
			local btn = menu:findChild("kl_beast_btn_" .. tables.capitalization[i] .. "")
			if btn and btn.widget.state == 4 then
				beast.tp = math.round((att[i + 1].base / beast.ratio) + (modData.level / 4) + 1)
				beast.req = math.round((att[i + 1].base / 2) + (modData.level * 2) + 10)
				beast.attName = "" .. tables.capitalization[i] .. ""
				beast.att = i
				beast.time = math.round(((att[i + 1].base / beast.ratio) + 1) * (1 - (beast.efficiency / 100)))
				beast.will_req.text = "Willpower Required: " .. math.round((att[i + 1].base / 2) + (modData.level * 2) + 10) .. ""
				break
			else
				btn.widget.state = 1
				btn.disabled = false
			end
		end

		elem.widget.state = 4
		beast.ref = ref


		--Base Attributes
		for i = 0, 7 do
			beast.base_atts[i].text = "" .. tables.capitalization[i] .. ": " .. att[i + 1].base .. ""
			beast.tp_costs[i].text = "" .. tables.capitalization[i] .. ": " .. math.round((att[i + 1].base / beast.ratio) + (modData.level / 4) + 1) .. " TP"
			beast.time_costs[i].text = "" .. tables.capitalization[i] .. ": " .. math.round(((att[i + 1].base / beast.ratio) + 1) * (1 - (beast.efficiency / 100))) .. " hours"
		end

		menu:updateLayout()
	end
end

function beast.onSelect2(elem)
	local menu = tes3ui.findMenu(beast.id_menu)

	if menu then
		local att = beast.ref.mobile.attributes
		local modData = func.getModData(beast.ref)

		for i = 0, 7 do
			local btn = menu:findChild("kl_beast_btn_" .. tables.capitalization[i] .. "")
			btn.widget.state = 1
		end

		elem.widget.state = 4

		for i = 0, 7 do
			local btn = menu:findChild("kl_beast_btn_" .. tables.capitalization[i] .. "")
			if btn and btn.widget.state == 4 then
				if config.aboveMaxAtt == false then
					if att[i + 1].base >= 100 then
						beast.amount = 0
					else
						beast.amount = 1
					end
				end
				beast.tp = math.round((att[i + 1].base / beast.ratio) + (modData.level / 4) + 1)
				beast.req = math.round((att[i + 1].base / 2) + (modData.level * 2) + 10)
				beast.attName = "" .. tables.capitalization[i] .. ""
				beast.att = i
				beast.time = math.round(((att[i + 1].base / beast.ratio) + 1) * (1 - (beast.efficiency / 100)))
				beast.will_req.text = "Willpower Required: " .. math.round((att[i + 1].base / 2) + (modData.level * 2) + 10) .. ""
				break
			end
		end


		beast.ok.widget.state = 1
		beast.ok.disabled = false

		menu:updateLayout()
	end
end

return beast