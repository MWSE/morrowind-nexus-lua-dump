--[[
Info about current playing music track
--]]

-- begin configurable parameters
local defaultConfig = {
logTracks = false,
printTracks = false,
logLevel = 0,
}
-- end configurable parameters

local author = 'abot'
local modName = 'Now Playing'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local logLevel = config.logLevel
local logLevel1 = logLevel >= 1
local logLevel2 = logLevel >= 2
local logLevel3 = logLevel >= 3
local logLevel4 = logLevel >= 4


local function getTrack()
	-- e.g. Data Files/Music/Explore/foo.mp3
	-- max 260 characters!
	local s = tes3.worldController.audioController.currentMusicFilePath
	if logLevel3 then
		mwse.log('%s: getTrack() = "%s"', modPrefix, s)
	end
	return s
end


local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end


local function stripPath(s)
	local result
	if s then
		local s2 = back2slash(s)
		result = string.gsub(s2, "[Dd]ata [Ff]iles/[Mm]usic/", "")
	end
	if logLevel3 then
		mwse.log('%s: stripPath("%s") = "%s"', modPrefix, s, result)
	end		
	return result
end


local function getStrippedTrack()
	local s = getTrack()
	local result = stripPath(s)
	if logLevel2 then
		mwse.log('%s: getStrippedTrack() = "%s"', modPrefix, result)
	end		
	return result 
end


local function getFileNameAndExtension(s)
	local result
	if s then
		result = string.match(back2slash(s), "([^/]-%.[^/]+)$")
	end
	if logLevel1 then
		mwse.log('%s: getFileNameAndExtension("%s") = "%s"', modPrefix, s, result)
	end		
	return result
end


local function urlEncode(s)
	local result
	if s then
		local s2 = string.gsub(s, "\n", "\r\n")
		local s3 = string.gsub(s2, "([^%w %-%_%.%~])",
			function(c)
				return string.format( "%%%02X", string.byte(c) )
			end
		)
		result = string.gsub(s3, " ", "+")
	end
	if logLevel1 then
		mwse.log('%s: urlEncode("%s") = "%s"', modPrefix, s, result)
	end		
	return result
end


local function getSearchURL(s)
	local result
	if s then
		result = string.format("https://duckduckgo.com/?q=%s", urlEncode(s))
	end
	if logLevel1 then
		mwse.log('%s: getSearchURL("%s") = "%s"', modPrefix, s, result)
	end		
	return result
end


local lastTrack = ''
local function loaded()
	lastTrack = ''
end
event.register('loaded', loaded)


local function timerCallback()
	local s = getStrippedTrack()
	if not s then
		return
	end
	if logLevel3 then
		mwse.log('%s: timerCallback() s = "%s", lastTrack = "%s"',
			modPrefix, s, lastTrack)
	end
	if lastTrack == s then
		return
	end
	lastTrack = s
	--[[
	if tes3ui.menuMode() then
		return
	end
	]]
	if config.printTracks then
		---tes3.messageBox('%s:\r\n%s', modName, s)
		tes3ui.showNotifyMenu('%s:\r\n"%s"', modName, s)
	end
	if config.logTracks then
		mwse.log("%s: %s Current Track: %s", modPrefix, os.date(), s)
	end
end


local function musicSelectTrack()
	if logLevel3 then
		mwse.log('%s: musicSelectTrack()', modPrefix)
	end
	timer.start({type = timer.real, duration = 1.5,
		iterations = 1, callback = timerCallback}
	)
end


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end


local yesOrNo = {[false] = 'No', [true] = 'Yes'}

