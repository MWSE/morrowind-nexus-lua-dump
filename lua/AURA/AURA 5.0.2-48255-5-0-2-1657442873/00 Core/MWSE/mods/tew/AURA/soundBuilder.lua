local this = {}

-- Imports
local common=require("tew.AURA.common")
local sounds=require("tew.AURA.sounds")

-- Load logger
local debugLog = common.debugLog

-- Load or create soundstate
local manifest
local fileAddedToManifest, fileRemovedFromManifest = false, false

-- Paths shortcuts
local manifestPath = "mods\\tew\\AURA\\manifest"
local AURAdir = "Data Files\\Sound\\tew\\A"
local soundDir = "tew\\A"
local climDir = "\\C\\"
local comDir = "\\S\\"
local popDir = "\\P\\"
local interiorDir = "\\I\\"
local wDir = "\\W\\"
local quietDir = "q"
local warmDir = "w"
local coldDir = "c"


-- Create sound objects against manifest file
local function createSound(objectId, filename, soundTable, i)
    debugLog("File id: "..objectId)
    debugLog("Filename: "..filename)

    local timestamp = lfs.attributes("Data Files\\Sound\\"..filename, "modification")
    local fileUnmodified = (manifest[objectId] == timestamp)

    local sound = tes3.createObject{
        id = objectId,
        objectType = tes3.objectType.sound,
        filename = filename,
        getIfExists = fileUnmodified
    }

    if soundTable then
        table.insert(soundTable, i or #soundTable+1, sound)
    end

	manifest[objectId] = timestamp

    if fileUnmodified then
        debugLog(filename.." unmodified.\n---------------")
    else
		if (not fileAddedToManifest) then fileAddedToManifest = true end
        debugLog(filename.." modified. Refreshing object.\n---------------")
    end
end


----- Building tables -----

-- General climate/time table --
local function buildClearSounds()
	debugLog("|---------------------- Building clear weather table. ----------------------|\n")
	for climate in lfs.dir(AURAdir..climDir) do
		if climate ~= ".." and climate ~= "." then
			sounds.clear[climate]={}
			for time in lfs.dir(AURAdir..climDir..climate) do
				if time ~= ".." and time ~= "." then
					sounds.clear[climate][time]={}
					for soundfile in lfs.dir(AURAdir..climDir..climate.."\\"..time) do
						if soundfile ~= ".." and soundfile ~= "." then
							if string.endswith(soundfile, ".wav") then
								local objectId = string.sub(climate.."_"..time.."_"..soundfile, 1, -5)
								local filename = soundDir..climDir..climate.."\\"..time.."\\"..soundfile
                                createSound(objectId, filename, sounds.clear[climate][time])
							end
						end
					end
				end
			end
		end
	end
end

-- Weather-specific --
local function buildContextSounds(dir, array)
	debugLog("|---------------------- Building '"..dir.."' weather table. ----------------------|\n")
	for soundfile in lfs.dir(AURAdir..comDir..dir) do
		if string.endswith(soundfile, ".wav") then
			local objectId = string.sub("S_"..dir.."_"..soundfile, 1, -5)
			local filename = soundDir..comDir.."\\"..dir.."\\"..soundfile
			createSound(objectId, filename, array)
		end
	end
end

-- Populated --
local function buildPopulatedSounds()
	debugLog("|---------------------- Building populated sounds table. ----------------------|\n")
	for populatedType, _ in pairs(sounds.populated) do
		for soundfile in lfs.dir(AURAdir..popDir..populatedType) do
			if soundfile and soundfile ~= ".." and soundfile ~= "." and string.endswith(soundfile, ".wav") then
				local objectId = string.sub("P_"..populatedType.."_"..soundfile, 1, -5)
				local filename = soundDir..popDir..populatedType.."\\"..soundfile
				createSound(objectId, filename, sounds.populated[populatedType])
			end
		end
	end
end

-- Interior --
local function buildInteriorSounds()
	debugLog("|---------------------- Building interior sounds table. ----------------------|\n")
	for interiorType, _ in pairs(sounds.interior) do
		for soundfile in lfs.dir(AURAdir..interiorDir..interiorType) do
			if soundfile and soundfile ~= ".." and soundfile ~= "." and string.endswith(soundfile, ".wav") then
				local objectId = string.sub("I_"..interiorType.."_"..soundfile, 1, -5)
				local filename = soundDir..interiorDir..interiorType.."\\"..soundfile
				createSound(objectId, filename, sounds.interior[interiorType])
			end
		end
	end
end

local function buildTavernSounds()
	debugLog("|---------------------- Building tavern sounds table. ----------------------|\n")
	for folder in lfs.dir(AURAdir..interiorDir.."\\tav\\") do
		for soundfile in lfs.dir(AURAdir..interiorDir.."\\tav\\"..folder) do
			if soundfile and soundfile ~= ".." and soundfile ~= "." and string.endswith(soundfile, ".wav") then
				local objectId = string.sub("I_tav_"..folder.."_"..soundfile, 1, -5)
				local filename = soundDir..interiorDir.."tav\\"..folder.."\\"..soundfile
				createSound(objectId, filename, sounds.interior["tav"][folder])
			end
		end
	end
end

local function buildWeatherSounds()
    debugLog("|---------------------- Building interior weather sounds. ----------------------|\n")

    local filename, objectId

    filename = soundDir..wDir.."\\big\\rl.wav"
    objectId = "tew_b_rainlight"
    createSound(objectId, filename)

    filename = soundDir..wDir.."\\big\\rm.wav"
    objectId = "tew_b_rainmedium"
    createSound(objectId, filename, sounds.interiorWeather["big"], 4)

	filename = soundDir..wDir.."\\big\\rh.wav"
    objectId = "tew_b_rainheavy"
	createSound(objectId, filename)

	filename = soundDir..wDir.."\\big\\th.wav"
    objectId = "tew_b_thunderheavy"
    createSound(objectId, filename, sounds.interiorWeather["big"], 5)

    filename = soundDir..wDir.."\\sma\\rl.wav"
    objectId = "tew_s_rainlight"
	createSound(objectId, filename)

	filename = soundDir..wDir.."\\sma\\rm.wav"
    objectId = "tew_s_rainmedium"
    createSound(objectId, filename, sounds.interiorWeather["sma"], 4)

    filename = soundDir..wDir.."\\sma\\rh.wav"
    objectId = "tew_s_rainheavy"
	createSound(objectId, filename)

	filename = soundDir..wDir.."\\sma\\th.wav"
    objectId = "tew_s_thunderheavy"
    createSound(objectId, filename, sounds.interiorWeather["sma"], 5)

    filename = soundDir..wDir.."\\ten\\rl.wav"
    objectId = "tew_t_rainlight"
    createSound(objectId, filename)

	filename = soundDir..wDir.."\\ten\\rm.wav"
    objectId = "tew_t_rainmedium"
    createSound(objectId, filename, sounds.interiorWeather["ten"], 4)

    filename = soundDir..wDir.."\\ten\\rh.wav"
    objectId = "tew_t_rainheavy"
    createSound(objectId, filename)

	filename = soundDir..wDir.."\\ten\\th.wav"
    objectId = "tew_t_thunderheavy"
    createSound(objectId, filename, sounds.interiorWeather["ten"], 5)

    filename = soundDir..wDir.."\\com\\wg.wav"
    objectId = "tew_wind_gust"
    createSound(objectId, filename)

    filename, objectId = nil, nil
end


local function buildMisc()
	debugLog("|---------------------- Creating misc sound objects. ----------------------|\n")

    local filename, objectId

	tes3.createObject{
		id = "splash_lrg",
		objectType = tes3.objectType.sound,
		filename = "Fx\\envrn\\splash_lrg.wav",
		getIfExists = true
	}
	debugLog("Adding misc file: splash_lrg")

	tes3.createObject{
		id = "splash_sml",
		objectType = tes3.objectType.sound,
		filename = "Fx\\envrn\\splash_sml.wav",
		getIfExists = true
	}
	debugLog("Adding misc file: splash_sml")

	tes3.createObject{
		id = "tew_clap",
		objectType = tes3.objectType.sound,
		filename = "Fx\\envrn\\ent_react04a.wav",
		getIfExists = true
	}

	tes3.createObject{
		id = "tew_potnpour",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\potnpour.wav",
		getIfExists = true
	}

	tes3.createObject{
		id = "tew_shield",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\shield.wav",
		getIfExists = true
	}

	tes3.createObject{
		id = "tew_blunt",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\bluntOut.wav",
		getIfExists = true
	}

	tes3.createObject{
		id = "tew_longblad",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\longblad.wav",
		getIfExists = true
	}

	tes3.createObject{
		id = "tew_spear",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\spear.wav",
		getIfExists = true
	}

    filename = "tew\\A\\M\\yurtflap.wav"
    objectId = "tew_yurt"
    createSound(objectId, filename)


    filename = "tew\\A\\M\\serviceboat.wav"
    objectId = "tew_boat"
    createSound(objectId, filename)

    filename = "tew\\A\\M\\servicegondola.wav"
    objectId = "tew_gondola"
	createSound(objectId, filename)

    filename, objectId = nil, nil
end

local function buildRain()
	debugLog("|---------------------- Creating rain sound objects. ----------------------|\n")

    local filename, objectId

    filename = "tew\\A\\R\\tew_rain_light.wav"
    objectId = "tew_rain_light"
    createSound(objectId, filename)

    filename = "tew\\A\\R\\tew_rain_medium.wav"
    objectId = "tew_rain_medium"
    createSound(objectId, filename)

    filename = "tew\\A\\R\\tew_rain_heavy.wav"
    objectId = "tew_rain_heavy"
    createSound(objectId, filename)

    filename = "tew\\A\\R\\tew_thunder_light.wav"
    objectId = "tew_thunder_light"
    createSound(objectId, filename)

    filename = "tew\\A\\R\\tew_thunder_medium.wav"
    objectId = "tew_thunder_medium"
    createSound(objectId, filename)

    filename = "tew\\A\\R\\tew_thunder_heavy.wav"
    objectId = "tew_thunder_heavy"
    createSound(objectId, filename)

    filename, objectId = nil, nil
end

function this.flushManifestFile()
	tes3.messageBox({
		message = "Are you sure you want to flush manifest file?",
		buttons = { tes3.findGMST(tes3.gmst.sYes).value, tes3.findGMST(tes3.gmst.sNo).value },
		callback = function(e)
			if (e.button == 0) then
				local empty = {}
				json.savefile(manifestPath, empty)
				local message = "Manifest file flushed."
				debugLog(message)
				tes3.messageBox({ message = message })
			end
		end
	})
end

local function getWeatherSounds()
	local ashSound = tes3.getSound("ashstorm")
	local blightSound = tes3.getSound("Blight")
	local blizzardSound = tes3.getSound("BM Blizzard")

	for type in pairs(sounds.interiorWeather) do
		table.insert(sounds.interiorWeather[type], 6, ashSound)
		table.insert(sounds.interiorWeather[type], 7, blightSound)
		table.insert(sounds.interiorWeather[type], 9, blizzardSound)
	end
end

local function checkForRemovedFiles()
	local removedSounds = {}
	for k, _ in pairs(manifest) do
		if not tes3.getSound(k) then
			table.insert(removedSounds, k)
		end
	end

	if #removedSounds > 0 then
		fileRemovedFromManifest = true
		for _, v in ipairs(removedSounds) do
			debugLog(v.." removed from manifest.")
			manifest[v] = nil
		end
	end
end

function this.build()
	event.register("loaded", getWeatherSounds) -- Needed to do after initialisation, errors out otherwise

	manifest = json.loadfile(manifestPath) or {}

    buildClearSounds()
	buildContextSounds(quietDir, sounds.quiet)
	buildContextSounds(warmDir, sounds.warm)
	buildContextSounds(coldDir, sounds.cold)
	buildPopulatedSounds()
	buildInteriorSounds()
	buildTavernSounds()
	buildWeatherSounds()
	buildMisc()
	buildRain()

	checkForRemovedFiles()
    -- Write manifest file if it was modified
	if fileRemovedFromManifest or fileAddedToManifest then
		json.savefile(manifestPath, manifest)
		debugLog("Manifest file updated.")
	else
		debugLog("Manifest file unchanged.")
	end
	manifest = nil
end

return this

