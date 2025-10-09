local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local tables = require("companionLeveler.tables")
local func = require("companionLeveler.functions.common")


local steal = {}


function steal.createWindow(ref)
	--Initialize IDs
	steal.id_menu = tes3ui.registerID("kl_steal_menu")
	steal.id_pane = tes3ui.registerID("kl_steal_pane")
	steal.id_pane2 = tes3ui.registerID("kl_steal_pane2")
	steal.id_ok = tes3ui.registerID("kl_steal_ok")
	steal.id_tp_bar = tes3ui.registerID("kl_steal_tp_bar")
	steal.id_fat_bar = tes3ui.registerID("kl_steal_fat_bar")

	log = logger.getLogger("Companion Leveler")
	log:debug("Steal menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")
	local modData = func.getModData(ref)

	steal.ref = ref
	steal.obj_choices = 0
	steal.target = nil
	steal.agility = ref.mobile.agility
	steal.fatigueText = tes3.findGMST(tes3.gmst.sFatigue).value
	steal.agilityText = tes3.findGMST(tes3.gmst.sAttributeAgility).value
	steal.valueText = tes3.findGMST(tes3.gmst.sValue).value
	steal.weightText = tes3.findGMST(tes3.gmst.sWeight).value

	-- Create Menu
	local menu = tes3ui.createMenu { id = steal.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_steal" }
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
	title_block:createLabel { text = "Choose a target." }

	-- Fatigue Bar
	steal.fat_bar = tp_block:createFillBar({ current = ref.mobile.fatigue.current, max = ref.mobile.fatigue.base, id = steal.id_fat_bar })
	func.configureBar(steal.fat_bar, "small", "green")
	steal.fat_bar.borderLeft = 20

	-- TP Bar
	steal.tp_bar = tp_block:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = steal.id_tp_bar })
	func.configureBar(steal.tp_bar, "small", "purple")
	steal.tp_bar.borderLeft = 5

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_steal" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- steal Border
	local border = pane_block:createThinBorder { id = "kl_border_steal" }
	border.positionX = 4
	border.positionY = -4
	border.width = 300
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4
	border.borderLeft = 126

	--Calculate Bonuses
	steal.modifier = steal.agility.current
	if steal.modifier > 200 then
		steal.modifier = 200
	end

	steal.fatReduction = math.round(steal.modifier * 0.33)


	----Populate-----------------------------------------------------------------------------------------------------

	--Panes
	local pane = border:createVerticalScrollPane { id = steal.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	--Populate Pane

	--OBJ Choices
	for refe in tes3.getPlayerCell():iterateReferences({ tes3.objectType.alchemy, tes3.objectType.ammunition, tes3.objectType.book, tes3.objectType.clothing, tes3.objectType.ingredient, tes3.objectType.lockpick, tes3.objectType.probe, tes3.objectType.repairItem }) do
		if refe.cell == tes3.getPlayerCell() and refe.disabled == false then
			local pos = refe.position
			local dist = pos:distance(tes3.player.position)
			log:debug("" .. refe.object.name .. "'s distance: " .. dist .. "")

			if dist < (300 + steal.modifier) and refe.object.name ~= ""and refe.object.weight and refe.object.weight < 30 then
				steal.obj_choices = steal.obj_choices + 1

				local a = pane:createTextSelect { text = "" .. refe.object.name .. "", id = "kl_steal_obj_btn_" .. steal.obj_choices .. ""}

				a:register("help", function(e)
					local tooltip = tes3ui.createTooltipMenu { item = refe.object }

					local contentElement = tooltip:getContentElement()
					contentElement.paddingAllSides = 12
					contentElement.childAlignX = 0.5
					contentElement.childAlignY = 0.5
				end)
				a:register("mouseClick", function(e) steal.onSelectTarget(a, refe) end)
			end
		end
	end

	--Text Block
	local text_block = menu:createBlock { id = "text_block_steal" }
	text_block.width = 490
	text_block.height = 112
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local base_block = text_block:createBlock {}
	base_block.width = 175
	base_block.height = 112
	base_block.borderAllSides = 4
	base_block.flowDirection = "top_to_bottom"

	local lock_block = text_block:createBlock {}
	lock_block.width = 175
	lock_block.height = 112
	lock_block.borderAllSides = 4
	lock_block.flowDirection = "top_to_bottom"
	lock_block.wrapText = true

	local total_block = text_block:createBlock {}
	total_block.width = 175
	total_block.height = 112
	total_block.borderAllSides = 4
	total_block.flowDirection = "top_to_bottom"
	total_block.wrapText = true

	--Fatigue
	local base_title = base_block:createLabel({ text = "" .. steal.fatigueText .. " Cost:", id = "kl_base_sabo" })
	base_title.color = tables.colors["white"]
	steal.base_fat = base_block:createLabel({ text = "Base: ", id = "kl_sabo_fat" })
	--Reductions
	local reduce_label = base_block:createLabel { text = "Reduction: " .. steal.fatReduction .. "%", id = "kl_sabo_fat_e" }
	func.clTooltip(reduce_label, "att:2")
	--Totals
	steal.total_fat = base_block:createLabel { text = "Total Cost: ", id = "kl_sabo_fat_t" }

	--Lock Level/trap
	local lock_title = lock_block:createLabel({ text = "Target: " })
	lock_title.color = tables.colors["white"]
	steal.weight_label = lock_block:createLabel { text = "" .. steal.weightText .. ": ", id = "kl_steal_weight_label" }
	steal.value_label = lock_block:createLabel { text = "" .. steal.valueText .. ": ", id = "kl_steal_value_label" }

	--Chance
	local chance_title = total_block:createLabel({ text = "Success Chance:" })
	chance_title.color = tables.colors["white"]
	func.clTooltip(chance_title, "att:2")
	steal.chance_label = total_block:createLabel { text = "", id = "kl_steal_chance" }


	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 10

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	steal.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		if not func.spendTP(ref, 1) then return end

		if ref.mobile.fatigue.current < steal.fatCost then
			tes3.messageBox("Not enough " .. steal.fatigueText .. "!")
			return
		end

		--Reset
		menu:destroy()
		tes3ui.leaveMenuMode()

		--Spend Fatigue
		tes3.modStatistic({ reference = ref, name = "fatigue", current = (steal.fatCost * -1) })

		--Roll
		local owned = tes3.getOwner({ reference = steal.target })

		if owned and math.random(0, 99) > steal.chance then
			--Fail
			tes3.messageBox("" .. ref.object.name .. " failed to find an opening!")
		else
			--Success
			tes3.addItem({ reference = tes3.player, item = steal.target.object, showMessage = true })
			steal.target:delete()
		end

		steal.createWindow(ref)
	end)
	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(steal.id_menu)
