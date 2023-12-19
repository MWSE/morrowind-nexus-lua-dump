-- begin tweakables
local defaultConfig = {
clearTopicsWithNoEntries = true, -- clear topics with no entries yet from the journal
collapseDates = true, -- collapse journal paragraphs having the same date header
addYearToDate = false, -- add year to Journal dates
skipLinksInsideWords = true, -- skip links contained inside journal words
copyPaste = true, -- Copy last quest text entry hint to clipboard if present/enabled
upgradeJournalMessage = true, -- add quest Name information to sJournalEntry e.g. from 'Your journal has been updated.' to 'You take a note in your Journal under section "Antabolis Informant"'
questPrefix = 1, -- add a prefix in order to group quest names (0 = No, 1 = source mod loading index, 2 = source mod condensed name, 3 = quest id)
questFilter = true, -- add a text search filter for quest names and topics list
clearFilter = true, -- clear filter when changing view from topics to quests
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

local adjustBookmarkWidth = config.adjustBookmarkWidth
local copyPaste = config.copyPaste
local logLevel = config.logLevel
local logLevelGT1 = logLevel >= 1
local logLevelGT2 = logLevel >= 2
local logLevelGT3 = logLevel >= 3
local logLevelGT4 = logLevel >= 4


-- return first found URL string in text, or nil
local function getFirstURL(text_with_URLs)
	local s = string.match(text_with_URLs, URL_PATTERN)
	if logLevelGT2 then
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
	local modFileName
	---assert(table.size(modList) == #modList)
	for loadingIndex = 1, #modList do
		modFileName = modList[loadingIndex]
		modData[modFileName] = { index = loadingIndex, prefix = getCondensedPrefix(modFileName) }
	end
end

local GUI_ID_MenuBook_page_1 = tes3ui.registerID('MenuBook_page_1')
local GUI_ID_MenuBook_page_2 = tes3ui.registerID('MenuBook_page_2')
local GUI_ID_MenuBook_hypertext = tes3ui.registerID('MenuBook_hypertext')
local GUI_ID_MenuJournal_bookmark = tes3ui.registerID('MenuJournal_bookmark')
local GUI_ID_MenuJournal_button_bookmark_topics = tes3ui.registerID('MenuJournal_button_bookmark_topics')
local GUI_ID_MenuJournal_button_bookmark_topics_pressed = tes3ui.registerID('MenuJournal_button_bookmark_topics_pressed')
local GUI_ID_MenuJournal_bookmark_layout = tes3ui.registerID('MenuJournal_bookmark_layout')
local GUI_ID_MenuJournal_calendar_pane = tes3ui.registerID('MenuJournal_calendar_pane')
local GUI_ID_MenuJournal_focus = tes3ui.registerID('MenuJournal_focus')
local GUIID_MenuJournal_calendar_notespane = tes3ui.registerID('MenuJournal_calendar_notespane')
local GUIID_PartParagraphInput_text_input = tes3ui.registerID('PartParagraphInput_text_input')
---local GUI_ID_MenuBook_hipertext = tes3ui.registerID('MenuBook_hipertext')

local GUI_ID_MenuJournal_button_bookmark_quests_active = tes3ui.registerID('MenuJournal_button_bookmark_quests_active')
local GUI_ID_MenuJournal_button_bookmark_quests_all = tes3ui.registerID('MenuJournal_button_bookmark_quests_all')

--[[local GUI_ID_MenuJournal_button_bookmark_quests_active_idle = tes3ui.registerID('MenuJournal_button_bookmark_quests_active_idle')
local GUI_ID_MenuJournal_button_bookmark_quests_all_idle = tes3ui.registerID('MenuJournal_button_bookmark_quests_all_idle')
local GUI_ID_MenuJournal_button_bookmark_quests_active_over = tes3ui.registerID('MenuJournal_button_bookmark_quests_active_over')
local GUI_ID_MenuJournal_button_bookmark_quests_all_over = tes3ui.registerID('MenuJournal_button_bookmark_quests_all_over')
local GUI_ID_MenuJournal_button_bookmark_quests_active_pressed = tes3ui.registerID('MenuJournal_button_bookmark_quests_active_pressed')
local GUI_ID_MenuJournal_button_bookmark_quests_all_pressed = tes3ui.registerID('MenuJournal_button_bookmark_quests_all_pressed')
]]

local GUI_ID_MenuBook_button_take = tes3ui.registerID('MenuBook_button_take')
local GUI_ID_MenuJournal_button_bookmark_quests = tes3ui.registerID('MenuJournal_button_bookmark_quests')
--[[
local GUI_ID_MenuBook_button_prev = tes3ui.registerID('MenuBook_button_prev')
local GUI_ID_MenuBook_button_next = tes3ui.registerID('MenuBook_button_next')
--]]

---local GUI_ID_MenuJournal_selecttopics = tes3ui.registerID('MenuJournal_selecttopics')
local GUI_ID_MenuJournal_topicscroll = tes3ui.registerID('MenuJournal_topicscroll')
local GUI_ID_PartScrollPane_pane = tes3ui.registerID('PartScrollPane_pane')

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

local function getCleanedTable(t)
	for k, v in pairs(t) do
		--[[if logLevelGT4 then
			mwse.log('%s: getCleanedTable(t) t["%s"] = nil', modPrefix, k)
		end]]
		if v then
			t[k] = nil
		end
	end
	t = {}
	return t
end

local function cleanTables()
	questsByName = getCleanedTable(questsByName)
	questHints = getCleanedTable(questHints)
end

--[[local LALT = tes3.scanCode.lAlt
local LCTRL = tes3.scanCode.lCtrl
local LSHIFT = tes3.scanCode.lShift]]

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

local tes3_dialogueType_journal = tes3.dialogueType.journal

local function stripTags(text)
	return string.gsub(text, '[@#]', '')
end

local function initQuests() -- called in loaded() as they do not seem to be yet ok in initialized/modConfigReady
	if quests then
		return
	end

	quests = {}
	local text, questId

	local noLog = not config.logMissingQuestNames

	local dialogues = tes3.dataHandler.nonDynamicData.dialogues

	---assert(table.size(dialogues) == #dialogues)

	if noLog then
		local d
		for i = 1, #dialogues do
			d = dialogues[i]
			if d.type == tes3_dialogueType_journal then
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
						if logLevelGT4 then
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
	local journalIndex ---, flags
	local d, d_info, info
	for i = 1, #dialogues do
		d = dialogues[i]
		if d.type == tes3_dialogueType_journal then
			d_info = d.info
			---assert(table.size(d_info) == #d_info)
			for j = 1, #d_info do
				info = d_info[j]
				---assert(info)
				if info then
					journalIndex = info.journalIndex
					if journalIndex then
						if journalIndex == 0 then -- disposition used as quest index, 0 should be quest name
							text = info.text
							if text then -- important!
								---assert(string.len(text) > 0)
								if string.len(text) > 0 then
									questId = d.id
									local s = stripTags(text)
									if not (s == text ) then
										if logLevelGT3 then
											mwse.log('%s: initQuests() before = "%s", after = "%s"', modPrefix, text, s)
										end
									end
									text = s
									--[[flags = info.objectFlags
									if ( -- quest name marker flag, plus not relevant bit 0
										(flags == 73)
									 or (flags == 72)
									) then]]
									if info.isQuestName then
										if logLevelGT3 then
											mwse.log('%s: initQuests() quests["%s"] = {name = "%s", sourceMod = "%s"}', modPrefix, questId, text, d.sourceMod)
										end
										quests[questId] = {name = text, sourceMod = d.sourceMod}
										break -- for info
									elseif not string.multifind(text:lower(), {'--','dummy'}, 1, true) then -- skip Antares', TR dummy entries
										table.insert(missingQuestNames, string.format('"%s" Journal "%s" has INFO %s "%s" with index %s, but is NOT set as Quest Name\n',
											info.sourceMod, questId, info.id, text, journalIndex))
									end
								end -- if string.len(text)
							end -- if text
						end -- if journalIndex == 0
					end -- if journalIndex
				end -- if info
			end -- for info
		end -- if d.type
	end -- for d

	if #missingQuestNames > 0 then
		table.sort(missingQuestNames)
		text = string.format("\n%s: список записей журнала, в которых может отсутствовать флаг названия задания\n", modPrefix)
		for i = 1, #missingQuestNames do
			text = text .. missingQuestNames[i]
		end
		mwse.log(text)
	end

end

local function calcQuestsByName()
	local etime = os.time()

	local questName, prefix
	local fmt = "%s > %s"
	local size = 0
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
		size = size + 1
		if logLevelGT4 then
			mwse.log('%s: calcQuestsByName() questsByName["%s"] = {prefixed = "%s", questId = "%s"}', modPrefix, questName, prefix, id)
		end
	end

	if logLevelGT3 then
		mwse.log("%s: calcQuestsByName() elapsed time: %.5f, count = %s", modPrefix, os.time() - etime, size)
	end

end

local function getHintsOrQuestPrefixOrFilterOn()
	return (config.questPrefix > 0)
	or config.questFilter
	or config.questHintFirstHeardFrom
	or config.questHintQuestInfo
	or config.questHintQuestId
	or config.questHintSourceMod
	or config.questHintAltSourceInfo
	or config.questHintCtrlAltURL
end

local function checkQuestNames()
	questPrefix = config.questPrefix
	if getHintsOrQuestPrefixOrFilterOn() then
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
		if logLevelGT1 then
			mwse.log('%s: journal(e) index = %s, topic = "%s", questName = "%s"', modPrefix, e.index, questId, questName)
		end
		--- too late for this sJournalEntryGMST.value = string.format('You take a note in your Journal under section "%s".', questName)
		tes3.messageBox('Вы делаете пометку в своем дневнике в разделе "%s".', questName)
	end
end

local function stripFalseLinks(text)
	local s = string.gsub(text, "@(%w+)#(%w+)", "%1%2")
	return string.gsub(s, "(%w+)@(%w+)#", "%1%2")
end

local function sortQuests(children)
	local etime = os.time();
	local keys = {}
	local elements = {}
	local n = 0
	local sortFunc = function(a, b)
		return a.t < b.t
	end
	local el
	for i = 1, #children do
		el = children[i]
		if el.visible then
			---assert(not el.disabled)
			n = n + 1
			keys[n] = { t = el.text, d = el:getPropertyObject('PartHyperText_dialog') }
			---mwse.log("keys[%s] = %s", n, el.text)
			elements[n] = el
		end
	end
	table.sort(keys, sortFunc)
	local k
	for i = 1, #elements do
		el = elements[i]
		k = keys[i]
		if not (el.text == k.t) then
			el.text = k.t
			el:setPropertyObject('PartHyperText_dialog', k.d )
			---mwse.log("children[%s].text = %s", i, el.text)
		end
	end
	if logLevelGT3 then
		mwse.log("%s sortQuests() elapsed time: %.5f", modPrefix, os.time() - etime)
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
	--[[if not d then
		assert(d)
		return
	end]]
	local questName = d.id -- should be the original quest name
	--[[if logLevelGT3 then
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

		---assert(table.size(d_info_iterator) == #d_info_iterator)

		if config.questHintFirstHeardFrom then
			local actor, actorName, ref, cell, cellName
			local heard = {}
			local i = 1
			local info
			for j = 1, #d_info_iterator do
				info = d_info_iterator[j]
				actor = info.firstHeardFrom
				if actor then
					if actor.cloneCount == 1 then
						actorName = actor.name
						ref = tes3.getReference(actor.id)
						if ref then
							cell = ref.cell
							if cell then
								cellName = cell.editorName
								if cellName then
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
					hint = string.format("%sИзвестно от: %s (Сейчас в %s)\n", hint, aname, v.cnam)
				end
				--[[if logLeveGT3 then
					mwse.log("%s getHint(e) quest %s %s", modPrefix, questId, hint)
				end]]
				hint = hint .. "\n"
			end
		end -- if config.questHintFirstHeardFrom

		if config.questHintQuestInfo then
			local disposition, s
			local info
			for i = 1, #d_info_iterator do
				info = d_info_iterator[i]
				disposition = info.disposition
				--[[if logLevelGT2 then
					mwse.log("%s info.disposition = %s, info.text = %s", modPrefix, disposition, info.text)
				end]]
				if journalIndex == disposition then
					s = info.text
					if s then
						if #s > 0 then
							s = stripTags(s)
							---s = s:gsub('%.[^\n]', '%.\n') -- add line breaks
							if copyPaste then
								os.setClipboardText(s)
							end
							hint = string.format("%s%s\n\n", hint, s)
							tip = true
							break -- exit loop when current journalIndex dialog info found
						end -- if #s
					end  -- if s
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
			hint = string.format("%sПлагин: %04d %s\n\n", hint, modData[sourceMod].index, sourceMod)
			tip = true
		---end
	end

	if config.questHintAltSourceInfo then
		if inputController:isAltDown() then
			local modAuth, modInfo = getModInfo(sourceMod)
			if modAuth then
				hint = string.format("%sАвтор: %s\n\n", hint, modAuth)
				tip = true
			end
			if modInfo then
				hint = string.format("%sИнформация: %s\n\n", hint, modInfo)
				tip = true
				if config.questHintCtrlAltURL then
					if inputController:isControlDown() then
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

local function isShowingTopicsIndex(menuJournal_bookmark)
	local menuJournal_focus = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_focus)
	if menuJournal_focus then
		if menuJournal_focus.visible then
			return true
		end
	end
end

local function isShowingCalendar(menuJournal_bookmark)
	local menuJournal_calendar_pane = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_calendar_pane)
	if menuJournal_calendar_pane then
		if menuJournal_calendar_pane.visible then
			return true
		end
	end
end

local function isShowingTopicsIndexOrCalendar(menuJournal_bookmark)
	return isShowingTopicsIndex(menuJournal_bookmark)
	or isShowingCalendar(menuJournal_bookmark)
end

--[[
local function isShowingQuests(menuJournal_bookmark)
	local menuJournal_button_bookmark_quests_all_idle = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_all_idle)
	if menuJournal_button_bookmark_quests_all_idle then
		if menuJournal_button_bookmark_quests_all_idle.visible then
			return true
		end
	end
	local menuJournal_button_bookmark_quests_active_idle = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_active_idle)
	if menuJournal_button_bookmark_quests_active_idle then
		if menuJournal_button_bookmark_quests_active_idle.visible then
			return true
		end
	end

	local menuJournal_button_bookmark_quests_all_over = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_all_over)
	if menuJournal_button_bookmark_quests_all_over then
		if menuJournal_button_bookmark_quests_all_over.visible then
			return true
		end
	end
	local menuJournal_button_bookmark_quests_active_over = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_active_over)
	if menuJournal_button_bookmark_quests_active_over then
		if menuJournal_button_bookmark_quests_active_over.visible then
			return true
		end
	end

	local menuJournal_button_bookmark_quests_all_pressed = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_all_pressed)
	if menuJournal_button_bookmark_quests_all_pressed then
		if menuJournal_button_bookmark_quests_all_pressed.visible then
			return true
		end
	end
	local menuJournal_button_bookmark_quests_active_pressed = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_active_pressed)
	if menuJournal_button_bookmark_quests_active_pressed then
		if menuJournal_button_bookmark_quests_active_pressed.visible then
			return true
		end
	end

	return false
end
]]

