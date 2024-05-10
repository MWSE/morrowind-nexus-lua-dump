--[[
Makes MCM filter/Console text input clear by clicking the input text space.
If you have UIExpansion installed also works with UI Expansion text input filters.
]]

local tes3_uiElementType_textInput = tes3.uiElementType.textInput

local function afterTextInputParentMouseClick(e)
	local parent = e.source
	local children = parent.children
	for i = #children, 1, -1 do
		local child = children[i]
		---mwse.log('i = %s, child = %s', i, child.name)
		if child.name == 'UIEXP:SearchClearIcon' then
			---mwse.log([[afterTextInputParentMouseClick(e) "%s":triggerEvent('mouseClick')]], child.name)
			child:triggerEvent('mouseClick')
			break
		elseif child.type == tes3_uiElementType_textInput then
			---mwse.log([[afterTextInputParentMouseClick(e) "%s".text = '']], child.name)
			child.text = ''
			child:triggerEvent('textCleared')
			break
		end
	end
	parent:getTopLevelMenu():updateLayout()
end

local function registerAfterTextInputParentMouseClick(root)
	for el in table.traverse({root}) do
		if el.type == tes3_uiElementType_textInput then
			---mwse.log('registerAfterParent(root) el = %s', el.name)
			el.parent:registerAfter('mouseClick', afterTextInputParentMouseClick)
		end
	end
end

local idMWSEmodConfigMenu = tes3ui.registerID('MWSE:ModConfigMenu')

local function checkRegister()
	local menu = tes3ui.findMenu(idMWSEmodConfigMenu)
	if not menu then
		return
	end
	registerAfterTextInputParentMouseClick(menu)
end

local function afterMouseClickMCMcontainer()
	timer.start({duration = 0.2, type = timer.real,	callback = checkRegister})
end

local idMenuOptions_MCM_container = tes3ui.registerID('MenuOptions_MCM_container')

local function uiActivatedOptions(e)
	if not e.newlyCreated then
		return
	end
	local el = e.element:findChild(idMenuOptions_MCM_container)
	if not el then
		return
	end
	el:registerAfter('mouseClick', afterMouseClickMCMcontainer)
end

local function uiActivated(e)
	if not e.newlyCreated then
		return
	end
	---mwse.log('uiActivated(e) e.element = %s', e.element.name)
	registerAfterTextInputParentMouseClick(e.element)
end

local function initialized()
	---mwse.log('Click Clears Input/initialized')
	local menus = {'MenuBarter','MenuConsole','MenuContents','MenuEnchantment','MenuInventory',
'MenuInventorySelect','MenuMagic','MenuMagicSelect','MenuName','MenuSave','MenuSpellmaking'}
	for i = 1, #menus do
		event.register('uiActivated', uiActivated, {filter = menus[i], priority = -100000})
	end
	event.register('uiActivated', uiActivatedOptions, {filter = 'MenuOptions'})
end
event.register('initialized', initialized, {priority = -100000})
