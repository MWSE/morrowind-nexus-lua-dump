---@diagnostic disable: undefined-field, need-check-nil
-- begin tweakables
local defaultConfig = {
clearTopicsWithNoEntries = true, -- clear topics with no entries yet from the journal
collapseDates = true, -- collapse journal paragraphs having the same date header
addYearToDate = false, -- add year to Journal dates
skipLinksInsideWords = true, -- skip links contained inside journal words
copyPaste = true, -- Copy last quest text entry hint to clipboard if present/enabled
copyLastDialog = true, -- Copy last dialog response text to clipboard
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
logLevel = 0
}
-- end tweakables

local author = 'abot'
local modName = 'Smart Journal'
local modPrefix = author .. '/'.. modName

local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

-- updated also in modConfigReady()
local questPrefix = config.questPrefix
local adjustBookmarkWidth = config.adjustBookmarkWidth
local copyLastDialog = config.copyLastDialog

-- updated in updateFromConfig()
local clearTopicsWithNoEntries, collapseDates, addYearToDate, skipLinksInsideWords
local copyPaste, upgradeJournalMessage, questFilter, clearFilter
local questHintFirstHeardFrom, questHintQuestInfo, questHintQuestId, questHintSourceMod
local questHintAltSourceInfo, questHintCtrlAltURL, logMissingQuestNames
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local function updateFromConfig()
	clearTopicsWithNoEntries = config.clearTopicsWithNoEntries
	collapseDates = config.collapseDates
	addYearToDate = config.addYearToDate
	skipLinksInsideWords = config.skipLinksInsideWords
	copyPaste = config.copyPaste
	upgradeJournalMessage = config.upgradeJournalMessage
	questFilter = config.questFilter
	clearFilter = config.clearFilter
	questHintFirstHeardFrom = config.questHintFirstHeardFrom
	questHintQuestInfo = config.questHintQuestInfo
	questHintQuestId = config.questHintQuestId
	questHintSourceMod = config.questHintSourceMod
	questHintAltSourceInfo = config.questHintAltSourceInfo
	questHintCtrlAltURL = config.questHintCtrlAltURL
	logMissingQuestNames = config.logMissingQuestNames
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
end
updateFromConfig()

local URL_PATTERN = 'https?://[_~a-zA-Z0-9/#\\=&;%.%%%+%-%?]+'

-- return first found URL string in text, or nil
local function getFirstURL(text_with_URLs)
	local s = string.match(text_with_URLs, URL_PATTERN)
	if logLevel4 then
		mwse.log("%s getFirstURL = %s", modPrefix, s)
	end
	return s
end

