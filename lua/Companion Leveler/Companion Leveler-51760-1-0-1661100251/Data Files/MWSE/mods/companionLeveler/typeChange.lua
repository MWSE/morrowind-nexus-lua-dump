local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.common")


local typeModule = {}


function typeModule.typeChange(reference)
    --Initialize IDs
    typeModule.id_menu = tes3ui.registerID("kl_type_menu")
    typeModule.id_pane = tes3ui.registerID("kl_type_pane")
    typeModule.id_ok = tes3ui.registerID("kl_type_ok")
	typeModule.id_image = tes3ui.registerID("kl_type_image")
	log = logger.getLogger("Companion Leveler")
    log:debug("Type menu initialized.")

    if (reference) then
            typeModule.reference = reference
    end

    if (tes3ui.findMenu(typeModule.id_menu) ~= nil) then
        return
    end

    log:debug("Type menu triggered.")
    -- Create window and frame
    local menu = tes3ui.createMenu{ id = typeModule.id_menu, fixedFrame = true }

    -- Create layout
	local name = reference.object.name
	local modData = func.getModData(reference)
    local input_label = menu:createLabel{ text = "Select " .. name .. "'s Type:" }
    input_label.borderBottom = 5

    local pane_block = menu:createBlock{ id = "pane_block_type" }
    pane_block.autoWidth = true
    pane_block.autoHeight = true

    local border = pane_block:createThinBorder{ id = "kl_border_type" }
	border.positionX = 4
	border.positionY = -4
    border.width = 190
    border.height = 140
    border.borderAllSides = 4
	border.paddingAllSides = 4

	local border2 = pane_block:createThinBorder{ id = "kl_border2_type" }
	border2.positionX = 202
	border2.positionY = 0
    border2.width = 270
    border2.height = 150
	border2.paddingAllSides = 4
	border2.wrapText = true

	----Populate-----------------------------------------------------------------------------------------------------
	local mAtt1 = 0
	local mAtt2 = 0
	local mSkillType = ""
	local desc = ""
	if modData.type == "Normal" then
		mAtt2 = 3
		mSkillType = "Physical Type. Limited close range spells and augmentations. Guaranteed bonus Agility."
		desc = "\"The familiar flora and fauna of Tamriel is exchanged for bizarre and twisted forms that can survive the regular ashfall.\" - Pocket Guide to the Empire, Morrowind"
	end
	if modData.type == "Daedra" then
		mAtt2 = 1
		mSkillType = "Mixed Type. Barriers. Proficient in Destruction and summoning other Daedra."
		desc = "\"We serve by choice. We serve the strong, so that their strength might shield us.\" - Spirit of the Daedra"
	end
	if modData.type == "Undead" then
		mAtt1 = 1
		mAtt2 = 5
		mSkillType = "Mixed Type. Debilitating spells. Proficient in Mysticism and summoning other Undead."
		desc = "\"The Ancestors are not departed. The dead are not under the earth. Their spirits are in the restless wind, in the fire's voice, in the foot-smoothed step. Pay heed to these things, and you will know your absent kin.\" - The Doors of the Spirit"
	end
	if modData.type == "Humanoid" then
		mAtt1 = 1
		mAtt2 = 2
		mSkillType = "Magical Type. Proficient in offensive magic. Learns magic at a faster rate."
		desc = "\"That House was a curse on our land for millennia, and when at last their pestilence was snuffed out, the very earth itself breathed a cloud of fire and ash in relief, bringing night to day for over a year's time.\" - Poison Song"
	end
	if modData.type == "Centurion" then
		mAtt1 = 0
		mAtt2 = 5
		mSkillType = "Physical Type. Weak electric and flame attacks. Guaranteed bonus Endurance."
		desc = "\"I wondered what secrets remained hidden in the maze of chambers that lay before me, defying the efforts of looters, waiting to gleam again in the light they had not seen in long eons.\" - The Ruins of Kemel-Ze"
	end
	if modData.type == "Spriggan" then
		mAtt1 = 1
		mAtt2 = 7
		mSkillType = "Magical Type. Proficient in supportive magic. Guaranteed bonus Luck."
		desc = "\"When the All-Maker breathed life into the creatures of the land, his Breath blew through the trees as well. Some of these trees kept a part of this life, and these are the spriggans you see today.\" - Skaal Legend"
	end
	if modData.type == "Goblin" then
		mAtt1 = 3
		mAtt2 = 4
		mSkillType = "Stealth Type. Proficient in Illusion magic. Learns many Abilities."
		desc = "\"Vile little beasts, but not as mindless as some may think. Some are capable of speech, and all are capable of great cunning.\" - Skaal warning regarding Rieklings, a type of Goblin"
	end
	if modData.type == "Domestic" then
		mAtt1 = 6
		mAtt2 = 7
		mSkillType = "Stealth Type. Learns no Spells or Abilities, but their mere presence makes you feel luckier somehow..."
		desc = "\"It is true that I call my guar herd my little family, but it is not because they are of my blood.\" - Esqoo of Dhalmora Answers Your Questions"
	end

	local description = border2:createLabel{ text = desc, id = "kl_desc_type" }

	local pane = border:createVerticalScrollPane{ id = typeModule.id_pane }
	pane.height = 128
	pane.width = 190
	pane.positionX = 4
	pane.positionY = -4
	pane.widget.scrollbarVisible = true

	local deftype = tables.typeTable[reference.object.type]
	if (string.endswith(name, "Sphere") or string.endswith(name, "Centurion") or string.endswith(name, "Fabricant") or string.startswith(name, "Centurion")) then
		deftype = "Centurion"
	end
	if string.startswith(name, "Spriggan") then
		deftype = "Spriggan"
	end
	if (string.startswith(name, "Goblin") or string.startswith(name, "Warchief")) then
		deftype = "Goblin"
	end
	if (string.startswith(name, "Guar") or string.endswith(name, "Guar") or string.startswith(name, "Corky") or string.startswith(name, "Pack Rat")) then
		deftype = "Domestic"
	end
	local a = pane:createTextSelect{ text = "Default: " .. deftype .. "", id = "tChangeB_D" }
	a:register("mouseClick", function(e) typeModule.defSelect(e) end)
	local line = pane:createDivider()
	for i = 0, 7 do
        local b = pane:createTextSelect{ text = tables.typeTable[i], id = "tChangeB_" .. i .. "" }
        b:register("mouseClick", function(e) typeModule.onSelect(i) end)
    end

	local text_block = menu:createBlock{ id = "text_block_type" }
	text_block.positionX = 10
	text_block.positionY = -146
	text_block.width = 470
    text_block.height = 88
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local spec_block = text_block:createBlock{}
	spec_block.positionX = 4
	spec_block.positionY = -4
	spec_block.width = 155
	spec_block.height = 95
	spec_block.borderAllSides = 4
	spec_block.flowDirection = "top_to_bottom"

	local major_block = text_block:createBlock{}
	major_block.positionX = 167
	major_block.positionY = -4
	major_block.width = 250
	major_block.height = 108
	major_block.borderAllSides = 4
	major_block.flowDirection = "top_to_bottom"
	major_block.wrapText = true

	local kl_att = spec_block:createLabel({ text = "Favored Attributes:", id = "kl_att_type" })
	kl_att.color = {1.0, 1.0, 1.0}
	local kl_att1 = spec_block:createLabel({ text = "" .. tables.capitalization[mAtt1] .. "", id = "kl_att1_type" })
	local kl_att2 = spec_block:createLabel({ text = "" .. tables.capitalization[mAtt2] .. "", id = "kl_att2_type" })

	local kl_major = major_block:createLabel({ text = "Growth Type:", id = "kl_major_type" })
	kl_major.color = {1.0, 1.0, 1.0}
	local t = major_block:createLabel{ text = mSkillType, id = "kl_major_type2" }

    local button_block = menu:createBlock{}
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 1.0

    local button_ok = button_block:createButton{ id = typeModule.id_ok, text = tes3.findGMST("sOK").value }

    -- Events
    menu:register(tes3.uiEvent.keyEnter, typeModule.onOK)
    button_ok:register(tes3.uiEvent.mouseClick, typeModule.onOK)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(typeModule.id_menu)