local sSearch = 'Поиск...'
local GUI_ID_ab01journalSearchInput = tes3ui.registerID("ab01journalSearchInput")

local function updateBookmark(menu)
	local menuJournal_bookmark = menu:findChild(GUI_ID_MenuJournal_bookmark)
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

	local searchInput = menuJournal_bookmark:findChild(GUI_ID_ab01journalSearchInput)
	local key, value, prefixed, dialogue

	local areQuests = false
	if getHintsOrQuestPrefixOrFilterOn() then
		local el
		for i = 1, #children do
			el = children[i]
			key = el.text
			if key then
				value = questsByName[key]
				if value then
					areQuests = true
					if questPrefix > 0 then
						prefixed = value.prefixed
						if not (prefixed == key ) then
							el.text = prefixed
						end
					end
				else
					break
				end -- if value
			end -- if key
		end -- for _, el
		if areQuests then
			sortQuests(children) -- sort quest list
		end
	end -- if getHintsOrQuestPrefixOrFilterOn()

	local el
	local searchText = searchInput.text:lower()
	local filtered = not (
		(searchText == '')
		or (searchText == string.lower(sSearch))
	)
	local shiftPressed = inputController:isShiftDown()
	for i = 1, #children do
		el = children[i]
		if filtered then
			if string.find(string.lower(el.text), searchText, 1, true) then
				el.visible = shiftPressed
				or (el.alpha > 0.55)
			else
				el.visible = shiftPressed
			end
		else
			el.visible = shiftPressed
			or (el.alpha > 0.55)
		end
	end
	if areQuests then
		for i = 1, #children do
			el = children[i]
			if el.visible then
				if not el:getPropertyBool('hasHint') then
					el:setPropertyBool('hasHint', true)
					el:register('help', getHint)
				end
			end
		end
	end

	local areTopics = false
	local menuJournal_button_bookmark_topics = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_topics)
	if menuJournal_button_bookmark_topics then
		local menuJournal_button_bookmark_topics_pressed = menuJournal_button_bookmark_topics:findChild(GUI_ID_MenuJournal_button_bookmark_topics_pressed)
		if menuJournal_button_bookmark_topics_pressed then
			if menuJournal_button_bookmark_topics_pressed.visible then
				areTopics = true
			end
		end
	end

	if areTopics then -- journal topics
		if config.clearTopicsWithNoEntries then
			local toDestroy = {}
			local dialogue_info, notHeard, info
			local update = false
			for i = 1, #children do
				el = children[i]
				dialogue = el:getPropertyObject('PartHyperText_dialog')
				if dialogue then
					notHeard = true
					dialogue_info = dialogue.info
					for j = 1, #dialogue_info do
						info = dialogue_info[j]
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
			if update then
				for i = 1, #toDestroy do
					toDestroy[i]:destroy()
				end
			end
		end
	end

	partScrollPane_pane:updateLayout()
	local widget = menuJournal_topicscroll.widget
	if widget then
		widget:contentsChanged()
	end

