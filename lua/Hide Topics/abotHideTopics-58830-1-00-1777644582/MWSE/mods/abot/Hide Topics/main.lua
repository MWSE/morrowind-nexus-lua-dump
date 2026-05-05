local defaultConfig = {
modDisabled = false,
notifyMsgEnabled = true,
filterTopics = true,
logLevel = 0
}

local author = 'abot'
local modName = 'Hide Topics'
local modPrefix = author..'/'..modName
local configName = author..modName
configName = configName:gsub(' ', '_')
local mcmName = author.."'s "..modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)
local modDisabled, notifyMsgEnabled, filterTopics
local logLevel, logLevel1, logLevel2, logLevel3

local function updateFromConfig()
	modDisabled = config.modDisabled
	notifyMsgEnabled = config.notifyMsgEnabled
	filterTopics = config.filterTopics
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
end
updateFromConfig()

local idMenuDialog_topics_pane = tes3ui.registerID('MenuDialog_topics_pane')
local idPartScrollPane_pane = tes3ui.registerID('PartScrollPane_pane')
local idMenuDialog_a_topic = tes3ui.registerID('MenuDialog_a_topic')
local idMenuDialog_scroll_pane = tes3ui.registerID('MenuDialog_scroll_pane')

local mwse_log = mwse.log
local table_bininsert, table_concat = table.bininsert, table.concat

-- set in loaded()
local player --@type tes3reference?
local inputController ---@type tes3inputController?
local hiddenTopicsDict ---@type boolean[]
local storedHiddenTopics ---@type string[]

---@param s string
local function messageBox(s)
	tes3.messageBox({message = s, showInDialog = false})
end

