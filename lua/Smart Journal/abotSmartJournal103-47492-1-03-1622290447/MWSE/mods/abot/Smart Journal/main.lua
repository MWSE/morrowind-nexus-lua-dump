-- begin tweakables
local defaultConfig = {
clearTopicsWithNoEntries = true, -- clear topics with no entries yet from the journal
collapseDates = true, -- collapse journal paragraphs having the same date header
skipLinksInsideWords = true, -- skip links contained inside journal words
questPrefix = 1, -- add a prefix in order to group quest names (0 = No, 1 = source mod loading index, 2 = source mod condensed name, 3 = quest id)
questSort = true, -- sort quests list by quest name (better to enable it when adding a prefix)
questHintQuestId = true, -- add quest id to quest hint
questHintSourceMod = true, -- add source mod name to quest hint
questHintAltSourceInfo = true, -- add source mod Author and Info to quest hint while Alt key pressed
questHintCtrlAltURL = true, -- open first URL found in mod Info while Ctrl+Alt keys are pressed
}
-- end tweakables

local author = 'abot'
local modName = 'Smart Journal'
local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local mcm = require(author .. '.' .. modName .. '.mcm')
mcm.config = table.copy(config)

local URL_PATTERN = 'https?://[_~a-zA-Z0-9/#\\=&;%.%%%+%-%?]+'

-- return first found URL string in text, or nil
local function getFirstURL(text_with_URLs)
	local s = string.match(text_with_URLs, URL_PATTERN)
	---mwse.log("%s getFirstURL = %s", modPrefix, s)
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

local nonDynamicData -- set in loaded()

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

local function initModData() -- called in modConfigReady()
	local modList = tes3.getModList()
	modData = {}
	for loadingIndex, modFileName in pairs(modList) do
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
--[[
local GUI_ID_MenuBook_button_prev = tes3ui.registerID("MenuBook_button_prev")
local GUI_ID_MenuBook_button_next = tes3ui.registerID("MenuBook_button_next")
--]]

---local GUI_ID_MenuJournal_selecttopics = tes3ui.registerID("MenuJournal_selecttopics")
local GUI_ID_MenuJournal_topicscroll = tes3ui.registerID("MenuJournal_topicscroll")
local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

--[[
A Dialogue is a topic of conversation or journal entry that the player can have.
Properties:
id (string, read-only) The name of the dialogue.
info (tes3iterator of tes3dialogueInfo, read-only) The potential responses for this dialogue topic.
journalIndex (number, read-only) The current journal index for this entry. This is only valid when type is 4 (journal).
objectType (number, read-only) The object's Object Type.
sourceMod (string, read-only) The object's originating plugin filename.
type (number, read-only) The type of dialogue. A value of 0 is regular dialogue, 1 is voice, 2 is a greeting, 3 is persuasion, 4 is a journal entry.

tes3dialogueInfo: A child for a given dialogue. Whereas a dialogue may be a conversation topic, a tes3dialogueInfo would be an individual response.
Properties
actor (tes3actor): The speaker's actor that the info is filtered for.
cell (tes3cell): The speaker's current cell that the info is filtered for.
deleted (boolean): The deleted state of the object.
disabled (boolean): The disabled state of the object.
disposition (number): The minimum disposition that the info is filtered for.
firstHeardFrom (tes3actor): The actor that the player first heard the info from.
id (string): The unique long string ID for the info. This is not kept in memory, and must be loaded from files for each call.
id (string): The unique identifier for the object.
modified (boolean): The modification state of the object since the last save.
npcClass (tes3class): The speaker's class that the info is filtered for.
npcFaction (tes3faction): The speaker's faction that the info is filtered for.
npcRace (tes3actor): The speaker's race that the info is filtered for.
npcRank (number): The speaker's faction rank that the info is filtered for.
npcSex (number): The speaker's sex that the info is filtered for.
objectFlags (number): The raw flags of the object.
objectType (number): The type of object. Maps to values in tes3.objectType.
pcFaction (number): The player's joined faction that the info is filtered for.
pcRank (number): The player's rank required rank in the speaker's faction.
sourceMod (string): The filename of the mod that owns this object.
text (string): String contents for the info. This is not kept in memory, and must be loaded from files for each call.
type (number): The type of the info.
--]]


