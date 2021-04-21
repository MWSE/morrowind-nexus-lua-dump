--[[
hotkeys for Quests and Topics /abot
--]]

local defaultConfig = {
questsKey = {
	keyCode = tes3.scanCode.u,
	isShiftDown = false,
	isAltDown = false,
	isControlDown = false,
},
topicsKey = {
	keyCode = tes3.scanCode.i,
	isShiftDown = false,
	isAltDown = false,
	isControlDown = false,
},
journalKeyCode = tes3.scanCode.j,
}

local author = 'abot'
local modName = 'Hot Quests'
---local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

-- 2nd parameter advantage: anything not defined in the loaded file inherits the value from defaultConfig
local config = mwse.loadConfig(configName, defaultConfig)

local GUI_ID_MenuJournal = tes3ui.registerID('MenuJournal')
local GUI_ID_MenuJournal_bookmark = tes3ui.registerID('MenuJournal_bookmark')
local GUI_ID_MenuBook_button_take = tes3ui.registerID('MenuBook_button_take')
local GUI_ID_MenuJournal_button_bookmark_quests = tes3ui.registerID('MenuJournal_button_bookmark_quests')
local GUI_ID_MenuJournal_button_bookmark_topics = tes3ui.registerID('MenuJournal_button_bookmark_topics')

local actionType = 0
local menuJournal

local function bookmarkButtonClick()
	local menuJournal_button_bookmark
	if actionType == 1 then
		menuJournal_button_bookmark = menuJournal:findChild(GUI_ID_MenuJournal_button_bookmark_quests)
	elseif actionType == 2 then
		menuJournal_button_bookmark = menuJournal:findChild(GUI_ID_MenuJournal_button_bookmark_topics)
	end
	actionType = 0
	if not menuJournal_button_bookmark then
		---assert(menuJournal_button_bookmark)
		return
	end
	menuJournal_button_bookmark:triggerEvent('mouseClick')
end

local function uiActivated(e)
	if actionType == 0 then
		return
	end
	menuJournal = e.element
	local menuBook_button_take = menuJournal:findChild(GUI_ID_MenuBook_button_take)
	if not menuBook_button_take then
		---assert(menuBook_button_take)
		return
	end
	tes3.releaseKey(config.journalKeyCode)
	menuBook_button_take:triggerEvent('mouseClick')
	timer.start({type = timer.real, duration = 0.1, iterations = 1, callback = bookmarkButtonClick})
end

local function keyDown(e)
	if tes3.menuMode() then
		local topMenu = tes3.getTopMenu()
		if topMenu then
			if not (topMenu.name == 'MenuJournal') then
				return -- more hotkey pressing only in journal menu
			end
		end
	end		
	local keyCode = e.keyCode
	local questsKey = config.questsKey
	if (keyCode == questsKey.keyCode)
	and (e.isShiftDown == questsKey.isShiftDown)
	and (e.isAltDown == questsKey.isAltDown)
	and (e.isControlDown == questsKey.isControlDown) then
		actionType = 1
	end
	if actionType == 0 then
		local topicsKey = config.topicsKey
		if (keyCode == topicsKey.keyCode)
		and (e.isShiftDown == topicsKey.isShiftDown)
		and (e.isAltDown == topicsKey.isAltDown)
		and (e.isControlDown == topicsKey.isControlDown) then
			actionType = 2
		end
	end
	if actionType > 0 then
		menuJournal = tes3ui.findMenu(GUI_ID_MenuJournal)
		if menuJournal then
			if menuJournal == tes3ui.getMenuOnTop() then
				local menuJournal_bookmark = tes3ui.findMenu(GUI_ID_MenuJournal_bookmark)
				if menuJournal_bookmark then
					if menuJournal_bookmark.visible then
						bookmarkButtonClick()
						return
					end
				end
				uiActivated({element = menuJournal})
				return
			end
		end
		tes3.tapKey(config.journalKeyCode)
		return
	end
	if tes3.worldController.inputController:keybindTest(tes3.keybind.journal) then
		config.journalKeyCode = keyCode
	end
end

local function modConfigReady()
	local mcm = mwse.mcm
	local template = mcm.createTemplate(mcmName)
	template:register()
	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
	end
	local page = template:createPage({})
	page.noScroll = true
	page.indent = 0
	page.postCreate = function(self)
		self.elements.innerContainer.paddingAllSides = 10
	end
	page:createKeyBinder({
		label = 'Quests Hotkey', allowCombinations = true,
		variable = mcm:createTableVariable({
			id = 'questsKey', table = config,
			defaultSetting = defaultConfig.questsKey,
			restartRequired = false,
		})
	})
	page:createKeyBinder({
		label = 'Topics Hotkey', allowCombinations = true,
		variable = mcm:createTableVariable({
			id = 'topicsKey', table = config,
			defaultSetting = defaultConfig.topicsKey,
			restartRequired = false,
		})
	})
	logConfig(config, {indent = false})
end
event.register('keyDown', keyDown)
event.register('uiActivated', uiActivated, {filter = 'MenuJournal'})
event.register('modConfigReady', modConfigReady)

