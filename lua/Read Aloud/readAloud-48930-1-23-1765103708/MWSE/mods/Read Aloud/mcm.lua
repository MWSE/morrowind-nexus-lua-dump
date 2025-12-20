---@diagnostic disable: redundant-parameter
local modPrefix = 'Read Aloud'
local cmn = require(modPrefix .. '.common')

local skillModule = include('OtherSkills.skillModule')

local mcmName = cmn.mcmName
local config = cmn.config
local configName = cmn.configName
local defaultConfig = cmn.defaultConfig

--[[local function logConfig(cfg, options)
	mwse.log(json.encode(cfg, options))
end]]

local string_format = string.format

local function modConfigReady()

	local function onClose()
		local player = tes3.player
		if player then
			cmn.playerSpeechParams = cmn.getSpeechParamsForReference(player)
		end
		mwse.saveConfig(configName, config, {indent = false})
	end
	
	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	-- Preferences Page
	local sideBarPage = template:createSideBarPage({
		description = mcmName .. "\n\nby " .. cmn.author,
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.2
			self.elements.sideToSideBlock.children[2].widthProportional = 0.8
		end
	})

	local controls = sideBarPage:createCategory(
		{label = 'What do you want to read today?\n'})

	controls:createSlider({
		label = 'Volume',
		description = 'Reading Volume',
		configKey = 'volume'
		,min = 0, max = 100, step = 1, jump = 5
	})
	
	controls:createSlider{
		label = 'Reading Speed Variance',
		description = 'Reading Speed Variance',
		configKey = 'speedDelta'
		,min = -5, max = 5, step = 1, jump = 1
	}
	
	local voices = cmn.getVoices()
	if voices then
		local count = #voices
		if count > 0 then
			local s = 'Detected voices:'
			for i = 1, count do
				s = s .. string_format("\n%s. %s", i, voices[i])
			end
			controls:createInfo{text = s}
		end
	end
	
	controls:createDropdown({
		label = 'Language Code:',
		description = [[The Microsoft SAPI language code used to select voices.
	Note: you must have at least one male and one female voices detected/installed and working for that language code.
	Not all voices may work, for instance I have installed all the listed voices, but only the US and UK voices seem to work in my setup.
	1.  409 English (United States) e.g. Zira, David, Mark.
	2.  809 English (United Kingdom) e.g. George, Hazel.
	3.  C09 English (Australia) e.g. James, Catherine.
	4. 1009 English (Canada) e.g. Richard, Linda.
	5. 4009 English (India) e.g. Ravi, Heera.
	6.  410 Italian e.g. Microsoft Elsa.
	7.  C0A Spanish.]],
		options = {
			{ label = "1.  409 English (United States)", value = 1 },
			{ label = "2.  809 English (United Kingdom)", value = 2 },
			{ label = "3.  C09 English (Australia)", value = 3 },
			{ label = "4. 1009 English (Canada)", value = 4 },
			{ label = "5. 4009 English (India)", value = 5 },
			{ label = "6.  410 Italian", value = 6 },
			{ label = "7.  C0A Spanish", value = 7 },
		},
		configKey = 'language'
	})
	
	controls:createOnOffButton({
		label = 'Use only player voice',
		description = [[Use only player voice even when reading NPCs dialog.
If you disable this option then first available female and male voices installed
in your system will be used, with different pitch according to speaker race/sex.
IMO only worth if you are lucky and have good quality voices installed for both genders.
You decide.]],
		configKey = 'useOnlyPlayerVoice'
	})
	
	controls:createOnOffButton({
		label = 'Keep reading on menu close',
		description = 'Toggles automatic read stopping when you close a menu.',
		configKey = 'keepReadingOnMenuClose'
	})
	
	controls:createKeyBinder({
		label = 'Stop reading Hotkey', allowCombinations = true,
		description = [[A quick key combination you can press/release to stop reading
(some Alt combo is suggested to avoid interfering with normal text writing).]],
		variable = mwse.mcm:createTableVariable({
			id = 'stopReadingKey', table = config,
			defaultSetting = cmn.defaultConfig.stopReadingKey,
			restartRequired = false,
		})
	})

	controls:createDropdown({
		label = "Read Books & Scrolls:",
		description = [[Read Books & Scrolls options.
	3. will start reading pages(s) on opening and pressing links and buttons.
	2. will start reading pages(s) on pressing links and buttons.
	1. will require to press the Read buttons.
	0. Disabled.
	1. Enabled.
	2. Enabled, On Link Click.
	3. Enabled, On Link Click, Automatic.]],
		options = {
		{ label = "0. Disabled", value = 0 },
		{ label = "1. Enabled", value = 1 },
		{ label = "2. Enabled, On Link Click", value = 2 },
		{ label = "3. Enabled, On Link Click, Automatic", value = 3 }
		},
		configKey = 'readBooksScrolls'
	})

	controls:createDropdown({
		label = "Read Journal:",
		description = [[Read Journal options.\n4. will start reading page(s) on opening and pressing links and buttons.
	3. will start reading last journal entry on opening, read page(s) on pressing links and buttons.
	2. will start reading page(s) on pressing links and buttons.
	1. will require to press the Read buttons.
	0. Disabled.
	1. Enabled.
	2. Enabled, On Link Click.
	3. Enabled, On Link Click, Last jornal entry.
	4. Enabled, On Link Click, Automatic.]],
		options = {
		{ label = "0. Disabled", value = 0 },
		{ label = "1. Enabled", value = 1 },
		{ label = "2. Enabled, On Link Click", value = 2 },
		{ label = "3. Enabled, On Link Click, Last entry", value = 3 },
		{ label = "4. Enabled, On Link Click, Automatic", value = 4 },
		},
		configKey = 'readJournal'
	})

	controls:createOnOffButton({
		label = 'Read updated Journal entry',
		description = 'You can read last updated Journal entry aloud.',
		configKey = 'readLastJournal'
	})
	controls:createOnOffButton({
		label = 'Read dialog choices',
		description = 'You can read your selected dialog choice aloud.',
		configKey = 'readDialogChoice'
	})

	controls:createOnOffButton({
		label = 'Alt + click to skip reading topics',
		description = "Alt + click a topic to skip reading it.",
		configKey = 'altClickTopic'
	})

	local disclaimer = [[
If you are not using good quality voices you may want to activate some of these options only if you are not comfortable reading unvoiced dialog
 (or maybe if you are a streamer trying to spare some reading).]]

	controls:createDropdown({
		label = 'Read dialog topics',
		description = [[Read dialog topics aloud.
0. Disabled.
1. Read dialog topic.
2. Read dialog topic, header.
3. Read dialog topic, header, notify.
4. Read dialog topic, header, notify, persuasion/service.]] .. disclaimer,
		options = {
			{ label = "0. Disabled", value = 0 },
			{ label = "1. Read dialog topic", value = 1 },
			{ label = "2. Read dialog topic, header", value = 2 },
			{ label = "3. Read dialog topic, header, notify", value = 3 },
			{ label = "4. Read dialog topic, header, notify, persuasion/service", value = 4 },
		},
		configKey = 'readDialog'
	})

	controls:createOnOffButton({
		label = 'Read dialog greetings',
		description = [[Read dialog greetings aloud.
Usually it works well enough, but it may fail detecting some sounds played from actors on greeting and overlap with them.
As usual, try and decide.
]] .. disclaimer,
		configKey = 'readGreeting'
	})

	local optionList = {'Off','Low','Some','Medium','High','Max'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string_format('%s. %s',
				i - 1, optionList[i]), value = i - 1}
		end
		return options
	end
	
	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	controls:createOnOffButton({
		label = 'Read Signs',
		description = 'Read signs, banners and road markers aloud.',
		configKey = 'readSigns'
	})
	
	controls:createOnOffButton({
		label = 'Daedric Translation',
		description = [[Show translated Daedric text from enchanted scrolls.
	If the Daedric skill is enabled only already known Daedric letters will be visible.]],
		configKey = 'daedricTranslation'
	})
	
	controls:createOnOffButton({
		label = 'Read Daedric Translation',
		description = [[Read translated Daedric text from enchanted scrolls."
If the Daedric skill is enabled only already known Daedric letters will be read.]],
		configKey = 'readDaedricTranslation'
	})
	
	if skillModule then
		controls:createOnOffButton({
			label = 'Daedric Skill',
			description = [[The Daedric Skill determines your effectiveness at reading and translating Daedric text in enchanted scrolls.
To increase the skill, try to read and translate some enchanted scrolls.
Books with identifier starting with "bk_daedric_" are considered Daedric skillbooks.
Note: on/off changes are effective on reload.]],
			configKey = 'daedricSkill'
		})
	end

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})
end

event.register('modConfigReady', modConfigReady)