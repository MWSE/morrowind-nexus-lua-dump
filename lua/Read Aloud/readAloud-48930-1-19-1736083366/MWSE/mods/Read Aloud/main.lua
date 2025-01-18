---@diagnostic disable: undefined-field
-- some parts from NullCascade's SAPI example, some parts from me /abot

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
	if tes3.isKeyEqual({expected = stopReadingKey, actual = e}) then
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
	local menu = tes3ui.getMenuOnTop()
	if menu
	and skipMenus[menu.name] then
		return
	end
	local s = text
	local i, _ = string.find(text, '<silence msec=', 1, true)
	if i
	and (i > 0) then
		s = string.sub(text, 1, i - 1)
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
	local line = text
	line = string.gsub(line,
		'<[Ff][Oo][Nn][Tt].+[Ff][Aa][Cc][Ee].*=.*"[Dd][Aa][Ee][Dd][Rr][Ii][Cc]">(.+)</[Ff][Oo][Nn][Tt]>',
		daedric.getDaedricReplace)
	if config.logLevel >= 1 then
		mwse.log('%s: speakRaw\n%s', modPrefix, line)
	end
	speak(line)
end

---local tes3_dialogueType_topic = 0
local tes3_dialogueType_voice = tes3.dialogueType.voice -- 1 -- voice
local tes3_dialogueType_greeting = tes3.dialogueType.greeting -- 2
local tes3_dialogueType_service = tes3.dialogueType.service -- 3 -- service/disposition
---local tes3_dialogueType_journal = 4

local function stripTagsAndReplacePercent(s)
	return text:gsub('[@#]', ''):gsub('%%', '%^'):gsub('%^%^', '%^')
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
	local topic_info = topic.info
	---mwse.log("topic.info = %s", topic_info)
	if not topic_info then
		return
	end

	local text
	for _, info in pairs(topic_info) do
		if info
		and info.journalIndex then
			local s = info.text
			if s
			and (string.len(s) > 0) then
				text = s
				break
			end
		end
	end

	if config.logLevel >= 4 then
		mwse.log("%s: journal(e) topic.id = %s, index = %s, text = %s", modPrefix, topic.id, index, text)
	end

	if text
	and (not string.multifind(string.lower(text), {'dummy','dialog filter'}, 1, true)) then
		-- skip dummy journal entries for reload detection
		speakIfNotAlreadySpeaking(text)
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
	if table.empty(children) then
		return ''
	end

	local text = ''
	local headerColor
	local breaks = 0

	local isJournal = not isBook
	if isJournal then
		for _, el in pairs(children) do
			if el
			and (el.name == 'MenuBook_hypertext')
			and (string.len(el.text) > 0) then
				headerColor = el.color
				break
			end
		end
	end

	local function getText(el)
		local line = el.text
		if line
		and isJournal
		and (el.name == 'MenuBook_hypertext') then
			breaks = 0
			if (string.len(line) > 0)
			and isSameColor(el.color, headerColor)
			and ( not string.find(line, '[%)%.]$') ) then
				line = line .. '.'
			end
		end
		if el.id == -1398 then -- image
			breaks = 0
			text = text .. silenceTag3
		elseif line then
			if (string.len(line) == 0)
			or (line == ' ') then
				if (el.width == 0)
				and (el.height > 0)
				and (breaks < 3) then
					breaks = breaks + 1
					-- empty lines are used as vertical spacing
					text = text .. silenceTag1
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
			if elem
			and (elem.name == 'MenuBook_hypertext') then
				local line = elem.text
				if line
				and (string.len(line) > 0) then
					last_el = elem
				end
			end
		end
		if last_el then
			getText(last_el)
		end
	else
		for _, elem in pairs(children) do
			if elem then
				getText(elem)
			end
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
			-- in journal, replace all but last line break with space
			-- as formatting may be weird
			if string.match(text, '\r?\n') then
				text = string.gsub(text, '\r?\n', ' ') .. '\n'
			end
		end
		---mwse.log("page.name = %s, text = %s", page.name, text)
		speak(text)
	end