local function storeHiddenTopics()
	if not hiddenTopicsDict then
		return
	end
	if not player then
		return
	end
	local data = player.data
	data.ab01hdntpcsbckp = {}
	storedHiddenTopics = data.ab01hdntpcsbckp
	for lcTopic, _ in pairs(hiddenTopicsDict) do
		table_bininsert(storedHiddenTopics, lcTopic)
	end
	if #storedHiddenTopics > 0 then
		messageBox(tostring(#storedHiddenTopics)..' hidden topics stored')
	end
end

local function retrieveHiddenTopics()
	if not storedHiddenTopics then
		return
	end
	if not player then
		return
	end
	local data = player.data
	data.ab01hdntpcs = {}
	hiddenTopicsDict = data.ab01hdntpcs
	for _, lcTopic in ipairs(storedHiddenTopics) do
		hiddenTopicsDict[lcTopic] = true
	end
	if #storedHiddenTopics > 0 then
		messageBox(tostring(#storedHiddenTopics)..' hidden topics retrieved')
	end
end

-- set in uiMenuDialogActivated()
local menuDialog ---@type tes3uiElement?
local topicsPane ---@type tes3uiElement?
local searchInputBlock ---@type tes3uiElement?
local searchInput ---@type tes3uiElement?

-- forward declaration
local delayedUpdateTopicsPaneFWD

---@param e tes3uiEventData
---@return boolean? block
local function mouseClickTopic(e)
	local el = e.source
	assert(el)
	if modDisabled then
		el:forwardEvent(e)
		return
	end
	if logLevel2 then
		mwse_log('%s: mouseClickTopic("%s")', modPrefix, el.text)
	end
	assert(inputController)
	if inputController:isAltDown() then
		local lcTopic = el.text:lower()
		if logLevel1 then
			mwse_log('%s: mouseClickTopic("%s") Topic "%s" hidden',
				modPrefix, el.text, lcTopic)
		end
		hiddenTopicsDict[lcTopic] = true
		if notifyMsgEnabled then
			messageBox('Topic "'..lcTopic..'" hidden')
		end
		delayedUpdateTopicsPaneFWD()
	else
		el:forwardEvent(e)
	end
end

local sSearch = 'Filter Topics...'
local doSearch, lastDoSearch = false, false

local function updateTopicsPane()
	if modDisabled then
		return
	end
	assert(hiddenTopicsDict)
	if logLevel3 then
		mwse_log('%s: updateTopicsPane()', modPrefix)
	end
	assert(topicsPane)
	assert(searchInputBlock)
	assert(searchInput)

	local children = topicsPane.children
	assert(children)
	local lcSearchText = searchInput.text:lower()
	if filterTopics then
		doSearch = not (
			(lcSearchText:len() < 1) --- test 2
			or (lcSearchText == sSearch:lower())
		)
		if not searchInputBlock.visible then
---mwse_log('>>> %s: searchInputBlock.visible = true', modPrefix)
			searchInputBlock.visible = true
			tes3ui.acquireTextInput(searchInput)
		end
	else
		doSearch = false
		if searchInputBlock.visible then
---mwse_log('>>> %s: searchInputBlock.visible = false', modPrefix)
			searchInputBlock.visible = false
		end
	end
	local visible = false
	for _, child in ipairs(children) do
		if child.id == idMenuDialog_a_topic then
			local lcText = child.text:lower()
			visible = not hiddenTopicsDict[lcText]
			if doSearch
			and (not lcText:find(lcSearchText, 1, true)) then
				visible = false
			end
			if not (child.visible == visible) then
				child.visible = visible
			end
			if not child:getPropertyBool('ab01hdntpc') then
				if logLevel3 then
					mwse_log('"%s" mouseClick registered', lcText)
				end
				child:setPropertyBool('ab01hdntpc', true)
				child:register('mouseClick', mouseClickTopic)
			end
		end
	end
	if not (doSearch == lastDoSearch) then
		lastDoSearch = doSearch
	end
end

local function checkUpdateTopicsPane()
	if modDisabled then
		return
	end
	if menuDialog
	and menuDialog.visible
	and topicsPane then
		updateTopicsPane()
	end
end

---local timer_real = timer.real
local timer_frame = timer.frame

local function delayedUpdateTopicsPane()
	if modDisabled then
		return
	end
	timer_frame.delayOneFrame(checkUpdateTopicsPane)
	-- timer.start({type = timer_real, duration = 0.1,
		-- callback = checkUpdateTopicsPane})
end

delayedUpdateTopicsPaneFWD = delayedUpdateTopicsPane

local function beforeDestroyMenuDialog()
	searchInputBlock = nil
	searchInput = nil
	topicsPane = nil
	menuDialog = nil
end

---@param e tes3uiEventData
local function acquireTextInput(e)
	searchInput.text = sSearch
	updateTopicsPane()
	tes3ui.acquireTextInput(e.source)
end

local function resetSearch()
	if not searchInput then
		return
	end
	tes3ui.acquireTextInput(searchInput)
	searchInput.text = sSearch
	updateTopicsPane()
end

--- @param e uiActivatedEventData
local function uiActivatedMenuDialog(e)
	if logLevel2 then
		mwse_log('%s: uiActivatedMenuDialog()', modPrefix)
	end
	menuDialog = e.element
	local tp = menuDialog:findChild(idMenuDialog_topics_pane)
	if not tp then
		return
	end
	tp.borderAllSides = 0
	tp.paddingAllSides = 0
	tp.paddingLeft = 4
	tp.paddingRight = 4
	topicsPane = tp:findChild(idPartScrollPane_pane)
	if not topicsPane then
		return
	end
	if logLevel2 then
		mwse_log('%s: topicsPane.name = %s', modPrefix, topicsPane.name)
	end
	topicsPane.borderAllSides = 0
	topicsPane.paddingAllSides = 0
	topicsPane.paddingLeft = 4
	topicsPane.paddingRight = 4
	topicsPane:registerAfter('mouseClick', resetSearch)

	local mdsp = menuDialog:findChild(idMenuDialog_scroll_pane)
	if mdsp then
		mdsp:registerAfter('mouseClick', acquireTextInput)
	end

	if not searchInput then
		searchInput = tp.parent:createTextInput({
			id = 'ab01SearchInput',
			placeholderText = sSearch,
			createBorder = true,
			autoFocus = true
		})
	end
	local input = searchInput
	searchInputBlock = input.parent
	searchInput = input
	input.widget.lengthLimit = 31
	input.widget.eraseOnFirstKey = true
	input:register('keyEnter', updateTopicsPane)

	-- only works when text input is not captured
	searchInputBlock:register('keyEnter', updateTopicsPane)

	input:registerAfter('keyPress', updateTopicsPane)
	input:register('mouseClick', resetSearch)
	searchInputBlock:register('mouseClick', resetSearch)

	searchInputBlock:reorder({after = tp})
	---tes3ui.acquireTextInput(input)

	if e.newlyCreated then
		menuDialog:registerBefore('destroy', beforeDestroyMenuDialog)
	end
	delayedUpdateTopicsPane()
end

local function logHiddenTopics()
	local t = {}
	for lcTopic, value in pairs(hiddenTopicsDict) do
		if value then
			table_bininsert(t, '"'..lcTopic..'"')
		end
	end
	if #t <= 0 then
		return
	end
	mwse_log('%s: Hidden Topics', modPrefix)
	mwse_log(table_concat(t,'\r\n'))
	for k, _ in pairs(t) do
		t[k] = nil
	end
end

local function topicsListUpdated()
	checkUpdateTopicsPane()
end

local loadedOnce = false

local function loaded()
	player = tes3.player
	inputController = tes3.worldController.inputController
	local data = player.data
	hiddenTopicsDict = data.ab01hdntpcs
	if hiddenTopicsDict then
		if logLevel1 then
			logHiddenTopics()
		end
	else
		data.ab01hdntpcs = {}
		hiddenTopicsDict = data.ab01hdntpcs
	end
	storedHiddenTopics = data.ab01hdntpcsbckp
	if not storedHiddenTopics then
		data.ab01hdntpcsbckp = {}
		storedHiddenTopics = data.ab01hdntpcsbckp
	end
	if loadedOnce then
		return
	end
	loadedOnce = true
	event.register('uiActivated', uiActivatedMenuDialog, {filter = 'MenuDialog'})
	event.register('topicsListUpdated', topicsListUpdated)
end

---@return string[]
local function getVisibleTopics()
	local t = {}
	local mobilePlayer = tes3.mobilePlayer
	if not mobilePlayer then
		return t
	end
	local a = mobilePlayer.dialogueList
	if a then
		for i = 1, #a do
			t[i] = a[i].id:lower()
		end
	end
	return t
end

local function onClose()
	updateFromConfig()
	player = tes3.player
	mwse.saveConfig(configName, config,	{indent = true})
	checkUpdateTopicsPane()
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		label = modName,
		showHeader = false,
		description = [[You can hide topics Alt+clicking them from the Dialogue right panel topics list.

You can hide/unhide multiple topics from the mod MCM Topics Blacklist page.

You can filter topics from a dedicated search input box.

You can store/retrieve current hidden topics clicking dedicated MCM buttons.]],
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.0
			self.elements.sideToSideBlock.children[2].widthProportional = 1.0
		end
	})

	local category = sideBarPage:createCategory({label = 'Features'})

	local optionList = {'Off', 'Low', 'Medium', 'High'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = ("%s. %s"):format(i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	category:createYesNoButton({
		label = 'Mod disabled',
		description = [[Temporarily disable mod effects.]],
		configKey = 'modDisabled'
	})
	category:createYesNoButton({
		label = 'Notify',
		description = [[Enables a notify message when you Alt + Click to hide a topic.]],
		configKey = 'notifyMsgEnabled'
	})
	category:createYesNoButton({
		label = 'Topics Filter',
		description = [[Enables a Topics Filter input field for the Dialogue right panel topics list.
Note:
to allow UI Expansion Choice numeric shortcut keys while filtering the topics list, click some whitespace in the Dialogue left panel to focus it before pressing the numeric key.]],
		configKey = 'filterTopics'
	})
	category:createButton({
		buttonText = 'Store',
		description = [[Store current player hidden topics.]],
		inGameOnly = true,
		callback = storeHiddenTopics
	})
	category:createButton({
		buttonText = 'Retrieve',
		description = [[Retrieve previously stored player hidden topics.]],
		inGameOnly = true,
		callback = retrieveHiddenTopics
	})

	category:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = [[Enables debug information written to the Morrowind\mwse_log file.]],
		configKey = 'logLevel'
	})

	local exclusionsPage ---@type mwseMCMExclusionsPage?
	exclusionsPage = template:createExclusionsPage({
		inGameOnly = true,
		label = 'Topics Blacklist',
		leftListLabel = 'Hidden Topics',
		rightListLabel = 'Available Player Known Topics',
		filters = { {callback = getVisibleTopics, label = ''} },
		-- stored player hidden topics dictionary
		variable = mwse.mcm.createPlayerData({id = 'ab01hdntpcs', path = ''}),
	})

	mwse.mcm.register(template)
	event.register('loaded', loaded)
end
event.register('modConfigReady', modConfigReady)
