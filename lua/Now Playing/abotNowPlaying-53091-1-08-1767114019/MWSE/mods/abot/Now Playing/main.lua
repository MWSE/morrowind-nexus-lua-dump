-- Info about current playing music track

local defaultConfig = {
logTracks = false,
printTracks = false,
logLevel = 0,
}

local author = 'abot'
local modName = 'Now Playing'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = configName:gsub(' ', '_')
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

-- local function notify(str, ...)
-- 	if not tes3.menuMode() then
-- 		tes3.messageBox(tostring(str):format(...))
-- 	end
-- end

local function getTrack()
	-- e.g. Data Files/Music/Explore/foo.mp3
	-- max 260 characters!
	local s = tes3.worldController.audioController.currentMusicFilePath
	if logLevel3 then
		mwse.log('%s: getTrack() = "%s"', modPrefix, s)
	end
	return s
end

---@param s string
local function back2slash(s)
	return s:gsub([[\]], [[/]])
end


---@param s string?
---@return string?
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


---@return string?
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


---@param s string?
---@return string?
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

local string_byte = string.byte

---@param s string?
---@return string?
local function urlEncode(s)
	local result
	if s then
		local s2 = s:gsub("\n", "\r\n")
		local s3 = s2:gsub("([^%w %-%_%.%~])",
			function(c)
				return ("%%%02X"):format(string_byte(c) )
			end
		)
		result = s3:gsub(" ", "+")
	end
	if logLevel1 then
		mwse.log('%s: urlEncode("%s") = "%s"', modPrefix, s, result)
	end
	return result
end


---@param s string?
---@return string?
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


local lastTrack ---@type string?

local canNotify = true

local function ab01nwplyPT1()
	canNotify = true
end

local function timerCallback()
	local s = getStrippedTrack()
	if not s then
		return
	end
	if s:lower():match('silence[^%.]-%.%w+$') then
		return
	end
	if s == lastTrack then
		return
	end
	lastTrack = s
	if logLevel3 then
		mwse.log('%s: timerCallback("%s")', modPrefix, s)
	end
	if config.logTracks then
		mwse.log("%s: %s Current Track: %s", modPrefix, os.date(), s)
	end
	if config.printTracks
	and canNotify
	and ( not tes3.menuMode() ) then
 -- important on persistent timer as during combat music situation could change
 -- too fast and cause messageboxes to crash
		canNotify = false
		timer.start({type = timer.real, duration = 5, callback = 'ab01nwplyPT1'})
		s = modName .. ':\n"' .. s .. '"'
		local el = tes3ui.showNotifyMenu(s)
		if el
		and (el.wrapText == false) then
			el.wrapText = true
---mwse.log(">>> 3")
			el:updateLayout()
		end
	end
end

local situations = table.invert(tes3.musicSituation)

local function musicChangeTrack(e)
	if logLevel3 then
		mwse.log('%s: musicChangeTrack() situation = %s music = "%s"',
			modPrefix, situations[e.situation], e.music)
	end
	timer.start({type = timer.real, duration = 1.5, callback = timerCallback})
end

local function modConfigReady()

	local function onClose()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		label = modName,
		showHeader = false,
		description = [[Shows/manages Current Music Track.
Note: max length of a music file path managed by related MWSE-Lua function is 260 characters, so (especially if you are using some music overhaul mod) you should not use longer/heavily nested paths for your music folders/file paths.
]],
		postCreate = function(self)
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	sideBarPage:createInfo({text = 'Current Music Track:'})
	local infoTrack = sideBarPage:createInfo({
		text = getTrack(),
		inGameOnly = true,
		postCreate = function(self)
			self.elements.info.text = getStrippedTrack()
		end
	})

	sideBarPage:createButton({
		buttonText = 'Update Current Track',
		inGameOnly = true,
		callback = function()
			local s = getStrippedTrack()
			if infoTrack then
				infoTrack.elements.info.text = s
			end
		end
	})

	sideBarPage:createButton({
		buttonText = 'Skip Current Track',
		callback = function()
			mge.macros.nextTrack()
		end
	})

	sideBarPage:createButton({
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
	})

	sideBarPage:createButton({
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
	})

	sideBarPage:createButton({
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
-- https://stackoverflow.com/questions/5243179/what-is-the-neatest-way-to-split-out-a-path-name-into-its-components-in-lua

			s = back2slash(s)
			local folder, _, _ = string.match(s, "(.-)([^/]-%.?([^%./]*))$")
			---mwse.log("folder = %s", folder)
			s = string.format('"%s/Data Files/Music/%s"', tes3.installDirectory, folder)
			s = s:gsub("/", "\\")
			s = "explorer "..s
			if logLevel4 then
				mwse.log('%s: Open Current Track Folder %s', modPrefix, s)
			end
			os.execute(s)
		end
	})

	sideBarPage:createButton({
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
	})

	sideBarPage:createYesNoButton({
		label = 'Log Tracks',
		description = 'Log tracks to MWSE.log.',
		configKey = 'logTracks'
	})

	sideBarPage:createYesNoButton({
		label = 'Show Tracks',
		description = [[Show track name message on track change.]],
		configKey = 'printTracks'
	})

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Max'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = ('%s. %s'):format(i - 1,
				optionList[i]), value = i - 1}
		end
		return options
	end

	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)


event.register('initialized', function ()
	timer.register('ab01nwplyPT1', ab01nwplyPT1)
	event.register('musicChangeTrack', musicChangeTrack, {priority = 1000})
end, {doOnce = true})