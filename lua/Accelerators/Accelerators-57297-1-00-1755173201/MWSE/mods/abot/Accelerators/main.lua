local defaultConfig = {
modEnabled = true,
invalidChars = '',
logLevel = 0
}

local author = 'abot'
local modName = 'Accelerators'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local modEnabled, invalidChars
local logLevel, logLevel1, logLevel2, logLevel3

local invalidCharsDict = {}

-- cached for speed
local tes3_uiElementType_button = tes3.uiElementType.button
local tes3_scanCode = tes3.scanCode
local tes3_getKeyName = tes3.getKeyName
---local tes3ui_findHelpLayerMenu = tes3ui.findHelpLayerMenu

local function getActiveTextInput(includeDisabled)
	local worldController = tes3.worldController
	---assert(worldController)
	local menuController = worldController.menuController
	---assert(menuController)
	local inputController = menuController.inputController
	---assert(inputController)
	local el = inputController.textInputFocus
	if el
	and el.visible then
		if includeDisabled then
			return el
		elseif (not el.disabled) then
			return el
		end
	end
end

---@param e keyDownEventData
local function keyDown(e)
	if not e.isAltDown then
		return
	end
	if not tes3.menuMode() then
		return
	end
	if not modEnabled then
		return
	end
	local menu = tes3ui.getMenuOnTop()
	if not menu then
		return
	end
	local accelerators = menu:getLuaData('ab01acclrtrs')
	if not accelerators then
		return
	end

	local keyCode = e.keyCode
	for el, code in pairs(accelerators) do
		if code == keyCode then
			local ok = true
			if (not el.visible)
			or el.disabled then
				ok = false
			elseif not (el.name
					and el.name:startswith('UIEXP:FilterButton')
				) then
				local node = el
				while node.parent do
					node = node.parent
					if (not node.visible)
					or node.disabled then
						ok = false
						break
					end
				end
			end -- if (not node.visible)
			if ok then
				if logLevel2 then
					mwse.log([[>>> %s: keyDown() keyCode = %s %s, menu = "%s" "%s", el = "%s" "%s" "%s"]],
						modPrefix, keyCode, tes3_getKeyName(keyCode), menu.id, menu.name, el.id, el.name, el.text)
				end

				-- nope crashing tes3ui.acquireTextInput() -- avoid spoamming text inputs
				local el2 = getActiveTextInput()
				if el2 then
					el2.disabled = true
					timer.start({type = timer.real, duration = 0.084, callback = function ()
						local el = getActiveTextInput(true)
						if el then
							el.disabled = false
						end
					end})
				end
				el:triggerEvent('mouseClick')
				return false
			end -- if ok
		end -- if code
	end
end

local function newTooltipBlock(tooltip, s)
	local block = tooltip:createBlock({})
	block.flowDirection = 'top_to_bottom'
	block.autoHeight = true
	block.autoWidth = true
	block:createLabel{text = s}
	return block
end

---local idHelpMenu = tes3ui.registerID('HelpMenu')

