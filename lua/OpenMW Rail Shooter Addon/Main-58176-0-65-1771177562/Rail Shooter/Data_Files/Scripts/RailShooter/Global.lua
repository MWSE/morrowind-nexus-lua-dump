local core=require('openmw.core')
local util=require('openmw.util')
local world=require('openmw.world')
local time=require('openmw_aux.time')
local types = require('openmw.types')



local CurrentPathPoint
local CurrentRS_Gameplay=0

local function onLoad(data)
	if data then
		if data.SaveCurrentPathPoint then
			CurrentPathPoint=data.SaveCurrentPathPoint
		end
	end
end

local function RSTeleport(data)
	data.object:teleport(data.Cell,data.Position,data.Rotation)
end


local function RSCreateFoe(data)
	local Foe=world.createObject(data.RecordId,1)
	Foe:teleport(data.Cell,data.Position)
	if data.Boss==true then
		world.players[1]:sendEvent("NewBoss",{Actor=Foe})
	end
end

local function RSRemove(data)
	data.object:remove()
end


local function RSCreateObject(data)
	print(data.CellName)
	local Object=world.createObject(data.RecordId,1)
	if data.DestContainer then
		Object:moveInto(data.DestContainer)
	else
		Object:teleport(data.CellName,data.Position,data.Rotation)
	end
end



local function RSWriteMWSGlobal(data)
	world.mwscript.getGlobalVariables(data.Player)[data.Variable]=data.Value
	if data.Variable=="CurrentPathPoint" then
		CurrentPathPoint=data.Value
	end
end


local function onUpdate(dt)
	local MWCurrentPathPoint=world.mwscript.getGlobalVariables(world.players[1])["CurrentPathPoint"]
	if CurrentPathPoint~=MWCurrentPathPoint then
		CurrentPathPoint=MWCurrentPathPoint
		world.players[1]:sendEvent("ChangeCurrentPathPoint",{Value=MWCurrentPathPoint+1})
	end

	
	local RS_Gameplay=world.mwscript.getGlobalVariables(world.players[1])["RS_Gameplay"]
	if RS_Gameplay==1 and CurrentRS_Gameplay==0 then
		CurrentRS_Gameplay=RS_Gameplay
		world.players[1]:sendEvent("StartRS")
	elseif RS_Gameplay==0 and CurrentRS_Gameplay==1 then
		CurrentRS_Gameplay=RS_Gameplay
		world.players[1]:sendEvent("StopRS")
	end

end



local function RSCReateMagicBolt(data)
	local Model="meshes/"
	if types.Weapon.records[core.magic.effects.records[data.MagicRecordId].bolt] then
		Model=types.Weapon.records[core.magic.effects.records[data.MagicRecordId].bolt].model
	end

	local BoltRecord=world.createRecord(types.Creature.createRecordDraft({	template=types.Creature.records["RSMagicBolt"],
																			model=Model,
																			scale=world.players[1].scale
																			}))

	local Bolt=world.createObject(BoltRecord.id,1)

--	Bolt:sendEvent("SetHealth",{Value=core.magic.effects.records[data.MagicRecordId].baseCost*4}) 
Bolt:sendEvent("SetSpeed",{Value=core.magic.effects.records[data.MagicRecordId].baseCost*40})
--	Bolt:sendEvent("SetSpeed",{Value=core.magic.effects.records[data.MagicRecordId].ProjectileSpeed})          projectileSpeed doesn't exist yet :()
--	core.sound.playSound3d(core.magic.effects.records[data.MagicRecordId].boltSound,Bolt,{loop=true})		Doesn't works, the sound spamm to the same position
	Bolt:teleport(data.CellName,data.Position)
end



local function onSave()
    return{SaveCurrentPathPoint=CurrentPathPoint}
end

return {
	eventHandlers = {RSRemove=RSRemove,
					RSTeleport=RSTeleport,
					RSCreateFoe=RSCreateFoe,
					RSCreateObject=RSCreateObject,
					RSWriteMWSGlobal=RSWriteMWSGlobal,
					RSCReateMagicBolt=RSCReateMagicBolt,


				},
	engineHandlers = {

        onUpdate = onUpdate,
		onSave=onSave,
		onLoad=onLoad,
	}

}