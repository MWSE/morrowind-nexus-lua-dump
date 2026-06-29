--==================
-- DEFAULT CONFIG
--==================

local config = {
	enabled = true,

	showMessages = true,
	debugLog = false,
	showWatcherConsole = true,
	watcherConsoleStaysOpen = false,
	voiceVolume = 50,
	speechSpeed = 1.00,
	--==================
	-- RUNTIME FILES
	--==================
	
	outputPath = [[Data Files\AIVoicesBackend\runtime\dialogue.txt]],
	voiceOutputPath = [[Data Files\AIVoicesBackend\runtime\voice.txt]],
	stopOutputPath = [[Data Files\AIVoicesBackend\runtime\stop.txt]],
	statusOutputPath = [[Data Files\AIVoicesBackend\runtime\status.txt]],
	speechSpeedOutputPath = [[Data Files\AIVoicesBackend\settings\speech_speed.txt]],
	
	--==================
	-- PRONUNCIATION
	--==================

	pronunciationMapPath = [[Data Files\AIVoicesBackend\settings\pronunciation.txt]],

	--==================
	-- WATCHER
	--==================

	pythonCommand = [[Data Files\AIVoicesBackend\dependencies\aivoices-venv\Scripts\python.exe]],
	watcherPath = [[Data Files\MWSE\mods\AIVoices\watcher.py]],
	watcherHeartbeatPath = [[Data Files\AIVoicesBackend\runtime\watcher_heartbeat.txt]],
	heartbeatPath = [[Data Files\AIVoicesBackend\runtime\heartbeat.txt]],
	heartbeatInterval = 2,

	installerMarkerPath = [[Data Files\AIVoicesBackend\install_markers\aivoices_installed.txt]],

	--==================
	-- TTS ENGINE
	--==================

	ttsEngine = "xtts", -- "piper", "elevenlabs", or "xtts"
	ttsEngineOutputPath = [[Data Files\AIVoicesBackend\settings\tts_engine.txt]],
	voiceVolumeOutputPath = [[Data Files\AIVoicesBackend\settings\voice_volume.txt]],

	--==================
	-- XTTS
	--==================

	xttsReferenceMapPath = [[Data Files\AIVoicesBackend\XTTS\xtts_reference_map.txt]],
	xttsSettingsPath = [[Data Files\AIVoicesBackend\settings\xtts_settings.txt]],

	xttsCacheGeneratedLines = false,
	xttsGeneratedCacheMaxMb = 500,

	xttsTemperature = 0.65,
	xttsRepetitionPenalty = 2.0,
	xttsTopK = 50,
	xttsTopP = 0.85,

	--==================
	-- PIPER
	--==================

	piperVoiceMapPath = [[Data Files\AIVoicesBackend\Piper\piper_voice_map.txt]],
	piperSettingsPath = [[Data Files\AIVoicesBackend\Piper\piper_settings.txt]],

	piperCacheGeneratedLines = false,
	piperGeneratedCacheMaxMb = 500,

	piperNoiseScale = 0.667,
	piperNoiseWScale = 0.333,
	piperSentenceSilence = 0.20,
	--==================
	-- ELEVENLABS
	--==================

	elevenLabsApiKeyOutputPath = [[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_api_key.txt]],
	elevenLabsVoiceMapPath = [[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_voice_map.txt]],
	elevenLabsModelIdOutputPath = [[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_model_id.txt]],
	elevenLabsOutputFormatPath = [[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_output_format.txt]],
	elevenLabsSettingsPath = [[Data Files\AIVoicesBackend\ElevenLabs\elevenlabs_settings.txt]],

	elevenLabsModelId = "eleven_multilingual_v2",
	elevenLabsOutputFormat = "wav_22050",

	elevenLabsStability = 0.50,
	elevenLabsSimilarityBoost = 0.75,
	elevenLabsStyle = 0.00,
	elevenLabsUseSpeakerBoost = true,
	elevenLabsCacheGeneratedLines = true,
	elevenLabsGeneratedCacheMaxMb = 500,

}

return config