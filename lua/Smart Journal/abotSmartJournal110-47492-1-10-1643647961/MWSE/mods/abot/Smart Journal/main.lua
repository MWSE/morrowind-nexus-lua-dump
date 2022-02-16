-- begin tweakables
local defaultConfig = {
clearTopicsWithNoEntries = true, -- clear topics with no entries yet from the journal
collapseDates = true, -- collapse journal paragraphs having the same date header
skipLinksInsideWords = true, -- skip links contained inside journal words
upgradeJournalMessage = true, -- add quest Name information to sJournalEntry e.g. from 'Your journal has been updated.' to 'You take a note in your Journal under section "Antabolis Informant"'
questPrefix = 1, -- add a prefix in order to group quest names (0 = No, 1 = source mod loading index, 2 = source mod condensed name, 3 = quest id)
questHintFirstHeardFrom = true, -- add who you talked with to quest hint
questHintQuestInfo = true, -- add last quest entry to quest hint
questHintQuestId = true, -- add quest id and current journal index to quest hint
questHintSourceMod = true, -- add source mod name to quest hint
questHintAltSourceInfo = true, -- add source mod Author and Info to quest hint while Alt key pressed
questHintCtrlAltURL = true, -- open first URL found in mod Info while Ctrl+Alt keys are pressed
adjustBookmarkWidth = false, -- adjust bookmark size to fit more text
logMissingQuestNames = false, -- Log Journal entries possibly missing the Quest Name flag
logLevel = 0, -- 0 = Low, 1 = Medium, 2 = High
}
-- end tweakables

local author = 'abot'
local modName = 'Smart Journal'
local modPrefix = author .. '/'.. modName

local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local URL_PATTERN = 'https?://[_~a-zA-Z0-9/#\\=&;%.%%%+%-%?]+'

-- return first found URL string in text, or nil
local function getFirstURL(text_with_URLs)
	local s = string.match(text_with_URLs, URL_PATTERN)
	if config.logLevel >= 2 then
		mwse.log("%s getFirstURL = %s", modPrefix, s)
	end
	return s
end

--[[
local function getURLs(text_with_URLs)
	local t = string.gmatch(text_with_URLs, URL_PATTERN)
	---for k, v in ipairs(t) do
		---mwse.log("URLs[%s] = %s", k, v)
	---end
	return t
end
--]]

local function ucfirst(first, rest)
   return first:upper() .. rest:lower()
end

local function getCondensedPrefix(modFileName) -- rather slow one so better to loop it once
	local s = string.sub(modFileName, 1, -5) -- strip the file extension e.g. from Morrowind.esm to Morrowind
	-- strip common clutter
	local s1 = string.gsub(s,"merged","")
	local s2 = string.gsub(s1,"clean","")
	local s3 = string.gsub(s2,"version","")
	local s4 = string.gsub(s3,"ver","")
	local s5 = string.gsub(s4,"the%W","")
	local s6 = string.gsub(s5,"v *%d+%.*%w*$","") -- strip "v <someversionnumber>"
	local s7 = string.gsub(s6, "(%a)([%w']*)", ucfirst) -- CamelCase
	--- return string.gsub(s7,"[%d%W%+%-%?%!%]","") -- strip digits and not-word
	return string.gsub(s7,"[aeiou%d%W%+%-%?%!%>]","") -- strip vowels, digits and not-word
end

-- initialized in modConfigReady() event
local modData = {}
local sJournalEntryGMST, sJournalEntry

local function initModData() -- called in modConfigReady()
	local modList = tes3.getModList()
	modData = {}
	for loadingIndex, modFileName in ipairs(modList) do
		modData[modFileName] = { index = loadingIndex, prefix = getCondensedPrefix(modFileName) }
	end
end

local GUI_ID_MenuBook_page_1 = tes3ui.registerID("MenuBook_page_1")
local GUI_ID_MenuBook_page_2 = tes3ui.registerID("MenuBook_page_2")
local GUI_ID_MenuBook_hypertext = tes3ui.registerID("MenuBook_hypertext")
local GUI_ID_MenuJournal_bookmark = tes3ui.registerID("MenuJournal_bookmark")
local GUI_ID_MenuJournal_button_bookmark_topics = tes3ui.registerID("MenuJournal_button_bookmark_topics")
local GUI_ID_MenuJournal_button_bookmark_topics_pressed = tes3ui.registerID("MenuJournal_button_bookmark_topics_pressed")
local GUI_ID_MenuJournal_bookmark_layout = tes3ui.registerID("MenuJournal_bookmark_layout")
local GUI_ID_MenuJournal_focus = tes3ui.registerID("MenuJournal_focus")
local GUI_ID_MenuJournal_button_bookmark_quests_active = tes3ui.registerID("MenuJournal_button_bookmark_quests_active")
local GUI_ID_MenuJournal_button_bookmark_quests_all = tes3ui.registerID("MenuJournal_button_bookmark_quests_all")
local GUI_ID_MenuBook_button_take = tes3ui.registerID("MenuBook_button_take")
local GUI_ID_MenuJournal_button_bookmark_quests = tes3ui.registerID("MenuJournal_button_bookmark_quests")
--[[
local GUI_ID_MenuBook_button_prev = tes3ui.registerID("MenuBook_button_prev")
local GUI_ID_MenuBook_button_next = tes3ui.registerID("MenuBook_button_next")
--]]

