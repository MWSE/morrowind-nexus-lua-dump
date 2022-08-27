local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.common")


local classModule = {}


function classModule.classChange(reference)
    --Initialize IDs
    classModule.id_menu = tes3ui.registerID("kl_class_menu")
    classModule.id_pane = tes3ui.registerID("kl_class_pane")
    classModule.id_ok = tes3ui.registerID("kl_class_ok")
	classModule.id_image = tes3ui.registerID("kl_class_image")
	log = logger.getLogger("Companion Leveler")
    log:debug("Class menu initialized.")

    if (reference) then
            classModule.reference = reference
    end

    if (tes3ui.findMenu(classModule.id_menu) ~= nil) then
        return
    end
    log:debug("Class menu triggered.")

    -- Create window and frame
    local menu = tes3ui.createMenu{ id = classModule.id_menu, fixedFrame = true }

    -- Create layout
	local name = reference.object.name
	local modData = func.getModData(reference)
	local cClass = tes3.findClass(modData.class)
    local input_label = menu:createLabel{ text = "Select " .. name .. "'s Class:" }
    input_label.borderBottom = 5

    local pane_block = menu:createBlock{ id = "pane_block" }
    pane_block.autoWidth = true
    pane_block.autoHeight = true

    local border = pane_block:createThinBorder{ id = "kl_border" }
	border.positionX = 4
	border.positionY = -4
    border.width = 190
    border.height = 128
    border.borderAllSides = 4
	border.paddingAllSides = 4

	local border2 = pane_block:createThinBorder{ id = "kl_border2" }
	border2.positionX = 202
	border2.positionY = 0
    border2.width = 262
    border2.height = 134
	border2.paddingAllSides = 2

	local path = cClass.image
	if path == nil then
		local default = tes3.findClass("Nightblade")
		path = default.image
	end
	local image = border2:createImage({ path = path, id = classModule.id_image })
	image.height = 128
	image.width = 256

	local pane = border:createVerticalScrollPane{ id = classModule.id_pane }
	pane.height = 128
	pane.width = 190
	pane.positionX = 4
	pane.positionY = -4
	pane.widget.scrollbarVisible = true

	local defclass = reference.object.class
	local a = pane:createTextSelect{ text = "Default: " .. defclass.name .. "", id = "cChangeB_0" }
	a:register("mouseClick", function(e) classModule.defSelect(e) end)
	local line = pane:createDivider()
	for i = 1, 38 do
        local b = pane:createTextSelect{ text = tables.classes[i], id = "cChangeB_" .. i .. "" }
        b:register("mouseClick", function(e) classModule.onSelect(i) end)
    end

	local text_block = menu:createBlock{ id = "text_block" }
	text_block.positionX = 10
	text_block.positionY = -146
	text_block.width = 470
	text_block.height = 116
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
	major_block.width = 155
	major_block.height = 108
	major_block.borderAllSides = 4
	major_block.flowDirection = "top_to_bottom"

	local minor_block = text_block:createBlock{}
	minor_block.positionX = 320
	minor_block.positionY = -4
	minor_block.width = 155
	minor_block.height = 108
	minor_block.borderAllSides = 4
	minor_block.flowDirection = "top_to_bottom"

	local kl_spec = spec_block:createLabel({ text = "Specialization:", id = "kl_spec" })
	kl_spec.color = {1.0, 1.0, 1.0}
	local kl_spec1 = spec_block:createLabel({ text = tables.capitalization2[cClass.specialization], id = "kl_spec1" })

	local kl_att = spec_block:createLabel({ text = "Favored Attributes:", id = "kl_att" })
	kl_att.color = {1.0, 1.0, 1.0}
	local mAttributes = cClass.attributes
	local mAtt1 = mAttributes[1]
	local mAtt2 = mAttributes[2]
	local kl_att1 = spec_block:createLabel({ text = "" .. tables.capitalization[mAtt1] .. "", id = "kl_att1" })
	local kl_att2 = spec_block:createLabel({ text = "" .. tables.capitalization[mAtt2] .. "", id = "kl_att2" })

	local kl_major = major_block:createLabel({ text = "Major Skills:", id = "kl_major" })
	kl_major.color = {1.0, 1.0, 1.0}
	local mSkills = cClass.majorSkills
	for i = 1, 7 do
        local t = major_block:createLabel{ text = tes3.skillName[mSkills[i]], id = "kl_major" .. i .. "" }
    end

	local kl_minor = minor_block:createLabel({ text = "Minor Skills:", id = "kl_minor" })
	kl_minor.color = {1.0, 1.0, 1.0}
	local minSkills = cClass.minorSkills
	for i = 1, 7 do
        local t = minor_block:createLabel{ text = tes3.skillName[minSkills[i]], id = "kl_minor" .. i .. "" }
    end

    local button_block = menu:createBlock{}
    button_block.widthProportional = 1.0  -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0  -- right content alignment

    local button_ok = button_block:createButton{ id = classModule.id_ok, text = tes3.findGMST("sOK").value }

    -- Events
    menu:register(tes3.uiEvent.keyEnter, classModule.onOK)
    button_ok:register(tes3.uiEvent.mouseClick, classModule.onOK)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(classModule.id_menu)
