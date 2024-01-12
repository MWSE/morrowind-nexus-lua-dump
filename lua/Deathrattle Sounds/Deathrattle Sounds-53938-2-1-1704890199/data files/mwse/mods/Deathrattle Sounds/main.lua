local function isValidTarget(e)
	if (not e.reference.mobile or not e.reference.mobile.actorType == tes3.actorType.npc) then
		return
	end

	if e.reference.mobile.hasVampirism then
		return
	end

	return true
end

local lastPlayedSound = {}
event.register("addTempSound", function(e)
	if (not isValidTarget(e)) then
		return
	end

	if e.isVoiceover then
		return
	end

	lastPlayedSound[e.reference.id] = e.path
	timer.start({ duration = 5, callback = function() lastPlayedSound = {} end }) -- this array can blow up if we never clear it
end)

local function damagedCallback(e)
	if (not isValidTarget(e)) then
		return
	end

	if (not e.killingBlow) then
		return
	end

	tes3.removeSound({ sound = nil, reference = e.reference }) -- cut off all trash talk
	tes3.playSound({ reference = e.reference, soundPath = lastPlayedSound[e.reference.id] }) -- replay silenced hit sound

	local soundPath
	math.randomseed(os.time())

	-- use vanilla sounds for beast races
	local unsupportedRaces = {["Argonian"] = true, ["Khajiit"] = true, ["Orc"] = true}
	if (unsupportedRaces[e.reference.object.race.id]) then
		local genderPath = e.reference.object.female and "f" or "m"
		local racePath = ({
			["Argonian"] = "a",
			["Khajiit"] = "k",
			["Orc"] = "o",
		})[e.reference.object.race.id]
		local range = ({
			["Argonian"] = ({
				["f"] = 16,
				["m"] = 16,
			}),
			["Khajiit"] = ({
				["f"] = 16,
				["m"] = 16,
			}),
			["Orc"] = ({
				["f"] = 21,
				["m"] = 15,
			}),
		})[e.reference.object.race.id][genderPath]
		local randomInRange = math.random(1, range)
		local rangePath = ((randomInRange < 10) and "00" or "0") .. randomInRange

		soundPath = "vo\\" .. racePath .. "\\" .. genderPath .. "\\Hit_" .. racePath .. genderPath .. rangePath .. ".mp3"
		-- i.e. vo\k\f\Hit_KF016.mp3 for Khajiit female

		tes3.playSound({ reference = e.reference, soundPath = soundPath })	
		return
	end

	-- use Gothic sounds for all races except Argonian, Khajiit, Orc
	if e.reference.object.female then
		soundPath = ({
			"vo\\death\\SVM_16_DEAD_RU.mp3",
			"vo\\death\\SVM_17_DEAD_RU.mp3",
			"vo\\death\\SVM_17_DEAD_EN.mp3",
			"vo\\death\\SVM_17_DEAD_PL.mp3",
		})[math.random(1, 4)]
	else
		soundPath = ({
			"vo\\death\\SVM_13_DEAD_RU.mp3",
			"vo\\death\\SVM_3_DEAD_DE.mp3",
		})[math.random(1, 2)]
	end

	tes3.playSound({ reference = e.reference, soundPath = soundPath })	
end

event.register(tes3.event.damaged, damagedCallback)