---local GUI_ID_MenuJournal_selecttopics = tes3ui.registerID("MenuJournal_selecttopics")
local GUI_ID_MenuJournal_topicscroll = tes3ui.registerID("MenuJournal_topicscroll")
local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

local questPrefix = defaultConfig.questPrefix -- set in checkQuestNames(), modConfigReady()

local function getPrefixedQuest(modNam)
	local data = modData[modNam]
	local s
	if questPrefix == 1 then
		s = string.format("%04d", data.index)
	else
		s = data.prefix -- precalculated and stored for speed
	end
	return s
end

-- cleared in load()
local questsByName = {}
local questHints = {}

local LALT = tes3.scanCode.lAlt
local LCTRL = tes3.scanCode.lCtrl

 -- initialized in modConfigReady()
local inputController

local function getModInfo(modFileName)
	local f = io.open("Data Files/" .. modFileName, "rb")
	if not f then
		return false, false
	end
	f:seek("set", 32)
	if not f then
		return false, false
	end
	local auth = f:read(32)
	if not auth then
		f:close()
		return false, false
	end
	auth = string.gsub(auth,"%z","")
	---mwse.log(auth)
	local info = f:read(256)
	if not info then
		f:close()
		return false, false
	end
	info = string.gsub(info, "%z", "")
	---mwse.log(info)
	f:close()
	return auth, info
end

local quests -- cashing once from dialogue database

local function initQuests() -- called in loaded() as they do not seem to be yet ok in initialized/modConfigReady
	if quests then
		return
	end

	quests = {}
	local text, questId

	local noLog = not config.logMissingQuestNames
	local logLevelGT1 = config.logLevel > 1

	local dialogues = tes3.dataHandler.nonDynamicData.dialogues

	if noLog then
		for d in tes3.iterate(dialogues) do
			if d.type == 4 then -- journal
				text = d:loadQuestName()
				---assert(text) -- this may still be nil!
				if text then -- still important!
					--[[ assert(string.len(text) > 0)
					if string.len(text) > 0 then -- ok this seems safe ]]
						questId = d.id
						---local s = text:gsub('[@#]', '') -- not needed here
						--[[if not (s == text ) then
							mwse.log("%s: initQuests() t = %s,\ns = %s", modPrefix, text, s)
						end
						text = s]]
						if logLevelGT1 then
							mwse.log('%s: initQuests() quests["%s"] = {name = "%s", sourceMod = "%s"}', modPrefix, questId, text, d.sourceMod)
						end
						quests[questId] = {name = text, sourceMod = d.sourceMod}
					---end
				end -- if text
			end -- if d.type
		end -- for d
		return
	end -- if noLog

	local missingQuestNames = {}
	local disposition, flags

	for d in tes3.iterate(dialogues) do
		if d.type == 4 then -- journal
			for info in tes3.iterate(d.info) do
				assert(info)
				if info then
					disposition = info.disposition
					if disposition then
						if disposition == 0 then -- disposition used as quest index, 0 should be quest name
							text = info.text
							if text then -- important!
								assert(string.len(text) > 0)
								if string.len(text) > 0 then
									questId = d.id
									flags = info.objectFlags
									local s = text:gsub('[@#]', '') -- not needed here
									if not (s == text ) then
										mwse.log("%s: initQuests() t = %s,\ns = %s", modPrefix, text, s)
									end
									text = text:gsub('[@#]', '') -- strip tags
									if ( -- quest name marker flag, plus not relevant bit 0
										(flags == 73)
									 or (flags == 72)
									) then
										if logLevelGT1 then
											mwse.log('%s: initQuests() quests["%s"] = {name = "%s", sourceMod = "%s"}', modPrefix, questId, text, d.sourceMod)
										end
										quests[questId] = {name = text, sourceMod = d.sourceMod}
										break -- for info
									elseif not string.multifind(text:lower(), {'--','dummy'}, 1, true) then -- skip Antares', TR dummy entries
										table.insert(missingQuestNames, string.format('"%s" Journal "%s" has INFO %s "%s" with index %s, but is NOT set as Quest Name\n',
											info.sourceMod, questId, info.id, text, disposition))
									end -- if flags
								end -- if string.len(text)
							end -- if text
						end -- if disposition == 0
					end -- if disposition
				end -- if info
			end -- for info
		end -- if d.type
	end -- for d

	if #missingQuestNames > 0 then
		table.sort(missingQuestNames)
		text = string.format("\n%s: list of journal entries that may be missing the Quest Name flag\n", modPrefix)
		for _, v in ipairs(missingQuestNames) do
			text = text .. v
		end
		mwse.log(text)
	end

