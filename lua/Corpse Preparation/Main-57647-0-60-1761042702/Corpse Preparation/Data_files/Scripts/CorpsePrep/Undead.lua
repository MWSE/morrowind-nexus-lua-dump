local self = require('openmw.self')
local types = require('openmw.types')
local AI=require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local nearby = require('openmw.nearby')
local Rampage=false
local Allies={}
local Master
local function onUpdate(dt)
  if dt>0 then
    if I.AI.getActivePackage() then
      if I.AI.getActivePackage().type=="Combat" and I.AI.getActivePackage().target==Master then
        AI.startPackage({type='Follow',target=Master})
      end
      if Rampage==true and I.AI.getActivePackage().type~="Combat" then
        for i, actor in pairs(nearby.actors) do
          if not(Allies[actor.id]) and (actor.position-self.position):length()<4000 then
            AI.startPackage({type='Combat',target=actor})
            break
          end
        end
        if not(I.AI.getActivePackage()) then
          AI.startPackage({type='Follow',target=Master})
        end
      end
    end
  end
end


local function Equip(data)
  types.Actor.setEquipment(self,data.Equipment)
end

local function setAttributes(data)
  for i, attribute in pairs(types.NPC.stats.attributes) do
    attribute(self).base=data.attributes[i]
  end
end

local function setSkills(data)
  for i, skill in pairs(types.NPC.stats.skills) do
    skill(self).base=data.skills[i]
  end
end

local function setLevel(data)
  types.NPC.stats.level(self).current=data.level
end


local function Order(data)
  if data.Order=="Follow" then
    types.Actor.stats.ai.fight(self).base=0
    AI.startPackage({type='Follow',target=data.Target})
    Rampage=false
  elseif data.Order=="Wait" then
    AI.removePackages()
    Rampage=false
  elseif data.Order=="Rampage" then
    Rampage=true
  elseif data.Order=="Combat" then
    AI.startPackage({type='Combat',target=data.Target})
    Rampage=false
  end
end


local function DeclareMinions(data)
  Allies={}
  for i, minion in pairs(data.Minions) do
    Allies[minion.id]=true
  end
  Allies[Master.id]=true
end

local function playAnimReanim()
  I.AnimationController.playBlendedAnimation( "knockout", {startKey="loop start", loops = 0, forceLoop = true, priority = anim.PRIORITY.Scripted })
end


local function onInit(initData)
  Master=initData.Master
end


local function onSave()
	return{Master=Master,Rampage=Rampage,Allies=Allies}

end

local function onLoad(data)
	if data.Master then
		Master=data.Master
	end
	if data.Rampage then
		Rampage=data.Rampage
	end
	if data.Allies then
		Allies=data.Allies
	end
end

return {
    eventHandlers = { Equip=Equip, Order=Order, 
                      setSkills=setSkills, 
                      setAttributes=setAttributes, 
                      setLevel=setLevel, 
                      playAnimReanim=playAnimReanim,
                      DeclareMinions=DeclareMinions,
    },
    engineHandlers = {onUpdate=onUpdate, 
                      onInit=onInit,
                      onSave=onSave,
                      onLoad=onLoad
  
  
  }
  }

