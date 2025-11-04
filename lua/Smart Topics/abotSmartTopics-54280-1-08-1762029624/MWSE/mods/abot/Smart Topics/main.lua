--[[
Press Shift while clicking a dialog topic/choice to log/paste to clipboard
the dialog INFO, hopefully including the sourceMod (name of the mod changing
the dialog INFO), something very useful to know in case of dialog conflicts.

Press Shift while activating an actor to log to MWSE.log/paste to clipboard the
next dialog greeting INFO triggered by that actor.

Press Ctrl + Shift while clicking a dialog topic to try and add
hidden/overridden topics to player known topics list.
]]

local voices = {'Hello','Idle','Intruder','Thief','Hit','Attack','Flee'}

local defaultConfig = {
logHello = true,
logIdle = true,
logIntruder = false,
logThief = false,
logHit = false,
logAttack = false,
logFlee = false,
playerTargetVoicesOnly = true,
modDisabled = false,
logLevel = 0,
}

local author = 'abot'
local modName = 'Smart Topics'
local modPrefix = author..'\\'..modName
local configName = author..modName
configName = configName:gsub(' ', '_')
local mcmName = author.."'s "..modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config) -- just to avoid Lua diagnostic complains

-- refreshed in modConfigReady()
local logVoicesDict = {}
local playerTargetVoicesOnly, modDisabled
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4, logLevel5

local function updateFromConfig()
	for _, v in ipairs(voices) do
		logVoicesDict[v] = config['log'..v]
	end
	playerTargetVoicesOnly = config.playerTargetVoicesOnly
	modDisabled = config.modDisabled
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	logLevel5 = logLevel >= 5
end
updateFromConfig()

local string_format = string.format

local tes3_dialogueType_topic = tes3.dialogueType.topic
---local tes3_dialogueType_greeting = tes3.dialogueType.greeting

-- set in loaded
local notYetKnownTopics = {}
local knownTopicsDict = {}

local function topicAdded(e)
	local d = e.topic
	knownTopicsDict[d.id:lower()] = d
end

---@param s string
local function stripTags(s)
	return s:gsub('[@#]', '')
end

