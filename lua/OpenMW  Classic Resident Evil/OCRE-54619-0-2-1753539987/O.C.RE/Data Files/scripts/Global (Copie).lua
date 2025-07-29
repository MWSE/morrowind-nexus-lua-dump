-- Save to my_lua_mod/scripts/example/player.lua


local util = require('openmw.util')
local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local vfs = require("openmw.vfs")
local deepToString=require('openmw_aux.util').deepToString
local players = world.players
local activecell
local activecam=nil
local targetcam
local lastcam
local lastcell
local MSK={}
local PointP
local L01=nil
local L12=nil
local L23=nil
local L30=nil
local L0P=nil
local L1P=nil
local L2P=nil
local L3P=nil
local BCG=nil
local ROOMS={}
local Cutscene={}
Cutscene[1]=false
Saves={}
local SelectionChoice={}
local LiveSelection=false
local ContainerLinked={}
ContainerLinked.items={}
ContainerLinked.lastcontainer=nil
ContainerLinked.TeleportTempo=5

local Puzzle=false
local Lockpicking={}



local code ="return({"
for i,book in ipairs(types.Book.records) do
	if string.find(book.id,"_rdt_")~=nil then
		--print(book.id)
		code = code..book.text..","
	end
end
code = code.."})"
ROOMS=util.loadCode(code,{util = require('openmw.util')})()
for i, cell in pairs (ROOMS) do
	print(i)
end



local function Container(data)
	types.Container.inventory(data.container):resolve()
	if types.Container.records[data.container.recordId].mwscript=="_container_linked" then
		--print("THEREE")
		if data.action=="out" then
			if data.Item then
				print("out1")
				print(data.Item)
				data.Item:moveInto(types.Actor.inventory(data.player))
				core.sendGlobalEvent('Container', {container=data.container, player=nil,action="out",Item = nil})
				
				for i, item in pairs(types.Container.inventory(data.container):getAll()) do
					print(item)
				end
			else
				print("out2")
				ContainerLinked.items[data.container.recordId]=types.Container.inventory(data.container):getAll()
				for i, item in pairs(ContainerLinked.items[data.container.recordId]) do
					print(item)
				end
			end
		elseif data.action=="in" then
			if data.Item then
				print("in1")
				print(data.Item)
				data.Item:moveInto(types.Container.content(data.container))
				core.sendGlobalEvent('Container', {container=data.container, player=nil,action="in",Item = nil})
				for i, item in pairs(types.Container.inventory(data.container):getAll()) do
					print(item)
				end
			else
				print("in2")
				for i, item in pairs(types.Container.inventory(data.container):getAll()) do
					print(item)
				end
				ContainerLinked.items[data.container.recordId]=types.Container.inventory(data.container):getAll()
				for i, item in pairs(ContainerLinked.items[data.container.recordId]) do
					print(item)
				end
			end



		elseif data.action=="activate" then
			print(ContainerLinked.lastcontainer)
			print(data.container)
			if ContainerLinked.lastcontainer~=data.container then
				--print(data.container.recordId)
				print(ContainerLinked.items)
				ContainerLinked.TeleportTempo=0
				if ContainerLinked.items[data.container.recordId] then
					print("HEHEHEHERE")
					for i, item in pairs(types.Container.inventory(data.container):getAll()) do
						print("remove "..item.recordId)
						item:remove()
					end
					print(data.container.recordId)
					print(ContainerLinked.items[data.container.recordId])
					for i, item in pairs(ContainerLinked.items[data.container.recordId]) do
						if item and item.count>0 then
							item:moveInto(data.container)
							print("teleport "..item.recordId)
						end
					end
				end
				
				ContainerLinked.lastcontainer=data.container
			end

		end
	end
	if data.player then
		data.player:sendEvent('ActiveContainer',{container=data.container})
	end

end


local function pushContainer(data)
	if data.Container.count>0 then
		if data.startPos~=nil then
			data.Container:teleport(data.Container.cell,data.startPos)
		end
		if data.Way=="X+" then
			data.Container:teleport(activecell,util.transform.move(-1,0,0)*data.Container.position)
		end
		if data.Way=="X-" then
			data.Container:teleport(activecell,util.transform.move(1,0,0)*data.Container.position)
		end
		if data.Way=="Y+" then
			data.Container:teleport(activecell,util.transform.move(0,-1,0)*data.Container.position)
		end
		if data.Way=="Y-" then
			data.Container:teleport(activecell,util.transform.move(0,1,0)*data.Container.position)
		end
		if data.Way=="Z-" then
			data.Container:teleport(activecell,util.transform.move(0,0,-1)*data.Container.position)
		end
	end
end


local function Teleport(data)
	if data.DestCell then
		data.object:teleport(data.DestCell,data.position,data.rotation)	
	elseif data.object.parentContainer then
		data.object:teleport(data.object.parentContainer.cell,data.position,data.rotation)	
	else
		data.object:teleport(data.object.cell,data.position,data.rotation)
	end
end

local function SetScale(data)
	data.object:setScale(data.scale)
end