end

local idMenuBook_page_1 = tes3ui.registerID('MenuBook_page_1')
local idMenuBook_page_2 = tes3ui.registerID('MenuBook_page_2')
local idMenuBook_buttons_left = tes3ui.registerID('MenuBook_buttons_left')
local idMenuBook_buttons_right = tes3ui.registerID('MenuBook_buttons_right')
---local idMenuBook_page_number_1 = tes3ui.registerID('MenuBook_page_number_1')
---local idMenuBook_page_number_2 = tes3ui.registerID('MenuBook_page_number_2')
local idMenuBook_button_prev = tes3ui.registerID('MenuBook_button_prev')
local idMenuBook_button_next = tes3ui.registerID('MenuBook_button_next')
local idMenuBook_button_close = tes3ui.registerID('MenuBook_button_close')

local function readPages()
	if not bookElement then
		return
	end
	local page_1 = bookElement:findChild(idMenuBook_page_1)
	if not page_1 then
		return
	end
	local page_2 = bookElement:findChild(idMenuBook_page_2)
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
		if text
		and (string.len(text) > 0) then
			speakRaw(text)
		end
	end
end

local idMenuScroll_Close = tes3ui.registerID('MenuScroll_Close')

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
	local menuScroll_Close = menu:findChild(idMenuScroll_Close)
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

local idPartHyperText_link = tes3ui.registerID('PartHyperText_link')
local idPartHyperText_plain_text = tes3ui.registerID('PartHyperText_plain_text')

local tes3_uiProperty_mouseClick = tes3.uiProperty.mouseClick
---local tes3_uiProperty_mouseDown = tes3.uiProperty.mouseDown

-- read Journal pages when clicking a link
local function uiEventJournal(e)
	if e.property == tes3_uiProperty_mouseClick then -- click
		local el = e.block
		local id = el.id
		if config.logLevel >= 2 then
			mwse.log('%s: uiEventJournal(e) e.property = %s, el.id = %s, el.name = %s, el.text = %s',
				modPrefix, e.property, id, el.name, el.text)
		end
		if	(id == -32588) -- text links
		 or (id == idPartHyperText_link) -- PartHyperText_link -1093
		 or (id == idPartHyperText_plain_text) then -- PartHyperText_plain_text --1092
			if not inputController:isShiftDown() then -- shift+click may be used by a mod to hide quests, skip it
				local menu = el:getTopLevelMenu()
				if (menu.name == 'MenuJournal')
				and ( menu == tes3ui.getMenuOnTop() ) then
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

local function menuBook_buttonAfterClick()
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
			---bookElement:registerBefore('uiEvent', uiEventJournal)
			bookElement:registerAfter('uiEvent', uiEventJournal)
			bookElement:registerAfter('destroy', onDestroyJournal)
		end

		local page_1 = bookElement:findChild(idMenuBook_page_1)
		local menuBook_buttons_left = bookElement:findChild(idMenuBook_buttons_left)
		local menuBook_button_prev = menuBook_buttons_left:findChild(idMenuBook_button_prev)

		menuBook_button_prev:registerAfter('mouseClick', menuBook_buttonAfterClick)

		local buttonReadLeft = newReadButton(menuBook_button_prev, READ_LEFT_PAGE_BTN_TXT)
		buttonReadLeft:register(
			'mouseClick', function () delayedReadPage(page_1) end
		)

		local page_2 = bookElement:findChild(idMenuBook_page_2)
		local menuBook_buttons_right = bookElement:findChild(idMenuBook_buttons_right)

		menuBook_button_next = menuBook_buttons_right:findChild(idMenuBook_button_next)
		menuBook_button_next:registerAfter('mouseClick', menuBook_buttonAfterClick)

		local buttonReadRight = newReadButton(menuBook_button_next, READ_RIGHT_PAGE_BTN_TXT)
		buttonReadRight:register(
			'mouseClick', function () delayedReadPage(page_2) end
		)

		local menuBook_button_close = menuBook_buttons_right:findChild(idMenuBook_button_close)
		local buttonReadBoth = newReadButton(menuBook_button_close, READ_BOTH_PAGES_BTN_TXT)
		buttonReadBoth:register(
			'mouseClick', function ()
				delayedReadPages()
				return false
			end
		)

 -- done last as this thing is messing with retrieving things from second page
		bookElement:updateLayout()
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
		if config.daedricSkill
		and ( not daedricBooks[daedricBookId] ) then
			daedricBooks[daedricBookId] = 1
			daedric.levelUpDaedricSkill()
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

