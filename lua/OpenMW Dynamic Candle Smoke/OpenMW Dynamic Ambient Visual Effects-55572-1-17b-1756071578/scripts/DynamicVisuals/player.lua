local types = require("openmw.types")
local core = require("openmw.core")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local anim = require("openmw.animation")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local camera = require("openmw.camera")
local storage = require("openmw.storage")
local async = require("openmw.async")

local v3 = util.vector3

local view		local devMode = false
local currentCell

local candles = require("scripts.DynamicVisuals.configCandleSmoke")


local function nearbyLights(table)
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
--	view = camera.getBaseViewDistance()
--	local v = view < 150000 and view or 150000
--	core.sendGlobalEvent("dcsSetDistance", v)
	core.sendGlobalEvent("dcsSetDistance", camera.getBaseViewDistance())
end

updateDistance()

local settingsG = storage.globalSection("Settings_DAVE_world")


local function uiModeChanged(e)
	local new = e.newMode		local old = e.oldMode
	if view ~= camera.getBaseViewDistance() then updateDistance()		end
	if new and uiModes[new] then
		saved = { gTime = core.getGameTime(), sTime = core.getSimulationTime() }
--		print(saved.gTime, saved.sTime)
	elseif old and uiModes[old] and settingsG:get("enable") then
		local gap = core.getGameTime() - saved.gTime
		if gap > 0 then gap =  gap / core.getGameTimeScale() - 10	end
--		print(gap, (core.getSimulationTime() - saved.sTime))
		if gap > (core.getSimulationTime() - saved.sTime) then
			if currentCell and currentCell.isExterior then
				local near = nearbyLights()
--				print("REFRESH",#near)
				if #near > 0 then
					core.sendGlobalEvent("dcsRefreshVfx", {type="lights", list=near})
				end
			else
				currentCell = nil
			end
		end
	end
end

local dust = {
	pattern = {"tomb", "barrow", "crypt", "catacomb", "burial" },
	options = { useAmbientLight = false, loop = true, vfxId = "AttachDust" },
	model = "meshes/e/taitech/dust_medium.nif",
	density = "disabled",
	active = false
}

local function attachDust(doDust)
	anim.removeVfx(self, "AttachDust")
	if not doDust or dust.density == "disabled" then
		dust.active = false
		return
	end
	if dust.active then		return		end
	anim.addVfx(self, dust.model, dust.options)
	dust.active = true
--	print("SPAWN DUST", dust.model)
end

local settings = storage.playerSection("Settings_DAVE_player")

local function updateSettings()
	local density = settings:get("dust_density"):gsub("opt_", "")
	if density ~= dust.density then
		dust.density = density
		dust.model = "meshes/e/taitech/dust_" .. density .. ".nif"
		currentCell = nil
	end
end

settings:subscribe(async:callback(updateSettings))
updateSettings()

local function collisionCheck(o, vec)
	vec = vec.V or vec.mV
	if type(vec) == "table" then vec = vec[1]		end
	local pos = o.rotation:apply(vec * o.scale) + o.position
	local res = nearby.castRenderingRay(pos, pos + util.vector3(0, 0, 100), {ignore=o})
	if not res.hitObject then		return		end
	local id = res.hitObject.recordId	local d = (res.hitPos - pos):length()
--	print("candle HIT "..id.." "..math.floor((res.hitPos - pos):length()))
	if id:find("shelf") and d < 80 then
		return true
	end
end

local skipCheck = true
local checkList

local function onFrame()
	if skipCheck then		return		end
	skipCheck = true
--	local t = core.getRealTime()
	local list = {}
	for _, v in ipairs(checkList) do
		if collisionCheck(v.obj, v.vec) then
--			print("CANDLE collision")
		else
			list[#list + 1] = v.obj
		end
	end
--	print("ELAPSED "..#checkList, core.getRealTime() - t)
	if #list > 0  then core.sendGlobalEvent("daveCandles", list)		end
end

local function onUpdate()
	if self.cell == currentCell then	return		end
	local c, doDust = self.cell		currentCell = c
	if not(c.isExterior or c:hasTag("QuasiExterior")) then
		for _, v in ipairs(dust.pattern) do 
			if c.id:find(v) then doDust = true		end
		end
	end
	attachDust(doDust)
	if c.isExterior or not settingsG:get("enable") then	return		end
	checkList = {}
	local near = nearbyLights()
	for _, o in ipairs(near) do
		local r = o.type.records[o.recordId]
		local model = r.model or ""
		-- bugfix for OMW versions before Nov 19 2024
		model = model:lower()		model = string.gsub(model, "\\", "/")
		local v = candles[model]
		if not v then
			local i, j
			i, j = string.find(model, "/[^/]*$")
			if i then model = string.sub(model, i+1, j)	v = candles[model]	end
		end

		if v then
			table.insert(checkList, {obj=o, vec=v})
			skipCheck = false
		end
	end
end

return {
	engineHandlers = { onUpdate = onUpdate, onFrame = onFrame },
	eventHandlers = {
		UiModeChanged = uiModeChanged,
		dcsRefreshVfx = function(e)
			local near = nearbyLights()
--			print("REFRESH",#near)
			if #near > 0 then
				core.sendGlobalEvent("dcsRefreshVfx", {type=e, list=near})
			end
		end,
		dcsGetNearby = function(e)
			local near = nearbyLights()
			core.sendGlobalEvent("dcsUpdateNearby", {type=e, list=near})
		end
	},
	interfaceName = "daveDev",
	interface = {
		version = 100,
		dust = attachDust,
	}
}