local BlinkingMaskTimer=0
local function BlinkingMask(data)
	if MSK[data.Mask].enabled then
		BlinkingMaskTimer=BlinkingMaskTimer+1
		if BlinkingMaskTimer==50 then
			MSK[data.Mask].enabled=false
			BlinkingMaskTimer=0
		end
	elseif MSK[data.Mask].enabled==false then
		MSK[data.Mask].enabled=true
	end
end


local function MoveInto(data)
	if data.newItem then
		print(data.newItem)
		if data.actor then
			world.createObject(data.newItem):moveInto(types.Actor.inventory(data.actor))
		elseif data.container then
			world.createObject(data.newItem):moveInto(types.Container.content(data.container))
		end
	elseif data.Item then
		if data.actor then
			data.Item:moveInto(types.Actor.inventory(data.actor))
		elseif data.container then
			data.Item:moveInto(types.Container.content(data.container))
		end
	end
end

local function setCharge(data)
	print("setcharge"..tostring(data.Item))
	print("setcharge"..tostring(data.value))
	if data.value>=0 then
		types.Item.setEnchantmentCharge(data.Item,data.value)
	end
end

local function createAmmosinInventory(data)
	world.createObject(data.ammo,data.number):moveInto(types.Actor.inventory(data.actor))
end

local function CreateNewObject(data)
	world.createObject(data.RecordId):teleport(data.Player.cell,data.position)
end

local function RemoveItem(data)
	print("removeditem "..tostring(data.Item))
	print("removeitem "..tostring(data.number))
	if data.Item.count>0 and data.number>0 and data.Item then
		data.Item:remove(data.number)
	end
end




local function ReturnLocalScriptVariable(data)
	print(data.value)
	print(data.Player)
	print(data.GameObject)
	print(data.Variable)
	print(world.mwscript.getLocalScript(data.GameObject,data.Player).variables[data.Variable])
	if world.mwscript.getLocalScript(data.GameObject,data.Player) then
		if world.mwscript.getLocalScript(data.GameObject,data.Player).variables[data.Variable] then
			world.mwscript.getLocalScript(data.GameObject,data.Player).variables[data.Variable]=data.value
		end
		print(world.mwscript.getLocalScript(data.GameObject,data.Player).variables[data.Variable])
	end
end


local LastMessageBoxText=nil

local function ReturnGlobalVariable(data)
	world.mwscript.getGlobalVariables(data.player)[data.variable]=data.value
	print(data.variable)
	print(data.value)
	if data.puzzle==true then	
		Puzzle=false
	end
	if LastMessageBoxText~=nil then
		LastMessageBoxText=nil
	end
	
end


SpecialAmmo={}
local function CreateSpecialAmmo(data)
	local RotZ=data.Player.rotation:getPitch()
	local RotX=data.Player.rotation:getYaw()
	SpecialAmmoVector=util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX),-math.sin(RotZ))*3
	Ammo=data.Ammo
	Special=world.createObject(data.Ammo)
	Special:addScript("scripts/SpecialAmmo.lua")
	print(Special)
	Special:teleport(data.Player.cell,util.vector3(0,0,110)+data.Player.position+util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX),-math.sin(RotZ))*50)
	SpecialAmmo[1]=true
end



local function Disable(data)
	print("disable")
	data.Object.enabled=false
end	
---------Essaie pour activer le script des armes dans l'inventaire
--for i, player in ipairs(world.players) do
--	for j, weapon in ipairs(types.Actor.inventory(player):getAll(types.weapons)) do
--		weapon:activateBy(player)
--		--weapon:addScript("scripts/Weapon.lua") 
--	end
--end

