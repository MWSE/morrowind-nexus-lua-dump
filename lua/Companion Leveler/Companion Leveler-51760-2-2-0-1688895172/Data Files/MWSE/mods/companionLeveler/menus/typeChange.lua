local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")
local growth = require("companionLeveler.menus.growthSettings")


local typeModule = {}


function typeModule.typeChange(reference)
	--Initialize IDs
	typeModule.id_menu = tes3ui.registerID("kl_type_menu")
	typeModule.id_pane = tes3ui.registerID("kl_type_pane")
	typeModule.id_ok = tes3ui.registerID("kl_type_ok")
	typeModule.id_growth = tes3ui.registerID("kl_type_growth_btn")
	typeModule.id_root = tes3ui.registerID("kl_type_root")
	log = logger.getLogger("Companion Leveler")
	log:debug("Type menu initialized.")

	local root = require("companionLeveler.menus.root")

	if (reference) then
		typeModule.reference = reference
	end

	log:debug("Type menu triggered.")

	-- Create window and frame
	local menu = tes3ui.createMenu { id = typeModule.id_menu, fixedFrame = true }

	-- Create layout
	local name = reference.object.name
	local modData = func.getModData(reference)
	local input_label = menu:createLabel { text = "Select " .. name .. "'s Type:" }
	input_label.borderBottom = 5

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_type" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- Pane Border
	local border = pane_block:createThinBorder { id = "kl_border_type" }
	border.positionX = 4
	border.positionY = -4
	border.width = 210
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4

	-- Flavor Text Border
	local border2 = pane_block:createThinBorder { id = "kl_border2_type" }
	border2.positionX = 202
	border2.positionY = 0
	border2.width = 308
	border2.height = 170
	border2.paddingAllSides = 4
	border2.wrapText = true

	----Populate-----------------------------------------------------------------------------------------------------
	local mAtt1 = 0
	local mAtt2 = 0
	local mSkillType = ""
	local desc = ""
	for i = 1, #tables.typeTable do
		if tables.typeTable[i] == modData.type then
			--Stats
			mAtt1 = tables.typeStat1[i]
			mAtt2 = tables.typeStat2[i]

			--Descriptions
			mSkillType = tables.typeDesc1[i]
			desc = tables.typeDesc2[i]
		end
	end

	border2:createLabel { text = desc, id = "kl_type_desc_2" }

	--Pane
	local pane = border:createVerticalScrollPane { id = typeModule.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	--Populate Pane
	local deftype = func.determineDefault(reference)
	local a = pane:createTextSelect { text = "Default: " .. deftype .. "", id = "tChangeB_D" }
	a:register("mouseClick", function(e) typeModule.defSelect() end)

	pane:createDivider()

	for i = 1, #tables.typeTable do
		local b = pane:createTextSelect { text = tables.typeTable[i], id = "tChangeB_" .. i .. "" }
		b:register("mouseClick", function() typeModule.onSelect(i) end)
	end

	--Text Block
	local text_block = menu:createBlock { id = "text_block_type" }
	text_block.width = 490
	text_block.height = 112
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local spec_block = text_block:createBlock {}
	spec_block.width = 175
	spec_block.height = 115
	spec_block.borderAllSides = 4
	spec_block.flowDirection = "top_to_bottom"

	local major_block = text_block:createBlock {}
	major_block.width = 270
	major_block.height = 128
	major_block.borderAllSides = 4
	major_block.flowDirection = "top_to_bottom"
	major_block.wrapText = true

	--Attribute Text
	local kl_att = spec_block:createLabel({ text = "Favored Attributes:", id = "kl_att_type" })
	kl_att.color = { 1.0, 1.0, 1.0 }
	spec_block:createLabel({ text = "" .. tables.capitalization[mAtt1] .. "", id = "kl_att1_type" })
	spec_block:createLabel({ text = "" .. tables.capitalization[mAtt2] .. "", id = "kl_att2_type" })
	local extraAtt = spec_block:createLabel({ text = "", id = "kl_att3_type" })
	if modData.type == "Draconic" then
		extraAtt.text = "Personality"
	end

	--Description Text
	local kl_major = major_block:createLabel({ text = "Growth Type:" })
	kl_major.color = { 1.0, 1.0, 1.0 }
	major_block:createLabel { text = mSkillType, id = "kl_type_desc" }

	--Button Block
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 1.0

	local button_root = button_block:createButton { id = typeModule.id_root, text = "Main Menu" }
	button_root.borderRight = 115

	local button_growth = button_block:createButton { id = typeModule.id_growth, text = "Growth Settings" }
	button_growth.borderRight = 116

	local button_ok = button_block:createButton { id = typeModule.id_ok, text = tes3.findGMST("sOK").value }

	-- Events
	menu:register(tes3.uiEvent.keyEnter, typeModule.onOK)
	button_ok:register(tes3.uiEvent.mouseClick, typeModule.onOK)
	button_growth:register("mouseClick", function() growth.createWindow(reference) end)
	button_root:register("mouseClick", function() menu:destroy() root.createWindow(reference) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(typeModule.id_menu)
end

function typeModule.onOK()
	local menu = tes3ui.findMenu(typeModule.id_menu)
	local modData = func.getModData(typeModule.reference)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
		log:info("" .. typeModule.reference.object.name .. " changed to " .. modData.type .. ".")
		tes3.messageBox { message = "" .. typeModule.reference.object.name .. " changed to " .. modData.type .. "." }
	end
end

function typeModule.onSelect(i)
	local menu = tes3ui.findMenu(typeModule.id_menu)

	if (menu) then
		local modData = func.getModData(typeModule.reference)
		local id = menu:findChild("tChangeB_" .. i .. "")

		modData.type = id.text

		--States
		local idDef = menu:findChild("tChangeB_D")
		if idDef.widget.state == 4 then
			idDef.widget.state = 1
		end

		for n = 1, #tables.typeTable do
			local id2 = menu:findChild("tChangeB_" .. n .. "")
			if id2.widget.state == 4 then
				id2.widget.state = 1
			end
		end

		id.widget.state = 4

		--Change Text
		local text4 = menu:findChild("kl_type_desc")
		text4.text = tables.typeDesc1[i]

		local text = menu:findChild("kl_type_desc_2")
		text.text = tables.typeDesc2[i]

		local text2 = menu:findChild("kl_att1_type")
		text2.text = tables.capitalization[tables.typeStat1[i]]

		local text3 = menu:findChild("kl_att2_type")
		text3.text = tables.capitalization[tables.typeStat2[i]]

		local text5 = menu:findChild("kl_att3_type")
		text5.text = ""
		if i == 11 then
			text5.text = "Personality"
		end


		log:debug("" .. modData.type .. " changed to " .. tables.typeTable[i] .. ".")
		menu:updateLayout()
	end
end

function typeModule.defSelect()
	local menu = tes3ui.findMenu(typeModule.id_menu)

	if (menu) then
		local defType = func.determineDefault(typeModule.reference)
		local modData = func.getModData(typeModule.reference)

		modData.type = defType

		--States
		local id = menu:findChild("tChangeB_D")
		id.widget.state = 4

		for n = 1, #tables.typeTable do
			local id2 = menu:findChild("tChangeB_" .. n .. "")
			if id2.widget.state == 4 then
				id2.widget.state = 1
			end
		end

		--Change Text
		for i = 1, #tables.typeTable do
			if tables.typeTable[i] == defType then
				--Change Text
				local text4 = menu:findChild("kl_type_desc")
				text4.text = tables.typeDesc1[i]

				local text = menu:findChild("kl_type_desc_2")
				text.text = tables.typeDesc2[i]

				local text2 = menu:findChild("kl_att1_type")
				text2.text = tables.capitalization[tables.typeStat1[i]]

				local text3 = menu:findChild("kl_att2_type")
				text3.text = tables.capitalization[tables.typeStat2[i]]

				local text5 = menu:findChild("kl_att3_type")
				text5.text = ""
				if i == 11 then
					text5.text = "Personality"
				end
			end
		end

		log:debug("" .. typeModule.reference.object.name .. " changed back to " .. defType .. ".")
		menu:updateLayout()
	end
end

return typeModule