local idMenuDialog_scroll_pane = tes3ui.registerID('MenuDialog_scroll_pane')
local idPartScrollPane_pane = tes3ui.registerID('PartScrollPane_pane')
local idMenuDialog_header = tes3ui.registerID('MenuDialog_header')
local idMenuDialog_hyper = tes3ui.registerID('MenuDialog_hyper')
local idMenuDialog_answer_block = tes3ui.registerID('MenuDialog_answer_block')
local idMenuDialog_notify = tes3ui.registerID('MenuDialog_notify')

--[[
local function preUpdateDialog(e)
	messageOutOfDialog(string.format("e.source = %s, e.id = %s, e.widget = %s, e.data0 = %s, e.data1 = %s",
			e.source, e.id, e.widget, e.data0, e.data1))
end
]]
local lastInfoType = 100

local function infoGetText(e)
	lastInfoType = 100
	if tes3.menuMode() then
		local infoType = e.info.infoType
		if infoType
-- 0 = dialog, 1 = voice, 2 = greeting, 3 = persuasion/service, 4 = journal
		and (infoType >= 1)
		and (infoType <= 3) then
			lastInfoType = infoType
		end
	end
	--[[if config.logLevel >= 5 then
		mwse.log("%s: infoGetText(e) e.info.type = %s",	modPrefix, lastInfoType)
	end]]
end

local function stripPrefixNumbers(s)
	local r = string.gsub(s, "^%d+[%.:]%s+", '')
	if r == s then
		return r
	end
	return stripPrefixNumbers(r)
end


local function answerMouseClick(e)
	--[[
	messageOutOfDialog(string.format("e.source = %s, e.id = %s, e.widget = %s, e.data0 = %s, e.data1 = %s",
			e.source, e.id, e.widget, e.data0, e.data1))
	]]
	local el = e.source
	local text = el.text
	if not text then
		return
	end
	if string.len(text) <= 0 then
		return
	end
	local s = stripPrefixNumbers(text)
	if not s then
		return
	end
	local numChars = string.len(s)
	if numChars <= 0 then
		return
	end
	local timePerChar = 0.1
	if fMessageTimePerCharGMST then
		local v = fMessageTimePerCharGMST.value
		if v then
			timePerChar = v
		end
	end
	local speedDelta = 1 - (config.speedDelta / 10)
	---local msec = math.round(226 * timePerChar * numChars * speedDelta) + 1400
	local msec = math.round(219 * timePerChar * numChars * speedDelta) + 1050
	local silenceTag = getSilenceTag(msec)
	if config.logLevel >= 4 then
		mwse.log('%s: answerMouseClick(e) stopAndSpeak() with %s msec silence after %s', modPrefix, msec, silenceTag)
	end
	stopAndSpeak(s .. silenceTag)
	---stopAndSpeak(text)
	dontStop = true -- for next hypertext
end

local voiceOverPlayingRefId