local function CreateSwitchzoneBorders(data)
	for i, object in pairs(data.player.cell:getAll()) do
		if object.type==types.Activator then
			if string.find(types.Activator.records[object.recordId].name," border") and string.find(types.Activator.records[object.recordId].name,"SwitchZone") then
				object.enabled=false
				object:remove()
			end
		end
	end
	local angle=0
	if data.point1.position.x<data.point2.position.x then
		if data.point1.position.y<data.point2.position.y then
			angle=math.acos((data.point2.position.x-data.point1.position.x)/((data.point1.position-data.point2.position):length()))
		else
			angle=-math.acos((data.point2.position.x-data.point1.position.x)/((data.point1.position-data.point2.position):length()))
		end
	else
		if data.point1.position.y<data.point2.position.y then
			angle=math.acos((data.point2.position.x-data.point1.position.x)/((data.point1.position-data.point2.position):length()))
		else
			angle=-math.acos((data.point2.position.x-data.point1.position.x)/((data.point1.position-data.point2.position):length()))
		end
	end
	
	for d=1,(data.point1.position-data.point2.position):length() do 
		if d%15==0 then
			world.createObject(world.createRecord(types.Activator.createRecordDraft({name=data.switchzone.." border",model=('meshes/Point'..data.switchzone..'border.nif')})).id,1):teleport(data.player.cell.name,data.point1.position+util.vector3(math.cos(angle),math.sin(angle),0)*d)
		end
	end	


	angle=0
	if data.point2.position.x<data.point3.position.x then
		if data.point2.position.y<data.point3.position.y then
			angle=math.acos((data.point3.position.x-data.point2.position.x)/((data.point2.position-data.point3.position):length()))
		else
			angle=-math.acos((data.point3.position.x-data.point2.position.x)/((data.point2.position-data.point3.position):length()))
		end
	else
		if data.point2.position.y<data.point3.position.y then
			angle=math.acos((data.point3.position.x-data.point2.position.x)/((data.point2.position-data.point3.position):length()))
		else
			angle=-math.acos((data.point3.position.x-data.point2.position.x)/((data.point2.position-data.point3.position):length()))
		end
	end
	
	for d=1,(data.point2.position-data.point3.position):length() do 
		if d%15==0 then
			world.createObject(world.createRecord(types.Activator.createRecordDraft({name=data.switchzone.." border",model=('meshes/Point'..data.switchzone..'border.nif')})).id,1):teleport(data.player.cell.name,data.point2.position+util.vector3(math.cos(angle),math.sin(angle),0)*d)
		end
	end


	angle=0
	if data.point3.position.x<data.point4.position.x then
		if data.point3.position.y<data.point4.position.y then
			angle=math.acos((data.point4.position.x-data.point3.position.x)/((data.point3.position-data.point4.position):length()))
		else
			angle=-math.acos((data.point4.position.x-data.point3.position.x)/((data.point3.position-data.point4.position):length()))
		end
	else
		if data.point3.position.y<data.point4.position.y then
			angle=math.acos((data.point4.position.x-data.point3.position.x)/((data.point3.position-data.point4.position):length()))
		else
			angle=-math.acos((data.point4.position.x-data.point3.position.x)/((data.point3.position-data.point4.position):length()))
		end
	end
	
	for d=1,(data.point3.position-data.point4.position):length() do 
		if d%15==0 then
			world.createObject(world.createRecord(types.Activator.createRecordDraft({name=data.switchzone.." border",model=('meshes/Point'..data.switchzone..'border.nif')})).id,1):teleport(data.player.cell.name,data.point3.position+util.vector3(math.cos(angle),math.sin(angle),0)*d)
		end
	end


	angle=0
	if data.point4.position.x<data.point1.position.x then
		if data.point4.position.y<data.point1.position.y then
			angle=math.acos((data.point1.position.x-data.point4.position.x)/((data.point4.position-data.point1.position):length()))
		else
			angle=-math.acos((data.point1.position.x-data.point4.position.x)/((data.point4.position-data.point1.position):length()))
		end
	else
		if data.point4.position.y<data.point1.position.y then
			angle=math.acos((data.point1.position.x-data.point4.position.x)/((data.point4.position-data.point1.position):length()))
		else
			angle=-math.acos((data.point1.position.x-data.point4.position.x)/((data.point4.position-data.point1.position):length()))
		end
	end
	
	for d=1,(data.point4.position-data.point1.position):length() do 
		if d%15==0 then
			world.createObject(world.createRecord(types.Activator.createRecordDraft({name=data.switchzone.." border",model=('meshes/Point'..data.switchzone..'border.nif')})).id,1):teleport(data.player.cell.name,data.point4.position+util.vector3(math.cos(angle),math.sin(angle),0)*d)
		end
	end	

end



SwitchZone={}
SwitchZone.Points={}
SwitchZone.Axis=nil
local function SHSwitchZones(data)
	if data.SH==0 then
		SwitchZone.Axis=world.createObject("SwitchZoneAxis")
		SwitchZone.Axis:setScale(data.AxisScale)
		SwitchZone.Axis:teleport(data.Player.cell.name,data.AxisPosition)
		for i, switchzone in pairs(ROOMS[data.Player.cell.name][data.cam].SwitchZone) do
			SwitchZone.Points[i]={}
			for p, point in pairs(switchzone) do
				if (p=="Point0" or p=="Point1" or p=="Point2" or p=="Point3") then
					SwitchZone.Points[i][p]=	world.createObject(world.createRecord(types.Activator.createRecordDraft({name=i..p.." to "..switchzone.Camera,model=('meshes/Point'..i..p..'.nif')})).id,1)
					--print(i..p.." :  "..tostring(SwitchZone.Points[i][p]))
					SwitchZone.Points[i][p]:teleport(data.Player.cell.name,util.vector3(point.x,point.y,data.Player.position.z))
				else
					SwitchZone.Points[i][p]=point
				end
			end
		end
	elseif data.SH==1 then
		SwitchZone.Axis:remove()
		for i, switchzone in pairs(SwitchZone.Points) do
			for p, point in pairs(switchzone) do
				if point.type==types.Activator then
					point.enabled=false
					point:remove()
				end
			end
		end
		SwitchZone.Points={}
		for i, object in pairs(data.Player.cell:getAll()) do
			if object.type==types.Activator then
				if string.find(types.Activator.records[object.recordId].name,"SwitchZone") and string.find(types.Activator.records[object.recordId].name," border") then
					object.enabled=false
					object:remove()
				end
			end
		end
	elseif data.SH==3 then
		for i, switchzone in pairs(SwitchZone.Points)do
			if switchzone.Point0.type==types.Activator then
				ROOMS[data.Player.cell.name][data.cam].SwitchZone[i]["Point0"]=util.vector2(switchzone.Point0.position.x,switchzone.Point0.position.y)
				ROOMS[data.Player.cell.name][data.cam].SwitchZone[i]["Point1"]=util.vector2(switchzone.Point1.position.x,switchzone.Point1.position.y)
				ROOMS[data.Player.cell.name][data.cam].SwitchZone[i]["Point2"]=util.vector2(switchzone.Point2.position.x,switchzone.Point2.position.y)
				ROOMS[data.Player.cell.name][data.cam].SwitchZone[i]["Point3"]=util.vector2(switchzone.Point3.position.x,switchzone.Point3.position.y)
				if data.TargetCam[i] then
					ROOMS[data.Player.cell.name][data.cam].SwitchZone[i]["Camera"]=data.TargetCam[i]
					print(i)
					print(data.TargetCam[i])
				end
			end
		end
	elseif data.SH==4 then

		data.Player:sendEvent('DefineSwitchZones',{SwitchZonePoints=SwitchZone.Points})

	end
	if data.SH~=4 then
		core.sendGlobalEvent('SHSwitchZones',{Player=data.Player,SH=4, cam=data.cam})
	end
