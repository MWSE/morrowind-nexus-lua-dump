local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local I=require('openmw.interfaces')

local PlacingUndead={Players = {},Prop = {},NavmeshPosition={}}



local function onUpdate(dt)
	if dt>0 then
		for i,player in pairs(PlacingUndead.Players) do
			if PlacingUndead.NavmeshPosition[player.id] and PlacingUndead.Prop[player.id] then
				if not(PlacingUndead.Prop[player.id].parentContainer) and PlacingUndead.Prop[player.id].count>0 then
					PlacingUndead.Prop[player.id]:teleport(player.cell.name, PlacingUndead.NavmeshPosition[player.id])
				else	
					core.sendGlobalEvent("SetPropPosition",{Player=player})
				end
			end
		end
	end
end

I.Activation.addHandlerForType(types.Miscellaneous, function(object, actor)
													if PlacingUndead.Prop[actor.id] then
														return(false)
													end
end
)


local function SetPropPosition(data)
	PlacingUndead.Prop[data.Player.id] = nil	
end

local function GetNavmeshPosition(data)
	PlacingUndead.NavmeshPosition[data.Player.id] = data.Position	
end



local function SpawnProp(data)
	PlacingUndead.Players[data.Player.id] = data.Player
	PlacingUndead.Prop[data.Player.id]= world.createObject(data.Undead, 1)
	PlacingUndead.Prop[data.Player.id]:teleport(data.Player.cell.name, data.Player.position)
    PlacingUndead.Prop[data.Player.id]:sendEvent("PlayAnimation", "knockout")
end




return {
    eventHandlers = { SpawnProp = SpawnProp, GetNavmeshPosition = GetNavmeshPosition, SetPropPosition = SetPropPosition,},
    engineHandlers = {onUpdate = onUpdate,} 
}


