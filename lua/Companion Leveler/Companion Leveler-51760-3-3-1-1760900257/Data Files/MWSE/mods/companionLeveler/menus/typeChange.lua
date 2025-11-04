local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")
local config = require("companionLeveler.config")


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

	log = logger.getLogger("Companion Leveler")
	log:debug("Type menu initialized.")

	if (reference) then
		typeModule.reference = reference
	end

	-- Create window and frame
	local menu = tes3ui.createMenu { id = typeModule.id_menu, fixedFrame = true }
	menu.alpha = 1.0

	-- Create layout
	local name = reference.object.name
	local modData = func.getModData(reference)

	local input_label = menu:createLabel { text = "Select " .. name .. "'s Type:" }
	input_label.borderBottom = 12

	--new main block
	local block = menu:createBlock { id = "main_block" }
	block.autoHeight = true
	block.autoWidth = true
	block.flowDirection = tes3.flowDirection.leftToRight
	--pane
	local pane_block = block:createBlock { id = "kl_pane_block_t" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true
	pane_block.borderRight = 12

	local border = pane_block:createThinBorder { id = "kl_border_t" }
	border.width = 190
	border.height = 351
	border.borderRight = 12

	local right_block = block:createBlock { id = "kl_right_block_t"}
	right_block.autoWidth = true
	right_block.autoHeight = true
	right_block.flowDirection = tes3.flowDirection.topToBottom

	local img_block = right_block:createBlock { id = "kl_img_block_t" }
	img_block.autoWidth = true
	img_block.autoHeight = true
	img_block.borderRight = 17

	local desc_block = right_block:createBlock { id = "kl_desc_block_t"}

	local border2 = img_block:createThinBorder { id = "kl_border2_t" }
	border2.width = 345
	border2.height = 160
	border2.paddingAllSides = 4
	border2.wrapText = true

	--Pane
	local pane = border:createVerticalScrollPane { id = typeModule.id_pane }
	pane.height = 351
	pane.width = 190
	pane.widget.scrollbarVisible = true

	-----Populate-----------------------------------------------------------------------------------------------------
	local mAtt1 = 0
	local mAtt2 = 0
	local mSkillType = ""
	local desc = ""
	for i = 1, #tables.typeTable do
		if tables.typeTable[i] == modData.type then
			--Stats
			mAtt1 = tables.typeStats[i][1]
			mAtt2 = tables.typeStats[i][2]

			--Descriptions
			mSkillType = tables.typeDesc1[i]
			desc = tables.typeDesc2[i]
		end
	end

	border2:createLabel { text = desc, id = "kl_type_desc_2" }

	--Populate Pane
	local bloc = pane:createBlock {}
	bloc.flowDirection = tes3.flowDirection.leftToRight
	bloc.width = 180
	bloc.height = 18
	local deftype = func.determineDefault(reference)
	local a = bloc:createTextSelect { text = "Default: " .. deftype .. "", id = "tChangeB_D" }
	for i = 1, #tables.typeTable do
		if tables.typeTable[i] == deftype then
			if modData.typelevels[i] >= 20 then
				a.widget.idle = tables.colors["gold"]
				local star = bloc:createImage({ path = "textures\\companionLeveler\\star.tga" })
				star.height = 10
				star.width = 10
				star.borderLeft = 4
				star.borderTop = 1
			end
		end
	end
	a:register("mouseClick", function(e) typeModule.defSelect() end)

	pane:createDivider()

	for i = 1, #tables.typeTable do
		local bl = pane:createBlock {}
		bl.flowDirection = tes3.flowDirection.leftToRight
		bl.width = 180
		bl.height = 18
		local b = bl:createTextSelect { text = tables.typeTable[i], id = "tChangeB_" .. i .. "" }
		if modData.typelevels[i] >= 20 then
			b.widget.idle = tables.colors["gold"]
			local star = bl:createImage({ path = "textures\\companionLeveler\\star.tga" })
			star.height = 10
			star.width = 10
			star.borderLeft = 4
			star.borderTop = 1
		end
		b:register("mouseClick", function() typeModule.onSelect(i) end)
	end

	--Text Blocks--
	local text_block = right_block:createBlock { id = "text_block_t" }
	text_block.autoHeight = true
	text_block.autoWidth = true
	text_block.flowDirection = tes3.flowDirection.leftToRight
	text_block.borderTop = 10

	local text_left = text_block:createBlock { id = "text_left_t" }
	text_left.height = 100
	text_left.width = 195
	text_left.flowDirection = tes3.flowDirection.topToBottom
	text_left.borderRight = 10

	local text_right = text_block:createBlock { id = "text_right_t" }
	text_right.height = 100
	text_right.width = 150
	text_right.flowDirection = tes3.flowDirection.topToBottom

	local text_bottom = right_block:createBlock { id = "text_bottom_t" }
	text_bottom.height = 100
	text_bottom.width = 345
	text_bottom.flowDirection = tes3.flowDirection.topToBottom

	--Ability Text
	local kl_ab = text_left:createLabel({ text = "Abilities:", id = "kl_ab_type" })
	kl_ab.color = tables.colors["white"]

	local bdr = text_left:createThinBorder { id = "kl_border_t_a" }
	bdr.width = 195
	bdr.height = 81

	local pne = bdr:createVerticalScrollPane({ id = "kl_type_ability_pane" })
	pne.width = 195
	pne.height = 81

	if modData.type == "Domestic" then
		pne:createTextSelect({ text = "None" })
	else
		for i = 1, #tables.typeTable do
			if modData.type == tables.typeTable[i] then
				local mod = (i * 4) - 3
				local s1 = tes3.getObject(tables.abList[mod])
				local s2 = tes3.getObject(tables.abList[mod + 1])
				local s3 = tes3.getObject(tables.abList[mod + 2])
				local s4 = tes3.getObject(tables.abList[mod + 3])
				local a1 = pne:createTextSelect({ text = s1.name, id = "kl_type_ability_1" })
				local a2 = pne:createTextSelect({ text = s2.name, id = "kl_type_ability_2" })
				local a3 = pne:createTextSelect({ text = s3.name, id = "kl_type_ability_3" })
				local a4 = pne:createTextSelect({ text = s4.name, id = "kl_type_ability_4" })
				local a5 = pne:createTextSelect({ text = "", id = "kl_type_ability_5" })
				local a6 = pne:createTextSelect({ text = "", id = "kl_type_ability_6" })
				local a7 = pne:createTextSelect({ text = "", id = "kl_type_ability_7" })
				local a8 = pne:createTextSelect({ text = "", id = "kl_type_ability_8" })
				func.abilityTooltip(a1, mod, false)
				func.abilityColor(a1, mod, false)
				func.abilityTooltip(a2, mod + 1, false)
				func.abilityColor(a2, mod + 1, false)
				func.abilityTooltip(a3, mod + 2, false)
				func.abilityColor(a3, mod + 2, false)
				func.abilityTooltip(a4, mod + 3, false)
				func.abilityColor(a4, mod + 3, false)
				if modData.type == "Goblin" then
					local s5 = tes3.getObject(tables.abList[mod + 4])
					local s6 = tes3.getObject(tables.abList[mod + 5])
					local s7 = tes3.getObject(tables.abList[mod + 6])
					local s8 = tes3.getObject(tables.abList[mod + 7])
					a5.text = s5.name
					a6.text = s6.name
					a7.text = s7.name
					a8.text = s8.name
					func.abilityTooltip(a5, mod + 4, false)
					func.abilityColor(a5, mod + 4, false)
					func.abilityTooltip(a6, mod + 5, false)
					func.abilityColor(a6, mod + 5, false)
					func.abilityTooltip(a7, mod + 6, false)
					func.abilityColor(a7, mod + 6, false)
					func.abilityTooltip(a8, mod + 7, false)
					func.abilityColor(a8, mod + 7, false)
				end
			end
		end
	end

	--Attribute Text
	local kl_att = text_right:createLabel({ text = "Favored Attributes:", id = "kl_att_type" })
	kl_att.color = tables.colors["white"]
	text_right:createLabel({ text = "" .. tables.capitalization[mAtt1] .. "", id = "kl_att1_type" })
	text_right:createLabel({ text = "" .. tables.capitalization[mAtt2] .. "", id = "kl_att2_type" })
	local extraAtt = text_right:createLabel({ text = "", id = "kl_att3_type" })
	if modData.type == "Draconic" then
		extraAtt.text = "Personality"
	end

	--Description Text
	local kl_spec = text_bottom:createLabel({ text = "Growth Type:" })
	kl_spec.color = tables.colors["white"]
	kl_spec.borderTop = 12
	local kl_desc = text_bottom:createLabel { text = mSkillType, id = "kl_type_desc" }
	kl_desc.wrapText = true

	--Button Block
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 1.0
	button_block.borderTop = 20

	local button_root = button_block:createButton { id = typeModule.id_root, text = "Main Menu" }
	button_root.borderRight = 140

	local button_color = button_block:createButton { id = typeModule.id_color, text = "Color:" }
	if config.abilityColors == true then
		button_color.text = "Color: By Ability"
		button_root.borderRight = 139
		button_color.borderRight = 143
	else
		button_color.text = "Color: Default"
		button_root.borderRight = 145
		button_color.borderRight = 160
	end

	local button_ok = button_block:createButton { id = typeModule.id_ok, text = tes3.findGMST("sOK").value }

	-- Events
	menu:register(tes3.uiEvent.keyEnter, typeModule.onOK)
	button_ok:register(tes3.uiEvent.mouseClick, typeModule.onOK)
	button_color:register("mouseClick", function()
		if config.abilityColors == true then
			config.abilityColors = false
		else
			config.abilityColors = true
		end
		menu:destroy()
		typeModule.typeChange(reference)
	end)
	button_root:register("mouseClick", function()
		menu:destroy()
		root.createWindow(reference)
		func.clMessageBox { message = "" .. typeModule.reference.object.name .. " changed to " .. modData.type .. "." }
	end)

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
		func.clMessageBox { message = "" .. typeModule.reference.object.name .. " changed to " .. modData.type .. "." }
	end
end

function typeModule.onSelect(i)
	local menu = tes3ui.findMenu(typeModule.id_menu)

	if (menu) then
		local modData = func.getModData(typeModule.reference)
		local id = menu:findChild("tChangeB_" .. i .. "")

		log:debug("" .. modData.type .. " changed to " .. tables.typeTable[i] .. ".")
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
		text2.text = tables.capitalization[tables.typeStats[i][1]]

		local text3 = menu:findChild("kl_att2_type")
		text3.text = tables.capitalization[tables.typeStats[i][2]]

		local text5 = menu:findChild("kl_att3_type")
		text5.text = ""
		if i == 11 then
			text5.text = "Personality"
		end

		if i == 8 then
			for n = 1, 4 do
				local a = menu:findChild("kl_type_ability_" .. n .. "")
				a.text = ""
			end
		else
			for n = 1, 4 do
				local a = menu:findChild("kl_type_ability_" .. n .. "")
				local mod = ((i * 4) - 3) + (n - 1)
				local spell = tes3.getObject(tables.abList[mod])
				a.text = "" .. spell.name .. ""
				func.abilityTooltip(a, mod, false)
				func.abilityColor(a, mod, false)
			end
		end

		if i == 7 then
			for n = 5, 8 do
				local a = menu:findChild("kl_type_ability_" .. n .."")
				local mod = ((i * 4) - 3) + (n - 1)
				local spell = tes3.getObject(tables.abList[mod])
				a.text = "" .. spell.name .. ""
				func.abilityTooltip(a, mod, false)
				func.abilityColor(a, mod, false)
			end
		else
			for n = 5, 8 do
				local a = menu:findChild("kl_type_ability_" .. n .."")
				a.text = ""
			end
		end

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
				text2.text = tables.capitalization[tables.typeStats[i][1]]

				local text3 = menu:findChild("kl_att2_type")
				text3.text = tables.capitalization[tables.typeStats[i][2]]

				local text5 = menu:findChild("kl_att3_type")
				text5.text = ""
				if i == 11 then
					text5.text = "Personality"
				end

				for n = 1, 4 do
					local a = menu:findChild("kl_type_ability_" .. n .. "")
					local mod = ((i * 4) - 3) + (n - 1)
					local spell = tes3.getObject(tables.abList[mod])
					a.text = "" .. spell.name .. ""
					func.abilityTooltip(a, mod, false)
					func.abilityColor(a, mod, false)
				end

				if i == 7 then
					for n = 5, 8 do
						local a = menu:findChild("kl_type_ability_" .. n .."")
						local mod = ((i * 4) - 3) + (n - 1)
						local spell = tes3.getObject(tables.abList[mod])
						a.text = "" .. spell.name .. ""
						func.abilityTooltip(a, mod, false)
						func.abilityColor(a, mod, false)
					end
				else
					for n = 5, 8 do
						local a = menu:findChild("kl_type_ability_" .. n .."")
						a.text = ""
					end
				end
			end
		end

		log:debug("" .. typeModule.reference.object.name .. " changed back to " .. defType .. ".")
		menu:updateLayout()
	end
end

return typeModule
