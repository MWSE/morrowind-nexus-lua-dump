local CreatureUtils = {}

local types = require('openmw.types')
local animation = require('openmw.animation')
local core = require('openmw.core')
local prevSecond = nil

local _creatureSoundbank = {}


function CreatureUtils.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' ..  CreatureUtils.dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end



function CreatureUtils.WriteLog(text)
        print("[DynamicSounds.Creatures] " .. tostring(text))    
end

function CreatureUtils.StringContains(text, textToFind)
   if (text == nil or textToFind == nil) then return false end 
   return string.find(string.lower(text), string.lower(textToFind)) ~= nil
end

function CreatureUtils.isRunning(actor)
   return  tonumber(string.format("%.3f", types.Actor.getCurrentSpeed(actor))) == tonumber(string.format("%.3f", types.Actor.getRunSpeed(actor)))
end

function CreatureUtils.loadCreatureSoundbank(creatureId)
   local soundbank = require("scripts.DynamicSounds.soundbanks.creatures.creatures")

   for _, item in ipairs(soundbank) do
      if  CreatureUtils.StringContains(creatureId, item.creatureId)
      then
         _creatureSoundbank = item
         return
      end
   end

end

function CreatureUtils.getCreatureSoundbank()
   return _creatureSoundbank
end

function CreatureUtils.isPlayingAnim(object, groupname)
   local time = animation.getCurrentTime(object, groupname)
   return time and time >= 0
end

function CreatureUtils.getCurrentLowerBodyAnimationGroup(object)
   return animation.getActiveGroup(object, animation.BONE_GROUP.LowerBody)
end

function CreatureUtils.getCurrentAnimationGroups(object)
   return {
      LowerBody = animation.getActiveGroup(object, animation.BONE_GROUP.LowerBody),
      Torso = animation.getActiveGroup(object, animation.BONE_GROUP.Torso),
      LeftArm = animation.getActiveGroup(object, animation.BONE_GROUP.LeftArm),
      RightArm = animation.getActiveGroup(object, animation.BONE_GROUP.RightArm),
   }
end

function CreatureUtils.animCurrentTime(object, groupname)
   return animation.getCurrentTime(object, groupname)
end

function CreatureUtils.shouldPlayLoopSound(object, groupname, sound)
 
   if not CreatureUtils.isPlayingAnim(object, groupname)  
   then
      return false
   end 

   return true
   

end

function CreatureUtils.shouldPlayNonLoopSound(object, groupname, step)
   
   local currentAnimTime = CreatureUtils.animCurrentTime(object, groupname)

   if currentAnimTime == nil then return false end

   local roundedAnimTime = tonumber(string.format("%.1f", currentAnimTime)) 

   --CreatureUtils.WriteLog("roundedAnimTime: " .. roundedAnimTime)

   if ( prevSecond ~= roundedAnimTime and ( roundedAnimTime == 0.0 or roundedAnimTime%step == 0 ) )
   then
      --CreatureUtils.WriteLog("playing sound now!")
      prevSecond = roundedAnimTime
      return true
   end

end

function CreatureUtils.stringSplit(str)

   local tbl = {}
    local _tableInsert = table.insert -- for performance optimization

   for item in string.gmatch(str, '([^,]+)') do
      _tableInsert(tbl, item)
   end  

   return tbl

end

function CreatureUtils.playSound(soundIdOrPath, object, params)

   -- a better way would be to check if the file exists on disk, but i want to avoid disk activity
   if  CreatureUtils.soundSourceIsAFile(soundIdOrPath)
   then
      --CreatureUtils.WriteLog("start playing " .. soundIdOrPath)
      core.sound.playSoundFile3d(soundIdOrPath, object, params) 
   else
      core.sound.playSound3d(soundIdOrPath, object, params) 
   end   
end

--- replaces a playing sound with another. The new sound will only play after 
--- the original one completely finishes it's "stopSound" command 
---@param originalSoundId any the original sound id
---@param newsoundPath any the sound to replace the original
---@param object any creature, npc, ...
---@param params any sound params
function CreatureUtils.replacePlayingSound(originalSoundId, newsoundPath, object, params)

   --CreatureUtils.WriteLog("replacePlayingSound.Try stopping " .. originalSoundId)

   CreatureUtils.stopSound(originalSoundId, object)

   while core.sound.isSoundPlaying(originalSoundId, object) do
   end
     
   --CreatureUtils.WriteLog("replacePlayingSound.Stopped " .. originalSoundId)

   CreatureUtils.playSound(newsoundPath, object, params)
end

function CreatureUtils.soundSourceIsAFile(soundIdOrPath)
   return string.find(soundIdOrPath, ".wav") ~= nil or string.find(soundIdOrPath, ".mp3") ~= nil 
      or string.find(soundIdOrPath, ".ogg") ~= nil 
