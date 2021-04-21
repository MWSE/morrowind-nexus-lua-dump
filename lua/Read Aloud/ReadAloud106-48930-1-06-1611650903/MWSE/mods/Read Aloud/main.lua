-- some  parts from NullCascade's SAPI example, some parts from me /abot

-- begin tweakables
local defaultConfig = {
volume = 50, -- Speech volume
language = 1, -- default to US English
readBooksScrolls = 3,
readJournal = 2, -- 0 = Disabled | 1 = Enabled | 2 = Enabled, On Link Click | 3 = Enabled, On Link Click, Automatic
readLastJournal = true,
readDialogChoice = true,
readSigns = true,
keepReadingOnMenuClose = false,
daedricTranslation = true,
readDaedricTranslation = true,
daedricSkill = true,
logLevel = 0, -- 0 = disabled, 1 = low, 2 = medium, 3 = high
stopReadingKey = {
	keyCode = tes3.scanCode.s,
	isShiftDown = false,
	isAltDown = true,
	isControlDown = false,
},
}
-- end tweakables

local languages = {}
languages[1] = "409" -- English (United States) e.g. Microsoft Zira, Microsoft David, Microsoft Mark
languages[2] = "809" -- English (United Kingdom) e.g. Microsoft George, Microsoft Hazel
languages[3] = "C09" -- English (Australia) e.g. Microsoft James, Microsoft Catherine
languages[4] = "1009" -- English (Canada) e.g. Microsoft Richard, Microsoft Linda
languages[5] = "4009" -- English (India) e.g. Microsoft Ravi, Microsoft Heera

local author = 'abot, NullCascade'
local modName = 'Read Aloud'
---local modPrefix = author .. '/'.. modName
local modPrefix = modName
---local configName = author .. modName
local configName = modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
---local mcmName = author .. "'s " .. modName
local mcmName = modName

local SAPIwind = require(string.format("%s.speech", modName))

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local speechParams = {
["argonian"] = { Male = {}, Female = {}, },
["breton"] = { Male = { pitch = 4, speed = -1 }, Female = { pitch = 2, speed = -1 }, },
["dark elf"] = { Male = { pitch = -10, speed = 0 }, Female = { pitch = -8, speed = 0 }, },
["high elf"] = { Male = { pitch = 6, speed = -1 }, Female = { pitch = 6, speed = -1 }, },
["imperial"] = { Male = { pitch = 0, speed = -1 }, Female = { pitch = 0, speed = -1 }, },
["khajiit"] = { Male = {}, Female = {}, },
["nord"] = { Male = { pitch = -4, speed = -1 }, Female = { pitch = -4, speed = -1 }, },
["orc"] = { Male = { pitch = -2, speed = -1 }, Female = { pitch = -2, speed = -1 }, },
["redguard"] = { Male = { pitch = -8, speed = -1 }, Female = { pitch = -8, speed = 0 }, },
["wood elf"] = { Male = { pitch = 8, speed = -1 }, Female = { pitch = 8, speed = -1 }, },
}

local function getSpeechParamsForReference(reference)
	SAPIwind.volume = config.volume
	local race = reference.baseObject.race.id:lower()
	local sex = reference.baseObject.female and "Female" or "Male"
	---sex = "Female" -- just for debugging
	local s = string.format("Gender=%s;Age!=Child;Language=%s", sex, languages[config.language])
	if (speechParams[race] and speechParams[race][sex]) then
		local r = table.copy(speechParams[race][sex])
		r.tokensRequired = s
		return r
	elseif (sex) then
		return { tokensRequired = s }
	end
	return {}
end


local player -- set in loaded()

local keyUpRegistered = false

local function stopReadingKeyUp(e)
	local stopReadingKey = config.stopReadingKey
	if (e.keyCode == stopReadingKey.keyCode)
	and (e.isAltDown == stopReadingKey.isAltDown)
	and (e.isShiftDown == stopReadingKey.isShiftDown)
	and (e.isControlDown == stopReadingKey.isControlDown) then
		if keyUpRegistered then
			keyUpRegistered = false
			event.unregister('keyUp', stopReadingKeyUp)
		end
		SAPIwind.stop()
		return false
	end
end

local function stopReading()
	if keyUpRegistered then
		keyUpRegistered = false
		event.unregister('keyUp', stopReadingKeyUp)
	end
	SAPIwind.stop()
end

local function checkStopReading()
	if config.keepReadingOnMenuClose then
		return
	end
	stopReading()
end

local function speak(text)
	local menu = tes3ui.getMenuOnTop()
	if menu then
		local name = menu.name
		if (name == "MenuOptions")
		or (name == "MWSE:ModConfigMenu")
		or (name == "Hrn:MenuInspector") then
			return
		end
	end
	if not keyUpRegistered then
		keyUpRegistered = true
		event.register('keyUp', stopReadingKeyUp)
	end
	SAPIwind.speak(text, getSpeechParamsForReference(player), config.logLevel)
end