end


----Events----------------------------------------------------------------------------------------------------------
function classModule.onOK(e)
    local menu = tes3ui.findMenu(classModule.id_menu)
	local modData = func.getModData(classModule.reference)
    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroy()
		log:info("" .. classModule.reference.object.name .. " changed to " .. modData.class .. ".")
        tes3.messageBox{ message = "" .. classModule.reference.object.name .. " changed to " .. modData.class .. "." }
    end
end

function classModule.onSelect(i)
    local menu = tes3ui.findMenu(classModule.id_menu)
	local pane = menu:findChild(classModule.id_pane)
    if (menu) then
		local modData = func.getModData(classModule.reference)
        local cChange = tables.classes[i]
		local block = menu:findChild("pane_block")
		local block2 = menu:findChild("text_block")
		local border = block:findChild("kl_border2")
		local image = border:findChild(classModule.id_image)
		image:destroy()
		local cClass = tes3.findClass(cChange)
		local path = cClass.image
		if path == nil then
			local default = tes3.findClass("Nightblade")
			path = default.image
		end
		border:createImage({ path = path, id = classModule.id_image })
		log:debug("" .. modData.class .. " changed to " .. cChange .. ".")
		modData.class = cChange
		local id = pane:findChild("cChangeB_" .. i .. "")
		local idDef = pane:findChild("cChangeB_0")
		if idDef.widget.state == 4 then
			idDef.widget.state = 1
		end
		for n = 1, 38 do
			local id2 = pane:findChild("cChangeB_" .. n .. "")
			if id2.widget.state == 4 then
				id2.widget.state = 1
			end
		end
		id.widget.state = 4
		local spec = cClass.specialization
		local sText = block2:findChild("kl_spec1")
		sText.text = tables.capitalization2[spec]
		local mAttributes = cClass.attributes
		for n = 1, 2 do
			local text = block2:findChild("kl_att" .. n .. "")
			text.text = tables.capitalization[mAttributes[n]]
		end
		local mSkills = cClass.majorSkills
		for n = 1, 7 do
			local text = block2:findChild("kl_major" .. n .. "")
        	text.text = tes3.skillName[mSkills[n]]
    	end
		local minSkills = cClass.minorSkills
		for n = 1, 7 do
			local text = block2:findChild("kl_minor" .. n .. "")
        	text.text = tes3.skillName[minSkills[n]]
    	end
		menu:updateLayout()
    end
end

function classModule.defSelect(e)
    local menu = tes3ui.findMenu(classModule.id_menu)
	local pane = menu:findChild(classModule.id_pane)
    if (menu) then
		local ref = classModule.reference
		local class = ref.object.class
		local block = menu:findChild("pane_block")
		local block2 = menu:findChild("text_block")
		local border = block:findChild("kl_border2")
		local image = border:findChild(classModule.id_image)
		image:destroy()
		local path = class.image
		if path == nil then
			local default = tes3.findClass("Nightblade")
			path = default.image
		end
		border:createImage({ path = path, id = classModule.id_image })
		local modData = func.getModData(classModule.reference)
		log:debug("" .. modData.class .. " changed back to " .. class.name .. ".")
		modData.class = class.name
		local id = pane:findChild("cChangeB_0")
		for n = 1, 38 do
			local id2 = pane:findChild("cChangeB_" .. n .. "")
			if id2.widget.state == 4 then
				id2.widget.state = 1
			end
		end
		id.widget.state = 4
		local spec = class.specialization
		local sText = block2:findChild("kl_spec1")
		sText.text = tables.capitalization2[spec]
		local mAttributes = class.attributes
		for n = 1, 2 do
			local text = block2:findChild("kl_att" .. n .. "")
			text.text = tables.capitalization[mAttributes[n]]
		end
		local mSkills = class.majorSkills
		for n = 1, 7 do
			local text = block2:findChild("kl_major" .. n .. "")
        	text.text = tes3.skillName[mSkills[n]]
    	end
		local minSkills = class.minorSkills
		for n = 1, 7 do
			local text = block2:findChild("kl_minor" .. n .. "")
        	text.text = tes3.skillName[minSkills[n]]
    	end
		menu:updateLayout()
    end
end


return classModule