--[[
local function GetInfo(i)
	if not i then
		return i
	end
	local s = ""
	if i.actor then
		s = s .. string.format("actor.id = %s\n", i.actor.id)
	end
	if i.cell then
		s = s .. string.format("cell.id = %s\n", i.cell.id)
	end
	if i.disposition then
		s = s .. string.format("disposition = %s\n", i.disposition)
	end
	if i.firstHeardFrom then
		s = s .. string.format("firstHeardFrom.id = %s\n", i.firstHeardFrom.id)
	end
	if i.id then
		s = s .. string.format("id = %s\n", i.id)
	end
	--if i.sourceMod then
		--s = s .. string.format("sourceMod = %s\n", i.sourceMod)
	--
	if i.text then
		s = s .. string.format("text = %s\n", i.text)
	end
	if i.type then
		s = s .. string.format("type = %s", i.type)
	end
	return s
end
--]]

local questPrefix

local function getPrefixedQuest(modNam)
	local s
	local data = modData[modNam]
	if questPrefix == 1 then
		s = string.format("%03d", data.index)
	else
		s = data.prefix -- precalculated and stored for speed
	end
	return s
end

local questNames = {}
local sourceMods = {}

local LALT = tes3.scanCode.lAlt
local LCTRL = tes3.scanCode.lCtrl
local inputController -- initialized in onMenuJournalActivated()

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

local function getHint(e)
	local t = e.source.text
	if not t then
		return
	end
	local sm = sourceMods[t]
	if not sm then
		return
	end
	local sourceMod = sm.sourceMod
	local tip = false
	local hint = ''
	if config.questHintQuestId then
		hint = string.format( "%s = %s ", sm.questId, tes3.getJournalIndex({id = sm.questId}) )
		tip = true
	end
	if config.questHintSourceMod then
		hint = string.format("%sfrom %03d %s", hint, modData[sourceMod].index, sourceMod)
		tip = true
	end
	if config.questHintAltSourceInfo then
		if inputController:isKeyDown(LALT) then
			local auth, info = getModInfo(sourceMod)
			if auth then
				hint = string.format("%s\nAuthor: %s", hint, auth)
			end
			if info then
				hint = string.format("%s\nInfo: %s", hint, info)
			end
			tip = true
			if config.questHintCtrlAltURL then
				if inputController:isKeyDown(LCTRL) then
					local s = getFirstURL(info)
					if s then
-- using explorer instead of start as start eats & and URL parameters
						s = string.format('explorer "%s"', s)
						---mwse.log(s)
						os.execute(s)
					end
				end
			end
		end
	end
	if tip then
		local tm = tes3ui.createTooltipMenu()
		tm:createLabel({text = hint})
	end
end

local questHints = {} -- store elements with already assigned hint

--[[
local function clearQuestHints()
	if questHints then
		for _, el in pairs(questHints) do
			if el then
				el:unregister("help", getHint)
			end
		end
	end
	questHints = {}
end
--]]

local quests = {} -- cashing from dialogue database

local function initQuests() -- called in loaded()
	quests = {}
	---local i = 0
	local index
	for d in tes3.iterate(nonDynamicData.dialogues) do
		---assert(d.id)
		if d.type == 4 then -- journal
			for q in tes3.iterate(d.info) do
				if q then -- important!
					index = q.disposition
					if index then
						if index == 0 then
-- disposition is used as Journal Index in quest,
-- use it as replacement for quest name flag access as index 0 is 99% quest name /abot
							if q.text then -- important!
								---i = i + 1
								quests[d.id] = q
								---mwse.log("quests[%s] = %s", d.id, q.text)
								break
							end
						end
					end
				end
			end
		end
	end