local skillModule = include("OtherSkills.skillModule")
---local skillModule = require("OtherSkills.skillModule")

if not skillModule then
	config.daedricSkill = false
	mwse.log("%s: Warning: OtherSkills.skillModule not found, Daedric Skill disabled.", modPrefix)
end

local daedricSkillId = "ab01daedric"
local daedricSkillCap = 100

local function getDaedricSkillActive()
	if config.daedricSkill then
		return "active"
	else
		return "inactive"
	end
end

local knownDaedricLetters = {}

-- daedric skill/translation

local daedricSkillRef -- set in onSkillReady()

local function initDaedricSkillRef()
-- each call to getSkill(daedricSkillId) returns a new object/address
	if skillModule then
		daedricSkillRef = skillModule.getSkill(daedricSkillId)
	else
		daedricSkillRef = nil
	end
end

local function getDaedricSkillValue()
	if daedricSkillRef then
		return daedricSkillRef.value
	else
		return 1
	end
end

local function progressDaedricSkill(valueToAdd)
	if daedricSkillRef then
		---mwse.log("daedricSkillRef:progressSkill(%s)", valueToAdd)
		daedricSkillRef:progressSkill(valueToAdd)
	end
end

local function levelUpDaedricSkill()
	if daedricSkillRef then
		---mwse.log("daedricSkillRef:levelUpSkill()")
		daedricSkillRef:levelUpSkill()
	end
end

local function onSkillReady()
	skillModule.registerSkill(
		daedricSkillId,
		{
		name = "Daedric",
		value =	5, --default: 5
		progress = 0, --default: 0
		lvlCap = daedricSkillCap, -- default: 100
		icon = "Icons/abot/daedric.dds", --default: a circle icon
		attribute = tes3.attribute.intelligence, --optional
		description	= "Determines your effectiveness at reading Daedric text in enchanted scrolls.", --optional
		specialization = tes3.specialization.magic, --optional. Icon background is gray if none set
		active = getDaedricSkillActive(),
		}
	)
	initDaedricSkillRef()
end

if skillModule then
	event.register("OtherSkills:Ready", onSkillReady)
end

-- weird language making sorting difficult
local function pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a, f)
	local i = 0 -- iterator variable
	local iter = function() -- iterator function
		i = i + 1
		local ai = a[i]
		if ai == nil then
			return nil
		else
			return ai, t[ai]
		end
	end
	return iter
end

local function letters2string()
	local s = ''
	if knownDaedricLetters then
		if #knownDaedricLetters > 0 then
			for _, v in pairsByKeys(knownDaedricLetters) do
				s = s .. v
			end
		end
	end
	return s
end

local function daedricSkillProcess(inStr)
	---mwse.log("daedricSkillProcess(%s)", inStr)
	local knownCount = 26
	local strlen = string.len(inStr)
	local count = 0
	local skill = getDaedricSkillValue()
	local outStr = inStr
	if skill < daedricSkillCap then
		local maxRand = 2 * (daedricSkillCap - 1)
		knownCount = #knownDaedricLetters
		local c
		local lc
		outStr = ''
		for i = 1, strlen do
			c = string.sub(inStr, i, i)
			lc = string.lower(c)
			if knownDaedricLetters[lc] then
				outStr = outStr .. c
				count = count + 1
			elseif string.find(c, "[%s%p]") then
				outStr = outStr .. c
			elseif skill > math.random(0, maxRand) then
				outStr = outStr .. c
				count = count + 1
				if knownCount < 26 then
					knownCount = knownCount + 1
				end
				knownDaedricLetters[lc] = 1
			else
				outStr = outStr .. ' '
			end
		end
	end

	local newSkill = math.floor((daedricSkillCap * knownCount / 26 ) + 0.5)
	local skillInc = newSkill - skill
	if config.logLevel > 2 then
		local l2s = letters2string()
		mwse.log("read Daedric:\noutStr = %s, knownDaedricLetters = %s, knownCount = %s, skill = %s, newSkill = %s, skillInc = %s"
		, outStr, l2s, knownCount, skill, newSkill, skillInc)
	end
	if skillInc > 0 then
		levelUpDaedricSkill()
		--[[
		skillInc = skillInc - 1
		if skillInc > 0 then
			mwse.log("timer.start({type = timer.real, duration = 5, callback = levelUpDaedricSkill, iterations = %s})", skillInc)
			timer.start({type = timer.real, duration = 5, callback = levelUpDaedricSkill, iterations = skillInc})
		end
		--]]
	else
		progressDaedricSkill(2*count)
	end
	return outStr
end

local function getDaedricTranslation(inStr)
	---mwse.log("getDaedricTranslation(inStr) config.daedricSkill = %s, daedricSkillRef = %s", config.daedricSkill, daedricSkillRef)
	local outStr = SAPIwind.getFiltered(inStr)
	if config.daedricSkill and daedricSkillRef then
		outStr = daedricSkillProcess(outStr)
	end
	local l = string.len(outStr)
	if l > 0 then
		if config.daedricTranslation then
			local maxChars = 200
			local s
			 -- usually 100 characters = 10 sec message, can be annoying
			if l > maxChars then
				s = string.sub(outStr, 1, maxChars) .. '...'
			else
				s = outStr
			end
			tes3.messageBox(s)
		end
		---mwse.log("read daedric: outStr =\n%s", outStr)
	end
	if config.readDaedricTranslation then
		return outStr
	else
		return ''
	end
