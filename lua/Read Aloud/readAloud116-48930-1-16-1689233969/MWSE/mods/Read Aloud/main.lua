---@diagnostic disable: undefined-field
-- some parts from NullCascade's SAPI example, some parts from me /abot

-- bah silly language I am not able to read parent folder from the current file path so I have to duplicate it everywhere
local modPrefix = 'Read Aloud'

local cmn = require(modPrefix .. '.common')
local SAPIwind = require(modPrefix .. '.speech')
local daedric = require(modPrefix .. '.daedric')
require(modPrefix .. '.mcm')

local config = cmn.config

-- begin tweakables

-- You can tweak the read page(s) buttons text here if you want.
local READ_LEFT_PAGE_BTN_TXT = 'Read'
local READ_RIGHT_PAGE_BTN_TXT = 'Read'
local READ_BOTH_PAGES_BTN_TXT = 'Read Both'

-- set in loaded()
local player

local function stopIfSpeaking()
	if SAPIwind.isSpeaking() then
		SAPIwind.stop()
	end
end

local keyUpRegistered = false

local stopReadingKey = config.stopReadingKey

local function stopReadingKeyUp(e)
	if (e.keyCode == stopReadingKey.keyCode)
	and (e.isAltDown == stopReadingKey.isAltDown)
	and (e.isShiftDown == stopReadingKey.isShiftDown)
	and (e.isControlDown == stopReadingKey.isControlDown) then
		if keyUpRegistered then
			keyUpRegistered = false
			event.unregister('keyUp', stopReadingKeyUp)
		end
		stopIfSpeaking()
		return false
	end
end

local lastText = ''

local function stopReading()
	if keyUpRegistered then
		keyUpRegistered = false
		event.unregister('keyUp', stopReadingKeyUp)
	end
	stopIfSpeaking()
end


local function checkStopReading()
	if config.keepReadingOnMenuClose then
		return
	end
	stopReading()
end

local skipMenus = {
	['MenuOptions'] = true,
	['MWSE:ModConfigMenu'] = true,
	['Hrn:MenuInspector'] = true
}

local dialogNPCref  -- set in updateDialog(e)

local function speak(text)
	--[[
	if not text then
		assert(text)
		return
	end
	if not player then
		assert(player)
		return
	end
	local textLen = string.len(text)
	if textLen <= 0 then
		assert(false)
		return
	end
	]]
	local menu = tes3ui.getMenuOnTop()
	if menu then
		local name = menu.name
		--[[if not name then
			assert(name)
			return
		end]]
		if skipMenus[name] then
			return
		end
	end

	local s = text
	local i, _ = string.find(text, '<silence msec=', 1, true)
	if i then
		if i > 0 then
			s = string.sub(text, 1, i-1)
		end
	end
	if s == lastText then
		return -- skip reading the same thing 2 times in case it happens
	end
	lastText = s

	if not keyUpRegistered then
		keyUpRegistered = true
		event.register('keyUp', stopReadingKeyUp)
	end

	local speechParams
	if dialogNPCref then
		speechParams = cmn.getSpeechParamsForReference(dialogNPCref)
	else
		speechParams = cmn.playerSpeechParams
	end
	SAPIwind.speak(text, speechParams, config.logLevel)
end

local function speakIfNotAlreadySpeaking(text)
	if not SAPIwind.isSpeaking() then
		speak(text)
	end
end

local dontStop = false
local function stopAndSpeak(text)
	if not dontStop then
		stopIfSpeaking()
	end
	speak(text)
end

local knownDaedricLetters = daedric.knownDaedricLetters

local function speakRaw(text)
	---mwse.log("speakRaw(%s)", text)
	-- replace and translate daedric
	stopIfSpeaking()
	local line = string.gsub(text, '<[Ff][Oo][Nn][Tt].+[Ff][Aa][Cc][Ee].*=.*"[Dd][Aa][Ee][Dd][Rr][Ii][Cc]">(.+)</[Ff][Oo][Nn][Tt]>', daedric.getDaedricReplace)
	if config.logLevel >= 1 then
		mwse.log('%s: speakRaw\n%s', modPrefix, line)
	end
	speak(line)
end

---local tes3_dialogueType_topic = 0
local tes3_dialogueType_voice = tes3.dialogueType.voice -- 1
local tes3_dialogueType_greeting = tes3.dialogueType.greeting -- 2
local tes3_dialogueType_service = tes3.dialogueType.service -- 3 -- service/disposition
---local tes3_dialogueType_journal = 4

local function stripTags(text)
	return text:gsub('[@#]', ''):gsub('%%', '%^')
end

local function messageOutOfDialog(s)
	tes3.messageBox({message = s, showInDialog = false})