end

local function calcQuestsByName()
	local etime = os.clock()

	local questName, prefix
	local fmt = "%s > %s"
	for id, q in pairs(quests) do
		questName = q.name
		if questPrefix == 3 then
			prefix = string.format(fmt, id, questName)
		elseif questPrefix > 0 then
			prefix = string.format(fmt, getPrefixedQuest(q.sourceMod), questName)
		else
			prefix = questName
		end
		questsByName[questName] = {prefixed = prefix}
		if not questsByName[questName].questId then
			questsByName[questName].questId = id
		end
		if config.logLevel >= 2 then
			mwse.log('%s: calcQuestsByName() questsByName["%s"] = {prefixed = "%s", questId = "%s"}', modPrefix, questName, prefix, id)
		end
	end

	if config.logLevel >= 2 then
		mwse.log("%s: calcQuestsByName() elapsed time: %.5f, count = %s", modPrefix, os.clock() - etime, #questsByName)
	end

end

local function getHintsOrQuestPrefixOn()
	return (config.questPrefix > 0)
	or config.questHintFirstHeardFrom
	or config.questHintQuestInfo
	or config.questHintQuestId
	or config.questHintSourceMod
	or config.questHintAltSourceInfo
	or config.questHintCtrlAltURL
end

local function checkQuestNames()
	questPrefix = config.questPrefix
	if getHintsOrQuestPrefixOn() then
		calcQuestsByName()
	end
end

local function journal(e)
	if not config.upgradeJournalMessage then
		return
	end
	local topic = e.topic
	if not topic then
		return
	end
	local questId = topic.id
	local q = quests[questId]
	if not q then
		return
	end
	local questName = q.name
	if questName then
		if questsByName[questName] then
			questsByName[questName].questId = questId
		end
		if config.logLevel > 0 then
			mwse.log('%s: journal(e) index = %s, topic = "%s", questName = "%s"', modPrefix, e.index, questId, questName)
		end
		--- too late for this sJournalEntryGMST.value = string.format('You take a note in your Journal under section "%s".', questName)
		tes3.messageBox('You take a note in your Journal under section "%s".', questName)
	end
end
event.register('journal', journal, {priority = 1})

local function stripFalseLinks(text)
	local s = string.gsub(text, "@(%w+)#(%w+)", "%1%2")
	local s1 = string.gsub(s, "(%w+)@(%w+)#", "%1%2")
	if not (s1 == text) then
		--mwse.log("before:\n%s\nafter:\n%s", text, s1)
		text = s1
	end
	return text
end

local function skipFalseLinks(menuBook_page)
	if not menuBook_page then
		return
	end
	if not menuBook_page.visible then
		return
	end
	local children = menuBook_page.children
	if not children then
		return
	end
	---if #children < 1 then
		---return
	---end
	for _, el in pairs(children) do
		if el.id == GUI_ID_MenuBook_hypertext then
			el.text = stripFalseLinks(el.text)
		end
	end
end

local function collapseDateHeader(menuBook_page)
-- group paragraphs with the same date header together
	if not menuBook_page then
		return
	end
	if not menuBook_page.visible then
		return
	end
	local children = menuBook_page.children
	if not children then
		return
	end
	---if #children < 1 then
		---return
	---end
	---mwse.log("collapseDateHeader(menuBook_page = %s)", menuBook_page)
	local headers = {}
	local text, count
	local skip = config.skipLinksInsideWords
	for _, el in pairs(children) do
		if el.id == GUI_ID_MenuBook_hypertext then
			text = el.text
			if not headers[text] then
				if string.match(text, "^%d+ .+%d+%)$") then
					headers[text] = 1
				end
			end
		end
		if skip then
			el.text = stripFalseLinks(el.text)
		end
	end
	local update = false
	for _, el in pairs(children) do
		if el.id == GUI_ID_MenuBook_hypertext then
			text = el.text
			count = headers[text]
			if count then
				if count == 1 then -- skip first
					headers[text] = 2
				else
					update = true
					--- el.disabled = true -- maybe safer if some other mod is looking for it?
					el:destroy()
				end
			end
		end
	end
	if update then
		menuBook_page:updateLayout()
	end
end

local sortFunc = function(a, b)
	return a.text < b.text
end

local keys = {}
local elements = {}

local function sortQuests(children)
	local etime = os.clock();
	keys = {}
	elements = {}
	local n = 0
	for _, el in pairs(children) do
		---assert(el)
		if el.visible then
			---assert(not el.disabled)
			n = n + 1
			keys[n] = { text = el.text, dialogue = el:getPropertyObject('PartHyperText_dialog') }
			---mwse.log("keys[%s] = %s", n, el.text)
			elements[n] = el
		end
	end
	table.sort(keys, sortFunc)
	local k
	for i, el in pairs(elements) do
		k = keys[i]
		if not (el.text == k.text) then
			el.text = k.text
			el:setPropertyObject('PartHyperText_dialog', k.dialogue )
			---mwse.log("children[%s].text = %s", i, el.text)
		end
	end
	if config.logLevel >= 2 then
		mwse.log("%s sortQuests() elapsed time: %.5f", modPrefix, os.clock() - etime)
	end
end

local hintMaxWidth, hintMaxHeight -- set in modConfigReady()

local function getHint(e)
	--[[local t = e.source.text
	if not t then
		assert(t)
		return
	end]]
	local d = e.source:getPropertyObject('PartHyperText_dialog')
	if not d then
		assert(d)
		return
	end
	local questName = d.id -- should be the original quest name
	--[[if config.logLevel >= 3 then
		-- both d.journal and d.type can be nil here
		mwse.log("%s t = %s, questName = %s, d.journalIndex = %s, d.type = %s", modPrefix, t, questName, d.journalIndex, d.type, d.sourceMod)
	end]]

	local qd = questsByName[questName]
	---assert(qd)
	local questId = qd.questId
	---assert(questId)
	local journalIndex = tes3.getJournalIndex({id = questId})
	local q = quests[questId]
	---assert(q)
	local sourceMod = q.sourceMod
	---assert(sourceMod)
	local d_info_iterator = d.info
	---assert(d_info_iterator)

	local tip = false
	local hint = ''

	if d_info_iterator then
		if config.questHintFirstHeardFrom then
			local actor, actorName, ref, cell, cellName
			local heard = {}
			local i = 1
			for info in tes3.iterate(d_info_iterator) do
				actor = info.firstHeardFrom
				if actor then
					if actor.cloneCount == 1 then
						actorName = actor.name
						ref = tes3.getReference(actor.id)
						if ref then
							cell = ref.cell
							if cell then
								cellName = cell.name
								if cellName then
									if not cell.isInterior then
										cellName = string.format("%s (%s, %s)", cellName, cell.gridX, cell.gridY)
									end
									heard[actorName] = {indx = i, cnam = cellName}
									i = i + 1
									tip = true
								end -- if cellName
							end -- if cell
						end -- if ref
					end -- if actor.cloneCount
					---break -- exit loop at first actor found
				end -- if actor
			end -- for info
			if tip then
				local function byIndex(a, b)
					return a.indx < b.indx
				end
				table.sort(heard, byIndex)
				for aname, v in pairs(heard) do
					hint = string.format("%sHeard from %s (now in %s)\n", hint, aname, v.cnam)
				end
				--[[if config.logLevel >= 3 then
					mwse.log("%s getHint(e) quest %s %s", modPrefix, questId, hint)
				end]]
				hint = hint .. "\n"
			end
		end -- if config.questHintFirstHeardFrom

		if config.questHintQuestInfo then
			local disposition, s
			for info in tes3.iterate(d_info_iterator) do
				disposition = info.disposition
				--[[if config.logLevel >= 2 then
					mwse.log("%s info.disposition = %s, info.text = %s", modPrefix, disposition, info.text)
				end]]
				if journalIndex == disposition then
					s = info.text
					if s then
						if string.len(s) > 0 then
							s = s:gsub('[@#]', '') -- strip tags
							---s = s:gsub('%.[^\n]', '%.\n') -- add line breaks
							hint = string.format("%s%s\n\n", hint, s)
							tip = true
							break -- exit loop when current journalIndex dialog info found
						end -- if s
					end -- if string.len(s)
				end -- if journalIndex == disposition
			end -- for info
		end -- if config.questHintQuestInfo

	end -- if d_info_iterator

	if config.questHintQuestId then
		if journalIndex > 0 then
			hint = string.format('%sGetJournalIndex("%s") == %s\n\n', hint, questId, journalIndex)
			tip = true
		end
	end

	if config.questHintSourceMod then
		---if sourceMod then
			hint = string.format("%sPlugin %03d %s\n\n", hint, modData[sourceMod].index, sourceMod)
			tip = true
		---end
	end

	if config.questHintAltSourceInfo then
		---if sourceMod then
			if inputController:isKeyDown(LALT) then
				local modAuth, modInfo = getModInfo(sourceMod)
				if modAuth then
					hint = string.format("%sAuthor: %s\n\n", hint, modAuth)
					tip = true
				end
				if modInfo then
					hint = string.format("%sInfo: %s\n\n", hint, modInfo)
					tip = true
					if config.questHintCtrlAltURL then
						if inputController:isKeyDown(LCTRL) then
							local s = getFirstURL(modInfo)
							if s then
								---mwse.log("os.openURL('%s')", s)
								---tes3.messageBox(s)
								os.openURL(s)
							end
						end
					end
				end
			end
		---end
	end

	if tip then
		hint = string.sub(hint, 1, -3) -- strip last \n\n
		local tm = tes3ui.createTooltipMenu()
		local bl = tm:createBlock({})
		bl.maxHeight = hintMaxHeight
		bl.maxWidth = hintMaxWidth
		bl.paddingAllSides = 4
		---bl.paddingBottom = 4
		bl.autoWidth = true
		bl.autoHeight = true
		local lbl = bl:createLabel({text = hint})
		lbl.wrapText = true
	end

end

local function updateBookmark(menuJournal_bookmark)
	if not menuJournal_bookmark then
		return
	end
	if not menuJournal_bookmark.visible then
		return
	end

	local menuJournal_bookmark_layout = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_bookmark_layout)
	if not menuJournal_bookmark_layout then
		return
	end
	--- mwse.log("updateBookmark(menuJournal_bookmark_layout = %s)", menuJournal_bookmark_layout)

	local menuJournal_button_bookmark_topics = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_topics)
	local menuJournal_button_bookmark_topics_pressed
	if menuJournal_button_bookmark_topics then
		menuJournal_button_bookmark_topics_pressed = menuJournal_button_bookmark_topics:findChild(GUI_ID_MenuJournal_button_bookmark_topics_pressed)
	end

	local menuJournal_topicscroll = menuJournal_bookmark_layout:findChild(GUI_ID_MenuJournal_topicscroll)
	if not menuJournal_topicscroll then
		return -- it happens
	end
	local partScrollPane_pane = menuJournal_topicscroll:findChild(GUI_ID_PartScrollPane_pane)
	if not partScrollPane_pane then
		return
	end

	---assert(partScrollPane_pane)
	local children = partScrollPane_pane.children
	if not children then
		return
	end

	---if #children <= 0 then
		---return
	---end

	local areTopics = 0
	if menuJournal_button_bookmark_topics_pressed then
		if menuJournal_button_bookmark_topics_pressed.visible then
			local menuJournal_focus = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_focus)
			if menuJournal_focus then
				areTopics = 1
			else
				areTopics = 2
			end
		end
	end

	---mwse.log("areTopics = %s", areTopics)
	local key, value, prefixed, dialogue
	local update = false

	if areTopics == 0 then -- quest list over bookmark
		if getHintsOrQuestPrefixOn() then
			update = true
			---local sortNeeded = false
			for _, el in pairs(children) do
				if el then
					key = el.text
					if key then
						value = questsByName[key]
						if value then
							if questPrefix > 0 then
								prefixed = value.prefixed
								if not (prefixed == key ) then
									---sortNeeded = true
									el.text = prefixed
								end
							end
							--if not el:getPropertyBool('hasHint') then
							--el:setPropertyBool('hasHint', true)
								el:register('help', getHint)
							--end
						end -- if value
					end -- if key
				end -- if el
			end -- for _, el
			---if sortNeeded then
				sortQuests(children) -- sort quest list
			---end
		end -- if getHintsOrQuestPrefixOn()


	elseif areTopics == 2 then -- journal topics
		if config.clearTopicsWithNoEntries then
			local toDestroy = {}
			for _, el in pairs(children) do
				if el then
					dialogue = el:getPropertyObject('PartHyperText_dialog')
					if dialogue then
						local notHeard = true
						for info in tes3.iterate(dialogue.info) do
							if info.firstHeardFrom then
								notHeard = false
								---mwse.log(GetInfo(info))
								break
							end
						end
						if notHeard then
							update = true
							table.insert(toDestroy, el)
						end
					end
				end
			end
			if update then
				for _, el in pairs(toDestroy) do
					el:destroy()
				end
			end
		end
	end

	if update then
		partScrollPane_pane:updateLayout()
		local widget = menuJournal_topicscroll.widget
		if widget then
			widget:contentsChanged()
		end
	end

