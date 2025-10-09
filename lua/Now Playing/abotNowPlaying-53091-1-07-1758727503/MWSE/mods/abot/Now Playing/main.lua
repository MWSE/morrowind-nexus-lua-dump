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
assert(config)

local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local function updateFromConfig()
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
end
updateFromConfig()

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
	local result = s
	if s then
		local s2 = back2slash(s)
		result = s2:gsub("[Dd]ata [Ff]iles/[Mm]usic/", "")
	end
	if logLevel3 then
		mwse.log('%s: stripPath("%s") = "%s"', modPrefix, s, result)
	end
	return result
end


local function getStrippedTrack()
	local result = getTrack()
	if result then
		result = stripPath(result)
		if logLevel2 then
			mwse.log('%s: getStrippedTrack() = "%s"', modPrefix, result)
		end
	end
	return result
end


local function getFileNameAndExtension(s)
	local result
	if s then
		result = back2slash(s):match("([^/]-%.[^/]+)$")
	end
	if logLevel1 then
		mwse.log('%s: getFileNameAndExtension("%s") = "%s"', modPrefix, s, result)
	end
	return result
end


local function urlEncode(s)
	local result
	if s then
		local s2 = s:gsub("\n", "\r\n")
		local s3 = s2:gsub("([^%w %-%_%.%~])",
			function(c)
				return string.format( "%%%02X", string.byte(c) )
			end
		)
		result = s3:gsub(" ", "+")
	end
	if logLevel1 then
		mwse.log('%s: urlEncode("%s") = "%s"', modPrefix, s, result)
	end
	return result
end


local function getSearchURL(s)
	local result
	if s then
		result = "https://duckduckgo.com/?q=" .. urlEncode(s)
	end
	if logLevel1 then
		mwse.log('%s: getSearchURL("%s") = "%s"', modPrefix, s, result)
	end
	return result
end


local lastTrack

local function timerCallback()
	local s = getStrippedTrack()
	if not s then
		return
	end
	if s == lastTrack then
		return
	end
	lastTrack = s
	if logLevel3 then
		mwse.log('%s: timerCallback("%s")',	modPrefix, s)
	end
	--[[
	if tes3ui.menuMode() then
		return
	end
	]]
	if config.logTracks then
		mwse.log("%s: %s Current Track: %s", modPrefix, os.date(), s)
	end
	if config.printTracks
	and ( not tes3.menuMode() ) then
		s = modName .. ':\n"' .. s .. '"'
		--- nope sometimes crashing tes3.messageBox({message = s, showInDialog = false})
		---local el = tes3.messageBox(s)
		local el = tes3ui.showNotifyMenu(s)
		if el
		and ( not (el.wrapText == nil) ) then
			el.wrapText = true
			el:updateLayout()
		end
	end
end


local function musicChangeTrack()
	if logLevel3 then
		mwse.log('%s: musicChangeTrack()', modPrefix)
	end
	timer.start({type = timer.real, duration = 1.5, callback = timerCallback})
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end


local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		updateFromConfig()
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
		buttonText = 'Skip Current Track',
		callback = function()
			mge.macros.nextTrack()
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
				mwse.log('%s: Open Current Track %s', modPrefix, s2)
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

			s = back2slash(s)
			local folder, _, _ = string.match(s, "(.-)([^/]-%.?([^%./]*))$")
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
			if s3 then
				os.openURL(s3)
			end
		end
	}

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

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
event.register('modConfigReady', modConfigReady)

event.register('initialized', function ()
	event.register('musicChangeTrack', musicChangeTrack, {priority = 1000})
end, {doOnce = true})