local function addTempSound(e)
	if voiceOverPlayingRefId then
		return
	end
	local ref = e.reference
	if not ref then
		return
	end
	local target = tes3.getPlayerTarget()
	if target then
		if not (ref == target) then
			return
		end
	end
	local isVoiceOver = e.isVoiceover
	local logLevel = config.logLevel
	if not isVoiceOver then
		local path = e.path
		if path
		and string.find(string.lower(path), '^vo[\\/].+%.[wm][ap][v3]$') then
			if logLevel >= 4 then
				local s = string.format('%s: addTempSound(e) "%s" playing VoiceOver path = "%s"',
					modPrefix, voiceOverPlayingRefId, path)
				mwse.log(s)
				if logLevel >= 6 then
					messageOutOfDialog(s)
				end
			end
			isVoiceOver = true
		end
	end
	if not isVoiceOver then
		return
	end
	voiceOverPlayingRefId = ref.id
	if logLevel >= 4 then
		local s = string.format('%s: addTempSound(e) "%s" playing VoiceOver', modPrefix, voiceOverPlayingRefId)
		mwse.log(s)
		if logLevel >= 6 then
			messageOutOfDialog(s)
		end
	end
end

 local responsePlayingRefId

local function infoResponse(e)
	local command = e.command
	if not command then
		return
	end
	local ref = e.reference
	if not ref then
		return
	end
	-- current mobileActor we are talking to
	local mob = tes3ui.getServiceActor()
	if not mob then
		return
	end
	local mobRef = mob.reference
	if mobRef
	and ( not (ref == mobRef) ) then
		return
	end
	local logLevel = config.logLevel
	if logLevel >= 4 then
		mwse.log("%s: infoResponse(e) e.command = %s, e.dialogue = %s, e.info = %s, e.reference = '%s', e.variables = '%s'",
			modPrefix, command, e.dialogue, e.info, e.reference, e.variables)
	end
	if string.find(string.lower(command),'say%s-,?%s-"') then
		responsePlayingRefId = e.reference.id
		if logLevel >= 3 then
			local s = string.format('%s: infoResponse(e) %s using Say command', modPrefix, responsePlayingRefId)
			mwse.log(s)
			if logLevel >= 6 then
				messageOutOfDialog(s)
			end
		end
	end
end

local tes3_dialogueFilterContext_voice = tes3.dialogueFilterContext.voice
local tes3_dialogueFilterContext_greeting = tes3.dialogueFilterContext.greeting


local contextDict = table.invert(tes3.dialogueFilterContext)

local filteredVoiceRefId

local function dialogueFiltered(e)
	local context = e.context
	if not (
		(context == tes3_dialogueFilterContext_voice)
		or (context == tes3_dialogueFilterContext_greeting)
	) then
		return
	end
	local ref = e.reference
	if not ref then
		return
	end
	-- current mobileActor we are talking to
	local mob = tes3ui.getServiceActor()
	if not mob then
		return
	end
	local mobRef = mob.reference
	if mobRef
	and ( not (ref == mobRef) ) then
		return
	end
	local text = e.info.text
	if not text then
		return
	end
	if string.len(text) < 3 then
		return
	end
	local logLevel = config.logLevel
	if logLevel >= 4 then
		mwse.log('%s: dialogueFiltered(e) context = "%s", dialogue = "%s", info = "%s", reference = "%s"',
			modPrefix, contextDict[context], e.dialogue, e.info, ref)
	end
	filteredVoiceRefId = ref.id
end