end

-- set in loaded()
local fMessageTimePerCharGMST

local function journal(e)
	if not config.readLastJournal then
		return
	end
	local topic = e.topic
	---mwse.log("topic = %s", topic)
	if not topic then
		return
	end
	local index = e.index
	---mwse.log("index = %s", index)
	if not index then
		return
	end
	local topic_info_iterator = topic.info
	---mwse.log("topic.info = %s", topic_info)
	if not topic_info_iterator then
		return
	end

	local text, disposition, s
	for _, info in pairs(topic_info_iterator) do
		if info then
			disposition = info.disposition
			if disposition then
				if index == disposition then -- disposition is used as Journal Index in quest
					s = info.text
					if s then
						if string.len(s) > 0 then
							text = s
							break
						end
					end
				end
			end
		end
	end

	if config.logLevel >= 4 then
		mwse.log("%s: journal(e) topic.id = %s, index = %s, text = %s", modPrefix, topic.id, index, text)
	end

	if text then
		if not string.multifind(text:lower(), {'dummy', 'dialog filter'}, 1, true) then
		-- skip dummy journal entries for reload detection
			speakIfNotAlreadySpeaking(text)
		end
	end
end

local function getSilenceTag(msec)
	return string.format('<silence msec="%s"/>', msec)
end

local silenceTag1 = getSilenceTag(300)
local silenceTag3 = getSilenceTag(900)

local function isSameColor(color1, color2)
	for i = 1, #color1 do
		if not (color1[i] == color2[i]) then
			return false
		end
	end
	return true
end

local isBook  -- updated by uiMenuBookActivated(e), uiMenuJournalActivated(e)
local lastEntry = false

local function getPageText(page)
	if not page then
		return ''
	end
	if config.logLevel >= 2 then
		mwse.log('%s: getPageText(page = %s, lastEntry = %s)', modPrefix, page.name, lastEntry)
	end
	local children = page.children
	if not children then
		return ''
	end
	---if #children <= 0 then
	if table.size(children) <= 0 then
		return ''
	end

	local text = ''
	local headerColor
	local breaks = 0

	local isJournal = not isBook
	if isJournal then
		for _, el in pairs(children) do
			if el.name == 'MenuBook_hypertext' then
				if string.len(el.text) > 0 then
					headerColor = el.color
					break
				end
			end
		end
	end


	local function getText(el)
		local line = el.text
		if line then
			if isJournal then
				if el.name == 'MenuBook_hypertext' then
					breaks = 0
					if string.len(line) > 0 then
						if isSameColor(el.color, headerColor) then
							if not string.find(line, '[%)%.]$') then
								line = line .. '.'
							end
						end
					end
				end
			end
		end
		if el.id == -1398 then -- image
			breaks = 0
			text = text .. silenceTag3
		elseif line then
			if (line == '') or (line == ' ') then
				if el.width == 0 then
					if el.height > 0 then
						if breaks < 3 then
							breaks = breaks + 1
							-- empty lines are used as vertical spacing
							text = text .. silenceTag1
						end
					end
				end
			else
				breaks = 0
				text = text .. ' ' .. line
			end
		end
	end

	if lastEntry then
		local last_el
		for _, elem in pairs(children) do
			if elem.name == 'MenuBook_hypertext' then
				local line = elem.text
				if line then
					if string.len(line) > 0 then
						last_el = elem
					end
				end
			end
		end
		if last_el then
			getText(last_el)
		end
	else
		for _, elem in pairs(children) do
			getText(elem)
		end
	end
	return text
end

--[[
local red = { 1, 0, 0}
local green = {0, 1, 0}
local blue = {0, 0, 1}
--]]
local link_color = {1 - (43 / 255), 1 - (30 / 255), 1 - (19 / 255)} -- complementary color works better for journal
local link_over_color = {80 / 255, 56 / 255, 37 / 255} -- tes3ui.getPalette('link_over_color')
local link_pressed_color = {105 / 255, 74 / 255, 50 / 255} -- tes3ui.getPalette('link_pressed_color')

--[[
local disabled_color = tes3ui.getPalette('disabled_color')
local disabled_over_color = tes3ui.getPalette('disabled_over_color')
local disabled_pressed_color = tes3ui.getPalette('disabled_pressed_color')
--]]
local function setButtonColors(button)
	button.borderAllSides = 1
	local widget = button.widget
	if not widget then
		return
	end
	widget.idle = link_color -- normal state, no mouse interaction
	widget.idleActive = link_color -- active state, no mouse interaction
	widget.over = link_over_color -- normal state, on mouseOver
	widget.overActive = link_over_color -- active state, on mouseOver
	widget.pressed = link_pressed_color -- normal state, on mouseDown
	widget.pressedActive = link_pressed_color -- active state, on mouseDown
	--[[
	widget.idleDisabled = disabled_color -- disabled state, no mouse interaction
	widget.overDisabled = disabled_over_color -- disabled state, on mouseOver
	widget.pressedDisabled = disabled_pressed_color -- disabled state, on mouseDown
	--]]
