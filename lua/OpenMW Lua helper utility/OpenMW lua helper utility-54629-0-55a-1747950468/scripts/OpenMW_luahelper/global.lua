local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local util = require("openmw.util")
local async = require("openmw.async")
local time = require("openmw_aux.time")

local playerRef = world.players[1]
local mwscriptCheck, dialogTarget = false
local mwGlobal
if playerRef then mwGlobal = world.mwscript.getGlobalVariables(playerRef)		end
local playerTurn, playerCell = 0
-- local prevCell = {exterior=nil, prev=nil}
local prevCell = {}
local devApi = {}

local playerRegion = ""		local playerWeather = 1
local weathertable = require("scripts.OpenMW_luahelper.configRegions")
local weatherHandlers = {}		local cellChange1Handlers = {}

if not core.contentFiles.has("OpenMW_luahelper.esp") then
	print("Lua helper matching .esp not present. Please check your load order. Disabling this script ...")
	return
end
if core.contentFiles.has("OpenMW_luahelper_dialog.esp") then
	print("Loaded lua dialogue helper for MW TB BM InfoGetText events.")
end
if core.contentFiles.has("OpenMW_luahelper_dialog_TR.esp") then
	print("Loaded lua dialogue helper for Tamriel Rebuilt InfoGetText events.")
end


local function setEnabled(data)
	local obj = data[1]
	if not obj then return end
	obj.enabled = data[2]
--	print(obj.recordId, "enabled ",(obj.enabled),"->",data[2])
end

local function objMove(data)
	local obj = data.object
	local cell = data.cell or obj.cell
	local rotation = data.rot or obj.rotation
	local position = data.pos or obj.position
	obj:teleport(cell, position, {rotation=rotation})
end

local function objTurn(data)
	local obj = data.object
	if obj == playerRef then
		playerTurn = data.angle
	else
		local rot = (obj.rotation * util.transform.rotateZ(math.rad(data.angle)))
		objMove({ object=obj, rot=rot })
	end
end

--[[
time.runRepeatedly(function()
	print(mwGlobal.omwWeather)
end, 1 * time.second)
--]]

local function findExterior(cell)
	local doors = cell:getAll(types.Door)
	for k,v in pairs(doors) do
		local c = types.Door.destCell(v)
		if c then
			if c.isExterior or c:hasTag("QuasiExterior") then return c end
		end
	end
end

local function omwRotateZ(dt)
	local var = world.mwscript.getGlobalScript("omwLuaHelper", playerRef).variables
--	print(var, var.rotate, dt)
	var.rotate = playerTurn / dt
	playerTurn = 0
end

local function getRegion(m)
	m = m or {}
	local region = ""
	local o = m.object or playerRef
	if not o then return region end
	local cell = m.cell or o.cell
	if cell.isExterior or cell:hasTag("QuasiExterior") then return cell.region end
	if m.useDoors == true then
		local extCell = findExterior(cell)
		if extCell then region = extCell.region		end
	end
	return region
end

local function getWeather(m)
	m = m or {}
	local region = m.region or getRegion(m)
	local weather = weathertable[region]
	if not weather then
		if m.useLast then weather = mwGlobal.omwWeather
		else weather = 1 end
	end
	return weather
end

local function updateWeather(force)
	local w = mwGlobal.omwWeather
	if playerWeather == w and not force then	return		end
	playerWeather = w	local cell = playerRef.cell
	if cell.isExterior or cell:hasTag("QuasiExterior") then
		weathertable[cell.region] = w
	end
	for i = 1, #weatherHandlers do	weatherHandlers[i](playerRef, w)	end
end

devApi.weather = {
	getCurrent = function(m) return weathertable[m]		end,
	getNext = function() return mwGlobal.omwWeather		end,
	getCurrentSunVisiblity = function() return 0.9		end,
	getCurrentSunPercentage = function() return 0.9		end,
	getCurrentWindSpeed = function() return 0.1		end,
	getCurrentStormDirection = function() return 0		end,
	changeWeather = function()				end,
	getAllWeather = function() return {}			end,
}

