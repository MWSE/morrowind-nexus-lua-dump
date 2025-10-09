local config = require("companionLeveler.config")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local tables = require("companionLeveler.tables")
local func = require("companionLeveler.functions.common")


local rez = {}


function rez.createWindow(ref, type)
	--Initialize IDs
	rez.id_menu = tes3ui.registerID("kl_rez_menu")
	rez.id_pane = tes3ui.registerID("kl_rez_pane")
	rez.id_ok = tes3ui.registerID("kl_rez_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("Resurrect menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")
	local modData = func.getModData(ref)

	rez.requirement = false
	rez.tp = modData.tp_max
	rez.changes = 0

	if type == "spectral" then
		rez.requirement = true

		rez.tp = math.round(rez.tp / 5)
		if rez.tp < 5 then
			rez.tp = 5
		end

		rez.changes = -3
	end

	-- Create window and frame
	local menu = tes3ui.createMenu { id = rez.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_rez" }
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
	title_block:createLabel { text = "Resurrect which corpse?" }

	-- TP Bar
	rez.tp_bar = tp_block:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = rez.id_tp_bar })
	func.configureBar(rez.tp_bar, "small", "purple")
	rez.tp_bar.borderLeft = 155

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_rez" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- Pane Border
	local border = pane_block:createThinBorder { id = "kl_border_rez" }
	border.positionX = 4
	border.positionY = -4
	border.width = 210
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4

	-- Material Border
	local border2 = pane_block:createThinBorder { id = "kl_border2_rez" }
	border2.positionX = 202
	border2.positionY = 0
	border2.width = 308
	border2.height = 170
	border2.paddingAllSides = 4
	border2.wrapText = true
	border2.flowDirection = tes3.flowDirection.topToBottom

	----Populate-----------------------------------------------------------------------------------------------------

	--Materials
	local mTitle = border2:createLabel { text = "Requirements", id = "kl_rez_mTitle" }
	mTitle.wrapText = true
	mTitle.justifyText = tes3.justifyText.center
	mTitle.borderBottom = 20

	local mats = border2:createLabel { text = "", id = "kl_rez_mats_0"}
	mats.wrapText = true
	mats.justifyText = tes3.justifyText.center

	rez.mats = mats

	--Pane
	local pane = border:createVerticalScrollPane { id = rez.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	--Populate Pane
	rez.total = 0

	for mobileActor in tes3.iterate(tes3.worldController.allMobileActors) do
		if (mobileActor.cell == tes3.getPlayerCell() and mobileActor.isDead) then
			local pos = mobileActor.reference.position
			local dist = pos:distance(tes3.player.position)
			log:debug("" .. mobileActor.reference.object.name .. "'s distance: " .. dist .. "")

			if dist < 750 then
				rez.total = rez.total + 1

				local a = pane:createTextSelect { text = "" .. mobileActor.reference.object.name .. "", id = "kl_rez_btn_" .. rez.total .. ""}
				local lvl = mobileActor.reference.object.level
				if func.checkModData(mobileActor.reference) == true then
					local tempModData = func.getModData(mobileActor.reference)
					lvl = tempModData.level
				end
				local chg = 0
				local req
				local tp = rez.tp

				if type == "spectral" then
					local mod = math.round(lvl / 5)
					chg = rez.changes - mod
					if chg < -20 then
						chg = -20
					end

					if lvl < 10 then
						req = 50
					else
						req = 75
					end

					tp = tp + math.round(lvl / 2)
				end

				a:register("mouseClick", function(e) rez.onSelect(a, mobileActor.reference, chg, lvl, tp, req, mobileActor.reference.object.id) end)
			end
		end
	end

	--Text Block
	local text_block = menu:createBlock { id = "text_block_rez" }
	text_block.width = 490
	text_block.height = 175
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local base_block = text_block:createBlock {}
	base_block.width = 175
	base_block.height = 175
	base_block.borderAllSides = 4
	base_block.flowDirection = "top_to_bottom"

	local chg_block = text_block:createBlock {}
	chg_block.width = 175
	chg_block.height = 175
	chg_block.borderAllSides = 4
	chg_block.flowDirection = "top_to_bottom"
	chg_block.wrapText = true

	local total_block = text_block:createBlock {}
	total_block.width = 175
	total_block.height = 175
	total_block.borderAllSides = 4
	total_block.flowDirection = "top_to_bottom"
	total_block.wrapText = true

	--Base Statistics
	local base_title = base_block:createLabel({ text = "Base Statistics:", id = "kl_att_rez" })
	base_title.color = tables.colors["white"]
	rez.base_atts = {}

	for i = 0, 7 do
		rez.base_atts[i] = base_block:createLabel({ text = "" .. tables.capitalization[i] .. ": ", id = "kl_rez_att_" .. i .. "" })
	end

	--Changes
	local chg_title = chg_block:createLabel({ text = "Changes:" })
	chg_title.color = tables.colors["white"]
	rez.att_chg = {}

	for i = 0, 7 do
		rez.att_chg[i] = chg_block:createLabel { text = "" .. tables.capitalization[i] .. ": ", id = "kl_beast_att_chg_" .. i .. "" }
	end

	func.clTooltip(chg_title, "att:level")

	--Totals
	local total_title = total_block:createLabel({ text = "New Statistics:" })
	total_title.color = tables.colors["white"]
	rez.att_totals = {}

	for i = 0, 7 do
		rez.att_totals[i] = total_block:createLabel { text = "" .. tables.capitalization[i] .. ": ", id = "kl_beast_att_total_" .. i .. "" }
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
	rez.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		if rez.requirement then
			if ref.mobile.willpower.current < rez.req then
				tes3.messageBox("" .. ref.object.name .. " is not powerful enough to resurrect " .. rez.ref.object.name .. ".")
				return
			end
		end

		if modData.tp_current < rez.tp then
			tes3.messageBox("Not enough Technique Points!")
			return
		end

		if rez.id == "vivec_god" or rez.id == "almalexia" or rez.id == "Almalexia_warrior" or string.startswith(rez.id, "dagoth") or string.startswith(rez.id, "Dagoth") then
			tes3.messageBox("Some fates cannot be avoided.")
			return
		end

		--Spend TP
		modData.tp_current = modData.tp_current - rez.tp

		--Resurrect
		rez.ref.mobile:resurrect({ resetState = false })
		tes3.createVisualEffect({ object = "VFX_RestorationHit", lifespan = 3, reference = rez.ref })
		tes3.playSound({ sound = "restoration hit", reference = rez.ref })
		tes3.messageBox("" .. rez.ref.object.name .. " was resurrected!")

		--Apply Changes
		if rez.changes ~= 0 then
			local modDataTarget = func.getModData(rez.ref)

			for i = 0, 7 do
				tes3.modStatistic({ attribute = i, value = rez.changes, reference = rez.ref, limit = false })
				modDataTarget.att_gained[i + 1] = modDataTarget.att_gained[i + 1] + rez.changes
			end
			
			if rez.ref.object.objectType == tes3.objectType.creature then
				func.addAbilitiesCre(rez.ref)
			else
				func.addAbilitiesNPC(rez.ref)
			end

			func.updateIdealSheet(rez.ref)
		end


		menu:destroy()
		tes3ui.leaveMenuMode()
	end)
	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(rez.id_menu)
end

function rez.onSelect(elem, ref, chg, lvl, tp, req, id)
	local menu = tes3ui.findMenu(rez.id_menu)

	if menu then
		local att = ref.mobile.attributes

		for i = 1, rez.total do
			local btn = menu:findChild("kl_rez_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4
		rez.ref = ref
		rez.tp = tp
		rez.changes = chg
		rez.req = req
		rez.id = id

		for i = 0, 7 do
			rez.base_atts[i].text = "" .. tables.capitalization[i] .. ": " .. att[i + 1].base .. ""
			rez.att_chg[i].text = "" .. tables.capitalization[i] .. ": " .. chg .. ""
			rez.att_totals[i].text = "" .. tables.capitalization[i] .. ": " .. att[i + 1].base + chg .. ""
		end

		rez.mats.text = "" .. ref.object.name .. ": Level " .. lvl .."\n\nTP Required: " .. tp .. "\n\nWillpower Required: " .. req .. ""

		rez.ok.widget.state = 1
		rez.ok.disabled = false

		menu:updateLayout()
	end
end


return rez