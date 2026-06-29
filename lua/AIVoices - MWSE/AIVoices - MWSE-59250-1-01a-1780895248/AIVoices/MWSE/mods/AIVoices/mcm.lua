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
config.piperSettingsPath = migrateBackendPath(config.piperSettingsPath)
config.piperVoiceMapPath = migrateBackendPath(config.piperVoiceMapPath)
config.elevenLabsApiKeyOutputPath = migrateBackendPath(config.elevenLabsApiKeyOutputPath)
config.elevenLabsVoiceMapPath = migrateBackendPath(config.elevenLabsVoiceMapPath)
config.elevenLabsModelIdOutputPath = migrateBackendPath(config.elevenLabsModelIdOutputPath)
config.elevenLabsOutputFormatPath = migrateBackendPath(config.elevenLabsOutputFormatPath)
config.elevenLabsSettingsPath = migrateBackendPath(config.elevenLabsSettingsPath)
config.voiceVolume = tonumber(config.voiceVolume) or 50
config.voiceVolumeOutputPath = config.voiceVolumeOutputPath or [[Data Files\AIVoicesBackend\settings\voice_volume.txt]]

if config.voiceVolume < 0 then
	config.voiceVolume = 0
end

if config.voiceVolume > 100 then
	config.voiceVolume = 100
end

config.pronunciationMapPath = config.pronunciationMapPath or [[Data Files\AIVoicesBackend\settings\pronunciation.txt]]
config.pronunciationAddLine = ""
config.pronunciationMap = {}

config.xttsReferenceMap = config.xttsReferenceMap or {}
config.voiceMap = config.voiceMap or {}
config.elevenLabsVoiceMap = config.elevenLabsVoiceMap or {}

config.xttsReferenceMapPath = config.xttsReferenceMapPath or [[Data Files\AIVoicesBackend\XTTS\xtts_reference_map.txt]]
config.piperVoiceMapPath = config.piperVoiceMapPath or [[Data Files\AIVoicesBackend\Piper\piper_voice_map.txt]]
config.piperSettingsPath = config.piperSettingsPath or [[Data Files\AIVoicesBackend\Piper\piper_settings.txt]]
config.elevenLabsVoiceMapPath = config.elevenLabsVoiceMapPath or [[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_voice_map.txt]]
config.speechSpeedOutputPath = config.speechSpeedOutputPath or [[Data Files\AIVoicesBackend\settings\speech_speed.txt]]

config.xttsTemperature = config.xttsTemperature or 0.65
config.xttsRepetitionPenalty = config.xttsRepetitionPenalty or 2.0
config.xttsTopK = config.xttsTopK or 50
config.xttsTopP = config.xttsTopP or 0.85
if config.speechSpeed == nil then config.speechSpeed = 1.00 end

if config.xttsCacheGeneratedLines == nil then
	config.xttsCacheGeneratedLines = false
end

config.xttsGeneratedCacheMaxMb = config.xttsGeneratedCacheMaxMb or 500



if config.piperCacheGeneratedLines == nil then
	config.piperCacheGeneratedLines = false
end

if config.piperSentenceSilence == nil then
	config.piperSentenceSilence = 0.20
end

if config.piperNoiseScale == nil then
	config.piperNoiseScale = 0.667
end

if config.piperNoiseWScale == nil then
	config.piperNoiseWScale = 0.333
end

config.piperGeneratedCacheMaxMb = config.piperGeneratedCacheMaxMb or 500

if config.elevenLabsCacheGeneratedLines == nil then
	config.elevenLabsCacheGeneratedLines = true
end

config.elevenLabsGeneratedCacheMaxMb = config.elevenLabsGeneratedCacheMaxMb or 500

local _reloadCallback = nil

local function setReloadCallback(fn)
    _reloadCallback = fn
end

local function saveAndReloadConfig()
	mwse.saveConfig("AIVoices", config)

	if _reloadCallback then
		_reloadCallback()
	end
end

local function saveConfigOnly()
	mwse.saveConfig("AIVoices", config)
end

--==================
-- TEMPLATE
--==================

local template = mwse.mcm.createTemplate({
	name = "AI Voices",
})


--==================
-- SAVE
--==================

template:saveOnClose("AIVoices", config)


--==================
-- FILE HELPERS
--==================

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

local function ensureDirectory(path)
	local ok, lfs = pcall(require, "lfs")

	if not ok or not lfs then
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
			local made = lfs.mkdir(current)

			if not made then
				return false
			end
		end
	end

	return true
end

local function ensureParentDirectoryForFile(path)
	path = tostring(path or "")
	local folder = path:match("^(.*)[/\\][^/\\]+$")

	if not folder or folder == "" then
		return true
	end

	return ensureDirectory(folder)
end

local function writeFile(path, text)
	if not path or path == "" then
		return false
	end

	ensureParentDirectoryForFile(path)

	local file = io.open(path, "w")

	if not file then
		return false
	end

	file:write(text or "")
	file:close()

	return true
end

local function writeVoiceVolume()
	writeFile(config.voiceVolumeOutputPath, tostring(config.voiceVolume or 50))
end

local function writeSpeechSpeed()
	writeFile(
		config.speechSpeedOutputPath or [[Data Files\AIVoicesBackend\settings\speech_speed.txt]],
		tostring(config.speechSpeed or 1.00)
	)
end

--==================
-- INSTALL / BACKEND HELPERS
--==================

local function getInstallerMarkerPath()
	return config.installerMarkerPath
		or [[Data Files\AIVoicesBackend\install_markers\aivoices_installed.txt]]
end

local function isInstallerComplete()
	return fileExists(getInstallerMarkerPath())
end

local function isPiperAvailable()
	return fileExists([[Data Files\AIVoicesBackend\dependencies\aivoices-venv\Scripts\piper.exe]])
		and fileExists([[Data Files\AIVoicesBackend\Piper\piper_voice_map.txt]])
end

local function isXttsAvailable()
	return fileExists([[Data Files\AIVoicesBackend\dependencies\aivoices-venv\Lib\site-packages\TTS\api.py]])
		and fileExists([[Data Files\AIVoicesBackend\XTTS\xtts_reference_map.txt]])