end

local doSort = 0
local function calcQuestNames()
	---local etime = os.clock();

	questNames = {}
	sourceMods = {}
	---clearQuestHints()
	questHints = {}
	doSort = doSort + 1
	local key, pf, sm, ok, qnk, qnksm
	for id, q in pairs(quests) do
		---assert(id)
		---assert(q)
		key = q.text
		--[[
		if not key then
			mwse.log("key = %s, q = %s", key, q)
		end
		--]]
		---assert(key)
		sm = q.sourceMod
		---assert(sm)
		ok = true
		qnk = questNames[key]
		if qnk then
			qnksm = qnk.sourceMod
			if qnksm then
				if qnksm == sm then
					ok = false
					---mwse.log("qnksm = %s, sm = %s, skipping", qnksm, sm)
				end
			end
		end
		if ok then
			if string.find(key, "^.+%w+%s%>%s") then -- skip quest already prefixed
				pf = key
				ok = false
			else
				if questPrefix == 3 then
					pf = id
				else
					pf = getPrefixedQuest(sm)
				end
			end
			if ok then
				pf = string.format("%s > %s", pf, key)
				questNames[key] = { prefixed = pf, sourceMod = sm }
				sourceMods[pf] = { sourceMod = sm, questId = id }
			end
		end -- if ok
	end -- for

	---mwse.log("calcQuestNames() elapsed time: %.5f", os.clock() - etime);

end

local function checkQuestNames()
	questPrefix = config.questPrefix
	if questPrefix > 0 then
		calcQuestNames()
	end
end

function mcm.onClose()
	config = table.copy(mcm.config)
	mwse.saveConfig(configName, config, {indent = false})
	if not (questPrefix == config.questPrefix ) then
		checkQuestNames()
	end
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
	local s, s1
	for _, el in pairs(children) do
		if el.id == GUI_ID_MenuBook_hypertext then
			s = string.gsub(el.text, "@(%w+)#(%w+)", "%1%2")
			s1 = string.gsub(s, "(%w+)@(%w+)#", "%1%2")
			if not (s1 == el.text) then
				---mwse.log("before:\n%s\nafter:\n%s", el.text, s1)
				el.text = s1
			end
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
				if string.match(text,"^%d+ .+%d+%)$") then
					headers[text] = 1
				end
			end
		elseif skip then
			el.text = string.gsub(el.text, "@(%w+)#(%w%w+)", "%1%2")
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
					el:destroy()
					--- el.disabled = true -- maybe safer if some other mod is looking for it?
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
	---local etime = os.clock();
	keys = {}
	elements = {}
	local n = 0
	for _, el in pairs(children) do
		---assert(el)
		if el.visible then
			---assert(not el.disabled)
			n = n + 1
			keys[n] = { text = el.text, dialogue = el:getPropertyObject("PartHyperText_dialog") }
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
			el:setPropertyObject("PartHyperText_dialog", k.dialogue )
			---mwse.log("children[%s].text = %s", i, el.text)
		end
	end
	---mwse.log("sortQuests() elapsed time: %.5f", os.clock() - etime);

end

