local core=require('openmw.core')
local util=require('openmw.util')
local world=require('openmw.world')
local time=require('openmw_aux.time')
local types = require('openmw.types')



local CurrentPathPoint

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
end



local function RSCReateMagicBolt(data)
	local Model="meshes/"
	if types.Weapon.records[core.magic.effects.records[data.MagicRecordId].bolt] then
		Model=types.Weapon.records[core.magic.effects.records[data.MagicRecordId].bolt].model
	end

	local BoltRecord=world.createRecord(types.Creature.createRecordDraft({	template=types.Creature.records["RSMagicBolt"],
																			model=Model,
																			}))

	local Bolt=world.createObject(BoltRecord.id,1)
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