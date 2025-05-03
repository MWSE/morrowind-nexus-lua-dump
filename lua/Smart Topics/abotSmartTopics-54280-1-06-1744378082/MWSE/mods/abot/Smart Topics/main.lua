--[[
Press Shift while clicking a dialog topic/choice to log/paste to clipboard
the dialog INFO, hopefully including the sourceMod (name of the mod changing
the dialog INFO), something very useful to know in case of dialog conflicts.

Press Shift while activating an actor to log to MWSE.log/paste to clipboard the
next dialog greeting INFO triggered by that actor.

Press Ctrl + Shift while clicking a dialog topic to try and add
hidden/overridden topics to player known topics list.
]]

local defaultConfig = {
logLevel = 0,
}

local author = 'abot'
local modName = 'Smart Topics'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config) -- just to avoid Lua diagnostic complains

-- refreshed in modConfigReady()
local logLevel, logLevel1, logLevel2, logLevel3

local function updateFromConfig()
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
end
updateFromConfig()


local tes3_dialogueType_topic = tes3.dialogueType.topic
---local tes3_dialogueType_greeting = tes3.dialogueType.greeting

-- set in loaded
local notYetKnownTopics = {}
local knownTopicsDict = {}

local function topicAdded(e)
	local d = e.topic
	knownTopicsDict[string.lower(d.id)] = d
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
	for lcMatch in string.gmatch(lcText, "@([%w%[%]]+)#") do
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
		local d = notYetKnownTopics[i]
		local lcTopic = string.lower(d.id)
		if (not infoMatchesDict[lcTopic])
		and (not knownTopicsDict[lcTopic]) then
			local lenLcTopic = string.len(lcTopic)
			if lenLcTopic < maxMatchLen then
				for lcMatch, _ in pairs(infoMatchesDict) do
				---mwse.log('%s: processing topic "%s"', modPrefix, lcMatch)
					if (lenLcTopic < string.len(lcMatch))
					and string.find(lcMatch, lcTopic, 1, true) then
						j = j + 1
						t[j] = d
						t2[j] = lcMatch
					end
				end
			else
				break
			end
		end
	end

	for i = 1, #t do
		local d = t[i]
		local knownMatch = t2[i]
		local lcTopic = string.lower(d.id)
		if tes3.addTopic({topic = lcTopic, updateGUI = false}) then
			if logLevel1 then
				local s = string.format('%s: added topic "%s"', modPrefix, lcTopic)
				local from = ''
				if d.sourceMod then
					from = ' (from "' .. d.sourceMod .. '")'
				end
				local ovr = ' overridden by topic "' .. knownMatch .. '"'
				local d2 = knownTopicsDict[knownMatch]
				if d2
				and d2.sourceMod then
					ovr = ovr .. ' (from "' .. d2.sourceMod .. '")'
				end
				s = s .. ovr
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
local tes3_dialogueFilterContext_greeting = tes3.dialogueFilterContext.greeting
local tes3_dialogueFilterContext_clickAnswer = tes3.dialogueFilterContext.clickAnswer

local contextDict = table.invert(tes3.dialogueFilterContext)

local inputController -- set in initialized

local validContext = table.invert({
tes3_dialogueFilterContext_greeting,
tes3_dialogueFilterContext_clickTopic,
tes3_dialogueFilterContext_clickAnswer
})

local fmt1 = [[

%s: dialogueFiltered(e)
dialogue.id = "%s" context = "%s"
actor = "%s" reference = "%s"
reference/leveledBaseReference.sourceMod = "%s"
reference.baseObject.sourceMod = "%s"
info.id = "%s" info.sourceMod = "%s"
info.text = "%s"]]

local function dialogueFiltered(e)
	local context = e.context
	if not validContext[context] then
		return
	end
	---assert(inputController == tes3.worldController.inputController)
	if not logLevel2 then
		if not inputController:isShiftDown() then
			return
		end
	end
	local info = e.info
	local text = info.text
	if not text then
		return
	end
	if string.len(text) <= 0 then
		return
	end
	if (context == tes3_dialogueFilterContext_clickTopic)
	and inputController:isShiftDown()
	and inputController:isControlDown() then
		addMissingTopics(text)
		return
	end
	local actor = e.actor
	local ref = e.reference
	local refSourceMod = ref.sourceMod
	local leveledBaseReference = ref.leveledBaseReference
	if leveledBaseReference
	and (leveledBaseReference.sourceMod) then
		refSourceMod = leveledBaseReference.sourceMod
	end
	local s = string.format(fmt1, modPrefix, e.dialogue.id,
		contextDict[context], actor, ref, refSourceMod, ref.baseObject.sourceMod,
		info.id, info.sourceMod, stripTags(text))
	print(s) -- no mwse.log(s) to avoid problems with format error with %name etc
	os.setClipboardText(s)