end

local function isElevenLabsAvailable()
	return fileExists([[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_api_key.txt]])
		and fileExists([[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_voice_map.txt]])
end

local function getAvailableTtsEngineOptions()
	if not isInstallerComplete() then
		return {
			{
				text = "AI Voices Not Installed",
				value = config.ttsEngine or "xtts",
			},
		}
	end

	local options = {}

	if isXttsAvailable() then
		table.insert(options, { text = "XTTS", value = "xtts" })
	end

	if isElevenLabsAvailable() then
		table.insert(options, { text = "ElevenLabs", value = "elevenlabs" })
	end

	if isPiperAvailable() then
		table.insert(options, { text = "Piper", value = "piper" })
	end

	if #options == 0 then
		return {
			{
				text = "No TTS Voice Engines Installed",
				value = config.ttsEngine or "xtts",
			},
		}
	end

	local currentEngineIsAvailable = false

	for _, option in ipairs(options) do
		if option.value == config.ttsEngine then
			currentEngineIsAvailable = true
			break
		end
	end

	if not currentEngineIsAvailable then
		config.ttsEngine = options[1].value
	end

	return options
end


--==================
-- TTS SETTINGS OUTPUT
--==================

local function writeElevenLabsSettings()
	writeFile(config.elevenLabsModelIdOutputPath, tostring(config.elevenLabsModelId or "eleven_multilingual_v2"))
	writeFile(config.elevenLabsOutputFormatPath, tostring(config.elevenLabsOutputFormat or "wav_22050"))

	local maxMb = tonumber(config.elevenLabsGeneratedCacheMaxMb) or 500

	if maxMb < 0 then
		maxMb = 0
	end

	local settingsText = table.concat({
		"stability=" .. tostring(config.elevenLabsStability or 0.50),
		"similarity_boost=" .. tostring(config.elevenLabsSimilarityBoost or 0.75),
		"style=" .. tostring(config.elevenLabsStyle or 0.00),
		"use_speaker_boost=" .. tostring(config.elevenLabsUseSpeakerBoost == true),
		"cache_generated_lines=" .. tostring(config.elevenLabsCacheGeneratedLines == true),
		"generated_cache_max_mb=" .. tostring(maxMb),
	}, "\n")

	writeFile(config.elevenLabsSettingsPath, settingsText)
end

local function writeXttsSettings()
	local cacheEnabled = config.xttsCacheGeneratedLines == true
	local maxMb = tonumber(config.xttsGeneratedCacheMaxMb) or 500

	if maxMb < 0 then
		maxMb = 0
	end

	local settingsText = table.concat({
		"cache_generated_lines=" .. tostring(cacheEnabled),
		"generated_cache_max_mb=" .. tostring(maxMb),
		"temperature=" .. tostring(config.xttsTemperature or 0.65),
		"repetition_penalty=" .. tostring(config.xttsRepetitionPenalty or 2.0),
		"top_k=" .. tostring(config.xttsTopK or 50),
		"top_p=" .. tostring(config.xttsTopP or 0.85),
	}, "\n")

	writeFile(config.xttsSettingsPath or [[Data Files\AIVoicesBackend\settings\xtts_settings.txt]], settingsText)
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
	if noiseWScale < 0 then noiseWScale = 0	end
	if noiseWScale > 1 then noiseWScale = 1	end
	if sentenceSilence < 0 then	sentenceSilence = 0	end
	if sentenceSilence > 2 then	sentenceSilence = 2	end

	local settingsText = table.concat({
		"cache_generated_lines=" .. tostring(config.piperCacheGeneratedLines == true),
		"generated_cache_max_mb=" .. tostring(maxMb),
		"noise_scale=" .. tostring(noiseScale),
		"noise_w=" .. tostring(noiseWScale),
		"sentence_silence=" .. tostring(sentenceSilence),
	}, "\n")

	writeFile(config.piperSettingsPath or [[Data Files\AIVoicesBackend\Piper\piper_settings.txt]], settingsText)
end

--==================
-- TTS ENGINE TEST
--==================

local function writeTtsEngineTestLine()
	mwse.saveConfig("AIVoices", config)

	local engine = tostring(config.ttsEngine or "xtts"):lower()

	if engine ~= "piper" and engine ~= "elevenlabs" and engine ~= "xtts" then
		engine = "xtts"
	end

	writeElevenLabsSettings()
	writeFile(config.statusOutputPath, "")
	writeXttsSettings()
	writePiperSettings()

	if engine == "xtts" then
		writeFile(config.voiceOutputPath, "xtts-test:darkElfMale")
		writeFile(config.outputPath, "M.W.S.E. is now talking to AI Voices with X.T.T.S.")

		tes3.messageBox("AI Voices: XTTS test line sent. XTTS can take a while to generate speech.")

	elseif engine == "elevenlabs" then
		writeFile(config.voiceOutputPath, "elevenlabs-test:darkElfMale")
		writeFile(config.outputPath, "M.W.S.E. is now talking to AI Voices with ElevenLabs.")

		tes3.messageBox("AI Voices: ElevenLabs test line sent. This may use API credits.")
		mwse.log("[AI Voices] ElevenLabs test line sent from MCM.")

	else
		writeFile(config.voiceOutputPath, "piper-test:darkElfMale")
		writeFile(config.outputPath, "M.W.S.E. is now talking to AI Voices with Piper.")

		tes3.messageBox("AI Voices: Piper test line sent.")
		mwse.log("[AI Voices] Piper test line sent from MCM.")
	end
end


--==================
-- PLAYBACK HELPERS
--==================

local function stopAllVoicePlayback()
    local stopText = string.format("%s | %s | %s", tostring(os.time()), "mcm", "manual stop")
    writeFile(config.stopOutputPath, stopText)
    writeFile(config.statusOutputPath, tostring(os.time()) .. "|Stop signal sent.")
    tes3.messageBox("AI Voices: Stop signal sent.")
end


--==================
-- PRONUNCIATION HELPERS
--==================

