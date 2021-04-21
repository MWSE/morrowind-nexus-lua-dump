local climates = require("tew\\AURA\\Ambient\\Outdoor\\outdoorClimates")
local config = require("tew\\AURA\\config")
local modversion = require("tew\\AURA\\version")
local common=require("tew\\AURA\\common")
local tewLib = require("tew\\tewLib\\tewLib")

local isOpenPlaza=tewLib.isOpenPlaza
--local getInteriorRegion = common.getInteriorRegion

local moduleAmbientOutdoor=config.moduleAmbientOutdoor
local moduleInteriorWeather=config.moduleInteriorWeather
local playTransSounds=config.playTransSounds
local playSplash=config.playSplash
local debugLogOn = config.debugLogOn
local calmChance=config.calmChance/100
local OAvol = config.OAvol/200
local splashVol = config.splashVol/200
local playWindy=config.playWindy
local playInteriorAmbient=config.playInteriorAmbient
local version = modversion.version
--local wTC=tes3.getWorldController().weatherController

local AURAdir = "Data Files\\Sound\\tew\\AURA"
local climDir = "\\Climates\\"
local comDir = "\\Common\\"

local pathLast, pathNow, tSound = "", "", ""
local climateLast, weatherLast, timeLast, cellLast
local climateNow, weatherNow, timeNow

local windoors, interiorTimer
local rArray, qArray, wArray, cArray = {},{},{},{}
local tArray=common.tArray

local function debugLog(string)
   if debugLogOn then
      mwse.log("[AURA "..version.."] OA: "..string.format("%s", string))
   end
end

-- Building clear paths array --
debugLog("Building clear weather regular array.")
for climate in lfs.dir(AURAdir..climDir) do
   if climate ~= ".." and climate ~= "." then
      rArray[climate]={}
      for time in lfs.dir(AURAdir..climDir..climate) do
         if time ~= ".." and time ~= "." then
            rArray[climate][time]={}
            for rSoundfile in lfs.dir(AURAdir..climDir..climate.."\\"..time) do
               if rSoundfile ~= ".." and rSoundfile ~= "." then
                  if string.endswith(rSoundfile, ".wav") then
                     table.insert(rArray[climate][time], rSoundfile)
                     debugLog("Adding file: "..rSoundfile)
                  end
               end
            end
         end
      end
   end
end

-- Bulding quiet paths array --
debugLog("Building clear weather quiet array.")
for qSoundfile in lfs.dir(AURAdir..comDir.."Quiet") do
   if string.endswith(qSoundfile, ".wav") then
      table.insert(qArray, qSoundfile)
      debugLog("Adding file: "..qSoundfile)
   end
end

-- Building warm wind paths array --
debugLog("Building warm wind array.")
for wSoundfile in lfs.dir(AURAdir..comDir.."Warm") do
   if string.endswith(wSoundfile, ".wav") then
      table.insert(wArray, wSoundfile)
      debugLog("Adding file: "..wSoundfile)
   end
end

-- Building cold wind paths array --
debugLog("Building cold wind array.")
for cSoundfile in lfs.dir(AURAdir..comDir.."Cold") do
   if string.endswith(cSoundfile, ".wav") then
      table.insert(cArray, cSoundfile)
      debugLog("Adding file: "..cSoundfile)
   end
end