end

local function updateJournalPages(menu)
	if config.collapseDates
	or config.skipLinksInsideWords then
		local page_1 = menu:findChild(GUI_ID_MenuBook_page_1)
		local page_2 = menu:findChild(GUI_ID_MenuBook_page_2)
		if config.collapseDates then
			collapseDateHeader(page_1)
			collapseDateHeader(page_2)
		end
		if config.skipLinksInsideWords then
			skipFalseLinks(page_1)
			skipFalseLinks(page_2)
		end
	end
end

local function updateJournalBookmark(menu)
	if getHintsOrQuestPrefixOn() then
		updateBookmark(menu:findChild(GUI_ID_MenuJournal_bookmark))
	end
end

local function updateJournalElement(menu)
	updateJournalPages(menu)
	updateJournalBookmark(menu)
end

local function onUpdateJournal(e)
	local el = e.source -- one time is element, one time is source...
	---mwse.log("onUpdateJournal %s", el.name)
	updateJournalElement(el)
	el:forwardEvent(e)
end

local function journalButtonClick(e)
	checkQuestNames()
	local el = e.source
	assert(el)
	el:forwardEvent(e)
	local menu = el:getTopLevelMenu()
	assert(menu)
	menu:updateLayout()
end

local function uiActivatedMenuJournal(e)
	local el = e.element
	if e.newlyCreated then
		---checkQuestNames()
		el:register('update', onUpdateJournal)
		---el:register('uiEvent', uiEventJournal)
		local menuBook_button_take = el:findChild(GUI_ID_MenuBook_button_take)
		if menuBook_button_take then
			menuBook_button_take:register("mouseClick", journalButtonClick)
		end
		local menuJournal_bookmark = el:findChild(GUI_ID_MenuJournal_bookmark)
		if menuJournal_bookmark then
			local menuJournal_button_bookmark_quests_active = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_active)
			if menuJournal_button_bookmark_quests_active then
				menuJournal_button_bookmark_quests_active:register("mouseClick", journalButtonClick)
			end
			local menuJournal_button_bookmark_quests_all = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_all)
			if menuJournal_button_bookmark_quests_all then
				menuJournal_button_bookmark_quests_all:register("mouseClick", journalButtonClick)
			end
			local menuJournal_button_bookmark_quests = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests)
			if menuJournal_button_bookmark_quests then
				menuJournal_button_bookmark_quests:register("mouseClick", journalButtonClick)
			end
			if config.adjustBookmarkWidth then
				menuJournal_bookmark.absolutePosAlignX = 0.945
				menuJournal_bookmark.width = 410
				menuJournal_bookmark.height = 572
				menuJournal_bookmark.imageScaleX = 2.49
				menuJournal_bookmark.imageScaleY = 2.3218
				
				local menuJournal_bookmark_layout = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_bookmark_layout)
				---assert(menuJournal_bookmark_layout)
				local menuJournal_topicscroll = menuJournal_bookmark_layout:findChild(GUI_ID_MenuJournal_topicscroll)
				local widget
				if menuJournal_topicscroll then
					local partScrollPane_pane = menuJournal_topicscroll:findChild(GUI_ID_PartScrollPane_pane)
					if partScrollPane_pane then
						widget = menuJournal_topicscroll.widget
						partScrollPane_pane:updateLayout()
					end
					menuJournal_topicscroll:updateLayout()
				end
				menuJournal_bookmark_layout:updateLayout()
				menuJournal_bookmark:updateLayout()
				el:updateLayout()
				if widget then
					widget:contentsChanged()
				end
			end
		end
	end
	---updateJournalElement(el)