end

local bookElement, menuBook_button_next  -- set in pagesActivated(e)

local function readPage(page)
	if not bookElement then
		return
	end
	if not page then
		return
	end
	local text = getPageText(page)
	if string.len(text) > 0 then
		if not isBook then
			-- in journal, replace line break with space as formatting may be weird
			text = string.gsub(text, '\r?\n', ' ')
		end
		---mwse.log("page.name = %s, text = %s", page.name, text)
		speak(text)
	end
end

local GUI_ID_MenuBook_page_1 = tes3ui.registerID('MenuBook_page_1')
local GUI_ID_MenuBook_page_2 = tes3ui.registerID('MenuBook_page_2')
local GUI_ID_MenuBook_buttons_left = tes3ui.registerID('MenuBook_buttons_left')
local GUI_ID_MenuBook_buttons_right = tes3ui.registerID('MenuBook_buttons_right')
---local GUI_ID_MenuBook_page_number_1 = tes3ui.registerID('MenuBook_page_number_1')
---local GUI_ID_MenuBook_page_number_2 = tes3ui.registerID('MenuBook_page_number_2')
local GUI_ID_MenuBook_button_prev = tes3ui.registerID('MenuBook_button_prev')
local GUI_ID_MenuBook_button_next = tes3ui.registerID('MenuBook_button_next')
local GUI_ID_MenuBook_button_close = tes3ui.registerID('MenuBook_button_close')

local function readPages()
	if not bookElement then
		return
	end
	local page_1 = bookElement:findChild(GUI_ID_MenuBook_page_1)
	if not page_1 then
		return
	end
	local page_2 = bookElement:findChild(GUI_ID_MenuBook_page_2)
	if not page_2 then
		return
	end
	local text1, text2
	if lastEntry then
		text2 = getPageText(page_2)
		if text2 == '' then
			text1 = getPageText(page_1)
		end
	else
		text1 = getPageText(page_1)
		text2 = getPageText(page_2)
	end

	if config.logLevel >= 2 then
		if lastEntry then
			mwse.log('%s: readPages()\ntext2 =%s', modPrefix, text2)
		else
			mwse.log('%s: readPages()\ntext1 =%s\n\ntext2 =%s', modPrefix, text1, text2)
		end
	end

	local text = text1
	if text then
		if text2 then
			text = text1 .. text2
		end
	else
		text = text2
	end

	lastEntry = false

	if string.len(text) > 0 then
		if not isBook then
			-- in journal, replace line break with space as formatting may be weird
			text = string.gsub(text, '\r?\n', ' ')
		end
		speak(text)
	end
end

local function delayedReadPage(page)
	stopIfSpeaking()
	timer.start(
		{type = timer.real, duration = 0.6,
		callback = function()
			readPage(page)
		end}
	)
end

local function delayedReadPages()
	stopIfSpeaking()
	timer.start({type = timer.real, duration = 0.6, callback = readPages})
end

local function readRawScroll()
	if config.readBooksScrolls > 0 then
		-- Fetch the current book text string and speak it.
		-- must get it from raw memory to be able to parse daedric font tag
		local text = mwse.memory.readValue({address = 0x7CA44C, as = 'string'})
		if text then
			if string.len(text) > 0 then
				speakRaw(text)
			end
		end
	end
end

local GUI_ID_MenuScroll_Close = tes3ui.registerID('MenuScroll_Close')

local daedricBooks = {} -- set in loaded(), stored in save()
local daedricBookId = nil -- set in activate(e), consumed in uiMenuBookActivated(e), uiMenuScrollActivated(e)

-- read scrolls text (scrollable, no paging)

local function onDestroyScroll()
	lastText = ''
	checkStopReading()
end