end

local function getDaedricReplace(inStr)
	local s = inStr
	if s then
		s = getDaedricTranslation(inStr)
-- important to get translation lowercase else 2 letters words will be spelled
		s = string.lower(s)
		if config.logLevel >= 2 then
			mwse.log("%s: getDaedricReplace(%s) --> %s", modPrefix, inStr, s)
		end
	end
	return s
end

local function speakRaw(text)
	---mwse.log("speakRaw(%s)", text)
	-- replace and translate daedric
	SAPIwind.stop()
	local line = string.gsub(text,
"<[Ff][Oo][Nn][Tt].+[Ff][Aa][Cc][Ee].*=.*\"[Dd][Aa][Ee][Dd][Rr][Ii][Cc]\">(.+)</[Ff][Oo][Nn][Tt]>",
		getDaedricReplace
	)
	if config.logLevel >= 2 then
		mwse.log("%s: speakRaw\n%s", modPrefix, line)
	end
	speak(line)
end


local timePerChar -- set in loaded()

-- read new journal entry
local function newJournalEntrySpeak(text)
	local delay = timePerChar * string.len(text) * 0.5
	if SAPIwind.isSpeaking() then
		if delay < 3 then
			delay = 3
		elseif delay > 10 then
			delay = 10
		end
		timer.start({
			type = timer.real, iterations = 1, duration = delay,
			callback = function() newJournalEntrySpeak(text) end
		})
		return
	end
	speak(text)
end

local function journal(e)
	if not config.readLastJournal then
		return
	end
	local dialogue = e.topic
	---mwse.log("dialogue = %s", dialogue)
	if not dialogue then
		return
	end
	local index = e.index
	---mwse.log("index = %s", index)
	if not index then
		return
	end
	local info = dialogue.info
	---mwse.log("info = %s", info.id)
	if not info then
		return
	end
	for q in tes3.iterate(info) do
		if q then -- important!
			---mwse.log("q = %s, q.disposition = %s", q.id, q.disposition)
			if q.disposition == index then -- disposition is used as Journal Index in quest
				local text = q.text
				if text then
					if string.len(text) > 0 then
						newJournalEntrySpeak(text)
					end
					return
				end
			end
		end
	end
end

local GUI_ID_MenuBook_page_1 = tes3ui.registerID("MenuBook_page_1")
local GUI_ID_MenuBook_page_2 = tes3ui.registerID("MenuBook_page_2")
local GUI_ID_MenuBook_buttons_left = tes3ui.registerID("MenuBook_buttons_left")
local GUI_ID_MenuBook_buttons_right = tes3ui.registerID("MenuBook_buttons_right")
local GUI_ID_MenuBook_page_number_1 = tes3ui.registerID("MenuBook_page_number_1")
local GUI_ID_MenuBook_page_number_2 = tes3ui.registerID("MenuBook_page_number_2")
local GUI_ID_MenuBook_button_prev = tes3ui.registerID("MenuBook_button_prev")
local GUI_ID_MenuBook_button_next = tes3ui.registerID("MenuBook_button_next")
local GUI_ID_MenuBook_button_close = tes3ui.registerID("MenuBook_button_close")
local GUI_ID_MenuScroll_Close = tes3ui.registerID("MenuScroll_Close")
local GUI_ID_PartHyperText_link = tes3ui.registerID("PartHyperText_link")
local GUI_ID_PartHyperText_plain_text = tes3ui.registerID("PartHyperText_plain_text")


local isBook -- updated by uiMenuBookActivated(e), uiMenuJournalActivated(e)

local function getSilenceTag(msec)
	return string.format("<silence msec=\"%s\"/>", msec)
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

local function getPageText(page)
	---mwse.log("getPageText(page = %s)", page.name)
	if not page then
		return
	end
	local children = page.children
	if not children then
		return ''
	end
	---if #children <= 0 then
	if table.size(children) <= 0 then
		return ''
	end
	local line
	local text = ''
	local headerColor
	local breaks = 0
	local isJournal = not isBook
	if isJournal then
		for _, el in pairs(children) do
			if el.name == "MenuBook_hypertext" then
				if string.len(el.text) > 0 then
					headerColor = el.color
					break
				end
			end
		end
	end
	for _, el in pairs(children) do
		line = el.text
		if line then
			if isJournal then
				if el.name == "MenuBook_hypertext" then
					breaks = 0
					if string.len(line) > 0 then
						if isSameColor(el.color, headerColor) then
							if not string.find(line,"[%)%.]$") then
								line = line .. "."
							end
						end
					end
				end
			end
		end
		if el.id == -1398 then -- image
			breaks = 0
			text = text .. silenceTag3
		elseif (line ) then
			if (line == '')
			or (line == ' ') then
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
	return text