--[[
local function getURLs(text_with_URLs)
	local t = string.gmatch(text_with_URLs, URL_PATTERN)
	---for k, v in pairs(t) do
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

--[[
local function getModInfo(sourceMod)
	local f = io.open("Data Files/" .. sourceMod, "rb")
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
]]

local modData = {} -- precalculated and stored for speed

--[[
local function initModData() -- called in modConfigReady()
	local modList = tes3.getModList()
	modData = {}
	local mod, auth, info
	for loadingIndex = 1, #modList do -- e.g. {[1] = 'Morrowind.esm', [2] = 'Bloodmoon.esm'}
		mod = modList[loadingIndex]
		auth, info = getModInfo(mod)
		modData[mod] = { idx = loadingIndex, pfx = getCondensedPrefix(mod), aut = auth, inf = info, url = getFirstURL(info) }
	end
end
]]

local function initModData() -- called in modConfigReady()
	modData = {}
	local activeMods = tes3.dataHandler.nonDynamicData.activeMods
	for i = 1, #activeMods do
		local am = activeMods[i]
		local mod = am.filename
		local info = am.description
		local prefix = getCondensedPrefix(mod)
		local author = am.author
		local link = getFirstURL(info)
		modData[mod] = {idx = i, pfx = prefix, aut = author, inf = info, url = link}
		if logLevel3 then
			mwse.log('%s initModData() modData["%s"] = {idx = %s, pfx = "%s", aut = "%s", inf = "%s", url = "%s"}',
				modPrefix, mod, i, prefix, author, info, link)
		end
	end
end

local idMenuBook_page_1 = tes3ui.registerID('MenuBook_page_1')
local idMenuBook_page_2 = tes3ui.registerID('MenuBook_page_2')
local idMenuBook_hypertext = tes3ui.registerID('MenuBook_hypertext')
local idMenuJournal_bookmark = tes3ui.registerID('MenuJournal_bookmark')
local idMenuJournal_button_bookmark_topics = tes3ui.registerID('MenuJournal_button_bookmark_topics')
local idMenuJournal_button_bookmark_topics_pressed = tes3ui.registerID('MenuJournal_button_bookmark_topics_pressed')
local idMenuJournal_bookmark_layout = tes3ui.registerID('MenuJournal_bookmark_layout')
local idMenuJournal_calendar_pane = tes3ui.registerID('MenuJournal_calendar_pane')
local idMenuJournal_focus = tes3ui.registerID('MenuJournal_focus')
local idMenuJournal_calendar_notespane = tes3ui.registerID('MenuJournal_calendar_notespane')
local idPartParagraphInput_text_input = tes3ui.registerID('PartParagraphInput_text_input')
---local idMenuBook_hipertext = tes3ui.registerID('MenuBook_hipertext')

local idMenuJournal_button_bookmark_quests_active = tes3ui.registerID('MenuJournal_button_bookmark_quests_active')
local idMenuJournal_button_bookmark_quests_all = tes3ui.registerID('MenuJournal_button_bookmark_quests_all')

--[[local idMenuJournal_button_bookmark_quests_active_idle = tes3ui.registerID('MenuJournal_button_bookmark_quests_active_idle')
local idMenuJournal_button_bookmark_quests_all_idle = tes3ui.registerID('MenuJournal_button_bookmark_quests_all_idle')
local idMenuJournal_button_bookmark_quests_active_over = tes3ui.registerID('MenuJournal_button_bookmark_quests_active_over')
local idMenuJournal_button_bookmark_quests_all_over = tes3ui.registerID('MenuJournal_button_bookmark_quests_all_over')
local idMenuJournal_button_bookmark_quests_active_pressed = tes3ui.registerID('MenuJournal_button_bookmark_quests_active_pressed')
local idMenuJournal_button_bookmark_quests_all_pressed = tes3ui.registerID('MenuJournal_button_bookmark_quests_all_pressed')
]]

local idMenuBook_button_take = tes3ui.registerID('MenuBook_button_take')
local idMenuJournal_button_bookmark_quests = tes3ui.registerID('MenuJournal_button_bookmark_quests')
--[[
local idMenuBook_button_prev = tes3ui.registerID('MenuBook_button_prev')
local idMenuBook_button_next = tes3ui.registerID('MenuBook_button_next')
--]]

---local idMenuJournal_selecttopics = tes3ui.registerID('MenuJournal_selecttopics')
local idMenuJournal_topicscroll = tes3ui.registerID('MenuJournal_topicscroll')
local idPartScrollPane_pane = tes3ui.registerID('PartScrollPane_pane')

local function getPrefixedQuest(modNam)
	local data = modData[modNam]
	local s
	if questPrefix == 1 then
		s = string.format("%04d", data.idx)
	else
		s = data.pfx
	end
	return s
end

-- cleared in load()
local questsByName = {}
local questHints = {}

local function getCleanedTable(t)
	for k, v in pairs(t) do
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

	local logMissing = config.logMissingQuestNames

	local missingQuestNames = {}

	local dialogues = tes3.dataHandler.nonDynamicData.dialogues
	---assert(table.size(dialogues) == #dialogues)

	local function processInfo(d, info)
		if not info then
			return
		end
		local journalIndex = info.journalIndex
		if not journalIndex then
			return
		end
		if not (journalIndex == 0) then
			return
		end
		local text = info.text
		if not text then-- important!
			return
		end
		if string.len(text) <= 0 then
			return
		end
		local questId = d.id
		if info.isQuestName then
			if logLevel3 then
				mwse.log('%s: initQuests() quests["%s"] = {name = "%s", sourceMod = "%s"}',
					modPrefix, questId, text, info.sourceMod)
			end
			if not quests[questId] then
				quests[questId] = {name = text, sourceMod = info.sourceMod}
			end
			return true --- break for info
		end

		local s = stripTags(text)
		if ( not (text == s) )
		and logLevel3 then
			mwse.log('%s: initQuests() before = "%s", after = "%s"', modPrefix, text, s)
		end
		if string.multifind(string.lower(s), {'--','dummy'}, 1, true) then
			return -- skip Antares', TR dummy entries
		end
		table.insert(missingQuestNames,
			string.format('"%s" Journal "%s" has INFO %s "%s" with index %s, but is NOT set as Quest Name\n',
				info.sourceMod, questId, info.id, s, journalIndex))
	end


	for i = 1, #dialogues do
		local d = dialogues[i]
		if d
		and (d.type == tes3_dialogueType_journal) then
			local text = d:loadQuestName()
			---assert(text) -- this may still be nil!
			if text -- still important!
			and (string.len(text) > 0) then
				local questId = d.id
				if logLevel4 then
					mwse.log('%s: initQuests() quests["%s"] = {name = "%s", sourceMod = "%s"}',
						modPrefix, questId, text, d.sourceMod)
				end
				quests[questId] = {name = text, sourceMod = d.sourceMod}
			end -- if text

			if logMissing then
				local infos = d.info
				---assert(table.size(infos) == #infos)
				for j = 1, #infos do
					if processInfo(d, infos[j]) then
						break
					end
				end
			end

		end -- if d

	end -- for i

	if logMissing
	and ( #missingQuestNames > 0 ) then
		table.sort(missingQuestNames)
		local txt = '\n'..modPrefix..': list of journal entries maybe missing the Quest Name flag\n'
		for i = 1, #missingQuestNames do
			txt = txt .. missingQuestNames[i]
		end
		mwse.log(txt)
	end

end

local function calcQuestsByName()
	local etime = os.clock()
	local size = 0
	for id, q in pairs(quests) do
		if q then
			local questName = q.name
			local prefix
			if questPrefix == 3 then
				prefix = id .. ' > ' .. questName
			elseif questPrefix > 0 then
				prefix = getPrefixedQuest(q.sourceMod) .. ' > ' .. questName
			else
				prefix = questName
			end
			local qd = questsByName[questName]
			if not qd then
				questsByName[questName] = {}
				qd = questsByName[questName]
			end
			qd.prefixed = prefix
			qd.questId = id
			size = size + 1
			if logLevel4 then
				mwse.log('%s: calcQuestsByName() questsByName["%s"] = {prefixed = "%s", questId = "%s", hint = "%s"}', modPrefix, questName, prefix, id, qd.hint)
			end
		end
	end

	if logLevel3 then
		mwse.log("%s: calcQuestsByName() elapsed time: %.3f, count = %s", modPrefix, os.clock() - etime, size)
	end

end

local function getHintsOrQuestPrefixOrFilterOn()
	return (questPrefix > 0)
	or questFilter
	or questHintFirstHeardFrom
	or questHintQuestInfo
	or questHintQuestId
	or questHintSourceMod
	or questHintAltSourceInfo
	or questHintCtrlAltURL
end

local function checkQuestNames()
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
		if logLevel1 then
			mwse.log('%s: journal(e) index = %s, topic = "%s", questName = "%s"', modPrefix, e.index, questId, questName)
		end
		--- too late for this sJournalEntryGMST.value = string.format('You take a note in your Journal under section "%s".', questName)
		tes3.messageBox('You take a note in your Journal under section "%s".', questName)
	end
end

local function stripFalseLinks(text)
	local s = string.gsub(text, "@(%w+)#(%w+)", "%1%2")
	return string.gsub(s, "(%w+)@(%w+)#", "%1%2")
end

local function sortQuests(children)
	local etime = os.clock()
	local keys = {}
	local elements = {}
	local n = 0
	local sortFunc = function(a, b)
		return a.t < b.t
	end
	for i = 1, #children do
		local el = children[i]
		if el.visible then
			---assert(not el.disabled)
			n = n + 1
			keys[n] = { t = el.text, d = el:getPropertyObject('PartHyperText_dialog') }
			---mwse.log("keys[%s] = %s", n, el.text)
			elements[n] = el
		end
	end
	table.sort(keys, sortFunc)
	for i = 1, #elements do
		local el = elements[i]
		local k = keys[i]
		if not (el.text == k.t) then
			el.text = k.t
			el:setPropertyObject('PartHyperText_dialog', k.d )
			---mwse.log("children[%s].text = %s", i, el.text)
		end
	end
	if logLevel3 then
		mwse.log("%s sortQuests() elapsed time: %.3f", modPrefix, os.clock() - etime)
	end
end

local function redirectURL(s)
	local lcs = string.lower(s)
	local r
	local webArchivePrefix = 'https://web.archive.org/web/'
	local modhistoryPrefix = 'mw.modhistory.com/download'
	local m = string.match(lcs, "https?://"..modhistoryPrefix.."(%-%d+%-%d+)")
	if m then
		r = webArchivePrefix..'20161103152243/https://'..modhistoryPrefix..m
		if logLevel3 then
			mwse.log('%s redirectURL("%s") = "%s"', modPrefix, s, r)
		end
		return r
	end
	local fliggertyPrefix = 'download.fliggerty.com/'
	m = string.match(lcs, "https?://"..fliggertyPrefix.."download%-(%d+%-%d+)")
	if m then
		r = webArchivePrefix..'20161103125749/https://'..fliggertyPrefix..'file.php?id='..m
		if logLevel3 then
			mwse.log('%s redirectURL("%s") = "%s"', modPrefix, s, r)
		end
		return r
	end
	return s
end

local hintMaxWidth, hintMaxHeight -- set in modConfigReady()

local lastHaltDown = false

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
	--[[if logLevel3 then
		-- both d.journal and d.type can be nil here
		mwse.log("%s t = %s, questName = %s, d.journalIndex = %s, d.type = %s", modPrefix, t, questName, d.journalIndex, d.type, d.sourceMod)
	end]]

	local qd = questsByName[questName]
	---assert(qd)
	local questId = qd.questId
	---assert(questId)

	local journalIndex = tes3.getJournalIndex({id = questId})
	if not journalIndex then
		return
	end

	local q = quests[questId]
	---assert(q)
	local sourceMod = q.sourceMod
	---assert(sourceMod)

	local hint
	-- note I want to be able to set it to nil
	-- without Lua linter complaining so no local hint = qd.hint
	hint = qd.hint

	local data = modData[sourceMod]

	local altDown = inputController:isAltDown()
	if not (altDown == lastHaltDown) then
		lastHaltDown = altDown
		hint = nil
	end

	local function showHint()
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

	local function checkOpenURL()
		if questHintCtrlAltURL
		and inputController:isAltDown()
		and inputController:isControlDown()
		and data then
			local s = data.url
			if s then
				---mwse.log("os.openURL('%s')", s)
				---tes3.messageBox(s)
				local s2 = redirectURL(s)
				os.openURL(s2)
			end
		end
	end

	if hint
	and (string.len(hint) > 0) then
		showHint()
		checkOpenURL()
		return
	end

	local tip = false
	hint = ''
	local d_infoA = d.info

	if d_infoA then
		---assert(table.size(d_infoA) == #d_infoA)
		if questHintFirstHeardFrom then
			local heard = {}
			local heardA = {}
			for j = 1, #d_infoA do
				local info = d_infoA[j]
				if info then
					local actor = info.firstHeardFrom
					if actor
					and (actor.cloneCount == 1) then
						local actorName = actor.name
						local ref = tes3.getReference(actor.id)
						if ref then
							local cell = ref.cell
							if cell then
								local cellName = cell.editorName
								if cellName
								and (not heard[actorName]) then
									heard[actorName] = true
									table.insert(heardA, {anam = actorName, cnam = cellName})
									tip = true
								end -- if cellName
							end -- if cell
						end -- if ref
						---break -- exit loop at first actor found
					end -- if actor
				end -- if info
			end -- f
			if tip then
				for i = 1, #heardA do
					local v = heardA[i]
					hint = hint..'Heard from '..v.anam..' (now in '..v.cnam..')\n'
				end
				--[[if logLeveGT3 then
					mwse.log("%s getHint(e) quest %s %s", modPrefix, questId, hint)
				end]]
				hint = hint .. '\n'
			end
		end -- if questHintFirstHeardFrom

		if questHintQuestInfo then
			for i = 1, #d_infoA do
				local info = d_infoA[i]
				--[[if logLevel2 then
					mwse.log("%s info.text = %s", modPrefix, info.text)
				end]]
				local info_journaIndex = info.journalIndex
				if info_journaIndex
				and (info_journaIndex == journalIndex) then
					local s = info.text
					if s
					and (string.len(s) > 0) then
						local s2 = stripTags(s)
						if s2 then
							hint = hint .. s2 .. '\n\n'
							if copyPaste then
								---mwse.log('os.setClipboardText("%s")', hint)
								os.setClipboardText(hint)
							end
							tip = true
 -- exit loop when current journalIndex dialog info found
							break
						end
					end  -- if s
				end -- if journalIndex == disposition
			end -- for info
		end -- if questHintQuestInfo

	end -- if d_infoA

	if questHintQuestId
	and (journalIndex > 0) then
		hint = hint .. string.format('GetJournalIndex("%s") == %s\n\n', questId, journalIndex)
		tip = true
	end

	if data then
		if questHintSourceMod then
			hint = hint..string.format("Plugin %04d %s\n\n", data.idx, sourceMod)
			tip = true
		end
		if questHintAltSourceInfo
		and altDown then
			if data.aut then
				hint = hint..'Author: '..data.aut..'\n\n'
				tip = true
			end
			local modInfo = data.inf
			if modInfo then
				hint = hint..'Info: '..modInfo..'\n\n'
				tip = true
			end
		end
	end

	if tip then
		hint = string.sub(hint, 1, -3) -- strip last \n\n
		qd.hint = hint
		showHint()
		checkOpenURL()
		---assert(qd.hint == hint)
	---else
		---hint = nil
	end

end

local function isShowingTopicsIndex(menuJournal_bookmark)
	local menuJournal_focus = menuJournal_bookmark:findChild(idMenuJournal_focus)
	if menuJournal_focus then
		if menuJournal_focus.visible then
			return true
		end
	end
	return false
end

local function isShowingCalendar(menuJournal_bookmark)
	local menuJournal_calendar_pane = menuJournal_bookmark:findChild(idMenuJournal_calendar_pane)
	if menuJournal_calendar_pane then
		if menuJournal_calendar_pane.visible then
			return true
		end
	end
	return false
end

local function isShowingTopicsIndexOrCalendar(menuJournal_bookmark)
	return isShowingTopicsIndex(menuJournal_bookmark)
	or isShowingCalendar(menuJournal_bookmark)
end

--[[
local function isShowingQuests(menuJournal_bookmark)
	local menuJournal_button_bookmark_quests_all_idle = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_quests_all_idle)
	if menuJournal_button_bookmark_quests_all_idle then
		if menuJournal_button_bookmark_quests_all_idle.visible then
			return true
		end
	end
	local menuJournal_button_bookmark_quests_active_idle = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_quests_active_idle)
	if menuJournal_button_bookmark_quests_active_idle then
		if menuJournal_button_bookmark_quests_active_idle.visible then
			return true
		end
	end

	local menuJournal_button_bookmark_quests_all_over = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_quests_all_over)
	if menuJournal_button_bookmark_quests_all_over then
		if menuJournal_button_bookmark_quests_all_over.visible then
			return true
		end
	end
	local menuJournal_button_bookmark_quests_active_over = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_quests_active_over)
	if menuJournal_button_bookmark_quests_active_over then
		if menuJournal_button_bookmark_quests_active_over.visible then
			return true
		end
	end

	local menuJournal_button_bookmark_quests_all_pressed = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_quests_all_pressed)
	if menuJournal_button_bookmark_quests_all_pressed then
		if menuJournal_button_bookmark_quests_all_pressed.visible then
			return true
		end
	end
	local menuJournal_button_bookmark_quests_active_pressed = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_quests_active_pressed)
	if menuJournal_button_bookmark_quests_active_pressed then
		if menuJournal_button_bookmark_quests_active_pressed.visible then
			return true
		end
	end

	return false
end
]]

