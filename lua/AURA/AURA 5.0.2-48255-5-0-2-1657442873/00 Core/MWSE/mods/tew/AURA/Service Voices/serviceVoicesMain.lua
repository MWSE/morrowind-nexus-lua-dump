local serviceVoicesData = require("tew.AURA.Service Voices.serviceVoicesData")
local config = require("tew.AURA.config")
local common = require("tew.AURA.common")
local UIvol=config.UIvol/200
local SVvol=config.SVvol/200
local moduleUI=config.moduleUI

local raceNames=serviceVoicesData.raceNames
local commonVoices=serviceVoicesData.commonVoices
local travelVoices=serviceVoicesData.travelVoices
local spellVoices=serviceVoicesData.spellVoices
local trainingVoices=serviceVoicesData.trainingVoices

local UISpells = config.UISpells

local serviceRepair=config.serviceRepair
local serviceSpells=config.serviceSpells
local serviceTraining=config.serviceTraining
local serviceSpellmaking=config.serviceSpellmaking
local serviceEnchantment=config.serviceEnchantment
local serviceTravel=config.serviceTravel
local serviceBarter=config.serviceBarter

local trainingFlag, spellsFlag, spellMakingFlag, repairFlag = 0, 0, 0, 0
local newVoice, lastVoice = "init", "init"

local debugLog = common.debugLog

