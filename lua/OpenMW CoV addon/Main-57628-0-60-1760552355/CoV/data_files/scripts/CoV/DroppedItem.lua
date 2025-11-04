local self=require('openmw.self')
local AI=require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')

local StartPosition
local StopPosition
local Direction={}
local MaxPositionZ


local function onUpdate(dt)
	if dt>0 then
		local DeltaDt=dt/0.002
		if self.cell then
			if not(StartPosition) then
				StartPosition=self.position
				Distance=math.random(50)+50
				Direction={x=(math.pow(-1,math.random(2)))/5*DeltaDt,y=(math.pow(-1,math.random(2)))/5*DeltaDt,z=0.5*DeltaDt}
				MaxPositionZ=math.random(200)+200
			elseif (util.vector2(self.position.x,self.position.y)-util.vector2(StartPosition.x,StartPosition.y)):length()>=Distance or self.parentContainer then
				core.sendGlobalEvent("CoVStopLuaScript",{Object=self, Script="scripts/cov/droppeditem.lua"})
				if not(self.parentContainer) then
					core.sound.playSoundFile3d("sound/fx/item/shield.wav",self)
				end
			else
				if (util.vector2(self.position.x,self.position.y)-util.vector2(StartPosition.x,StartPosition.y)):length()>=Distance/2 and Direction.z>0 then
					Direction.z=-Direction.z
				end
--				core.sendGlobalEvent("CoVTeleport",{Object=self,Cell=self.cell.name,Position=(self.position+StopPosition)/2+util.vector3(0,0,Direction.Z)})
		--		core.sendGlobalEvent("CoVTeleport",{Object=self,Cell=self.cell.name,Position=util.vector3(self.position.x+(StopPosition.x/StartPosition.x)*Direction.Plan,self.position.y+(StopPosition.y/StartPosition.y)*Direction.Plan,self.position.z)
		--		+util.vector3(0,0,Direction.Z)})
				core.sendGlobalEvent("CoVTeleport",{Object=self,Cell=self.cell.name,Position=self.position+util.vector3(Direction.x,Direction.y,Direction.z)})
			end 
		end
	end
end


return {
	eventHandlers = {	
						
					},
	engineHandlers = {
						onUpdate=onUpdate,

	}

}