local sSearch = 'Search...'
local idab01journalSearchInput = tes3ui.registerID("ab01journalSearchInput")

local function updateLayout(el)
	if el
	and el.visible then
		el:updateLayout()
	end
end

---local lastSearch = true

local function updateBookmark(menu)
	local menuJournal_bookmark = menu:findChild(idMenuJournal_bookmark)
	if not menuJournal_bookmark then
		return
	end
	if not menuJournal_bookmark.visible then
		return
	end
	local menuJournal_bookmark_layout = menuJournal_bookmark:findChild(idMenuJournal_bookmark_layout)
	if not menuJournal_bookmark_layout then
		return
	end
	--- mwse.log("updateBookmark(menuJournal_bookmark_layout = %s)", menuJournal_bookmark_layout)

	local menuJournal_topicscroll = menuJournal_bookmark_layout:findChild(idMenuJournal_topicscroll)
	if not menuJournal_topicscroll then
		return -- it happens
	end
	local partScrollPane_pane = menuJournal_topicscroll:findChild(idPartScrollPane_pane)
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

	local searchInput = menuJournal_bookmark:findChild(idab01journalSearchInput)

	local lcsSearch = string.lower(sSearch)

	local areQuests = false
	if getHintsOrQuestPrefixOrFilterOn() then
		for i = 1, #children do
			local el = children[i]
			local key = el.text
			if key then
				local value = questsByName[key]
				if value then
					areQuests = true
					if questPrefix > 0 then
						local prefixed = value.prefixed
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
			sortQuests(children) -- sort quests list
		end
	end -- if getHintsOrQuestPrefixOrFilterOn()

	local searchText = searchInput.text:lower()
	local search = not (
		(string.len(searchText) <= 0)
		or (searchText == lcsSearch)
	)
	--[[if search == lastSearch then
		if not search then
			return
		end
	end
	lastSearch = search]]

	local shiftPressed = inputController:isShiftDown()
	for i = 1, #children do
		local el = children[i]
		if search then
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
			local el = children[i]
			if el.visible then
				if not el:getPropertyBool('ab01sjh') then
					el:setPropertyBool('ab01sjh', true)
					el:register('help', getHint)
				end
			end
		end
	end

	local areTopics = false
	local menuJournal_button_bookmark_topics = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_topics)
	if menuJournal_button_bookmark_topics then
		local menuJournal_button_bookmark_topics_pressed = menuJournal_button_bookmark_topics:findChild(
			idMenuJournal_button_bookmark_topics_pressed)
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
				local el = children[i]
				local dialogue = el:getPropertyObject('PartHyperText_dialog')
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

