-- Library packaging
local this={}

-- Imports
local common=require("tew.AURA.common")

-- Logger
local debugLog = common.debugLog

-- Timer
local blockTimer

-- Paths
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

-- Load config
local config = require("tew.AURA.config")

-- Constants
local STEP = 0.04
local TICK = 0.25
local MAX = 1
local MIN = 0

-- Array attributes
local clear = {}
local quiet = {}
local warm = {}
local cold = {}

local blocked = {}

local populated = {
    ["ash"] = {},
    ["dae"] = {},
    ["dar"] = {},
    ["dwe"] = {},
    ["imp"] = {},
    ["nor"] = {},
    ["n"] = {}
}

local interior = {
    ["aba"] = {},
    ["alc"] = {},
	["cou"] = {},
    ["cav"] = {},
    ["clo"] = {},
    ["dae"] = {},
    ["dwe"] = {},
    ["ice"] = {},
    ["mag"] = {},
    ["fig"] = {},
    ["tem"] = {},
    ["lib"] = {},
    ["smi"] = {},
    ["tra"] = {},
    ["tom"] = {},
    ["tav"] = {
        ["imp"] = {},
        ["dar"] = {},
        ["nor"] = {},
    }
}

local interiorWeather = {

    ["big"] = {
        [4] = nil,
        [5] = nil,
        [6] = nil,
        [7] = nil,
        [9] = nil
    },
    ["sma"] = {
        [4] = nil,
        [5] = nil,
        [6] = nil,
        [7] = nil,
        [9] = nil
    },
    ["ten"] = {
        [4] = nil,
        [5] = nil,
        [6] = nil,
        [7] = nil,
        [9] = nil
    }
}

local function getWeatherSounds()
	local ashSound = tes3.getSound("ashstorm")
	local blightSound = tes3.getSound("Blight")
	local blizzardSound = tes3.getSound("BM Blizzard")

	for type in pairs(interiorWeather) do
		table.insert(interiorWeather[type], 6, ashSound)
		table.insert(interiorWeather[type], 7, blightSound)
		table.insert(interiorWeather[type], 9, blizzardSound)
	end
end

local modules = {
	["outdoor"] = {
		old = nil,
		new = nil
	},
	["populated"] = {
		old = nil,
		new = nil
	},
	["interior"] = {
		old = nil,
		new = nil
	},
	["interiorWeather"] = {
		old = nil,
		new = nil
	}
}



-- Building tables --

-- General climate/time table --
local function buildClearSounds()
	mwse.log("\n")
	debugLog("|---------------------- Building clear weather table. ----------------------|\n")
	for climate in lfs.dir(AURAdir..climDir) do
		if climate ~= ".." and climate ~= "." then
			clear[climate]={}
			for time in lfs.dir(AURAdir..climDir..climate) do
				if time ~= ".." and time ~= "." then
					clear[climate][time]={}
					for soundfile in lfs.dir(AURAdir..climDir..climate.."\\"..time) do
						if soundfile ~= ".." and soundfile ~= "." then
							if string.endswith(soundfile, ".wav") then
								local objectId = string.sub(climate.."_"..time.."_"..soundfile, 1, -5)
								local filename = soundDir..climDir..climate.."\\"..time.."\\"..soundfile
								debugLog("Adding file: "..soundfile)
								debugLog("File id: "..objectId)
								debugLog("Filename: "..filename.."\n---------------")
								local sound = tes3.createObject{
									id = objectId,
									objectType = tes3.objectType.sound,
									filename = filename,
									getIfExists = config.safeFetchMode
								}
								table.insert(clear[climate][time], sound)
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
	mwse.log("\n")
	debugLog("|---------------------- Building '"..dir.."' weather table. ----------------------|\n")
	for soundfile in lfs.dir(AURAdir..comDir..dir) do
		if string.endswith(soundfile, ".wav") then
			local objectId = string.sub("S_"..dir.."_"..soundfile, 1, -5)
			local filename = soundDir..comDir.."\\"..dir.."\\"..soundfile
			debugLog("Adding file: "..soundfile)
			debugLog("File id: "..objectId)
			debugLog("Filename: "..filename.."\n---------------")
			local sound = tes3.createObject{
				id = objectId,
				objectType = tes3.objectType.sound,
				filename = filename,
				getIfExists = config.safeFetchMode
			}
			table.insert(array, sound)
		end
	end
