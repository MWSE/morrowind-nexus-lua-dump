local self=require('openmw.self')
local ui=require('openmw.ui')
local core=require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')


local TimeChecking=core.getGameTime()

local DifficultyMode={"",0}


local Axe2Hs={}
for i, weapon in pairs(types.Weapon.records) do
	if weapon.type==types.Weapon.TYPE.AxeTwoHand then
		table.insert(Axe2Hs,weapon.name)
	end
end


I.Settings.updateRendererArgument('FarmingSettings1', 'Pick', {disabled = false, l10n = 'LocalizationContext', items=Axe2Hs})


local function TakeCare(data)
	if data.Cared==false then
		if types.Actor.stats.dynamic.fatigue(self).current>(50-20*DifficultyMode[2]) then
			types.Actor.stats.dynamic.fatigue(self).current=types.Actor.stats.dynamic.fatigue(self).current-(50-20*DifficultyMode[2])
			ui.showMessage("You take care of the plant")
			core.sound.playSoundFile3d("sound/farming/createclod.mp3",self)
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
	if DifficultyMode[1]~=storage.playerSection('FarmingSettings1'):get('DifficultyMode') then
		if storage.playerSection('FarmingSettings1'):get('DifficultyMode') == "Don't it grow all by itself?" then
			DifficultyMode[1]=storage.playerSection('FarmingSettings1'):get('DifficultyMode')
			DifficultyMode[2]=2
			core.sendGlobalEvent("SetDifficulty",{Difficulty=DifficultyMode[2]})
		elseif storage.playerSection('FarmingSettings1'):get('DifficultyMode') == "I have a pot of mint in my kitchen." then
			DifficultyMode[1]=storage.playerSection('FarmingSettings1'):get('DifficultyMode')
			DifficultyMode[2]=1
			core.sendGlobalEvent("SetDifficulty",{Difficulty=DifficultyMode[2]})
		elseif storage.playerSection('FarmingSettings1'):get('DifficultyMode') == "Gardening is my hobby." then
			DifficultyMode[1]=storage.playerSection('FarmingSettings1'):get('DifficultyMode')
			DifficultyMode[2]=0
			core.sendGlobalEvent("SetDifficulty",{Difficulty=DifficultyMode[2]})
		end
	end

	if core.getGameTime()>(TimeChecking+86400) then
		core.sendGlobalEvent("GrowPlants",{player=self})
		TimeChecking=TimeChecking+86400
	elseif core.getGameTime()<TimeChecking then
		TimeChecking=core.getGameTime()
	end
end

local function CheckPlantInCell()
	for i, container in pairs(nearby.containers) do
		if container.type.records[container.recordId].weight==0 and string.find(container.recordId,"flora") then
			return(true)
		end
	end
end




I.AnimationController.addTextKeyHandler("weapontwohand", function(_, key)
    if 	types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight) and 
		types.Weapon.records[types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight).recordId].name==storage.playerSection('FarmingSettings1'):get('Pick') and 
		CheckPlantInCell() and
		key:match("hit$") and not (key:match("min") or key:match("max"))  then
			local RotZ = self.rotation:getPitch()
			local RotX = self.rotation:getYaw()
			local Ray = nearby.castRay(
				util.vector3(0, 0, 110) + self.position 
--				+util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ)) * 50
				,
				util.vector3(0, 0, 110) + self.position +
				util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ)) * 150,
				{ignore=self})
		if Ray.hit and Ray.hitObject==nil then
			if types.Actor.stats.dynamic.fatigue(self).current> (100-40*DifficultyMode[2]) then
				types.Actor.stats.dynamic.fatigue(self).current=types.Actor.stats.dynamic.fatigue(self).current-(100-40*DifficultyMode[2])
				for i, activator in pairs(nearby.activators) do
					if types.Activator.records[activator.recordId].name=="Clod" then
						if (activator.position-Ray.hitPos):length()<100 then
							core.sendGlobalEvent('RemoveItem',{ Object = activator, number=1})
						end
						
					end
					
					if types.Activator.records[activator.recordId].name then
						if string.find(types.Activator.records[activator.recordId].name,"Young ") and (activator.position-self.position):length()<100 then
							core.sendGlobalEvent('RemoveItem',{ Object = activator, number=1})
						end
					end
				end
				core.sendGlobalEvent('CreateClod',{ CellName=self.cell.name, Position=Ray.hitPos})
				core.sound.playSoundFile3d("sound/farming/createclod.mp3",self)
			else
				ui.showMessage("You are too exhausted to turn the soil")
			end
		end
    end
end)



return {
	eventHandlers = {TakeCare=TakeCare},
	engineHandlers = {

        onFrame = onFrame,
	}

}