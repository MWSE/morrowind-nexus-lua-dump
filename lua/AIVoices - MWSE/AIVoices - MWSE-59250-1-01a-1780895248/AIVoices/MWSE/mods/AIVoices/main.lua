--==================
-- REQUIREMENTS
--==================

local defaultConfig = require("AIVoices.config")
local config = mwse.loadConfig("AIVoices", defaultConfig)

local function migrateBackendPath(path)
	if type(path) ~= "string" then
		return path
	end

	path = path:gsub([[^Data Files\MWSE\mods\AIVoices\]], [[Data Files\AIVoicesBackend\]])

	return path
end

local function applyConfigDefaults()
	config.outputPath = migrateBackendPath(config.outputPath)
	config.voiceOutputPath = migrateBackendPath(config.voiceOutputPath)
	config.stopOutputPath = migrateBackendPath(config.stopOutputPath)
	config.statusOutputPath = migrateBackendPath(config.statusOutputPath)
	config.pronunciationMapPath = migrateBackendPath(config.pronunciationMapPath)
	config.pythonCommand = migrateBackendPath(config.pythonCommand)
	config.watcherHeartbeatPath = migrateBackendPath(config.watcherHeartbeatPath)
	config.heartbeatPath = migrateBackendPath(config.heartbeatPath)
	config.installerMarkerPath = migrateBackendPath(config.installerMarkerPath)
	config.ttsEngineOutputPath = migrateBackendPath(config.ttsEngineOutputPath)
	config.xttsReferenceMapPath = migrateBackendPath(config.xttsReferenceMapPath)
	config.xttsSettingsPath = migrateBackendPath(config.xttsSettingsPath)
	config.piperVoiceMapPath = migrateBackendPath(config.piperVoiceMapPath)
	config.piperSettingsPath = migrateBackendPath(config.piperSettingsPath)
	config.elevenLabsApiKeyOutputPath = migrateBackendPath(config.elevenLabsApiKeyOutputPath)
	config.elevenLabsVoiceMapPath = migrateBackendPath(config.elevenLabsVoiceMapPath)
	config.elevenLabsModelIdOutputPath = migrateBackendPath(config.elevenLabsModelIdOutputPath)
	config.elevenLabsOutputFormatPath = migrateBackendPath(config.elevenLabsOutputFormatPath)
	config.elevenLabsSettingsPath = migrateBackendPath(config.elevenLabsSettingsPath)
	config.voiceVolumeOutputPath = migrateBackendPath(config.voiceVolumeOutputPath)


	config.voiceVolumeOutputPath = config.voiceVolumeOutputPath or [[Data Files\AIVoicesBackend\settings\voice_volume.txt]]
	config.xttsReferenceMapPath = config.xttsReferenceMapPath or [[Data Files\AIVoicesBackend\XTTS\xtts_reference_map.txt]]
	config.xttsSettingsPath = config.xttsSettingsPath or [[Data Files\AIVoicesBackend\settings\xtts_settings.txt]]
	config.piperVoiceMapPath = config.piperVoiceMapPath or [[Data Files\AIVoicesBackend\Piper\piper_voice_map.txt]]
	config.piperSettingsPath = config.piperSettingsPath or [[Data Files\AIVoicesBackend\Piper\piper_settings.txt]]
	config.elevenLabsVoiceMapPath = config.elevenLabsVoiceMapPath or [[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_voice_map.txt]]
    config.watcherHeartbeatPath = config.watcherHeartbeatPath or [[Data Files\AIVoicesBackend\runtime\watcher_heartbeat.txt]]
	config.speechSpeedOutputPath = config.speechSpeedOutputPath or [[Data Files\AIVoicesBackend\settings\speech_speed.txt]]

	
    config.xttsTemperature = config.xttsTemperature or 0.65
    config.xttsRepetitionPenalty = config.xttsRepetitionPenalty or 2.0
    if config.xttsTopK == nil then config.xttsTopK = 50 end
    config.xttsTopP = config.xttsTopP or 0.85
	if config.speechSpeed == nil then config.speechSpeed = 1.00 end

	
	if config.voiceVolume == nil then config.voiceVolume = 50 end

	if config.xttsGeneratedCacheMaxMb == nil then config.xttsGeneratedCacheMaxMb = 500 end
	
	if config.xttsCacheGeneratedLines == nil then
		config.xttsCacheGeneratedLines = false
	end

	if config.piperCacheGeneratedLines == nil then
		config.piperCacheGeneratedLines = false
	end

	if config.piperGeneratedCacheMaxMb == nil then
		config.piperGeneratedCacheMaxMb = 500
	end

	if config.piperNoiseScale == nil then
		config.piperNoiseScale = 0.667
	end

	if config.piperNoiseWScale == nil then
		config.piperNoiseWScale = 0.333
	end

	if config.piperSentenceSilence == nil then
		config.piperSentenceSilence = 0.20
	end

	if config.elevenLabsCacheGeneratedLines == nil then
		config.elevenLabsCacheGeneratedLines = true
	end

	if config.elevenLabsGeneratedCacheMaxMb == nil then
		config.elevenLabsGeneratedCacheMaxMb = 500
	end



	if config.voiceVolume < 0 then
		config.voiceVolume = 0
	end

	if config.voiceVolume > 100 then
		config.voiceVolume = 100
	end