local function getPronunciationMapPath()
	return config.pronunciationMapPath
		or [[Data Files\AIVoicesBackend\settings\pronunciation.txt]]
end

local function getDefaultPronunciationHeader()
	return table.concat({
		"# AI Voices pronunciation replacements",
		"# Format: original=replacement",
		"# Edit this file to change how words are spoken.",
		"",
	}, "\n")
end

local function ensurePronunciationFileExists()
	local path = getPronunciationMapPath()

	if fileExists(path) then
		return true
	end

	return writeFile(path, getDefaultPronunciationHeader())
end

local function readPronunciationMap(path)
	local values = {}
	local keys = {}

	if not path or path == "" then
		return values, keys
	end

	local file = io.open(path, "r")

	if not file then
		return values, keys
	end

	for line in file:lines() do
		line = tostring(line or "")
		line = line:gsub("^%s+", ""):gsub("%s+$", "")

		if line ~= "" and not line:match("^#") then
			local original, replacement = line:match("^([^=]+)=(.*)$")

			if original then
				original = original:gsub("^%s+", ""):gsub("%s+$", "")
				replacement = tostring(replacement or ""):gsub("^%s+", ""):gsub("%s+$", "")

				if original ~= "" then
					values[original] = replacement
					table.insert(keys, original)
				end
			end
		end
	end

	file:close()

	return values, keys
end

local function writePronunciationMapFile(path, values, keys)
	if not path or path == "" then
		return false
	end

	local file = io.open(path, "w")

	if not file then
		return false
	end

	file:write(getDefaultPronunciationHeader())

	for _, key in ipairs(keys) do
		file:write(tostring(key) .. "=" .. tostring(values[key] or "") .. "\n")
	end

	file:close()

	return true
end

ensurePronunciationFileExists()

local pronunciationMapPath = getPronunciationMapPath()
local pronunciationMapFromFile, pronunciationMapKeys = readPronunciationMap(pronunciationMapPath)

config.pronunciationMap = {}

for _, key in ipairs(pronunciationMapKeys) do
	config.pronunciationMap[key] = pronunciationMapFromFile[key]
end

local function writePronunciationMap()
	writePronunciationMapFile(pronunciationMapPath, config.pronunciationMap, pronunciationMapKeys)
end

local function addPronunciationLine()
	local line = tostring(config.pronunciationAddLine or "")
	line = line:gsub("^%s+", ""):gsub("%s+$", "")

	if line == "" then
		tes3.messageBox("AI Voices: Enter a pronunciation first. Format: original=replacement")
		return
	end

	local original, replacement = line:match("^([^=]+)=(.+)$")

	if not original or not replacement then
		tes3.messageBox("AI Voices: Invalid format. Use: original=replacement")
		return
	end

	original = original:gsub("^%s+", ""):gsub("%s+$", "")
	replacement = replacement:gsub("^%s+", ""):gsub("%s+$", "")

	if original == "" or replacement == "" then
		tes3.messageBox("AI Voices: Both sides must have text. Use: original=replacement")
		return
	end

	config.pronunciationMap[original] = replacement
	table.insert(pronunciationMapKeys, original)

	writePronunciationMap()

	config.pronunciationAddLine = ""
	mwse.saveConfig("AIVoices", config)

	tes3.messageBox("AI Voices: Added pronunciation:\n" .. original .. "=" .. replacement)
end

local function openPronunciationFile()
	ensurePronunciationFileExists()
	os.execute('start "" notepad "' .. getPronunciationMapPath() .. '"')
end


--==================
-- GENERAL PAGE
--==================

local generalPage = template:createSideBarPage({
	label = "General",
	description = "Basic AI Voices settings. Run install_aivoices.bat before using a TTS voice engine.",
})

generalPage:createYesNoButton({
	label = "Enable AI Voices",
	description = "Enables or disables AI Voices. Restart recommended after changing.",
	variable = mwse.mcm.createTableVariable({
		id = "enabled",
		table = config,
	}),
	callback = saveAndReloadConfig,
})

generalPage:createSlider({
	label = "Voice Volume",
	description = "Playback volume for AI Voices. Affects XTTS, Piper, and ElevenLabs. Default: 50%.",
	min = 0,
	max = 100,
	step = 5,
	jump = 10,
	variable = mwse.mcm.createTableVariable({
		id = "voiceVolume",
		table = config,
	}),
	callback = function()
		writeVoiceVolume()
		mwse.saveConfig("AIVoices", config)
	end,
})

generalPage:createSlider({
	label = "Speech Speed",
	description = "Playback speed for all voice engines. 1.00 is normal speed. ElevenLabs is capped at 1.2 by the API. Default: 1.00",
	min = 0.75,
	max = 2.00,
	step = 0.05,
	jump = 0.25,
	decimalPlaces = 2,
	variable = mwse.mcm.createTableVariable({
		id = "speechSpeed",
		table = config,
	}),
	callback = function()
		writeSpeechSpeed()
		mwse.saveConfig("AIVoices", config)
		if _reloadCallback then _reloadCallback() end
	end,
})

generalPage:createButton({
	label = "Stop All Voice Playback",
	description = "Stops the currently playing AI Voices WAV, regardless of the selected TTS engine.",
	buttonText = "Stop Voice",
	callback = function()
		stopAllVoicePlayback()
	end,
})

generalPage:createCategory({
	label = "Pronunciations",
})

generalPage:createTextField({
	label = "Pronunciation File",
	description = "File where pronunciation replacements are saved. Advanced setting. Reopen MCM after changing this path.",
	variable = mwse.mcm.createTableVariable({
		id = "pronunciationMapPath",
		table = config,
	}),
	callback = saveConfigOnly,
})

generalPage:createTextField({
	label = "Add Pronunciation",
	description = "Format: original=replacement. Example: Vvardenfell=Vardenfell",
	variable = mwse.mcm.createTableVariable({
		id = "pronunciationAddLine",
		table = config,
	}),
	callback = function()
		addPronunciationLine()
	end,
})