end


local function PlaceBgdMsk(activecell,activecam,player)
	for i, switchzone in pairs(SwitchZone.Points) do
		for p, point in pairs(switchzone) do
			if point.type==types.Activator and point:isValid() and point.count>0 then
				point.enabled=false
				print(point:isValid())
				point:remove()
			end
		end
	end
	for i, object in pairs(player.cell:getAll()) do
		if object.type==types.Activator then
			if string.find(types.Activator.records[object.recordId].name,"SwitchZone") and string.find(types.Activator.records[object.recordId].name," border") and object:isValid() then
				object.enabled=false
				object:remove()
			end
		end
	end
	
	--print(ROOMS[activecell][activecam].name)

	-------------- Creation des Masks
	--print(ROOMS[activecell][activecam].MASK.mask1.scale)
	local RotMskZ=ROOMS[activecell][activecam].Pitch
	local RotMskX=ROOMS[activecell][activecam].Yaw
	local MskNum=1

	for i=1,20 do
		--print(activecell)
		--print(ROOMS[activecell][activecam].name)
		if vfs.fileExists('meshes/Masks/'..activecell..ROOMS[activecell][activecam].name.."MASK"..i..'.nif') then
			if ROOMS[activecell][activecam].MASK[i]==nil then
				table.insert(ROOMS[activecell][activecam].MASK,{["idname"]=tostring(activecell..ROOMS[activecell][activecam].name.."MASK"..i),["depth"]=1})
			end
		else
			break
		end	
	end


	for d, msk in pairs(ROOMS[activecell][activecam].MASK) do
		if MSK[d] then
			MSK[d].enabled=false
			MSK[d]:remove()
			MSK[d]=nil
		end
		--print(ROOMS[activecell][activecam].MASK[MskNum])
		if ROOMS[activecell][activecam].MASK[MskNum] and vfs.fileExists('meshes/Masks/'..ROOMS[activecell][activecam].MASK[MskNum].idname..'.nif') then --ROOMS[activecell][activecam].MASK[d].depth>0 then
			MSK[MskNum]=world.createObject(world.createRecord(types.Activator.createRecordDraft({name=ROOMS[activecell][activecam].MASK[MskNum].idname,model=('meshes/Masks/'..ROOMS[activecell][activecam].MASK[MskNum].idname..'.nif')})).id,1)
			print(MSK['MSK'..d])
			print("here")
			MSK[MskNum]:teleport(activecell,ROOMS[activecell][activecam].Position +util.vector3(math.cos(RotMskZ) * math.sin(RotMskX), math.cos(RotMskZ) * math.cos(RotMskX),-math.sin(RotMskZ))* ROOMS[activecell][activecam].MASK[d].depth,
				MSK[MskNum].rotation*util.transform.rotateZ(ROOMS[activecell][activecam].Yaw)*util.transform.rotateX(ROOMS[activecell][activecam].Pitch))
			MSK[MskNum]:setScale(ROOMS[activecell][activecam].MASK[d].depth/5000)
			print(MSK[MskNum])
			print(MskNum)
			MskNum=MskNum+1
		end
	end
			
	if BGD and BGD:isValid() and BGD.count>0 then
		BGD:remove()
		--BGD.enabled=false
	end
	if ROOMS[activecell][activecam].bgd.idname~="" then
		if vfs.fileExists('meshes/bgd/'..ROOMS[activecell][activecam].bgd.idname..'.nif') then
			if ROOMS[activecell][activecam].bgd["depth"]==nil then
				--table.insert(ROOMS[activecell][activecam].bgd,"depth")
				ROOMS[activecell][activecam].bgd.depth=5000
			end
			print("BGD depth"..tostring(ROOMS[activecell][activecam].bgd.depth))
			BGD=world.createObject(world.createRecord(types.Activator.createRecordDraft({name=ROOMS[activecell][activecam].bgd.idname,model=('meshes/bgd/'..ROOMS[activecell][activecam].bgd.idname..'.nif')})).id,1)			
			BGD:teleport(activecell,ROOMS[activecell][activecam].Position +util.vector3(math.cos(RotMskZ) * math.sin(RotMskX), math.cos(RotMskZ) * math.cos(RotMskX),-math.sin(RotMskZ))*ROOMS[activecell][activecam].bgd.depth,
			BGD.rotation*util.transform.rotateZ(ROOMS[activecell][activecam].Yaw)*util.transform.rotateX(ROOMS[activecell][activecam].Pitch))
			BGD:setScale(ROOMS[activecell][activecam].bgd.depth/5000)
		end
	end
	CamRotation=util.vector2(ROOMS[activecell][activecam].Pitch,ROOMS[activecell][activecam].Yaw)
	player:sendEvent('CameraPos', {source=player.object, ROOMS=ROOMS, BGDepth=ROOMS[activecell][activecam].bgd.depth,CamPos=ROOMS[activecell][activecam].Position, CamAng=CamRotation, ActiveCam=activecam,ActiveBkg=BGD,MSKList=ROOMS[activecell][activecam].MASK})
	print("Change cam")