---@param text string
local function addMissingTopics(text)
	--[[
	local etime
	if logLevel3 then
		etime = os.clock()
	end
	]]
	local lcText = text:lower()
	local maxMatchLen = 0
	local infoMatchesDict = {}
	for lcMatch in lcText:gmatch("@([%w%[%]]+)#") do
		infoMatchesDict[lcMatch] = true
		local matchLen = lcMatch:len()
		if matchLen > maxMatchLen then
			maxMatchLen = matchLen
		end
	end
	local t = {}
	local t2 = {}
	local j = 0
	for i = 1, #notYetKnownTopics do
		local d = notYetKnownTopics[i]
		local lcTopic = d.id:lower()
		if (not infoMatchesDict[lcTopic])
		and (not knownTopicsDict[lcTopic]) then
			local lenLcTopic = lcTopic:len()
			if lenLcTopic < maxMatchLen then
				for lcMatch, _ in pairs(infoMatchesDict) do
				---mwse.log('%s: processing topic "%s"', modPrefix, lcMatch)
					if (lenLcTopic < lcMatch:len())
					and lcMatch:find(lcTopic, 1, true) then
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

	local t3 = {}
	for i = 1, #t do
		local d = t[i]
		local knownMatch = t2[i]
		local lcTopic = d.id:lower()
		if tes3.addTopic({topic = lcTopic, updateGUI = false}) then
			t3[#t3 + 1] = modPrefix..': added topic "'..lcTopic..'"'
			if d.sourceMod then
				t3[#t3 + 1] = ' (from "'..d.sourceMod..'")'
			end
			t3[#t3 + 1] = ' overridden by topic "'..knownMatch..'"'
			local d2 = knownTopicsDict[knownMatch]
			if d2
			and d2.sourceMod then
				t3[#t3 + 1] = ' (from "'..d2.sourceMod..'")'
			end
			t3[#t3 + 1] = '\r\n'
		end
	end
	if #t3 > 0 then
		print(table.concat(t3)..'\r\n')
	else
		mwse.log('%s: addMissingTopics() no missing topics found.', modPrefix)
	end
	--[[
	if logLevel3 then
		mwse.log('%s: addMissingTopics() elapsed time: %.4f', modPrefix, os.clock() - etime)
	end
	]]
end

local tes3_dialogueFilterContext_clickTopic = tes3.dialogueFilterContext.clickTopic
local tes3_dialogueFilterContext_greeting = tes3.dialogueFilterContext.greeting
local tes3_dialogueFilterContext_clickAnswer = tes3.dialogueFilterContext.clickAnswer

local tes3_dialogueFilterContext_voice = tes3.dialogueFilterContext.voice

local contextDict = table.invert(tes3.dialogueFilterContext)

-- set in initialized
local inputController

local validContext = table.invert({
tes3_dialogueFilterContext_greeting,
tes3_dialogueFilterContext_clickTopic,
tes3_dialogueFilterContext_clickAnswer,
tes3_dialogueFilterContext_voice
})

---@param s string|nil
---@return string|nil
local function quoted(s)
	if s then
		return '"'..s..'"'
	end
	return s
end

-- info text/command cache
local texts = {}

local function clearTexts()
	for k, v in pairs(texts) do
		v.t, v.i = nil, nil
		texts[k] = nil
	end
	texts = {}
end

local fmt1 = [[
%s: %s(e)
dialogue.id = "%s"
reference = "%s"
reference/leveledBaseReference.sourceMod = %s
reference.baseObject.sourceMod = "%s"
info.id = "%s" info.sourceMod = "%s"
]]

---@param e dialogueFilteredEventData|infoResponseEventData|infoFilterEventData
local function logInfo(e)
	local ref = e.reference
	local refSourceMod = ref.sourceMod
	local leveledBaseReference = ref['leveledBaseReference']
	if leveledBaseReference
	and (leveledBaseReference.sourceMod) then
		refSourceMod = leveledBaseReference.sourceMod
	end

	local info = e.info
	local actor = info.actor
	local info_id = info.id
	local soundPath = info:getSoundPath()
	local command = e.command
	local text
	local ct = texts[info_id]
	if ct then
		text = ct.t
	elseif (not command) then
		-- accessing the fucked info.text field sometimes may screw
		-- the dialog result/command script execution
		-- cache it when possible to read it safely
		text = info.text
		texts[info_id] = {t = text, i = 1}
		if logLevel5 then
			mwse.log('%s: >>> texts["%s"] = {t = "%s", i = 1}',
				modPrefix, info_id, text)
		end
	end
	local t = {}
	t[#t + 1] = string_format(fmt1, modPrefix, e['eventType'],
		e.dialogue.id,
		ref.id,
		quoted(refSourceMod), quoted(ref.baseObject.sourceMod),
		info_id, info.sourceMod)

	if actor then
		t[#t + 1] = 'e.actor = "'..actor.id..'"\r\n'
	end
	if e.context then
		t[#t + 1] = 'e.context = "'..contextDict[e.context]..'"\r\n'
	end
	if text then
		t[#t + 1] = 'info.text = {\r\n'..stripTags(text)..'\r\n}\r\n'
	end
	if command then
		t[#t + 1] = 'info.command = {\r\n'..command..'\r\n}\r\n'
	end
	if text
	and ct then
		if ct.i >= 6 then
			-- clear the cached text after a while
			ct.t, ct.i = nil, nil
			texts[info_id] = nil
		else
			ct.i = ct.i + 1
		end
	end
	if soundPath then
		t[#t + 1] = 'info.soundPath = "'..soundPath..'"'
	end
	local s = table.concat(t)

	print(s)
	os.setClipboardText(s)
end

local tes3_dialogueType_journal = tes3.dialogueType.journal

---@param e dialogueFilteredEventData
local function dialogueFiltered(e)
	if modDisabled then
		return
	end
	if e.info.type == tes3_dialogueType_journal then
		return -- no sound, no result, no need to patch
	end
	local context = e.context
	local isShiftDown = inputController:isShiftDown()
	if (context == tes3_dialogueFilterContext_clickTopic)
	and isShiftDown
	and inputController:isControlDown() then
		local text = e.info.text
		if text
		and (text:len() > 0) then
			addMissingTopics(text)
			return
		end
	end
	local ref = e.reference
	local isVoice = (context == tes3_dialogueFilterContext_voice)
	if isVoice then
		if not logVoicesDict[e.dialogue.id] then
			return
		end
		if playerTargetVoicesOnly then
			local playerTarget = tes3.getPlayerTarget()
			if not playerTarget then
				return
			end
			if not ref then
				return
			end
			if not (ref == playerTarget) then
				return
			end
		end
	else
		if not validContext[context] then
			return
		end
		if (not logLevel3)
		and ( not isShiftDown ) then
			return
		end
	end
	logInfo(e)
end

---@param e infoResponseEventData
local function infoResponse(e)
	if modDisabled then
		return
	end
	if not logLevel3 then
		---assert(inputController == tes3.worldController.inputController)
		if not inputController:isShiftDown() then
			return
		end
	end
	logInfo(e)
end

--[[
---@param e infoFilterEventData
local function infoFilter(e)
	if not e.passes then
		return
	end
	if modDisabled then
		return
	end
	local dialogue = e.dialogue
	if not dialogue then
		return
	end
	if not logVoicesDict[dialogue.id] then
		return
	end
	local ref = e.reference
	if playerTargetVoicesOnly then
		local playerTarget = tes3.getPlayerTarget()
		if not playerTarget then
			return
		end
		if not ref then
			return
		end
		if not (ref == playerTarget) then
			return
		end
	end
	logInfo(e)
end
]]


local function byId(a, b)
	return a.id:lower() < b.id:lower()
end

local function byLength(a, b)
	return a.id:len() < b.id:len()
end

--[[ -- slower
local fmt = "%04d%s"
local function byLengthAndAlpha(a, b)
	return string_format(fmt, a:len(), a) < string_format(fmt, b:len(), b)
end
]]

local function initTopics()
	if modDisabled then
		return
	end
	local etime
	if logLevel3 then
		etime = os.clock()
	end

	for k, _ in pairs(knownTopicsDict) do
		knownTopicsDict[k] = nil
	end
	knownTopicsDict = {}

	local dialogueList = tes3.mobilePlayer.dialogueList

	local playerName = tes3.player.object.name
	local t = {}
	if logLevel4 then
		t[#t + 1] = '\r\n'..modPrefix..': "'..playerName..'" player known topics:\r\n'
	end
	local d_id
	for i = 1, #dialogueList do
		---assert(d.type == tes3_dialogueType_topic)
		local d = dialogueList[i]
		d_id = d.id
		if d_id then
			knownTopicsDict[d_id:lower()] = d
		elseif logLevel4 then
			t[#t + 1] = modPrefix..': 1. found tes3.mobilePlayer.dialogueList topic with id = "'
				..d_id..'" from mod "'..d.sourceMod..'"\r\n'
		end
		if logLevel4 then
			if d.sourceMod then
				t[#t + 1] = '"'..d.id..'" from "'..d.sourceMod..'"\r\n'
			else
				t[#t + 1] = '"'..d.id..'"\r\n'
			end
		end
	end

	for k, _ in pairs(notYetKnownTopics) do
		notYetKnownTopics[k] = nil
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
				if (not knownTopicsDict[d_id:lower()]) then
					j = j + 1
					notYetKnownTopics[j] = d
				end
			elseif logLevel3 then
				t[#t + 1] =
modPrefix..[[: 2. WARNING: found tes3.dataHandler.nonDynamicData.dialogues topic
with id = "]]..d_id..'" from mod "'..d.sourceMod..[[".
Better clean the mod from the empty topic (you can usually do it from the Construction Set mod details window,
marking the deleted empty topic to be ignored).
]]
			end
		end
	end

	-- slower, and no need to be conservative on alphabetic order
	--- table.sort(notYetKnownTopics, byLengthAndAlpha)

	-- alphabetic sort first...
	table.sort(notYetKnownTopics, byId)
	-- ... then by length (the important one for early break in addMissingTopics)
	table.sort(notYetKnownTopics, byLength)

	if logLevel4 then
		t[#t + 1] = '\r\n'..modPrefix..': "'..playerName..'" player not yet known topics:\r\n'
		for i = 1, #notYetKnownTopics do
			local d = notYetKnownTopics[i]
			if d.sourceMod then
				t[#t + 1] = '"'..d.id..'" from "'..d.sourceMod..'"\r\n'
			else
				t[#t + 1] = '"'..d.id..'"\r\n'
			end
		end
	end

	if logLevel3 then
		t[#t + 1] = string_format('%s: initTopics() elapsed time: %.4f\r\n', modPrefix, os.clock() - etime)
	end

	mwse.log(table.concat(t))
end

local function cellChanged()
	clearTexts() -- clear the cached info.text table
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
	event.register('cellChanged', cellChanged)
	---event.register('infoFilter', infoFilter)
end

local function loaded()
	assert(inputController == tes3.worldController.inputController)
	initOnce()
	initTopics()
end


local function modConfigReady()

	local function onClose()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = true})
	end

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		label = modName,
		showHeader = false,
		description = [[Press Shift while clicking a dialog topic/choice to log/paste to clipboard the dialog INFO, hopefully including the sourceMod (name of the mod changing the dialog INFO), something very useful to know in case of dialog conflicts.

Press Shift while activating an actor to log to MWSE.log/paste to clipboard the next dialog greeting/voice INFO triggered by that actor.

You can selectively enable the logging of dialog voices for the currently pointed actor.

Note that having the "Log only current player target voices" option disabled could spam the log in crowded places so better disable it during normal gameplay/when the information is not needed.

Also you set the Log Level 3 or higher it should log some data without needing the key combos, useful to debug dialog, just remember to set the Log level back for normal playing.

If you think you are blocked in some quest because you can't find the proper highlighted
topic to click and progress, you can try using the Ctrl + Shift + click a dialog topic option to try and add hidden/overridden topics to player known topics list.

Don't use this option liberally/without reason/without a previous save backup though, as you could make available
early some topic that was not meant to be available until a certain quest stage, potentially causing opposite problems.]],
		showReset = true,
		postCreate = function(self)
			self.elements.sideToSideBlock.children[1].widthProportional = 0.7
			self.elements.sideToSideBlock.children[2].widthProportional = 1.3
		end
	})

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Very High', 'Max'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = ('%s. %s'):format(i - 1,
				optionList[i]), value = i - 1}
		end
		return options
	end

--[[
tes3.voices hello 0, idle 1, intruder 2, thief 3, hit 4, attack	5, flee	6
voices 1 Hello, 2 Idle, 3 Intruder, 4 Thief, 5 Hit 4 6 Attack 7 Flee
]]
	for _, v in ipairs(voices) do
		sideBarPage:createYesNoButton({
			label = 'Log '..v..' voice',
			description = 'Log the pointed actor '..v..' voice INFO.',
			configKey = 'log'..v
		})
	end

	sideBarPage:createYesNoButton({
		label = 'Log only current player target voices',
		description = [[Log only voices INFO from the current actor pointed/targeted by player.
Disabling this could log also dialog voices not coming from the currently pointed actor (the one under the cursor).
Note that disabling this option could spam the log in crowded places where several actors could say their Hello lines at the same time.]],
		configKey = 'playerTargetVoicesOnly'
	})

	sideBarPage:createYesNoButton({
		label = 'Disable mod',
		description = [[Toggle for mod effects. Requires reloading a saved game to be effective.]],
		configKey = 'modDisabled'
	})

	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady, {doOnce = true})


event.register('initialized', function ()
	inputController = tes3.worldController.inputController
	event.register('loaded', loaded)
end, {doOnce = true})