end

-- Populated --
local function buildPopulatedSounds()
	mwse.log("\n")
	debugLog("|---------------------- Building populated sounds table. ----------------------|\n")
	for populatedType, _ in pairs(populated) do
		for soundfile in lfs.dir(AURAdir..popDir..populatedType) do
			if soundfile and soundfile ~= ".." and soundfile ~= "." and string.endswith(soundfile, ".wav") then

				local objectId = string.sub("P_"..populatedType.."_"..soundfile, 1, -5)
				local filename = soundDir..popDir..populatedType.."\\"..soundfile
				debugLog("Adding file: "..soundfile)
				debugLog("File id: "..objectId)
				debugLog("Filename: "..filename.."\n---------------")
				local sound = tes3.createObject{
					id = objectId,
					objectType = tes3.objectType.sound,
					filename = filename,
					getIfExists = config.safeFetchMode
				}
				table.insert(populated[populatedType], sound)
				debugLog("Adding populated file: "..soundfile)
			end
		end
	end
end

-- Interior --
local function buildInteriorSounds()
	mwse.log("\n")
	debugLog("|---------------------- Building interior sounds table. ----------------------|\n")
	for interiorType, _ in pairs(interior) do
		for soundfile in lfs.dir(AURAdir..interiorDir..interiorType) do
			if soundfile and soundfile ~= ".." and soundfile ~= "." and string.endswith(soundfile, ".wav") then
				local objectId = string.sub("I_"..interiorType.."_"..soundfile, 1, -5)
				local filename = soundDir..interiorDir..interiorType.."\\"..soundfile
				debugLog("Adding interior file: "..soundfile)
				debugLog("File id: "..objectId)
				debugLog("Filename: "..filename.."\n---------------")
				local sound = tes3.createObject{
					id = objectId,
					objectType = tes3.objectType.sound,
					filename = filename,
					getIfExists = config.safeFetchMode
				}

				table.insert(interior[interiorType], sound)
			end
		end
	end
end

local function buildTavernSounds()
	mwse.log("\n")
	debugLog("|---------------------- Building tavern sounds table. ----------------------|\n")
	for folder in lfs.dir(AURAdir..interiorDir.."\\tav\\") do
		for soundfile in lfs.dir(AURAdir..interiorDir.."\\tav\\"..folder) do
			if soundfile and soundfile ~= ".." and soundfile ~= "." and string.endswith(soundfile, ".wav") then
				local objectId = string.sub("I_tav_"..folder.."_"..soundfile, 1, -5)
				local filename = soundDir..interiorDir.."tav\\"..folder.."\\"..soundfile
				debugLog("Adding tavern file: "..soundfile)
				debugLog("File id: "..objectId)
				debugLog("Filename: "..filename.."\n---------------")
				local sound = tes3.createObject{
					id = objectId,
					objectType = tes3.objectType.sound,
					filename = filename,
					getIfExists = config.safeFetchMode
				}
				table.insert(interior["tav"][folder], sound)
			end
		end
	end
end