end


local function changeCam(data)
	ROOMS[data.player.cell.name][data.ActivCam].Position=data.CamPos
	ROOMS[data.player.cell.name][data.ActivCam].Pitch=data.CamPitch
	ROOMS[data.player.cell.name][data.ActivCam].Yaw=data.CamYaw
	ROOMS[data.player.cell.name][data.ActivCam].bgd.depth=data.BGDepth
	ROOMS[data.player.cell.name][data.ActivCam].bgd.Anglez=data.CamYaw
	ROOMS[data.player.cell.name][data.ActivCam].bgd.Anglex=data.CamPitch
	ROOMS[data.player.cell.name][data.ActivCam].MASK=data.MSKList

	PlaceBgdMsk(data.player.cell.name,data.ActivCam,data.player)
end

local function CreateCheckedObject (data)
	local Show={}
	Show.Object=world.createObject(data.object)
	Show.Light=world.createObject("LightforUiObjects")
	Show.Object:setScale(0.05)
--	Show.Object:teleport(data.player.cell.name,data.Position)
--	Show.Light:teleport(data.player.cell.name,data.Position)
	Show.Object:teleport(data.player.cell.name,data.PositionObject)
	Show.Light:teleport(data.player.cell.name,data.PositionLight)
	data.player:sendEvent('ReturnCheckedObject',{Object=Show.Object,Light=Show.Light})
end


local function Lockpick(data)
	Lockpicking.Object={}
	Lockpicking.Object.Fixe=world.createObject("LockFix")
	Lockpicking.Object.Fixe:setScale(0.05)
	Lockpicking.Object.Fixe:teleport(data.Actor.cell.name,util.vector3(0,0,0))
	Lockpicking.Object.Rot=world.createObject("LockRot")
	Lockpicking.Object.Rot:setScale(0.05)
	Lockpicking.Object.Rot:teleport(data.Actor.cell.name,util.vector3(0,0,0))
	Lockpicking.Object.LockPick=world.createObject("UILockPick")
	Lockpicking.Object.LockPick:setScale(0.05)
	Lockpicking.Object.LockPick:teleport(data.Actor.cell.name,util.vector3(0,0,0))
	Lockpicking.Object.Light=world.createObject("LightforUiObjects")
	Lockpicking.Object.Light:teleport(data.Actor.cell.name,util.vector3(0,0,0))
	Lockpicking.Check=1
	Lockpicking.Actor=data.Actor
	Lockpicking.Lockable=data.Lockable
	Lockpicking.Value=data.Value

end

local function table_to_string(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- Check the key type (ignore any numerical keys - assume its an array)
        if type(k) == "string" then
            result = result.."[\""..k.."\"]".."="
        end

        -- Check the value type
        if type(v) == "table" then
            result = result..table_to_string(v)
        elseif type(v) == "boolean" then
            result = result..tostring(v)
        elseif type(v) == "number" then
            result = result..tostring(v)
		elseif type(v) == "userdata" then
			if string.find(tostring(v),",",string.find(tostring(v),",")+1) then
				result=result.."util.vector3"..tostring(v)
			else
				result=result.."util.vector2"..tostring(v)
			end
        else
            result = result.."\""..v.."\""
        end
        result = result..","
    end
    -- Remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len()-1)
    end
    return (result.."}")
end


local function saveRDT(data)
	print(tostring(activecell).."="..table_to_string(ROOMS[data.Cell]))
    --print(string.gsub(string.gsub(deepToString(ROOMS[data.Cell],7), "\n",""),"\t",""))
end

local SaveNum=0

local function onSave()
	for d, msk in pairs(ROOMS[activecell][activecam].MASK) do
		if MSK[d] then
			MSK[d].enabled=false
			MSK[d]:remove()
			MSK[d]=nil
		end
	end
			
	if BGD and BGD:isValid() and BGD.count>0 then
		BGD:remove()
		--BGD.enabled=false
	end
	return{activecam=activecam,Savenum=SaveNum,ContainerLinked=ContainerLinked}