generalPage:createButton({
	label = "Open Pronunciation File",
	description = "Opens pronunciation.txt in Notepad.",
	buttonText = "Open File",
	callback = function()
		openPronunciationFile()
	end,
})

generalPage:createYesNoButton({
	label = "Show In-Game Messages",
	description = "Shows simple in-game status messages.",
	variable = mwse.mcm.createTableVariable({
		id = "showMessages",
		table = config,
	}),
	callback = saveAndReloadConfig,
})

generalPage:createYesNoButton({
	label = "Debug Log",
	description = "Writes AI Voices debug messages to MWSE.log.",
	variable = mwse.mcm.createTableVariable({
		id = "debugLog",
		table = config,
	}),
	callback = saveAndReloadConfig,
})


--==================
-- ENGINE PAGE
--==================

local enginePage = template:createSideBarPage({
	label = "Engine",
	description = "Choose the active TTS voice engine. Only installed voice engines appear here. XTTS is local AI voice cloning, ElevenLabs is online API voice generation, and Piper is local .onnx TTS.",
})

enginePage:createCycleButton({
	label = "TTS Engine",
	description = "Select the voice engine used by watcher.py. If AI Voices is not installed, this will show AI Voices Not Installed.",
	options = getAvailableTtsEngineOptions(),
	variable = mwse.mcm.createTableVariable({
		id = "ttsEngine",
		table = config,
	}),
	callback = function()
		if not isInstallerComplete() then
			tes3.messageBox("AI Voices is not installed yet. Please run install_aivoices.bat from Data Files\\MWSE\\mods\\AIVoices.")
			return
		end

		mwse.saveConfig("AIVoices", config)
		writeFile(config.ttsEngineOutputPath, tostring(config.ttsEngine or "xtts"):lower())
		writeElevenLabsSettings()
		writeXttsSettings()
		writePiperSettings()

		if _reloadCallback then _reloadCallback() end

		tes3.messageBox("AI Voices: TTS engine changed. Use Test Voice to hear it.")
	end,
})

enginePage:createInfo({
	text = "Use Test Voice to send a short test line to the selected voice engine. ",
})

enginePage:createInfo({
	text = "Test voice is not cached.",
})

enginePage:createInfo({
	text = "ElevenLabs tests use API credits.",
})

enginePage:createInfo({
	text = "XTTS loads on first use. If you switch to XTTS after starting the game, use Test Voice once to preload the model before talking to NPCs.",
})



enginePage:createButton({
	label = "Test Selected Voice",
	description = "Sends a short test line to the selected TTS voice engine. ElevenLabs will use API credits.",
	buttonText = "Test Voice",
	callback = function()
		if not isInstallerComplete() then
			tes3.messageBox("AI Voices is not installed yet. Please run install_aivoices.bat from Data Files\\MWSE\\mods\\AIVoices.")
			return
		end

		writeTtsEngineTestLine()
	end,
})


--==================
-- XTTS REFERENCE MAP HELPERS
--==================

local function getXttsReferenceMapPath()
	return config.xttsReferenceMapPath
		or [[Data Files\AIVoicesBackend\XTTS\xtts_reference_map.txt]]
end

local function readXttsReferenceMap(path)
	local values = {}

	if not path or path == "" then
		return values
	end

	local file = io.open(path, "r")

	if not file then
		return values
	end

	for line in file:lines() do
		line = tostring(line or "")
		line = line:gsub("^%s+", "")
		line = line:gsub("%s+$", "")

		if line ~= "" and not line:match("^#") then
			local key, value = line:match("^([^=]+)=(.*)$")

			if key then
				key = key:gsub("^%s+", ""):gsub("%s+$", "")
				value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")

				if key ~= "" then
					values[key] = value
				end
			end
		end
	end

	file:close()

	return values
end

local function writeXttsReferenceMapFile(path, values, orderedKeys)
	if not path or path == "" then
		return false
	end

	local file = io.open(path, "w")

	if not file then
		return false
	end

	file:write("# AI Voices XTTS reference audio map\n")
	file:write("# Format: voiceKey=reference audio file\n")
	file:write("# Paths are relative to Morrowind Data Files.\n")
	file:write("# Race/gender entries and actor-specific entries use the same map.\n")
	file:write("# Do not redistribute generated reference_samples files.\n")
	file:write("\n")

	for _, key in ipairs(orderedKeys) do
		file:write(tostring(key) .. "=" .. tostring(values[key] or "") .. "\n")
	end

	file:close()

	return true
end

local function getVoiceKeyLabel(voiceKey)
	local labels = {
		argonianMale = "Argonian Male",
		argonianFemale = "Argonian Female",
		bretonMale = "Breton Male",
		bretonFemale = "Breton Female",
		darkElfMale = "Dark Elf Male",
		darkElfFemale = "Dark Elf Female",
		highElfMale = "High Elf Male",
		highElfFemale = "High Elf Female",
		imperialMale = "Imperial Male",
		imperialFemale = "Imperial Female",
		khajiitMale = "Khajiit Male",
		khajiitFemale = "Khajiit Female",
		nordMale = "Nord Male",
		nordFemale = "Nord Female",
		orcMale = "Orc Male",
		orcFemale = "Orc Female",
		redguardMale = "Redguard Male",
		redguardFemale = "Redguard Female",
		woodElfMale = "Wood Elf Male",
		woodElfFemale = "Wood Elf Female",

		vivec = "Vivec",
		["dagoth ur"] = "Dagoth Ur",
		almalexia = "Almalexia",
		["yagrum bagarn"] = "Yagrum Bagarn",
	}

	return labels[voiceKey] or tostring(voiceKey)
end

local preferredVoiceKeyOrder = {
	"argonianMale",
	"argonianFemale",
	"bretonMale",
	"bretonFemale",
	"darkElfMale",
	"darkElfFemale",
	"highElfMale",
	"highElfFemale",
	"imperialMale",
	"imperialFemale",
	"khajiitMale",
	"khajiitFemale",
	"nordMale",
	"nordFemale",
	"orcMale",
	"orcFemale",
	"redguardMale",
	"redguardFemale",
	"woodElfMale",
	"woodElfFemale",

	"vivec",
	"dagoth ur",
	"almalexia",
	"yagrum bagarn",
}