local function uiMenuScrollActivated(e)

	if daedricBookId then
		if config.daedricSkill then
			if daedricBooks[daedricBookId] then
				daedric.skipProgress = true
			else
				daedricBooks[daedricBookId] = 1
			end
		end
		daedricBookId = nil
	end

	if not e.newlyCreated then
		return
	end
	---mwse.log("uiMenuScrollActivated(e)")
	if config.readBooksScrolls == 0 then
		return
	end
	local menu = e.element
	menu:registerAfter('destroy', onDestroyScroll)
	local menuScroll_Close = menu:findChild(GUI_ID_MenuScroll_Close)
	if menuScroll_Close then
		menuScroll_Close.absolutePosAlignX = 1.0
		local parent = menuScroll_Close.parent
		parent.autoWidth = true
		parent.autoHeight = true
		local block = parent:createBlock({})
		block.autoWidth = true
		block.autoHeight = true
		block.absolutePosAlignX = 0.89
		block.absolutePosAlignY = 0.3
		local button = block:createButton({text = 'Read'})
		setButtonColors(button)
		button:register('mouseClick', readRawScroll)
		menu:updateLayout()
	end
	if config.readBooksScrolls >= 3 then
		readRawScroll()
	end
end

local function checkDelayedReadPages()
	if isBook then
		if config.readBooksScrolls >= 3 then
			delayedReadPages()
		end
	elseif config.readJournal >= 4 then
		delayedReadPages()
	end
end

local inputController  -- set in initialized()

local tes3_scanCode_lShift = tes3.scanCode.lShift
local tes3_scanCode_rShift = tes3.scanCode.rShift
local function isShiftDown()
	return inputController:isKeyDown(tes3_scanCode_lShift)
	or inputController:isKeyDown(tes3_scanCode_rShift)
end

local GUI_ID_PartHyperText_link = tes3ui.registerID('PartHyperText_link')
local GUI_ID_PartHyperText_plain_text = tes3ui.registerID('PartHyperText_plain_text')

local tes3_uiProperty_mouseClick = tes3.uiProperty.mouseClick
---local tes3_uiProperty_mouseDown = tes3.uiProperty.mouseDown

-- read Journal pages when clicking a link
local function uiEventJournal(e)
	if e.property == tes3_uiProperty_mouseClick then -- click
		local el = e.block
		local id = el.id
		if config.logLevel >= 2 then
			mwse.log('%s: uiEventJournal(e) e.property = %s, el.id = %s, el.name = %s, el.text = %s', modPrefix, e.property, id, el.name, el.text)
		end
		if	(id == -32588) -- text links
		 or (id == GUI_ID_PartHyperText_link) -- PartHyperText_link -1093
		 or (id == GUI_ID_PartHyperText_plain_text) then -- PartHyperText_plain_text --1092
			if not isShiftDown() then -- shift+click may be used by a mod to hide quests, skip it
				local menu = el:getTopLevelMenu()
				if menu.name == 'MenuJournal' then
					if menu == tes3ui.getMenuOnTop() then
						local s = el.text
						if s then
							if (s == READ_LEFT_PAGE_BTN_TXT)
							or (s == READ_RIGHT_PAGE_BTN_TXT)
							or (s == READ_BOTH_PAGES_BTN_TXT) then
								return -- skip reading both pages in case we use pages read button
							end
						end
						---e.source:forwardEvent(e)
						checkDelayedReadPages()
					end
				end
			end
		end
	end
end

local function onDestroyJournal()
	bookElement = nil
	menuBook_button_next = nil
	checkStopReading()
	---event.unregister('uiEvent', uiEventJournal)
end

local function onDestroyBook()
	bookElement = nil
	menuBook_button_next = nil
	lastText = ''
	checkStopReading()
end

local function menuBook_buttonClick(e)
	e.source:forwardEvent(e)
	checkDelayedReadPages()
end

local function newReadButton(el, buttonText)
	local parent = el.parent
	parent.autoWidth = true
	parent.autoHeight = true
	local block = parent:createBlock({})
	block.autoWidth = true
	block.autoHeight = true
	---block.absolutePosAlignX = x
	---block.absolutePosAlignY = y
	local button = block:createButton({text = buttonText})
	setButtonColors(button)
	---button.borderAllSides = 1
	---mwse.log("button.text = %s", button.text)
	return button
end