local function serviceGreet(e)

   local npcId=tes3ui.getServiceActor(e)
   local raceId=npcId.object.race.id
   local raceLet, sexLet
   local serviceFeed={}

   if npcId.object.female then
      debugLog("Female NPC found.")
      sexLet="f"
   else
      sexLet="m"
      debugLog("Male NPC found.")
   end

   for k, v in pairs(raceNames) do
      if raceId==k then
         raceLet=v
      end
   end

   for kRace, _ in pairs(commonVoices) do
      if kRace==raceLet then
         for kSex, _ in pairs(commonVoices[kRace]) do
            if kSex==sexLet then
               for _, voice in pairs(commonVoices[kRace][kSex]) do
                  table.insert(serviceFeed, voice)
               end
            end
         end
      end
   end

   if serviceFeed[1] then
      while newVoice == lastVoice or newVoice == nil do
         newVoice=serviceFeed[math.random(1, #serviceFeed)]
      end
      tes3.removeSound{reference=npcId}
      tes3.say{
      volume=0.9*SVvol*SVvol,
      soundPath="Vo\\"..raceLet.."\\"..sexLet.."\\"..
      newVoice..".mp3", reference=npcId
      }
      lastVoice=newVoice
      debugLog("NPC says a service comment.")
   end

end

local function travelGreet(e)

   local npcId=tes3ui.getServiceActor(e)
   local raceId=npcId.object.race.id
   local raceLet, sexLet
   local serviceFeed={}

   if npcId.object.female then
      debugLog("Female NPC found.")
      sexLet="f"
   else
      sexLet="m"
      debugLog("Male NPC found.")
   end

   for k, v in pairs(raceNames) do
      if raceId==k then
         raceLet=v
      end
   end

   for kRace, _ in pairs(travelVoices) do
      if kRace==raceLet then
         for kSex, _ in pairs(travelVoices[kRace]) do
            if kSex==sexLet then
               for _, voice in pairs(travelVoices[kRace][kSex]) do
                  table.insert(serviceFeed, voice)
               end
            end
         end
      end
   end

   if serviceFeed[1] then
      while newVoice == lastVoice or newVoice == nil do
         newVoice=serviceFeed[math.random(1, #serviceFeed)]
      end
      tes3.removeSound{reference=npcId}
      tes3.say{
      volume=0.9*SVvol,
      soundPath="Vo\\"..raceLet.."\\"..sexLet.."\\"..
      newVoice..".mp3", reference=npcId
      }
      lastVoice=newVoice
      debugLog("NPC says a travel comment.")
   end

end

local function trainingGreet(e)

   local closeButton=e.element:findChild(tes3ui.registerID("MenuServiceTraining_Okbutton"))
   closeButton:register("mouseDown", function()
      tes3.playSound{sound="Menu Click", reference=tes3.player}
      trainingFlag=0
   end)

   if trainingFlag==1 then return end

   local npcId=tes3ui.getServiceActor(e)
   local raceId=npcId.object.race.id
   local raceLet, sexLet
   local serviceFeed={}

   if npcId.object.female then
      debugLog("Female NPC found.")
      sexLet="f"
   else
      sexLet="m"
      debugLog("Male NPC found.")
   end

   for k, v in pairs(raceNames) do
      if raceId==k then
         raceLet=v
      end
   end

   for kRace, _ in pairs(trainingVoices) do
      if kRace==raceLet then
         for kSex, _ in pairs(trainingVoices[kRace]) do
            if kSex==sexLet then
               for _, voice in pairs(trainingVoices[kRace][kSex]) do
                  table.insert(serviceFeed, voice)
               end
            end
         end
      end
   end

   if serviceFeed[1] then
      while newVoice == lastVoice or newVoice == nil do
         newVoice=serviceFeed[math.random(1, #serviceFeed)]
      end
      tes3.removeSound{reference=npcId}
      tes3.say{
      volume=0.9*SVvol,
      soundPath="Vo\\"..raceLet.."\\"..sexLet.."\\"..
      newVoice..".mp3", reference=npcId
      }
      lastVoice=newVoice
      debugLog("NPC says a trainer comment.")
      trainingFlag=1
   end

end

local function spellGreet(e)

   local closeButton=e.element:findChild(tes3ui.registerID("MenuServiceSpells_Okbutton"))
   closeButton:register("mouseDown", function()
      tes3.playSound{sound="Menu Click", reference=tes3.player}
      spellsFlag=0
   end)

   if spellsFlag==1 then return end

   local npcId=tes3ui.getServiceActor(e)
   local raceId=npcId.object.race.id
   local raceLet, sexLet
   local serviceFeed={}

   if npcId.object.female then
      debugLog("Female NPC found.")
      sexLet="f"
   else
      sexLet="m"
      debugLog("Male NPC found.")
   end

   for k, v in pairs(raceNames) do
      if raceId==k then
         raceLet=v
      end
   end

   for kRace, _ in pairs(spellVoices) do
      if kRace==raceLet then
         for kSex, _ in pairs(spellVoices[kRace]) do
            if kSex==sexLet then
               for _, voice in pairs(spellVoices[kRace][kSex]) do
                  table.insert(serviceFeed, voice)
               end
            end
         end
      end
   end

   if not serviceFeed[1] then
      for kRace, _ in pairs(commonVoices) do
         if kRace==raceLet then
            for kSex, _ in pairs(commonVoices[kRace]) do
               if kSex==sexLet then
                  for _, voice in pairs(commonVoices[kRace][kSex]) do
                     table.insert(serviceFeed, voice)
                  end
               end
            end
         end
      end
   end

   while newVoice == lastVoice or newVoice == nil do
      newVoice=serviceFeed[math.random(1, #serviceFeed)]
   end
   tes3.removeSound{reference=npcId}
   tes3.say{
   volume=0.9*SVvol,
   soundPath="Vo\\"..raceLet.."\\"..sexLet.."\\"..
   newVoice..".mp3", reference=npcId
   }
   lastVoice=newVoice
   spellsFlag=1
   debugLog("NPC says a spell vendor comment.")

   if UISpells and moduleUI then
      tes3.playSound{soundPath="FX\\MysticGate.wav", reference=tes3.player, volume=0.6*UIvol, pitch=1.3}
      debugLog("Opening spell menu sound played.")
   end
end

local function spellMakingGreet(e)

   local cancelButton=e.element:findChild(tes3ui.registerID("MenuSpellmaking_Cancelbutton"))
   cancelButton:register("mouseDown", function()
      tes3.playSound{sound="Menu Click", reference=tes3.player}
      spellMakingFlag=0
   end)

   local buyButton=e.element:findChild(tes3ui.registerID("MenuSpellmaking_Buybutton"))
   buyButton:register("mouseDown", function()
      spellMakingFlag=0
   end)

   if spellMakingFlag==1 then return end

   local npcId=tes3ui.getServiceActor(e)
   local raceId=npcId.object.race.id
   local raceLet, sexLet
   local serviceFeed={}

   if npcId.object.female then
      debugLog("Female NPC found.")
      sexLet="f"
   else
      sexLet="m"
      debugLog("Male NPC found.")
   end

   for k, v in pairs(raceNames) do
      if raceId==k then
         raceLet=v
      end
   end

   for kRace, _ in pairs(spellVoices) do
      if kRace==raceLet then
         for kSex, _ in pairs(spellVoices[kRace]) do
            if kSex==sexLet then
               for _, voice in pairs(spellVoices[kRace][kSex]) do
                  table.insert(serviceFeed, voice)
               end
            end
         end
      end
   end

   if not serviceFeed[1] then
      for kRace, _ in pairs(commonVoices) do
         if kRace==raceLet then
            for kSex, _ in pairs(commonVoices[kRace]) do
               if kSex==sexLet then
                  for _, voice in pairs(commonVoices[kRace][kSex]) do
                     table.insert(serviceFeed, voice)
                  end
               end
            end
         end
      end
   end

   while newVoice == lastVoice or newVoice == nil do
      newVoice=serviceFeed[math.random(1, #serviceFeed)]
   end
   tes3.removeSound{reference=npcId}
   tes3.say{
   volume=0.9*SVvol,
   soundPath="Vo\\"..raceLet.."\\"..sexLet.."\\"..
   newVoice..".mp3", reference=npcId
   }
   lastVoice=newVoice
   spellMakingFlag=1
   debugLog("NPC says a spellmaking comment.")

   if UISpells and moduleUI then
      tes3.playSound{soundPath="FX\\MysticGate.wav", reference=tes3.player, volume=0.6*UIvol, pitch=0.9}
      debugLog("Opening spell menu sound played.")
   end

end

local function repairGreet(e)

   local closeButton=e.element:findChild(tes3ui.registerID("MenuServiceRepair_Okbutton"))
   closeButton:register("mouseDown", function()
      repairFlag=0
   end)

   if repairFlag==1 then return end

   local npcId=tes3ui.getServiceActor(e)
   local raceId=npcId.object.race.id
   local raceLet, sexLet
   local serviceFeed={}

   if npcId.object.female then
      debugLog("Female NPC found.")
      sexLet="f"
   else
      sexLet="m"
      debugLog("Male NPC found.")
   end

   for k, v in pairs(raceNames) do
      if raceId==k then
         raceLet=v
      end
   end

   for kRace, _ in pairs(commonVoices) do
      if kRace==raceLet then
         for kSex, _ in pairs(commonVoices[kRace]) do
            if kSex==sexLet then
               for _, voice in pairs(commonVoices[kRace][kSex]) do
                  table.insert(serviceFeed, voice)
               end
            end
         end
      end
   end

   if serviceFeed[1] then
      while newVoice == lastVoice or newVoice == nil do
         newVoice=serviceFeed[math.random(1, #serviceFeed)]
      end
      tes3.removeSound{reference=npcId}
      tes3.say{
      volume=0.9*SVvol,
      soundPath="Vo\\"..raceLet.."\\"..sexLet.."\\"..
      newVoice..".mp3", reference=npcId
      }
      lastVoice=newVoice
      repairFlag=1
      debugLog("NPC says a repair comment.")
   end

end

debugLog("Service voices module initialised.")

if serviceTravel then event.register("uiActivated", travelGreet, {filter="MenuServiceTravel", priority=-10}) end
if serviceBarter then event.register("uiActivated", serviceGreet, {filter="MenuBarter", priority=-10}) end
if serviceTraining then event.register("uiActivated", trainingGreet, {filter="MenuServiceTraining", priority=-10}) end
if serviceEnchantment then event.register("uiActivated", serviceGreet, {filter="MenuEnchantment", priority=-10}) end
if serviceSpellmaking then event.register("uiActivated", spellMakingGreet, {filter="MenuSpellmaking", priority=-10}) end
if serviceSpells then event.register("uiActivated", spellGreet, {filter="MenuServiceSpells", priority=-10}) end
if serviceRepair then event.register("uiActivated", repairGreet, {filter="MenuServiceRepair", priority=-10}) end