local function updateMenuBookmark(e)
	---lastSearch = not lastSearch
	updateBookmark(e.source:getTopLevelMenu())
end

local function onOK(e)
	updateMenuBookmark(e)
end
--[[local function onCancel(e)
	updateBookmark(e.source:getTopLevelMenu())
end]]

local function onClear(e)
	e.source.text = sSearch
	updateMenuBookmark(e)
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
	local input = border:createTextInput({id = idab01journalSearchInput})
	input.text = sSearch
	input.borderLeft = 3
	input.borderRight = 3
	input.color = {0.000, 0.000, 0.000}
	input.widget.lengthLimit = 50
	input.widget.eraseOnFirstKey = true
	el:register('keyEnter', onOK) -- only works when text input is not captured
	input:register('keyEnter', onOK)
	input:register('mouseClick', onClear)

	input:registerAfter('textUpdated', updateMenuBookmark)
	input:registerAfter('textCleared', onClear)

	local menu = el:getTopLevelMenu()
	updateLayout(menu)
	if questFilter then
		el:registerAfter('destroy', enableJournalCloseKeybind)
		disableJournalCloseKeybind()
	end
end

local function addYearToJournalDate(journalDateStr)
	-- insert year e.g. from 16 Last Seed (Day 1) to 16 Last Seed, 3E 427 (Day 1)
	local daysPassed = string.match(journalDateStr, "[^3][^E] %(Day (%d+)%)$")
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
		if el.id == idMenuBook_hypertext then
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
		if el.id == idMenuBook_hypertext then
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
		updateLayout(menuBook_page)
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
		if inputController:isControlDown() then
			if elId == idMenuBook_hipertext then
				text = stripTags(text)
				os.setClipboardText(text)
			elseif elId == idPartParagraphInput_text_input then
				text = string.sub(text, 1, -2) -- strip last '|' character
				os.setClipboardText(text)
			end
		elseif inputController:isShiftDown() then
			if elId == idPartParagraphInput_text_input then
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
	if not skipLinksInsideWords then
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
	for i = 1, #children do
		local el = children[i]
		if (el.id == idMenuBook_hypertext)
		and ( not el:getPropertyBool(ab01sjd) ) then
			el:setPropertyBool(ab01sjd, true)
			local text = el.text
			if text
			and ( string.len(text) > 2 ) then
				el.text = stripFalseLinks(text)
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
		local page_1 = menu:findChild(idMenuBook_page_1)
		local page_2 = menu:findChild(idMenuBook_page_2)
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
	local menuJournal_bookmark = menu:findChild(idMenuJournal_bookmark)
	if not menuJournal_bookmark then
		return
	end
	local journalSearchInput = menuJournal_bookmark:findChild(idab01journalSearchInput)
	if journalSearchInput then
		if clear then
			journalSearchInput:triggerEvent('mouseClick')
		end
		if questFilter then
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
	updateLayout(menu)
