local ui = {}
ui.id = require("Place Stacks.ui.uiid")
local i18n = mwse.loadTranslations("Place Stacks")

---@param parent tes3uiElement
---@param id string|integer|nil
local function createAutoSizedBlock(parent, id)
	local block = parent:createBlock({ id = id })
	block.autoHeight = true
	block.autoWidth = true
	block.widthProportional = 1.0
	return block
end

--- @param parent tes3uiElement
--- @param id string|integer|nil
function ui.createLeftRightBlock(parent, id)
	local block = createAutoSizedBlock(parent, id)
	block.flowDirection = tes3.flowDirection.leftToRight
	return block
end

--- @param parent tes3uiElement
--- @param id string|integer|nil
function ui.createTopBottomBlock(parent, id)
	local block = createAutoSizedBlock(parent, id)
	block.flowDirection = tes3.flowDirection.topToBottom
	return block
end

---@param container tes3uiElement
---@param columns integer
---@param headRowLabels string[]
---@param columnChildAlignX number[]
---@return tes3uiElement
local function createTable(container, columns, headRowLabels, columnChildAlignX)
	local parent = ui.createTopBottomBlock(container)
	local head = ui.createLeftRightBlock(parent, tes3ui.registerID("TableHeadContainer"))
	head.borderLeft = 8
	head.borderRight = 8

	for i = 1, columns do
		local element = ui.createTopBottomBlock(head)
		element.childAlignX = columnChildAlignX[i]
		local text = headRowLabels[i]
		if text then
			element:createLabel({ text = text })
		end
	end

	parent:createDivider()
	local body = ui.createLeftRightBlock(parent, tes3ui.registerID("TableBodyContainer"))
	body.borderLeft = 8
	body.borderRight = 8

	for i = 1, columns do
		local element = ui.createTopBottomBlock(body)
		element.childAlignX = columnChildAlignX[i]
	end
	return parent
end

---@param container tes3uiElement
---@param containerLabel tes3uiElement
---@param transferred placeStacks.transferredTable
function ui.createTransferredPage(container, containerLabel, transferred)
	containerLabel.text = string.format(i18n("Stored in: %s"), transferred.container.object.name)

	local tableContainer = createTable(container, 2, { i18n("Items"), i18n("Amount") }, { nil, 1.0 })
	local contents = tableContainer:findChild(tes3ui.registerID("TableBodyContainer")) --[[@as tes3uiElement]]
	local items = contents.children[1]
	local amounts = contents.children[2]

	for _, record in ipairs(transferred.list) do
		items:createLabel({ text = record.name })
		amounts:createLabel({ text = tostring(record.count) })
	end
	container:getTopLevelMenu():updateLayout()
end


---@param transferredList placeStacks.transferredTable[]
function ui.createTransferNotification(transferredList)
	local menu = tes3ui.createMenu({ id = ui.id.menu, fixedFrame = true })

	menu.absolutePosAlignX = 0.5
	menu.absolutePosAlignY = 0.2
	menu.childAlignX = 0.5
	menu.childAlignY = 0.5
	menu.autoWidth = true
	menu.autoHeight = true
	menu.minWidth = 500

	-- Heading
	local headingBlock = ui.createLeftRightBlock(menu)
	headingBlock.paddingAllSides = 8

	local title = headingBlock:createLabel({ text = i18n("Transfer Results") })
	title.autoWidth = true
	title.widthProportional = 1.0
	title.color = tes3ui.getPalette(tes3.palette.headerColor)
	local containerLabel = headingBlock:createLabel({
		id = tes3ui.registerID("PlaceStacksMenu_containerLabel")
	})

	-- Main body
	local body = ui.createTopBottomBlock(menu)
	body.heightProportional = 1.0
	body.paddingLeft = 8
	body.paddingRight = 8
	body:createDivider()

	local pageIndex = "pageIndex"
	local index = 1
	local current = transferredList[index]
	local textContainer = ui.createTopBottomBlock(body, ui.id.textContainer)
	textContainer.borderLeft = 8
	textContainer.borderRight = 8
	textContainer:setLuaData(pageIndex, index)
	ui.createTransferredPage(textContainer, containerLabel, current)

	-- Buttons
	body:createDivider()
	local onlyOnePage = #transferredList == 1
	local buttonsContainer = ui.createLeftRightBlock(body)
	buttonsContainer.childAlignX = 0.5
	local previous = buttonsContainer:createButton({
		text = tes3.findGMST(tes3.gmst.sPrev).value
	})
	previous.visible = not onlyOnePage
	previous:registerAfter(tes3.uiEvent.mouseClick, function(e)
		local index = textContainer:getLuaData(pageIndex)
		index = table.wrapindex(transferredList, index - 1)
		textContainer:setLuaData(pageIndex, index)

		textContainer:destroyChildren()
		ui.createTransferredPage(textContainer, containerLabel, transferredList[index])
	end)
	local next = buttonsContainer:createButton({
		text = tes3.findGMST(tes3.gmst.sNext).value
	})
	next.visible = not onlyOnePage
	next:registerAfter(tes3.uiEvent.mouseClick, function(e)
		local index = textContainer:getLuaData(pageIndex)
		index = table.wrapindex(transferredList, index + 1)
		textContainer:setLuaData(pageIndex, index)

		textContainer:destroyChildren()
		ui.createTransferredPage(textContainer, containerLabel, transferredList[index])
	end)
	local close = buttonsContainer:createButton({
		text = tes3.findGMST(tes3.gmst.sClose).value,
		id = ui.id.closeButton
	})
	close:registerAfter(tes3.uiEvent.mouseClick, function(e)
		menu:destroy()
		tes3ui.leaveMenuMode()
	end)


	body:getTopLevelMenu():updateLayout()
	tes3ui.enterMenuMode(ui.id.menu)
end

return ui