end

function steal.onSelectTarget(elem, ref)
	local menu = tes3ui.findMenu(steal.id_menu)

	if menu then
		for i = 1, steal.obj_choices do
			local btn = menu:findChild("kl_steal_obj_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4

		steal.target = ref
		steal.value = ref.object.value
		steal.weight = ref.object.weight

		--Trap Label
		steal.value_label.text = "" .. steal.valueText .. ": " .. steal.value .. ""

		local owned = tes3.getOwner({ reference = ref })

		steal.chance = math.round(70 - (((steal.value / 3) + steal.weight * 3) - steal.modifier))
		if not owned then
			steal.chance = 100
		end
		steal.chance_label.text = "" .. steal.chance .. "%"
		steal.weight_label.text = "" .. steal.weightText .. ": " .. steal.weight .. ""

		steal.fatCost = math.round((steal.weight * 8.5) * (1 - (steal.fatReduction * 0.01)))
		if steal.fatCost < 1 then
			steal.fatCost = 1
		end

		steal.base_fat.text = "Base: " .. math.round(steal.weight * 7.5) .. ""
		steal.total_fat.text = "Total Cost: " .. steal.fatCost .. ""

		if steal.target ~= nil then
			steal.ok.widget.state = 1
			steal.ok.disabled = false
		end

		menu:updateLayout()
	end
end


return steal