end

local function onOK(e)
	updateBookmark(e.source:getTopLevelMenu())
end
--[[local function onCancel(e)
	updateBookmark(e.source:getTopLevelMenu())
end]]

local function onClear(e)
	e.source.text = sSearch
	updateBookmark(e.source:getTopLevelMenu())
end

-- some magic code from Hrn. I don't know how it works, but it does the trick!
-- the first function disables the JournalCloseKeybind, which is the one keybind not caught by tes3ui.acquireTextInput(element)
-- the second function reenables that keybind. If you use this in your own mod, make sure to reenable the keybind when you are done
local function disableJournalCloseKeybind()
	mwse.memory.writeByte{address = 0x41AF6D, byte = 0xEB}
end
local function enableJournalCloseKeybind()
	mwse.memory.writeByte{address = 0x41AF6D, byte = 0x74}
end

local function makeInput(el)
	---tes3.messageBox(el.name)
	local searchInputBlock = el:createBlock{}
	searchInputBlock.width = 100
	searchInputBlock.autoHeight = true
	---searchInputBlock.childAlignX = 0.5
	searchInputBlock.childAlignX = 0.0
	local border = searchInputBlock:createThinBorder{}
	border.width = searchInputBlock.width
	---border.height = 30
	border.autoHeight = true
	---border.childAlignX = 0.5
	---border.childAlignY = 0.5
	local input = border:createTextInput({id = GUI_ID_ab01journalSearchInput})
	input.text = sSearch
	input.borderLeft = 3
	input.borderRight = 3
	input.color = {0.000, 0.000, 0.000}
	input.widget.lengthLimit = 50
	input.widget.eraseOnFirstKey = true
	el:register('keyEnter', onOK) -- only works when text input is not captured
	input:register('keyEnter', onOK)
	input:register('mouseClick', onClear)
	local menu = el:getTopLevelMenu()
	menu:updateLayout()
	if config.questFilter then
		el:registerAfter('destroy', enableJournalCloseKeybind)
		disableJournalCloseKeybind()
	end
