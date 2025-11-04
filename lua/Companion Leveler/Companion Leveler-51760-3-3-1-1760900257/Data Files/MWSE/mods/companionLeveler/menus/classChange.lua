local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")



local classModule = {}


function classModule.classChange(reference)
	--Initialize IDs
	classModule.id_menu = tes3ui.registerID("kl_class_change_menu")
	classModule.id_pane = tes3ui.registerID("kl_class_change_pane")
	classModule.id_ok = tes3ui.registerID("kl_class_change_ok")
	classModule.id_growth = tes3ui.registerID("kl_class_change_growth_btn")
	classModule.id_root = tes3ui.registerID("kl_class_change_root")
	classModule.id_image = tes3ui.registerID("kl_class_change_image")

	local root = require("companionLeveler.menus.root")

	log = logger.getLogger("Companion Leveler")
	log:debug("Class menu initialized.")

	if (reference) then
		classModule.reference = reference
	end

	classModule.total = 0

	if (tes3ui.findMenu(classModule.id_menu) ~= nil) then
		return
	end
	log:debug("Class menu triggered.")

	-- Create window and frame
	local menu = tes3ui.createMenu { id = classModule.id_menu, fixedFrame = true }
	menu.alpha = 1.0

	-- Create layout
	local name = reference.object.name
	local modData = func.getModData(reference)
	local cClass = tes3.findClass(modData.class)

	local input_label = menu:createLabel { text = "Select " .. name .. "'s Class:" }
	input_label.borderBottom = 10

	--new main block
	local block = menu:createBlock { id = "main_block" }
	block.autoHeight = true
	block.autoWidth = true
	block.flowDirection = tes3.flowDirection.leftToRight
	--pane
	local pane_block = block:createBlock { id = "kl_pane_block" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true
	pane_block.borderRight = 12

	local border = pane_block:createThinBorder { id = "kl_border" }
	border.width = 190
	border.height = 314
	border.borderRight = 12

	local right_block = block:createBlock { id = "kl_right_block"}
	right_block.autoWidth = true
	right_block.autoHeight = true
	right_block.flowDirection = tes3.flowDirection.topToBottom
	local img_block = right_block:createBlock { id = "kl_img_block" }
	img_block.autoWidth = true
	img_block.autoHeight = true
	img_block.borderLeft = 19
	local border2 = img_block:createThinBorder { id = "kl_border2" }
	border2.width = 260
	border2.height = 132
	border2.paddingAllSides = 2

	--Image
	local path = cClass.image
	if path == nil then
		local default = tes3.findClass("Nightblade")
		path = default.image
	end
	local image = border2:createImage({ path = path, id = classModule.id_image })
	image.height = 128
	image.width = 256

	--Pane
	local pane = border:createVerticalScrollPane { id = classModule.id_pane }
	pane.height = 314
	pane.width = 190
	pane.widget.scrollbarVisible = true

	--Populate Pane
	local bloc = pane:createBlock {}
	bloc.flowDirection = tes3.flowDirection.leftToRight
	bloc.width = 180
	bloc.height = 18
	local a = bloc:createTextSelect { text = "Default: " .. reference.object.class.name .. "", id = "cChangeB_D" }
	a:register("mouseClick", function() classModule.defSelect() end)

	for int = 1, #tables.classesSpecial do
		if reference.object.class.name == tables.classesSpecial[int] then
			if modData.abilities[int] == true then
				a.widget.idle = tables.colors["gold"]
				local star = bloc:createImage({ path = "textures\\companionLeveler\\star.tga" })
				star.height = 10
				star.width = 10
				star.borderLeft = 4
				star.borderTop = 1
			end

			func.abilityColor(a, int, true)
		end
	end

	local bloc2 = pane:createBlock {}
	bloc2.flowDirection = tes3.flowDirection.leftToRight
	bloc2.width = 180
	bloc2.height = 18

	bloc2:createDivider()

	if config.allClasses == true then
		--list all available classes
		for n, k in pairs(tes3.dataHandler.nonDynamicData.classes) do
			log:debug("Class: " .. k.name .. ", Source Mod: " .. tostring(k.sourceMod) .. "")
	
			local num = classModule.total
			local bl = pane:createBlock {}
			bl.flowDirection = tes3.flowDirection.leftToRight
			bl.width = 180
			bl.height = 18
			local b = bl:createTextSelect { text = k.name, id = "cChangeB_" .. num .. "" }
			b:register("mouseClick", function() classModule.onSelect(num, k.id) end)
			classModule.total = classModule.total + 1
			for int = 1, #tables.classesSpecial do
				if k.name == tables.classesSpecial[int] then
					if modData.abilities[int] == true then
						b.widget.idle = tables.colors["gold"]
						local star = bl:createImage({ path = "textures\\companionLeveler\\star.tga" })
						star.height = 10
						star.width = 10
						star.borderLeft = 4
						star.borderTop = 1
					end

					func.abilityColor(b, int, true)
				end
			end
		end
	else
		--list most vanilla classes
		for i = 1, #tables.classes do
			local num = classModule.total
			local bl = pane:createBlock {}
			bl.flowDirection = tes3.flowDirection.leftToRight
			bl.width = 180
			bl.height = 18
			local b = bl:createTextSelect { text = tables.classes[i], id = "cChangeB_" .. num .. "" }
			b:register("mouseClick", function() classModule.onSelect(num, tables.classes[i]) end)
			classModule.total = classModule.total + 1
			for int = 1, #tables.classesSpecial do
				if b.text == tables.classesSpecial[int] then
					if modData.abilities[int] == true then
						b.widget.idle = tables.colors["gold"]
						local star = bl:createImage({ path = "textures\\companionLeveler\\star.tga" })
						star.height = 10
						star.width = 10
						star.borderLeft = 4
						star.borderTop = 1
					end

					func.abilityColor(b, int, true)

				end
			end
		end
		--Ahead of the Classes
		local modList = tes3.getModList()

		if config.aheadClasses == true then
			for i, v in pairs(modList) do
				if v == "Ahead of the Classes.ESP" then
					for n, k in pairs(tes3.dataHandler.nonDynamicData.classes) do
						--Rare error for some reason, problem with formatting
						--log:debug("Class: " .. k.name .. ", Source Mod: " .. k.sourceMod .. "")
						if k.sourceMod == "Ahead of the Classes.ESP" or k.sourceMod == "F&F_Ahead of the Classes.ESP" then
							local dupe = false
							for int = 1, #tables.classes do
								if k.name == tables.classes[int] then
									dupe = true
									break
								end
							end
							if dupe == false then
								local num = classModule.total
								local bl = pane:createBlock {}
								bl.flowDirection = tes3.flowDirection.leftToRight
								bl.width = 180
								bl.height = 18
								local b = bl:createTextSelect { text = "" .. k.name .. "", id = "cChangeB_" .. num .. "" }
								b:register("mouseClick", function() classModule.onSelect(num, k.id) end)
								classModule.total = classModule.total + 1
								for int = 1, #tables.classesSpecial do
									if k.name == tables.classesSpecial[int] then
										if modData.abilities[int] == true then
											b.widget.idle = tables.colors["gold"]
											local star = bl:createImage({ path = "textures\\companionLeveler\\star.tga" })
											star.height = 10
											star.width = 10
											star.borderLeft = 4
											star.borderTop = 1
										end

										func.abilityColor(b, int, true)

									end
								end
							end
						end
					end
					break
				end
			end
		end

		--Companion Leveler Classes
		for i, v in pairs(modList) do
			if v == "companionLeveler.ESP" then
				for n, k in pairs(tes3.dataHandler.nonDynamicData.classes) do
					--log:debug("Class: " .. k.name .. ", Source Mod: " .. tostring(k.sourceMod) .. "")
					if k.sourceMod == "companionLeveler.ESP" then
						local dupe = false
						for int = 1, #tables.classes do
							if k.name == tables.classes[int] then
								dupe = true
								break
							end
						end
						if dupe == false then
							local num = classModule.total
							local bl = pane:createBlock {}
							bl.flowDirection = tes3.flowDirection.leftToRight
							bl.width = 180
							bl.height = 18
							local b = bl:createTextSelect { text = "" .. k.name .. "", id = "cChangeB_" .. num .. "" }
							b:register("mouseClick", function() classModule.onSelect(num, k.id) end)
							classModule.total = classModule.total + 1
							for int = 1, #tables.classesSpecial do
								if k.name == tables.classesSpecial[int] then
									if modData.abilities[int] == true then
										b.widget.idle = tables.colors["gold"]
										local star = bl:createImage({ path = "textures\\companionLeveler\\star.tga" })
										star.height = 10
										star.width = 10
										star.borderLeft = 4
										star.borderTop = 1
									end

									func.abilityColor(b, int, true)

								end
							end
						end
					end
				end
				break
			end
		end
	end

	--Sort
	pane:getContentElement():sortChildren(function(c, d)
		local cText
		local dText

		for int = 0, classModule.total do
			cText = ""
			local cChild = c:findChild("cChangeB_" .. int .. "")
			if cChild == nil then
				cChild = c:findChild("cChangeB_D")
			end
			if cChild ~= nil then cText = cChild.text break end
		end
		for num = 0, classModule.total do
			dText = ""
			local dChild = d:findChild("cChangeB_" .. num .. "")
			if dChild == nil then
				dChild = d:findChild("cChangeB_D")
			end
			if dChild ~= nil then dText = dChild.text break end
		end

		if not string.startswith(cText, "Default") and not string.startswith(dText, "Default") then
			return cText < dText
		end
	end)

	--Text Blocks--
	local text_block = right_block:createBlock { id = "text_block" }
	text_block.autoHeight = true
	text_block.autoWidth = true
	text_block.flowDirection = tes3.flowDirection.leftToRight
	text_block.borderTop = 10

	local text_left = text_block:createBlock { id = "text_left" }
	text_left.height = 172
	text_left.width = 155
	text_left.flowDirection = tes3.flowDirection.topToBottom

	local text_right = text_block:createBlock { id = "text_right" }
	text_right.height = 172
	text_right.width = 155
	text_right.flowDirection = tes3.flowDirection.topToBottom

	--Specialization
	local kl_spec = text_left:createLabel({ text = "Specialization:", id = "kl_spec_title" })
	kl_spec.color = tables.colors["white"]
	text_left:createLabel({ text = tables.capitalization2[cClass.specialization], id = "kl_spec1" })

	--Attributes
	local kl_att = text_right:createLabel({ text = "Favored Attributes:", id = "kl_att_title" })
	kl_att.color = tables.colors["white"]
	local mAtt1 = cClass.attributes[1]
	local mAtt2 = cClass.attributes[2]
	text_right:createLabel({ text = "" .. tables.capitalization[mAtt1] .. "", id = "kl_att1" })
	text_right:createLabel({ text = "" .. tables.capitalization[mAtt2] .. "", id = "kl_att2" })

	--Major Skills
	local kl_major = text_left:createLabel({ text = "Major Skills:", id = "kl_major_title" })
	kl_major.color = tables.colors["white"]
	kl_major.borderTop = 29
	local mSkills = cClass.majorSkills
	for i = 1, 5 do
		local skill = text_left:createLabel { text = tes3.skillName[mSkills[i]], id = "kl_major" .. i .. "" }
		if modData.ignore_skill ~= 99 then
			if skill.text == (tes3.getSkillName(modData.ignore_skill)) then
				skill.color = tables.colors["yellow"]
			end
		end
	end

	--Minor Skills
	local kl_minor = text_right:createLabel({ text = "Minor Skills:", id = "kl_minor_title" })
	kl_minor.color = tables.colors["white"]
	kl_minor.borderTop = 10
	local minSkills = cClass.minorSkills
	for i = 1, 5 do
		local skill = text_right:createLabel { text = tes3.skillName[minSkills[i]], id = "kl_minor" .. i .. "" }
		if modData.ignore_skill ~= 99 then
			if skill.text == (tes3.getSkillName(modData.ignore_skill)) then
				skill.color = tables.colors["yellow"]
			end
		end
	end

	--Ability Block
	local ability_block = menu:createBlock {}
	ability_block.widthProportional = 1.0
	ability_block.autoHeight = true
	ability_block.childAlignX = 0.5
	ability_block.flowDirection = "left_to_right"
	ability_block.borderTop = 20

	--Ability
	local kl_ability = ability_block:createLabel({ text = "Ability:", id = "kl_ability_title" })
	kl_ability.color = tables.colors["white"]

	local abilityName = ability_block:createLabel({ text = "", id = "kl_ability_name" })
	abilityName.borderLeft = 4
	abilityName.borderRight = 4

	local learned = ability_block:createLabel({ text = "", id = "kl_ability_learned" })

	for i = 1, #tables.classesSpecial do
		if cClass.name == tables.classesSpecial[i] then
			local spellObject = tes3.getObject(tables.abListNPC[i])
			abilityName.text = "" .. spellObject.name .. ""

			if modData.abilities[i] == true then
				learned.text = "(Learned)"
			else
				learned.text = "(Unlearned)"
			end

			func.abilityTooltip(abilityName, i, true)
		end
	end


	--Button Block
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0 -- width is 100% parent width
	button_block.autoHeight = true
	button_block.childAlignY = 0.5
	button_block.borderTop = 20
	button_block.childOffsetX = 20

	local button_root = button_block:createButton { id = classModule.id_root, text = "Main Menu" }
	local button_color = button_block:createButton { id = classModule.id_color, text = "Color:" }
	if config.abilityColors == true then
		button_color.text = "Color: By Ability"
		button_root.borderRight = 72
		button_color.borderRight = 105
	else
		button_color.text = "Color: Default"
		button_root.borderRight = 78
		button_color.borderRight = 122
	end
	local button_ok = button_block:createButton { id = classModule.id_ok, text = tes3.findGMST("sOK").value }

	-- Events
	menu:register(tes3.uiEvent.keyEnter, classModule.onOK)
	button_ok:register(tes3.uiEvent.mouseClick, classModule.onOK)
	button_color:register("mouseClick", function()
		if config.abilityColors == true then
			config.abilityColors = false
		else
			config.abilityColors = true
		end
		menu:destroy()
		classModule.classChange(reference)
	end)
	button_root:register("mouseClick",
		function() menu:destroy()
			func.clMessageBox("" .. classModule.reference.object.name .. " changed to " .. tes3.findClass(modData.class).name .. ".")
			root.createWindow(reference)
		end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(classModule.id_menu)
end

----Events----------------------------------------------------------------------------------------------------------
function classModule.onOK()
	local menu = tes3ui.findMenu(classModule.id_menu)
	local modData = func.getModData(classModule.reference)
	local class = tes3.findClass(modData.class)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
		func.clMessageBox("" .. classModule.reference.object.name .. " changed to " .. class.name .. ".")
	end
end

function classModule.onSelect(i, id)
	local menu = tes3ui.findMenu(classModule.id_menu)
	if (menu) then
		local modData = func.getModData(classModule.reference)
		local cClass = tes3.findClass(id)

		--Image
		local border = menu:findChild("kl_border2")
		local image = menu:findChild(classModule.id_image)
		image:destroy()
		local path = cClass.image
		if path == nil then
			local default = tes3.findClass("Nightblade")
			path = default.image
		end
		border:createImage({ path = path, id = classModule.id_image })

		modData.class = id

		--States
		local idDef = menu:findChild("cChangeB_D")
		if idDef.widget.state == 4 then
			idDef.widget.state = 1
		end

		for n = 0, classModule.total do
			local id2 = menu:findChild("cChangeB_" .. n .. "")
			if id2 then
				if id2.widget.state == 4 then
					id2.widget.state = 1
				end
			end
		end

		local choice = menu:findChild("cChangeB_" .. i .. "")
		choice.widget.state = 4

		--Change Text
		local sText = menu:findChild("kl_spec1")
		sText.text = tables.capitalization2[cClass.specialization]

		local mAttributes = cClass.attributes
		for n = 1, 2 do
			local text = menu:findChild("kl_att" .. n .. "")
			text.text = tables.capitalization[mAttributes[n]]
		end

		local mSkills = cClass.majorSkills
		for n = 1, 5 do
			local text = menu:findChild("kl_major" .. n .. "")
			text.text = tes3.skillName[mSkills[n]]
			text.color = tables.colors["default_font"]
			if modData.ignore_skill ~= 99 then
				if text.text == (tes3.getSkillName(modData.ignore_skill)) then
					text.color = tables.colors["yellow"]
				end
			end
		end

		local minSkills = cClass.minorSkills
		for n = 1, 5 do
			local text = menu:findChild("kl_minor" .. n .. "")
			text.text = tes3.skillName[minSkills[n]]
			text.color = tables.colors["default_font"]
			if modData.ignore_skill ~= 99 then
				if text.text == (tes3.getSkillName(modData.ignore_skill)) then
					text.color = tables.colors["yellow"]
				end
			end
		end

		local ability = menu:findChild("kl_ability_name")
		ability.text = ""

		local learned = menu:findChild("kl_ability_learned")
		learned.text = ""

		for n = 1, #tables.classesSpecial do
			if cClass.name == tables.classesSpecial[n] then
				local spellObject = tes3.getObject(tables.abListNPC[n])
				ability.text = "" .. spellObject.name .. ""

				if modData.abilities[n] == true then
					learned.text = "(Learned)"
				else
					learned.text = "(Unlearned)"
				end

				func.abilityTooltip(ability, n, true)
			end
		end

		log:debug("" .. classModule.reference.object.name .. " changed to " .. cClass.name .. ".")
		menu:updateLayout()
	end
end

function classModule.defSelect()
	local menu = tes3ui.findMenu(classModule.id_menu)
	if (menu) then
		local class = classModule.reference.object.class
		local modData = func.getModData(classModule.reference)

		--Image
		local border = menu:findChild("kl_border2")
		local image = menu:findChild(classModule.id_image)
		image:destroy()
		local path = class.image
		if path == nil then
			local default = tes3.findClass("Nightblade")
			path = default.image
		end
		border:createImage({ path = path, id = classModule.id_image })

		modData.class = class.id

		--States
		local id = menu:findChild("cChangeB_D")
		id.widget.state = 4

		for n = 0, classModule.total do
			local id2 = menu:findChild("cChangeB_" .. n .. "")
			if id2 then
				if id2.widget.state == 4 then
					id2.widget.state = 1
				end
			end
		end

		--Change Text
		local sText = menu:findChild("kl_spec1")
		sText.text = tables.capitalization2[class.specialization]

		local mAttributes = class.attributes
		for n = 1, 2 do
			local text = menu:findChild("kl_att" .. n .. "")
			text.text = tables.capitalization[mAttributes[n]]
		end

		local mSkills = class.majorSkills
		for n = 1, 5 do
			local text = menu:findChild("kl_major" .. n .. "")
			text.text = tes3.skillName[mSkills[n]]
			text.color = tables.colors["default_font"]
			if modData.ignore_skill ~= 99 then
				if text.text == (tes3.getSkillName(modData.ignore_skill)) then
					text.color = tables.colors["yellow"]
				end
			end
		end

		local minSkills = class.minorSkills
		for n = 1, 5 do
			local text = menu:findChild("kl_minor" .. n .. "")
			text.text = tes3.skillName[minSkills[n]]
			text.color = tables.colors["default_font"]
			if modData.ignore_skill ~= 99 then
				if text.text == (tes3.getSkillName(modData.ignore_skill)) then
					text.color = tables.colors["yellow"]
				end
			end
		end

		local ability = menu:findChild("kl_ability_name")
		ability.text = ""

		local learned = menu:findChild("kl_ability_learned")
		learned.text = ""

		for n = 1, #tables.classesSpecial do
			if class.name == tables.classesSpecial[n] then
				local spellObject = tes3.getObject(tables.abListNPC[n])
				ability.text = "" .. spellObject.name .. ""

				if modData.abilities[n] == true then
					learned.text = "(Learned)"
				else
					learned.text = "(Unlearned)"
				end

				func.abilityTooltip(ability, n, true)
			end
		end

		log:debug("" .. modData.class .. " changed back to " .. class.name .. ".")
		menu:updateLayout()
	end
end


return classModule