end
event.register('uiActivated', uiActivatedMenuJournal, {filter = 'MenuJournal'})

local GUI_ID_MenuDialog_scroll_pane = tes3ui.registerID('MenuDialog_scroll_pane')
local GUI_ID_MenuDialog_notify = tes3ui.registerID('MenuDialog_notify')

local function updateDialog(e)
	local el = e.source:findChild(GUI_ID_MenuDialog_scroll_pane)
	if not el then
		return
	end
	local pane = el:findChild(GUI_ID_PartScrollPane_pane)
	if not pane then
		return
	end
	local visible = not config.upgradeJournalMessage
	for node in table.traverse(pane.children) do
		if node.id == GUI_ID_MenuDialog_notify then
			if node.text then
				if node.text == sJournalEntry then
					if not (node.visible == visible) then
						node.visible = visible
						---el:getTopLevelMenu()::updateLayout()
						return
					end
				end
			end
		end
	end
end

local function uiMenuDialogActivated(e)
	if not e.newlyCreated then
		return
	end
	local el = e.element
	el:registerBefore('update', updateDialog)
	---el:register('update', updateDialog)
	---el:registerAfter('update', updateDialog)
end
event.register('uiActivated', uiMenuDialogActivated, {filter = 'MenuDialog'})



local function getClearTable(t)
	if t then
		for k in pairs(t) do
			t[k] = nil
		end
	end
	t = {}
	return t
