local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local util = require("openmw.util")
local async = require("openmw.async")
local time = require("openmw_aux.time")

local openDialog = false
local playerobj = world.players[1]
local MWglobal = world.mwscript.getGlobalVariables()
local playercell, playerTurn = nil, 0
local pcell = {exterior=nil, prev=nil}
local weathertable = {
	["ascadian isles region"] = 0,
	["ashlands region"] = 0,
	["azura\'s coast region"] = 0,
	["bitter coast region"] = 0,
	["brodir grove region"] = 0,
	["felsaad coast region"] = 0,
	["grazelands region"] = 0,
	["hirstaang forest region"] = 0,
	["isinfier plains region"] = 0,
	["moesring mountains region"] = 0,
	["molag mar region"] = 0,
	["mournhold region"] = 0,
	["red mountain region"] = 0,
	["sheogorad"] = 0,
	["thirsk region"] = 0,
	["west gash region"] = 0,

	["aanthirin region"] = 0,
	["abecean sea region"] = 0,
	["alt orethan region"] = 0,
	["aranyon pass region"] = 0,
	["armun ashlands region"] = 0,
	["arnesian jungle region"] = 0,
	["ascadian bluffs region"] = 0,
	["boethiah\'s spine region"] = 0,
	["broken cape region"] = 0,
	["clambering moor region"] = 0,
	["colovian barrowlands region"] = 0,
	["colovian highlands region"] = 0,
	["dagon urul region"] = 0,
	["dasek marsh region"] = 0,
	["deshaan plains region"] = 0,
	["drajkmyr marsh region"] = 0,
	["druadach highlands region"] = 0,
	["falkheim region"] = 0,
	["gilded hills region"] = 0,
	["gold coast region"] = 0,
	["gorvigh mountains region"] = 0,
	["grey meadows region"] = 0,
	["helnim fields region"] = 0,
	["hirsing forest region"] = 0,
	["hrimbald plateau region"] = 0,
	["jerall mountains region"] = 0,
	["julan-shar region"] = 0,
	["kilkreath mountains region"] = 0,
	["kreathi vale region"] = 0,
	["kvetch pass region"] = 0,
	["lan orethan region"] = 0,
	["lorchwuir heath region"] = 0,
	["mephalan vales region"] = 0,
	["mhorken hills region"] = 0,
	["midkarth region"] = 0,
	["molah ruhn region"] = 0,
	["molagreahd region"] = 0,
	["mudflats region"] = 0,
	["nedothril region"] = 0,
	["northshore region"] = 0,
	["old ebonheart region"] = 0,
	["othreleth woods region"] = 0,
	["padomaic ocean region"] = 0,
	["reaver\'s shore region"] = 0,
	["rift valley region"] = 0,
	["roth roryn region"] = 0,
	["sacred lands region"] = 0,
	["salt marsh region"] = 0,
	["sea of ghosts region"] = 0,
	["seitur region"] = 0,
	["shambalun veil region"] = 0,
	["shipal-shin region"] = 0,
	["skaldring mountains region"] = 0,
	["solitude forest region"] = 0,
	["solitude forest region s"] = 0,
	["southern gold coast region"] = 0,
	["stirk isle region"] = 0,
	["sundered hills region"] = 0,
	["sundered scar region"] = 0,
	["telvanni isles region"] = 0,
	["temaris isle region"] = 0,
	["thirr valley region"] = 0,
	["throat of the world region"] = 0,
	["trolls\'s teeth mountains region"] = 0,
	["uld vraech region"] = 0,
	["valstaag highlands region"] = 0,
	["velothi mountains region"] = 0,
	["vorndgad forest region"] = 0,
	["west weald region"] = 0,
	["white plains region"] = 0,
	["wuurthal dale region"] = 0,
	["ysheim region"] = 0,

}

if not core.contentFiles.has("OpenMW_luahelper.esp") then
	print("Lua helper matching .esp not present. Please check your load order. Disabling this script ...")
	return
end
if core.contentFiles.has("OpenMW_luahelper_dialog.esp") then
	print("Loaded lua dialogue helper for MW TB BM InfoGetText events.")
