local types = require('openmw.types')
local core = require('openmw.core')
local anim = require('openmw.animation')
local world = require('openmw.world')
local player = world.players[1]
local PropID = nil
local NavmeshPosition
local DoOnce = nil
local function ChoosePropPlace()
	if NavmeshPosition == nil then
	return
	end
	if PropID == nil then
	return
	end
	player = world.players[1]
	print(NavmeshPosition)
	PropID:teleport(world.players[1].cell.name, NavmeshPosition)
	if DoOnce == nil then
		anim.clearAnimationQueue(PropID, true)
	end
	anim.playQueued(PropID, 'knockout', {startkey = 'loop start', stopkey = 'loop stop'})

end



local function SetPropPosition(Position)
	--Dodać tutaj efekt paraliżu coby skurwysynu sie nie ruszały
	DoOnce = nil
	PropID = nil
	
end

local function GetNavmeshPosition(Position)
	NavmeshPosition = Position
	
end



local function SpawnProp(obj)
	player = world.players[1]
	Prop = world.createObject(obj, 1)
	Prop:teleport(world.players[1].cell.name, world.players[1].position)
        player:sendEvent("GetPropID", Prop)
	PropID = Prop
end

return {
    eventHandlers = { SpawnProp = SpawnProp, GetNavmeshPosition = GetNavmeshPosition, SetPropPosition = SetPropPosition },
    engineHandlers = {onUpdate = ChoosePropPlace} 
}