end

applyConfigDefaults()

local function reloadConfig()
	config = mwse.loadConfig("AIVoices", defaultConfig)
	applyConfigDefaults()
end




--==================
-- MOD INFO
--==================

local modName = "AI Voices"


--==================
-- FORWARD DECLARATIONS
--==================

local updateMenuStopState
local updateWatcherStatus
local getCurrentDialogueActor

--==================
-- MESSAGE HELPERS
--==================

local function debugLog(message)
	if config.debugLog then
		mwse.log("[%s] %s", modName, tostring(message))
	end
end

local function showMessage(message)
	if config.showMessages then
		tes3.messageBox(tostring(message))
	end
end

--==================
-- FILE HELPERS
--==================
local ensureParentDirectoryForFile
local function fileExists(path)
	if not path or path == "" then
		return false
	end

	local file = io.open(path, "r")

	if file then
		file:close()
		return true
	end

	return false
end

local function writeFile(path, text)
	if not path or path == "" then
		debugLog("No output path set.")
		return false
	end

	ensureParentDirectoryForFile(path)

	local file, errorMessage = io.open(path, "w")

	if not file then
		debugLog("Failed to open file: " .. tostring(path))
		debugLog("Error: " .. tostring(errorMessage))
		return false
	end

	file:write(text or "")
	file:close()

	return true
end


local function readFile(path)
	if not path or path == "" then
		return ""
	end

	local file = io.open(path, "r")

	if not file then
		return ""
	end

	local text = file:read("*a") or ""

	file:close()

	return text
end

local function ensureDirectory(path)
	local ok, lfs = pcall(require, "lfs")

	if not ok or not lfs then
		debugLog("Could not create directory because LuaFileSystem is unavailable: " .. tostring(path))
		return false
	end

	local current = ""
	path = tostring(path or ""):gsub("/", "\\")

	for part in path:gmatch("[^\\]+") do
		if current == "" then
			current = part
		else
			current = current .. "\\" .. part
		end

		if not lfs.attributes(current, "mode") then
			local made, errorMessage = lfs.mkdir(current)

			if not made then
				debugLog("Failed to create directory: " .. tostring(current))
				debugLog("Error: " .. tostring(errorMessage))
				return false
			end
		end
	end

	return true
end

ensureParentDirectoryForFile = function(path)
	path = tostring(path or "")
	local folder = path:match("^(.*)[/\\][^/\\]+$")

	if not folder or folder == "" then
		return true
	end

	return ensureDirectory(folder)
end

--==================
-- INSTALL CHECK
--==================

local hasShownInstallerWarning = false

local function isInstallerComplete()
	return fileExists(config.installerMarkerPath)
end

local function warnInstallerRequired()
	if hasShownInstallerWarning then
		return
	end

	hasShownInstallerWarning = true

	tes3.messageBox("AI Voices is not installed yet. Please run install_aivoices.bat from Data Files\\MWSE\\mods\\AIVoices.")
end

--==================
-- GAME STATE HELPERS
--==================

local function isPlayerInGame()
	return tes3.player ~= nil
		and tes3.player.cell ~= nil
		and tes3.mobilePlayer ~= nil
end

--==================
-- WATCHER PROCESS
--==================

local watcherProcess = nil
local heartbeatStarted = false
local lastHeartbeatTime = 0

local function quotePath(path)
	return [["]] .. tostring(path or "") .. [["]]
end

local function writeHeartbeat()
	if not isInstallerComplete() then
		return
	end

	writeFile(config.heartbeatPath, tostring(os.time()))
end

local function startHeartbeat()
	if heartbeatStarted then
		return
	end

	heartbeatStarted = true
	lastHeartbeatTime = os.time()

	writeHeartbeat()

	debugLog("Heartbeat started.")
end



local function startWatcher()

	if not isInstallerComplete() then
		warnInstallerRequired()
		return
	end

	if config.showWatcherConsole then
		debugLog("Watcher Console visible.")
	else
		debugLog("Watcher Console hidden.")
	end

	if watcherProcess then
		debugLog("Watcher already started.")
		showMessage("AI Voices: Watcher already started.")
		return
	end

	if not config.pythonCommand or config.pythonCommand == "" then
		debugLog("No Python command set.")
		showMessage("AI Voices: No Python command set.")
		return
	end

	if not config.watcherPath or config.watcherPath == "" then
		debugLog("No watcher path set.")
		showMessage("AI Voices: No watcher path set.")
		return
	end

	local pythonwCommand = config.pythonCommand:gsub("python.exe$", "pythonw.exe")

	local command

	if config.showWatcherConsole then
		-- Visible watcher console.
		if config.watcherConsoleStaysOpen then
			-- Console stays open after watcher.py exits. Useful for debugging. Kill or not kill
			command = [[cmd /c start "AI Voices Watcher" cmd /k ]] .. quotePath(quotePath(config.pythonCommand) .. [[ -u ]] .. quotePath(config.watcherPath))
		else
			-- Console closes automatically when watcher.py exits.
			command = [[cmd /c start "AI Voices Watcher" cmd /c ]] .. quotePath(quotePath(config.pythonCommand) .. [[ -u ]] .. quotePath(config.watcherPath))
		end
	else
		-- Hidden watcher version. Uses pythonw.exe, so no console window appears.
		command = [[cmd /c start "AI Voices Watcher" ]] .. quotePath(pythonwCommand) .. [[ -u ]] .. quotePath(config.watcherPath)
	end

	debugLog("Starting watcher: " .. command)
	showMessage("AI Voices: Starting watcher.")

	startHeartbeat()

	watcherProcess = os.createProcess({
		command = command,
		async = true,
	})

	if watcherProcess then
		debugLog("Watcher process started.")
		showMessage("AI Voices: Watcher process started.")
	else
		debugLog("Watcher process failed to start.")
		showMessage("AI Voices: Watcher failed to start.")
	end
