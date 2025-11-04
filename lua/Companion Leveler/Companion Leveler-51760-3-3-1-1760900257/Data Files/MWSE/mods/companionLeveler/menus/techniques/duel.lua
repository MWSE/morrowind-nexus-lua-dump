local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local tables = require("companionLeveler.tables")
local func = require("companionLeveler.functions.common")


local duel = {}


function duel.createWindow(ref)
	--Initialize IDs
	duel.id_menu = tes3ui.registerID("kl_duel_menu")
	duel.id_pane = tes3ui.registerID("kl_duel_pane")
	duel.id_pane2 = tes3ui.registerID("kl_duel_pane2")
	duel.id_ok = tes3ui.registerID("kl_duel_ok")
	duel.id_tp_bar = tes3ui.registerID("kl_duel_tp_bar")
	duel.id_fat_bar = tes3ui.registerID("kl_duel_fat_bar")

	log = logger.getLogger("Companion Leveler")
	log:debug("Duel menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")
	local modData = func.getModData(ref)

	duel.ref = ref
	duel.obj_choices = 0
	duel.target = nil
	duel.speech = ref.mobile:getSkillStatistic(25)
	duel.willText = tes3.findGMST(tes3.gmst.sAttributeWillpower).value
	duel.speechText = tes3.findGMST(tes3.gmst.sSkillSpeechcraft).value
	duel.levelText = tes3.findGMST(tes3.gmst.sLevel).value
	duel.classText = tes3.findGMST(tes3.gmst.sClass).value

	-- Create Menu
	local menu = tes3ui.createMenu { id = duel.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_duel" }
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
	title_block:createLabel { text = "Choose an opponent. TP Cost: 1" }

	-- TP Bar
	duel.tp_bar = tp_block:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = duel.id_tp_bar })
	func.configureBar(duel.tp_bar, "small", "purple")
	duel.tp_bar.borderLeft = 154

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_duel" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- duel Border
	local border = pane_block:createThinBorder { id = "kl_border_duel" }
	border.positionX = 4
	border.positionY = -4
	border.width = 300
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4
	border.borderLeft = 126

	--Calculate Bonuses
	duel.modifier = duel.speech.current
	if duel.modifier > 200 then
		duel.modifier = 200
	end


	----Populate-----------------------------------------------------------------------------------------------------

	--Panes
	local pane = border:createVerticalScrollPane { id = duel.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	--Populate Pane

	--OBJ Choices
	for refe in tes3.getPlayerCell():iterateReferences({ tes3.objectType.npc }) do
		if refe.cell == tes3.getPlayerCell() and refe.disabled == false then
			local pos = refe.position
			local dist = pos:distance(tes3.player.position)
			log:debug("" .. refe.object.name .. "'s distance: " .. dist .. "")

			if dist < 400  and refe.object.name ~= "" and not func.validCompanionCheck(refe.mobile) then
				duel.obj_choices = duel.obj_choices + 1

				local a = pane:createTextSelect { text = "" .. refe.object.name .. "", id = "kl_duel_obj_btn_" .. duel.obj_choices .. ""}

				a:register("mouseClick", function(e) duel.onSelectTarget(a, refe) end)
			end
		end
	end

	--Text Block
	local text_block = menu:createBlock { id = "text_block_duel" }
	text_block.width = 490
	text_block.height = 112
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local base_block = text_block:createBlock {}
	base_block.width = 105
	base_block.height = 112
	base_block.borderAllSides = 4
	base_block.flowDirection = "top_to_bottom"

	local target_block = text_block:createBlock {}
	target_block.width = 175
	target_block.height = 112
	target_block.borderAllSides = 4
	target_block.flowDirection = "top_to_bottom"
	target_block.wrapText = true

	local chance_block = text_block:createBlock {}
	chance_block.width = 175
	chance_block.height = 112
	chance_block.borderAllSides = 4
	chance_block.flowDirection = "top_to_bottom"
	chance_block.wrapText = true

	--Target Block
	local target_title = target_block:createLabel({ text = "Target: " })
	target_title.color = tables.colors["white"]
	duel.level_label = target_block:createLabel { text = "" .. duel.levelText .. ": ", id = "kl_duel_level_label" }
	duel.class_label = target_block:createLabel { text = "" .. duel.classText .. ": ", id = "kl_duel_class_label" }
	duel.will_label = target_block:createLabel { text = "" .. duel.willText .. ": ", id = "kl_duel_will_label" }

	--Chance
	local chance_title = chance_block:createLabel({ text = "Success Chance:" })
	chance_title.color = tables.colors["white"]
	func.clTooltip(chance_title, "skill:25")
	duel.chance_label = chance_block:createLabel { text = "", id = "kl_duel_chance" }


	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 10

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	duel.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		if not func.spendTP(ref, 1) then return end

		--Roll
		if math.random(0, 99) > duel.chance then
			--Fail
			func.clMessageBox("" .. ref.object.name .. " failed to convince " .. duel.target.object.name .. "!")
			menu:destroy()
			duel.createWindow(duel.ref)
		else
			--Success
			--Reset
			menu:destroy()
			tes3ui.leaveMenuMode()

			duel.target.mobile:startCombat(duel.ref.mobile)
			duel.ref.mobile:startCombat(duel.target.mobile)
		end
	end)
	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(duel.id_menu)