end

local function addYearToJournalDate(journalDateStr)
	-- insert year e.g. from 16 Last Seed (Day 1) to 16 Last Seed, 3E 427 (Day 1)
	local daysPassed = string.match(journalDateStr, "[^3][^E] %(День (%d+)%)$")
	if daysPassed then
		local year = math.floor( (daysPassed - 1) / 365 ) + 427
		local replaceStr = string.format(", 3E %s (", year)
		return string.gsub(journalDateStr, " %(", replaceStr)
	end
	return journalDateStr
end

local ab01sjd = 'ab01sjd' -- abot's Smart Journal Dialog

local function processDateHeader(menuBook_page)
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
	---mwse.log("processDateHeader(menuBook_page = %s)", menuBook_page)
	local headers = {}
	local text, count
	local collapseDates = config.collapseDates
	local addYearToDate = config.addYearToDate
	local el
	for i = 1, #children do
		el = children[i]
		if el.id == GUI_ID_MenuBook_hypertext then
			if not el:getPropertyBool(ab01sjd) then
				text = el.text
				if text then
					if not headers[text] then
						if string.match(text, "^%d+ [^,]+%d+%)$") then
							headers[text] = 1
						end
					end
				end
			end
		end
	end
	local update = false
	for i = 1, #children do
		el = children[i]
		if el.id == GUI_ID_MenuBook_hypertext then
			if not el:getPropertyBool(ab01sjd) then
				el:setPropertyBool(ab01sjd, true)
				text = el.text
				count = headers[text]
				if count then
					if count == 1 then
						headers[text] = 2
						if addYearToDate then
							update = true
							el.text = addYearToJournalDate(text)
						end
					elseif collapseDates then
						update = true
						--- el.disabled = true -- maybe safer if some other mod is looking for it?
						el:destroy() -- collapse after first
					end
				end
			end
		end
	end
	if update then
		menuBook_page:updateLayout()
	end