local function pagesActivated(e)
	---assert(e)
	---mwse.log("pagesActivated(e), e.element = %s", e.element)
	local justCreated = false
	if not (e.element == bookElement) then
		justCreated = true
		bookElement = e.element
	end

	---assert(bookElement)
	if e.newlyCreated then
		if isBook then
			bookElement:registerAfter('destroy', onDestroyBook)
		else
			---event.register('uiEvent', uiEventJournal)
			bookElement:registerBefore('uiEvent', uiEventJournal)
			bookElement:registerAfter('destroy', onDestroyJournal)
		end

		local page_1 = bookElement:findChild(GUI_ID_MenuBook_page_1)
		---assert(page_1)
		local menuBook_buttons_left = bookElement:findChild(GUI_ID_MenuBook_buttons_left)
		---assert(menuBook_buttons_left)
		---local menuBook_page_number_1 = menuBook_buttons_left:findChild(GUI_ID_MenuBook_page_number_1)
		---assert(menuBook_page_number_1)
		local menuBook_button_prev = menuBook_buttons_left:findChild(GUI_ID_MenuBook_button_prev)
		---assert(menuBook_button_prev)
		menuBook_button_prev:register('mouseClick', menuBook_buttonClick)

		local buttonReadLeft = newReadButton(menuBook_button_prev, READ_LEFT_PAGE_BTN_TXT)
		---assert(buttonReadLeft)
		buttonReadLeft:register(
			'mouseClick', function () delayedReadPage(page_1) end
		)

		local page_2 = bookElement:findChild(GUI_ID_MenuBook_page_2)
		---assert(page_2)
		local menuBook_buttons_right = bookElement:findChild(GUI_ID_MenuBook_buttons_right)
		---assert(menuBook_buttons_right)
		---local menuBook_page_number_2 = menuBook_buttons_right:findChild(GUI_ID_MenuBook_page_number_2)
		---assert(menuBook_page_number_2)
		menuBook_button_next = menuBook_buttons_right:findChild(GUI_ID_MenuBook_button_next)
		---assert(menuBook_button_next)
		menuBook_button_next:register('mouseClick', menuBook_buttonClick)
		local buttonReadRight = newReadButton(menuBook_button_next, READ_RIGHT_PAGE_BTN_TXT)
		---assert(buttonReadRight)
		buttonReadRight:register(
			'mouseClick', function () delayedReadPage(page_2) end
		)

		local menuBook_button_close = menuBook_buttons_right:findChild(GUI_ID_MenuBook_button_close)
		local buttonReadBoth = newReadButton(menuBook_button_close, READ_BOTH_PAGES_BTN_TXT)
		---assert(buttonReadBoth)
		buttonReadBoth:register(
			'mouseClick', function ()
				delayedReadPages()
				return false
			end
		)

		bookElement:updateLayout() -- done last as this thing is messing with retrieving things from second page
	end
	if justCreated then
		if isBook then
			if config.readBooksScrolls >= 3 then
				delayedReadPages()
			end
		elseif config.readJournal >= 3 then
			lastEntry = config.readJournal == 3
			if menuBook_button_next then
				if menuBook_button_next.visible then
					lastEntry = false
				end
			end
			---tes3.messageBox("config.readJournal = %s", config.readJournal)
			delayedReadPages()
		end
	end
end

local function uiMenuBookActivated(e)
	---mwse.log("uiMenuBookActivated(e)")

	if daedricBookId then
		if config.daedricSkill then
			if not daedricBooks[daedricBookId] then
				daedricBooks[daedricBookId] = 1
				daedric.levelUpDaedricSkill()
			end
		end
		daedricBookId = nil
	end

	if config.readBooksScrolls == 0 then
		return
	end
	isBook = true
	pagesActivated(e)
end

local function uiMenuJournalActivated(e)
	---mwse.log("uiMenuJournalActivated(e)")
	if config.readJournal == 0 then
		return
	end
	isBook = false
	pagesActivated(e)
end

local GUI_ID_MenuDialog_scroll_pane = tes3ui.registerID('MenuDialog_scroll_pane')
local GUI_ID_PartScrollPane_pane = tes3ui.registerID('PartScrollPane_pane')
local GUI_ID_MenuDialog_header = tes3ui.registerID('MenuDialog_header')
local GUI_ID_MenuDialog_hyper = tes3ui.registerID('MenuDialog_hyper')
local GUI_ID_MenuDialog_answer_block = tes3ui.registerID('MenuDialog_answer_block')
local GUI_ID_MenuDialog_notify = tes3ui.registerID('MenuDialog_notify')

--[[
local function preUpdateDialog(e)
	messageOutOfDialog(string.format("e.source = %s, e.id = %s, e.widget = %s, e.data0 = %s, e.data1 = %s",
			e.source, e.id, e.widget, e.data0, e.data1))
end
]]
local lastInfoType
local function infoGetText(e)
	-- 0 = dialog, 1 = voice, 2 = greeting, 3 = persuasion/service, 4 = journal
	lastInfoType = e.info.type
	--[[if config.logLevel >= 5 then
		mwse.log("%s: infoGetText(e) e.info.type = %s",	modPrefix, lastInfoType)
	end]]
end

local function stripPrefixNumber(text)
	local s = string.match(text, "^%d+[:%.]%s(.+)$")
	if s then
		return s
	end
	return text
end