end

local function onLoad(data)
	activecam=data.activecam
	SaveNum=data.Savenum
	print(data.ContainerLinked)
	print(ContainerLinked)
	ContainerLinked=data.ContainerLinked
end

local function ReceiveSaves(data)
	print("Saves received by Global")
	if Saves[1]==nil then
		Saves=data.saves
	end
end

local function ReceiveSaveNum(data)
	SaveNum=data.savenum
end

local function AskObjectsInWorld(data)
	local OIM={}
	local OIW={}
	local Mapped={}
	local objects={}
	local Text
	for i, cell in ipairs(world.cells) do
		--table.insert(OIW,cell)
		--print(OIW.cell)
		objects={}
		for i, object in ipairs(cell:getAll()) do
			if object.type==types.Weapon or object.type==types.Potion or object.type==types.Miscellaneous or object.type==types.Lockpick or (object.type==types.Light and types.Light.records[object.recordId].isCarriable==true) then
				--print(object.recordId)
				Text=object.type.records[object.recordId].name
				Text=Text:gsub("^%l", string.upper)
				table.insert(objects,Text)
			elseif object.type==types.Container then
				if types.Container.records[object.recordId].mwscript~="climbable" and types.Container.records[object.recordId].mwscript~="pushable" and types.Container.records[object.recordId].mwscript~="climbable_pushable" then
					if types.Container.records[object.recordId].mwscript=="_container_linked" then
						table.insert(objects,"Container (teleport)")
					elseif types.Container.inventory(object):getAll()==nil then
						table.insert(objects,"Container (empty)")
					else 
						table.insert(objects,"Container")
					end
				end
			end
		end
		OIW[cell.name]=objects
		--print(OIW[cell])
	end
	
	for i, variable in pairs(world.mwscript.getGlobalVariables(data.player)) do 
		if string.find(i,"objectmap")~=nil and variable==1 then
			OIM[i]=variable
		elseif string.find(i,"map:")~=nil and variable==1 then
			for j, area in pairs(data.maps) do
				if string.gsub(string.match(i,".*-",string.find(i,":")+1),"-","")==area[1] then
					if Mapped[j]==nil then
						Mapped[j]={}
					end
					Mapped[j][1]=area[1]
					if Mapped[j][2]==nil then
						Mapped[j][2]={}
					end
					for k, zone in pairs(area[2]) do
						if zone[1]==string.match(i,".*",string.find(i,"-")+1) then
							Mapped[j][2][k]=zone
						end
					end
				end

			end	
		end
	end
--	print("Table")
--	for j, area in pairs(Mapped) do
--		print(area[1].."  "..j)
--		for k, zone in pairs(area[2]) do
--			print(zone[1].."  "..k)
--			for l, room in pairs(zone[2]) do
--				print(room.."  "..l)
--			end
--		end
--	end

	data.player:sendEvent('ReturnObjectsInWorld',{Objects=OIW,ObjectsInMap=OIM,Mapped=Mapped})
end

local function Unlock(data)
	types.Lockable.unlock(data.Lockable)
	Lockpicking={}
end	

local function LocalVariableCheck(data)
--	print(data.Variable)
--	print(world.mwscript.getLocalScript(data.Object,data.Player).variables[1])
	if data.Variable=="crowbarvalue" and world.mwscript.getLocalScript(data.Object,data.Player) and  world.mwscript.getLocalScript(data.Object,data.Player).variables[data.Variable] and world.mwscript.getLocalScript(data.Object,data.Player).variables[data.Variable]>0 and world.mwscript.getLocalScript(data.Object,data.Player).variables[data.Variable]<11 then
		data.Player:sendEvent("CrowbarPuzzle", {value=world.mwscript.getLocalScript(data.Object,data.Player).variables[data.Variable],Object=data.Object})
	elseif data.Variable=="electricalpanelpuzzle" and world.mwscript.getLocalScript(data.Object,data.Player) and world.mwscript.getLocalScript(data.Object,data.Player).variables and world.mwscript.getLocalScript(data.Object,data.Player).variables[data.Variable] and world.mwscript.getLocalScript(data.Object,data.Player).variables[data.Variable]==1 then
		data.Player:sendEvent("ElectricalPanelPuzzle", {Value=world.mwscript.getLocalScript(data.Object,data.Player).variables[data.Variable],Object=data.Object})
	--print("check")
	print(data.Variable)
	print(world.mwscript.getLocalScript(data.Object,data.Player).variables[data.Variable])
	end

end