end
if core.contentFiles.has("OpenMW_luahelper_dialog_tr.esp") then
	print("Loaded lua dialogue helper for Tamriel Rebuilt InfoGetText events.")
end


local function setEnabled(data)
	local obj = data[1]
	if not obj then return end
	obj.enabled = data[2]
	print(obj.recordId, "enabled ",(obj.enabled),"->",data[2])
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
	if obj == playerobj then
		playerTurn = data.angle
	else
		local rot = (obj.rotation * util.transform.rotateZ(math.rad(data.angle)))
		objMove({ object=obj, rot=rot })
	end
end

--[[
time.runRepeatedly(function()
	print(MWglobal.omwWeather)
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
	return nil
end

local function omwRotateZ(dt)
	local var = world.mwscript.getGlobalScript("omwLuaHelper", playerobj).variables
--	print(var, var.rotate, dt)
	var.rotate = playerTurn / dt
	playerTurn = 0
end

local function onUpdate(dt)
	if playerTurn ~= 0 then omwRotateZ(dt) end
	if not playerobj then return end
	local cell = playerobj.cell
	if MWglobal.omwCellChanged == 0 then return end
	local cellchange = cell ~= playercell
	if playercell == nil then playercell = cell
	elseif cell.isExterior and playercell.isExterior then
		if cell.gridX == playercell.gridX and cell.gridY == playercell.gridY then cellchange = false end
	end
	if not cellchange and MWglobal.omwCellChanged ~= 0 then
		MWglobal.omwCellChanged = 0		
		print("omw cell change suppressed")
		return
	end
	pcell.prev = playercell
	playercell = cell
	local isInterior = 1
	if cell.isExterior or cell:hasTag("QuasiExterior") then
		isInterior = nil
		weathertable[cell.region] = MWglobal.omwWeather
	-- omwWeather is inaccurate immediately after a cell change from interior->exterior
		async:newUnsavableSimulationTimer(1, function() weathertable[cell.region] = MWglobal.omwWeather end)
		pcell.exterior = cell
	else
		pcell.exterior = findExterior(cell)
	end
	local region, weather = nil, 0
	if pcell.exterior then
		region = pcell.exterior.region
		weather = weathertable[region]
		if not weather and region then weathertable[region] = 0 end
	end
	if not weather then weather = 0 end
	local data = { player=playerobj, isInterior=isInterior, weather=weather, region=region }
	MWglobal.omwCellChanged = 0
	playerobj:sendEvent("onCellChangeOlh", data)
	core.sendGlobalEvent("onCellChangeOlh", data)
end

local function onFrame(dt)
	if not openDialog then return end
	if MWglobal.diagInfoID1 == 0 then return end
	local infoId = tostring(MWglobal.diagInfoID1..MWglobal.diagInfoID2..MWglobal.diagInfoID3)
	if MWglobal.diagInfoID4 ~= 1234 then infoId = infoId..tostring(MWglobal.diagInfoID4) end
	core.sendGlobalEvent("tes3InfoGetText", {info={id=infoId, type="dialogue"}})
	playerobj:sendEvent("tes3InfoGetText", {info={id=infoId, type="dialogue"}})
	MWglobal.diagInfoID1, MWglobal.diagInfoID4 = 0, 1234
end


return {
	engineHandlers = {
		onUpdate = onUpdate,
		onPlayerAdded = function(data)
			playerobj = data
			print("Creating CellChange event")
			MWglobal = world.mwscript.getGlobalVariables(playerobj)
			MWglobal.omwCellChanged = 1
		end
	},
	eventHandlers = {
		onFrameOlh = onFrame,
		onDialogOpened = function() openDialog = true end,
		onDialogClosed = function() openDialog = false end,
		olhObjEnabled = olhObjEnabled,
		setEnabled = setEnabled,
		removeScriptOlh = function(data)
	print(data.object, "removing", data.script)
	data.object:removeScript(data.script)
	end,
		objTurn = objTurn,
		objMove = objMove
	},
	interfaceName = "LuaHelper",
	interface = {
		version = 1,
		objMove = objMove,
		objTurn = objTurn
	}

}
