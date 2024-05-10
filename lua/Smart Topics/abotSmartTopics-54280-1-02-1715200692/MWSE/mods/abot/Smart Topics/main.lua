--[[
Press Alt while clicking a dialog topic to try and add
hidden/overridden topics to player known topics list

Ctrl + Alt + click to log/paste to clipboard the dialog INFO
hopefully including the sourceMod (name of the mod changing the dialog INFO),
something very useful to know in case of dialog conflicts.
]]


local logLevel = 0

local author = 'abot'
local modName = 'Smart Topics'
local modPrefix = author .. '/' .. modName

local logLevel1 = (logLevel >= 1)
local logLevel2 = (logLevel >= 2)
local logLevel3 = (logLevel >= 3)
---local logLevel4 = (logLevel >= 4)

local tes3_dialogueType_topic = tes3.dialogueType.topic
---local tes3_dialogueType_greeting = tes3.dialogueType.greeting

-- set in loaded
local notYetKnownTopics = {}
local knownTopicsDict = {}

local function topicAdded(e)
	knownTopicsDict[string.lower(e.topic.id)] = true
end

local function stripTags(text)
	return string.gsub(text, '[@#]', '')
end

local function addMissingTopics(text)
	--[[
	local etime
	if logLevel2 then
		etime = os.clock()
	end
	]]
	local lcText = string.lower(text)
	local maxMatchLen = 0
	local infoMatchesDict = {}
	for lcMatch in string.gmatch(lcText, "@(%w+)#") do
		infoMatchesDict[lcMatch] = true
		local matchLen = string.len(lcMatch)
		if matchLen > maxMatchLen then
			maxMatchLen = matchLen
		end
	end
	local t = {}
	local t2 = {}
	local j = 0
	for i = 1, #notYetKnownTopics do
		local lcTopic = notYetKnownTopics[i]
		if (not infoMatchesDict[lcTopic])
		and (not knownTopicsDict[lcTopic]) then
			local lenLcTopic = string.len(lcTopic)
			if lenLcTopic < maxMatchLen then
				for lcMatch, _ in pairs(infoMatchesDict) do
				---mwse.log('%s: processing topic "%s"', modPrefix, lcMatch)
					if (lenLcTopic < string.len(lcMatch))
					and string.find(lcMatch, lcTopic, 1, true) then
						j = j + 1
						t[j] = lcTopic
						t2[j] = lcMatch
					end
				end
			else
				break
			end
		end
	end
	for i = 1, #t do
		local lcTopic = t[i]
		if tes3.addTopic({topic = lcTopic, updateGUI = false}) then
			if logLevel1 then
				local s = string.format('%s: topic "%s" (overridden by topic "%s") added to player known topics.',
					modPrefix, lcTopic, t2[i])
				print(s)
				--[[if logLevel2 then
					tes3ui.showNotifyMenu(s) -- not really noticeable
				end]]
			end
		end
	end
	--[[
	if logLevel2 then
		mwse.log('%s: addMissingTopics() elapsed time: %.4f', modPrefix, os.clock() - etime)
	end
	]]
end

local tes3_dialogueFilterContext_clickTopic = tes3.dialogueFilterContext.clickTopic
local contextDict = table.invert(tes3.dialogueFilterContext)


---local function back2slash(s)
	---return string.gsub(s, [[\]], [[/]])
---end

