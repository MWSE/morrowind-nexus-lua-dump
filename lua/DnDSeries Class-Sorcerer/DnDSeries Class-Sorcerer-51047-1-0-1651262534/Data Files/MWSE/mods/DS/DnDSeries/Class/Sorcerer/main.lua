local framework = require('DS.DnDSeries.Class.Base.framework')
local common = require('DS.DnDSeries.Class.Sorcerer.common')
local UI =require('DS.DnDSeries.Class.Base.UI')
local class ="Sorcerer"
local charGen
local newGame
local function newGameMenu()
UI.createFeatsMenu()
end
local function simulationCheck()
    local pcClassId = tes3.player.object.class.id
    common.addFeats()
    if charGen.value == 10 then
        newGame = true
    elseif newGame == true and charGen.value == -1 then
        framework.checkClass(class)
        event.unregister("simulate", simulationCheck)
        if pcClassId == class then
            timer.start{
                type = timer.simulate,
                duration = 3,
                callback = newGameMenu
            }
        end
    elseif newGame == false and charGen.value == -1 then
     local LearnedFeats = tes3.player.data.DnDSeries.LearnedFeats or {}
       if table.empty(LearnedFeats) == false then
           common.RegisterEvents()
       end
        framework.checkClass(class)
        event.unregister("simulate", simulationCheck)
    end
end
local function loaded()
  if tes3.player.data.DnDSeries == nil then
    tes3.player.data.DnDSeries = {}
 end
newGame = false --reset so we can check chargen state again
charGen = tes3.findGlobal("CharGenState")
 if event.isRegistered("simulate", simulationCheck) == false then
  event.register("simulate", simulationCheck)
 end
end
event.register("initialized", function ()
if event.isRegistered("loaded", loaded )== false then
  event.register("loaded", loaded )
end
end)