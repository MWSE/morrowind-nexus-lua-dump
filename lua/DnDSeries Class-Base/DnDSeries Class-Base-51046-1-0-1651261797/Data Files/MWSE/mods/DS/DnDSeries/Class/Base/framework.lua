local UI= require('DS.DnDSeries.Class.Base.UI')
local tables=require('DS.DnDSeries.Class.Base.Tables')
local this = {}
local function MyTradeCheck(class)
    local dialog = tes3.findDialogue({topic = "my trade"})
    if dialog then
      for _, info in ipairs(dialog.info) do
        if info.npcClass ~= nil then
         if info.npcClass == class then
          return info
         end
        end
      end
    end
    end
local function createNewMenu()
UI.createFeatsMenu()
end
local function infoFeats(e)
local actor = tes3ui.getServiceActor()
local class = actor.object.class
local featsDifficulty = tables.FeatsDifficulty
local pcName = tes3.player.object.name
local LearnableFeats = tables.LearnableFeats
if table.empty(LearnableFeats) == false then
  if featsDifficulty[class.id] ~= nil then
    local difficulty =  featsDifficulty[class.id]
    if difficulty == "low" then
      e.text = "You have the same training as i do, you are worthy of my teachings I will train you " .. pcName
      tes3.runLegacyScript{ command = 'Goodbye' }
      event.register("simulate", createNewMenu,{doOnce=true})
    end
    if difficulty == "medium" then
      e.text = "your training is similar to mine, it will be difficult but I can train you " .. pcName
      tes3.runLegacyScript{ command = 'Goodbye' }
      event.register("simulate", createNewMenu,{doOnce=true})
    end
    if difficulty == "high" then
      e.text = "Your training is completely opposite from mine, this will be very difficult " .. pcName
      tes3.runLegacyScript{ command = 'Goodbye' }
      event.register("simulate", createNewMenu,{doOnce=true})
    end
  end
  if featsDifficulty[class.specialization] ~= nil then
    local difficulty =  featsDifficulty[class.specialization]
    if difficulty == "low" then
      e.text = "You have the same training as i do, you are worthy of my teachings I will train you " .. pcName
        tes3.runLegacyScript{ command = 'Goodbye' }
        event.register("simulate", createNewMenu,{doOnce=true})
    end
    if difficulty == "medium" then
      e.text = "Your training is completely opposite from mine, it will be difficult but I can train you " .. pcName
      tes3.runLegacyScript{ command = 'Goodbye' }
      event.register("simulate", createNewMenu,{doOnce=true})
    end
  end
else
  e.text="I have nothing left to teach you" .. pcName
end
end
local function infoClass(e)
 e.text = e:loadOriginalText() .. "\nI can train you to learn special abilities from my own discipline"
 local dialog = tes3.findDialogue({topic = "Special Abilities"})
 if dialog then
  for _, info in ipairs(dialog.info) do
    event.register("infoGetText", infoFeats, {filter = info, doOnce=true})
  end
 end
end
local function checkNpcClass(e)
  if e.activator ~= tes3.player and e.target.object.objectType ~= tes3.objectType.npc then return end
  local class = e.target.object.class
  local availableFeats = tes3.player.data.DnDSeries.AvailableFeats
  local LearnableFeats = tables.LearnableFeats
  local feats = tables.Feats
  local info = MyTradeCheck(class)
  assert(info, "Couldnt find class related info")
  if info then
    event.register("infoGetText", infoClass, {filter= info, doOnce=true})
  end
  for _, data1 in ipairs(availableFeats) do
    if data1.class then
      if data1.class == class.id then
        for _, data2 in ipairs(feats) do
          if data1.id == data2.id then
          if table.find(LearnableFeats, data2) == nil then
            table.insert(LearnableFeats, data2)
            tables.LearnableFeats = LearnableFeats
          end
          end
        end
      end
    end
    if data1.specialization then
      if data1.specialization == class.specialization then
        for _, data2 in ipairs(feats) do
          if data1.id == data2.id then
          if table.find(LearnableFeats, data2) == nil then
            table.insert(LearnableFeats, data2)
            tables.LearnableFeats = LearnableFeats
          end
          end
        end
      end
    end
  end
  end
local function startingFeats()
  local featsDifficulty = tables.FeatsDifficulty
  local Feats = tables.Feats
  local RequirimentFeats = tables.RequirimentFeats
  local learnableFeats = tables.LearnableFeats
  local learnableFeatId
  for _, data1 in ipairs(Feats) do
    if data1.class then
     local difficulty = featsDifficulty[data1.class]
     if difficulty == "low" then
      for _, data2 in ipairs(RequirimentFeats) do
        local skill = tes3.mobilePlayer:getSkillStatistic(data2.skill)
        local req = data2.requiriment
        if skill.base >= req then
         learnableFeatId = data2.id
        end
        if data1.class == tes3.player.object.class.id then
          if data1.id == learnableFeatId then
            if not table.find(learnableFeats, data1) then
              table.insert(learnableFeats, data1)
              tables.LearnableFeats = learnableFeats
            end
          end
        end
      end
     end
    end
    if data1.specialization then
      local difficulty = featsDifficulty[data1.specialization]
      if difficulty == "low" then
       for _, data2 in ipairs(RequirimentFeats) do
         local skill = tes3.mobilePlayer:getSkillStatistic(data2.skill)
         local req = data2.requiriment
         if skill.base >= req then
          learnableFeatId = data2.id
         end
         if data1.specialization == tes3.player.object.class.specialization then
           if data1.id == learnableFeatId then
             if not table.find(learnableFeats, data1) then
               table.insert(learnableFeats, data1)
               tables.LearnableFeats = learnableFeats
             end
           end
         end
       end
      end
    end
   end