-- Fetching randomised soundpath from a pre-build clear weather array --
local function getPathClear()
   if calmChance<math.random() then
      debugLog("Getting regular weather soundpath.")
      local soundPaths=rArray[climateNow][timeNow]
      pathNow="tew\\AURA"..climDir..climateNow.."\\"..timeNow.."\\"..soundPaths[math.random(1, #soundPaths)]
   else
      debugLog("Getting quiet weather soundpath.")
      local quietType=math.random(3)
      if quietType == 1 then
         pathNow="tew\\AURA"..comDir.."Quiet\\"..qArray[math.random(1, #qArray)]
      elseif quietType == 2 then
         pathNow="tew\\AURA"..comDir.."Cold\\"..cArray[math.random(1, #cArray)]
      else
         pathNow="tew\\AURA"..comDir.."Warm\\"..wArray[math.random(1, #wArray)]
      end
   end
end


-- Fetching randomised soundpath from a pre-build windy weather array --
local function getPathWindy()
   debugLog("Getting windy weather soundpath.")
   if weatherNow == 3 or weatherNow == 4 then
      debugLog("Found warm weather, using warm wind loops.")
      pathNow="tew\\AURA"..comDir.."Warm\\"..wArray[math.random(1, #wArray)]
   elseif weatherNow == 8 or weatherNow == 5 then
      debugLog("Found cold weather, using cold wind loops.")
      pathNow="tew\\AURA"..comDir.."Cold\\"..cArray[math.random(1, #cArray)]
   end
end

local function playExterior(cell)
   timer.start{duration=0.62, type=timer.real, callback=function()
      debugLog("Playing exterior loop. File: "..pathNow)
      tes3.playSound{soundPath=pathNow, volume=1.0*OAvol, loop=true, reference=cell}
   end}
end

local function playTrans(cell)
   if cell.isInterior and not cell.behavesAsExterior then
      return
   else
   tes3.playSound{sound=tSound, volume=0.3*OAvol, pitch=0.8, reference=tes3.player}
   debugLog("Playing transition rustle. Sound: "..tSound)
   end
end

local function playInteriorBig(windoor)
   timer.start{duration=0.62, type=timer.real, callback=function()
      if windoor==nil then debugLog("Dodging an empty ref.") return end
      if cellLast and pathLast and not cellLast.isInterior then
         debugLog("Playing interior ambient sounds for big interiors using last path. File: "..pathLast)
         tes3.playSound{soundPath=pathLast, reference=windoor, loop=true, volume=0.35*OAvol, pitch=0.8}
      else
         debugLog("Playing interior ambient sounds for big interiors using new path. File: "..pathNow)
         tes3.playSound{soundPath=pathNow, reference=windoor, loop=true, volume=0.35*OAvol, pitch=0.8}
      end
   end}
end

local function updateInteriorBig()
   debugLog("Updating interior doors and windows.")
   local playerPos=tes3.player.position
   for _, windoor in ipairs(windoors) do
      if common.getDistance(playerPos, windoor.position) > 2048
      and windoor~=nil then
         playInteriorBig(windoor)
      end
   end
end

local function playInteriorSmall(cell)
   timer.start{duration=0.62, type=timer.real, callback=function()
      if cellLast and pathLast and not cellLast.isInterior then
         debugLog("Playing interior ambient sounds for small interiors using last path. File: "..pathLast)
         tes3.playSound{soundPath=pathLast, reference=cell, loop=true, volume=0.3*OAvol, pitch=0.8}
      else
         debugLog("Playing interior ambient sounds for small interiors using new path. File: "..pathNow)
         tes3.playSound{soundPath=pathNow, reference=cell, loop=true, volume=0.3*OAvol, pitch=0.8}
      end
   end}
end

local function cellCheck()
   local region

   OAvol = config.OAvol/200

   debugLog("Cell changed or time check triggered. Running cell check.")

   -- Getting rid of timers on cell check --
   if not interiorTimer then
      interiorTimer = timer.start({duration=3, iterations=-1, callback=updateInteriorBig, type=timer.real})
      interiorTimer:pause()
   else
      interiorTimer:pause()
   end

   local cell = tes3.getPlayerCell()
   if cell == nil then debugLog("No cell detected. Returning.") return end

   if cell.isInterior then
      region = tes3.getRegion({useDoors=true}).name
      --region = getInteriorRegion(cell)
   else
      region = tes3.getRegion().name
   end

   if region == nil then debugLog("No region detected. Returning.") return end

   -- Checking climate --
   for kRegion, vClimate in pairs(climates.regions) do
      if kRegion==region then
         climateNow=vClimate
      end
   end
   if not climateNow then debugLog ("Blacklisted region - no climate detected. Returning.") return end
   debugLog("Climate: "..climateNow)

   -- Checking time --
   local gameHour=tes3.worldController.hour.value
   if gameHour >= 5 and gameHour <= 8 then
      timeNow="Dawn"
   elseif gameHour >= 18 and gameHour <= 21  then
      timeNow="Dusk"
   elseif gameHour > 8 and gameHour < 18 then
      timeNow="Day"
   elseif gameHour < 5 or gameHour > 21 then
      timeNow="Night"
   end
   debugLog("Time: "..timeNow)

   -- Checking current weather --
   weatherNow=tes3.getRegion({useDoors=true}).weather.index
   debugLog("Weather: "..weatherNow)

   -- Transition filter chunk --
   if timeNow==timeLast
   and climateNow==climateLast
   and weatherNow==weatherLast
   and (common.checkCellDiff(cell, cellLast)==false
   or cell == cellLast) then
      debugLog("Same conditions detected. Returning.")
      return
   elseif timeNow~=timeLast and weatherNow==weatherLast then
      if (weatherNow >= 4 and weatherNow < 6) or (weatherNow == 8) then
         debugLog("Same conditions detected. Returning.")
         return
      end
   end

   debugLog("Different conditions detected. Resetting sounds.")
   tes3.removeSound{reference=cell}

   if moduleInteriorWeather == false and windoors[1]~=nil and weatherNow<4 or weatherNow==8 then
      for _, windoor in ipairs(windoors) do
         tes3.removeSound{reference=windoor}
     end
     debugLog("Clearing windoors.")
   end

   -- Getting appropriate paths per conditions detected --
   if pathLast and cellLast and common.checkCellDiff(cell, cellLast)==true and timeNow==timeLast
   and weatherNow==weatherLast and climateNow==climateLast then
      pathNow=pathLast
         -- New in 2.0.1; using same soundpath when entering int/ext in same area; time/weather change will randomise path again --
      debugLog("Cells changed, but conditions are the same. Using last path: "..pathNow)
   else
      if weatherNow >= 0 and weatherNow <4 then
         debugLog("Clear weather detected.")
         getPathClear()
      elseif (weatherNow >= 4 and weatherNow < 6) or (weatherNow == 8) then
         if playWindy then
            debugLog("Bad weather detected and windy option on.")
            getPathWindy()
         else
            debugLog("Bad weather detected and no windy option on. Returning.")
            return
         end
      elseif weatherNow == 6 or weatherNow == 7 or weatherNow == 9 then
         debugLog("Extreme weather detected.")
         return
      end
      debugLog("Done getting sound. Current path: "..pathNow)
   end


   if playTransSounds then
      tSound=tArray[math.random(1, #tArray)]
      debugLog ("Transition sound: "..tSound)
      playTrans(cell)
   end

   if not cell.isInterior
   or (cell.isInterior) and (cell.behavesAsExterior
   and not isOpenPlaza(cell)) then
      debugLog("Found exterior cell.")
      playExterior(cell)
   elseif cell.isInterior then
      if (not playInteriorAmbient) or (playInteriorAmbient and isOpenPlaza(cell) and weatherNow==3) then
         debugLog("Found interior cell. Removing sounds.")
         tes3.removeSound{reference=cell}
      else
         if common.getCellType(cell, common.cellTypesSmall)==true
         or common.getCellType(cell, common.cellTypesTent)==true then
            playInteriorSmall(cell, weatherNow)
            debugLog("Found small interior cell. Playing interior loops.")
         else
            windoors=nil
            windoors=common.getWindoors(cell)
            if windoors ~= nil then
               for _, windoor in ipairs(windoors) do
                  playInteriorBig(windoor)
               end
               interiorTimer:resume()
               debugLog("Found big interior cell. Playing interior loops.")
            end
        end
      end
   end

   timeLast=timeNow
   climateLast=climateNow
   weatherLast=weatherNow
   cellLast=cell
   pathLast=pathNow
   debugLog("Cell check complete.")
end

local function positionCheck(e)
   local cell=tes3.getPlayerCell()
   local element=e.element
   debugLog("Player underwater. Stopping AURA sounds.")
   if (not cell.isInterior) or (cell.behavesAsExterior) then
      tes3.removeSound{reference=cell}
      tes3.playSound{soundPath=pathLast, volume=0.4*OAvol, pitch=0.5, reference=cell, loop=true}
   end
   if playSplash and moduleAmbientOutdoor then
      tes3.playSound{soundPath="Fx\\envrn\\splash_lrg.wav", volume=0.5*splashVol, pitch=0.6}
   end
   element:register("destroy", function()
      debugLog("Player above water level. Resetting AURA sounds.")
      if (not cell.isInterior) or (cell.behavesAsExterior) then
         tes3.removeSound{reference=cell}
         tes3.playSound{soundPath=pathLast, volume=1.0*OAvol, reference=cell, loop=true}
      end
      timer.start({duration=5, callback=cellCheck, type=timer.real})
      if playSplash and moduleAmbientOutdoor then
         tes3.playSound{soundPath="Fx\\envrn\\splash_sml.wav", volume=0.6*splashVol, pitch=0.7}
      end
   end)
end

local function runResetter()
   pathLast, pathNow, tSound = "", "", ""
   climateLast, weatherLast, timeLast = nil, nil, nil
   climateNow, weatherNow, timeNow = nil, nil, nil
   windoors = {}
end

local function runHourTimer()
   timer.start({duration=0.5, callback=cellCheck, iterations=-1, type=timer.game})
end

debugLog("Outdoor Ambient Sounds module initialised.")
event.register("loaded", runHourTimer, {priority=-160})
event.register("load", runResetter, {priority=-160})
event.register("cellChanged", cellCheck, {priority=-160})
event.register("weatherTransitionFinished", cellCheck, {priority=-160})
event.register("weatherChangedImmediate", cellCheck, {priority=-160})
event.register("uiActivated", positionCheck, {filter="MenuSwimFillBar", priority = -5})