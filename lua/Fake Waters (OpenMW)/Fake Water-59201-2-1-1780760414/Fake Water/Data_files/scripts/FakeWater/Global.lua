--global

local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local SecondEquipKeys={}
local vfs = require('openmw.vfs')
local util = require('openmw.util')


local Ripples={}
local RipplesRecords={}

local FakeWaters={}
local RemoveFakeWaterTempo=0
local Waters={}
local CheckedWatersRecordId={}



local WaterNamesToCheck= require('scripts.fakewater.water names')


local function onSave()
  return{ 
          RipplesSaved=Ripples,
          RipplesRecordsSaved=RipplesRecords,
          WatersSaved=Waters,
          CheckedWatersRecordIdSaved=CheckedWatersRecordId,
          FakeWatersSaved=FakeWaters,

        }
end


local function onLoad(data)
  if data then
    RipplesRecords=data.RipplesRecordsSaved
    Ripples=data.RipplesSaved
    Waters=data.WatersSaved
    CheckedWatersRecordId=data.CheckedWatersRecordIdSaved
    FakeWaters=data.FakeWatersSaved
  end
end




local function CreateRipple(data)


  if not(RipplesRecords[1]) then
      RipplesRecords={  world.createRecord(types.Activator.createRecordDraft({model="meshes/waterripple0.nif"})).id,
                        world.createRecord(types.Activator.createRecordDraft({model="meshes/waterripple1.nif"})).id,
                        world.createRecord(types.Activator.createRecordDraft({model="meshes/waterripple2.nif"})).id,
                        world.createRecord(types.Activator.createRecordDraft({model="meshes/waterripple1.nif"})).id,
                      }
  end
  local random=math.random(4)
  local ripple=world.createObject(RipplesRecords[random],1)
  ripple:teleport(data.cell,data.position,data.rotation)
  ripple:addScript("scripts/fakewater/ripple.lua")
  table.insert(Ripples,{ripple,0})
end




local function NewCell(data)
  local Checkedtypes={types.Static,types.Activator}
  for _, type in pairs(Checkedtypes) do
    for i, SA in pairs(data.Actor.cell:getAll(type)) do
      if not(Waters[SA.id]) then
        for j , string in pairs(WaterNamesToCheck) do
          if string.find(SA.recordId,string) then
            --print("NEWWATER",SA,SA.type.records[SA.recordId].model)
            Waters[SA.id]=true

            local FakeWater

            if not(CheckedWatersRecordId[SA.recordId]) then
              local meshePath=string.gsub(SA.type.records[SA.recordId].model,".nif","fakeWater.nif")
              if vfs.fileExists(meshePath) then
                --print("CreateRecord",SA.recordId)
                CheckedWatersRecordId[SA.recordId]=world.createRecord(SA.type.createRecordDraft({model=meshePath})).id

              else 
                print("Missing meshe : "..meshePath)
              end
            end
            if CheckedWatersRecordId[SA.recordId] then
              FakeWater=world.createObject(CheckedWatersRecordId[SA.recordId],1)
              FakeWater:teleport(SA.cell,SA.position+util.vector3(0,0,1),SA.rotation)
              --print("WaterAdded", SA.recordId)
              if not(FakeWaters[FakeWater.id]) then
                FakeWaters[FakeWater.id]=FakeWater
              end
            end
            break
          end
        end
      end
    end
  end
  for i, creature in pairs(data.Actor.cell:getAll(types.Creature)) do
    creature:sendEvent("DeclareFakeWater",{FakeWaters=FakeWaters})
  end
  for i, npc in pairs(data.Actor.cell:getAll(types.NPC)) do
    npc:sendEvent("DeclareFakeWater",{FakeWaters=FakeWaters})
  end
  data.Actor:sendEvent("DeclareFakeWater",{FakeWaters=FakeWaters})
end


local function DisableFakeWater()
  for i, water in pairs(FakeWaters) do
    RemoveFakeWaterTempo=1
    water.enabled=false
  end
end


local function onUpdate(dt)
  if dt>0 then
    for i, ripple in pairs(Ripples) do
      ripple[2]=ripple[2]+dt 
      if ripple[2]>1 then
        ripple[1]:remove()
        Ripples[i]=nil
      end
    end
    if RemoveFakeWaterTempo>0 then
      RemoveFakeWaterTempo=RemoveFakeWaterTempo-dt
      if RemoveFakeWaterTempo<0 then
        for i, water in pairs(FakeWaters) do
          RemoveFakeWaterTempo=2
          water.enabled=true
        end

      end
    end
  end
end


local function SetInWaterMwscript(data)
  for i, player in pairs(world.players) do
    local mwscript=world.mwscript.getLocalScript(data.actor, player)
    if mwscript and mwscript.variables and mwscript.variables["infakewater"] then
       mwscript.variables["infakewater"]=data.value
    end
  end
end

return {
    eventHandlers = {
      CreateRipple=CreateRipple,
      SetInWaterMwscript=SetInWaterMwscript,
      DisableFakeWater=DisableFakeWater,
      NewCell=NewCell,
    },
    engineHandlers = {onUpdate=onUpdate,
                      onActivate=onActivate,
                      onSave=onSave,
                      onLoad=onLoad,
                      onActorActive=onActorActive,

  
  
  }
  }

