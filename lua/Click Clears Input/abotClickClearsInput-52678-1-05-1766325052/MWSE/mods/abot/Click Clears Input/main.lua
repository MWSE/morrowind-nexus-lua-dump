--[[
Makes MCM filter/Console text input clear by clicking the input text space.
If you have UIExpansion installed also works with UI Expansion text input filters.
]]

local tes3_uiElementType_textInput = tes3.uiElementType.textInput

-- some magic code from Hrn. I don't know how it works, but it does the trick!
-- the first function disables the JournalCloseKeybind, which is the one keybind not caught by tes3ui.acquireTextInput(element)
-- the second function reenables that keybind. If you use this in your own mod, make sure to reenable the keybind when you are done
local function disableJournalKeybind()
---@diagnostic disable-next-line: undefined-field
	mwse.memory.writeByte{address = 0x41AF6D, byte = 0xEB}
end

local function enableJournalKeybind()
---@diagnostic disable-next-line: undefined-field
	mwse.memory.writeByte{address = 0x41AF6D, byte = 0x74}
end

local function menuClose()
	enableJournalKeybind()
	event.unregister('menuClose', menuClose)
end

local function afterTextInputParentMouseClick(e)
	local parent = e.source
	local children = parent.children
	local changed = false
	for i = #children, 1, -1 do
		local child = children[i]
		if child.type == tes3_uiElementType_textInput then
			---mwse.log([[afterTextInputParentMouseClick(e) "%s".text = '']], child.name)
			---tes3ui.acquireTextInput(child)

			-- try and fix buggy UIExpansion placeholder text
			local widget = child.widget
			if widget then
				---mwse.log('i = %s, child = %s widget:clear()', i, child.name)
				changed = true
				widget.eraseOnFirstKey = true
				local placeHoldingText = widget:getPlaceholdingText()
				local hidePlaceHoldingText = placeHoldingText
					and (placeHoldingText:len() > 0)
				if hidePlaceHoldingText then
					widget:setPlaceholdingText('')
				end
				widget:clear()
				if hidePlaceHoldingText then
					widget:setPlaceholdingText(placeHoldingText)
				end
			end
		elseif child.name == 'UIEXP:SearchClearIcon' then
			---mwse.log([[afterTextInputParentMouseClick(e) "%s":triggerEvent('mouseClick')]], child.name)
			changed = true
			child:triggerEvent('mouseClick')
		end
	end
	if changed then
		local menu = parent:getTopLevelMenu()
		disableJournalKeybind()
		if not event.isRegistered('menuClose', menuClose) then
			event.register('menuClose', menuClose)
		end
		menu:updateLayout()
	end
end

local function registerAfterTextInputParentMouseClick(root)
	for el in table.traverse({root}) do
		if el.type == tes3_uiElementType_textInput then
			---mwse.log('registerAfterParent(root) el = %s', el.name)
			local widget = el.widget
			if widget then
				widget.eraseOnFirstKey = true
			end
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

-- set in initialized()
local menuController

-- ripped (but search placeHolder fixed) from UI expansion
--- @param e keyDownEventData
local function onKeyDownCtrlV(e)
	if not e.isControlDown then
		return
	end
	--assert(menuController == tes3.worldController.menuController)
	local inputController = menuController.inputController
	local inputFocus = inputController.textInputFocus
	if not (
		inputFocus
		and inputFocus.visible
	) then
		return
	end
	local clipboardText = os.getClipboardText()
	if not clipboardText then
		return
	end
	clipboardText = clipboardText:gsub('[|\r\n]', '')
	if clipboardText:len() <= 0 then
		return
	end

	inputController:flushBufferedTextEvents()
	local inputFocusText = inputFocus.rawText

	-- try and fix buggy UIExpansion placeholder text
	local widget = inputFocus.widget
	if widget then
		local placeholdingText = widget:getPlaceholdingText()
		if placeholdingText
		and (placeholdingText:len() > 0) then
			inputFocusText = inputFocusText:gsub('^'..placeholdingText, '')
		end
	end
	
	local cursorPosition = inputFocusText:find('|', 1, true) or 1
	inputFocus.text = string.insert(inputFocusText, clipboardText, cursorPosition - 1)
	inputFocus:getTopLevelMenu():updateLayout()
	---inputFocus:triggerEvent("keyPress")
	return false
end

event.register('initialized', function ()
	---mwse.log('Click Clears Input/initialized')
	local menus = {'MenuBarter','MenuConsole','MenuContents','MenuEnchantment','MenuInventory',
'MenuInventorySelect','MenuMagic','MenuMagicSelect','MenuName','MenuSave','MenuSpellmaking'}
	for i = 1, #menus do
		event.register('uiActivated', uiActivated, {filter = menus[i], priority = -100000})
	end
	event.register('uiActivated', uiActivatedOptions, {filter = 'MenuOptions'})

	menuController = tes3.worldController.menuController

	event.register('keyDown', onKeyDownCtrlV, {filter = tes3.scanCode.v, prority = 100000})
end, {priority = -100000, doOnce = 'true'})