end

local function journalButtonClick(e)
	checkQuestNames()
	local el = e.source
	el:forwardEvent(e)
	local menu = el:getTopLevelMenu()
	updateJournalSearchInput(menu, config.clearFilter)
	updateLayout(menu)
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
		updateLayout(menu)
	end
end

local function uiActivatedMenuJournal(e)
	local el = e.element
	if not e.newlyCreated then
		return
	end
	checkQuestNames()
	el:register('update', onUpdateJournal)
	local menuBook_button_take = el:findChild(idMenuBook_button_take)
	if menuBook_button_take then
		menuBook_button_take:register('mouseClick', journalButtonClick)
	end

	local menuJournal_bookmark = el:findChild(idMenuJournal_bookmark)
	if menuJournal_bookmark then

		local menuJournal_calendar_pane = menuJournal_bookmark:findChild(idMenuJournal_calendar_pane)
		if menuJournal_calendar_pane then
			local menuJournal_calendar_notespane = menuJournal_calendar_pane:findChild(idMenuJournal_calendar_notespane)
			if menuJournal_calendar_notespane then
				local partParagraphInput_text_input = menuJournal_calendar_notespane:findChild(idPartParagraphInput_text_input)
				if partParagraphInput_text_input then
					---mwse.log(">>> Smart Journal: partParagraphInput_text_input:register('mouseClick', calendarInputClick)")
					partParagraphInput_text_input:register('mouseClick', calendarInputClick)
				end
			end
		end

		local menuJournal_button_bookmark_quests_active = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_quests_active)
		if menuJournal_button_bookmark_quests_active then
			menuJournal_button_bookmark_quests_active:register('mouseClick', journalButtonClick)
		end
		local menuJournal_button_bookmark_quests_all = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_quests_all)
		if menuJournal_button_bookmark_quests_all then
			menuJournal_button_bookmark_quests_all:register('mouseClick', journalButtonClick)
		end
		local menuJournal_button_bookmark_quests = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_quests)
		if menuJournal_button_bookmark_quests then
			menuJournal_button_bookmark_quests:register('mouseClick', journalButtonClick)
			makeInput(menuJournal_bookmark)
		end
		local menuJournal_button_bookmark_topics = menuJournal_bookmark:findChild(idMenuJournal_button_bookmark_topics)
		if menuJournal_button_bookmark_topics then
			menuJournal_button_bookmark_topics:register('mouseClick', journalButtonClick2)
		end

		if adjustBookmarkWidth then
			menuJournal_bookmark.absolutePosAlignX = 0.945
			menuJournal_bookmark.width = 410
			menuJournal_bookmark.height = 572
			menuJournal_bookmark.imageScaleX = 2.49
			menuJournal_bookmark.imageScaleY = 2.3218

			local menuJournal_bookmark_layout = menuJournal_bookmark:findChild(idMenuJournal_bookmark_layout)
			---assert(menuJournal_bookmark_layout)
			local menuJournal_topicscroll = menuJournal_bookmark_layout:findChild(idMenuJournal_topicscroll)
			local widget
			if menuJournal_topicscroll then
				local partScrollPane_pane = menuJournal_topicscroll:findChild(idPartScrollPane_pane)
				if partScrollPane_pane then
					widget = menuJournal_topicscroll.widget
					updateLayout(partScrollPane_pane)
				end
				updateLayout(menuJournal_topicscroll)
			end
			updateLayout(menuJournal_bookmark_layout)
			updateLayout(menuJournal_bookmark)
			updateLayout(el)
			if widget then
				widget:contentsChanged()
			end
		end
		updateJournalElement(el)
	end