--[[

local bethMasters = {['Morrowind.esm'] = true, ['Tribunal.esm'] = true, ['Bloodmoon.esm'] = true}

local function getTopicDatas(topicId)
	local d = tes3.findDialogue({topic = topicId})
	local infos = d.info
	local t = {}
	local j = 0
	---local mob = tes3ui.getServiceActor()
	---if not mob then
		---mob = tes3.mobilePlayer
	---end
	---local obj = mob.reference.object

	for i = 1, #infos do
		local info = infos[i] -- must be local?
		if info then
			local sourceMod = info.sourceMod
			if sourceMod
			and (not bethMasters[sourceMod])
			and ( not (sourceMod == '') ) then
				j = j + 1
				local s = ''
				local text = info.text
				if text
				and (string.len(text) > 0) then
					s = back2slash(text)
					s = stripTags(s)
					-- replace remaining % with %% to avoid mwse.log pattern parsing problems
					s = string.gsub(s, "%[^%]", "%%")
				end
				t[j] = {ii = info.id, it = s, sm = sourceMod}
			end
		end
	end
	return t
end

local function topicInfos(topicId)
	local topicDatas = getTopicDatas(topicId)
	local count = #topicDatas
	if count == 0 then
		return
	end
	local hdr = string.format('Loaded mods changing topic "%s":', topicId)
	local s = string.format('%s: topicInfos()\n%s\nsourceMod\t#\tinfoID\tinfoText\n',
		modPrefix, hdr)
	local td
	for i = 1, count do
		td = topicDatas[i]
		s = s..'"'..td.sm..'"\t"'..tostring(i)..'"\t"'..td.ii..'"\t"'..td.it..'"\n'
	end
	os.setClipboardText(s)
	print(s)
end
]]

local inputController -- set in initialized

local function dialogueFiltered(e)
	if not (e.context == tes3_dialogueFilterContext_clickTopic) then
		return
	end
	if not inputController:isAltDown() then
		return
	end
	local info = e.info
	local text = info.text
	if not text then
		return
	end
	if string.len(text) <= 0 then
		return
	end
	if inputController:isControlDown() then
		local fmt = [[%s: dialogueFiltered(e)
dialogue.id = "%s" context = "%s" actor = "%s" reference = "%s"
info.id = "%s" info.sourceMod = "%s"
info.text = "%s"]]
		local s = string.format(fmt, modPrefix, e.dialogue.id, contextDict[e.context],
			e.actor, e.reference, info.id, info.sourceMod, stripTags(text))
		print(s) -- no mwse.log(s) to avoid problems with foemat error with %name etc
		os.setClipboardText(s)
		return
	end
	addMissingTopics(text)
end

local function byLength(a, b)
	return string.len(a) < string.len(b)
end

--[[ -- slower
local fmt = "%04d%s"
local function byLengthAndAlpha(a, b)
	return string.format(fmt, string.len(a), a) < string.format(fmt, string.len(b), b)
end
]]

local function initTopics()
	local etime
	if logLevel2 then
		etime = os.clock()
	end
	for k, v in pairs(knownTopicsDict) do
		if v then
			knownTopicsDict[k] = nil
		end
	end
	knownTopicsDict = {}
	local dialogueList = tes3.mobilePlayer.dialogueList

    for i = 1, #dialogueList do
		local d = dialogueList[i]
		---assert(d.type == tes3_dialogueType_topic)
		local lcTopic = string.lower(d.id)
		knownTopicsDict[lcTopic] = true
	end

	for k, v in pairs(notYetKnownTopics) do
		if v then
			notYetKnownTopics[k] = nil
		end
	end
	notYetKnownTopics = {}

	local dialogues = tes3.dataHandler.nonDynamicData.dialogues
	local j = 0
	for i = 1, #dialogues do
		local d = dialogues[i]
		if d.type == tes3_dialogueType_topic then
			local lcId = string.lower(d.id)
			if not knownTopicsDict[lcId] then
				j = j + 1
				notYetKnownTopics[j] = lcId
			end
		end
	end

	-- slower, and no need to be conservative on alphabetic order
	--- table.sort(notYetKnownTopics, byLengthAndAlpha)

	-- alphabetic sort first...
	table.sort(notYetKnownTopics)
	-- ... then by length (the important one for early break in addMissingTopics)
	table.sort(notYetKnownTopics, byLength)

	if logLevel3 then
		for i = 1, #notYetKnownTopics do
			mwse.log('%s: notYetKnownTopics[%s] = "%s"', modPrefix, i, notYetKnownTopics[i])
		end
	end
	if logLevel2 then
		mwse.log('%s: initTopics() elapsed time: %.4f', modPrefix, os.clock() - etime)
	end
end

local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	event.register('topicAdded', topicAdded)
	event.register('dialogueFiltered', dialogueFiltered)
end

local function loaded()
	initTopics()
	initOnce()
end

event.register('initialized', function ()
	inputController = tes3.worldController.inputController
	event.register('loaded', loaded)
end---, {doOnce = true}
)