local function mwscriptInterop(dt)
	if not dialogTarget then return end
	if mwGlobal.diagInfoID1 == 0 then return end
	local infoId = tostring(mwGlobal.diagInfoID1..mwGlobal.diagInfoID2..mwGlobal.diagInfoID3)
	if mwGlobal.diagInfoID4 ~= 1234 then infoId = infoId..tostring(mwGlobal.diagInfoID4) end
	core.sendGlobalEvent("tes3InfoGetText", {info={id=infoId, type="topic"}})
	playerRef:sendEvent("tes3InfoGetText", {info={id=infoId, type="topic"}})
	dialogTarget:sendEvent("tes3InfoGetText", {info={id=infoId, type="topic"}})
	mwGlobal.diagInfoID1, mwGlobal.diagInfoID4 = 0, 1234
end

local function isExterior(c) return c.isExterior or c:hasTag("QuasiExterior")		end

local count = 0

local function onUpdate(dt)
	if mwscriptCheck then mwscriptInterop(dt)		end
	if dt == 0 then return		end
	if playerTurn ~= 0 then omwRotateZ(dt) end
	if not playerRef then return end
	count = count + 1	if count > 114 then count = 0	updateWeather()		end
	if mwGlobal.omwCellChanged == 0 then return end
	local cell = playerRef.cell
	local cellchange = cell ~= playerCell
--[[
	if playerCell == nil then playerCell = cell
	elseif cell.isExterior and playerCell.isExterior then
		if cell.gridX == playerCell.gridX and cell.gridY == playerCell.gridY then cellchange = false end
	end
--]]
	if playerCell and cell.isExterior and playerCell.isExterior then
		if cell.gridX == playerCell.gridX and cell.gridY == playerCell.gridY then
			cellchange = false
		end
	end
	if not cellchange and mwGlobal.omwCellChanged ~= 0 then
		mwGlobal.omwCellChanged = 0		
		print("omw cell change suppressed")
		return
	end

	prevCell.prev = playerCell or cell		playerCell = cell
	local isInterior = 1
	if isExterior(cell) then
		isInterior = nil
		playerRegion = cell.region
		weathertable[cell.region] = mwGlobal.omwWeather
		prevCell.exterior = cell
	else
		local extCell = findExterior(cell)
		playerRegion = extCell and extCell.region
		prevCell.exterior = extCell
	end
	local weather = 0
	if playerRegion then
		weather = weathertable[playerRegion]
		if not weather then weathertable[playerRegion] = 0		end
	end
	local data = { player=playerRef, isInterior=isInterior, weather=weather, region=playerRegion }
	mwGlobal.omwCellChanged = 0
	playerRef:sendEvent("onCellChangeOlh", data)
	core.sendGlobalEvent("onCellChangeOlh", data)
end

core.sendGlobalEvent("olhInitialized")

return {
	engineHandlers = {
		onUpdate = onUpdate,
		onPlayerAdded = function(data)
			playerRef = data
			print("Creating CellChange event")
			mwGlobal = world.mwscript.getGlobalVariables(playerRef)
			mwGlobal.omwCellChanged = 1
		end
	},
	eventHandlers = {
		onFrameOlh = mwscriptInterop,
		onDialogOpened = function(e) dialogTarget = e.arg end,
		onDialogClosed = function() dialogTarget = nil end,
		olhObjEnabled = olhObjEnabled,
		setEnabled = setEnabled,
		removeScriptOlh = function(data)
	print(data.object, "removing", data.script)
	data.object:removeScript(data.script)
	end,
		objTurn = objTurn,
		objMove = objMove,
		onCellChangeOlh = function()
			updateWeather(true)
			for i = 1, #cellChange1Handlers do	cellChange1Handlers[i](playerRef)	end
		end
	},
	interfaceName = "luaHelper",
	interface = {
		version = 55,
		objMove = objMove,
		objTurn = objTurn,
		getRegion = getRegion,
		getWeather = getWeather,
		addWeatherHandler = function(h) weatherHandlers[#weatherHandlers + 1] = h	end,
		addCellChange1Handler = function(h)
			cellChange1Handlers[#cellChange1Handlers + 1] = h
		end,
		weather = devApi.weather
	}

}
