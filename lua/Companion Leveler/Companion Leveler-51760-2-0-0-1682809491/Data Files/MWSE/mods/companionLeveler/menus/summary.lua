----Initialize----------------------------------------------------------------------------------------------------------
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")

local sumr = {}


function sumr.createWindow(reference)
	sumr.id_menu = tes3ui.registerID("kl_sum_menu")
	sumr.id_pane = tes3ui.registerID("kl_sum_pane")
	sumr.id_ok = tes3ui.registerID("kl_sum_ok")
	sumr.id_image = tes3ui.registerID("kl_sum_img")
	log = logger.getLogger("Companion Leveler")
	log:debug("Build menu initialized.")

	if (reference) then
		sumr.reference = reference
	end

	if (tes3ui.findMenu(sumr.id_menu) ~= nil) then
		return
	end

	local menu = tes3ui.createMenu { id = sumr.id_menu, fixedFrame = true }

	-- Create layout
	local input_label = menu:createLabel { text = "Party Level Summary:" }
	input_label.borderBottom = 5

	local pane_block = menu:createBlock { id = "pane_block_sum" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	local border = pane_block:createThinBorder {}
	border.positionX = 4
	border.positionY = -4
	border.width = 220
	border.height = 280
	border.borderAllSides = 4
	border.borderTop = 54
	border.paddingAllSides = 4

	local pane = border:createVerticalScrollPane({ id = sumr.id_pane })
	pane.height = 290
	pane.width = 220
	pane.positionX = 4
	pane.positionY = -4
	pane.widget.scrollbarVisible = false
	pane.wrapText = true

	local border2 = pane_block:createThinBorder { id = "kl_border2_sum" }
	border2.positionX = 204
	border2.positionY = 0
	border2.width = 572
	border2.height = 380
	border2.borderAllSides = 5
	border2.paddingAllSides = 4
	border2.borderRight = 4
	border2.wrapText = true

	local modData = func.getModData(reference)
	local class = tes3.findClass(modData.class)
	if class == nil then
		class = tes3.findClass("Nightblade")
	end
	local initSum = border2:createLabel({ text = modData.summary, id = "kl_text_sum" })
	initSum.color = { 1.0, 1.0, 1.0 }

	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 1.0

	local limit = modData.level
	if limit > 100 then
		limit = 100
	end
	local initMsg = button_block:createLabel({ text = tables.npcMessage[limit], id = "kl_msg_sum" })
	initMsg.borderAllSides = 5
	local button_ok = button_block:createButton { id = sumr.id_ok, text = "Done" }

	-- Events
	button_ok:register(tes3.uiEvent.mouseClick, sumr.onOK)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(sumr.id_menu)
end

----Events-------------------------------------------------------
function sumr.onSelectN(i, reference)
	local menu = tes3ui.findMenu(sumr.id_menu)
	local pane = menu:findChild(sumr.id_pane)
	if (menu) then
		local modData = func.getModData(reference)
		local block = menu:findChild("pane_block_sum")
		local text = block:findChild("kl_text_sum")
		local id = pane:findChild("sumSelect_" .. i .. "")
		for n = 1, 10 do
			local id2 = pane:findChild("sumSelect_" .. n .. "")
			local id3 = pane:findChild("sumSelectC_" .. n .. "")
			if (id2 and id2.widget.state == 4) then
				id2.widget.state = 1
			end
			if (id3 and id3.widget.state == 4) then
				id3.widget.state = 1
			end
		end
		id.widget.state = 4
		text.text = modData.summary
		menu:updateLayout()
	end
end

function sumr.onSelectC(i, reference)
	local menu = tes3ui.findMenu(sumr.id_menu)
	local pane = menu:findChild(sumr.id_pane)
	if (menu) then
		local modData = func.getModData(reference)
		local block = menu:findChild("pane_block_sum")
		local text = block:findChild("kl_text_sum")
		local id = pane:findChild("sumSelectC_" .. i .. "")
		for n = 1, 10 do
			local id2 = pane:findChild("sumSelectC_" .. n .. "")
			local id3 = pane:findChild("sumSelect_" .. n .. "")
			if (id2 and id2.widget.state == 4) then
				id2.widget.state = 1
			end
			if (id3 and id3.widget.state == 4) then
				id3.widget.state = 1
			end
		end
		id.widget.state = 4
		text.text = modData.summary
		menu:updateLayout()
	end
end

function sumr.onOK(e)
	local menu = tes3ui.findMenu(sumr.id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

return sumr
