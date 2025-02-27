local types = require("openmw.types")
local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local camera = require("openmw.camera")

local v3 = util.vector3

local view		local devMode = false


local function nearbyScan(table)
--	if devMode then print(table.." scan nearby")		end
	local light = types.Light	local items = nearby.items
	local list = {}
	for k = 1, #items do
		local o = items[k]
		if o.type == light and not light.records[o.recordId].isOffByDefault then
			list[#list + 1] = o
		end
	end
	return list
end

local saved = { gtime = core.getGameTime(), stime = core.getSimulationTime() }
local uiModes = {
	[I.UI.MODE.Rest] = true,
	[I.UI.MODE.Training] = true,
}

local function updateDistance()
	view = camera.getBaseViewDistance()
	local v = view < 150000 and view or 150000
	core.sendGlobalEvent("dcsSetDistance", v)
end

updateDistance()

local function uiModeChanged(e)
	local new = e.newMode		local old = e.oldMode
	if view ~= camera.getBaseViewDistance() then updateDistance()		end
	if new and uiModes[new] then
		saved = { gTime = core.getGameTime(), sTime = core.getSimulationTime() }
--		print(saved.gTime, saved.sTime)
	elseif old and uiModes[old] then
		local gap = core.getGameTime() - saved.gTime
		if gap > 0 then gap =  gap / core.getGameTimeScale() - 10	end
--		print(gap, (core.getSimulationTime() - saved.sTime))
		if gap > (core.getSimulationTime() - saved.sTime) then
			local near = nearbyScan("lightsCandles")
--			print("REFRESH",#near)
			if #near > 0 then
				core.sendGlobalEvent("dcsRefreshVfx", {type="lights", list=near})
			end
		end
	end
end

return {
	eventHandlers = {
		UiModeChanged = uiModeChanged,
		dcsRefreshVfx = function(e)
			local near = nearbyScan(e)
--			print("REFRESH",#near)
			if #near > 0 then
				core.sendGlobalEvent("dcsRefreshVfx", {type=e, list=near})
			end
		end,
		dcsGetNearby = function(e)
			local near = nearbyScan(e)
			core.sendGlobalEvent("dcsUpdateNearby", {type=e, list=near})
		end
	},
}
