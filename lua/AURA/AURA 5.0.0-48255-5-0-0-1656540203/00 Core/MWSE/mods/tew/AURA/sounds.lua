-- Library packaging
local this = {}

-- Imports
local common=require("tew.AURA.common")

-- Logger
local debugLog = common.debugLog

-- Constants
local STEP = 0.015
local TICK = 0.1
local MAX = 1
local MIN = 0

-- Array attributes
this.clear = {}
this.quiet = {}
this.warm = {}
this.cold = {}

-- Blocker
local blocked = {}

this.populated = {
	["ash"] = {},
	["dae"] = {},
	["dar"] = {},
	["dwe"] = {},
	["imp"] = {},
	["nor"] = {},
	["n"] = {}
}

this.interior = {
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

this.interiorWeather = {

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
		timer.start{
			callback = function()
				fadeIn(ref, volume, track, module)
			end,
			type = timer.real,
			iterations = 1,
			duration = 2
		}
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
		duration = TIME + 0.1,
		callback = queuer
	}
end

local function fadeOut(ref, volume, track, module)

	if not track or not tes3.getSoundPlaying{sound = track, reference = ref} then debugLog("No track to fade out. Returning.") return end

	if isBlocked(track) then
		timer.start{
			callback = function()
				fadeOut(ref, volume, track, module)
			end,
			type = timer.real,
			iterations = 1,
			duration = 2
		}
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
		duration = TIME + 0.1,
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
		modules[options.module].old = modules[options.module].new
		debugLog(modules[options.module].new.id.." removed.")
	else
		debugLog("New track not playing.")
	end
end

function this.remove(options)
	debugLog("Removing sounds for module: "..options.module)
	local ref = options.reference or tes3.mobilePlayer.reference
	local volume = options.volume or MAX

	if
		modules[options.module].old
		and tes3.getSoundPlaying{sound = modules[options.module].old, reference = ref}
	then
		fadeOut(ref, volume, modules[options.module].old, options.module)
	else
		debugLog("Old track not playing.")
	end

	if
		modules[options.module].new
		and tes3.getSoundPlaying{sound = modules[options.module].new, reference = ref}
	then
		fadeOut(ref, volume, modules[options.module].new, options.module)
	else
		debugLog("New track not playing.")
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
				table = this.quiet
			elseif options.type == "warm" then
				debugLog("Got warm type.")
				table = this.warm
			elseif options.type == "cold" then
				debugLog("Got cold type.")
				table = this.cold
			end
		else
			local climate = options.climate
			local time = options.time
			debugLog("Got "..climate.." climate and "..time.." time.")
			table = this.clear[climate][time]
		end
	elseif options.module == "populated" then
		debugLog("Got populated module.")
		if options.type == "night" then
			debugLog("Got populated night.")
			table = this.populated["n"]
		elseif options.type == "day" then
			debugLog("Got populated day.")
			table = this.populated[options.typeCell]
		end
	elseif options.module == "interior" then
		debugLog("Got interior module.")
		if options.race then
			debugLog("Got tavern for "..options.race.." race.")
			table = this.interior["tav"][options.race]
		else
			debugLog("Got interior "..options.type.." type.")
			table = this.interior[options.type]
		end
	elseif options.module == "interiorWeather" then
		if options.type == "wind" then
			return tes3.getSound("tew_wind_gust")
		end
		debugLog("Got interior weather module.")
		debugLog("Got interior type: "..options.type)
		return this.interiorWeather[options.type][options.weather]
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


return this