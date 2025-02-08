---@diagnostic disable: missing-fields, lowercase-global
--[[
try and fix bad-behaved MWSE-Lua sound replacer mods
and playSound breaking SayDone when playing files
]]

-- begin configurable parameters
local defaultConfig = {
unblockSounds = true,
volumePerc = 75,
fixSayDoneActivators = true,
fixPlayerCreatureSayDone = true,
fixNPCSayDone = true,
blockLoadSave = true,
shortBlockLoadSave = true,
---autoSubtitles = true,
minVoiceoverSize = 50000,
limitSpeechSubtitles = true,
speechSubtitleMaxDist = 160,
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium 3 = High, 4 = Max
}
-- end configurable parameters

local author = 'abot'
local modName = 'WBSR'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)
local unblockSounds, volumeMul, fixSayDoneActivators, fixPlayerCreatureSayDone
local fixNPCSayDone, blockLoadSave, shortBlockLoadSave, minVoiceoverSize
local limitSpeechSubtitles, speechSubtitleMaxDist ---, autoSubtitles
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local worldController -- set in initialized()

local stringToNotNotify

local idMenuNotify_message = tes3ui.registerID('MenuNotify_message')

local function uiActivatedMenuNotify(e)
	if not worldController.showSubtitles then
		return
	end
	local menu = e.element
	local el = menu:findChild(idMenuNotify_message)
	if not el then
		return
	end
	local s = el.text
	if not s then
		return
	end
	if string.len(s) <= 0 then
		return
	end
	---mwse.log('el.id = "%s", el.name = "%s", el.text = "%s"', el.id, el.name, s)
	if not stringToNotNotify then
		return
	end
	if s == stringToNotNotify then
		if logLevel1 then
			mwse.log('%s: uiActivatedMenuNotify() "%s" notify hidden',
				modPrefix, stringToNotNotify)
		end
		stringToNotNotify = nil
		menu.visible = false
		e.claim = true
		menu:destroy()
	end
end

local uiaRegistered = false
local function uiaRegistering()
	local f = event.unregister
	if limitSpeechSubtitles then
		if uiaRegistered then
			return
		end
		f = event.register
		uiaRegistered = true
	else
		if (not uiaRegistered) then
			return
		end
		uiaRegistered = false
	end
	for i = 1, 3 do
		f('uiActivated', uiActivatedMenuNotify, {filter = 'MenuNotify' .. i, priority = 1000})
	end
end

local function updateFromConfig()
	assert(config)
	unblockSounds = config.unblockSounds
	volumeMul = config.volumePerc * 0.01
	fixSayDoneActivators = config.fixSayDoneActivators
	fixPlayerCreatureSayDone = config.fixPlayerCreatureSayDone
	fixNPCSayDone = config.fixNPCSayDone
	blockLoadSave = config.blockLoadSave
	shortBlockLoadSave = config.shortBlockLoadSave
	minVoiceoverSize = config.minVoiceoverSize
	limitSpeechSubtitles = config.limitSpeechSubtitles
	if not (config.limitSpeechSubtitles == limitSpeechSubtitles) then
		limitSpeechSubtitles = config.limitSpeechSubtitles
		uiaRegistering()
	end
	speechSubtitleMaxDist = config.speechSubtitleMaxDist
	---autoSubtitles = config.autoSubtitles
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
end
updateFromConfig()

-- set in loaded()
local player, mobilePlayer

local dataFilesPath = tes3.installDirectory..'\\Data Files\\'

local soundFileSizes = {} -- voiceOver sizes cache, cleared on loaded

local function getSoundFileSize(path)
	local size = soundFileSizes[path]
	if size then
		return size
	end
	if path then
		local fullPath = dataFilesPath .. 'Sound\\' .. path
		size = lfs.attributes(fullPath, 'size')
		if logLevel3 then
			mwse.log('%s: getSoundFileSize("%s") = %s', modPrefix, path, size)
		end
		if not size then
			size = 0
		end
	end
	soundFileSizes[path] = size
	return size
end

local voiceoverSize = 0

---local tes3_dialogueFilterContext_voice = tes3.dialogueFilterContext.voice

local tes3_dialogueType_voice = tes3.dialogueType.voice
local tes3_dialogueType_greeting = tes3.dialogueType.greeting