end

--==================
-- WATCHER HEALTH CHECK
--==================

local watcherWasDead = false
local loadingStatusFirstSeenTime = nil
local loadingStatusGraceSeconds = 10

local function getFileModifiedTime(path)
	local ok, lfs = pcall(require, "lfs")

	if not ok or not lfs then
		mwse.log("[AI Voices] Watcher health check failed: LuaFileSystem unavailable.")
		return nil, "lfs"
	end

	local modifiedTime = lfs.attributes(path, "modification")

	if not modifiedTime then
		return nil, "missing"
	end

	return modifiedTime, nil
end

local function checkWatcherHealth()
    local heartbeatPath = config.watcherHeartbeatPath
    	or [[Data Files\AIVoicesBackend\runtime\watcher_heartbeat.txt]]

	local statusText = string.lower(readFile(config.statusOutputPath) or "")
	local isBackendLoading = statusText:find("loading", 1, true) ~= nil

	if isBackendLoading then
		if not loadingStatusFirstSeenTime then
			loadingStatusFirstSeenTime = os.time()
		end

		local loadingSeconds = os.time() - loadingStatusFirstSeenTime

		if loadingSeconds <= loadingStatusGraceSeconds then
			debugLog("Skipped watcher health check while backend is loading.")
			return
		end

		debugLog("Backend has been loading too long. Resuming watcher health checks.")
	else
		loadingStatusFirstSeenTime = nil
	end

	local modifiedTime, reason = getFileModifiedTime(heartbeatPath)

	if not modifiedTime then
		if not watcherWasDead then
			watcherWasDead = true

			if reason == "lfs" then
				mwse.log("[AI Voices] Watcher health check could not run. LuaFileSystem unavailable.")
			else
				mwse.log("[AI Voices] Watcher appears to be dead. Heartbeat file is missing: %s", heartbeatPath)
				tes3.messageBox("AI Voices: Watcher appears to have died. Please restart Morrowind to continue using AI Voices.")
			end
		end

		return
	end

	local secondsSinceHeartbeat = os.time() - modifiedTime

--	mwse.log("[AI Voices] Watcher heartbeat age: %d seconds.", secondsSinceHeartbeat)

	if secondsSinceHeartbeat > 15 then
		if not watcherWasDead then
			watcherWasDead = true
			mwse.log("[AI Voices] Watcher appears to be dead. Last heartbeat was %d seconds ago.", secondsSinceHeartbeat)
			tes3.messageBox("AI Voices: Watcher appears to have died. Please restart Morrowind to continue using AI Voices.")
		end
	else
		if watcherWasDead then
			watcherWasDead = false
			mwse.log("[AI Voices] Watcher heartbeat restored.")
		end
	end
end

local lastHealthCheckTime = 0

local function onEnterFrame()
    if updateMenuStopState then
        updateMenuStopState()
    end

    updateWatcherStatus()

    if not heartbeatStarted then
        return
    end

    local now = os.time()
    local interval = config.heartbeatInterval or 2

    if now - lastHeartbeatTime >= interval then
        lastHeartbeatTime = now
        writeHeartbeat()
    end

    if now - lastHealthCheckTime >= 5 then
        lastHealthCheckTime = now
        checkWatcherHealth()
    end
end

--==================
-- TTS ENGINE OUTPUT
--==================

local function normalizeTtsEngine(engine)
	engine = tostring(engine or "xtts"):lower()

	if engine ~= "piper" and engine ~= "elevenlabs" and engine ~= "xtts" then
		return "xtts"
	end

	return engine
end

local function writePiperSettings()
	local maxMb = tonumber(config.piperGeneratedCacheMaxMb) or 500

	if maxMb < 0 then
		maxMb = 0
	end

	local noiseScale = tonumber(config.piperNoiseScale) or 0.667
	local noiseWScale = tonumber(config.piperNoiseWScale) or 0.333
	local sentenceSilence = tonumber(config.piperSentenceSilence) or 0.20

	if noiseScale < 0 then noiseScale = 0 end
	if noiseScale > 1 then noiseScale = 1 end

	if noiseWScale < 0 then noiseWScale = 0 end
	if noiseWScale > 1 then noiseWScale = 1 end

	if sentenceSilence < 0 then sentenceSilence = 0 end
	if sentenceSilence > 2 then sentenceSilence = 2 end

	local settingsText = table.concat({
		"cache_generated_lines=" .. tostring(config.piperCacheGeneratedLines == true),
		"generated_cache_max_mb=" .. tostring(maxMb),
		"noise_scale=" .. tostring(noiseScale),
		"noise_w=" .. tostring(noiseWScale),
		"sentence_silence=" .. tostring(sentenceSilence),
	}, "\n")

	writeFile(config.piperSettingsPath or [[Data Files\AIVoicesBackend\Piper\piper_settings.txt]], settingsText)

	return maxMb