local function buildWeatherSounds()
    debugLog("|---------------------- Building interior weather sounds. ----------------------|\n")
   
    local sound, filename, objectId

    filename = soundDir..wDir.."\\big\\r.wav"
    objectId = "tew_b_rainheavy"
    debugLog("File id: "..objectId)
    debugLog("Filename: "..filename.."\n---------------")
    sound = tes3.createObject{
        id = objectId,
        objectType = tes3.objectType.sound,
        filename = filename,
		getIfExists = config.safeFetchMode
    }
    interiorWeather["big"][4] = sound

    filename = soundDir..wDir.."\\big\\rh.wav"
    objectId = "tew_b_rain"
    debugLog("File id: "..objectId)
    debugLog("Filename: "..filename.."\n---------------")
    sound = tes3.createObject{
        id = objectId,
        objectType = tes3.objectType.sound,
        filename = filename,
		getIfExists = config.safeFetchMode
    }
    interiorWeather["big"][5] = sound

    filename = soundDir..wDir.."\\sma\\r.wav"
    objectId = "tew_s_rain"
    debugLog("File id: "..objectId)
    debugLog("Filename: "..filename.."\n---------------")
    sound = tes3.createObject{
        id = objectId,
        objectType = tes3.objectType.sound,
        filename = filename,
		getIfExists = config.safeFetchMode
    }
    interiorWeather["sma"][4] = sound

    filename = soundDir..wDir.."\\sma\\rh.wav"
    objectId = "tew_s_rainheavy"
    debugLog("File id: "..objectId)
    debugLog("Filename: "..filename.."\n---------------")
    sound = tes3.createObject{
        id = objectId,
        objectType = tes3.objectType.sound,
        filename = filename,
		getIfExists = config.safeFetchMode
    }
    interiorWeather["sma"][5] = sound

    filename = soundDir..wDir.."\\ten\\r.wav"
    objectId = "tew_t_rain"
    debugLog("File id: "..objectId)
    debugLog("Filename: "..filename.."\n---------------")
    sound = tes3.createObject{
        id = objectId,
        objectType = tes3.objectType.sound,
        filename = filename,
		getIfExists = config.safeFetchMode
    }
    interiorWeather["ten"][4] = sound

    filename = soundDir..wDir.."\\ten\\rh.wav"
    objectId = "tew_t_rainheavy"
    debugLog("File id: "..objectId)
    debugLog("Filename: "..filename.."\n---------------")
    sound = tes3.createObject{
        id = objectId,
        objectType = tes3.objectType.sound,
        filename = filename,
		getIfExists = config.safeFetchMode
    }
    interiorWeather["ten"][5] = sound

    filename = soundDir..wDir.."\\com\\wg.wav"
    objectId = "tew_wind_gust"
    debugLog("File id: "..objectId)
    debugLog("Filename: "..filename.."\n---------------")
    tes3.createObject{
        id = objectId,
        objectType = tes3.objectType.sound,
        filename = filename,
		getIfExists = config.safeFetchMode
    }

    sound, filename, objectId = nil, nil, nil

    debugLog("|---------------------- Finished building interior weather sounds. ----------------------|\n")
end


