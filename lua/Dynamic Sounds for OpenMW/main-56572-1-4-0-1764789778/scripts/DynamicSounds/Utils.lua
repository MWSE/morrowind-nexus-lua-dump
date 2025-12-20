local Utils = {}
local world = require("openmw.world")
local core = require("openmw.core")
local vfs = require('openmw.vfs')
local types = require('openmw.types')
local SettingsManager = require('scripts.DynamicSounds.SettingsManager')

local _settings = { }

local _defaultPlayChance = SettingsManager.currentSettings().playChance -- 20
local _debugMode =  SettingsManager.currentSettings().enableDebugMode -- false
local _maxDistanceObjectSounds = SettingsManager.currentSettings().maxDistanceObjectSounds -- 2000
local _dayStartingHour = SettingsManager.currentSettings().dayStartingHour
local _dayEndingHour = SettingsManager.currentSettings().dayEndingHour

-- wheather 
local _interiorCells = {}
local _regionWeathers = {}
local _lastVisitedRegion = ""

local _mathRnd = math.random

function Utils.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' ..  Utils.dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end



function Utils.loadSoundBanks()

    _settings.soundbanks = {}
    local _tableInsert = table.insert

    for file in vfs.pathsWithPrefix("scripts\\DynamicSounds\\soundbanks") do
        file = file.gsub(file, ".lua", "")

        local soundbank = require(file)
        _tableInsert(_settings.soundbanks, soundbank)
    end

    Utils.WriteLog( "loadSoundBanks: " .. #_settings.soundbanks .. " loaded." )

end

function Utils.soundbanksLoaded()
    return _settings.soundbanks ~= nil
end

-- returns the section area of the config file corresponding to the cellObj 
function Utils.getConfigSectionForCell(cellObj)

    local cellName = Utils.getCellName(cellObj)  -- Utils.getCellGeneralName(cellObj)
    local regionName = Utils.getCellRegionName(cellObj)

    local matchCellSoundBank = {}
    local matchRegionSoundBank = {}
    local matchDefaultSoundBank = {}

    for _, soundbank in pairs(_settings.soundbanks) do

        -- finds the matching cell soundbank
        if cellName ~= "" and soundbank.affectingCells ~= nil and #matchCellSoundBank == 0 then
            for _, soundbankCell in ipairs(soundbank.affectingCells) do
                if Utils.phraseContainsPhrase(cellName, soundbankCell) then
                    if ( 
                       (Utils.cellIsExterior(cellObj) and soundbank.isInterior == false ) or
                       (Utils.cellIsExterior(cellObj) == false and soundbank.isInterior == true ) or
                       (Utils.cellIsExterior(cellObj) and soundbank.isInterior == nil)
                  ) then
                      matchCellSoundBank = soundbank
                      break
              end 

                end
                            
            end
        end

         -- finds the matching region soundbank
         if regionName ~= "" and soundbank.affectingRegions ~= nil and #matchRegionSoundBank == 0 
             and Utils.cellIsExterior(cellObj) then
                for _, soundbankRegion in ipairs(soundbank.affectingRegions) do
                    if Utils.phraseContainsPhrase(regionName, soundbankRegion) then
                        matchRegionSoundBank = soundbank
                        break
                    end                
                end
        end
        
    end

        -- finds the default soundbank
        matchDefaultSoundBank = Utils.getDefaultSoundbank((not Utils.cellIsExterior(cellObj)))

        if (_debugMode) then
            Utils.WriteLog("matchCellSoundBank " .. Utils.dump(matchCellSoundBank))
            Utils.WriteLog("matchRegionSoundBank " .. Utils.dump(matchRegionSoundBank))        
            Utils.WriteLog("matchDefaultSoundBank " .. Utils.dump(matchDefaultSoundBank))             
        end

        -- merge ambient soundbank
        local mergeResult = Utils.joinSoundbanks(matchCellSoundBank, matchRegionSoundBank)

        --Utils.WriteLog("mergeResult reg " .. Utils.dump(mergeResult))

        -- merge default soundbank
        mergeResult = Utils.joinSoundbanks(mergeResult, matchDefaultSoundBank)

       --Utils.WriteLog("mergeResult def " .. Utils.dump(mergeResult))

        return mergeResult

end




function Utils.phraseContainsPhrase(basePhrase, wordsToFind)

    local isAMatch = Utils.StringContains(basePhrase, wordsToFind)
    
    Utils.WriteLog("checking " .. basePhrase .. " against " .. wordsToFind .. " is match? " .. tostring(isAMatch) )

    -- since isAMatch also matches "Sad" with "Raven Rock, Sados Relothan's House"
    -- we need to check for whole words (Sados should not be a match)
    if (isAMatch) then
        
        local startIndex, endIndex = string.find(basePhrase, wordsToFind)

        if startIndex == nil or endIndex == nil then return false end

        if  (
                string.sub(basePhrase, endIndex+1, endIndex+1) == " " or
                string.sub(basePhrase, endIndex+1, endIndex+1) == "" or
                string.sub(basePhrase, endIndex+1, endIndex+1) == ","
            ) 
            and   
            (
                string.sub(basePhrase, startIndex-1, startIndex-1) == " " or
                string.sub(basePhrase, startIndex-1, startIndex-1) == "" or 
                string.sub(basePhrase, startIndex-1, startIndex-1) == ","
            ) 

        then
            return true
        end

    end
    
    return false

end

function Utils.cellIsExterior(cell)
    -- for the purpose of this mod, a QuasiExterior is considered exterior 
    return cell.isExterior or cell:hasTag("QuasiExterior")
end

function Utils.cellNamePartiallyExistsOnCellList(cellName, cellList)

    Utils.WriteLog("cellNamePartiallyExistsOnCellList:" .. cellName)

    if #cellList == 0 then return false end

    for _, cellListItem in ipairs(cellList) do
        if Utils.phraseContainsPhrase(cellName, cellListItem) then
            Utils.WriteLog("cellNamePartiallyExistsOnCellList: yes!")
            return true        
        end                    
    end    
    Utils.WriteLog("cellNamePartiallyExistsOnCellList: no!")
    return false
    
end

--- returns the default interior or exterior config section  
---@param isInterior boolean true to get the interior section, false otherwise
function Utils.getDefaultSoundbank(isInterior)

    --Utils.WriteLog("finding default settings for area. Is interior? " .. tostring(interior) )

    for _, soundbank in pairs(_settings.soundbanks) do
        if soundbank.affectingCells ~= nil 
            and soundbank.affectingCells[1] == "DEFAULT" and soundbank.isInterior == isInterior then
            return soundbank
        end
    end

    return nil

end

--- returns the region soundbank, if it exists
function Utils.getRegionSoundbank(regionName)

    --Utils.WriteLog("finding default settings for area. Is interior? " .. tostring(interior) )

    for _, soundbank in pairs(_settings.soundbanks) do
        if Utils.arrayContains(soundbank.affectingRegions, regionName) then
            return soundbank
        end
    end

    return nil

end

function Utils.joinSoundbanks(soundbank1, soundbank2)

    local _tableInsert = table.insert -- for performance optimization

    if (soundbank1 == soundbank2 and soundbank1 == nil) then return {} end 

    if soundbank1.ambientLoopSounds == nil and soundbank1.objects == nil then
        return soundbank2
    end 
    
    if soundbank2.ambientLoopSounds == nil and soundbank2.objects == nil then
        return soundbank1
    end    
   
    if (Utils._debugMode) then
        Utils.WriteLog("merging soundbank " )
        Utils.WriteLog( Utils.dump(soundbank2) )
        Utils.WriteLog(" into " )
        Utils.WriteLog( Utils.dump(soundbank1) )      
    end


    -- merge ambient sounds
    for _, defLoopSound in ipairs(soundbank2.ambientLoopSounds) do
       
        local isMatch = false
       
        if soundbank1.ambientLoopSounds ~= nil then
 
            -- only merge if the soundbank has not already the same ambient sound   
            for _, loopSound in pairs(soundbank1.ambientLoopSounds) do
                isMatch  = defLoopSound.soundPath == loopSound.soundPath and 
                defLoopSound.loop == loopSound.loop and 
                defLoopSound.dayCycle == loopSound.dayCycle and 
                Utils.arraysAreEqual(defLoopSound.weather, loopSound.weather)  
                if isMatch then break end
            end
            if not isMatch then
                _tableInsert(soundbank1.ambientLoopSounds, defLoopSound)               
            end            

        end
        
    end  

    -- merge object sounds
    if soundbank2.objects ~= nil then
        for _, objDefault in ipairs(soundbank2.objects) do
            if not Utils.soundBankContainsObject(soundbank1, objDefault[1]) then
                _tableInsert(soundbank1.objects, objDefault)
            end   
     end       
    end

  

    if (Utils._debugMode) then
        Utils.WriteLog(" result of merge: " )
        Utils.WriteLog( Utils.dump(soundbank1) )        
    end 


    return soundbank1
end

function Utils.getAmbientLoopSounds(areaConfigSection)

    -- also does some cleaning, like reset loaded flag and clean the cellContainsObjectsResult 
    for _, ambientLoopSound in pairs(areaConfigSection.ambientLoopSounds) do
        ambientLoopSound.loaded = false

        if ambientLoopSound.ifCellContainsObjects ~= nil then
            ambientLoopSound.cellContainsObjectsResult = nil
        end  
    end

    return areaConfigSection.ambientLoopSounds

end

function Utils.StringContains(text, textToFind)

    if (text == nil or textToFind == nil) then return false end
    
    return string.find(string.lower(text), string.lower(textToFind)) ~= nil
end


-- returns a list of cell objects that match cellObjectSettings 
function Utils.getCellObjectsByObjectSettings(cell, cellObjectSettings)

    local objects = {}
    local _tableInsert = table.insert -- for performance optimization

    for _, cellObj in ipairs(cell:getAll()) do
        if Utils.StringContains(cellObj.recordId, cellObjectSettings[1]) then
            _tableInsert(objects, cellObj)
        end
    end
    return objects

end


-- test for 0.50 weather
function Utils.getOutsideWeather(cell)

    Utils.WriteLog("looking into cell: " .. cell.name, true)

    if Utils.cellIsExterior(cell) then return core.weather.getCurrent(cell).scriptId end

    local doors = cell:getAll(types.Door)

    if doors == nil then return 0 end

    for _, door in pairs(doors) do   
        Utils.WriteLog("looking into door: " .. door.id , true)
        return Utils.getOutsideWeather( types.Door.destCell(door) )
    end
    
end

function Utils.getCellObjectsByRecordId(cell, recordId)

    local objects = {}
    local _tableInsert = table.insert -- for performance optimization

    for _, cellObj in ipairs(cell:getAll()) do
        if Utils.StringContains(cellObj.recordId, recordId) then
            --Utils.WriteLog("cell contains objects with recId " .. recordId)
            _tableInsert(objects, cellObj)
        end
    end
    return objects

end


function Utils.cellContainsObjectByRecordId(cell, recordId)
    local res =  Utils.getCellObjectsByRecordId(cell, recordId)
    return (res ~= nil and res[1] ~= nil )
end

--- func desc
---@param cell any
---@param recordIds string A string containing a list of comma separated recordIds
function Utils.cellContainsAnyObjectWithRecordIds(cell, recordIds)
    
    for recordId in string.gmatch(recordIds, '([^,]+)') do
        if Utils.cellContainsObjectByRecordId(cell, recordId) then
            return true
        end
     end

     return false
end

--- func desc
---@param cell any
---@param recordIds string A string containing a list of comma separated recordIds
function Utils.cellContainsAnyObjectWithRecordIdsV2(cell, recordIds)
    
    local recordIdArray = {}
    local _tableInsert = table.insert -- for performance optimization

    for recordId in string.gmatch(recordIds, '([^,]+)') do
        _tableInsert(recordIdArray, recordId)
     end   

    for _, cellObj in ipairs(cell:getAll()) do

        for _, recordId in ipairs(recordIdArray) do
            if Utils.StringContains(cellObj.recordId, recordId) then
                return true
            end
        end

    end

     return false
end

--- func desc
---@param soundFromConfig string A string containing a list of comma separated recordIds
function Utils.currentCellContainsAnyObjectWithRecordIds(soundFromConfig)

    -- since this is a resource intensive task (checking all objects on the cell every 1 second to see
    -- if any object matches what we have on sound.ifCellContainsObjects), we will store the result on
    -- sound.cellContainsObjectsResult, so we only do this operation once, when entering a cell
    if soundFromConfig.cellContainsObjectsResult == nil then
        local res = Utils.cellContainsAnyObjectWithRecordIdsV2(world.players[1].cell, soundFromConfig.ifCellContainsObjects)   
        soundFromConfig.cellContainsObjectsResult = res     
    end    

    Utils.WriteLog("cell contains objects with recordIds .." .. soundFromConfig.ifCellContainsObjects .. "? " .. tostring(soundFromConfig.cellContainsObjectsResult) )

    return soundFromConfig.cellContainsObjectsResult

end

function Utils.distanceToPlayer(object)

    if object.cell:isInSameSpace(world.players[1]) then
        return (object.position - world.players[1].position):length()
    end

    return -1
end


function Utils.pickRandomAmbientLoopSoundFromConfig(cellSettings)

    local soundsAvailableCount = #cellSettings.ambientLoopSounds
    return cellSettings.ambientLoopSounds[_mathRnd(soundsAvailableCount)]

end

function Utils.soundListContains(sounds, soundToCheck)
          return Utils.getSound(sounds, soundToCheck)  ~= nil       
end

function Utils.getSound(sounds, soundToFind)
    
    for _, sound in pairs(sounds) do
        if  sound.soundPath == soundToFind.soundPath and 
            Utils.arraysAreEqual(sound.weather, soundToFind.weather) and  
            sound.volume == soundToFind.volume and  
            sound.ifCellContainsObjects == soundToFind.ifCellContainsObjects 
        then return sound end
    end
    return nil

end

function Utils.soundBankContainsObject(soundbank, objectName)
    return Utils.getSoundbankObject(soundbank, objectName)  ~= nil       
end

function Utils.getSoundbankObject(soundbank, objectName)
    for _, object in pairs(soundbank.objects) do
    if object[1] == objectName then return object[1] end
    end
return nil

end


function Utils.getSoundsForCell(cellObjectSettings)

    local returnArray = {}
    local _tableInsert = table.insert -- for performance optimization

    for _, objectSound in ipairs(cellObjectSettings[2]) do
        --objectSound.loaded = false
        _tableInsert(returnArray, objectSound)
    end

    return returnArray

end

function Utils.getDoorDestCellName(object)
    
    if not Utils.ObjectIsDoor(object) then
        return nil
    end

    local destCell = types.Door.destCell(object)
    
    if destCell == nil then return nil end
    
    return destCell.name ~= nil and destCell.name or nil  

end

function Utils.ObjectIsDoor(object)
    return object.type == types.Door
end

--- returns true if a door object has it's destCell name matching the list in 
--    "ifDestinationCellsAre" from the soundbank 
--- returns false if not, or if the object is not a door  
---@param doorObject any
---@param soundFromConfig any
function Utils.doorShouldPlaySound(doorObject, soundFromConfig)
    
    if soundFromConfig.ifDestinationCellsAre == nil 
      or #soundFromConfig.ifDestinationCellsAre == 0 then return true end
    

    if soundFromConfig.ifDestinationCellsAre ~= nil and Utils.ObjectIsDoor(doorObject) then
        local destCellName = Utils.getDoorDestCellName(doorObject)

        if destCellName == nil then return false end

        local isAMatch = false

        for _, destinationCell in pairs(soundFromConfig.ifDestinationCellsAre) do
            isAMatch = Utils.phraseContainsPhrase(destCellName, destinationCell)
            if isAMatch then
                return true
            end
        end
    end

    return false
end


function Utils.getGameHour()
    return (core.getGameTime() / 60 / 60) % 24
end

function Utils.isDayTime()
    return Utils.getGameHour() > _dayStartingHour and Utils.getGameHour() < _dayEndingHour
end

function Utils.isNightTime()
    return not Utils.isDayTime()
end

function Utils.getCurrentDayCycle()
    if Utils.isDayTime() then
        return "day"
    end
    return "night"
end


function Utils.getCurrentCellNameOrRegion()
    return Utils.getCellNameOrRegion(world.players[1].cell)
end

function Utils.getCellNameOrRegion(cell)

    if Utils.getCellName(cell) ~= "" then
        return Utils.getCellName(cell)
    end

    return Utils.getCellRegionName(cell)

end

function Utils.getCellName(cell)
    return cell.name 
end

function Utils.getCellRegionName(cell)
    return cell.region
end

function Utils.objectIsPlayingSound(cellObject, soundPath)

    Utils.WriteLog("objectIsPlayingSound: " .. cellObject.recordId .. " " .. soundPath )

    return core.sound.isSoundFilePlaying(soundPath, cellObject)
end

function Utils.objectIsPlayingSounds(cellObject, objSoundListSection)

   for _, sound in ipairs(objSoundListSection) do
        if Utils.objectIsPlayingSound(cellObject, sound.soundPath) then
            return true
        end
   end

   return false

end

function Utils.SoundAlreadyPlayingOnCell(cellObjectList, soundPath)
    for _, cellObject in ipairs(cellObjectList) do
        if Utils.objectIsPlayingSound(cellObject[1], soundPath) then
            return true
        end
    end

    return false
end


function Utils.pickRandomItemFromList(list)
    return list[_mathRnd(#list)]
end

-- note: a valid random sound is a random sound with valid weather and day cycle   
function Utils.pickRandomValidObjectSoundFromConfig(object)

    local validationList = {}
    local _tableInsert = table.insert -- for performance optimization

    -- this means the object is no longer active on cell 
    if object[1].cell == nil then return end 

    for _, sound in ipairs(object[2]) do

        if (not Utils.isInvalidSound(sound) and 
            Utils.distanceToPlayer(object[1]) < _maxDistanceObjectSounds ) then
            _tableInsert(validationList, sound)
        end
    end

   -- Utils.WriteLog("Utils.pickRandomValidObjectSoundFromConfig: " .. Utils.dump(validationList))

    return  Utils.pickRandomItemFromList(validationList)

end

-- note: a valid random ambient sound is a random non-loop sound with valid weather and day cycle   
function Utils.pickRandomValidAmbientSoundFromConfig(soundList)

    local validationList = {}
    local _tableInsert = table.insert -- for performance optimization

    for _, sound in ipairs(soundList) do

        if ( (sound.loop == nil or sound.loop == false)  and not Utils.isInvalidSound(sound)) then
            _tableInsert(validationList, sound)
        end
    end

    return  Utils.pickRandomItemFromList(validationList)

end

-- note: an invalid sound is a sound with any of the following:
-- * invalid weather; 
-- * invalid day cycle; 
-- * no objects with recordId defined by "ifCellContainsObjects"     
-- * no soundPath
function Utils.isInvalidSound(soundFromConfig)

   --Utils.WriteLog("Utils.isInvalidSound: " .. Utils.dump(soundFromConfig))

   if soundFromConfig.soundPath == nil then return true end

   if (soundFromConfig.dayCycle ~= nil and soundFromConfig.dayCycle ~= Utils.getCurrentDayCycle()) then
    return true
   end

   if (soundFromConfig.weather ~= nil and not Utils.arrayContains(soundFromConfig.weather, Utils.getCurrentWeather())) then
    return true
   end

   if (soundFromConfig.exceptInCells ~= nil and Utils.cellNamePartiallyExistsOnCellList(Utils.getCurrentCellNameOrRegion(), soundFromConfig.exceptInCells)  ) then
        return true
   end

   if (soundFromConfig.ifCellContainsObjects ~= nil 
      and not Utils.currentCellContainsAnyObjectWithRecordIds(soundFromConfig)) then
        return true
    end

    return false
         
end


function Utils.shouldPlaySound(soundToPlay, objectRecordId, objectSounds)
    -- return _mathRnd(0,_timer) < 
    --     (soundToPlay.PlayChance ~=nil and soundToPlay.PlayChance or _defaultPlayChance  ) 

    -- random high limit increases according to the number of objects with the same recordId 
    local rndHighLimit = 100 * Utils.getObjectCountWithSameRecordId(objectRecordId, objectSounds)

    --Utils.WriteLog("rndHighLimit for " .. objectRecordId .. ": " .. rndHighLimit)

    return _mathRnd(0, rndHighLimit ) <
        (soundToPlay.PlayChancePercent ~=nil and soundToPlay.PlayChancePercent or _defaultPlayChance  )
end

function Utils.shouldPlayNonLoopAmbientSound(soundToPlay)

    local rndHighLimit = 100 * 1

    local shouldPlay = _mathRnd(0, rndHighLimit ) <
        (soundToPlay.PlayChancePercent ~=nil and soundToPlay.PlayChancePercent or _defaultPlayChance  )

    Utils.WriteLog("shouldPlayNonLoopAmbientSound.shouldPlay: " .. soundToPlay.soundPath .. "? " .. tostring(shouldPlay) )

    return shouldPlay
end

function Utils.getObjectCountWithSameRecordId(objectRecordId, objectSounds)

    local count = 0

    for _, objectInfo in ipairs(objectSounds) do
        count = count + ( objectInfo[1].recordId == objectRecordId and 1 or 0 )
    end

    return count

end

--- compare the content of 2 arrays and return true if it is the same
--- or if the arrays are nil
--- @param array1 any
--- @param array2 any
---@return boolean
function Utils.arraysAreEqual(array1, array2)
    if (array1 == array2) then return true end
    if (#array1 ~= #array2) then return false end

    for index, _ in ipairs(array1) do
        if array1[index] ~= array2[index] then
            return false
        end

        return true
    end
end

function Utils.arrayContains(array, value)
    
    if array == nil then return false end
    
    for _, item in ipairs(array) do
        if item == value then 
            return true 
        end
    end

    return false
end

--- https://en.uesp.net/wiki/Morrowind_Mod:GetCurrentWeather
            -- 0	Clear
			-- 1	Cloudy
			-- 2	Foggy
			-- 3	Overcast
			-- 4	Rain
			-- 5	Thunder
			-- 6	Ash
			-- 7	Blight
			-- 8	Snow (Bloodmoon)
			-- 9	Blizzard (Bloodmoon)
function Utils.getCurrentWeather()
    
  -- Early exit if running OpenMW 0.49
    if not core.weather then
        return world.mwscript.getGlobalVariables().omwWeather
    end
    
    local currentCell = world.players[1].cell
    
    if Utils.cellIsExterior(currentCell) then
        _lastVisitedRegion = currentCell.region
        _regionWeathers[_lastVisitedRegion] = core.weather.getCurrent(currentCell).scriptId
        return _regionWeathers[_lastVisitedRegion]
    end    

    local interior = _interiorCells[currentCell.id]
    if interior then
        return _regionWeathers[interior.region or _lastVisitedRegion] or 1
    end


   -- Scan nearby doors for an exterior cell destination    
    interior = {}
    _interiorCells[currentCell.id] = interior
    for _, v in pairs(currentCell:getAll(types.Door)) do
        local destCell = types.Door.destCell(v)
        if destCell and Utils.cellIsExterior(destCell) then
            interior.region = destCell.region
            break
        end
    end
    return _regionWeathers[interior.region or _lastVisitedRegion] or 1


end

function Utils.WriteLog (text, forcePrint)
    if forcePrint == true or _debugMode then
        print("[DynamicSounds] " .. tostring(text))
    end
    
end

function Utils.setSettings(data)
    _debugMode = SettingsManager.currentSettings().enableDebugMode
	_defaultPlayChance = SettingsManager.currentSettings().playChance	
	_maxDistanceObjectSounds = SettingsManager.currentSettings().maxDistanceObjectSounds
    _dayStartingHour = SettingsManager.currentSettings().dayStartingHour
    _dayEndingHour = SettingsManager.currentSettings().dayEndingHour
end

function Utils.debugMode()
    return _debugMode
end

return Utils
