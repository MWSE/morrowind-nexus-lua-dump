--[[
Press Alt while clicking a dialog topic to try and add
hidden/overridden topics to player known topics list
]]
local logLevel = 1

local author = 'abot'
local modName = 'Smart Topics'
local modPrefix = author .. '/' .. modName

local logLevel1 = (logLevel >= 1)
local logLevel2 = (logLevel >= 2)
local logLevel3 = (logLevel >= 3)
local logLevel4 = (logLevel >= 4)

local tes3_dialogueType_topic = tes3.dialogueType.topic
---local tes3_dialogueType_greeting = tes3.dialogueType.greeting

-- set in loaded
local notYetKnownTopics = {}
local knownTopicsDict = {}

local function topicAdded(e)
	knownTopicsDict[string.lower(e.topic.id)] = true
end

local function addMissingTopics(text)
	--[[ -- not needed, it is fast
	local etime
	if logLevel2 then
		etime = os.clock()
	end
	]]
	local lcText = string.lower(text)
	local matchLen = 0
	local maxMatchLen = 0
	local infoMatchesDict = {}
	for lcMatch in string.gmatch(lcText, "@(%w+)#") do
		infoMatchesDict[lcMatch] = true
		matchLen = string.len(lcMatch)
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
	local s
	for i = 1, #t do
		local lcTopic = t[i]
		if tes3.addTopic({topic = lcTopic, updateGUI = false}) then
			if logLevel1 then
				s = string.format('%s: topic "%s" (overridden by topic "%s") added to player known topics.',
					modPrefix, lcTopic, t2[i])
				mwse.log(s)
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

local function dialogueFiltered(e)
	if not (e.context == tes3_dialogueFilterContext_clickTopic) then
		return
	end
	if not tes3.worldController.inputController:isAltDown() then
		return
	end
	local text = e.info.text
	if logLevel4 then
		mwse.log([[%s: dialogueFiltered(e)
actor = "%s" context = "%s" dialogue.id = "%s"
info.text = "%s" reference = "%s"]],
			modPrefix, e.actor, contextDict[e.context],
			e.dialogue.id, text, e.reference.id)
	end
	addMissingTopics(text)
end

local function byLength(a, b)
	return string.len(a) < string.len(b)
end

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
	local d, lcTopic
	for i = 1, #dialogueList do
		d = dialogueList[i]
		---assert(d.type == tes3_dialogueType_topic)
		lcTopic = string.lower(d.id)
		knownTopicsDict[lcTopic] = true
	end

	for k, v in pairs(notYetKnownTopics) do
		if v then
			notYetKnownTopics[k] = nil
		end
	end
	notYetKnownTopics = {}

	local dialogues = tes3.dataHandler.nonDynamicData.dialogues
	local lcId
	local j = 0
	for i = 1, #dialogues do
		d = dialogues[i]
		if d.type == tes3_dialogueType_topic then
			lcId = string.lower(d.id)
			if not knownTopicsDict[lcId] then
				j = j + 1
				notYetKnownTopics[j] = lcId
			end
		end
	end
	table.sort(notYetKnownTopics) -- alphabetic sort first...
	table.sort(notYetKnownTopics, byLength) -- ... then by length (the important one)
	if logLevel3 then
		for i = 1, #notYetKnownTopics do
			mwse.log('%s: notYetKnownTopics[%s] = "%s"', modPrefix, i, notYetKnownTopics[i])
		end
	end
	if logLevel2 then
		mwse.log('%s: initTopics() elapsed time: %.4f', modPrefix, os.clock() - etime)
	end
end

local function loaded()
	initTopics()
end

event.register('modConfigReady', function ()
	event.register('loaded', loaded)
	event.register('topicAdded', topicAdded)
	event.register('dialogueFiltered', dialogueFiltered)
end)