---@param menu tes3uiElement
local function setAccelerators(menu)
	local result = false
	local accelerators = {}
	local accCodes = {}
	if logLevel1 then
		mwse.log([[%s: setAccelerators("%s")]], modPrefix, menu)
	end

	local function validAccelerator(el, c, i)
		local keyCode = tes3_scanCode[c]
		if keyCode
		and (not accCodes[keyCode]) then
			accCodes[keyCode] = true
			accelerators[el] = keyCode
			local tip = 'Alt + ' .. tes3_getKeyName(keyCode)
			if el.name
			and el.name:startswith('UIEXP:FilterButton') then
				local s = el.text
				local s2 = '(' .. s:sub(i, i) .. ')'
				if not s:find(s2, 1, true) then
					el.text = s:sub(1, i - 1) .. s2 .. s:sub(i + 1)
				end
				--[[ nope
				el:registerAfter('help', function ()
					local tooltip = tes3ui_findHelpLayerMenu(idHelpMenu)
					if not tooltip then
						tooltip = tes3ui.createTooltipMenu()
					end
					newTooltipBlock(tooltip, tip)
					---tooltip:updateLayout()
				end)]]
			else
				el:registerBefore('help', function ()
					local tooltip = tes3ui.createTooltipMenu()
					newTooltipBlock(tooltip, tip)
				end)
			end
			return true
		end
		return false
	end

	for el in table.traverse({menu}) do
		if (el.type == tes3_uiElementType_button) then
			local text = el.text
			if text then
				if logLevel1 then
					mwse.log([[>>> el = "%s" "%s", text = "%s"]],
						el.id, el.name, text)
				end
				local lcText = text:lower() .. '1234567890'
				lcText = lcText:match('(%w+)')
				local c
				for i = 1, #lcText do
					c = lcText:sub(i, i)
					if (not invalidCharsDict[c])
					and validAccelerator(el, c, i) then
						result = true
						break -- for i = 1, #lcText do
					end
				end -- for i
			end -- if text
		end -- if (el.type
	end -- for el

	if result then
		menu:setLuaData('ab01acclrtrs', accelerators)
	end
	return result
end

---@param e tes3uiEventData
local function beforeDestroyMenu(e)
	local menu = e.source
	local accelerators = menu:getLuaData('ab01acclrtrs')
	if not accelerators then
		return
	end
	for k, _ in pairs(accelerators) do
		accelerators[k] = nil
	end
	menu:setLuaData('ab01acclrtrs', nil)
end

-- process also when not newlyCreated
local menuWhiteList = {'MenuMessage'}

-- skip
local menuBlackList = {'MenuMulti','MenuNotify1','MenuNotify2','MenuNotify3'}

local menuWhitelListDict = table.invert(menuWhiteList)
local menuBlacklListDict = table.invert(menuBlackList)


local keyDownRegistered = false

---@param e uiActivatedEventData
local function uiActivated(e)
	if not modEnabled then
		return
	end
	local menu = e.element
	if not menu then
		return
	end
	local menu_name = menu.name
	if not menu_name then
		return
	end
	if menuBlacklListDict[menu_name] then
		if logLevel1 then
			mwse.log('%s: uiActivated("%s") blacklisted menu, skip', modPrefix, menu_name)
		end
		return
	end
	if not e.newlyCreated then
		if not menuWhitelListDict[menu_name] then
			return -- process only newly created menus unless in white list
		end
	end

	if logLevel2 then
		mwse.log('%s: uiActivated("%s") e.newlyCreated = %s', modPrefix, menu_name, e.newlyCreated)
	end
	local destroyRegistered = false
	if menu:getLuaData('ab01acclrtrs') then
		destroyRegistered = true
	end
	if setAccelerators(menu) then
		if not destroyRegistered then
			menu:registerBefore('destroy', beforeDestroyMenu)
		end
		if not keyDownRegistered then
			keyDownRegistered = true
			event.register(tes3.event.keyDown, keyDown, {priority = 1000000})
		end
	end
end

-- local scanCodeToChar = {}
-- for s, code in pairs(tes3_scanCode) do
-- 	if s:match('%w') then
-- 		scanCodeToChar[code] = s
-- 	end
-- end

local function modConfigReady()

	local function updateFromConfig()
		modEnabled = config.modEnabled
		invalidChars = config.invalidChars
		logLevel = config.logLevel
		logLevel1 = logLevel >= 1
		logLevel2 = logLevel >= 2
		logLevel3 = logLevel >= 3
	end

	updateFromConfig()

	local function onClose()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	local optionList = {'Off', 'Low', 'Medium', 'High'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s",
				i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		description = [[Button Accelerators

Top menu buttons should have automatically generated (A)ccelerator keys you can Alt + press to click the button (when the button window is focused, single-click the window header to try and focus a window).

The button accelerator key combo is Alt + first button text character when possible, and usually described in a new button tooltip.

In case of known buttons already having a tooltip (e.g. the ones coming from UI Expansion inventory filter buttons), most of the times the first letter of the button functionality should be the one used as accelerator e.g. Alt + w for "Filter to weapons" button.

Note: If you are using the Cheat Menu mod, try to avoid using a possible Alt + accelerator combo for the Kill cheat commands! e.g. in the Cheat mod use something like Shift + Ctrl + PageUp imstead of Alt + K that would be a frequent button accelerator for this mod. Or you could add the K letter to this mod "Invalid Characters" text input.
]],
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.1
			self.elements.sideToSideBlock.children[2].widthProportional = 0.9
		end
	})

	sideBarPage:createYesNoButton({
		label = 'Mod enabled',
		description = [[Toggle mod effects.]],
		configKey = 'modEnabled'
	})

	local textField

	local function validateInvalidCharacters(s)
		invalidCharsDict = {}
		s = s:lower()
		s = s:match('(%w+)') or ''
		local c
		for i = 1, #s do
			c = s:sub(i, i)
			invalidCharsDict[c] = i
		end
		-- it does not update the input box text though
		textField.elements.inputField.text = s
		return s
	end

	textField = sideBarPage:createTextField({
		label = 'Invalid Characters',
		description = [[Enter invalid alphanumeric characters you do not want to use ad Alt accelerator.
e.g. entering K2 would skip Alt + K, Alt + 2 accelerators.]],
		configKey = 'invalidChars',
		text = '',
		createBorder = true,
		converter = validateInvalidCharacters
	})
	--- aaargh NOPE it needs to wait postCreate
	--- local inputField = textField.elements.inputField

	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	if modEnabled then
		event.register('uiActivated', uiActivated, {priority = -110000})
	end

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)