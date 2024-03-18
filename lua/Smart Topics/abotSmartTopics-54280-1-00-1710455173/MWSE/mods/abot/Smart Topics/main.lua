--[[
Press Alt while clicking a dialog topic to try and add
hidden/overridden topics to player known topics list 
]]

local author = 'abot'
local modName = 'Smart Topics'
local modPrefix = author .. '/' .. modName

local function getClearedTable(t)
	for k, v in pairs(t) do
		if v then
			t[k] = nil
		end
	end
	t = {}
	return t
end

local tes3_dialogueType_topic = tes3.dialogueType.topic
local tes3_dialogueType_greeting = tes3.dialogueType.greeting

-- set in loaded
local topics = {}
local knownTopicsDict = {}

local function topicAdded(e)
	knownTopicsDict[string.lower(e.topic.id)] = true
end

local function addMissingTopics(text)
	local lcText = string.lower(text)
	local matchesDict = {}
	for lcId in string.gmatch(lcText, "@(%w+)#") do
		matchesDict[lcId] = true
	end
	local lcTopic, lenLcId
	for lcId, _ in pairs(matchesDict) do
		---mwse.log('%s: processing topic "%s"', modPrefix, lcId)
		lenLcId = string.len(lcId)
		for i = 1, #topics do
			lcTopic = topics[i]
			if (string.len(lcTopic) < lenLcId)
			and (not matchesDict[lcTopic])
			and (not knownTopicsDict[lcTopic]) then
				if string.find(lcId, lcTopic, 1, true) then
					if tes3.addTopic({topic = lcTopic, updateGUI = true}) then
						mwse.log('%s: topic "%s" (overridden by topic "%s") added to player known topics',
							modPrefix, lcTopic, lcId)
					end
				end
			end
		end
	end
end

 -- set in modConfigReady()
local inputController

local function infoFilter(e)
    if not e.passes then
        return
    end
	local dType = e.dialogue.type
	if not (
		(dType == tes3_dialogueType_topic)
		or (dType == tes3_dialogueType_greeting)
	) then
		return
	end
	-- needed else there is not enought time to execute dialogue result
	if not inputController:isAltDown() then
		return
	end
	addMissingTopics(e.info.text)
end

local function initTopics()
	knownTopicsDict = getClearedTable(knownTopicsDict)
	local dialogueList = tes3.mobilePlayer.dialogueList
	local lcTopic, d
	for i = 1, #dialogueList do
		d = dialogueList[i]
		---assert(d.type == tes3_dialogueType_topic)
		lcTopic = string.lower(d.id)
		knownTopicsDict[lcTopic] = true
	end
	
	local dialogues = tes3.dataHandler.nonDynamicData.dialogues
	local lcId
	local j = 0
	topics = getClearedTable(topics)
	for i = 1, #dialogues do
		d = dialogues[i]
		if d.type == tes3_dialogueType_topic then
			lcId = string.lower(d.id)
			if not knownTopicsDict[lcId] then
				j = j + 1
				topics[j] = lcId
			end
		end
	end
	table.sort(topics) -- first alphabetical
	-- then by length
	local function byLen(a, b)
		return string.len(a) < string.len(b)
	end
	table.sort(topics, byLen)
end

local function loaded()
	initTopics()
end

local function modConfigReady()
	inputController = tes3.worldController.inputController
	event.register('loaded', loaded)
	event.register('topicAdded', topicAdded)
	event.register('infoFilter', infoFilter)
end
event.register('modConfigReady', modConfigReady)