end

local function clearTables()
	questsByName = getClearTable(questsByName)
	questHints = getClearTable(questHints)
end
event.register('load', clearTables)


local function loaded()
	initQuests()
	---checkQuestNames()
	---mwse.log(modPrefix .. ' loaded')
end
event.register('loaded', loaded)

local function logConfig(cfg, options)
	mwse.log(json.encode(cfg, options))
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable({id = varId, table = config})
end

--[[local function copyFile(sourcePath, destPath)
	local sourceFile = io.open(sourcePath, 'rb')
	local destFile = io.open(destPath, 'wb')
	local sourceFileSize, destFileSize
	if (not sourceFile)
	or (not destFile) then
		return false
	end
	local buffSize = 2^13
	local block
	repeat
		block = sourceFile:read(buffSize)
		if block then
			destFile:write(block)
		end
	until not block
	sourceFileSize = sourceFile:seek('end')
	sourceFile:close()
	destFileSize = destFile:seek('end')
	destFile:close()
	local result = (destFileSize == sourceFileSize)
	if result then
		if config.logLevel > 0 then
			mwse.log('%s: copyFile() file "%s" copied to "%s"', modPrefix, sourcePath, destPath)
		end
	else
		local s = string.format('%s: copyFile() error copying file "%s" to "%s"', modPrefix, sourcePath, destPath)
		mwse.log(s)
		tes3.messageBox(s)
	end
	return result
end]]