local function answerMouseClick(e)
	--[[
	messageOutOfDialog(string.format("e.source = %s, e.id = %s, e.widget = %s, e.data0 = %s, e.data1 = %s",
			e.source, e.id, e.widget, e.data0, e.data1))
	]]
	local text = e.source.text
	if not text then
		return
	end
	text = stripPrefixNumber(text)
	local timePerChar = fMessageTimePerCharGMST.value
	local numChars = text:len()
	local speedDelta = 1 - (config.speedDelta / 10)
	local msec = math.round(226 * timePerChar * numChars * speedDelta) + 1400
	local silenceTag = getSilenceTag(msec)
	if config.logLevel >= 4 then
		mwse.log('%s: answerMouseClick(e) stopAndSpeak() with %s msec silence after %s', modPrefix, msec, silenceTag)
	end
	stopAndSpeak(text .. silenceTag)
	---stopAndSpeak(text)
	dontStop = true -- for next hypertext
end

local voiceOverPlayingRefId
local function addTempSound(e)
	if e.isVoiceover then
		voiceOverPlayingRefId = e.reference.id
		if config.logLevel >= 4 then
			local s = string.format('%s: addTempSound(e) %s playing VoiceOver', modPrefix, voiceOverPlayingRefId)
			mwse.log(s)
			if config.logLevel >= 6 then
				messageOutOfDialog(s)
			end
		end
	else
		voiceOverPlayingRefId = nil
	end
end

local responsePlayingRefId
local function infoResponse(e)
	if config.logLevel >= 3 then
		mwse.log("%s: infoResponse(e) e.command = %s, e.dialogue = %s, e.info = %s, e.reference = '%s', e.variables = '%s'",
			modPrefix, e.command, e.dialogue, e.info, e.reference, e.variables)
	end
	responsePlayingRefId = nil
	local command = e.command
	if command then
		if string.find(command,'[sS]ay%s-,?%s-"') then
			responsePlayingRefId = e.reference.id
			if config.logLevel >= 3 then
				local s = string.format('%s: infoResponse(e) %s using Say command', modPrefix, responsePlayingRefId)
				mwse.log(s)
				if config.logLevel >= 6 then
					messageOutOfDialog(s)
				end
			end
		end
	end
end

---local readElements = {}
local function afterDestroyDialog()
	lastText = ''
	checkStopReading()
	--[[for k in pairs(readElements) do
		readElements[k] = nil
	end
	readElements = {}]]
end

local alreadyRead = 'SAPIwind:read'
local function checkReadElement(el, text)
	if not text then
		return false
	end
	if string.len(text) < 2 then
		el:setPropertyBool(alreadyRead, true)
		---readElements[el] = true
		return false -- skip some empty pregreeting/hello, does not make sense to read anyway
	end
	if config.logLevel >= 5 then
		mwse.log('%s: checkReadElement() id = %s, name = %s, dontStop = %s, text = %s', modPrefix, el.id, el.name, dontStop, text)
	end
	if config.logLevel >= 6 then
		messageOutOfDialog(stripTags(text))
	end
	el:setPropertyBool(alreadyRead, true)
	---readElements[el] = true
	stopAndSpeak(text)
	return true
end