end

local function writeGeneratedSettings()
	if not isInstallerComplete() then
		warnInstallerRequired()
		return false
	end

	local engine = normalizeTtsEngine(config.ttsEngine)

	writeFile(config.ttsEngineOutputPath, engine)
	writeFile(config.voiceVolumeOutputPath, tostring(config.voiceVolume or 50))
	writeFile(config.speechSpeedOutputPath, tostring(config.speechSpeed or 1.00))

	writeFile(config.elevenLabsModelIdOutputPath, tostring(config.elevenLabsModelId or "eleven_multilingual_v2"))
	writeFile(config.elevenLabsOutputFormatPath, tostring(config.elevenLabsOutputFormat or "wav_22050"))

	local elevenLabsMaxMb = tonumber(config.elevenLabsGeneratedCacheMaxMb) or 500

	if elevenLabsMaxMb < 0 then
		elevenLabsMaxMb = 0
	end

	local elevenLabsSettingsText = table.concat({
		"stability=" .. tostring(config.elevenLabsStability or 0.50),
		"similarity_boost=" .. tostring(config.elevenLabsSimilarityBoost or 0.75),
		"style=" .. tostring(config.elevenLabsStyle or 0.00),
		"use_speaker_boost=" .. tostring(config.elevenLabsUseSpeakerBoost == true),
		"cache_generated_lines=" .. tostring(config.elevenLabsCacheGeneratedLines == true),
		"generated_cache_max_mb=" .. tostring(elevenLabsMaxMb),
	}, "\n")



	local xttsMaxMb = tonumber(config.xttsGeneratedCacheMaxMb) or 500

	if xttsMaxMb < 0 then
		xttsMaxMb = 0
	end

	local xttsSettingsText = table.concat({
		"cache_generated_lines=" .. tostring(config.xttsCacheGeneratedLines == true),
		"generated_cache_max_mb=" .. tostring(xttsMaxMb),
		"temperature=" .. tostring(config.xttsTemperature or 0.65),
		"repetition_penalty=" .. tostring(config.xttsRepetitionPenalty or 2.0),
		"top_k=" .. tostring(config.xttsTopK or 50),
		"top_p=" .. tostring(config.xttsTopP or 0.85),
	}, "\n")

	writeFile(config.xttsSettingsPath or [[Data Files\AIVoicesBackend\settings\xtts_settings.txt]], xttsSettingsText)

	debugLog("TTS engine written: " .. tostring(engine))
	debugLog("Speech speed written: " .. tostring(config.speechSpeed or 1.00))
	debugLog("XTTS line cache enabled: " .. tostring(config.xttsCacheGeneratedLines == true))
	debugLog("XTTS line cache limit MB: " .. tostring(xttsMaxMb))
	debugLog("ElevenLabs model ID written: " .. tostring(config.elevenLabsModelId or "eleven_multilingual_v2"))
	debugLog("ElevenLabs output format written: " .. tostring(config.elevenLabsOutputFormat or "wav_22050"))
	local piperMaxMb = writePiperSettings()
	debugLog("Piper line cache enabled: " .. tostring(config.piperCacheGeneratedLines == true))
	debugLog("Piper line cache limit MB: " .. tostring(piperMaxMb))
	writeFile(config.elevenLabsSettingsPath, elevenLabsSettingsText)
	debugLog("ElevenLabs line cache enabled: " .. tostring(config.elevenLabsCacheGeneratedLines == true))
	debugLog("ElevenLabs line cache limit MB: " .. tostring(elevenLabsMaxMb))
	return true
end

--==================
-- VOICE MAP HELPERS
--==================

local function makeVoicePrefixFromRaceId(value)
	value = tostring(value or "")

	-- Split existing camelCase/PascalCase before lowercasing.
	value = value:gsub("([a-z])([A-Z])", "%1 %2")

	-- Treat spaces as word separators.
	-- Keep hyphens and underscores because some race IDs use them intentionally.
	value = value:gsub("%s+", " ")

	-- Remove weird punctuation, but keep hyphens and underscores.
	value = value:gsub("[^%w%s%-_]", "")

	-- Trim.
	value = value:gsub("^%s+", "")
	value = value:gsub("%s+$", "")

	if value == "" then
		return nil
	end

	local words = {}

	for word in value:gmatch("%S+") do
		table.insert(words, word:lower())
	end

	if #words == 0 then
		return nil
	end

	local result = words[1]

	for i = 2, #words do
		local word = words[i]
		result = result .. word:sub(1, 1):upper() .. word:sub(2)
	end

	return result
end

