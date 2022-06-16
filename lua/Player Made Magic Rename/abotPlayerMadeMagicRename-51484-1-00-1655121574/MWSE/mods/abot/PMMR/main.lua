--[[
Player Made Magic Rename
CTRL+click to rename a player made spell or enchanted item
]]

local author = 'abot'
local modName = 'PMMR'
local modPrefix = author .. '/' .. modName
---local mcmName = author .. "'s " .. modName

local logLevel = 0

local renameBoxId = tes3ui.registerID('renameBoxId')
local renameBoxInputId = tes3ui.registerID('renameBoxInputId')
local renameBoxButtonOkId = tes3ui.registerID('renameBoxButtonOkId')
local renameBoxButtonCancelId = tes3ui.registerID('renameBoxButtonCancelId')


local obj -- current object to be renamed

local function onOK(e)
	local menu = e.source:getTopLevelMenu()
	local text = menu:findChild(renameBoxInputId).text
---@diagnostic disable-next-line: redundant-parameter
	tes3ui.leaveMenuMode(menu.id)
	menu:destroy()
	if not text then
		return
	end
	if string.len(text) <= 0 then
		return
	end
	if text == obj.name then
		return
	end
	tes3.messageBox('"%s"\nrenamed to\n"%s"', obj.name, text)
	obj.name = text
	tes3.updateMagicGUI({reference = tes3.player})
	tes3.updateInventoryGUI({reference = tes3.player})
end

local function onCancel(e)
	local menu = e.source:getTopLevelMenu()
---@diagnostic disable-next-line: redundant-parameter
	tes3ui.leaveMenuMode(menu.id)
	menu:destroy()
end

local function renameBox()
	-- thanks Hrnchamd as usual
	if logLevel > 0 then
		mwse.log('%s: renameBox obj.id = %s, obj.name = %s', modPrefix, obj.id, obj.name)
	end
	local menu = tes3ui.createMenu({id = renameBoxId, fixedFrame = true})
	menu.minWidth = 300
	menu.alignX = 0.5
	menu.alignY = 0
	menu.autoHeight = true
	menu.alpha = 1.0
	local input_label = menu:createLabel({text = 'Rename to:'})
	input_label.borderBottom = 5

	local input_block = menu:createBlock({})
	input_block.width = menu.minWidth
	input_block.autoHeight = true
	input_block.childAlignX = 0.5

	local border = input_block:createThinBorder({})
	border.width = menu.minWidth
	border.height = 30
	border.childAlignX = 0.5
	border.childAlignY = 0.5

	-- and good riddance of that f* createTextField
	local input = border:createTextInput({id = renameBoxInputId})
	input.text = obj.name
	input.borderLeft = 5
	input.borderRight = 5
	input.widget.lengthLimit = 31
	input.widget.eraseOnFirstKey = true

	local button_block = menu:createBlock({})
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 1.0

	local button_cancel = button_block:createButton({id = renameBoxButtonCancelId,
		text = tes3.findGMST('sCancel').value})

	local button_ok = button_block:createButton({id = renameBoxButtonOkId,
		text = tes3.findGMST('sOK').value})

	button_cancel:register('mouseClick', onCancel)
	menu:register('keyEnter', onOK) -- only works when text input is not captured
	input:register('keyEnter', onOK)
	button_ok:register('mouseClick', onOK)

	menu:updateLayout()
	tes3ui.enterMenuMode(renameBoxId)
	tes3ui.acquireTextInput(input) -- automatically reset when menu is closed
end

local function click(e, propertyId)
	if not tes3.worldController.inputController:isControlDown() then
		return
	end
	local el = e.source
	local o = el:getPropertyObject(propertyId)
	if o then
		obj = o
		renameBox()
	end
end

local sMagicMenu_Spell = 'MagicMenu_Spell'
local sMagicMenu_object = 'MagicMenu_object'

local function mouseClickSpell(e)
	click(e, sMagicMenu_Spell)
	return false
end

local function mouseClickItem(e)
	click(e, sMagicMenu_object)
	return false
end

local function initialize(elem, propertyId)
	if not elem then
		return
	end
	local children = elem.children
	if not children then
		return
	end
	if #children <= 0 then
		return
	end
	local o
	for _, el in pairs(children) do
		o = el:getPropertyObject(propertyId)
		if o then
			if o.id then
				if tonumber(o.id) then
					if logLevel > 0 then
						mwse.log('%s: o.id = %s, o.name = %s, el.text = %s', modPrefix, o.id, o.name, el.text)
					end
					if propertyId == sMagicMenu_Spell then
						el:registerBefore('mouseClick', mouseClickSpell)
					else
						el:registerBefore('mouseClick', mouseClickItem)
					end
				end
			end
		end
	end
end

local magicMenu_spell_namesId = tes3ui.registerID('MagicMenu_spell_names')
local magicMenu_item_namesId = tes3ui.registerID('MagicMenu_item_names')

local function uiActivatedMenuMagic(e)
	---tes3.messageBox('uiActivatedMenuMagic')
	if not e.newlyCreated then
		return
	end
	if logLevel > 0 then
		tes3.messageBox("Ctrl+click to rename\na player made spell\nor enchanted item")
	end
	local el = e.element
	local magicMenu_spell_names = el:findChild(magicMenu_spell_namesId)
	initialize(magicMenu_spell_names, sMagicMenu_Spell)
	local magicMenu_item_names = el:findChild(magicMenu_item_namesId)
	initialize(magicMenu_item_names, sMagicMenu_object)
end
event.register('uiActivated', uiActivatedMenuMagic, {filter = 'MenuMagic'})