end

--[[
	local currElem = nil

local function mouseOver(e)
	currElem = e.source
	tes3.messageBox('currElem = %s', currElem.name)
end

local function mouseLeave()
	currElem = nil
end

local function mouseButtonUp(e)
	---tes3.messageBox('e.button = %s', e.button)
	---mwse.log('e.button = %s', e.button)
	if not (e.button == 1) then -- right mouse button
		return
	end
	if not currElem then
		return
	end
	local text = currElem.text
	if not text then
		return
	end
	if #text then
		local elId = currElem.id
		if inputController.isControlDown then
			if elId == GUI_ID_MenuBook_hipertext then
				text = stripTags(text)
				os.setClipboardText(text)
			elseif elId == GUI_ID_PartParagraphInput_text_input then
				text = string.sub(text, 1, -2) -- strip last '|' character
				os.setClipboardText(text)
			end
		elseif inputController.isShiftDown then
			if elId == GUI_ID_PartParagraphInput_text_input then
				text = os.getClipboardText() .. '|'
				currElem.text = text
			end
		end
		---tes3.messageBox(text)
	end
end

local function journalEntryClick(e)
	if inputController:isControlDown() then
		local el = e.element
		local text = stripTags(el.text)
		os.setClipboardText(text)
	end
end]]

local function skipFalseLinksOrCopy(menuBook_page)
	local skip = config.skipLinksInsideWords
	if not skip then
		return
	end
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
	local el, text
	for i = 1, #children do
		el = children[i]
		if el.id == GUI_ID_MenuBook_hypertext then
			if not el:getPropertyBool(ab01sjd) then
				el:setPropertyBool(ab01sjd, true)
				text = el.text
				if text then
					if skip then
						el.text = stripFalseLinks(text)
					end
				end
			end
		end
	end
