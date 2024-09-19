local self=require('openmw.self')
local ui=require('openmw.ui')
local core=require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local I = require('openmw.interfaces')

local ActionButton=false
local TimeChecking=core.getGameTime()


local function TakeCare(data)
	if data.Cared==false then
		if types.Actor.stats.dynamic.fatigue(self).current>50 then
			types.Actor.stats.dynamic.fatigue(self).current=types.Actor.stats.dynamic.fatigue(self).current-50
			ui.showMessage("You take care of the plant")
			core.sound.playSound3d("animalLARGEleft",self)
			types.NPC.stats.skills.restoration(self).progress=types.NPC.stats.skills.restoration(self).progress+0.01
			if types.NPC.stats.skills.restoration(self).progress>1 then
				I.SkillProgression.skillLevelUp("restoration",I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
			end
		else
			ui.showMessage("You are too exhausted to take care of the plant")
		end
	else
		ui.showMessage("You already have taken care of this plant today")
	end
end

local function onFrame()
	if core.getGameTime()>(TimeChecking+86400) then
		core.sendGlobalEvent("GrowPlants",{player=self})
		TimeChecking=TimeChecking+86400
	elseif core.getGameTime()<TimeChecking then
		TimeChecking=core.getGameTime()
	end
end

local function CheckPlantInCell()
	for i, container in pairs(nearby.containers) do
		if container.type.record(container).weight==0 and string.find(container.type.record(container).id,"flora") then
			return(true)
		end
	end
end

local function onUpdate()
	if self.controls.use==0 
	and ActionButton==true 
	and types.Actor.getStance(self) == 1 
	and types.Actor.getEquipment(self, 16) 
	and CheckPlantInCell()==true
	then
		ActionButton=false 
		if types.Actor.getEquipment(self, 16).recordId=="miner's pick"  then
				ActionButton=false
				local RotZ = self.rotation:getPitch()
				local RotX = self.rotation:getYaw()
				local Ray = nearby.castRay(
					util.vector3(0, 0, 110) + self.position +
					util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ)) * 50,
					util.vector3(0, 0, 110) + self.position +
					util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ)) * 150)

				if Ray.hit and Ray.hitObject==nil then
					if types.Actor.stats.dynamic.fatigue(self).current>100 then
						types.Actor.stats.dynamic.fatigue(self).current=types.Actor.stats.dynamic.fatigue(self).current-100
					for i, activator in pairs(nearby.activators) do
						if activator.recordId=="clod" then
							if (activator.position-Ray.hitPos):length()<100 then
								core.sendGlobalEvent('RemoveItem',{ Object = activator, number=1})
							end
							
						end
						
						if types.Activator.record(activator).name then
							if string.find(types.Activator.record(activator).name,"Young ") and (activator.position-self.position):length()<100 then
								core.sendGlobalEvent('RemoveItem',{ Object = activator, number=1})
							end
						end
					end
					core.sendGlobalEvent('CreateClod',{ RecordId = "Clod", CellName=self.cell.name, Position=Ray.hitPos})
					core.sound.playSound3d("animalLARGEleft",self)
				else
					ui.showMessage("You are too exhausted to turn the soil")
				end
			end
		end
	elseif self.controls.use==1 and ActionButton==false then 
		ActionButton=true
	end

end

return {
	eventHandlers = {TakeCare=TakeCare},
	engineHandlers = {

        onFrame = onFrame,
		onUpdate=onUpdate,
	}

}