end

local fmt2 = [[

%s: infoResponse(e)
dialogue.id = "%s"
reference = "%s"
reference/leveledBaseReference.sourceMod = "%s"
reference.baseObject.sourceMod = "%s"
info.id = "%s" info.sourceMod = "%s"
info.text = "%s"
command = "%s"]]

local function infoResponse(e)
	if not logLevel2 then
		if not inputController:isShiftDown() then
			return
		end
	end
	local info = e.info
	local ref = e.reference
	local s = string.format(fmt2, modPrefix, e.dialogue.id,
	ref.id, ref.sourceMod, ref.baseObject.sourceMod,
		info.id, info.sourceMod, stripTags(info.text), e.command)
	print(s)
	os.setClipboardText(s)
end

local function byId(a, b)
	return string.lower(a.id) < string.lower(b.id)
end

local function byLength(a, b)
	return string.len(a.id) < string.len(b.id)
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

	local playerName = tes3.player.object.name
	if logLevel3 then
		mwse.log('\n%s: "%s" player known topics:', modPrefix, playerName)
	end
	local d_id
	for i = 1, #dialogueList do
		---assert(d.type == tes3_dialogueType_topic)
		local d = dialogueList[i]
		d_id = d.id
		if d_id then
			knownTopicsDict[string.lower(d_id)] = d
		elseif logLevel1 then
			mwse.log('%s: 1. found tes3.mobilePlayer.dialogueList topic with id = "%s" from mod "%s"',
				modPrefix, d_id, d.sourceMod)
		end
		if logLevel3 then
			if d.sourceMod then
				mwse.log('"%s" from "%s"', d.id, d.sourceMod)
			else
				mwse.log('"%s"', d.id)
			end
		end
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
		if d
		and (d.type == tes3_dialogueType_topic) then
			 -- weird, but it seems d.id could be nil
			d_id = d.id
			if d_id then
				if (not knownTopicsDict[string.lower(d_id)]) then
					j = j + 1
					notYetKnownTopics[j] = d
				end
			elseif logLevel1 then
				mwse.log([[%s: 2. WARNING: found tes3.dataHandler.nonDynamicData.dialogues
topic with id = "%s" from mod "%s".
Better clean the mod from the empty topic (you can usually do it from the Construction Set mod details window,
marking the deleted empty topic to be ignored).]],
					modPrefix, d_id, d.sourceMod)
			end
		end
	end

	-- slower, and no need to be conservative on alphabetic order
	--- table.sort(notYetKnownTopics, byLengthAndAlpha)

	-- alphabetic sort first...
	table.sort(notYetKnownTopics, byId)
	-- ... then by length (the important one for early break in addMissingTopics)
	table.sort(notYetKnownTopics, byLength)

	if logLevel3 then
		mwse.log('\n%s: "%s" player not yet known topics:', modPrefix, playerName)
		for i = 1, #notYetKnownTopics do
			local d = notYetKnownTopics[i]
			if d.sourceMod then
				mwse.log('"%s" from "%s"', d.id, d.sourceMod)
			else
				mwse.log('"%s"', d.id)
			end
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
	event.register('infoResponse', infoResponse)
end

local function loaded()
	initOnce()
	initTopics()
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate({name = mcmName})

	template.onClose = function()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage({
		label = 'Info',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 0.7
			self.elements.sideToSideBlock.children[2].widthProportional = 1.3
		end
	})

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = [[Press Shift while clicking a dialog topic/choice to log/paste to clipboard the dialog INFO, hopefully including the sourceMod (name of the mod changing the dialog INFO), something very useful to know in case of dialog conflicts.

Press Shift while activating an actor to log to MWSE.log/paste to clipboard the next dialog greeting INFO triggered by that actor.

Press Ctrl + Shift while clicking a dialog topic to try and add hidden/overridden topics to player known topics list.

If you set the Log Level Full or higher it will log to MWSE.log interesting data from dialogueFiltered() and infoResponse() events without needing the key combos, very useful to debug dialog, just remember to set the Log Level back to Off for normal playing.
]]
})

	local controls = preferences:createCategory({})

	--[[local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end]]

	local optionList = {'Off', 'Low', 'Full', 'Max'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1,
				optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)

event.register('initialized', function ()
	inputController = tes3.worldController.inputController
	event.register('loaded', loaded)
end, {doOnce = true})