end

local idMenuDialog_scroll_pane = tes3ui.registerID('MenuDialog_scroll_pane')
local idMenuDialog_notify = tes3ui.registerID('MenuDialog_notify')


-- set in modConfigReady() event
local sJournalEntryGMST, sJournalEntry

local dialogScrollPane

local function updateDialog(e)
	local el = dialogScrollPane
	if not el then
		el = e.source:findChild(idMenuDialog_scroll_pane)
		if not el then
			return
		end
		dialogScrollPane = el
	end
	local pane = el:findChild(idPartScrollPane_pane)
	if not pane then
		return
	end
	local visible = not config.upgradeJournalMessage
	for node in table.traverse(pane.children) do
		if (node.id == idMenuDialog_notify)
		and node.text
		and (node.text == sJournalEntry)
		and ( not (node.visible == visible) ) then
			node.visible = visible
			updateLayout(el:getTopLevelMenu())
			return
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



---@diagnostic disable-next-line: lowercase-global
ab01cachedInfoText = {} -- shared global variable on purpose
local function clearCachedInfoText()
	local t = ab01cachedInfoText
	for k, v in pairs(t) do
		if v then
			t[k] = nil
		end
	end
---@diagnostic disable-next-line: lowercase-global
	ab01cachedInfoText = {}