local function updateBookmark(menuJournal_bookmark)
	if not menuJournal_bookmark then
		return
	end
	if not menuJournal_bookmark.visible then
		return
	end
	---menuJournal_bookmark.absolutePosAlignX = 0.768
	---menuJournal_bookmark.imageScaleX = 2.41
	---menuJournal_bookmark:updateLayout()

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

	if areTopics == 0 then

		update = true
		local hintsOn = config.questHintSourceMod or config.questHintAltSourceInfo
		for _, el in pairs(children) do
			if el then
				key = el.text
				if key then
					value = questNames[key]
					if value then
						if questPrefix > 0 then
							prefixed = value.prefixed
							if not (prefixed == el.text ) then
								el.text = prefixed
							end
						end
						if hintsOn then
							if not questHints[el.text] then --- questHints are cleared in calcQuestNames()
								questHints[el.text] = el
								el:register("help", getHint)
							end
						end
					end
				end
			end
		end

		-- sort quest list
		if config.questSort then
			---if doSort > 0 then -- set by calcQuestNames
				---doSort = doSort - 1
				---local etime = os.clock();
				sortQuests(children)
				---mwse.log("sortQuests() elapsed time: %.5f", os.clock() - etime);
			---end
		end

	elseif areTopics == 2 then

		for _, el in pairs(children) do
			if el then
				if config.clearTopicsWithNoEntries then
					dialogue = el:getPropertyObject("PartHyperText_dialog")
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
							el:destroy() -- clear topic with no entries yet
						end
					end
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
	if (questPrefix > 0)
	or config.questSort
	or config.questHintSourceMod
	or config.questHintAltSourceInfo then
		updateBookmark(menu:findChild(GUI_ID_MenuJournal_bookmark))
	end
end

local function updateJournalElement(menu)
	updateJournalPages(menu)
	updateJournalBookmark(menu)
end

local function onUpdateJournal(event)
	local el = event.source -- one time is element, one time is source...
	---mwse.log("onUpdateJournal %s", el.name)
	updateJournalElement(el)
	el:forwardEvent(event)
end

local function journalButtonClick(e)
	---mwse.log("journalButtonClick %s", e.source.name)
	checkQuestNames()
	e.source:forwardEvent(e)
end

--[[
local LSHIFT = tes3.scanCode.lShift
local RSHIFT = tes3.scanCode.rShift

local function isShiftDown()
	return inputController:isKeyDown(LSHIFT)
	or inputController:isKeyDown(RSHIFT)
end

local function uiEventJournal(e)
	if e.property == 4294934580 then -- click
		local el = e.block
		mwse.log("var1 = %s, property = %s, var2 = %s, id = %s, name = %s, text = %s", e.var1, e.property, e.var2, el.id, el.name, el.text)
		if not isShiftDown() then -- shift+click may be used by a mod to hide quests, skip it
			local menu = el:getTopLevelMenu()
			if menu == tes3ui.getMenuOnTop() then
				if (el.id == -1093) then -- PartHyperText_link
					updateJournalPages(menu)
					updateJournalBookmark(menu)
				elseif (el.id == -32588) then -- text links (quests, topics)
					updateJournalPages(menu)
					updateJournalBookmark(menu)
				end
			end
		end
	end
end
]]

local function onDestroyJournal(e)
-- source (Element) The source element of the event
	---e.source:unregister('uiEvent', uiEventJournal)
	e.source:unregister("update", onUpdateJournal)
end

local function onMenuJournalActivated(event)
	local el = event.element
	if event.newlyCreated then
		el:register("update", onUpdateJournal)
		---el:register('uiEvent', uiEventJournal)
		el:registerAfter("destroy", onDestroyJournal)
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
		end
		local menuBook_button_take = el:findChild(GUI_ID_MenuBook_button_take)
		if menuBook_button_take then
			menuBook_button_take:register("mouseClick", journalButtonClick)
		end
	end
	updateJournalElement(el)
end
event.register("uiActivated", onMenuJournalActivated, { filter = "MenuJournal" })

local function modConfigReady()
	mwse.log(modPrefix .. " modConfigReady")
	mwse.registerModConfig(mcmName, mcm)
	logConfig(config, {indent = false})
	initModData()
	questPrefix = config.questPrefix
end
event.register('modConfigReady', modConfigReady)

local function loaded()
	nonDynamicData = tes3.dataHandler.nonDynamicData
	inputController = tes3.worldController.inputController
	initQuests()
	questHints = {} -- I have a feeling UI events are no more valid = crashing on reload
	---checkQuestNames()
	mwse.log(modPrefix .. " loaded")
end
event.register("loaded", loaded)