end


--[[
local red = { 1, 0, 0}
local green = {0, 1, 0}
local blue = {0, 0, 1}
--]]

local link_color = { 43/255, 30/255, 19/255 } ---tes3ui.getPalette("active_color") --link_color
local link_over_color = { 80/255, 56/255, 37/255} -- tes3ui.getPalette("link_over_color")
local link_pressed_color = { 105/255, 74/255, 50/255} -- tes3ui.getPalette("link_pressed_color")
--[[
local disabled_color = tes3ui.getPalette("disabled_color")
local disabled_over_color = tes3ui.getPalette("disabled_over_color")
local disabled_pressed_color = tes3ui.getPalette("disabled_pressed_color")
--]]
local function setButtonColors(button)
	button.color = link_color
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

local bookElement -- set in pagesActivated(e)

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
			text = string.gsub(text, "\r?\n", " ")
		end
		---mwse.log("page.name = %s, text = %s", page.name, text)
		speak(text)
	end
end

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
	local text = getPageText(page_1)
	text = text .. getPageText(page_2)
	if string.len(text) > 0 then
		if not isBook then
-- in journal, replace line break with space as formatting may be weird
			text = string.gsub(text, "\r?\n", " ")
		end
		speak(text)
	end
end

local function delayedReadPage(page)
	SAPIwind.stop()
	timer.start({type = timer.real, callback = function () readPage(page) end , iterations = 1, duration = 0.6})
end

local function delayedReadPages()
	SAPIwind.stop()
	timer.start({type = timer.real, callback = readPages, iterations = 1, duration = 0.6})
end

local function readRawScroll()
	if config.readBooksScrolls > 0 then
-- Fetch the current book text string and speak it.
-- must get it from raw memory to be able to parse daedric font tag
		local text = mwse.memory.readValue({ address = 0x7CA44C, as = "string" })
		if text then
			if string.len(text) > 0 then
				speakRaw(text)
			end
		end
	end
end

-- read scrolls text (scrollable, no paging)
local function uiMenuScrollActivated(e)
	if not e.newlyCreated then
		return
	end
	---mwse.log("uiMenuScrollActivated(e)")
	if config.readBooksScrolls == 0 then
		return
	end
	local menu = e.element
	menu:registerAfter("destroy", checkStopReading)
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
		local button = block:createButton({})
		button.text = "Read"
		setButtonColors(button)
		button:register("mouseClick", readRawScroll)
		menu:updateLayout()
	end
	if config.readBooksScrolls >= 3 then
		readRawScroll()
	end
end

local function checkDelayedReadPages()
	if isBook then
		if config.readBooksScrolls >= 2 then
			delayedReadPages()
		end
	elseif config.readJournal >= 2 then
		delayedReadPages()
	end
end

local inputController -- set in initialized()
local LSHIFT = tes3.scanCode.lShift
local RSHIFT = tes3.scanCode.rShift

local function isShiftDown()
	return inputController:isKeyDown(LSHIFT)
	or inputController:isKeyDown(RSHIFT)
end

-- read Journal pages when clicking a link

local function uiEventJournal(e)
	if e.property == 4294934580 then -- click
		local el = e.block
		local id = el.id
		if config.logLevel >= 3 then
			mwse.log("%s: uiEventJournal(e) e.property = %s, el.id = %s, el.name = %s, el.text = %s",
			modPrefix, e.property, id, el.name, el.text)
		end
		if (id == -32588) -- text links
		or (id == GUI_ID_PartHyperText_link) -- PartHyperText_link -1093
		or (id == GUI_ID_PartHyperText_plain_text) then -- PartHyperText_plain_text --1092
			if not isShiftDown() then -- shift+click may be used by a mod to hide quests, skip it
				local menu = el:getTopLevelMenu()
				if menu.name == "MenuJournal" then
					if menu == tes3ui.getMenuOnTop() then
						local s = el.text
						if s then
							if s == "Read Page" then
								return -- skip reading booth pages in case we use new single page read button
							end
						end
						e.source:forwardEvent(e)
						checkDelayedReadPages()
					end
				end
			end
		end
	end
end

local function onDestroyJournal()
	bookElement = nil
	checkStopReading()
	event.unregister('uiEvent', uiEventJournal)
end

local function onDestroyBook()
	bookElement = nil
	checkStopReading()
end

local function menuBook_buttonClick(e)
	e.source:forwardEvent(e)
	checkDelayedReadPages()
end