local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		logLevel = config.logLevel
		logLevel1 = logLevel >= 1
		logLevel2 = logLevel >= 2
		logLevel3 = logLevel >= 3
		logLevel4 = logLevel >= 4
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo({
		text = [[Shows/manages Current Music Track.
Note: max length of a music file path managed by related MWSE-Lua function is 260 characters, so (especially if you are using some music overhaul mod) you should not use longer/heavily nested paths for your music folders/file paths.
]]
	})

	---local controls = preferences:createCategory{label = mcmName}
	local controls = preferences:createCategory({})

	controls:createInfo({text = 'Current Music Track:'})
	local infoTrack = controls:createInfo({
		text = getTrack(),
		inGameOnly = true,
		postCreate = function(self)
			self.elements.info.text = getStrippedTrack()
		end
	})

	controls:createButton{
		buttonText = 'Update Current Track',
		inGameOnly = true,
		callback = function()
			local s = getStrippedTrack()
			if infoTrack then
				infoTrack.elements.info.text = s
			end
		end
	}

	controls:createButton{
		buttonText = 'Open Current Track',
		inGameOnly = true,
		callback = function()
			if not infoTrack then
				return
			end
			local s = infoTrack.elements.info.text
			if not s then
				return
			end
			local s2 = string.format('"%s/Data Files/Music/%s"', tes3.installDirectory, s)
			if logLevel4 then
				mwse.log('%s: Open Current Track "%s"', modPrefix, s2)
			end
			os.execute(s2)
		end
	}

	controls:createButton{
		buttonText = 'Copy Current Track to Windows clipboard',
		inGameOnly = true,
		callback = function()
			if not infoTrack then
				return
			end
			local s = infoTrack.elements.info.text
			if not s then
				return
			end
			if logLevel4 then
				mwse.log('%s: Copy Current Track "%s"', modPrefix, s)
			end
			os.setClipboardText(s) -- copy track path to clipboard
		end
	}

	controls:createButton{
		buttonText = 'Open Current Track Folder',
		inGameOnly = true,
		callback = function()
			if not infoTrack then
				return
			end
			local s = infoTrack.elements.info.text
			if not s then
				return
			end
--[[
https://stackoverflow.com/questions/5243179/what-is-the-neatest-way-to-split-out-a-path-name-into-its-components-in-lua
--]]
			local folder, _, _ = string.match(s, "(.-)([^\\/]-%.?([^%.\\/]*))$")
			---mwse.log("folder = %s", folder)
			s = string.format('"%s/Data Files/Music/%s"', tes3.installDirectory, folder)
			s = string.gsub(s, "/", "\\")
			s = string.format("explorer %s", s)
			if logLevel4 then
				mwse.log('%s: Open Current Track Folder %s', modPrefix, s)
			end
			os.execute(s)
		end
	}

	controls:createButton{
		buttonText = 'Internet Search for Current Track',
		inGameOnly = true,
		callback = function()
			if not infoTrack then
				return
			end
			local s = infoTrack.elements.info.text
			if not s then
				return
			end
			local s2 = getFileNameAndExtension(s)
			local s3 = getSearchURL(s2)
			if logLevel4 then
				mwse.log('%s: Internet Search for Current Track "%s"', modPrefix, s3)
			end
			os.openURL(s3)
		end
	}
	
	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createYesNoButton({
		label = 'Log Tracks',
		description = getYesNoDescription([[Default: %s.
Log tracks to MWSE.log.]], 'logTracks'),
		variable = createConfigVariable('logTracks')
	})

	controls:createYesNoButton({
		label = 'Show Tracks',
		description = getYesNoDescription([[Default: %s.
Show track name message on track change.]], 'printTracks'),
		variable = createConfigVariable('printTracks')
	})

	controls:createDropdown({
		label = "Logging level:",
		options = {
			{ label = "0. Off", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
			{ label = "4. Max", value = 4 },
		},
		variable = createConfigVariable("logLevel"),
		description = [[Logging level. Default: 0. Off.]]
	})

	mwse.mcm.register(template)

end
event.register('musicSelectTrack', musicSelectTrack)
event.register('modConfigReady', modConfigReady)

--[[
musicSelectTrack
The musicSelectTrack event occurs when new music is needed after a playing music track ends, or the combat situation changes.
It allows you to select your own music for the current conditions by setting eventData.music. However, it does not control transitions
to combat music, which in the future will be available in another event.
Event Data
music: string. If set to the path of a given track (relative to Data Files/music), it will play the given path instead of a random one.
situation: number. Read-only. Maps to tes3.musicSituation.*, indicating combat or non-combat music.
--]]