local function buildOrderedKeys(values, preferredOrder)
    local orderedKeys = {}
    local added = {}

    for _, key in ipairs(preferredOrder) do
        if values[key] ~= nil then
            table.insert(orderedKeys, key)
            added[key] = true
        end
    end

    for key in pairs(values) do
        if not added[key] then
            table.insert(orderedKeys, key)
        end
    end

    return orderedKeys
end

local xttsReferenceMapPath = getXttsReferenceMapPath()
local xttsReferenceMapFromFile = readXttsReferenceMap(xttsReferenceMapPath)
local xttsReferenceMapKeys = buildOrderedKeys(xttsReferenceMapFromFile, preferredVoiceKeyOrder)

config.xttsReferenceMap = {}

for _, key in ipairs(xttsReferenceMapKeys) do
	config.xttsReferenceMap[key] = xttsReferenceMapFromFile[key]
end

local function writeXttsReferenceMap()
	writeXttsReferenceMapFile(xttsReferenceMapPath, config.xttsReferenceMap, xttsReferenceMapKeys)
end


--==================
-- XTTS CACHE HELPERS
--==================

local function getXttsGeneratedCachePath()
	return [[Data Files\AIVoicesBackend\XTTS\cache\generated_lines]]
end

local function clearDirectoryFilesRecursive(path)
	local ok, lfs = pcall(require, "lfs")

	if not ok or not lfs then
		tes3.messageBox("AI Voices: Could not access LuaFileSystem.")
		return false, 0
	end

	local deletedCount = 0

	local function clearFolder(folderPath)
		for fileName in lfs.dir(folderPath) do
			if fileName ~= "." and fileName ~= ".." then
				local fullPath = folderPath .. "\\" .. fileName
				local mode = lfs.attributes(fullPath, "mode")

				if mode == "directory" then
					clearFolder(fullPath)
					os.remove(fullPath)
				elseif mode == "file" then
					if os.remove(fullPath) then
						deletedCount = deletedCount + 1
					end
				end
			end
		end
	end

	if not lfs.attributes(path, "mode") then
		return true, 0
	end

	clearFolder(path)

	return true, deletedCount
end

local function clearGeneratedCache(label, path)
	local success, deletedCount = clearDirectoryFilesRecursive(path)

	if success then
		tes3.messageBox("AI Voices: Cleared " .. label .. " generated line cache. Deleted " .. tostring(deletedCount) .. " file(s).")
	else
		tes3.messageBox("AI Voices: Failed to clear " .. label .. " generated line cache.")
	end
end


--==================
-- RESET TO DEFAULTS
--==================

local function resetXttsGenerationDefaults()
	config.xttsTemperature = 0.65
	config.xttsRepetitionPenalty = 2.0
	config.xttsTopK = 50
	config.xttsTopP = 0.85

	writeXttsSettings()
	mwse.saveConfig("AIVoices", config)

	tes3.messageBox("AI Voices: XTTS generation defaults restored. Refresh MCM to reflect changes.")
end

local function resetPiperGenerationSettings()
	config.piperNoiseScale = 0.667
	config.piperNoiseWScale = 0.333
	config.piperSentenceSilence = 0.20

	writePiperSettings()
	mwse.saveConfig("AIVoices", config)

	tes3.messageBox("AI Voices: Piper generation settings reset to defaults. Refresh MCM to reflect changes.")
end

local function resetElevenLabsGenerationSettings()
	config.elevenLabsStability = 0.50
	config.elevenLabsSimilarityBoost = 0.75
	config.elevenLabsStyle = 0.00
	config.elevenLabsUseSpeakerBoost = true

	writeElevenLabsSettings()
	mwse.saveConfig("AIVoices", config)

	tes3.messageBox("AI Voices: ElevenLabs generation settings reset to defaults. Refresh MCM to reflect changes.")
end

--==================
-- XTTS PAGE
--==================

local xttsPage = template:createSideBarPage({
	label = "XTTS",
	description = "XTTS is local AI voice cloning. It uses your own CPU/GPU, may be slow on older devices, and uses reference audio listed in xtts_reference_map.txt.",
})

xttsPage:createTextField({
	label = "XTTS Reference Map File",
	description = "Only voice keys listed in this file are shown below.",
	variable = mwse.mcm.createTableVariable({
		id = "xttsReferenceMapPath",
		table = config,
	}),
})

xttsPage:createCategory({
	label = "Generation Settings",
})

xttsPage:createButton({
	label = "Reset Generation Defaults",
	description = "Resets Temperature, Repetition Penalty, Top K, and Top P to their recommended defaults.",
	buttonText = "Reset Defaults",
	callback = function()
		resetXttsGenerationDefaults()
	end,
})