local function newReadButton(el, text)
	local parent = el.parent
	parent.autoWidth = true
	parent.autoHeight = true
	local block = parent:createBlock({})
	block.autoWidth = true
	block.autoHeight = true
	---block.absolutePosAlignX = x
	---block.absolutePosAlignY = y
	local button = block:createButton({})
	button.text = text
	setButtonColors(button)
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
			bookElement:registerAfter("destroy", onDestroyBook)
		else
			event.register('uiEvent', uiEventJournal)
			bookElement:registerAfter("destroy", onDestroyJournal)
		end

		local page_1 = bookElement:findChild(GUI_ID_MenuBook_page_1)
		assert(page_1)
		local menuBook_buttons_left = bookElement:findChild(GUI_ID_MenuBook_buttons_left)
		assert(menuBook_buttons_left)
		local menuBook_page_number_1 = menuBook_buttons_left:findChild(GUI_ID_MenuBook_page_number_1)
		assert(menuBook_page_number_1)
		local menuBook_button_prev = menuBook_buttons_left:findChild(GUI_ID_MenuBook_button_prev)
		assert(menuBook_button_prev)
		menuBook_button_prev:register("mouseClick", menuBook_buttonClick)
		local buttonRead1 = newReadButton(menuBook_button_prev, "Read Page")
		assert(buttonRead1)
		buttonRead1:register("mouseClick", function () delayedReadPage(page_1) end )

		local page_2 = bookElement:findChild(GUI_ID_MenuBook_page_2)
		assert(page_2)
		local menuBook_buttons_right = bookElement:findChild(GUI_ID_MenuBook_buttons_right)
		assert(menuBook_buttons_right)
		local menuBook_page_number_2 = menuBook_buttons_right:findChild(GUI_ID_MenuBook_page_number_2)
		assert(menuBook_page_number_2)
		local menuBook_button_next = menuBook_buttons_right:findChild(GUI_ID_MenuBook_button_next)
		assert(menuBook_button_next)
		menuBook_button_next:register("mouseClick", menuBook_buttonClick)
		local buttonRead2 = newReadButton(menuBook_button_next, "Read Page")
		assert(buttonRead2)
		buttonRead2:register("mouseClick", function () delayedReadPage(page_2) end )

		local menuBook_button_close = menuBook_buttons_right:findChild(GUI_ID_MenuBook_button_close)
		local buttonReadBoth = newReadButton(menuBook_button_close, "Read")
		assert(buttonReadBoth)
		buttonReadBoth:register("mouseClick", function () delayedReadPages() return false end)

		bookElement:updateLayout() -- done last as this thing is messing with retrieving things from second page
	end
	if justCreated then
		if isBook then
			if config.readBooksScrolls >= 3 then
				delayedReadPages()
			end
		elseif config.readJournal >= 3 then
			delayedReadPages()
		end
	end
end

local function uiMenuBookActivated(e)
	---mwse.log("uiMenuBookActivated(e)")
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



-- read dialog Choice answers

local function uiEventDialog(e)
	if e.property == 4294934580 then -- click
		local el = e.block
		if el.name == "MenuDialog_answer_block" then
			local menu = el:getTopLevelMenu()
			if menu == tes3ui.getMenuOnTop() then
				local answer = el.text
				local s = string.match(answer, "^%d+[:%.] (.+)$")
				if s then
					answer = s -- strip answer number if added by UI Expansion
				end
				if not string.multifind(string.lower(answer), {"continue", "goodbye"}, 1, true) then -- skip standard answers
					speak(answer)
					---tes3.messageBox(answer) -- nope conflict with ui expansion number choice feature
				end
			end
		end
	end
end

local function onDestroyDialog()
	checkStopReading()
	event.unregister('uiEvent', uiEventDialog)
end

local function uiMenuDialogActivated(e)
	if not config.readDialogChoice then
		return
	end
	if e.newlyCreated then
		event.register('uiEvent', uiEventDialog)
		e.element:registerAfter("destroy", onDestroyDialog)
	end
end




local ACTI_TYPE = tes3.objectType.activator

-- read signs, banners, roadmarkers
local function activate(e)
	if not (e.activator == player) then
		return
	end
	if not config.readSigns then
		return
	end
	local ref = e.target
	local obj = ref.object
	if not (obj.objectType == ACTI_TYPE) then
		return
	end
	local text = obj.name
	if not text then
		assert(text)
		return
	end
	if text == '' then
		return
	end
	local lcId = string.lower(obj.id)
	local mesh = obj.mesh
	assert(mesh)
	local lcMesh = string.lower(mesh)
	if not string.multifind(lcId, {'banner', 'roadmarker', 'sign', '_inn_'}, 1, true) then
		if not string.multifind(lcMesh, {'banner', 'roadmarker', 'sign', '_inn_'}, 1, true) then
			return
		end
	end
	---mwse.log("text = %s", text)
	speak(text)
	return false -- skip triggering so we also avoid problems if object is set as owned and has no script, that's too common
end

-- begin SUBSTITUTIONS

local SPC = "[!&,%.:;%?]"
-- add a missing space after a special punctuation character
SAPIwind.setSubstitution("("..SPC..")(%a)", "%1 %2")
--[[
-- replace line breaks after a special punctuation character with spacing
["("..SPC..")\r?\n"] = "%1 ",
--]]