end

function duel.onSelectTarget(elem, ref)
	local menu = tes3ui.findMenu(duel.id_menu)

	if menu then
		for i = 1, duel.obj_choices do
			local btn = menu:findChild("kl_duel_obj_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4

		duel.target = ref
		duel.level = ref.object.level
		duel.class = ref.object.class
		duel.will = ref.mobile.willpower.current

		--Trap Label
		duel.class_label.text = "" .. duel.levelText .. ": " .. duel.level .. ""

		local classBonus = 0
		if duel.class.id == "Commoner" or duel.class.id == "Pauper" or duel.class.id == "Thief" or duel.class.id == "Clothier" or duel.class.id == "Pawnbroker" or duel.class.id == "Merchant" or duel.class.id == "King" or duel.class.id == "Pilgrim" or duel.class.id == "Slave" then
			classBonus = -10
		elseif duel.class.id == "Knight" or duel.class.id == "Noble" or duel.class.id == "Warrior" or duel.class.id == "Champion" or duel.class.id == "Buoyant Armiger" or duel.class.id == duel.ref.object.class.id then
			classBonus = 10
		elseif duel.class.id == "Guard" or duel.class.id == "Priest" or duel.class.id == "Healer" or duel.class.id == "Ordinator" or duel.class.id == "Publican" then
			classBonus = -50
		elseif duel.class.id == "Duelist" or duel.class.id == "Gladiator" or duel.class.id == "Barbarian" or duel.class.id == "Reaver" then
			classBonus = 20
		elseif duel.class.id == "Bard" or duel.class.id == "Crusader" or duel.class.id == "Paladin" or duel.class.id == "Rogue" then
			classBonus = 5
		end
		local levelBonus = duel.level - duel.ref.object.level
		local chance = math.round(((duel.modifier * 0.85) + classBonus + levelBonus) - (duel.will * 0.9))
		duel.chance = chance

		duel.chance_label.text = "" .. duel.chance .. "%"
		duel.level_label.text = "" .. duel.classText .. ": " .. duel.class.name .. ""
		if classBonus < 0 then
			duel.level_label.color = tables.colors["red"]
		elseif classBonus > 0 then
			duel.level_label.color = tables.colors["green"]
		else
			duel.level_label.color = tables.colors["default_font"]
		end
		duel.will_label.text = "" .. duel.willText .. ": " .. duel.will .. ""

		if duel.target ~= nil then
			duel.ok.widget.state = 1
			duel.ok.disabled = false
		end

		menu:updateLayout()
	end
end


return duel