end
event.register('cellChanged', clearCachedInfoText)

local function loadOriginalText(e)
	local id = e.info.id
	local v = ab01cachedInfoText[id]
	if v then
		return v
	end

	-- caching the fucking thing as it is crashy if you call it
	-- from different mods, same (infoGetText) event
	v = e:loadOriginalText()

	ab01cachedInfoText[id] = v
	return v
end

local tes3_dialogueType_greeting = tes3.dialogueType.greeting
local tes3_dialogueType_topic = tes3.dialogueType.topic

local function infoGetText(e)
	local info = e.info
	local info_type = info.type
	if not (
		(info_type == tes3_dialogueType_topic)
	 or (info_type == tes3_dialogueType_greeting)
	) then
		return
	end
	local s = loadOriginalText(e)
	local s2 = s
	if string.len(s) > 2 then
		local st = stripTags(s)
		if st and
		( string.len(st) > 0 ) then
			s2 = st
		end
	end
	local s3 = s2
	local mob = tes3ui.getServiceActor()
	if mob then
		s3 = tes3.applyTextDefines({text = s2, actor = mob.reference.object})
	end
	---tes3ui.showNotifyMenu(s2)
	if logLevel3 then
		mwse.log("%s infoGetText() %s", modPrefix, s3)
	end
	if copyPaste
	and s3 then
		os.setClipboardText(s3)
	end
end

