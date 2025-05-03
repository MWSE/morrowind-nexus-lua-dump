local self=require('openmw.self')
local AI=require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local time=require('openmw_aux.time')

local CoopActor
local AttackAnim=0
local LastPlatformPosition
local MovingTempo=0


local function onUpdate()
	AI.removePackages() 
end





local function Right()	
	MovingTempo=0.1
	if self.rotation:getYaw()~=3.14 then
		self.controls.yawChange=-self.rotation:getYaw()+3.14
	end
	self.controls.movement = 1
	self.controls.run=true
end

local function Left()
	MovingTempo=0.1

	if self.rotation:getYaw()~=0 then
		self.controls.yawChange=-self.rotation:getYaw()
	end
	self.controls.movement = 1
	self.controls.run=true
end

local function Jump()
	MovingTempo=0.1
	self.controls.jump=true
end


local function Activate()
	for i, activator in ipairs(nearby.activators) do
		if math.abs(self.position.y-activator.position.y)<100 and math.abs(self.position.z-activator.position.z)<100 then
			activator:activateBy(self)
		end
	end
end

local function round(number)
	return(math.floor(number+0.5))
end

time.runRepeatedly(function() 

end,
0.05*time.second)


local function onUpdate(dt)
	if MovingTempo>0 then	
		MovingTempo=MovingTempo-dt
	end

end


local function CheckPlatform()
	local Ray=nearby.castRay(self.position,self.position+util.vector3(0,0,-2))
	if MovingTempo<=0 and self.count>0 and Ray.hitObject and Ray.hitObject.position then
		if LastPlatformPosition~=Ray.hitObject.position then
			if LastPlatformPosition then
				core.sendGlobalEvent("Teleport",{object=self,position=util.vector3(round(self.position.x),round(self.position.y)+round(Ray.hitObject.position.y)-round(LastPlatformPosition.y),round(self.position.z)+round(LastPlatformPosition.z)-round(Ray.hitObject.position.z))})
			end
			LastPlatformPosition=Ray.hitObject.position
			--print(self)
			--print(Ray.hitObject.position)
		end
	elseif LastPlatformPosition and Ray.hitObject==nil then
		LastPlatformPosition=nil
	end

end

return {
	eventHandlers = {Right=Right, Left=Left, Jump=Jump, Activate=Activate, CheckPlatform=CheckPlatform,},
	engineHandlers = {
		onLoad=onLoad,
		onUpdate=onUpdate,
	}

}