---local readElements = {}
local function afterDestroyDialog()
	voiceOverPlayingRefId = nil
	responsePlayingRefId = nil
	filteredVoiceRefId = nil
	lastText = ''
	checkStopReading()
	--[[for k, _ in pairs(readElements) do
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
	local logLevel = config.logLevel
	if logLevel >= 5 then
		mwse.log('%s: checkReadElement() id = %s, name = %s, dontStop = %s, text = %s',
			modPrefix, el.id, el.name, dontStop, text)
	end
	if logLevel >= 6 then
		messageOutOfDialog(stripTagsAndReplacePercent(text))
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

	local logLevel4 = logLevel >= 4
	local logLevel5 = logLevel >= 5

	if mobile.actorType == 0 then -- a creature
		local boundSize = mobile.boundSize
		if (boundSize.y > 1.5 * boundSize.x) -- long
		and (boundSize.y > 1.5 * boundSize.z) then -- not tall
			if logLevel4 then
				mwse.log('%s: updateDialog(e) skipping %s creature as unable to talk', modPrefix, mobile.reference.object.id)
			end
			return -- probably not a talking creature
		end
	end

	local el = e.source:findChild(idMenuDialog_scroll_pane)
	if not el then
		return
	end
	local pane = el:findChild(idPartScrollPane_pane)
	if not pane then
		return
	end

	local npcRef
	if not config.useOnlyPlayerVoice then
		npcRef = mobile.reference
	end

	local firstInfo = true
	local readDialog = config.readDialog

	for node in table.traverse(pane.children) do
		if not node:getPropertyBool(alreadyRead) then
		---if not readElements[node] then
			local id = node.id
			local text = node.text
			if text then
				dialogNPCref = nil -- player voice by default
				if id == idMenuDialog_header then
					if readDialog > 1 then
						local ok = true
						if (lastInfoType == tes3_dialogueType_service)
						and (readDialog < 4) then
							ok = false
							if logLevel4 then
								mwse.log('%s: updateDialog(e) tes3_dialogueType_service, skipping', modPrefix)
							end
						end
						if ok then
							dontStop = checkReadElement(node, text) -- so it does not stop on next idMenuDialog_hyper one
						end
					end
				elseif id == idMenuDialog_notify then
					if node.visible then
						if string.len(text) < 2 then
							node.visible = false
							skipNextNotify = false
						elseif readDialog > 2 then
							if skipNextNotify then
								skipNextNotify = false
							else
								dontStop = true -- don't stop on this one
								skipNextNotify = true
								-- so it does not stop on next idMenuDialog_hyper one
								dontStop = checkReadElement(node, stripPrefixNumbers(text))
							end
						else
							skipNextNotify = false
						end
					end
				elseif id == idMenuDialog_answer_block then
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
				elseif id == idMenuDialog_hyper then
					if readDialog > 0 then
						local ok = true
						if lastInfoType == tes3_dialogueType_greeting then
							ok = config.readGreeting
						elseif lastInfoType == tes3_dialogueType_voice then
							ok = false -- skip voices in case
							if logLevel4 then
								mwse.log('%s: updateDialog(e) tes3_dialogueType_voice, skipping', modPrefix)
							end
						end

						local lcId = string.lower(mobile.reference.id)
						if string.startswith(lcId, 'dagoth_ur_1') then
							-- Greater Dwemer Ruin Dagoth Ur speech, skip
							ok = false
							if logLevel5 then
								mwse.log('%s: updateDialog(e) skipping voiced dagoth_ur_1', modPrefix)
							end
						end

						local mob_ref_id = mobile.reference.id
						if voiceOverPlayingRefId then
							if logLevel5 then
								mwse.log('%s: updateDialog(e) mobile.reference = %s, voiceOverPlayingRefId = %s',
									modPrefix, mobile.reference, voiceOverPlayingRefId)
							end
							-- comparing references directly does not work
							if mob_ref_id == voiceOverPlayingRefId then
								voiceOverPlayingRefId = nil
								ok = false -- skip actor already playing voiceover
								if logLevel4 then
									mwse.log('%s: updateDialog(e) voiceOverPlayingRefId skipping %s as already talking',
										modPrefix, mobile.reference.id)
								end
							end
						end

						if responsePlayingRefId then
							if logLevel5 then
								mwse.log('%s: updateDialog(e) mobile.reference = %s, responsePlayingRefId = %s',
									modPrefix, mob_ref_id, responsePlayingRefId)
							end
							if mob_ref_id == responsePlayingRefId then
								ok = false -- skip actor already playing voiceover
								if logLevel >= 4 then
									mwse.log('%s: updateDialog(e) responsePlayingRefId skipping %s as already talking', modPrefix, mob_ref_id)
								end
							end
							responsePlayingRefId = nil
						end

						if filteredVoiceRefId then
							if logLevel5 then
								mwse.log('%s: updateDialog(e) mobile.reference = %s, filteredVoiceRefId = %s',
									modPrefix, mob_ref_id, filteredVoiceRefId)
							end
							if mob_ref_id == filteredVoiceRefId then
								ok = false -- skip actor already playing voiceover
								if logLevel >= 4 then
									mwse.log('%s: updateDialog(e) skipping filteredVoiceRefId %s as already talking', modPrefix, mob_ref_id)
								end
							end
							filteredVoiceRefId = nil
						end



						-- for now...
						if firstInfo then
							firstInfo = false
							if config.readGreeting
							and ok then
								if string.startswith(lcId, '_mca_companion') -- skip MCA companions
								or string.startswith(lcId, 'ks_') --skip Julan & C.
								or string.startswith(lcId, 'aa_comp_') --skip Constance
								or string.startswith(lcId, 'aa_latte_comp') then --skip Latte
									ok = false
									skipNextNotify = true
									if logLevel5 then
										mwse.log('%s: updateDialog(e) skipping voiced companion', modPrefix)
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
	if string.multifind(string.lower(s),
		{'banner', 'sign', '_inn_', 'roadmarker', '_flag'}, 1, true) then
		return true
	end
	return false
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
			local lcId = string.lower(obj.id)
			if (obj.type == tes3_bookType_scroll)
			or string.find(lcId, 'bk_daedric_', 1, true) then
				if not daedricBooks[lcId] then
					daedricBookId = lcId -- set it for uiMenuBookActivated(e), uiMenuScrollActivated(e)
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
	if string.len(text) <= 0 then
		return
	end
	if not isSignLike(obj.id) then
		local mesh = obj.mesh
		---assert(mesh)
		if not isSignLike(mesh) then
			return
		end
	end

	---mwse.log("text = %s", text)
	speak(text)
	if not ref:testActionFlag(tes3_actionFlag_useEnabled) then
		return -- onactivate block present, skip disabling event on scripted activate
	end

	-- skip triggering normal behavior so we also avoid problems
	-- if object is set as owned and has no script, that's too common
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

local function charGenFinished()
	if config.logLevel >= 5 then
		mwse.log('%s: charGenFinished() playerSpeechParams updated on new game', modPrefix)
	end
	cmn.playerSpeechParams = cmn.getSpeechParamsForReference(player)
	event.unregister('charGenFinished', charGenFinished)
end

local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	inputController = tes3.worldController.inputController
	---fargothwalkGlobal = tes3.findGlobal('fargothwalk')
	event.register('save', save)
    event.register('journal', journal, {priority = 2}) -- prority > Smart Journal
	event.register('activate', activate, {priority = 1})
	event.register('uiActivated', uiMenuJournalActivated, {filter = 'MenuJournal'})
	event.register('infoGetText', infoGetText)
	event.register('addTempSound', addTempSound)
	event.register('infoResponse', infoResponse)
	event.register('dialogueFiltered', dialogueFiltered)
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
	mwse.log('%s: initialized', modPrefix)
end

local function loaded(e)
	player = tes3.player
	lastText = ''
	stopReading()
	cmn.playerSpeechParams = cmn.getSpeechParamsForReference(player)
	fMessageTimePerCharGMST = tes3.findGMST(tes3.gmst.fMessageTimePerChar) -- default 0.1 sec
	---assert(fMessageTimePerCharGMST)
	bookElement = nil
	menuBook_button_next = nil
	initOnce()
	if e.newGame then
		event.register('charGenFinished', charGenFinished)
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

event.register('initialized', function ()
	inputController = tes3.worldController.inputController
	event.register('uiActivated', uiMenuScrollActivated, {filter = 'MenuScroll'})
	event.register('uiActivated', uiMenuBookActivated, {filter = 'MenuBook'})
	event.register('uiActivated', uiMenuDialogActivated, {filter = 'MenuDialog'})
	event.register('loaded', loaded)
end, {doOnce = true})