end


function typeModule.onOK(e)
    local menu = tes3ui.findMenu(typeModule.id_menu)
	local modData = func.getModData(typeModule.reference)
    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroy()
		log:info("" .. typeModule.reference.object.name .. " changed to " .. modData.type .. ".")
        tes3.messageBox{ message = "" .. typeModule.reference.object.name .. " changed to " .. modData.type .. "." }
    end
end

function typeModule.onSelect(i)
    local menu = tes3ui.findMenu(typeModule.id_menu)
	local pane = menu:findChild(typeModule.id_pane)
    if (menu) then
		local modData = func.getModData(typeModule.reference)
        local tChange = tables.typeTable[i]
		local block = menu:findChild("pane_block_type")
		local block2 = menu:findChild("text_block_type")
		local border = block:findChild("kl_border2_type")
		log:debug("" .. modData.type .. " changed to " .. tChange .. ".")
		modData.type = tChange
		local id = pane:findChild("tChangeB_" .. i .. "")
		local idDef = pane:findChild("tChangeB_D")
		if idDef.widget.state == 4 then
			idDef.widget.state = 1
		end
		for n = 0, 7 do
			local id2 = pane:findChild("tChangeB_" .. n .. "")
			if id2.widget.state == 4 then
				id2.widget.state = 1
			end
		end
		id.widget.state = 4
		local mAtt1 = 0
		local mAtt2 = 0
		local mSkillType = ""
		local desc = ""
		if tChange == "Normal" then
			mAtt2 = 3
			mSkillType = "Physical Type. Limited close range spells and augmentations. Guaranteed bonus Agility."
			desc = "\"The familiar flora and fauna of Tamriel is exchanged for bizarre and twisted forms that can survive the regular ashfall.\" - Pocket Guide to the Empire, Morrowind"
		end
		if tChange == "Daedra" then
			mAtt2 = 1
			mSkillType = "Mixed Type. Barriers. Proficient in Destruction and summoning other Daedra."
			desc = "\"We serve by choice. We serve the strong, so that their strength might shield us.\" - Spirit of the Daedra"
		end
		if tChange == "Undead" then
			mAtt1 = 1
			mAtt2 = 5
			mSkillType = "Mixed Type. Debilitating spells. Proficient in Mysticism and summoning other Undead."
			desc = "\"The Ancestors are not departed. The dead are not under the earth. Their spirits are in the restless wind, in the fire's voice, in the foot-smoothed step. Pay heed to these things, and you will know your absent kin.\" - The Doors of the Spirit"
		end
		if tChange == "Humanoid" then
			mAtt1 = 1
			mAtt2 = 2
			mSkillType = "Magical Type. Proficient in offensive magic. Learns magic at a faster rate."
			desc = "\"That House was a curse on our land for millennia, and when at last their pestilence was snuffed out, the very earth itself breathed a cloud of fire and ash in relief, bringing night to day for over a year's time.\" - Poison Song"
		end
		if tChange == "Centurion" then
			mAtt1 = 0
			mAtt2 = 5
			mSkillType = "Physical Type. Weak electric and flame attacks. Guaranteed bonus Endurance."
			desc = "\"I wondered what secrets remained hidden in the maze of chambers that lay before me, defying the efforts of looters, waiting to gleam again in the light they had not seen in long eons.\" - The Ruins of Kemel-Ze"
		end
		if tChange == "Spriggan" then
			mAtt1 = 1
			mAtt2 = 7
			mSkillType = "Magical Type. Proficient in supportive magic. Guaranteed bonus Luck."
			desc = "\"When the All-Maker breathed life into the creatures of the land, his Breath blew through the trees as well. Some of these trees kept a part of this life, and these are the spriggans you see today.\" - Skaal Legend"
		end
		if tChange == "Goblin" then
			mAtt1 = 3
			mAtt2 = 4
			mSkillType = "Stealth Type. Proficient in Illusion magic. Learns many Abilities."
			desc = "\"Vile little beasts, but not as mindless as some may think. Some are capable of speech, and all are capable of great cunning.\" - Skaal warning regarding Rieklings, a type of Goblin"
		end
		if tChange == "Domestic" then
			mAtt1 = 6
			mAtt2 = 7
			mSkillType = "Stealth Type. Learns no Spells or Abilities, but their mere presence makes you feel luckier somehow..."
			desc = "\"It is true that I call my guar herd my little family, but it is not because they are of my blood.\" - Esqoo of Dhalmora Answers Your Questions"
		end
		local text = border:findChild("kl_desc_type")
		text.text = desc
		local text2 = block2:findChild("kl_att1_type")
		text2.text = tables.capitalization[mAtt1]
		local text3 = block2:findChild("kl_att2_type")
		text3.text = tables.capitalization[mAtt2]
		local text4 = block2:findChild("kl_major_type2")
        text4.text = mSkillType
		menu:updateLayout()
    end
