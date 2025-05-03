local core=require('openmw.core')
local util=require('openmw.util')
local world=require('openmw.world')
local time=require('openmw_aux.time')

local PlayerOne=nil
local PlayerTwo=nil
local Platformer=false

local function MovePlayer()
	if PlayerOne then
		world.players[1]:teleport(PlayerOne.cell,PlayerOne.position+util.vector3(-1000,0,0))
		if world.players[1].scale>0.01 then
			world.players[1]:setScale(0.01)
		end
	end
end

local function Players(data)
	PlayerOne=data.P1
	PlayerTwo=data.P2
	PlayerThree=data.P3
	PlayerFour=data.P4
	MovePlayer()
end

time.runRepeatedly(function() 	
									--print("teleport")
									if Platformer==true then
										MovePlayer()
									end
							
							end
					,1*time.second)
local function onUpdate()


end


local function Teleport(data)
	data.object:teleport(data.object.cell,data.position)
end


local function onUpdate()
	if Platformer==false and world.mwscript.getGlobalVariables(world.players[1])["Platformer"]==1 then
		Platformer=true
		world.players[1]:sendEvent("StartPlatformer",{})
	elseif Platformer==true and world.mwscript.getGlobalVariables(world.players[1])["Platformer"]==0 then
		Platformer=false
		world.players[1]:sendEvent("StopPlatformer",{})
		world.players[1]:setScale(1)
	end
end

return {
	eventHandlers = {Players=Players, StopControl=StopControl, Teleport=Teleport},
	engineHandlers = {

        onUpdate = onUpdate,
		onSave=onSave,
		onLoad=onLoad,
	}

}