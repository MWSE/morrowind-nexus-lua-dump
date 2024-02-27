--[[
Player Made Magic Rename
CTRL + Click in to rename a player made spell or enchanted item from player magic menu
CTRL + Equip on paperdoll to rename a player made constant enchanted item from player inventory menu
]]

local author = 'abot'
local modName = 'PMMR'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local defaultConfig = {
disabled = false,
renameMessage = true,
logLevel = 0,
}

local config = mwse.loadConfig(configName, defaultConfig)

 -- updated in modConfigReady()
local disabled = config.disabled
local logLevel = config.logLevel

local renameBoxId = tes3ui.registerID('renameBoxId')
local renameBoxInputId = tes3ui.registerID('renameBoxInputId')
local renameBoxButtonOkId = tes3ui.registerID('renameBoxButtonOkId')
local renameBoxButtonCancelId = tes3ui.registerID('renameBoxButtonCancelId')
local menuMagicId = tes3ui.registerID('MenuMagic')

local obj, propertyId, currElement, currMenu

local function onOK(e)
	local menu = e.source:getTopLevelMenu()
	local input = menu:findChild(renameBoxInputId)
	if input then
		local text = input.text
		if text then
			if not (text == '') then
				if not (text == obj.name) then
					if config.renameMessage then
						tes3ui.showNotifyMenu('"%s"\nrenamed to\n"%s"', obj.name, text)
					end
					obj.name = text
					obj.modified = true
					if currElement then
						currElement.text = text
						currMenu = currElement:getTopLevelMenu()
						timer.start({duration = 0.2, type = timer.real,
							callback = function ()
								currElement.parent:updateLayout()
								currMenu:updateLayout()
							end
						})
					--[[else
						timer.start({duration = 0.2, type = timer.real,
							callback = function (
							)
								tes3.updateInventoryGUI({reference = tes3.player})
							end
						})]]
					end
				end
			end
		end
	end
	menu:destroy()
end

local function onCancel(e)
	local menu = e.source:getTopLevelMenu()
	---tes3ui.leaveMenuMode()
	menu:destroy()
end

local function renameBox()
	-- thanks Hrnchamd as usual
	if logLevel > 0 then
		mwse.log('%s: renameBox() obj.id = %s, obj.name = %s', modPrefix, obj.id, obj.name)
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

local tes3_enchantmentType_constant = tes3.enchantmentType.constant

local function equip(e)
	if not (e.reference == tes3.player) then
		return
	end
	local o = e.item
	local ench = o.enchantment
	if not ench then
		return
	end
	local castType = ench.castType
	if not (castType == tes3_enchantmentType_constant) then
		return
	end
	if not tonumber(o.id) then
		return
	end

	if not tes3.worldController.inputController:isControlDown() then
		return
	end

	if logLevel > 1 then
		mwse.log('%s: o.id = %s, o.name = %s', modPrefix, o.id, o.name)
	end

	obj = o
	currElement = nil
	renameBox()
	return false
end

local function renameAction(e)
	if logLevel > 1 then
		mwse.log('%s: renameAction(e.sorce.id = "%s")', modPrefix, e.source.id)
	end
	if not tes3.worldController.inputController:isControlDown() then
		return false
	end
	local el = e.source
	local o = el:getPropertyObject(propertyId)
	if not o then
		return false
	end
	obj = o
	currElement = el
	renameBox()
	return true
end

local sMagicMenu_Spell = 'MagicMenu_Spell'
local sMagicMenu_object = 'MagicMenu_object'

local function mouseClickSpell(e)
	---tes3ui.showNotifyMenu('click')
	propertyId = sMagicMenu_Spell
	if renameAction(e) then
		return false
	end
end

local function mouseClickItem(e)
	---tes3ui.showNotifyMenu('click')
	propertyId = sMagicMenu_object
	if renameAction(e) then
		return false
	end
end

