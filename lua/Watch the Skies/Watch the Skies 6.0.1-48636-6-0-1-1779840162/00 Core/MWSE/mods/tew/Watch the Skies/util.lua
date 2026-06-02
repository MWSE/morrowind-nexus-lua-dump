local util = {}

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog

function util.updateController()
	local WtC = tes3.worldController.weatherController
	if not WtC then return end

	-- if WtC.nextWeather then
	-- 	local t = WtC.transitionScalar
	-- 	WtC:switchTransition(WtC.nextWeather.index)
	-- 	WtC.transitionScalar = t
	-- else
	-- 	WtC:switchImmediate(WtC.currentWeather.index)
	-- end

	if tes3.player then
		WtC:updateVisuals()
	end
	debugLog("Weather controller updated.")
end

function util.metadataMissing()
	local msg = "Error! Watch the Skies-metadata.toml file is missing. Please install."
	tes3.messageBox { message = msg }
	error(msg)
end

function util.getRegionWeatherChances()
	local seasonalChances = require("tew.Watch the Skies.components.seasonalChances")

	for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
		if not seasonalChances[region.id] then
			local values = string.format(
				"{ %d, %d, %d, %d, %d, %d, %d, %d, %d, %d }",
				region.weatherChanceClear,
				region.weatherChanceCloudy,
				region.weatherChanceFoggy,
				region.weatherChanceOvercast,
				region.weatherChanceRain,
				region.weatherChanceThunder,
				region.weatherChanceAsh,
				region.weatherChanceBlight,
				region.weatherChanceSnow,
				region.weatherChanceBlizzard
			)

			mwse.log(string.format([[
			["%s"] = {
				[1] = %s,
				[2] = %s,
				[3] = %s,
				[4] = %s,
				[5] = %s,
				[6] = %s,
				[7] = %s,
				[8] = %s,
				[9] = %s,
				[10] = %s,
				[11] = %s,
				[12] = %s,
			},
			]],
				region.name,
				values, values, values, values,
				values, values, values, values,
				values, values, values, values
			))
		end
	end
end

return util