--[[local texturesPath = tes3.installDirectory .. '\\Data Files\\Textures\\'
local backupTexture = texturesPath .. 'Tx_menubook_bookmark_ab01sjBack.dds'
local stdDDStexture = texturesPath .. 'Tx_menubook_bookmark.dds'
local wideTexture = texturesPath .. 'Tx_menubook_bookmark_ab01sj.dds'
local stdDDStextureFound = lfs.fileexists(stdDDStexture)]]

--[[
local function newBookmarkTexture(on)
	local result
	if stdDDStextureFound then
		if on then
			if lfs.fileexists(backupTexture) then
				local stdSize = lfs.attributes(stdDDStexture, 'size')
				local wideSize = lfs.attributes(wideTexture, 'size')
				if stdSize then
					if wideSize then
						if stdSize == wideSize then
							return true
						end
					end
				end
				result = copyFile(wideTexture, stdDDStexture)
			elseif copyFile(stdDDStexture, backupTexture) then
				result = copyFile(wideTexture, stdDDStexture)
			end
		else
			if lfs.fileexists(backupTexture) then
				result = copyFile(backupTexture, stdDDStexture)
			else
				result = copyFile(stdDDStexture, backupTexture)
			end
		end
	else
		if on then
			result = copyFile(wideTexture, stdDDStexture)
		elseif lfs.fileexists(backupTexture) then
			result = copyFile(backupTexture, stdDDStexture)
		end
	end
	return result
end
]]

local adjustBookmarkWidth