local skipNextNotify = false
local function updateDialog(e)
	local mobile = e.source:getPropertyObject('PartHyperText_actor')
	if not mobile then
		return
	end

	local logLevel = config.logLevel

	--[[if logLevel >= 5 then
		mwse.log("%s: updateDialog(e) e.source = %s, e.id = %s, e.widget = %s, e.data0 = %s, e.data1 = %s",
			modPrefix, e.source, e.id, e.widget, e.data0, e.data1)
	end]]

	if mobile.actorType == 0 then -- a creature
		local boundSize = mobile.boundSize
		if boundSize.y > 1.5 * boundSize.x then -- long
			if boundSize.y > 1.5 * boundSize.z then -- not tall
				if logLevel >= 4 then
					mwse.log('%s: updateDialog(e) skipping %s creature as unable to talk', modPrefix, mobile.reference.object.id)
				end
				return -- probably not a talking creature
			end
		end
	end

	local el = e.source:findChild(GUI_ID_MenuDialog_scroll_pane)
	if not el then
		return
	end
	local pane = el:findChild(GUI_ID_PartScrollPane_pane)
	if not pane then
		return
	end

	local npcRef
	if not config.useOnlyPlayerVoice then
		npcRef = mobile.reference
	end

	local id, text, ok

	local firstInfo = true
	for node in table.traverse(pane.children) do
		if not node:getPropertyBool(alreadyRead) then
		---if not readElements[node] then
			id = node.id
			text = node.text
			if text then
				dialogNPCref = nil -- player voice by default
				if id == GUI_ID_MenuDialog_header then
					if config.readDialog > 1 then
						ok = true
						if lastInfoType == tes3_dialogueType_service then
							if config.readDialog < 4 then
								ok = false
								if logLevel >= 4 then
									mwse.log('%s: updateDialog(e) tes3_dialogueType_service, skipping', modPrefix)
								end
							end
						end
						if ok then
							dontStop = checkReadElement(node, text) -- so it does not stop on next GUI_ID_MenuDialog_hyper one
						end
					end
				elseif id == GUI_ID_MenuDialog_notify then
					if node.visible then
						if text:len() < 2 then
							node.visible = false
							skipNextNotify = false
						elseif config.readDialog > 2 then
							if skipNextNotify then
								skipNextNotify = false
							else
								dontStop = true -- don't stop on this one
								skipNextNotify = true
								dontStop = checkReadElement(node, stripPrefixNumber(text)) -- so it does not stop on next GUI_ID_MenuDialog_hyper one
							end
						else
							skipNextNotify = false
						end
					end
				elseif id == GUI_ID_MenuDialog_answer_block then
					if node.visible then
						if config.readDialogChoice then
							if skipNextNotify then
								skipNextNotify = false
							else
								if string.multifind(string.lower(text), {'continue', 'goodbye'}, 1, true) then
									skipNextNotify = false
								else
									-- skip reading standard answers
									skipNextNotify = true
									node:registerBefore('mouseClick', answerMouseClick)
								end
							end
						end
					else
						skipNextNotify = false
					end
				elseif id == GUI_ID_MenuDialog_hyper then
					if config.readDialog > 0 then
						ok = true
						if lastInfoType == tes3_dialogueType_greeting then
							ok = config.readGreeting
						elseif lastInfoType == tes3_dialogueType_voice then
							ok = false -- skip voices in case
							if logLevel >= 4 then
								mwse.log('%s: updateDialog(e) tes3_dialogueType_voice, skipping', modPrefix)
							end
						end

						local lcId = string.lower(mobile.reference.id)
						if string.startswith(lcId, 'dagoth_ur_1') then -- Greater Dwemer Ruin Dagoth Ur speech, skip
							ok = false
							if logLevel >= 5 then
								mwse.log('%s: updateDialog(e) skipping voiced dagoth_ur_1', modPrefix)
							end
						end

						if voiceOverPlayingRefId then
							if logLevel >= 5 then
								mwse.log('%s: updateDialog(e) mobile.reference = %s, voiceOverPlayingRefId = %s', modPrefix, mobile.reference, voiceOverPlayingRefId)
							end
							if mobile.reference.id == voiceOverPlayingRefId then -- comparing references directly does not work
								voiceOverPlayingRefId = nil
								ok = false -- skip actor already playing voiceover
								if logLevel >= 4 then
									mwse.log('%s: updateDialog(e) voiceOverPlayingRefId skipping %s as already talking', modPrefix, mobile.reference.id)
								end
							end
						end

						if responsePlayingRefId then
							if logLevel >= 5 then
								mwse.log('%s: updateDialog(e) mobile.reference = %s, responsePlayingRefId = %s', modPrefix, mobile.reference, responsePlayingRefId)
							end
							if mobile.reference.id == responsePlayingRefId then
								responsePlayingRefId = nil
								ok = false -- skip actor already playing voiceover
								if logLevel >= 4 then
									mwse.log('%s: updateDialog(e) responsePlayingRefId skipping %s as already talking', modPrefix, mobile.reference.id)
								end
							end
						end

						-- for now...
						if firstInfo then
							firstInfo = false
							if config.readGreeting then
								if ok then
									if string.startswith(lcId, '_mca_companion') -- skip MCA companions
									or string.startswith(lcId, 'ks_') --skip Julan & C.
									or string.startswith(lcId, 'aa_comp_') --skip Constance
									or string.startswith(lcId, 'aa_latte_comp') then --skip Latte
										ok = false
										if logLevel >= 5 then
											mwse.log('%s: updateDialog(e) skipping voiced companion', modPrefix)
										end
									end
								end
							end
						end

						if ok then
							dialogNPCref = npcRef
							checkReadElement(node, text)
							dontStop = false
						end

					end -- if config.readDialog > 0
				end -- if id ==
			end -- if text
		end -- if not
	end -- for node
end

local function uiMenuDialogActivated(e)
	if not e.newlyCreated then
		return
	end
	if not (
		config.readDialogChoice
	 or (config.readDialog > 0)
	 or config.readGreeting
	) then
		return
	end
	lastText = ''
	local el = e.element
	---el:registerBefore('update', updateDialog)
	---el:register('update', updateDialog)
	el:registerAfter('update', updateDialog)
	el:registerAfter('destroy', afterDestroyDialog)
end