end

function CreatureUtils.stopSound(soundIdOrPath, object)
   
   if CreatureUtils.soundSourceIsAFile(soundIdOrPath)
   then
      core.sound.stopSoundFile3d(soundIdOrPath, object)     
   else
      core.sound.stopSound3d(soundIdOrPath, object) 
   end   
end

--- func desc
---@param soundIds any - soundId list separated by ","
function CreatureUtils.anySoundFromListIsPlaying(soundIds, object)
   
   if soundIds == nil or soundIds == "" then return false end

    for _, soundId in ipairs(CreatureUtils.stringSplit(soundIds)) do
      if core.sound.isSoundPlaying(soundId, object) then
         --CreatureUtils.WriteLog(soundId .. " is playing!")
         return true
      end 
    end
   
    return false

end

--- func desc
---@param soundIds any - soundId list separated by ","
function CreatureUtils.stopSoundsFromList(soundIds, object)
   
   if soundIds == nil or soundIds == "" then return end

   for _, soundId in ipairs(CreatureUtils.stringSplit(soundIds)) do
      if  core.sound.isSoundPlaying(soundId, object) then
         --CreatureUtils.WriteLog("stopping sound: " .. soundId)
         CreatureUtils.stopSound(soundId, object)
      end
     
   end

end

function CreatureUtils.currentAnimationIsOnTheList(animationList, object)
   
   if animationList == nil or animationList == "" then return false end

   local currentAnim = CreatureUtils.getCurrentAnimationGroups(object).LowerBody

   return CreatureUtils.tableContains(CreatureUtils.stringSplit(animationList), currentAnim)
end

function CreatureUtils.hasNoAnim(object)
   local currentAnim = CreatureUtils.getCurrentAnimationGroups(object).LowerBody
   return currentAnim == nil   
end


function CreatureUtils.isDead(object)
   local currentAnim = CreatureUtils.getCurrentAnimationGroups(object).LowerBody
   if currentAnim == nil then return true end  

   return CreatureUtils.StringContains( currentAnim, "death" )
   
end

function CreatureUtils.getAllSoundbankSoundsFromCurrentAnimation(object)
   
   local currentAnim = CreatureUtils.getCurrentAnimationGroups(object).LowerBody
   local resultList = {}
   local _tableInsert = table.insert -- for performance optimization

   for _, sound in pairs(_creatureSoundbank.sounds) do
      if  CreatureUtils.StringContains(currentAnim, sound.animGroupName) then
         _tableInsert(resultList, sound.animSound)
      end
   end

   return resultList

end

function CreatureUtils.tableContains(table, element)

   if table == nil or #table == 0 then return false end

   for _, tblItem in pairs(table) do
      if tblItem == element then return true end
   end
   return false

end

function CreatureUtils.distanceToPlayer(playerPos, object)
      if  playerPos == nil then return -1 end

      return (object.position - playerPos):length()
end

function CreatureUtils.isCreatureCloseEnoughToPlayerToEnableScript(playerPos, object, maxDistance)

   local distance = CreatureUtils.distanceToPlayer(playerPos, object)
   return distance ~= 1 and distance < maxDistance 

end

function CreatureUtils.stringIsNullOrEmpty(string)
   return string == nil or string:gsub("%s+", "") == ""
end

function CreatureUtils.getAllSoundsFromCurrentAnimation(object)
   
   local activeSounds = {}
   local currentAnimGroup = CreatureUtils.getCurrentAnimationGroups(object).LowerBody

   if currentAnimGroup == nil then return {} end

   local _tableInsert = table.insert -- for performance optimization

   for _, sound in pairs(CreatureUtils.getCreatureSoundbank().sounds) do
      if sound.animGroupName == currentAnimGroup or sound.animGroupName == "*" and
           not CreatureUtils.StringContains(sound.exceptAnimGroups, currentAnimGroup)
           then
              _tableInsert(activeSounds, sound)
           end
   end

   return activeSounds

end

function CreatureUtils.getAllSoundsFromInactiveAnimations(object)
   
   local inactiveSounds = {}
   local currentAnimGroup = CreatureUtils.getCurrentAnimationGroups(object).LowerBody
   local _tableInsert = table.insert -- for performance optimization

   for _, sound in pairs(CreatureUtils.getCreatureSoundbank().sounds) do
      if sound.animGroupName ~= currentAnimGroup or sound.animGroupName == "*" and
             CreatureUtils.StringContains(sound.exceptAnimGroups, currentAnimGroup)
           then
              _tableInsert(inactiveSounds, sound)
           end
   end

   return inactiveSounds

end

return CreatureUtils
