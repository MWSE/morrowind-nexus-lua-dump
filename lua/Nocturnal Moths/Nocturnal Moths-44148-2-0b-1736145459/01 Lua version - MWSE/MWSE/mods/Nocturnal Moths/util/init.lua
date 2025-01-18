local log = require("logging.logger").getLogger("Nocturnal Moths") --[[@as mwseLogger]]

local config = require("Nocturnal Moths.config")
local lanterns = require("Nocturnal Moths.data")


local soundId = "R0_moths_fluttering"
local soundPath = "R0\\Fx\\envrn\\mothflutter.wav"
---@type tes3sound
local sound

event.register(tes3.event.initialized, function(e)
	sound = tes3.createObject({
		id = soundId,
		objectType = tes3.objectType.sound,
		filename = soundPath,
		volume = 1,
	})
end)


local util = {}

local niceWeather = {
	[tes3.weather.clear] = true,
	[tes3.weather.cloudy] = true,
	[tes3.weather.foggy] = true,
	[tes3.weather.overcast] = true,
}

function util.isNiceWeather()
	return niceWeather[tes3.worldController.weatherController.currentWeather.index] or false
end

function util.isNight()
	local hour = tes3.worldController.hour.value
	local wc = tes3.worldController.weatherController
	local nightStarHour = wc.sunsetHour + wc.sunsetDuration

	return (hour < wc.sunriseHour) or (hour >= nightStarHour)
end


---@param reference tes3reference
function util.playSound(reference)
	if not config.enableSound then return end
	tes3.playSound({
		reference = reference,
		sound = sound,
		loop = true,
		volume = config.soundVolume,
	})
end

---@param reference tes3reference
function util.stopSound(reference)
	if not config.enableSound then return end
	tes3.removeSound({
		reference = reference,
		sound = sound,
	})
end

-- Compatibility with Midnight Oil
---@param reference tes3reference
function util.isLightOff(reference)
	return reference.supportsLuaData and reference.data.lightTurnedOff
end

---@param node niNode
function util.updateNode(node)
	node:update()
	node:updateEffects()
	node:updateProperties()
end

---@param ref tes3reference
function util.isLanternValid(ref)
	-- Make sure not to include disabled/deleted lights. These frequently
	-- result from light toggling on/off with Midnight Oil.
	if ref.disabled or ref.deleted then
		return false
	end
	local light = ref.object --[[@as tes3light]]
	if light.isOffByDefault then
		return false
	end
	local mesh = string.lower(light.mesh)
	return (lanterns[mesh] or config.whitelist[mesh]) or false
end

function util.getLights()
	---@type tes3reference[]
	local candles = {}
	for _, cell in ipairs(tes3.getActiveCells()) do
		for ref in cell:iterateReferences(tes3.objectType.light) do
			if util.isLanternValid(ref) then
				table.insert(candles, ref)
			end
		end
	end
	return candles
end


return util