local function delayedInfoGetText(e)
	local function myInfoGetText(e)
	    timer.frame.delayOneFrame(function () infoGetText(e) end)
	end
	timer.frame.delayOneFrame(myInfoGetText)
end

local infoGetTextRegistered = false
local function setInfoGetText(on)
	local settings = {priority = -20000}
	if infoGetTextRegistered
	or event.isRegistered('infoGetText', delayedInfoGetText, settings) then
		if on then
			return
		end
		infoGetTextRegistered = false
		event.unregister('infoGetText', delayedInfoGetText, settings)
		return
	end
	if on then
		infoGetTextRegistered = true
		event.register('infoGetText', delayedInfoGetText, settings)
	end
end

local function checkInfoGetTextRegistering()
	local infoGetTextOn = copyLastDialog
	setInfoGetText(infoGetTextOn)
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable({id = varId, table = config})
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	function template.onClose()
		updateFromConfig()

		if not (questPrefix == config.questPrefix) then
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

		if not (copyLastDialog == config.copyLastDialog ) then
			copyLastDialog = config.copyLastDialog
			checkInfoGetTextRegistering()
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
		label = 'Add year to journal date header',
		description = [[Add year to journal date header e.g.
from 16 Last Seed, (Day 1)
to 16 Last Seed, 3E 427 (Day 1).]],
		variable = createConfigVariable('addYearToDate')
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
	controls:createOnOffButton{
		label = 'Search filter',
		description = [[Add a text search filter for quest names and topics list.]],
		variable = createConfigVariable('questFilter')
	}
	controls:createOnOffButton{
		label = 'Auto clear filter',
		description = [[clear filter when changing view from topics to quests.]],
		variable = createConfigVariable('clearFilter')
	}

	controls:createDropdown{
		label = 'Add a prefix in order to group quest names:',
		description = [[Add a prefix in order to group quest names.
0. No prefix,
1. Prefixed by source mod loading order
2. Prefixed by source mod condensed name
3. Prefixed by quest identifier
Note: as prefix calculation and sorting is done on the fly, using a prefix will cause a slight delay on displaying the quest list.
Well worth IMO, but you decide.]],
		options = {
			{ label = '0. No prefix', value = 0 },
			{ label = '1. Source mod loading order (suggested)', value = 1 },
			{ label = '2. Source mod condensed name', value = 2 },
			{ label = '3. Quest identifier', value = 3 },
		},
		variable = createConfigVariable('questPrefix')
	}

	controls:createDropdown{
		label = 'Log level:',
		description = [[The amount of debug information logged to MWSE.log and/or screen.]],
		options = {
			{ label = '0. Minimum', value = 0 },
			{ label = '1. Low', value = 1 },
			{ label = '2. Medium', value = 2 },
			{ label = '3. High', value = 3 },
			{ label = '4. Max', value = 4 },
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
		label = 'Copy last quest text entry hint to clipboard',
		description = [[Copy (if visible) last quest text entry from quest hint to OS clipboard. Useful to paste it somewhere else.]],
		variable = createConfigVariable('copyPaste')
	}
	controls:createOnOffButton{
		label = 'Copy last dialog topic/greeting text to clipboard',
		description = [[Copy last dialog topic/greeting text to OS clipboard. Useful to paste it somewhere else.]],
		variable = createConfigVariable('copyLastDialog')
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
	---assert(sJournalEntryGMST)
	sJournalEntry = sJournalEntryGMST.value -- store it, default: 'Your journal has been updated.'
	---assert(sJournalEntry)

	local width, height = tes3ui.getViewportSize()
	hintMaxHeight = math.floor((height * 0.5) + 0.5)
	hintMaxWidth = math.floor((width * 0.5) + 0.5)
	inputController = tes3.worldController.inputController
	---logConfig(config, {indent = false})
	---mwse.log(modPrefix .. " modConfigReady")
end
event.register('modConfigReady', modConfigReady)

event.register('initialized', function ()
	assert(inputController == tes3.worldController.inputController)
	inputController = tes3.worldController.inputController
	assert(inputController)
	sJournalEntryGMST = tes3.findGMST(tes3.gmst.sJournalEntry)
	---assert(sJournalEntryGMST)
	sJournalEntry = sJournalEntryGMST.value -- store it, default: 'Your journal has been updated.'
	---assert(sJournalEntry)
	event.register('journal', journal, {priority = 1})
	event.register('uiActivated', uiActivatedMenuJournal, {filter = 'MenuJournal'})
	event.register('uiActivated', uiMenuDialogActivated, {filter = 'MenuDialog'})
	event.register('loaded', loaded)
	---event.register('mouseButtonUp', mouseButtonUp)
end, {doOnce = true})