local function setAction(elem, propId)
	if not elem then
		return
	end
	local children = elem.children
	if not children then
		return
	end
	local o
	--[[if logLevel > 0 then
		mwse.log('%s: setAction("%s", "%s")', modPrefix, elem.name, propId)
	end]]
	for _, el in pairs(children) do
		if el then
			o = el:getPropertyObject(propId)
			if o then
				---if o.id then
				---if tonumber(o.id) then
				if string.match(o.id, "^%d+$") then
					--[[if logLevel > 1 then
						mwse.log('%s: o.id = %s, o.name = %s, el.text = %s', modPrefix, o.id, o.name, el.text)
					end]]
					if propId == sMagicMenu_Spell then
						if not el:getPropertyBool('ab01mc') then
							el:setPropertyBool('ab01mc', true)
							---mwse.log("%s:registerBefore('mouseClick', mouseClickSpell)", el.id)
							el:registerBefore('mouseClick', mouseClickSpell)
						end
					elseif propId == sMagicMenu_object then
						if not el:getPropertyBool('ab01mc') then
							el:setPropertyBool('ab01mc', true)
							---mwse.log("%s:registerBefore('mouseClick', mouseClickItem)", el.id)
							el:registerBefore('mouseClick', mouseClickItem)
						end
					end
				end
			end
		end
	end
end

local magicMenu_spell_namesId = tes3ui.registerID('MagicMenu_spell_names')
local magicMenu_item_namesId = tes3ui.registerID('MagicMenu_item_names')

local function updateMenuMagic(el)
	if disabled then
		return
	end
	local magicMenu_spell_names = el:findChild(magicMenu_spell_namesId)
	setAction(magicMenu_spell_names, sMagicMenu_Spell)
	local magicMenu_item_names = el:findChild(magicMenu_item_namesId)
	setAction(magicMenu_item_names, sMagicMenu_object)
end

local function beforeFocusMenuMagic(e)
	if logLevel > 1 then
		mwse.log('%s: beforeFocusMenuMagic() updateMenuMagic()', modPrefix)
	end
	updateMenuMagic(e.source)
end

local function uiActivatedMenuMagic(e)
	if e.newlyCreated then
		local menu = e.element
		menu:registerBefore('focus', beforeFocusMenuMagic)
 	end
end	

local function uiActivatedMagicMaker(e)
	if not e.newlyCreated then
		return
	end
	e.element:registerAfter('destroy',
		function ()
			local menu = tes3ui.findMenu(menuMagicId)
			if menu then
				updateMenuMagic(menu)
			end
		end
	)
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		disabled = config.disabled
		logLevel = config.logLevel
		mwse.saveConfig(configName, config, {indent = false})
	end

	local preferences = template:createSideBarPage({
		label='Preferences',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.0
			self.elements.sideToSideBlock.children[2].widthProportional = 1.0
		end
	})

local info = [[CTRL + Click to rename a player made spell or enchanted item from player magic menu.
CTRL + Equip on paperdoll to rename a player made constant enchanted item from player inventory menu.
]]

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = info})

	local controls = preferences:createCategory({label = "Player Made Magic Rename"})

	controls:createYesNoButton({
		label = 'Disabled',
		description = 'A toggle to enable/disable the mod effects. Default: No.',
		variable = createConfigVariable('disabled')
	})
	controls:createYesNoButton({
		label = 'Rename message',
		description = 'Display a message after renaming. Default: Yes.',
		variable = createConfigVariable('renameMessage')
	})
	controls:createDropdown({
		label = "Logging level:",
		options = {
			{ label = "0. Minimum", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
		},
		variable = createConfigVariable("logLevel"),
		description = "Default: 0. Minimum."
	})
	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)

event.register('initialized', function ()
	event.register('uiActivated', uiActivatedMenuMagic, {filter = 'MenuMagic'})
	event.register('uiActivated', uiActivatedMagicMaker, {filter = 'MenuSpellmaking'})
	event.register('uiActivated', uiActivatedMagicMaker, {filter = 'MenuEnchantment'})
	event.register('equip', equip)
end)