local lastDialogVoiceRef

local function checkSubtitle(ref, s)
	if not limitSpeechSubtitles then
		return
	end
	if not worldController.showSubtitles then
		return
	end
	if string.len(s) < 3 then
		if logLevel2 then
			mwse.log('%s: checkSubtitle("%s") string.len("%s") < 3, hiding notify',
				modPrefix, ref.id, s)
		end
		stringToNotNotify = s
		return
	end
	local playerDistance = player.position:distance(ref.position)
	if not playerDistance then
		return
	end
	if logLevel3 then
		mwse.log('%s: checkSubtitle("%s") playerDistance = %s',
			modPrefix, ref.id, playerDistance)
	end
	if playerDistance <= speechSubtitleMaxDist then
		return
	end
	if logLevel2 then
		mwse.log('%s: checkSubtitle("%s") playerDistance = %s > speechSubtitleMaxDist = %s, hiding notify',
			modPrefix, ref.id, playerDistance, speechSubtitleMaxDist)
	end
	stringToNotNotify = s
end

local tes3_dialogueFilterContext_voice = tes3.dialogueFilterContext.voice

local function dialogueFiltered(e)
	if not (e.context == tes3_dialogueFilterContext_voice) then
		return
	end
	local s = e.info.text
	if not s then
		return
	end
	local ref = e.reference
	if not ref then
		return
	end
	if ref == lastDialogVoiceRef then
		return
	end
	local len_s = string.len(s)
	if len_s <= 0 then
		return
	end
	local id = e.dialogue.id
	if (id == 'Hello')
	or (id == 'Idle') then
		if len_s > 3 then
			lastDialogVoiceRef = ref
		end
	end
	checkSubtitle(ref, s)
end

---local tes3_dialogueTypeDict = table.invert(tes3.dialogueType)

local function stripTags(s)
	return s:gsub('[@#]', '')
end

---local function replacePercent(s)
	---return s:gsub('%%', '%^'):gsub('%^%^', '%^')
---end

local function stripTagsAndApplyTextDefines(s, actorObj)
	local s2 = stripTags(s)
	if actorObj then
		s2 = tes3.applyTextDefines({text = s2, actor = actorObj})
	end
	return s2
end

local function infoResponse(e)
	local dType = e.dialogue.type
	---mwse.log('>>> e.dialogue.type = %s', tes3_dialogueTypeDict[dType])
	if not (
		(dType == tes3_dialogueType_voice)
		or (dType == tes3_dialogueType_greeting)
	) then
		return
	end
	local ref = e.reference
	if not ref then
		return
	end
	if ref == lastDialogVoiceRef then
		return
	end
	local info = e.info
	local soundPath = info:getSoundPath()
	if soundPath
	and (string.len(soundPath) > 0) then
		lastDialogVoiceRef = ref
		---mwse.log('>>> soundPath = %s', soundPath)
	end
	local cmd = e.command
	---mwse.log('>>> e.command =\n%s', cmd)
	if cmd
	and (string.len(cmd) > 0) then
		local lcCmd = string.lower(cmd)
		local s = string.match(lcCmd,'"?say"?[%s,]-"[^"]+"[%s,]-"([^"]+)"')
		if s then
			if logLevel1 then
				mwse.log('%s: infoResponse() "%s" say "%s"', modPrefix, ref.id, s)
			end
			lastDialogVoiceRef = ref
			---mwse.log('>>> infoResponse() checkSubtitle("%s", "%s")', ref.id, s)
			checkSubtitle(ref, s)
			return
		end
	end

	local s2 = info.text
	if not s2 then
		return
	end
	if string.len(s2) <= 0 then
		return
	end
	if logLevel3 then
		mwse.log('%s: infoResponse() "%s" s2 = "%s"', modPrefix, ref.id, s2)
	end
	local s3 = stripTagsAndApplyTextDefines(s2, ref.object)
	---s3 = replacePercent(s3)
	if logLevel3 then
		mwse.log('%s: infoResponse() "%s" s3 = "%s"', modPrefix, ref.id, s3)
	end
	checkSubtitle(ref, s3)
end

