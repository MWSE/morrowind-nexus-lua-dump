
local common = require("Virnetch.enchantmentServicesRedone.common")

local menu = tes3ui.findMenu(common.GUI_ID.TranscriptionMenu)

local nameBlock = menu:createBlock({ id = common.GUI_ID.TranscriptionMenu_nameBlock })
nameBlock.autoHeight = true
nameBlock.widthProportional = 1.0
nameBlock.childAlignY = 0.5
nameBlock.borderAllSides = 6
nameBlock.borderLeft = 5

	local nameLabel = nameBlock:createLabel({ text = tes3.findGMST(tes3.gmst.sName).value })
	nameLabel.borderAllSides = 6
	nameLabel.color = common.palette.headerColor
	nameLabel:register(tes3.uiEvent.help, function()
		common.tooltip(common.i18n("service.transcription.mainMenu.customNameTooltip"), true)
	end)

	local nameInputBorder = nameBlock:createThinBorder()
	nameInputBorder.widthProportional = 1.0
	nameInputBorder.height = 30
	nameInputBorder.childAlignY = 0.5
	nameInputBorder.paddingAllSides = 4

		local nameInput = nameInputBorder:createTextInput({ id = common.GUI_ID.TranscriptionMenu_nameInput })
		nameInput.widget.lengthLimit = 31
		nameInput.widget.eraseOnFirstKey = false
		nameInput.borderLeft = 5
		nameInput.borderRight = 5
		nameInputBorder:register(tes3.uiEvent.mouseClick, function()
			tes3ui.acquireTextInput(nameInput)
		end)

		tes3ui.acquireTextInput(nameInput)

return nameBlock