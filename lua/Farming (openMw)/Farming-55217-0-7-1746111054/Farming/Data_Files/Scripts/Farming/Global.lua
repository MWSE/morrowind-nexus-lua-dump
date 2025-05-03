local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')

local Initialize=false
local Seeds={}
local YoungFlora={}
local SavedData={}
local VFXmodel='meshes/farming/mudbursts.nif'


local Clod=world.createRecord(types.Activator.createRecordDraft({name="Clod",model=('meshes/farming/clod.nif')}))

if SavedData.SeedsRecordId==nil then
	SavedData.SeedsRecordId={}
end
if SavedData.FloraIngredients==nil then
	SavedData.FloraIngredients={}
end
if SavedData.YoungFlora==nil then
	SavedData.YoungFlora={}
	SavedData.YoungFlora.List={}
	SavedData.YoungFlora.Cared={}
end
if SavedData.YoungFlora then
	if SavedData.YoungFlora.List==nil then
		SavedData.YoungFlora.List={}
	end
	if SavedData.YoungFlora.Cared==nil then
		SavedData.YoungFlora.Cared={}
	end
end


local ActiveCell=nil

local function SetScale(data)
	data.Object:setScale(data.scale)
end

local function RemoveItem(data)
	if data.number>0 and data.Object.count>0 then
		data.Object:remove(data.number)
	end
end

local function CreateClod(data)
	world.createObject(Clod.id,1):teleport(data.CellName,data.Position)
	world.vfx.spawn(VFXmodel,data.Position)
end

local function CreateYoungFlora(data)
	local YoungF=nil
	for i,youngflora in pairs(YoungFlora) do
		if youngflora.name=="Young "..data.Name then
			YoungF=world.createObject(youngflora.id,1)
			table.insert(SavedData.YoungFlora.List,YoungF)
			SavedData.YoungFlora.Cared[YoungF.id]=0
			YoungF:setScale(0.1)
			world.vfx.spawn(VFXmodel,data.Position)
			YoungF:teleport(data.CellName,data.Position+util.vector3(0,0,0))
			break
		end
	end
end

local function CarePlant(data)
	
	if SavedData.YoungFlora.Cared[data.Plant.id]==0 then
		if types.Actor.stats.dynamic.fatigue(data.Player).current>50 then
			data.Player:sendEvent("TakeCare",{Cared=false})
			SavedData.YoungFlora.Cared[data.Plant.id]=types.NPC.stats.skills.restoration(data.Player).modified/2
		else
			data.Player:sendEvent("TakeCare",{Cared=false})
		end
	else 
		data.Player:sendEvent("TakeCare",{Cared=true})
	end
end

local function GrowPlants(data)
	--if data.player==world.players[1] then
		if SavedData.YoungFlora~=nil then
			for i, youngplant in pairs(SavedData.YoungFlora.List) do
				if youngplant:isValid() then
					if youngplant.scale<1 then
						local GrowChance=5
						GrowChance=GrowChance+SavedData.YoungFlora.Cared[youngplant.id]
						SavedData.YoungFlora.Cared[youngplant.id]=0
						for i, container in pairs(youngplant.cell:getAll(types.Container)) do
							if container.type.record(container).name==string.gsub(youngplant.type.record(youngplant).name,"Young ","") then
								if (container.position.z>0 and youngplant.position.z>0) or (container.position.z<0 and youngplant.position.z<0) then
									GrowChance=GrowChance+5
								end
							end
						end
						if math.random(100)<GrowChance then
							youngplant:setScale(youngplant.scale+0.1)
						end
					elseif youngplant.scale>1 and youngplant.scale<1.1 and youngplant.count>0 then
						local Flora
						for i,container in pairs(types.Container.records) do
							if container.name==string.gsub(youngplant.type.record(youngplant).name,"Young ","") and container.model==youngplant.type.record(youngplant).model then
								Flora=world.createObject(container.id,1)
								if SavedData.FloraIngredients[container.name] then
									world.createObject(SavedData.FloraIngredients[container.name],1):moveInto(types.Container.content(Flora))
								else
									types.Container.content(Flora):resolve()
								end
								SavedData.YoungFlora.Cared[youngplant.id]=nil
								SavedData.YoungFlora.List[youngplant]=nil
								Flora:teleport(youngplant.cell.name,youngplant.position)
								youngplant:remove()
								break
							end
						end
					end
				end
			end
		end
	--end
	
end

local function CreateFlora(data)
	local Flora
	for i,container in pairs(types.Container.records) do
		if container.name==string.gsub(data.Object.type.record(data.Object).name,"Young ","") and container.model==data.Object.type.record(data.Object).model then
			Flora=world.createObject(container.id,1)
			if SavedData.FloraIngredients[container.name] then
				world.createObject(SavedData.FloraIngredients[container.name],1):moveInto(types.Container.content(Flora))
			else
				types.Container.content(Flora):resolve()
			end
			Flora:teleport(data.CellName,data.Position+util.vector3(0,0,10))
			break
		end
	end
end

local function onUpdate()
	if Initialize==false then
		Initialize=true
		for i,container in pairs(types.Container.records) do
			if container.weight==0 and string.find(container.id,"flora") then --Check string waiting for checking respan and organic in container.record
				Seeds[container.name]=world.createRecord(types.Weapon.createRecordDraft({	name=container.name.." seed", 
																											value=10, 
																											weight=0.01,
																											icon="icons/farming/seed.tga",
																											model="meshes\\farming\\seed.nif",
																											type=types.Weapon.TYPE.MarksmanThrown,
																											speed=1,
																											reach=1,
																											health=1,
																											
																											
																										}))
				YoungFlora[container.name]=world.createRecord(types.Activator.createRecordDraft({	name="Young "..container.name, 
																												model=container.model,
																											}))
			end
		end
	end

	if ActiveCell==nil then
		ActiveCell=world.players[1].cell
	elseif ActiveCell~=world.players[1].cell then	
		ActiveCell=world.players[1].cell
		for i, object in ipairs(world.players[1].cell:getAll(types.Container)) do
			if object.type.record(object).weight==0 and string.find(object.type.record(object).id,"flora") then --Check string waiting for checking respawn and organic in container.record
				if math.random(100)<=5 then
					world.createObject(Seeds[object.type.record(object).name].id,1 ):moveInto(types.Container.content(object))
					print(object)
				end
				types.Container.content(object):resolve()
				if SavedData.FloraIngredients[object.type.record(object).name]==nil and object.type.inventory(object):getAll(types.Ingredient)[1] then
					SavedData.FloraIngredients[object.type.record(object).name]=object.type.inventory(object):getAll(types.Ingredient)[1].recordId
				end
				types.Container.content(object):resolve()
			end
		end
	end

end


local function onSave()
	return{SavedData=SavedData,}
end

local function onLoad(data)
	if data then
		SavedData=data.SavedData
	end
end


return {
	eventHandlers = {CarePlant=CarePlant, GrowPlants=GrowPlants, CreateFlora=CreateFlora,SetScale=SetScale, CreateYoungFlora=CreateYoungFlora, CreateClod=CreateClod,RemoveItem=RemoveItem,},
	engineHandlers = {
        onUpdate = onUpdate,
		onSave=onSave,
		onLoad=onLoad,

	},
}