local function buildMisc()
	mwse.log("\n")
	debugLog("|---------------------- Creating misc sound objects. ----------------------|\n")
	
	tes3.createObject{
		id = "splash_lrg",
		objectType = tes3.objectType.sound,
		filename = "Fx\\envrn\\splash_lrg.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: splash_lrg")

	tes3.createObject{
		id = "splash_sml",
		objectType = tes3.objectType.sound,
		filename = "Fx\\envrn\\splash_sml.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: splash_sml")

	tes3.createObject{
		id = "tew_yurt",
		objectType = tes3.objectType.sound,
		filename = "tew\\A\\M\\yurtflap.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: tew_yurt")

	tes3.createObject{
		id = "tew_boat",
		objectType = tes3.objectType.sound,
		filename = "tew\\A\\M\\serviceboat.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: tew_boat")

	tes3.createObject{
		id = "tew_gondola",
		objectType = tes3.objectType.sound,
		filename = "tew\\A\\M\\servicegondola.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: tew_gondola")

	tes3.createObject{
		id = "tew_clap",
		objectType = tes3.objectType.sound,
		filename = "Fx\\envrn\\ent_react04a.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: tew_clap")

	tes3.createObject{
		id = "tew_potnpour",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\potnpour.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: tew_potnpour")

	tes3.createObject{
		id = "tew_shield",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\shield.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: tew_shield")

	tes3.createObject{
		id = "tew_blunt",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\bluntOut.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: tew_blunt")

	tes3.createObject{
		id = "tew_longblad",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\longblad.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: tew_longblad")

	tes3.createObject{
		id = "tew_spear",
		objectType = tes3.objectType.sound,
		filename = "Fx\\item\\spear.wav",
		getIfExists = config.safeFetchMode
	}
	debugLog("Adding misc file: tew_spear")
end

----------------------------------------------------------------------------------------------------------
--//////////////////////////////////////////////////////////////////////////////////////////////////////--
----------------------------------------------------------------------------------------------------------

local function removeBlocked(track)
	for k, v in pairs(blocked) do
		if v == track then
			table.remove(blocked, k)
		end
	end
end

local function isBlocked(track)
	for _, v in pairs(blocked) do
		if v == track then debugLog("Track blocked: "..track.id) return true end
	end
end

-- Play/Stop handling --
local function fadeIn(ref, volume, track, module)
	
	if not track or not tes3.getSoundPlaying{sound = track, reference = ref} then debugLog("No track to fade in. Returning.") return end

	if isBlocked(track) then
		return
	end

	debugLog("Running fade in for: "..track.id)
	table.insert(blocked, track)

	local TIME = TICK*volume/STEP
	local ITERS = math.ceil(volume/STEP)
	local runs = 1

	local function fader()
		local incremented = STEP*runs

		if not tes3.getSoundPlaying{sound = track, reference = ref} then
			debugLog("In not playing: "..track.id)
			return
		end

		tes3.adjustSoundVolume{sound = track, volume = incremented, reference = ref}
		debugLog("Adjusting volume in: "..track.id.." | "..tostring(incremented))
		runs = runs + 1
		debugLog("In runs for track: "..track.id.." : "..runs)
	end

	local function queuer()
		modules[module].old = track
		removeBlocked(track)
		debugLog("Fade in for "..track.id.." finished in: "..tostring(TIME).." s.")
	end

	debugLog("Iterations: "..tostring(ITERS))
	debugLog("Time: "..tostring(TIME))

	timer.start{
		iterations = ITERS,
		duration = TICK,
		callback = fader
	}

	timer.start{
		iterations = 1,
		duration = TIME,
		callback = queuer
	}
end

local function fadeOut(ref, volume, track, module)

	if not track or not tes3.getSoundPlaying{sound = track, reference = ref} then debugLog("No track to fade out. Returning.") return end
	
	if isBlocked(track) then
		if not (blockTimer) or (blockTimer.state == timer.expired) then
			blockTimer = timer.start
			{
				callback = function()
					fadeOut(ref, volume, track, module)
				end,
				type = timer.real,
				iterations = 2,
				duration = 3
			}
		end
	end

	if isBlocked(track) then
		return
	end
	
	debugLog("Running fade out for: "..track.id)
	table.insert(blocked, track)
	
	local TIME = TICK*volume/STEP
	local ITERS = math.ceil(volume/STEP)
	local runs = ITERS

	local function fader()
		local incremented = STEP*runs
		if not tes3.getSoundPlaying{sound = track, reference = ref} then
			debugLog("Out not playing: "..track.id)
			return
		end

		tes3.adjustSoundVolume{sound = track, volume = incremented, reference = ref}
		debugLog("Adjusting volume out: "..track.id.." | "..tostring(incremented))
		runs = runs - 1
		debugLog("Out runs for track: "..track.id.." : "..runs)
	end

	local function queuer()
		modules[module].old = track
		removeBlocked(track)
		if tes3.getSoundPlaying{sound = track, reference = ref} then tes3.removeSound{sound = track, reference = ref} end
		debugLog("Fade out for "..track.id.." finished in: "..tostring(TIME).." s.")
	end

	debugLog("Iterations: "..tostring(ITERS))
	debugLog("Time: "..tostring(TIME))

	timer.start{
		iterations = ITERS,
		duration = TICK,
		callback = fader
	}

	timer.start{
		iterations = 1,
		duration = TIME,
		callback = queuer
	}
end

local function crossFade(ref, volume, trackOld, trackNew, module)
	if not trackOld or not trackNew then return end
	debugLog("Running crossfade for: "..trackOld.id..", "..trackNew.id)
	fadeOut(ref, volume, trackOld, module)
	fadeIn(ref, volume, trackNew, module)
end

function this.removeImmediate(options)
	debugLog("Immediately removing sounds for module: "..options.module)
	local ref = options.reference or tes3.mobilePlayer.reference

	if
		modules[options.module].old
		and tes3.getSoundPlaying{sound = modules[options.module].old, reference = ref}
	then
		tes3.removeSound{sound = modules[options.module].old, reference = ref}
		debugLog(modules[options.module].old.id.." removed.")
	else
		debugLog("Old track not playing.")
	end
	
	if
		modules[options.module].new
		and tes3.getSoundPlaying{sound = modules[options.module].new, reference = ref}
	then
		tes3.removeSound{sound = modules[options.module].new, reference = ref}
		debugLog(modules[options.module].new.id.." removed.")
	else
		debugLog("New track not playing.")
	end
end

function this.remove(options)
	local ref = options.reference or tes3.mobilePlayer.reference
	local volume = options.volume or MAX

	if
		modules[options.module].old
		and tes3.getSoundPlaying{sound = modules[options.module].old, reference = ref}
	then
		fadeOut(ref, volume, modules[options.module].old, options.module)
	end
	
	if
		modules[options.module].new
		and tes3.getSoundPlaying{sound = modules[options.module].new, reference = ref}
	then
		fadeOut(ref, volume, modules[options.module].new, options.module)
	end
end

local function getTrack(options)
	debugLog("Parsing passed options.")

	if not options.module then debugLog("No module detected. Returning.") end

	local table

	if options.module == "outdoor" then
		debugLog("Got outdoor module.")
		if not (options.climate) or not (options.time) then
			if options.type == "quiet" then
				debugLog("Got quiet type.")
				table = quiet
			elseif options.type == "warm" then
				debugLog("Got warm type.")
				table = warm
			elseif options.type == "cold" then
				debugLog("Got cold type.")
				table = cold
			end
		else
			local climate = options.climate
			local time = options.time
			debugLog("Got "..climate.." climate and "..time.." time.")
			table = clear[climate][time]
		end
	elseif options.module == "populated" then
		debugLog("Got populated module.")
		if options.type == "night" then
			debugLog("Got populated night.")
			table = populated["n"]
		elseif options.type == "day" then
			debugLog("Got populated day.")
			table = populated[options.typeCell]
		end
	elseif options.module == "interior" then
		debugLog("Got interior module.")
		if options.race then
			debugLog("Got tavern for "..options.race.." race.")
			table = interior["tav"][options.race]
		else
			debugLog("Got interior "..options.type.." type.")
			table = interior[options.type]
		end
	elseif options.module == "interiorWeather" then
		if options.type == "wind" then
			return tes3.getSound("tew_wind_gust")
		end
		debugLog("Got interior weather module.")
		debugLog("Got interior type: "..options.type)
		return interiorWeather[options.type][options.weather]
	end

	if not table then
		debugLog("No table found. Triggering condition change.")
		event.trigger("AURA:conditionChanged")
		return
	end

	local newTrack = table[math.random(1, #table)]
	if modules[options.module].old and #table > 1 then
		while newTrack.id == modules[options.module].old.id do
			newTrack = table[math.random(1, #table)]
		end
	end

	debugLog("Selected track: "..newTrack.id)

	return newTrack
end

function this.playImmediate(options)
	local ref = options.reference or tes3.mobilePlayer.reference
	local volume = options.volume or MAX

	if options.last and modules[options.module].new then
		if tes3.getSoundPlaying{sound = modules[options.module].new, reference = ref} then tes3.removeSound{sound = modules[options.module].new, reference = ref} end
		debugLog("Immediately restaring: "..modules[options.module].new.id)
		tes3.playSound {
			sound = modules[options.module].new,
			loop = true,
			reference = ref,
			volume = volume,
			pitch = options.pitch or MAX
		}
		modules[options.module].old = modules[options.module].new
	else
		local newTrack = getTrack(options)
		modules[options.module].old = modules[options.module].new
		modules[options.module].new = newTrack

		if newTrack then
			debugLog("Immediately playing new track: "..newTrack.id.." for module: "..options.module)

			tes3.playSound {
				sound = newTrack,
				loop = true,
				reference = ref,
				volume = volume,
				pitch = options.pitch or MAX
			}
		end
	end
end

-- Supporting kwargs here
function this.play(options)


	local ref = options.reference or tes3.mobilePlayer.reference
	local volume = options.volume or MAX

	local newTrack = getTrack(options)
	modules[options.module].old = modules[options.module].new
	modules[options.module].new = newTrack

	debugLog("Playing new track: "..newTrack.id.." for module: "..options.module)

	tes3.playSound {
		sound = newTrack,
		loop = true,
		reference = ref,
		volume = MIN,
		pitch = options.pitch or MAX
	}

	if not modules[options.module].old then
		fadeIn(ref, volume, newTrack, options.module)
	else
		crossFade(ref, volume, modules[options.module].old, newTrack, options.module)
	end
				
end

function this.build()
	buildClearSounds()
	buildContextSounds(quietDir, quiet)
	buildContextSounds(warmDir, warm)
	buildContextSounds(coldDir, cold)
	buildPopulatedSounds()
	buildInteriorSounds()
	buildTavernSounds()
	buildWeatherSounds()
	buildMisc()
	event.register("loaded", getWeatherSounds) -- Needed to do after initialisation, errors out otherwise

	mwse.log("\n")
	debugLog("|---------------------- Finished building sound objects. ----------------------|\n")
end

return this