end


local function updateJournalPages(menu)
	local collapseOrAddDates = config.collapseDates
		or config.addYearToDate
	local skipOrCopy = config.skipLinksInsideWords
	if collapseOrAddDates
	or skipOrCopy then
		local page_1 = menu:findChild(GUI_ID_MenuBook_page_1)
		local page_2 = menu:findChild(GUI_ID_MenuBook_page_2)
		if collapseOrAddDates then
			processDateHeader(page_1)
			processDateHeader(page_2)
		end
		if skipOrCopy then
			skipFalseLinksOrCopy(page_1)
			skipFalseLinksOrCopy(page_2)
		end
	end
end

local function updateJournalSearchInput(menu, clear)
	local menuJournal_bookmark = menu:findChild(GUI_ID_MenuJournal_bookmark)
	if not menuJournal_bookmark then
		return
	end
	local journalSearchInput = menuJournal_bookmark:findChild(GUI_ID_ab01journalSearchInput)
	if journalSearchInput then
		if clear then
			journalSearchInput:triggerEvent('mouseClick')
		end
		if config.questFilter then
			if not isShowingTopicsIndexOrCalendar(menuJournal_bookmark) then
				journalSearchInput.parent.visible = true
				journalSearchInput.disabled = false
				return
			end
		end
		journalSearchInput.parent.visible = false
		journalSearchInput.disabled = true
	end
end

local function updateJournalBookmark(menu)
	updateJournalSearchInput(menu)
	if getHintsOrQuestPrefixOrFilterOn() then
		updateBookmark(menu)
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


local function journalButtonClick2(e)
	local el = e.source
	el:forwardEvent(e)
	local menu = el:getTopLevelMenu()
	updateJournalSearchInput(menu, config.clearFilter)
	menu:updateLayout()
end

local function journalButtonClick(e)
	checkQuestNames()
	local el = e.source
	el:forwardEvent(e)
	local menu = el:getTopLevelMenu()
	updateJournalSearchInput(menu, config.clearFilter)
	menu:updateLayout()
end

local function calendarInputClick(e)
	local el = e.source
	---el:forwardEvent(e)
	if inputController:isAltDown() then
		local text = el.text
		if text then
			if #text > 0 then
				el.text = ''
			end
		end
		tes3.messageBox("calendarInputClick(e) + Alt")
		local menu = el:getTopLevelMenu()
		menu:updateLayout()
	end
end

local function uiActivatedMenuJournal(e)
	local el = e.element
	if not e.newlyCreated then
		return
	end
	checkQuestNames()
	el:register('update', onUpdateJournal)
	local menuBook_button_take = el:findChild(GUI_ID_MenuBook_button_take)
	if menuBook_button_take then
		menuBook_button_take:register('mouseClick', journalButtonClick)
	end
	
	local menuJournal_bookmark = el:findChild(GUI_ID_MenuJournal_bookmark)
	if menuJournal_bookmark then

		local menuJournal_calendar_pane = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_calendar_pane)
		if menuJournal_calendar_pane then
			local menuJournal_calendar_notespane = menuJournal_calendar_pane:findChild(GUIID_MenuJournal_calendar_notespane)
			if menuJournal_calendar_notespane then
				local partParagraphInput_text_input = menuJournal_calendar_notespane:findChild(GUIID_PartParagraphInput_text_input)
				if partParagraphInput_text_input then
					mwse.log(">>> Smart Journal: partParagraphInput_text_input:register('mouseClick', calendarInputClick)")
					partParagraphInput_text_input:register('mouseClick', calendarInputClick)
				end
			end
		end

		local menuJournal_button_bookmark_quests_active = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_active)
		if menuJournal_button_bookmark_quests_active then
			menuJournal_button_bookmark_quests_active:register('mouseClick', journalButtonClick)
		end
		local menuJournal_button_bookmark_quests_all = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests_all)
		if menuJournal_button_bookmark_quests_all then
			menuJournal_button_bookmark_quests_all:register('mouseClick', journalButtonClick)
		end
		local menuJournal_button_bookmark_quests = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_quests)
		if menuJournal_button_bookmark_quests then
			menuJournal_button_bookmark_quests:register('mouseClick', journalButtonClick)
			makeInput(menuJournal_bookmark)
		end
		local menuJournal_button_bookmark_topics = menuJournal_bookmark:findChild(GUI_ID_MenuJournal_button_bookmark_topics)
		if menuJournal_button_bookmark_topics then
			menuJournal_button_bookmark_topics:register('mouseClick', journalButtonClick2)
		end

		if adjustBookmarkWidth then
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
		updateJournalElement(el)
	end