local function getIsVoiceover(e, checkDialog)
	local path = e.path
	local ref = e.reference
	if checkDialog
	and lastDialogVoiceRef then
		if ref == lastDialogVoiceRef then
			lastDialogVoiceRef = nil
			if logLevel3 then
				if e.sound then
					mwse.log('%s: getIsVoiceover() 1 ref = "%s", isVoiceover = %s, sound = "%s"', modPrefix, ref.id, e.isVoiceover, e.sound)
				else
					mwse.log('%s: getIsVoiceover() 1 ref = "%s", path = "%s", isVoiceover = %s', modPrefix, ref.id, path, e.isVoiceover)
				end
			end
			return e.isVoiceover
		end
		lastDialogVoiceRef = nil
	end
	if e.isVoiceover then
		local mob = ref.mobile
		local d = 4096
		if mob
		and mob.playerDistance then
			d = mob.playerDistance
		end
		if logLevel3 then
			if e.sound then
				mwse.log('%s: getIsVoiceover() 2 ref = "%s", isVoiceover = %s, sound = "%s"', modPrefix, ref.id, e.isVoiceover, e.sound)
			else
				mwse.log('%s: getIsVoiceover() 2 ref = "%s", path = "%s", isVoiceover = %s', modPrefix, ref.id, path, e.isVoiceover)
			end
		end
		if d > 3072 then
			return false
		end
		voiceoverSize = getSoundFileSize(path)
		return true
	end
	if not path then
		return false
	end
	if string.len(path) == 0 then
		return false
	end
	if string.find(string.lower(path), '^vo[\\/].+%.[wm][ap][v3]$') then
		if logLevel1 then
			if e.sound then
				mwse.log('%s: getIsVoiceover() 3 ref = "%s", isVoiceover = %s, sound = %s', modPrefix, ref.id, e.isVoiceover, e.sound)
			else
				mwse.log('%s: getIsVoiceover() 3 ref = "%s", path = "%s", isVoiceover = %s', modPrefix, ref.id, path, e.isVoiceover)
			end
		end
		voiceoverSize = getSoundFileSize(path)
		return true
	end
	return false
end

local function addSoundVoiceoverOnly(e)
	if not getIsVoiceover(e) then
		e.block = true
	end
	e.claim = true
end

local function disablePlayerControls()
	if tes3.isCharGenFinished() then
		mobilePlayer.controlsDisabled = true
		---tes3.runLegacyScript({command = 'DisablePlayerControls', source = tes3.compilerSource.console})
	end
end

local function enablePlayerControls()
	if tes3.isCharGenFinished() then
		mobilePlayer.controlsDisabled = false
		---tes3.runLegacyScript({command = 'EnablePlayerControls', source = tes3.compilerSource.console})
	end
end

local processingActivator = false

local reset

local function journal(e)
	e.claim = true
	reset()
end

local function saveBlock()
	return false
end

local function registerSaveBlock()
	if event.isRegistered('save', saveBlock, {priority = 300000}) then
		return
	end
	event.register('save', saveBlock, {priority = 300000})
end

local nonDynamicData
local function enterFrameLS()
	if nonDynamicData.isSavingOrLoading then
		return
	end
	event.unregister('enterFrame', enterFrameLS)
	registerSaveBlock()
end

local function disableSave()
	nonDynamicData = tes3.dataHandler.nonDynamicData
	if nonDynamicData.isSavingOrLoading then
		event.register('enterFrame', enterFrameLS, {priority = 300000})
		return
	end
	registerSaveBlock()
end

local function enableSave()
	if event.isRegistered('save', saveBlock, {priority = 300000}) then
		event.unregister('save', saveBlock, {priority = 300000})
	end
end

--[[
local showSubtitles
local function checkSubtitles()
	if autoSubtitles then
		showSubtitles = tes3.worldController.showSubtitles
		tes3.worldController.showSubtitles = true -- pity, only works from console
	end
end

local function resetSubtitles()
	if showSubtitles == nil then
		return
	end
	if tes3.worldController.showSubtitles == showSubtitles then
		return
	end
	tes3.worldController.showSubtitles = showSubtitles
end
]]