end
local function checkRequirimentFeats()
local featsDifficulty = tables.FeatsDifficulty
local Feats = tables.Feats
local RequirimentFeats = tables.RequirimentFeats
local newFeat
for _, data in ipairs(Feats) do
  if data.class then
   local difficulty = featsDifficulty[data.class]
   if difficulty == "low" then
    newFeat = {id=data.id,
               skill=data.skill,
               requiriment= 25}
    if not table.find(RequirimentFeats, newFeat) then
      table.insert(RequirimentFeats, newFeat)
    end
    tables.RequirimentFeats = RequirimentFeats
    if tes3.player.object.level == 1 then
     startingFeats()
    end
   elseif difficulty == "medium" then
     newFeat = {id=data.id,
                skill=data.skill,
                requiriment= 50}
    if not table.find(RequirimentFeats, newFeat) then
      table.insert(RequirimentFeats, newFeat)
    end
    tables.RequirimentFeats = RequirimentFeats
   elseif difficulty == "high" then
     newFeat = {id=data.id,
                skill=data.skill,
                requiriment= 75}
    if not table.find(RequirimentFeats, newFeat) then
      table.insert(RequirimentFeats, newFeat)
    end
    tables.RequirimentFeats = RequirimentFeats
   end
  end
  if data.specialization then
   local difficulty = featsDifficulty[data.specialization]
   if difficulty == "low" then
    newFeat = {id=data.id,
               skill=data.skill,
               requiriment= 25}
    if not table.find(RequirimentFeats, newFeat) then
      table.insert(RequirimentFeats, newFeat)
    end
    tables.RequirimentFeats = RequirimentFeats
    if tes3.player.object.level == 1 then
     startingFeats()
    end
   elseif difficulty == "medium" then
     newFeat = {id=data.id,
                skill=data.skill,
                requiriment= 50}
    if not table.find(RequirimentFeats, newFeat) then
      table.insert(RequirimentFeats, newFeat)
    end
    tables.RequirimentFeats = RequirimentFeats
   end
  end
end
end
local function checkLevelup(e)
local featsDifficulty = tables.FeatsDifficulty
local Feats = tables.Feats
local RequirimentFeats = tables.RequirimentFeats
local availableFeats = tes3.player.data.DnDSeries.AvailableFeats or {}
local levelDividend
local availableFeatId
 for _, data1 in ipairs(Feats) do
  if data1.class then
   local difficulty = featsDifficulty[data1.class]
   if difficulty == "low" then
    levelDividend = 3
   elseif difficulty == "medium" then
    levelDividend = 5
   elseif difficulty == "high" then
    levelDividend = 10
   end
   if e.level%levelDividend == 0 then
    for _, data2 in ipairs(RequirimentFeats) do
      local skill = tes3.mobilePlayer:getSkillStatistic(data2.skill)
      local req = data2.requiriment
      if skill.base >= req then
       availableFeatId = data2.id
      end
      if data1.id == availableFeatId then
        local newFeat={id=data1.id,
                       class=data1.class}
        if table.find(availableFeats, newFeat)== nil then
          table.insert(availableFeats, newFeat)
          tes3.player.data.DnDSeries.AvailableFeats = availableFeats
        end
      end
    end
   end
  end
  if data1.specialization then
   local difficulty = featsDifficulty[data1.specialization]
   if difficulty == "low" then
    levelDividend = 3
   elseif difficulty == "medium" then
    levelDividend = 5
   end
   if e.level%levelDividend == 0 then
    for _, data2 in ipairs(RequirimentFeats) do
      local skill = tes3.mobilePlayer:getSkillStatistic(data2.skill)
      local req = data2.requiriment
      if skill.base >= req then
       availableFeatId = data2.id
      end
      if data1.id == availableFeatId then
        local newFeat={id=data1.id,
                       specialization=data1.specialization}
        if table.find(availableFeats, newFeat)== nil then
          table.insert(availableFeats, newFeat)
          tes3.player.data.DnDSeries.AvailableFeats = availableFeats
        end
      end
    end
   end
  end
 end
end
function this.checkClass(classId)
local featsDifficulty = tables.FeatsDifficulty
local class = tes3.findClass(classId)
local difficulty
 if tes3.player.object.class == class then
   difficulty = "low"
 elseif tes3.player.object.class.specialization == class.specialization then
   difficulty = "medium"
 else
   difficulty = "high"
 end
 featsDifficulty[classId] = difficulty
 tables.FeatsDifficulty = featsDifficulty
 checkRequirimentFeats()
if event.isRegistered("levelUp", checkLevelup) == false then
 event.register("levelUp", checkLevelup)
end
if event.isRegistered("activate", checkNpcClass) == false then
  event.register("activate", checkNpcClass)
 end
end
function this.checkSpecialization(specialization)
local featsDifficulty = tables.FeatsDifficulty
local difficulty
 if tes3.player.object.class.specialization == specialization then
   difficulty = "low"
 else
   difficulty = "medium"
 end
 featsDifficulty[specialization] = difficulty
 tables.FeatsDifficulty = featsDifficulty
 checkRequirimentFeats()
if event.isRegistered("levelUp", checkLevelup) == false then
 event.register("levelUp", checkLevelup)
end
if event.isRegistered("activate", checkNpcClass) == false then
  event.register("activate", checkNpcClass)
 end
end
return this