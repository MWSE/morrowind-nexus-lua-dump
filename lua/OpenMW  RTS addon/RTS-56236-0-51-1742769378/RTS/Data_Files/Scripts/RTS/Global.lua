local core=require('openmw.core')
local util=require('openmw.util')
local world=require('openmw.world')
local time=require('openmw_aux.time')
local types = require('openmw.types')

local VFXmodel='meshes/target.nif'

local RTS=false

local function StartRTS(data)
	data.Player:setScale(0.001)
	RTS=true
end

local function StopRTS(data)
	data.Player:setScale(1)
	data.Player:teleport(data.Player.cell,data.Position)
	RTS=false
end


local function Teleport(data)
--	print(data.object.count)
--	print(data.object.enabled)
--	print(data.object:isValid())
	data.object:teleport(data.cell,data.position)
end


local function MovePlayer()
	if RTS==true then
		--world.players[1]:teleport(Bounds.cell,Bounds.position+util.vector3(0,0,200))
	end
end


time.runRepeatedly(function() 	MovePlayer()
							end
					,5*time.second)


local function onUpdate()
--	if Bounds then
--		print("teleport")
--		print(world.players[1].enabled)
--		world.players[1]:teleport(Bounds.cell,Bounds.position+util.vector3(0,0,200))
--	end
end

local function MovingSelect(data)
	world.vfx.spawn(VFXmodel,data.Position)
end	



local function MoveInto(data)
	data.Item:moveInto(types.Actor.inventory(data.actor))
end


return {
	eventHandlers = {StartRTS=StartRTS,StopRTS=StopRTS,Teleport=Teleport,MovingSelect=MovingSelect,MoveInto=MoveInto},
	engineHandlers = {

        onUpdate = onUpdate,
	}

}