return {
	eventHandlers = {CreateNewObject=CreateNewObject, LocalVariableCheck=LocalVariableCheck,Unlock=Unlock,Lockpick=Lockpick,Container=Container, CreateCheckedObject=CreateCheckedObject, CreateSwitchzoneBorders=CreateSwitchzoneBorders,SHSwitchZones=SHSwitchZones,AskObjectsInWorld=AskObjectsInWorld,ReceiveSaveNum=ReceiveSaveNum,ReceiveSaves=ReceiveSaves,BlinkingMask=BlinkingMask,saveRDT=saveRDT,ReturnGlobalVariable=ReturnGlobalVariable,Disable=Disable,CreateSpecialAmmo=CreateSpecialAmmo,ReturnLocalScriptVariable=ReturnLocalScriptVariable,PushContainer = pushContainer, Teleport=Teleport,MoveInto=MoveInto, setCharge=setCharge; RemoveItem=RemoveItem, createAmmosinInventory=createAmmosinInventory,SetScale=SetScale,changeCam=changeCam },
    engineHandlers = {
		onSave=onSave,
		onLoad=onLoad,
        onUpdate = function()



			

			if Lockpicking.Check==1 then
				Lockpicking.Check=2
			elseif Lockpicking.Check==2 then
				Lockpicking.Actor:sendEvent("LockPicking", {Value=Lockpicking.Value,Lockable=Lockpicking.Lockable,Object=Lockpicking.Object})
				Lockpicking.Check=3
			end


			if ContainerLinked.TeleportTempo<5 then---update ContainerLinked.items after :teleport an :moveInto
				ContainerLinked.TeleportTempo=ContainerLinked.TeleportTempo+1
				if ContainerLinked.TeleportTempo==4 then	
					print("recordid "..ContainerLinked.lastcontainer.recordId)			
					ContainerLinked.items[ContainerLinked.lastcontainer.recordId]=types.Container.inventory(ContainerLinked.lastcontainer):getAll()
				end
			end

        	if SpecialAmmo[1] then
				if SpecialAmmo[2] then
					print(Special.cell)
					Special:sendEvent('start',{Vector=SpecialAmmoVector,Ammo=Ammo})
					print(Special)
					SpecialAmmo={}
				else 
					SpecialAmmo[2]=true
					print("activateSpecial2")
				end
			end
        	
            for i, player in ipairs(players) do

        		PointP=util.vector2(player.position.x,player.position.y)
        		activecell=player.cell.name
				--print(activecell)

				for i , container in pairs(player.cell:getAll(types.Container)) do 
					if string.find(types.Container.records[container.recordId].mwscript,"climbable")~=nil then
						interfaces.Activation.addHandlerForObject(container,function(container,actor) return false end)
					elseif types.Container.records[container.recordId].mwscript=="_container_linked" then
						--interfaces.Activation.addHandlerForObject(container,function(container,actor) return false end)
					end
				end




				----------savingMenu
				if world.mwscript.getGlobalVariables(player)["SavingMenu"]==1 then
					types.Player.sendMenuEvent(player, 'AskSaves', {value=nil,})
					--for i, save in pairs(Saves) do print(i) end
					if Saves[1] then
						Saves[11]=SaveNum
						print(Saves[11])
						player:sendEvent('SavingMenu', {Value=Saves,})
						--world.mwscript.getGlobalVariables(player)['SavingMenu']=0
						Saves={}
					end
					--print("saving menu")
				end


				

				---------------Puzzles
				
				SelectionChoice={}
				for variable,value in pairs(world.mwscript.getGlobalVariables(player))  do
					if value==world.mwscript.getGlobalVariables(player)["SelectionChoiceValue"] and variable~="selectionchoicevalue" then					
						table.insert(SelectionChoice,variable)
					elseif value==world.mwscript.getGlobalVariables(player)["MessageBox"] and variable~="messagebox" and variable~="0" and LastMessageBoxText~=tostring(variable) then
						LastMessageBoxText=tostring(variable)
						core.sendGlobalEvent("ReturnGlobalVariable",{variable=variable,player=player,value=0})
						player:sendEvent("MessageBox",{Text=variable})
					end
				end
				if SelectionChoice[2] then
					player:sendEvent("ChoicesSelection", {selection=SelectionChoice})
				end

			

--[[
				if Test==nil then
					Test=world.createObject("LockFix")
					Test:teleport("Custom",player.position)
				else
					print(Test.rotation:getAnglesZYX())
					Test:teleport("Custom",Test.position,{rotation=Test.rotation*util.transform.rotateY(-0.1)})
				end
]]--
				----------Cutscene
				if Cutscene[3]==nil and Cutscene[2]==true then
					Cutscene[3]=true
					player:setScale(0.01)
					player:sendEvent('Cutscene', {cutscene=Cutscene[1]})
				end


				if world.mwscript.getGlobalVariables(player)["Cutscene"] ==1 and Cutscene[1]==false then
						Cutscene[1]=true
						types.Actor.activeEffects(player):set(100,"paralyze")
						types.Actor.activeEffects(player):set(100,"levitate")
						types.Actor.activeEffects(player):set(100,"chameleon")
						PlayerActor=world.createObject("PlayerActor")
						print(player.position)
						PlayerActor:teleport(player.cell,player.position+util.vector3(0,0,0),player.rotation)
						player:teleport(player.cell,player.position+util.vector3(0,0,-200))
						Cutscene[2]=true

				end


				if world.mwscript.getGlobalVariables(player)["Cutscene"]==0 and Cutscene[1]==true then
					Cutscene[3]=nil
					Cutscene[2]=false
					Cutscene[1]=false
					types.Actor.activeEffects(player):set(0,"paralyze")
					types.Actor.activeEffects(player):set(0,"levitate")
					types.Actor.activeEffects(player):set(0,"chameleon")
					player:setScale(1)
					player:teleport(PlayerActor.cell,PlayerActor.position,PlayerActor.rotation)
					PlayerActor.enabled=false
					LiveSelection=false
					player:sendEvent('Cutscene', {cutscene=Cutscene[1]})
				end



				------------------LiveSelection Text
				if Cutscene[1]==true and LiveSelection==false then
					local Choice1=nil
					local Choice2=nil

					for i, GlobalVariable in pairs(world.mwscript.getGlobalVariables(player)) do 
						if GlobalVariable==world.mwscript.getGlobalVariables(player)["LiveSelectionChoice1"] and i~="liveselectionchoice1" then
							Choice1=i
						end
						if GlobalVariable==world.mwscript.getGlobalVariables(player)["LiveSelectionChoice2"] and i~="liveselectionchoice2" then
							Choice2=i
						end
					end
					if Choice1 and Choice2 then
						LiveSelection=true
						player:sendEvent("LiveSelection", { Choice1 = Choice1, Choice2 = Choice2})
						world.mwscript.getGlobalVariables(player)["respond"]=0
					end
				end
				----------------
				





				---------transform ammunitions to ammunitions_
				for a, cell in pairs(world.cells) do
					if cell==player.cell then
						for b, ammo in pairs(cell:getAll(types.Weapon)) do
							for c, weapon in pairs(types.Weapon.records) do
								if (ammo.recordId.."_")==weapon.id then
									world.createObject(weapon.id,ammo.count):teleport(activecell,ammo.position)
									ammo:remove()
								end
							end
						end
					end
				end
				------------transform ammunitions_ to ammunitions in inventory
				for i,ammo in pairs(types.Actor.inventory(player):getAll(types.Weapon)) do
					for c, weapon in pairs(types.Weapon.records) do
						if ammo.recordId==(weapon.id.."_") then
							world.createObject(weapon.id,types.Actor.inventory(player):countOf(ammo.recordId)):moveInto(types.Actor.inventory(player))
							ammo:remove()
						end
					end
				end
				----------------------------


				if world.mwscript.getGlobalVariables(player)["camera"] >-1 then
					activecam="Cam"..world.mwscript.getGlobalVariables(player)["camera"]
				end
				
				if Cutscene[1]==false and ROOMS[activecell] then
					--for i,v in pairs(ROOMS) do print(i) print(v) end
					--print(ROOMS[activecell]["Cam0"])
					--print(ROOMS[activecell][activecam])
					--print(activecam)
					--print(ROOMS[activecell][activecam].SwitchZone)
					--print(ROOMS[activecell]["Cam5"].SwitchZone)

					if ROOMS[activecell][activecam].SwitchZone then
						for f,zone in pairs(ROOMS[activecell][activecam].SwitchZone) do
								L01=(zone.Point0-zone.Point1):length()
								L12=(zone.Point1-zone.Point2):length()
								L23=(zone.Point2-zone.Point3):length()
								L30=(zone.Point3-zone.Point0):length()
								L0P=(zone.Point0-PointP):length()
								L1P=(zone.Point1-PointP):length()
								L2P=(zone.Point2-PointP):length()
								L3P=(zone.Point3-PointP):length()
								if (math.acos(((L01*L01-L1P*L1P-L0P*L0P)/(-2*L1P*L0P)))+math.acos(((L12*L12-L2P*L2P-L1P*L1P)/(-2*L2P*L1P)))+math.acos(((L23*L23-L3P*L3P-L2P*L2P)/(-2*L3P*L2P)))+math.acos(((L30*L30-L0P*L0P-L3P*L3P)/(-2*L0P*L3P)))>=6.27) and (math.acos(((L01*L01-L1P*L1P-L0P*L0P)/(-2*L1P*L0P)))+math.acos(((L12*L12-L2P*L2P-L1P*L1P)/(-2*L2P*L1P)))+math.acos(((L23*L23-L3P*L3P-L2P*L2P)/(-2*L3P*L2P)))+math.acos(((L30*L30-L0P*L0P-L3P*L3P)/(-2*L0P*L3P)))<=(2*math.pi))  then
									activecam=zone.Camera
									print("SWITCHZONE")
									print(zone.Camera)
								end
						end
					end
				end


				--print(activecam)
				--print(activecell)

				--if BGD then print(BGD:isValid()) end
				--if BGD then print(BGD.enabled) end
				if activecam==nil then
					activecam="Cam0"
				end
				if ROOMS[player.cell.name] and ((activecam~=lastcam or lastcam==nil or activecell~=lastcell or ((BGD==nil or BGD.enabled==false) and ROOMS[player.cell.name][activecam] and ROOMS[player.cell.name][activecam].bgd.idname~="")) and player.cell.name~="DoorStransition") then					
					PlaceBgdMsk(activecell,activecam,player)
				end

				lastcam=activecam
				if player.cell.name~="DoorStransition" then
					lastcell=activecell
				end
			end		
		end
	}
}