local function getVoiceKeyForRaceGender(raceId, isFemale)
	local genderName = isFemale and "Female" or "Male"
	local raceKey = makeVoicePrefixFromRaceId(raceId)

	if not raceKey then
		debugLog("Unknown race for voice map: " .. tostring(raceId))
		return nil
	end

	return raceKey .. genderName
end

--==================
-- XTTS FIRST LOAD WARNING
--==================

local xttsFirstLoadWarningShown = false

local function warnXttsFirstLoad()
	if xttsFirstLoadWarningShown then
		return
	end

	xttsFirstLoadWarningShown = true

	debugLog("XTTS model is ready. First dialogue sent.")
end


--==================
-- VOICE FILE OUTPUT
--==================

local function writeDialogueOutput(text, voiceKey)
	if not isInstallerComplete() then
		return
	end

	if not config.enabled then
		debugLog("Skipped write because mod is disabled.")
		return false
	end

	if not config.outputPath or config.outputPath == "" then
		showMessage("AI Voices: No dialogue output path set.")
		debugLog("No dialogue output path set.")
		return false
	end

	local engine = normalizeTtsEngine(config.ttsEngine)

	-- If XTTS is still loading, show a message and skip dialogue
	if engine == "xtts" then
		local status = readFile(config.statusOutputPath) or ""
		if status:find("loading") then
			showMessage("AI Voices: XTTS is loading. Please wait.")
			debugLog("Skipped dialogue because XTTS model is still loading.")
			return false
		end
	end

	local voicePath = nil
	local resolvedVoiceKey = nil

	if not voiceKey or voiceKey == "" then
		showMessage("AI Voices: No voice key available for this actor.")
		debugLog("No voice key available for this actor.")
		return false
	end

	if engine == "xtts" then
		resolvedVoiceKey = voiceKey
		voicePath = "xtts:" .. tostring(resolvedVoiceKey)
	elseif engine == "piper" then
		resolvedVoiceKey = voiceKey
		voicePath = "piper:" .. tostring(resolvedVoiceKey)
	elseif engine == "elevenlabs" then
		resolvedVoiceKey = voiceKey
		voicePath = "elevenlabs:" .. tostring(resolvedVoiceKey)
	else
		showMessage("AI Voices: Unknown TTS engine.")
		debugLog("Unknown TTS engine: " .. tostring(engine))
		return false
	end

	if engine == "xtts" then
		warnXttsFirstLoad()
	end

	local dialogueWritten = writeFile(config.outputPath, text or "")
	local voiceWritten = writeFile(config.voiceOutputPath, voicePath)

	if not dialogueWritten then
		showMessage("AI Voices: Failed to write dialogue file.")
		return false
	end

	if not voiceWritten then
		showMessage("AI Voices: Failed to write voice file.")
		return false
	end

	debugLog("Dialogue text: " .. tostring(text))
	debugLog("Requested voice key: " .. tostring(voiceKey))
	debugLog("Resolved voice key: " .. tostring(resolvedVoiceKey))
	debugLog("Resolved voice path: " .. tostring(voicePath))

	return true
end


--==================
-- WATCHER STATUS MESSAGES
--==================

local lastWatcherStatusText = nil

local function initializeWatcherStatus()
	lastWatcherStatusText = readFile(config.statusOutputPath)
end

updateWatcherStatus = function()
	if not config.statusOutputPath or config.statusOutputPath == "" then
		return
	end

	local statusText = readFile(config.statusOutputPath)

	if not statusText or statusText == "" then
		return
	end

	if statusText == lastWatcherStatusText then
		return
	end

	lastWatcherStatusText = statusText

	local message = statusText:match("^.-|(.+)$") or statusText

	if message and message ~= "" then
		showMessage("AI Voices: " .. tostring(message))
		debugLog("Watcher status: " .. tostring(message))
	end
end

--==================
-- STOP SPEECH OUTPUT
--==================

local stopSignalCounter = 0

local function writeStopSignal(reason)
	if not isInstallerComplete() then
		return false
	end

	if not config.stopOutputPath or config.stopOutputPath == "" then
		debugLog("No stop output path set.")
		return false
	end

	stopSignalCounter = stopSignalCounter + 1

	local stopText = string.format(
		"%s | %s | %s",
		tostring(os.time()),
		tostring(stopSignalCounter),
		tostring(reason or "stop")
	)

	local success = writeFile(config.stopOutputPath, stopText)

	if success then
		debugLog("Stop signal written: " .. tostring(reason or "stop"))
	else
		debugLog("Failed to write stop signal.")
	end

	return success
end


--==================
-- DIALOGUE TEXT HELPERS
--==================

local lastSpokenInfoId = nil
local lastSpokenText = nil
local greetingSpokenThisDialog = false