local function isSignLike(s)
	return string.multifind(s:lower(), {'banner', 'sign', '_inn_', 'roadmarker', '_flag'}, 1, true)
end

local tes3_objectType_activator = tes3.objectType.activator
local tes3_actionFlag_useEnabled = tes3.actionFlag.useEnabled

local tes3_objectType_book = tes3.objectType.book
local tes3_bookType_scroll = tes3.bookType.scroll

-- read signs, banners, roadmarkers
local function activate(e)
	if not (e.activator == player) then
		return
	end

	local ref = e.target
	local obj = ref.object
	local objType = obj.objectType

	if objType == tes3_objectType_book then
		lastText = ''
		daedricBookId = nil
		if config.daedricSkill then
			local id = obj.id:lower()
			if (obj.type == tes3_bookType_scroll)
			or string.find(id, 'bk_daedric_', 1, true) then
				if not daedricBooks[id] then
					daedricBookId = id -- set it for uiMenuBookActivated(e), uiMenuScrollActivated(e)
				end
			end
		end
		return
	end

	if not config.readSigns then
		return
	end
	if not (objType == tes3_objectType_activator) then
		return
	end
	lastText = ''
	local text = obj.name
	if not text then
		---assert(text)
		return
	end
	if text:len() == 0 then
		return
	end
	if not isSignLike(obj.id) then
		local mesh = obj.mesh
		assert(mesh)
		if not isSignLike(mesh) then
			return
		end
	end

	---mwse.log("text = %s", text)
	speak(text)
	if not ref:testActionFlag(tes3_actionFlag_useEnabled) then
		return -- onactivate block present, skip disabling event on scripted activate
	end

	-- skip triggering normal behavior so we also avoid problems if object is set as owned and has no script, that's too common
	return false
end

local function save()
	local playerData = player.data
	if not playerData then
		return
	end
	playerData.raKnownDaedricLetters = knownDaedricLetters
	playerData.raDaedricSkillBooks = daedricBooks
end


local charGenTimer
local function checkCharGenState()
	local charGenStateValue = tes3.worldController.charGenState.value
	if math.floor(charGenStateValue + 0.5) == -1 then
		if config.logLevel >= 5 then
			mwse.log('%s: loaded(e) charGenState = %s, playerSpeechParams updated on new game', modPrefix, charGenStateValue)
		end
		cmn.playerSpeechParams = cmn.getSpeechParamsForReference(player)
		charGenTimer:cancel()
		charGenTimer = nil
	end
end

local function loaded(e)
	lastText = ''
	stopReading()

	fMessageTimePerCharGMST = tes3.findGMST(tes3.gmst.fMessageTimePerChar) -- default 0.1 sec
	---assert(fMessageTimePerCharGMST)

	bookElement = nil
	menuBook_button_next = nil
	player = tes3.player
	---assert(player)

	cmn.playerSpeechParams = cmn.getSpeechParamsForReference(player)
	if e.newGame then
		charGenTimer = timer.start({duration = 2.05 - (0.1 * math.random()), callback = checkCharGenState, iterations = -1})
	end

	local playerData = player.data
	if not playerData then
		return
	end
	knownDaedricLetters = playerData.raKnownDaedricLetters

	if not knownDaedricLetters then
		knownDaedricLetters = {}
	elseif not (type(knownDaedricLetters) == 'table') then
		knownDaedricLetters = {} -- make possible old version compatible
	end
	daedricBooks = playerData.raDaedricSkillBooks
	if not daedricBooks then
		daedricBooks = {}
	end
end

local function initialized()
	inputController = tes3.worldController.inputController
	---fargothwalkGlobal = tes3.findGlobal('fargothwalk')
	event.register('loaded', loaded)
	event.register('save', save)
	event.register('journal', journal)
	event.register('activate', activate, {priority = 1})
	event.register('uiActivated', uiMenuScrollActivated, {filter = 'MenuScroll'})
	event.register('uiActivated', uiMenuBookActivated, {filter = 'MenuBook'})
	event.register('uiActivated', uiMenuJournalActivated, {filter = 'MenuJournal'})
	event.register('uiActivated', uiMenuDialogActivated, {filter = 'MenuDialog'})
	event.register('infoGetText', infoGetText)
	event.register('addTempSound', addTempSound)
	event.register('infoResponse', infoResponse)
	
	mwse.log('%s: initialized', modPrefix)
	local voices = SAPIwind.getVoices()
	if voices then
		local count = #voices
		if count > 0 then
			mwse.log('%s: detected voices', modPrefix)
			for i = 1, count do
				mwse.log("%s. %s", i, voices[i])
			end
		end
	end
end
event.register('initialized', initialized)
