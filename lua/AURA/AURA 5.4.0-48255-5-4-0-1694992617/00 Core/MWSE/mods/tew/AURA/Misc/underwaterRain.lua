local common = require("tew.AURA.common")
local debugLog = common.debugLog

local weatherSounds = {
	["Rain"] = 0,
	["rain heavy"] = 0,
	["Blight"] = 0,
	["Ashstorm"] = 0,
	["BM Blizzard"] = 0,
	["tew_b_rainlight"] = 0,
	["tew_b_rainmedium"] = 0,
	["tew_b_rainheavy"] = 0,
	["tew_s_rainlight"] = 0,
	["tew_s_rainmedium"] = 0,
	["tew_s_rainheavy"] = 0,
	["tew_t_rainlight"] = 0,
	["tew_t_rainmedium"] = 0,
	["tew_t_rainheavy"] = 0,
	["tew_rain_light"] = 0,
	["tew_rain_medium"] = 0,
	["tew_rain_heavy"] = 0,
	["tew_thunder_light"] = 0,
	["tew_thunder_medium"] = 0,
	["tew_thunder_heavy"] = 0
}

local function setVolume(track, volume)
	local rounded = math.round(volume, 2)
	debugLog(string.format("Setting volume for track %s to %s", track.id, rounded))
	track.volume = rounded
end

local function modifyVolume()
	if not tes3.player or not tes3.mobilePlayer then return end
	local waterLevel = tes3.player.cell.waterLevel or 0
	local playerPosZ = tes3.player.position.z
	for id, originalVol in pairs(weatherSounds) do
		local sound = tes3.getSound(id)
		if playerPosZ < waterLevel and sound:isPlaying() then
			local volume = math.clamp(1 - math.remap(waterLevel - playerPosZ, 0, 1500, 0, originalVol), 0.0, originalVol)
			setVolume(sound, volume)
		else
			setVolume(sound, originalVol)
		end
	end
end

local underwaterPrev

local function underWaterCheck(e)
	local mp = tes3.mobilePlayer
	if mp then
		if mp.isSwimming and not underwaterPrev then
			underwaterPrev = true
			event.trigger("AURA:enteredUnderwater")
		elseif not mp.isSwimming and underwaterPrev then
			underwaterPrev = false
			event.trigger("AURA:exitedUnderwater")
		end
	end
end

local function setOriginalVolume()
	for id, _ in pairs(weatherSounds) do
		local sound = tes3.getSound(id)
		weatherSounds[id] = sound.volume
	end
end

local function registerModify()
	event.unregister(tes3.event.simulate, underWaterCheck)
	event.unregister(tes3.event.simulate, modifyVolume)
	event.register(tes3.event.simulate, modifyVolume)
end

local function unRegisterModify()
	event.unregister(tes3.event.simulate, underWaterCheck)
	event.register(tes3.event.simulate, underWaterCheck)
	event.unregister(tes3.event.simulate, modifyVolume)
	modifyVolume()
end

event.unregister(tes3.event.simulate, underWaterCheck)
event.register(tes3.event.simulate, underWaterCheck)

event.register("AURA:enteredUnderwater", registerModify)
event.register("AURA:exitedUnderwater", unRegisterModify)

event.register(tes3.event.load, setOriginalVolume)