local function cleanDialogueText(text)
	text = tostring(text or "")

	local player = tes3.player
	local playerObject = player and player.object
	local actor = getCurrentDialogueActor and getCurrentDialogueActor()

	local function getPlayerName()
		return playerObject and playerObject.name or "player"
	end

	local function getPlayerRaceName()
		return playerObject and playerObject.race and (playerObject.race.name or playerObject.race.id) or ""
	end

	local function getPlayerClassName()
		return playerObject and playerObject.class and (playerObject.class.name or playerObject.class.id) or ""
	end

	local function getPlayerSexPossessive()
		if playerObject then
			return playerObject.female and "her" or "his"
		end
		return ""
	end

	local function getPlayerCellName()
		if player and player.cell then
			return player.cell.name or player.cell.id or ""
		end
		return ""
	end

	local function getPlayerGold()
		if tes3.getPlayerGold then
			return tostring(tes3.getPlayerGold())
		end
		return ""
	end

	local function getPlayerCrimeLevel()
		if tes3.mobilePlayer and tes3.mobilePlayer.bounty then
			return tostring(tes3.mobilePlayer.bounty)
		end
		return ""
	end

	local function getPlayerReputation()
		if tes3.mobilePlayer and tes3.mobilePlayer.reputation then
			return tostring(tes3.mobilePlayer.reputation)
		end
		if playerObject and playerObject.reputation then
			return tostring(playerObject.reputation)
		end
		return ""
	end

	local function getActorName()
		return actor and (actor.name or actor.id) or ""
	end

	local function getActorRaceName()
		return actor and actor.race and (actor.race.name or actor.race.id) or ""
	end

	local function getActorClassName()
		return actor and actor.class and (actor.class.name or actor.class.id) or ""
	end

	local function getActorFactionName()
		return actor and actor.faction and (actor.faction.name or actor.faction.id) or ""
	end

	local function getActorRankName()
		if actor and actor.faction and actor.faction.playerJoined then
			return actor.faction:getRankName(actor.faction.playerRank) or ""
		end
		return ""
	end

	local function getActorNextRankName()
		if actor and actor.faction and actor.faction.playerJoined then
			local nextRank = (actor.faction.playerRank or 0) + 1
			return actor.faction:getRankName(nextRank) or ""
		end
		return ""
	end

	-- Player substitutions
	text = text:gsub("%%PCName", getPlayerName())
	text = text:gsub("%%PCRace", getPlayerRaceName())
	text = text:gsub("%%PCClass", getPlayerClassName())
	text = text:gsub("%%PCSex", getPlayerSexPossessive())
	text = text:gsub("%%PCRank", getActorRankName())
	text = text:gsub("%%PCNextRank", getActorNextRankName())
	text = text:gsub("%%PCCell", getPlayerCellName())
	text = text:gsub("%%PCGold", getPlayerGold())
	text = text:gsub("%%PCCrimeLevel", getPlayerCrimeLevel())
	text = text:gsub("%%PCReputation", getPlayerReputation())

	-- Actor substitutions
	text = text:gsub("%%name", getActorName())
	text = text:gsub("%%Name", getActorName())
	text = text:gsub("%%race", getActorRaceName())
	text = text:gsub("%%Race", getActorRaceName())
	text = text:gsub("%%class", getActorClassName())
	text = text:gsub("%%Class", getActorClassName())
	text = text:gsub("%%faction", getActorFactionName())
	text = text:gsub("%%Faction", getActorFactionName())
	text = text:gsub("%%rank", getActorRankName())
	text = text:gsub("%%Rank", getActorRankName())

	-- Strip any remaining unresolved % tokens
	text = text:gsub("%%%u%a+", "")
	text = text:gsub("%%%l%a+", "")

	-- Strip Morrowind colour/formatting codes
	text = text:gsub("@([^#]+)#", "%1")
	text = text:gsub("[@#]", "")

	-- Normalise whitespace
	text = text:gsub("\r", " ")
	text = text:gsub("\n", " ")
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")

	return text
end


--==================
-- BACKEND VOICE MAP LOOKUP
--==================

local function readUsableVoiceMapKeys(path)
	local keys = {}

	if not path or path == "" then
		return keys
	end

	local file = io.open(path, "r")

	if not file then
		return keys
	end

	for line in file:lines() do
		line = tostring(line or "")
		line = line:gsub("^%s+", ""):gsub("%s+$", "")

		if line ~= "" and not line:match("^#") then
			local key, value = line:match("^([^=]+)=(.*)$")

			if key and value then
				key = key:gsub("^%s+", ""):gsub("%s+$", "")
				value = value:gsub("^%s+", ""):gsub("%s+$", "")

				if key ~= "" and value ~= "" then
					keys[string.lower(key)] = true
				end
			end
		end
	end

	file:close()

	return keys
end

local function getVoiceMapPathForEngine(engine)
	if engine == "xtts" then
		return config.xttsReferenceMapPath
	end

	if engine == "piper" then
		return config.piperVoiceMapPath
	end

	if engine == "elevenlabs" then
		return config.elevenLabsVoiceMapPath
	end

	return nil
end

local function getActorVoiceKeyFromBackendMap(actor, engine)
	if not actor then
		return nil
	end

	local path = getVoiceMapPathForEngine(engine)
	local keys = readUsableVoiceMapKeys(path)

	local actorId = string.lower(tostring(actor.id or ""))
	local actorName = string.lower(tostring(actor.name or ""))

	if actorId ~= "" and keys[actorId] then
		return actorId
	end

	if actorName ~= "" and keys[actorName] then
		return actorName
	end

	return nil
end

--==================
-- DIALOGUE ACTOR HELPERS
--==================