xttsPage:createSlider({
	label = "Temperature",
	description = "Lower is more stable. Higher is more expressive but can get weird. Default: 0.65",
	min = 0.1,
	max = 2.0,
	step = 0.05,
	jump = 0.1,
	decimalPlaces = 2,
	variable = mwse.mcm.createTableVariable({
		id = "xttsTemperature",
		table = config,
	}),
	callback = function()
		writeXttsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

xttsPage:createSlider({
	label = "Repetition Penalty",
	description = "Higher helps reduce repeated words or looping. Default: 2.0",
	min = 0.5,
	max = 5.0,
	step = 0.1,
	jump = 0.5,
	decimalPlaces = 2,
	variable = mwse.mcm.createTableVariable({
		id = "xttsRepetitionPenalty",
		table = config,
	}),
	callback = function()
		writeXttsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

xttsPage:createSlider({
	label = "Top K",
	description = "Controls how many likely choices XTTS considers. Higher is more varied. Default: 50",
	min = 1,
	max = 150,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable({
		id = "xttsTopK",
		table = config,
	}),
	callback = function()
		writeXttsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

xttsPage:createSlider({
	label = "Top P",
	description = "Controls randomness range. Lower is safer, higher is more varied. Default: 0.85",
	min = 0.1,
	max = 1.0,
	step = 0.01,
	jump = 0.05,
	decimalPlaces = 2,
	variable = mwse.mcm.createTableVariable({
		id = "xttsTopP",
		table = config,
	}),
	callback = function()
		writeXttsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

xttsPage:createYesNoButton({
	label = "Cache Generated XTTS Lines",
	description = "Stores generated XTTS dialogue WAVs so repeated exact lines can play faster. Consider caching if generation is slow. Default: No",
	variable = mwse.mcm.createTableVariable({
		id = "xttsCacheGeneratedLines",
		table = config,
	}),
	callback = function()
		writeXttsSettings()
		mwse.saveConfig("AIVoices", config)
		tes3.messageBox("AI Voices: XTTS cache setting saved.")
	end,
})

xttsPage:createSlider({
	label = "XTTS Line Cache Limit MB",
	description = "Approximate size limit for generated XTTS dialogue WAVs. Older cached lines are deleted first. Set to 0 for unlimited. Default: 500MB",
	min = 0,
	max = 5000,
	step = 100,
	jump = 500,
	variable = mwse.mcm.createTableVariable({
		id = "xttsGeneratedCacheMaxMb",
		table = config,
	}),
	callback = function()
		writeXttsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

xttsPage:createButton({
	label = "Clear XTTS Generated Line Cache",
	description = "Deletes generated XTTS dialogue WAVs from XTTS\\cache\\generated_lines. Reference samples are not deleted.",
	buttonText = "Clear Cache",
	callback = function()
		clearGeneratedCache("XTTS", [[Data Files\AIVoicesBackend\XTTS\cache\generated_lines]])
	end,
})

if #xttsReferenceMapKeys == 0 then
	xttsPage:createInfo({
		text = "No XTTS reference entries found. Run the installer or add entries to XTTS\\xtts_reference_map.txt.",
	})
else
	xttsPage:createCategory({
		label = "Reference Audio",
	})

	for _, voiceKey in ipairs(xttsReferenceMapKeys) do
		xttsPage:createTextField({
			label = getVoiceKeyLabel(voiceKey),
			description = "XTTS reference audio file for voice key: " .. tostring(voiceKey),
			variable = mwse.mcm.createTableVariable({
				id = voiceKey,
				table = config.xttsReferenceMap,
			}),
			callback = function()
				writeXttsReferenceMap()
				mwse.saveConfig("AIVoices", config)
			end,
		})
	end
end


--==================
-- KEY VALUE MAP HELPERS
--==================

local function readKeyValueMap(path)
	local values = {}

	if not path or path == "" then
		return values
	end

	local file = io.open(path, "r")

	if not file then
		return values
	end

	for line in file:lines() do
		line = tostring(line or "")
		line = line:gsub("^%s+", "")
		line = line:gsub("%s+$", "")

		if line ~= "" and not line:match("^#") then
			local key, value = line:match("^([^=]+)=(.*)$")

			if key then
				key = key:gsub("^%s+", ""):gsub("%s+$", "")
				value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")

				if key ~= "" then
					values[key] = value
				end
			end
		end
	end

	file:close()

	return values
end

local function writeKeyValueMap(path, values, orderedKeys, headerLines)
	if not path or path == "" then
		return false
	end

	local file = io.open(path, "w")

	if not file then
		return false
	end

	for _, line in ipairs(headerLines or {}) do
		file:write(line .. "\n")
	end

	if headerLines and #headerLines > 0 then
		file:write("\n")
	end

	for _, key in ipairs(orderedKeys) do
		file:write(tostring(key) .. "=" .. tostring(values[key] or "") .. "\n")
	end

	file:close()

	return true
end


--==================
-- ELEVENLABS VOICE MAP HELPERS
--==================

local function getElevenLabsVoiceMapPath()
	return config.elevenLabsVoiceMapPath
		or [[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_voice_map.txt]]
end

local elevenLabsVoiceMapPath = getElevenLabsVoiceMapPath()
local elevenLabsVoiceMapFromFile = readKeyValueMap(elevenLabsVoiceMapPath)
local elevenLabsVoiceMapKeys = buildOrderedKeys(elevenLabsVoiceMapFromFile, preferredVoiceKeyOrder)

config.elevenLabsVoiceMap = {}

for _, key in ipairs(elevenLabsVoiceMapKeys) do
	config.elevenLabsVoiceMap[key] = elevenLabsVoiceMapFromFile[key]
end

local function writeElevenLabsVoiceMap()
	writeKeyValueMap(elevenLabsVoiceMapPath, config.elevenLabsVoiceMap, elevenLabsVoiceMapKeys, {
		"# AI Voices ElevenLabs voice map",
		"# Paste ElevenLabs voice IDs after the equals sign.",
		"# Format: voiceKey=voiceId",
	})
end


--==================
-- ELEVENLABS PAGE
--==================

local elevenLabsPage = template:createSideBarPage({
	label = "ElevenLabs",
	description = "ElevenLabs uses online API voice generation. It requires your own API key and uses credits per generated line.",
})

elevenLabsPage:createTextField({
	label = "Model ID",
	description = "Example: eleven_multilingual_v2.",
	variable = mwse.mcm.createTableVariable({
		id = "elevenLabsModelId",
		table = config,
	}),
	callback = function()
		writeElevenLabsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

elevenLabsPage:createTextField({
	label = "Output Format",
	description = "Default: wav_22050. If your plan rejects this, check watcher_log.txt.",
	variable = mwse.mcm.createTableVariable({
		id = "elevenLabsOutputFormat",
		table = config,
	}),
	callback = function()
		writeElevenLabsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

elevenLabsPage:createSlider({
	label = "Stability",
	description = "Lower can be more expressive. Higher can be more stable. Default: 0.50",
	min = 0,
	max = 1,
	step = 0.01,
	jump = 0.05,
	decimalPlaces = 2,
	variable = mwse.mcm.createTableVariable({
		id = "elevenLabsStability",
		table = config,
	}),
	callback = function()
		writeElevenLabsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

elevenLabsPage:createSlider({
	label = "Similarity Boost",
	description = "Higher tries to stay closer to the selected voice. Default: 0.75",
	min = 0,
	max = 1,
	step = 0.01,
	jump = 0.05,
	decimalPlaces = 2,
	variable = mwse.mcm.createTableVariable({
		id = "elevenLabsSimilarityBoost",
		table = config,
	}),
	callback = function()
		writeElevenLabsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

elevenLabsPage:createSlider({
	label = "Style",
	description = "Higher can add more style/expression, depending on model and voice. Default: 0.00",
	min = 0,
	max = 1,
	step = 0.01,
	jump = 0.05,
	decimalPlaces = 2,
	variable = mwse.mcm.createTableVariable({
		id = "elevenLabsStyle",
		table = config,
	}),
	callback = function()
		writeElevenLabsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

elevenLabsPage:createYesNoButton({
	label = "Speaker Boost",
	description = "Boosts similarity to the original speaker. Default: On. May increase latency.",
	variable = mwse.mcm.createTableVariable({
		id = "elevenLabsUseSpeakerBoost",
		table = config,
	}),
	callback = function()
		writeElevenLabsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

elevenLabsPage:createCategory({
	label = "Generated Line Cache",
})

elevenLabsPage:createYesNoButton({
	label = "Cache Generated ElevenLabs Lines",
	description = "Stores ElevenLabs dialogue WAVs so repeated exact lines do not use more API credits. Default: Yes",
	variable = mwse.mcm.createTableVariable({
		id = "elevenLabsCacheGeneratedLines",
		table = config,
	}),
	callback = function()
		writeElevenLabsSettings()
		mwse.saveConfig("AIVoices", config)
		tes3.messageBox("AI Voices: ElevenLabs cache setting saved.")
	end,
})

elevenLabsPage:createSlider({
	label = "ElevenLabs Line Cache Limit MB",
	description = "Approximate size limit for generated ElevenLabs dialogue WAVs. Older cached lines are deleted first. Set to 0 for unlimited. Default: 500MB",
	min = 0,
	max = 5000,
	step = 100,
	jump = 500,
	variable = mwse.mcm.createTableVariable({
		id = "elevenLabsGeneratedCacheMaxMb",
		table = config,
	}),
	callback = function()
		writeElevenLabsSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

elevenLabsPage:createButton({
	label = "Clear ElevenLabs Generated Line Cache",
	description = "Deletes generated ElevenLabs dialogue WAVs from ElevenLabs\\cache\\generated_lines.",
	buttonText = "Clear Cache",
	callback = function()
		clearGeneratedCache("ElevenLabs", [[Data Files\AIVoicesBackend\ElevenLabs\cache\generated_lines]])
	end,
})

elevenLabsPage:createCategory({
	label = "Generation Settings",
})

elevenLabsPage:createButton({
	label = "Reset ElevenLabs Generation Defaults",
	description = "Resets ElevenLabs generation settings to default values. Does not change cache settings, model ID, output format, API key, or voice maps.",
	buttonText = "Reset Defaults",
	callback = function()
		resetElevenLabsGenerationSettings()
	end,
})

elevenLabsPage:createTextField({
	label = "Voice Map File",
	description = "Only voice keys listed in this file are shown below.",
	variable = mwse.mcm.createTableVariable({
		id = "elevenLabsVoiceMapPath",
		table = config,
	}),
})

if #elevenLabsVoiceMapKeys == 0 then
	elevenLabsPage:createInfo({
		text = "No ElevenLabs voice IDs found. Run the installer or add entries to ElevenLabs\\elevenlabs_voice_map.txt.",
	})
else
	elevenLabsPage:createCategory({
		label = "Voice IDs",
	})

	for _, voiceKey in ipairs(elevenLabsVoiceMapKeys) do
		elevenLabsPage:createTextField({
			label = getVoiceKeyLabel(voiceKey),
			description = "ElevenLabs voice ID for voice key: " .. tostring(voiceKey),
			variable = mwse.mcm.createTableVariable({
				id = voiceKey,
				table = config.elevenLabsVoiceMap,
			}),
			callback = function()
				writeElevenLabsVoiceMap()
				mwse.saveConfig("AIVoices", config)
			end,
		})
	end
end


--==================
-- PIPER VOICE MAP HELPERS
--==================

local function getPiperVoiceMapPath()
	return config.piperVoiceMapPath
		or [[Data Files\AIVoicesBackend\Piper\piper_voice_map.txt]]
end

local piperVoiceMapPath = getPiperVoiceMapPath()
local piperVoiceMapFromFile = readKeyValueMap(piperVoiceMapPath)
local piperVoiceMapKeys = buildOrderedKeys(piperVoiceMapFromFile, preferredVoiceKeyOrder)

config.voiceMap = {}

for _, key in ipairs(piperVoiceMapKeys) do
	config.voiceMap[key] = piperVoiceMapFromFile[key]
end

local function writePiperVoiceMap()
	writeKeyValueMap(piperVoiceMapPath, config.voiceMap, piperVoiceMapKeys, {
		"# AI Voices Piper voice map",
		"# Place .onnx and matching .onnx.json files in Piper\\voices.",
		"# Format: voiceKey=relative path from AIVoices folder",
	})
end


--==================
-- PIPER PAGE
--==================

local piperPage = template:createSideBarPage({
	label = "Piper",
	description = "Piper is local TTS using .onnx voice files. Only voice keys listed in piper_voice_map.txt are shown here.",
})

piperPage:createCategory({
	label = "Generation Settings",
})

piperPage:createButton({
	label = "Reset Piper Generation Defaults",
	description = "Resets Piper generation settings to default values. Does not change cache settings or voice maps.",
	buttonText = "Reset Defaults",
	callback = function()
		resetPiperGenerationSettings()
	end,
})

piperPage:createSlider({
	label = "Noise Scale",
	description = "Controls Piper voice variation. Lower is flatter/cleaner. Higher is more varied and can get weird. Default: 0.667",
	min = 0,
	max = 1,
	step = 0.01,
	jump = 0.05,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable({
		id = "piperNoiseScale",
		table = config,
	}),
	callback = function()
		writePiperSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

piperPage:createSlider({
	label = "Noise W",
	description = "Controls Piper phoneme/timing variation. Lower is steadier. Higher is more varied. Default: 0.333",
	min = 0,
	max = 1,
	step = 0.01,
	jump = 0.05,
	decimalPlaces = 3,
	variable = mwse.mcm.createTableVariable({
		id = "piperNoiseWScale",
		table = config,
	}),
	callback = function()
		writePiperSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

piperPage:createSlider({
	label = "Sentence Silence",
	description = "Pause between sentences in seconds. Default: 0.20",
	min = 0,
	max = 2,
	step = 0.05,
	jump = 0.25,
	decimalPlaces = 2,
	variable = mwse.mcm.createTableVariable({
		id = "piperSentenceSilence",
		table = config,
	}),
	callback = function()
		writePiperSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

piperPage:createCategory({
	label = "Generated Line Cache",
})

piperPage:createYesNoButton({
	label = "Cache Generated Piper Lines",
	description = "Stores generated Piper dialogue WAVs so repeated exact lines can play faster. Default: No",
	variable = mwse.mcm.createTableVariable({
		id = "piperCacheGeneratedLines",
		table = config,
	}),
	callback = function()
		writePiperSettings()
		mwse.saveConfig("AIVoices", config)
		tes3.messageBox("AI Voices: Piper cache setting saved.")
	end,
})

piperPage:createSlider({
	label = "Piper Line Cache Limit MB",
	description = "Approximate size limit for generated Piper dialogue WAVs. Older cached lines are deleted first. Set to 0 for unlimited. Default: 500MB",
	min = 0,
	max = 5000,
	step = 100,
	jump = 500,
	variable = mwse.mcm.createTableVariable({
		id = "piperGeneratedCacheMaxMb",
		table = config,
	}),
	callback = function()
		writePiperSettings()
		mwse.saveConfig("AIVoices", config)
	end,
})

piperPage:createButton({
	label = "Clear Piper Generated Line Cache",
	description = "Deletes generated Piper dialogue WAVs from Piper\\cache\\generated_lines.",
	buttonText = "Clear Cache",
	callback = function()
		clearGeneratedCache("Piper", [[Data Files\AIVoicesBackend\Piper\cache\generated_lines]])
	end,
})

piperPage:createCategory({
	label = "Voice Map Files",
})

piperPage:createTextField({
	label = "Piper Voice Map File",
	description = "Only voice keys listed in this file are shown below.",
	variable = mwse.mcm.createTableVariable({
		id = "piperVoiceMapPath",
		table = config,
	}),
})

if #piperVoiceMapKeys == 0 then
	piperPage:createInfo({
		text = "No Piper voice entries found. Run the installer or add entries to Piper\\piper_voice_map.txt.",
	})
else
	piperPage:createCategory({
		label = "Voice Files",
	})

	for _, voiceKey in ipairs(piperVoiceMapKeys) do
		piperPage:createTextField({
			label = getVoiceKeyLabel(voiceKey),
			description = "Piper .onnx path for voice key: " .. tostring(voiceKey),
			variable = mwse.mcm.createTableVariable({
				id = voiceKey,
				table = config.voiceMap,
			}),
			callback = function()
				writePiperVoiceMap()
				mwse.saveConfig("AIVoices", config)
			end,
		})
	end
end




--==================
-- WATCHER PAGE
--==================

local watcherPage = template:createSideBarPage({
	label = "Watcher",
	description = "Settings for launching and monitoring watcher.py.",
})

watcherPage:createYesNoButton({
	label = "Show Watcher Console",
	description = "If enabled, the AI Voices watcher opens in a visible console window. If disabled, it runs hidden in the background. Applies next watcher start.",
	variable = mwse.mcm.createTableVariable({
		id = "showWatcherConsole",
		table = config,
	}),
	callback = saveAndReloadConfig,
})

watcherPage:createYesNoButton({
	label = "Keep Watcher Console Open",
	description = "If enabled, the visible watcher console stays open after watcher.py exits. Useful for debugging errors. Only applies when Show Watcher Console is enabled. Applies next watcher start.",
	variable = mwse.mcm.createTableVariable({
		id = "watcherConsoleStaysOpen",
		table = config,
	}),
	callback = saveAndReloadConfig,
})

watcherPage:createTextField({
	label = "Python Command",
	description = "Usually the local venv python created by install_aivoices.bat. Applies next watcher start.",
	variable = mwse.mcm.createTableVariable({
		id = "pythonCommand",
		table = config,
	}),
	callback = saveAndReloadConfig,
})

watcherPage:createTextField({
	label = "Watcher Script Path",
	description = "Path to watcher.py. Applies next watcher start.",
	variable = mwse.mcm.createTableVariable({
		id = "watcherPath",
		table = config,
	}),
	callback = saveAndReloadConfig,
})

watcherPage:createTextField({
	label = "Installer Marker File",
	description = "If this file is missing, AI Voices treats the voice engine as not installed.",
	variable = mwse.mcm.createTableVariable({
		id = "installerMarkerPath",
		table = config,
	}),
	callback = saveAndReloadConfig,
})

watcherPage:createTextField({
	label = "Heartbeat File",
	variable = mwse.mcm.createTableVariable({
		id = "heartbeatPath",
		table = config,
	}),
	callback = saveAndReloadConfig,
})

watcherPage:createSlider({
	label = "Heartbeat Interval",
	description = "How often MWSE updates heartbeat.txt.",
	min = 1,
	max = 10,
	step = 1,
	jump = 1,
	variable = mwse.mcm.createTableVariable({
		id = "heartbeatInterval",
		table = config,
	}),
	callback = saveAndReloadConfig,
})


--==================
-- REGISTER
--==================

writeXttsSettings()
writeElevenLabsSettings()
writePiperSettings()
writeVoiceVolume()
writeSpeechSpeed()

mwse.mcm.register(template)
return {
    setReloadCallback = setReloadCallback,
}