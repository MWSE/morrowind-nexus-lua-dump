--global

local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local SecondEquipKeys={}

local Ripples={}
local RipplesRecords={}


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


local function onSave()
  return{ 
          RipplesSaved=Ripples,
          RipplesRecordsSaved=RipplesRecords
        }
end


local function onLoad(data)
  if data then
    RipplesRecords=data.RipplesRecordsSaved
    Ripples=data.RipplesSaved
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
      SetInWaterMwscript=SetInWaterMwscript
    },
    engineHandlers = {onUpdate=onUpdate,
                      onActivate=onActivate,
                      onSave=onSave,
                      onLoad=onLoad,

  
  
  }
  }

