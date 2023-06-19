--[[
Info about current playing music track
--]]

-- begin configurable parameters
local defaultConfig = {
logTracks = false,
}
-- end configurable parameters

local author = 'abot'
local modName = 'Now Playing'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

-- 2nd parameter advantage: anything not defined in the loaded file inherits the value from my_default_config
local config = mwse.loadConfig(configName, defaultConfig)
assert(config)


local function getTrack()
	return tes3.worldController.audioController.currentMusicFilePath
end

local function stripPath(s)
	local result
	if s then
		result = string.gsub(s, "Data Files/Music/[^/]+/", "")
	end
	---mwse.log("stripPath(%s) --> %s", s, result)
	return result
end

local function urlEncode(s)
	local r = s:gsub("\n", "\r\n")
	r = r:gsub("([^%w %-%_%.%~])",
		function(c)
			return ("%%%02X"):format(string.byte(c))
		end
	)
	r = r:gsub(" ", "+")
	---mwse.log("urlEncode(%s) --> %s", s, r)
	return r
end

local function getSearchURL(s)
	local result = string.format("https://duckduckgo.com/?q=%s", urlEncode(s))
	---mwse.log("getSearchURL(%s) --> %s", s, result)
	return result
end

local lastTrack = ''
local function loaded()
	lastTrack = ''
end
event.register('loaded', loaded)

local function musicSelectTrack()
	timer.start({type = timer.real, duration = 1.5, iterations = 1, callback = function()
		local t = getTrack()
		if not t then
			return
		end
		local s = stripPath(t)
		if lastTrack == s then
			return
		end
		lastTrack = s
		if not tes3ui.menuMode() then
			if config.logTracks then
				mwse.log("%s, %s Current Track: %s", modPrefix, os.date(), s)
			end
		end
	end
	})
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	local sYes = tes3.findGMST(tes3.gmst.sYes).value
	local sNo = tes3.findGMST(tes3.gmst.sNo).value
	local template = mwse.mcm:createTemplate(mcmName)

	local page = template:createPage({})
	local categoryTrack = page:createCategory('Current Music Track:')

	local infoTrack = categoryTrack:createInfo({
		text = getTrack(),
		inGameOnly = true,
		postCreate = function(self)
			self.elements.info.text = getTrack()
		end
	})

	page:createButton{
		buttonText = 'Update Current Track',
		inGameOnly = true,
		callback = function()
			local t = getTrack()
			--- tes3.messageBox(  string.format( "Current Track:\n%s", stripPath(t) )  )
			if infoTrack then
				infoTrack.elements.info.text = t
			end
		end
	}

	page:createButton{
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
			s = string.format('"%s/%s"', tes3.installDirectory, s)
			s = string.gsub(s, "\\", "/")
			os.execute(s)
		end
	}

	page:createButton{
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
			s = string.format('"%s/%s"', tes3.installDirectory, s)
			s = string.gsub(s, "\\", "/")
			os.setClipboardText(s) -- copy track path to clipboard
		end
	}

	page:createButton{
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
			s = string.gsub(s, "\\", "/")
			os.execute(s)
			---mwse.log("folder = %s, name = %s, ext = %s", folder, name, ext)
			s = string.format('"%s/%s"', tes3.installDirectory, folder)
			s = string.gsub(s, "/", "\\")
			s = string.format("explorer %s", s)
			---mwse.log("os.execute(%s)", s)
			os.execute(s)
		end
	}

	page:createButton{
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
			s = stripPath(s)
			local s2 = getSearchURL(s)
			---mwse.log("getSearchURL(%s) --> %s", s, s2)
			---s = string.format("start %s", s2)
			---mwse.log('os.execute("%s")', s)
			---os.execute(s)
			mwse.log('os.openURL("%s")', s2)
			os.openURL(s2)
		end
	}

	local s = sNo
	if defaultConfig.logTracks then
		s = sYes
	end
	page:createYesNoButton{
		label = 'Log Tracks',
		description = 'Default: '..s,
		variable = createConfigVariable('logTracks')
	}
	mwse.mcm.register(template)
	logConfig(config, {indent = false})
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