end

local GUI_ID_MenuDialog_scroll_pane = tes3ui.registerID('MenuDialog_scroll_pane')
local GUI_ID_MenuDialog_notify = tes3ui.registerID('MenuDialog_notify')

local dialogScrollPane

local function updateDialog(e)
	local el = dialogScrollPane
	if not el then
		el = e.source:findChild(GUI_ID_MenuDialog_scroll_pane)
		if not el then
			return
		end
		dialogScrollPane = el
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
	el:registerBefore('destroy', function() dialogScrollPane = nil end)
	el:registerBefore('update', updateDialog)
	---el:register('update', updateDialog)
	---el:registerAfter('update', updateDialog)
end

local function loaded()
	cleanTables()
	initQuests()
end

--[[local function logConfig(cfg, options)
	mwse.log(json.encode(cfg, options))
end]]

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable({id = varId, table = config})
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	function template.onClose()
		logLevel = config.logLevel
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

		mwse.saveConfig(configName, config, {indent = true})
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
		label = 'Убрать темы, в которых еще нет записей из журнала',
		description = 'Убирает темы, в которых еще нет записей из журнала.',
		variable = createConfigVariable('clearTopicsWithNoEntries')
	}
	controls:createOnOffButton{
		label = 'Соединить абзацы журнала с одинаковыми датами',
		description = 'Соединяет абзацы журнала с одинаковыми датами на странице.',
		variable = createConfigVariable('collapseDates')
	}
	controls:createOnOffButton{
		label = 'Добавить год к заголовку даты журнала',
		description = [[Добавляет год в заголовок даты журнала, например,
вместо: 16 Месяц Урожая (день 1)
будет: 16 Месяц Урожая, 3E 427 (день 1).]],
		variable = createConfigVariable('addYearToDate')
	}
	controls:createOnOffButton{
		label = 'Пропускать ссылки, содержащиеся в словах журнала',
		description = 'Пропускает ссылки, содержащиеся в словах журнала.',
		variable = createConfigVariable('skipLinksInsideWords')
	}
	controls:createOnOffButton{
		label = 'Добавить информацию о названии задания в сообщения дневника',
		description = [[Добавляет информацию о названии задания в сообщение о записи в дневнике, например,
вместо: "Ваш дневник был дополнен."  
будет: "Вы делаете пометку в своем дневнике в разделе "Информация от Антаболиса".]],
		variable = createConfigVariable('upgradeJournalMessage')
	}
	controls:createOnOffButton{
		label = 'Фильтр поиска',
		description = [[Добавляет фильтр для поиска по названию заданий и тем.]],
		variable = createConfigVariable('questFilter')
	}
	controls:createOnOffButton{
		label = 'Автоочистка фильтра',
		description = [[Очищает фильтр при переходе от тем на задания.]],
		variable = createConfigVariable('clearFilter')
	}

	controls:createDropdown{
		label = 'Добавить префикс для группировки заданий:',
		description = [[Добавляет префикс, по которому будут группироваться задания.
0. Без префикса,
1. С префиксом порядка загрузки исходного мода
2. С префиксом сокращенного имени исходного мода
3. С префиксом идентификатора задания
Примечание: поскольку вычисление префикса и сортировка выполняются "на лету", использование префикса вызовет небольшую задержку при отображении списка заданий.
ИМХО, это того стоит, но решать вам.]],
		options = {
			{ label = '0. Без префикса', value = 0 },
			{ label = '1. Порядок загрузки исходного мода (рекомендуется)', value = 1 },
			{ label = '2. Сокращенное название исходного мода', value = 2 },
			{ label = '3. Идентификатор задания', value = 3 },
		},
		variable = createConfigVariable('questPrefix')
	}

	controls:createDropdown{
		label = 'Размер лога:',
		description = [[Объем отладочной информации, записываемой в MWSE.log, или на экране.]],
		options = {
			{ label = '0. Минимальный', value = 0 },
			{ label = '1. Малый', value = 1 },
			{ label = '2. Средний', value = 2 },
			{ label = '3. Большой', value = 3 },
			{ label = '4. Максимальный', value = 4 },
		},
		variable = createConfigVariable('logLevel')
	}

	controls:createOnOffButton{
		label = 'Регистрировать отсутствующие названия заданий',
		description = [[Регистрирует в записях журнала отсутствующие флаги названий заданий.
Полезно, если вы хотите исправить в конструкторе части заданий, которые не группируются под правильным названием журнала.
Примечание: эта настройка будет загружать с диска больше информации о квесте, что, возможно, сделает перезагрузку / запуск игры немного медленнее.
В моей настройке нет заметной разницы в скорости загрузки, но, если у вас медленный жесткий диск, вы можете включать эту опцию только тогда, когда вам нужна информация.]],
		variable = createConfigVariable('logMissingQuestNames')
	}

	local hintInfo = "\nПримечание: эти подсказки могут сработать лучше, если вы настроите в Options\\Prefs\\Menu ползунок задержки подсказок на 1/3."
	controls:createOnOffButton{
		label = 'Добавить тех, с кем вы разговаривали, в подсказку к заданию',
		description = 'Добавляет тех, с кем вы разговаривали по ходу задания в подсказку к заданию.'..hintInfo,
		variable = createConfigVariable('questHintFirstHeardFrom')
	}
	controls:createOnOffButton{
		label = 'Добавить последнюю запись задания в подсказку к заданию',
		description = 'Добавляет последнюю запись задания в подсказку к заданию.'..hintInfo,
		variable = createConfigVariable('questHintQuestInfo')
	}
	controls:createOnOffButton{
		label = 'Копировать последнюю запись задания в буфер обмена',
		description = [[Копирует (по возможности) последнюю запись задания из подсказки к заданию в буфер обмена вашей ОС. Полезно, если нужно куда-нибудь вставить этот текст.]],
		variable = createConfigVariable('copyPaste')
	}
	controls:createOnOffButton{
		label = 'Добавить идентификатор задания в подсказку к заданию',
		description = 'Добавляет идентификатор задания в подсказку к заданию.'..hintInfo,
		variable = createConfigVariable('questHintQuestId')
	}
	controls:createOnOffButton{
		label = 'Добавить название мода в подсказку к заданию',
		description = 'Добавляет название мода в подсказку к заданию.'..hintInfo,
		variable = createConfigVariable('questHintSourceMod')
	}
	controls:createOnOffButton{
		label = 'Добавить автора мода и информацию в подсказку к заданию при нажатии клавиши Alt',
		description = 'Добавляет автора мода и информацию о моде в подсказку к заданию при нажатии клавиши Alt.'..hintInfo,
		variable = createConfigVariable('questHintAltSourceInfo')
	}
	controls:createOnOffButton{
		label = 'Открыть первую найденную ссылку с информацией о моде, при нажатии клавиш Ctrl+Alt',
		description = 'Открывает первую найденную в поле информации о моде ссылку, при наведении курсора мыши на подсказку квестов с нажатыми клавишами Ctrl+Alt.'..hintInfo,
		variable = createConfigVariable('questHintCtrlAltURL')
	}

	controls:createOnOffButton{
		label = 'Регулировать размер закладки',
		description = [[Регулирует размер закладки, чтобы в нее помещалось больше текста.
Теперь работает со стандартнымы Textures\Tx_menubook_bookmark.dds с ванильным разрешением для лучшей совместимости с другими заменителями текстур.
Если вам не нравится закладка, предоставляемая этим модом, замените ее на вашу текстуру, или удалите ее, чтобы ванильная из Morrowind.bsa использовалась вместо него.]],
		variable = createConfigVariable('adjustBookmarkWidth')
	}

	mwse.mcm.register(template)

	initModData()
	sJournalEntryGMST = tes3.findGMST(tes3.gmst.sJournalEntry)
	---assert(sJournalEntryGMST)
	sJournalEntry = sJournalEntryGMST.value -- store it, default: 'Your journal has been updated.'
	---assert(sJournalEntry)

	local width, height = tes3ui.getViewportSize()
	hintMaxHeight = math.floor((height * 0.5) + 0.5)
	hintMaxWidth = math.floor((width * 0.5) + 0.5)
	inputController = tes3.worldController.inputController

	event.register('journal', journal, {priority = 1})
	event.register('uiActivated', uiActivatedMenuJournal, {filter = 'MenuJournal'})
	event.register('uiActivated', uiMenuDialogActivated, {filter = 'MenuDialog'})
	event.register('loaded', loaded)
	---event.register('mouseButtonUp', mouseButtonUp)

	---logConfig(config, {indent = false})
	---mwse.log(modPrefix .. " modConfigReady")
end
event.register('modConfigReady', modConfigReady)