getCurrentDialogueActor = function()
	local mobile = tes3ui.getServiceActor()

	if not mobile then
		return nil
	end

	return mobile.object
end

local function getVoiceKeyForCurrentDialogueActor()
	local actor = getCurrentDialogueActor()

	if not actor then
		debugLog("No dialogue actor found with tes3ui.getServiceActor().")
		return nil
	end

	local raceId = actor.race and actor.race.id
	local raceName = actor.race and actor.race.name
	local isFemale = actor.female == true
	local engine = tostring(config.ttsEngine or ""):lower()

	debugLog("Dialogue actor: " .. tostring(actor.id))
	debugLog("Dialogue name: " .. tostring(actor.name))
	debugLog("Dialogue race: " .. tostring(raceId))
	debugLog("Dialogue female: " .. tostring(isFemale))

	local actorVoiceKey = getActorVoiceKeyFromBackendMap(actor, engine)

	if actorVoiceKey then
		debugLog("Using actor-specific voice key from backend map: " .. tostring(actorVoiceKey))
		return actorVoiceKey
	end

	return getVoiceKeyForRaceGender(raceId, isFemale)
end


--==================
-- DIALOGUE SPEECH
--==================

local function speakDialogueInfo(info, text)
	text = cleanDialogueText(text)

	if text == "" then
		debugLog("Skipped empty dialogue text.")
		return
	end

	if not getCurrentDialogueActor() then
		debugLog("Skipped dialogue info because no service actor was found.")
		return
	end

	local infoId = info and info.id

	if infoId and infoId == lastSpokenInfoId and text == lastSpokenText then
		debugLog("Skipped duplicate dialogue info: " .. tostring(infoId))
		return
	end

	lastSpokenInfoId = infoId
	lastSpokenText = text

	local voiceKey = getVoiceKeyForCurrentDialogueActor()

	debugLog("Speaking dialogue info.")
	debugLog("Info ID: " .. tostring(infoId))
	debugLog("Voice key: " .. tostring(voiceKey))
	debugLog("Text: " .. tostring(text))

	writeDialogueOutput(text, voiceKey)
end


--==================
-- GREETING CAPTURE
--==================

local function hasSentencePunctuation(text)
	text = tostring(text or "")

	return text:find(".", 1, true)
		or text:find("!", 1, true)
		or text:find("?", 1, true)
end

local function isUsefulGreetingText(text)
	text = cleanDialogueText(text)

	if text == "" then
		return false
	end

	local lowerText = text:lower()

	if lowerText == "goodbye" then
		return false
	end

	if not hasSentencePunctuation(text) then
		return false
	end

	if #text < 4 then
		return false
	end

	return true
end

local function scanElementForBestText(element, best)
	if not element then
		return best
	end

	if best.text then
		return best
	end

	if element.text then
		local text = cleanDialogueText(element.text)

		if isUsefulGreetingText(text) then
			best.text = text
			best.length = #text
			return best
		end
	end

	if element.children then
		for _, child in ipairs(element.children) do
			best = scanElementForBestText(child, best)

			if best.text then
				return best
			end
		end
	end

	return best
end

local function findGreetingTextInMenu()
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))

	if not menu then
		return nil
	end

	local best = {
		text = nil,
		length = 0,
	}

	best = scanElementForBestText(menu, best)

	return best.text
end

local function speakGreetingFromMenu()
	if not config.enabled then
		return
	end

	if greetingSpokenThisDialog then
		debugLog("Greeting skipped because it already spoke for this dialogue opening.")
		return
	end

	if not tes3ui.findMenu(tes3ui.registerID("MenuDialog")) then
		return
	end

	if not getCurrentDialogueActor() then
		debugLog("Greeting skipped because no service actor was found.")
		return
	end

	local text = findGreetingTextInMenu()

	if not text or text == "" then
		debugLog("Greeting skipped because no greeting text was found.")
		return
	end

	if not isUsefulGreetingText(text) then
		debugLog("Greeting skipped because final candidate failed validation: " .. tostring(text))
		return
	end

	debugLog("Greeting candidate text: " .. tostring(text))

	greetingSpokenThisDialog = true
	lastSpokenInfoId = nil

	local voiceKey = getVoiceKeyForCurrentDialogueActor()

	debugLog("Speaking greeting from MenuDialog.")
	debugLog("Voice key: " .. tostring(voiceKey))
	debugLog("Greeting text: " .. tostring(text))

	writeDialogueOutput(text, voiceKey)
end


local function scheduleGreetingCapture()
    -- MenuDialog text can populate at different times depending on dialogue type,
    -- NPC script timing, and load. Multiple attempts are scheduled as a fallback.
    -- greetingSpokenThisDialog prevents the greeting from being spoken more than once.
    local delays = {
        0.10,
        0.25,
        0.50,
        1.00,
    }

    for _, delay in ipairs(delays) do
        timer.start({
            duration = delay,
            type = timer.real,
            callback = speakGreetingFromMenu,
        })
    end
end

--==================
-- MENU STATE TRACKING
--==================

local wasDialogMenuOpen = false
local wasPauseMenuOpen = false

local function isMenuOpen(menuName)
	return tes3ui.findMenu(tes3ui.registerID(menuName)) ~= nil
