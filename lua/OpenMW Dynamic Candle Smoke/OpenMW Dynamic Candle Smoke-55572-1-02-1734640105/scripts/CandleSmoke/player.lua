local types = require("openmw.types")
local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v3 = util.vector3

local vectors = require("scripts.CandleSmoke.modelLookup")


local function refreshVfx()
--	ui.showMessage("Candle VFX refresh")
	local light = types.Light	local items = nearby.items
	local candles = {}
	for k = 1, #items do
		local o = items[k]
		if o.type == light and not light.record(o).isOffByDefault then
			local model = light.record(o).model or ""	model = model:lower()

			--	OMW versions before Nov 19 2024
			model = string.gsub(model, "\\", "/")

			local i, j
			i, j = string.find(model, "/[^/]*$")
			if i then model = string.sub(model, i+1, j) end
			if vectors[model] then candles[#candles + 1] = o	end
		end
	end
	if #candles > 0 then core.sendGlobalEvent("doCandleSmoke", candles)	end
end

local saved = { gtime = core.getGameTime(), stime = core.getSimulationTime() }
local uiModes = {
	[I.UI.MODE.Rest] = true,
	[I.UI.MODE.Training] = true,
}

local function uiModeChanged(e)
	local new = e.newMode		local old = e.oldMode
	if new and uiModes[new] then
		saved = { gTime = core.getGameTime(), sTime = core.getSimulationTime() }
--		print(saved.gTime, saved.sTime)
	elseif old and uiModes[old] then
		local gap = core.getGameTime() - saved.gTime
		if gap > 0 then gap =  gap / core.getGameTimeScale() - 10	end
--		print(gap, (core.getSimulationTime() - saved.sTime))
		if gap > (core.getSimulationTime() - saved.sTime) then refreshVfx()		end
	end
end

return {
	eventHandlers = { UiModeChanged = uiModeChanged },
}