end

function typeModule.defSelect(e)
    local menu = tes3ui.findMenu(typeModule.id_menu)
	local pane = menu:findChild(typeModule.id_pane)
    if (menu) then
		local ref = typeModule.reference
		local defType = tables.typeTable[ref.object.type]
		if (string.endswith(ref.object.name, "Sphere") or string.endswith(ref.object.name, "Centurion") or string.endswith(ref.object.name, "Fabricant") or string.startswith(ref.object.name, "Centurion")) then
			defType = "Centurion"
		end
		if string.startswith(ref.object.name, "Spriggan") then
			defType = "Spriggan"
		end
		if (string.startswith(ref.object.name, "Goblin") or string.startswith(ref.object.name, "Warchief")) then
			defType = "Goblin"
		end
		if (string.startswith(ref.object.name, "Guar") or string.endswith(ref.object.name, "Guar") or string.startswith(ref.object.name, "Corky") or string.startswith(ref.object.name, "Pack Rat")) then
			defType = "Domestic"
		end
		local block = menu:findChild("pane_block_type")
		local block2 = menu:findChild("text_block_type")
		local border = block:findChild("kl_border2_type")
		local modData = func.getModData(typeModule.reference)
		log:debug("" .. ref.object.name .. " changed back to " .. defType .. ".")
		modData.type = defType
		local id = pane:findChild("tChangeB_D")
		for n = 0, 7 do
			local id2 = pane:findChild("tChangeB_" .. n .. "")
			if id2.widget.state == 4 then
				id2.widget.state = 1
			end
		end
		id.widget.state = 4
		local mAtt1 = 0
		local mAtt2 = 0
		local mSkillType = ""
		local desc = ""
		if defType == "Normal" then
			mAtt2 = 3
			mSkillType = "Physical Type. Limited close range spells and augmentations. Guaranteed bonus Agility."
			desc = "\"The familiar flora and fauna of Tamriel is exchanged for bizarre and twisted forms that can survive the regular ashfall.\" - Pocket Guide to the Empire, Morrowind"
		end
		if defType == "Daedra" then
			mAtt2 = 1
			mSkillType = "Mixed Type. Barriers. Proficient in Destruction and summoning other Daedra."
			desc = "\"We serve by choice. We serve the strong, so that their strength might shield us.\" - Spirit of the Daedra"
		end
		if defType == "Undead" then
			mAtt1 = 1
			mAtt2 = 5
			mSkillType = "Mixed Type. Debilitating spells. Proficient in Mysticism and summoning other Undead."
			desc = "\"The Ancestors are not departed. The dead are not under the earth. Their spirits are in the restless wind, in the fire's voice, in the foot-smoothed step. Pay heed to these things, and you will know your absent kin.\" - The Doors of the Spirit"
		end
		if defType == "Humanoid" then
			mAtt1 = 1
			mAtt2 = 2
			mSkillType = "Magical Type. Proficient in offensive magic. Learns magic at a faster rate."
			desc = "\"That House was a curse on our land for millennia, and when at last their pestilence was snuffed out, the very earth itself breathed a cloud of fire and ash in relief, bringing night to day for over a year's time.\" - Poison Song"
		end
		if defType == "Centurion" then
			mAtt1 = 0
			mAtt2 = 5
			mSkillType = "Physical Type. Weak electric and flame attacks. Guaranteed bonus Endurance."
			desc = "\"I wondered what secrets remained hidden in the maze of chambers that lay before me, defying the efforts of looters, waiting to gleam again in the light they had not seen in long eons.\" - The Ruins of Kemel-Ze"
		end
		if defType == "Spriggan" then
			mAtt1 = 1
			mAtt2 = 7
			mSkillType = "Magical Type. Proficient in supportive magic. Guaranteed bonus Luck."
			desc = "\"When the All-Maker breathed life into the creatures of the land, his Breath blew through the trees as well. Some of these trees kept a part of this life, and these are the spriggans you see today.\" - Skaal Legend"
		end
		if defType == "Goblin" then
			mAtt1 = 3
			mAtt2 = 4
			mSkillType = "Stealth Type. Proficient in Illusion magic. Learns many Abilities."
			desc = "\"Vile little beasts, but not as mindless as some may think. Some are capable of speech, and all are capable of great cunning.\" - Skaal warning regarding Rieklings, a type of Goblin"
		end
		if defType == "Domestic" then
			mAtt1 = 6
			mAtt2 = 7
			mSkillType = "Stealth Type. Learns no Spells or Abilities, but their mere presence makes you feel luckier somehow..."
			desc = "\"It is true that I call my guar herd my little family, but it is not because they are of my blood.\" - Esqoo of Dhalmora Answers Your Questions"
		end
		local text = border:findChild("kl_desc_type")
		text.text = desc
		local text2 = block2:findChild("kl_att1_type")
		text2.text = tables.capitalization[mAtt1]
		local text3 = block2:findChild("kl_att2_type")
		text3.text = tables.capitalization[mAtt2]
		local text4 = block2:findChild("kl_major_type2")
        text4.text = mSkillType
		menu:updateLayout()
    end
end


return typeModule