local subs = {
-- replace <P> tags in e.g. sc_cureblight_ranged
["<[Pp]/?>"] = "\n",

-- 3E 127 --> 3rd Era 127 e.g. BookSkill_Enchant2
["(%d)[Ee],? ?(%d+)%.?"] = function(digit, year)
	local th
	if digit == '1' then
		th = 'st'
	elseif digit == '2' then
		th = 'nd'
	elseif digit == '3' then
		th = 'rd'
	else
		th = 'th'
	end
	return string.format("%s%s Era %s. ", digit, th, year)
end,

-- weird, but some books have lines ending with only \r and no \n.
-- They show fine in the construction set, but sound with no pause
["\r$"] = "\n",

-- replace * in bk_hospitality_papers scroll *Certification of Hospitality*<BR>
["%*(.*)%*<[Bb][Rr]>"] = "%1\n",

-- replace double with single spaces
["%s%s"] = " ",

-- replace weird Wordprocessor characters
["[\130]"] = ",",
["[\096\145\146]"] = "'",
["[\147\148]"] = '"',

-- fix sound of dialog journal ending like: Elone, 'Tell You what'.
["'([^']+)'%."] = "%1%.",

-- "Hla" -> "la"
["[hH]([lL][aeiouAEIOU]%A+)"] = "%1",

-- "Redguard" --> "Red-guard"
["([rR][eE][dD])([gG][uU][aA][rR][dD])"] = "%1-%2",

-- "Gra-" --> "Ghraa-"
["(%A[dDgG])([rR][aA])(%A)"] = "%1h%2a%3",

-- aedra --> aeddra
["(%A[aA][eE])([dD])([rR][aA]%A)"] = "%1%2%2%3",

-- "Gro-" --> "Ghro-"
["(%A[dDgG])([rR][oO])(%A)"] = "%1h%2%3",

-- single letter I as roman 1 in titles, II is already recognized as 2
["([Aa]ct )I([%p%s$])"] = "%11%2",
["([Bb]ook )I([%p%s$])"] = "%11%2",
["([Cc]hapter )I([%p%s$])"] = "%11%2",
["([Ss]cene )I([%p%s$])"] = "%11%2",
["([Vv]olume )I([%p%s$])"] = "%11%2",

["[Vv]ol([%s%p])"] = "Volume%1",

["([Aa]ntiochus )I([%p%s$])"] = "%11%2",
["([Cc]assynder )I([%p%s$])"] = "%11%2",
["([Cc]ephorus )I([%p%s$])"] = "%11%2",
["([Kk]atariah )I([%p%s$])"] = "%11%2",
["([Kk]intyra )I([%p%s$])"] = "%11%2",
["([Ma]Magnus )I([%p%s$])"] = "%11%2",
["([Pp]elagius )I([%p%s$])"] = "%11%2",
["([Tt]iber )I([%p%s$])"] = "%11%2",
["([Uu]riel )I([%p%s$])"] = "%11%2",


["([^%s]?)([Bb]a)(l%s)"] = "%1%2a%3", -- Bal --> Baal
["([^%s]?)([Ss]o)(r%s)"] = "%1%2o%3", -- Sor --> Soor
["([^%s]?)[Uu][Ss](%s)"] = "%1as%2", -- us --> as


---["(%d+)%s?[gG][pP](%p?)$"] = "%1 gold pieces%2", -- 20gp --> 20 gold pieces
["(%d+)%s?[gG][pP]?(%p?)$"] = "%1 gold pieces%2", -- 20gp, 20g --> 20 gold pieces

["([bB])attlemage"] = "%1attle-mage",
["[Mm]orrowind's"] = "Morro-wind's",
["([Tt])hu'um"] = "%1huum",
["%s([Ff]yr)[%s%p$]"] = "Feer",
["%s([Mm][aA][rR])(%p)"] = "%1 %2", -- "Molag Mar." --> "Molag Mar ." else it sounds like "Molag March"

}

for k, v in pairs(subs) do
	SAPIwind.setSubstitution(k,v)
end

-- end SUBSTITUTIONS



local function loaded()
	bookElement = nil
	player = tes3.player
	local fMessageTimePerChar = tes3.findGMST(tes3.gmst.fMessageTimePerChar)
	if fMessageTimePerChar then
		timePerChar = fMessageTimePerChar.value
	else
		timePerChar = 0.1
	end
	local playerData = player.data
	if not playerData then
		return
	end
	knownDaedricLetters = playerData.raKnownDaedricLetters
	if not knownDaedricLetters then
		knownDaedricLetters = {}
	end
	if not (type(knownDaedricLetters) == 'table') then
		knownDaedricLetters = {}
	end
end

local function save()
	local playerData = player.data
	if not playerData then
		return
	end
	playerData.raKnownDaedricLetters = knownDaedricLetters
end