end

updateMenuStopState = function()
	if not isPlayerInGame() then
		wasDialogMenuOpen = false
		wasPauseMenuOpen = false
		return
	end

	local isDialogMenuOpen = isMenuOpen("MenuDialog")
	local isPauseMenuOpen = isMenuOpen("MenuOptions")

	if wasDialogMenuOpen and not isDialogMenuOpen then
		debugLog("MenuDialog closed by frame-state check.")
		writeStopSignal("dialogue closed")
	end

	if isPauseMenuOpen and not wasPauseMenuOpen then
		debugLog("MenuOptions opened in-game. Stopping speech.")
		writeStopSignal("pause menu opened")
	end

	wasDialogMenuOpen = isDialogMenuOpen
	wasPauseMenuOpen = isPauseMenuOpen
end

--==================
-- DIALOGUE MENU TEXT VALIDATION
--==================

local function menuContainsText(element, targetText)
	if not element or not targetText or targetText == "" then
		return false
	end

	targetText = cleanDialogueText(targetText)

	if element.text then
		local elementText = cleanDialogueText(element.text)

		if elementText == targetText then
			return true
		end

		if #targetText > 20 and elementText:find(targetText, 1, true) then
			return true
		end
	end

	if element.children then
		for _, child in ipairs(element.children) do
			if menuContainsText(child, targetText) then
				return true
			end
		end
	end

	return false
end

local function isTextVisibleInDialogueMenu(text)
	local menuDialog = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))

	if not menuDialog then
		return false
	end

	return menuContainsText(menuDialog, text)
end

local function onInfoGetText(e)
	if not config.enabled then
		return
	end

	if not isMenuOpen("MenuDialog") then
		return
	end

	if not e or not e.info then
		return
	end

	local info = e.info
	local text = e.text

	if not text or text == "" then
		text = e:loadOriginalText()
	end

	text = cleanDialogueText(text)

	if text == "" then
		return
	end

	timer.start({
		duration = 0.10,
		type = timer.real,
		callback = function()
			if not config.enabled then
				return
			end

			if not isMenuOpen("MenuDialog") then
				return
			end

			if not isTextVisibleInDialogueMenu(text) then
				debugLog("Skipped infoGetText because text is not visible in MenuDialog.")
				debugLog("Skipped text: " .. tostring(text))
				return
			end

			speakDialogueInfo(info, text)
		end,
	})
end

local function onDialogUiActivated(e)
	if not config.enabled then
		return
	end

	if not e or not e.element then
		return
	end

	if e.element.name ~= "MenuDialog" then
		return
	end

	debugLog("MenuDialog uiActivated. Scheduling greeting capture.")
	greetingSpokenThisDialog = false
	scheduleGreetingCapture()
end

local function onMenuExit(e)
	if not config.enabled then
		return
	end

	if not isPlayerInGame() then
		return
	end

	if not e or not e.menu then
		return
	end

	if e.menu.name == "MenuDialog" then
		debugLog("MenuDialog closed by menuExit.")
		writeStopSignal("dialogue menuExit")
	end
end

--==================
-- INITIALIZE
--==================

local function initialized()
	reloadConfig()

	if not config.enabled then
		mwse.log("[%s] Disabled. This can be enabled in MCM settings.", modName)
		return
	end

	if not isInstallerComplete() then
		debugLog("Installer marker path: " .. tostring(config.installerMarkerPath))
		warnInstallerRequired()
		return
	end

	event.register(tes3.event.infoGetText, onInfoGetText)
	event.register(tes3.event.enterFrame, onEnterFrame)
	event.register(tes3.event.uiActivated, onDialogUiActivated)
	event.register(tes3.event.menuExit, onMenuExit)

	writeFile(config.watcherHeartbeatPath, "")
	writeFile(config.outputPath, "")
	writeFile(config.voiceOutputPath, "")
	writeFile(config.statusOutputPath, "")

	showMessage("Initialized.")
	mwse.log("[%s] Initialized.", modName)

	debugLog("Enabled: " .. tostring(config.enabled))
	debugLog("TTS engine: " .. tostring(config.ttsEngine))
	debugLog("Installer marker path: " .. tostring(config.installerMarkerPath))
	debugLog("Dialogue output path: " .. tostring(config.outputPath))
	debugLog("Voice output path: " .. tostring(config.voiceOutputPath))
	debugLog("Stop output path: " .. tostring(config.stopOutputPath))
	debugLog("Python command: " .. tostring(config.pythonCommand))
	debugLog("Watcher path: " .. tostring(config.watcherPath))
	debugLog("Heartbeat path: " .. tostring(config.heartbeatPath))

	writeGeneratedSettings()
	initializeWatcherStatus()
	startWatcher()

end


--==================
-- MCM REGISTRATION
--==================

local function onModConfigReady()
    local mcm = require("AIVoices.mcm")
    if mcm and mcm.setReloadCallback then
        mcm.setReloadCallback(reloadConfig)
    end
end

--==================
-- EVENT REGISTRATION
--==================

event.register(tes3.event.initialized, initialized)
event.register(tes3.event.modConfigReady, onModConfigReady)