local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	function template.onClose()
		mwse.saveConfig(configName, config, {indent = false})
		if not (questPrefix == config.questPrefix ) then
			questPrefix = config.questPrefix
			local menuJournal = tes3ui.findMenu('MenuJournal')
			if menuJournal then
				if menuJournal.visible then
					checkQuestNames()
					menuJournal:updateLayout()
				end
			end
		end
		if not (adjustBookmarkWidth == config.adjustBookmarkWidth ) then
			adjustBookmarkWidth = config.adjustBookmarkWidth
			--[[if not newBookmarkTexture(adjustBookmarkWidth) then
				mwse.log('%s: newBookmarkTexture(%s) error', modPrefix, adjustBookmarkWidth)
			end]]
		end
	end

	---mwse.log('modConfigReady')
	-- Preferences Page
	local preferences = template:createSideBarPage{
		label='Preferences',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.1
			self.elements.sideToSideBlock.children[2].widthProportional = 0.9
		end
	}
	preferences.sidebar:createInfo{text = mcmName}

	-- Feature controls
	local controls = preferences:createCategory({})

	controls:createOnOffButton{
		label = 'Clear topics with no entries yet from the journal',
		description = 'Clear topics with no entries yet from the journal.',
		variable = createConfigVariable('clearTopicsWithNoEntries')
	}
	controls:createOnOffButton{
		label = 'Collapse journal paragraphs having the same date header',
		description = 'Collapse journal paragraphs having the same date header in a page.',
		variable = createConfigVariable('collapseDates')
	}
	controls:createOnOffButton{
		label = 'Skip links contained inside journal words',
		description = 'Skip links contained inside journal words.',
		variable = createConfigVariable('skipLinksInsideWords')
	}
	controls:createOnOffButton{
		label = 'Add quest name information to journal message',
		description = [[Add quest name information to sJournalEntry message e.g.
from: 'Your journal has been updated.'
to: 'You take a note in your Journal under section "Antabolis Informant"'.]],
		variable = createConfigVariable('upgradeJournalMessage')
	}

	controls:createDropdown{
		label = "Add a prefix in order to group quest names:",
		description = [[Add a prefix in order to group quest names.
0. No prefix,
1. Prefixed by source mod loading order
2. Prefixed by source mod condensed name
3. Prefixed by quest identifier
Note: as prefix calculation and sorting is done on the fly, using a prefix will cause a slight delay on displaying the quest list.
Well worth IMO, but you decide.]],
		options = {
			{ label = "0. No prefix", value = 0 },
			{ label = "1. Source mod loading order (suggested)", value = 1 },
			{ label = "2. Source mod condensed name", value = 2 },
			{ label = "3. Quest identifier", value = 3 },
		},
		variable = createConfigVariable('questPrefix')
	}

	controls:createDropdown{
		label = "Log level:",
		description = [[The amount of debug information logged to MWSE.log and/or screen.
0. Low
1. Medium
2. High]],
		options = {
			{ label = "0. Low", value = 0 },
			{ label = "1. Medium", value = 1 },
			{ label = "2. High", value = 2 },
		},
		variable = createConfigVariable('logLevel')
	}

	controls:createOnOffButton{
		label = 'Log missing quest names',
		description = [[Log Journal entries possibly missing the Quest Name flag.
Useful if you want to try and fix in the Construction Set parts of quests not grouping under the correct journal title.
Note: this setting will load more quest information from disk, in theory reloading/starting the game a little slower.
I have no measurable loading speed difference in my setup, but maybe if you have a slow hard drive you may want to enable this option only when you need the information.]],
		variable = createConfigVariable('logMissingQuestNames')
	}

	local hintInfo = "\nNote: these hints may work better if you set the game Options\\Prefs\\Menu Help Delay slider to about 1/3 position."
	controls:createOnOffButton{
		label = 'Add who you talked with to quest hint',
		description = 'Add who you talked with to quest hint.'..hintInfo,
		variable = createConfigVariable('questHintFirstHeardFrom')
	}
	controls:createOnOffButton{
		label = 'Add last quest text entry to quest hint',
		description = 'Add last quest text entry to quest hint.'..hintInfo,
		variable = createConfigVariable('questHintQuestInfo')
	}
	controls:createOnOffButton{
		label = 'Add quest identifier to quest hint',
		description = 'Add quest identifier to quest hint.'..hintInfo,
		variable = createConfigVariable('questHintQuestId')
	}
	controls:createOnOffButton{
		label = 'Add source mod name to quest hint',
		description = 'Add source mod name to quest hint.'..hintInfo,
		variable = createConfigVariable('questHintSourceMod')
	}
	controls:createOnOffButton{
		label = 'Add source mod Author and Info to quest hint while Alt key is pressed',
		description = 'Add source mod Author and Info to quest hint while Alt key is pressed.'..hintInfo,
		variable = createConfigVariable('questHintAltSourceInfo')
	}
	controls:createOnOffButton{
		label = 'Open first URL found in mod Info while Ctrl+Alt keys are pressed',
		description = 'Open first URL found in mod Info field while mouse hovering the mod quest hint with Ctrl+Alt keys pressed.'..hintInfo,
		variable = createConfigVariable('questHintCtrlAltURL')
	}
	controls:createOnOffButton{
		label = 'Adjust bookmark size',
		description = [[Adjust bookmark size to fit more text.
Now it works with standard Textures\Tx_menubook_bookmark.dds vanilla resolution image for better compatibility with other texture replacers.
If you don't like the one provided by this mod, overwrite it with one from your preferred texture replacer or delete it so the vanilla one from Morrowind.bsa is used instead.]],
		variable = createConfigVariable('adjustBookmarkWidth')
	}

	mwse.mcm.register(template)

	initModData()
	sJournalEntryGMST = tes3.findGMST(tes3.gmst.sJournalEntry)
	assert(sJournalEntryGMST)
	sJournalEntry = sJournalEntryGMST.value -- store it, default: 'Your journal has been updated.'
	assert(sJournalEntry)

	local width, height = tes3ui.getViewportSize()
	hintMaxHeight = math.floor((height * 0.5) + 0.5)
	hintMaxWidth = math.floor((width * 0.5) + 0.5)
	inputController = tes3.worldController.inputController

	logConfig(config, {indent = false})
	mwse.log(modPrefix .. " modConfigReady")
end
event.register('modConfigReady', modConfigReady)