local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	---mwse.log("modConfigReady")
	local template = mwse.mcm.createTemplate(mcmName)

	---template:saveOnClose(configName, config)
	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Preferences",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.2
			self.elements.sideToSideBlock.children[2].widthProportional = 0.8
		end
	}
	preferences.sidebar:createInfo{text = mcmName .. "\n\nby " .. author
	}

	-- Feature controls
	local controls = preferences:createCategory{label = "What do you want to read today?\n"}

	controls:createSlider{
		label = "Volume",
		description = "Reading Volume (default: 50)",
		variable = createConfigVariable("volume")
		,min = 0, max = 100, step = 1, jump = 5
	}

	controls:createDropdown{
		label = "Language Code:",
		description = "The Microsoft SAPI language code used to select voices.\n"
		.."Note: you must have at least one male and one female voices installed and working for that language code."
		.."\nNot all voices may work, for instance I have installed all the listed voices, but only the US and UK voices seem to work in my setup."
		.."\n1.  409 English (United States) e.g. Zira, David, Mark."
		.."\n2.  809 English (United Kingdom) e.g. George, Hazel."
		.."\n3.  C09 English (Australia) e.g. James, Catherine."
		.."\n4. 1009 English (Canada) e.g. Richard, Linda."
		.."\n5. 4009 English (India) e.g. Ravi, Heera.",
		options = {
			{ label = "1.  409 English (United States)", value = 1 },
			{ label = "2.  809 English (United Kingdom)", value = 2 },
			{ label = "3.  C09 English (Australia)", value = 3 },
			{ label = "4. 1009 English (Canada)", value = 4 },
			{ label = "5. 4009 English (India)", value = 5 },
		},
		variable = createConfigVariable("language")
	}

	local des1 = "\n3. will start reading on opening and pressing links and buttons."
		.."\n2. will start reading on pressing links and buttons."
		.."\n1. will require to press the Read button."
		.."\n0. Disabled."
		.."\n1. Enabled."
		.."\n2. Enabled, On Link Click."
		.."\n3. Enabled, On Link Click, Automatic."

	local opt1 = {
		{ label = "0. Disabled", value = 0 },
		{ label = "1. Enabled", value = 1 },
		{ label = "2. Enabled, On Link Click", value = 2 },
		{ label = "3. Enabled, On Link Click, Automatic", value = 3 }
	}

	controls:createOnOffButton{
		label = "Keep reading on menu close",
		description = "Toggles automatic read stopping when you close a menu.",
		variable = createConfigVariable("keepReadingOnMenuClose")
	}
	controls:createKeyBinder({
		label = "Stop reading Hotkey", allowCombinations = true,
		description = 'A quick key combination you can press/release to stop reading (some Alt combo is suggested to avoid interfering with normal text writing).',
		variable = mwse.mcm:createTableVariable({
			id = "stopReadingKey", table = config,
			defaultSetting = defaultConfig.stopReadingKey,
			restartRequired = false,
		})
	})
	controls:createDropdown{
		label = "Read Books & Scrolls:",
		description = "Read Books & Scrolls options." .. des1,
		options = opt1,
		variable = createConfigVariable("readBooksScrolls")
	}
	controls:createDropdown{
		label = "Read Journal:",
		description = "Read Journal options." .. des1,
		options = opt1,
		variable = createConfigVariable("readJournal")
	}
	controls:createOnOffButton{
		label = "Read updated Journal entry",
		description = "You can read last updated Journal entry aloud.",
		variable = createConfigVariable("readLastJournal")
	}
	controls:createOnOffButton{
		label = "Read Dialog Choice",
		description = "You can read your selected dialog choice aloud.",
		variable = createConfigVariable("readDialogChoice")
	}
	controls:createOnOffButton{
		label = "Read Signs",
		description = "You can read signs, banners and road markers aloud.",
		variable = createConfigVariable("readSigns")
	}
	controls:createOnOffButton{
		label = "Daedric Translation",
		description = "Show translated Daedric text from enchanted scrolls."
		.."\nIf the Daedric skill is enabled only already known Daedric letters will be visible.",
		variable = createConfigVariable("daedricTranslation")
	}
	controls:createOnOffButton{
		label = "Read Daedric Translation",
		description = "Read aloud translated Daedric text from enchanted scrolls."
		.."\nIf the Daedric skill is enabled only already known Daedric letters will be read.",
		variable = createConfigVariable("readDaedricTranslation")
	}
	if skillModule then
		controls:createOnOffButton{
			label = "Daedric Skill",
			description = "The Daedric Skill determines your effectiveness at reading and translating Daedric text in enchanted scrolls."
			.."\nTo increase the skill, try to read and translate some enchanted scrolls."
			.."\nNote: changes to the skill display are effective on reload.",
			variable = createConfigVariable("daedricSkill")
		}
	end
	controls:createDropdown{
		label = "Log level:",
		description = "The amount of text logged to MWSE.log."
		.."\n0. Disabled."
		.."\n1. Low (input text)."
		.."\n2. Medium (input + processed text)."
		.."\n3. High (input + processed text + extras).",
		options = {
			{ label = "0. Disabled", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
		},
		variable = createConfigVariable("logLevel")
	}

	mwse.mcm.register(template)
	logConfig(config, {{indent = false}})
end
event.register('modConfigReady', modConfigReady)

local function initialized()
	inputController = tes3.worldController.inputController
	event.register('loaded', loaded)
	event.register('save', save)
	event.register("uiActivated", uiMenuScrollActivated, { filter = "MenuScroll" })
	event.register("uiActivated", uiMenuBookActivated, { filter = "MenuBook" })
	event.register("uiActivated", uiMenuJournalActivated, { filter = "MenuJournal" })
	event.register("uiActivated", uiMenuDialogActivated, { filter = "MenuDialog" })
	event.register('journal', journal)
	event.register('activate', activate)
	mwse.log("%s: initialized", modPrefix)
end
event.register('initialized', initialized)




--[[
local function doubleConsonants(s)
	mwse.log(s)
	if not s then
		return ''
	end
	local ls = string.lower(s)
	local c
	local r = ''
	for i = 1, 3 do
		c = string.sub(ls, i, i)
		if c:find("[aeiou]") then
			r = r .. c
		else -- a consonant
			r = r .. c .. c
		end
	end
	return r
end

SAPIwind.setSubstitution(
	"[%s%p](%a%a%a)[%s%p]",	--  with 3 letters groups...
	doubleConsonants(s)		-- double consonants for better reading output
)
--]]

--[[
local sw = {}
sw["[Vv]vardenfell"] = "v aa1 r d ah0 n f eh1 l"
sw["[Ss]eyda [nN]een"] = "s ey1 d ah0 n iy1 n"
sw["([gG]ra)[-%s]"] = "g r ae1"
sw["([gG]ro)[-%s]"] = "g r ow1"
sw["([gG]uard)"] = "g aa2 r d"
sw["([Hh]la [Oo]ad)"] = "hh l ae1 ow1 d"
sw["([Kk]huul)"] = "k uw1 l"
sw["([rR]edguard)"] = "r eh1 d g aa2 r d"
sw["([Ss]olstheim)"] = "s ao1 l s t hh ay2 m"
sw["([Vv]odunius)"] = "v ow1 d ah1 n iy0 ih0 s"
sw["([Gg]ilnith)"] = "g ih1 l n ih0 th"
sw["([Ll]lendo)"] = "l eh1 n d ow0"
sw["([Mm]ebestien [Ee]nce)"] = "m eh1 b ah0 s t ah0 n eh0 n s"
sw["([Nn]im)"] = "n ih1 m"
sw["([Oo]mavel)"] = "ow0 m ae1 v ah0 l"
for k, v in pairs(sw) do
	---SAPIwind.setSubstitution(k,	"<PRON SYM=\"" .. v .. "\">%1</PRON>")
	SAPIwind.setSubstitution(k,	"<PRON SYM=\"" .. v .. "\"/>")
end
--]]


--[[
SAPIwind.addProperPronunciation("gra","g r ae1")
SAPIwind.addProperPronunciation("gro","g r ow1")
--]]
---<PRON SYM = "h eh l ow"/>
--[[
uiEvent is triggered through various UI events. This includes scrolling through panes, clicking buttons, selecting icons, or a host of other UI-related activities.
Event Data
var1 number. Read-only. One of two undefined variables related to the event.
parent tes3uiElement. Read-only. The calling element’s parent.
block tes3uiElement. Read-only. The UI element that is firing this event.
property number. Read-only. The property identifier that is being triggered.
var2 number. Read-only. One of two undefined variables related to the event.

https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ee431828(v=vs.85)

local function sayTokenizedDialog(text, mobile)
	local params = getSpeechParamsForReference(mobile.reference)
	SAPIwind.speak(text, params)
end

-- voices are too crappy at the moment /abot
local function speakAllOfDialogMenu()
	checkStopReading()

	local MenuDialog = tes3ui.findMenu("MenuDialog")
	local MenuDialog_hyper = tes3ui.registerID("MenuDialog_hyper")
	local mobile = MenuDialog:getPropertyObject("PartHyperText_actor")

	local MenuDialog_scroll_pane = MenuDialog:findChild("MenuDialog_scroll_pane")
	assert(MenuDialog_scroll_pane)
	for _, child in ipairs(MenuDialog_scroll_pane.widget.contentPane.children) do
		if (child.id == MenuDialog_hyper and not child:getPropertyBool("SAPIwind:read")) then
			sayTokenizedDialog(child.text, mobile)
			child:setPropertyBool("SAPIwind:read", true)
		end
	end
end

local function onShowDialogMenu(e)
	if (not e.newlyCreated) then
		return
	end

	-- Get who we are talking to.
	local mobile = e.element:getPropertyObject("PartHyperText_actor")
	if (mobile.reference.object.objectType ~= tes3.objectType.npc) then
		return
	end

	-- Fetch the current dialog text string and speak it.
	speakAllOfDialogMenu()

	--
	e.element:registerAfter("update", speakAllOfDialogMenu)
	e.element:registerAfter("destroy", checkStopReading())
end
event.register("uiActivated", onShowDialogMenu, { filter = "MenuDialog" })
--]]