reset = function ()
	processingActivator = false
	event.unregister('journal', journal, {priority = 300000})
	event.unregister('addTempSound', addSoundVoiceoverOnly, {priority = 300000})
	event.unregister('addSound', addSoundVoiceoverOnly, {priority = 300000})
	enableSave()
	enablePlayerControls()
	---resetSubtitles()
end

--[[
local function getLcScriptSource(modName, scriptId)
	local filePath = dataFilesPath..modName
	local f = io.open(filePath, 'rb')
	if not f then
		return
	end
	local text = f:read('*a')
	f:close()
	if not text then
		return
	end
	local s = string.lower(text)
	local pattern = '(begin%s-'..string.lower(scriptId)..'.-end%c)'
	local m = string.match(s, pattern)
	if m then
		return m
	end
end
]]

local cachedSayScripts = {}
local function clearCachedSayScripts()
	cachedSayScripts = {}
end
event.register('loaded', clearCachedSayScripts)

local function isSayScript(script, fromPlayerMouth)
	local scriptId = script.id
	if cachedSayScripts[scriptId] then
		return true
	end
	local sourceMod = script.sourceMod
	if not sourceMod then
		return
	end
	---local s = getLcScriptSource(sourceMod, scriptId)
	local text = script.text
	if not text then
		return
	end
	local s = string.lower(text)
	if fromPlayerMouth then
		if not string.find(s, 'player["%s,]-%->[ ,]*saydone') then
			return
		end
	elseif not string.find(s, 'saydone', 1, true) then
		return
	end
	if not string.find(s, 'onactivate', 1, true) then
		return
	end
	--[[if logLevel3 then
		mwse.log('%s: isSayScript("%s", %s) script source detected',
			modPrefix, scriptId, fromPlayerMouth)
	end]]
	local jourId, jourIndex = string.match(s,
		[[journal[%s,]+"?([^%c,"]+)"?[%s,]+(%d+)]])
	if not jourId then
		return
	end
	if not jourIndex then
		return
	end
	jourIndex = tonumber(jourIndex)
	if not jourIndex then
		return
	end
	if logLevel2 then
		mwse.log('%s: isSayScript("%s", %s) sourceMod = %s, Journal "%s" %s',
			modPrefix, scriptId, fromPlayerMouth, sourceMod, jourId, jourIndex)
	end
	if tes3.getJournalIndex({id = jourId}) >= jourIndex then
		if logLevel1 then
			mwse.log('%s: isSayScript("%s", %s) sourceMod = "%s", Journal "%s" %s',
				modPrefix, scriptId, fromPlayerMouth, sourceMod, jourId, jourIndex)
		end
		if logLevel1 then
			mwse.log('%s: isSayScript("%s", %s) sourceMod = "%s", GeTJournalIndex "%s" >= %s, skip',
				modPrefix, scriptId, fromPlayerMouth, sourceMod, jourId, jourIndex)
		end
		return
	end
	cachedSayScripts[scriptId] = true
	return true
end

local tes3_objectType_activator = tes3.objectType.activator

local function activate(e)
	if not fixSayDoneActivators then
		return
	end
	if not (e.activator == player) then
		return
	end
	local ref = e.target
	local obj = ref.baseObject
	if not (obj.objectType == tes3_objectType_activator) then
		return
	end
	local script = obj.script
	if not script then
		return
	end
	if not isSayScript(script, true) then
		return
	end
	local data = ref.data
	if not ref.data then
		ref.data = {}
		data = ref.data
	end
	if data.ab01wbsr then
		return -- process activate only once
	end
	data.ab01wbsr = 1
	ref.modified = true
	if logLevel1 then
		mwse.log('%s: player activate("%s") activator saydone + onactivate + journal script detected',
			modPrefix, ref.id, script.id)
	end
	e.claim = true
	if tes3.is3rdPerson() then
		tes3.force1stPerson()
	end
	---checkSubtitles()
	disablePlayerControls()
	processingActivator = true
	event.register('addTempSound', addSoundVoiceoverOnly, {priority = 300000})
	event.register('addSound', addSoundVoiceoverOnly, {priority = 300000})
	event.register('journal', journal, {priority = 300000})
	if blockLoadSave then
		disableSave()
	end
end

local voiceoverRef

local function sayDone()
	if not voiceoverRef then
		return true
	end
	local mob = voiceoverRef.mobile
	if not mob then
		return true
	end
	local animationController = mob.animationController
	if not animationController then
		return true
	end
	local animationData = animationController.animationData
	if not animationData then
		return true
	end
	local lipsyncLevel = animationData.lipsyncLevel
	if not lipsyncLevel then
		return true
	end
	if logLevel4 then
		mwse.log('%s: sayDone() voiceoverRef = "%s", lipsyncLevel = %s',
			modPrefix, voiceoverRef.id, lipsyncLevel)
	end
	return (lipsyncLevel < 0)
end

local enterFrameRegistered = false

local function enterFrame()
	if processingActivator then
		return
	end
	if sayDone() then
		enableSave()
		enterFrameRegistered = false
		event.unregister('enterFrame', enterFrame)
		---resetSubtitles()
		voiceoverRef = nil
	end
end

--[[
---@diagnostic disable-next-line: lowercase-global
ab01cachedInfoText = {} -- shared global variable on purpose
local function clearCachedInfoText()
	table.clear(ab01cachedInfoText)
end

local function loadCachedOriginalText(e)
	local id = e.info.id
	local s = ab01cachedInfoText[id]
	if s then
		return s
	end
	-- caching the fucking thing as it is crashy if you call it
	-- from different mods, same (infoGetText) event
	local s2 = e:loadOriginalText()
	ab01cachedInfoText[id] = s2
	return s2
end

local function getActorText(s)
	local actorObj
	local mob = tes3ui.getServiceActor()
	if mob then
		actorObj = mob.reference.object
	end
	return stripTagsAndApplyTextDefines(s, actorObj)
end

local function getProcessedText(e)
	local s = loadCachedOriginalText(e)
	return getActorText(s)
end

local function delayedInfoGetText(e)
	local info = e.info
	if not (info.type == tes3_dialogueType_voice) then
		return
	end
	local soundPath = info:getSoundPath()
	if not soundPath then
		return
	end
	if string.len(soundPath) <= 0 then
		return
	end
	local info_actor = info.actor
	if not info_actor then
		return
	end
	local ref = tes3.getReference(info_actor.id)
	if not ref then
		return
	end
	local mob = tes3ui.getServiceActor()
	if not mob then
		return
	end
	if not (ref == lastDialogVoiceRef) then
		lastDialogVoiceRef = ref
	end
	if not worldController.showSubtitles then
		return
	end
	local s = getProcessedText(e)
	if not s then
		return
	end
	if string.len(s) <= 0 then
		return
	end
	if logLevel4 then
		mwse.log('%s: delayedInfoGetText() text = "%s"', modPrefix, s)
	end
	checkSubtitle(ref, s)
end

local function infoGetText(e)
	local info = e.info
	if not (info.type == tes3_dialogueType_voice) then
		return
	end
	local soundPath = info:getSoundPath()
	if not soundPath then
		return
	end
	-- if string.len(soundPath) <= 0 then
		-- assert(false)
		-- return
	-- end
	-- local info_actor = info.actor
	-- if not info_actor then
		-- return
	-- end
	-- local ref = tes3.getReference(info_actor.id)
	-- if not ref then
		-- return
	-- end
	if logLevel4 then
		mwse.log('%s: infoGetText() soundPath = "%s"', modPrefix, soundPath)
	end
	if not (ref == lastDialogVoiceRef) then
		lastDialogVoiceRef = ref
	end
	timer.frame.delayOneFrame(
		function () delayedInfoGetText(e) end
	)
end
]]

local tes3_actorType_npc = tes3.actorType.npc

local function addTempSoundHP(e)
	local ref = e.reference
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	local actorType = mob.actorType
	if not actorType then
		return
	end
	local fixSayDone = true
	if actorType == tes3_actorType_npc then
		if not fixNPCSayDone then
			fixSayDone = false
		end
	elseif not fixPlayerCreatureSayDone then
		fixSayDone = false
	end

	local refIsPlayingVoiceover = false
	if voiceoverRef
	and (ref == voiceoverRef) then
		refIsPlayingVoiceover = true
		if fixSayDone then
			e.claim = true
		end
	end
	if not getIsVoiceover(e, true) then
		if refIsPlayingVoiceover then
			if fixSayDone then
				e.block = true
			end
		end
		return
	end
	if processingActivator then
		return
	end
	if voiceoverRef then
		return
	end
	if logLevel3 then
		if e.sound then
			mwse.log('%s: addTempSoundHP() ref = "%s", sound = "%s", isVoiceover = %s', modPrefix, ref.id, e.sound, e.isVoiceover)
		else
			mwse.log('%s: addTempSoundHP() ref = "%s", path = "%s", isVoiceover = %s', modPrefix, ref.id, e.path, e.isVoiceover)
		end
	end
	if voiceoverSize < minVoiceoverSize then
		return
	end
	voiceoverRef = ref
	---checkSubtitles()
	if shortBlockLoadSave then
		disableSave()
	end
	if enterFrameRegistered then
		return
	end
	enterFrameRegistered = true
	event.register('enterFrame', enterFrame)
end

local function addTempSoundLP(e)
	if not unblockSounds then
		return
	end
	if not e.block then
		return
	end
	local ref = e.reference
	if not ref then
		return
	end
	local path = e.path

	if e.volume <= 0 then
		if logLevel3 then
			mwse.log('%s: addTempSoundLP() ref = "%s", path = "%s" volume <= 0 unblocked',
				modPrefix, ref.id, path)
		end
		e.block = false
		return
	end

	if not path then
		return
	end
	if string.len(path) <= 0 then
		return
	end

	local prefix = string.match(path, "^([^\\/]+)[\\/]")
	if not prefix then
		return
	end
	local lcPrefix = string.lower(prefix)
	if string.find(lcPrefix, '4nm', 1, true) then
		if logLevel2 then
			mwse.log('%s: addTempSoundLP() ref = "%s", path = "%s" unblocked',
				modPrefix, ref.id, path)
		end
		e.block = false
		return
	end
	if string.multifind(lcPrefix, {'anu', 'tew'}, 1, true) then
		if logLevel3 then
			mwse.log('%s: addTempSoundLP() ref = "%s", path = "%s" unblocked',
				modPrefix, ref.id, path)
		end
		e.block = false
	end
end

local function getNewVolume(volume)
	return math.floor(volume * volumeMul + 0.5)
end

local function addSoundLP(e)
	if not e.block then
		return
	end
	if not unblockSounds then
		return
	end
	local ref = e.reference
	if not ref then
		return
	end
	if e.volume <= 0 then
		if logLevel4 then
			mwse.log('%s: addSoundLP() "%s" "%s" volume <= 0 unblocked',
				modPrefix, ref.id, e.sound.id)
		end
		e.block = false
		return
	end
	if not getIsVoiceover(e) then
		local volume = getNewVolume(e.volume)
		if e.volume > volume then
			if logLevel4 then
				mwse.log(
'%s: addSoundLP() "%s" "%s" "%s" unblocked volume before: %s, after: %s (%s%%)',
					modPrefix, ref.id, e.sound.id, e.sound.filename,
					e.volume, volume, config.volumePerc)
			end
			e.volume = volume
		end
	end
	e.block = false
end


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate({name = mcmName})
	local info = [[WBSR (Well Behaved Sound Replacers).

Try and fix bad-behaved MWSE-Lua sound replacer mods and playSound breaking SayDone when playing files.

Please read the readme for more details.]]
	-- Preferences Page
	local preferences = template:createSideBarPage({
		label = 'Info',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = info})

	local controls = preferences:createCategory({})

	--[[local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end]]

	template.onClose = function()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createYesNoButton({
		label = 'Unblock sounds',
		description = getYesNoDescription([[Default: %s.
Unblock sounds, lowering their sound volume instead so they are still detectable.]], 'unblockSounds'),
		variable = createConfigVariable('unblockSounds')
	})

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	controls:createYesNoButton({
		label = 'Fix speech activators SayDone',
		description = getYesNoDescription([[Default: %s.
When player activates some activator object having a local script attached using the Saydone + Activate + Journal command (e.g. Azura shrine statue) triggering a long speech, blocks player from acting while the speech is going.]], 'fixSayDoneActivators'),
		variable = createConfigVariable('fixSayDoneActivators')
	})

	controls:createYesNoButton({
		label = 'Fix player/creature SayDone',
		description = getYesNoDescription([[Default: %s.
Try to detect player (e.g. daedra shrines statues/creatures e.g. Almalexia) long speeches and allow only them to play while blocking the other kind of sound replacements until the speech is done.]], 'fixPlayerCreatureSayDone'),
		variable = createConfigVariable('fixPlayerCreatureSayDone')
	})

	controls:createYesNoButton({
		label = 'Fix NPCs SayDone',
		description = getYesNoDescription([[Default: %s.
Try to detect generic NPCs speeches and allow only them to play while blocking the other kind of sound replacements until the speech is done.
This is the first option you should try to disable if you are having problems while some NPC is talking.]], 'fixNPCSayDone'),
		variable = createConfigVariable('fixNPCSayDone')
	})

	controls:createYesNoButton({
		label = 'Block saving while speech is playing',
		description = getYesNoDescription([[Default: %s.
Keeping this enabled is the suggested/default option, but if it really bothers you]]
.." the chance of overlapping speech on reload disabling this option should still be low,"
.." although speeches not starting from a detectable activator (e.g. Almalexia pre battle speech)"
.." could still overlap on reload if this is disabled.", 'shortBlockLoadSave'),
		variable = createConfigVariable('shortBlockLoadSave')
	})

	controls:createYesNoButton({
		label = 'Block saving while activated multipart speech is playing',
		description = getYesNoDescription([[Default: %s.
Keeping this enabled is the suggested/default option.
Pros: should help avoiding overlapping on reload for long speeches you get e.g. from activating daedra shrines.
Cons: if you are a quicksave maniac you will suffer because you cannot save while the long speech is going.
]], 'blockLoadSave'),
		variable = createConfigVariable('blockLoadSave')
	})

	controls:createYesNoButton({
		label = 'Limit speech subtitles',
		description = getYesNoDescription([[Default: %s.
Toggle limiting speech subtitles by distance from player
(subtitles with length < 3 will be hidden by default).
Max distance is tweakable by the slider below.]], 'limitSpeechSubtitles'),
		variable = createConfigVariable('limitSpeechSubtitles')
	})

	controls:createSlider({
		label = 'Speech subtitle max distance %s',
		description = getDescription([[Default: %s.
Max distance from player to display subtitles for an actor speech.
Effective only with "Limit speech subtitles" option active.]], 'speechSubtitleMaxDist'),
		variable = createConfigVariable('speechSubtitleMaxDist')
		,min = 0, max = 3072, step = 1, jump = 5
	})

	controls:createSlider({
		label = 'Replaced Sound Volume Multiplier %s%%',
		description = getDescription([[Default: %s.
Percentual multiplier for replced sounds volume.]], 'volumePerc'),
		variable = createConfigVariable('volumePerc')
		,min = 5, max = 100, step = 1, jump = 5
	})

	controls:createSlider({
		label = 'Min Voiceover Size %s',
		description = getDescription([[Default: %s.
Minimum size of a sound file to be processed as voiceover.]], 'minVoiceoverSize'),
		variable = createConfigVariable('minVoiceoverSize')
		,min = 20000, max = 100000, step = 1, jump = 10
	})

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Max'}
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

local function cellChanged()
	voiceoverRef = nil
	---clearCachedInfoText()
end

local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	---event.register('infoGetText', infoGetText)
	event.register('dialogueFiltered', dialogueFiltered)
	event.register('postInfoResponse', infoResponse)
	event.register('addTempSound', addTempSoundHP, {priority = 200000})
	event.register('addTempSound', addTempSoundLP, {priority = -200000})
	event.register('addSound', addSoundLP, {priority = -200000})
	event.register('activate', activate, {priority = 300000})
	event.register('cellChanged', cellChanged)
	uiaRegistering()
end


local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	if enterFrameRegistered then
		enterFrameRegistered = false
		event.unregister('enterFrame', enterFrame)
	end
	enableSave()
	---resetSubtitles()
	---mwse.log('loaded() voiceoverRef = nil')
	voiceoverRef = nil -- important!
	soundFileSizes = {}
	initOnce()
end

event.register('initialized',
function ()
	worldController = tes3.worldController
	event.register('loaded', loaded)
end, {doOnce = true})