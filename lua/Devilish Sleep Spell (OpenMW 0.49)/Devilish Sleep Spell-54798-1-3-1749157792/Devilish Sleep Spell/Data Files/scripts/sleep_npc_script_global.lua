local time = require('openmw_aux.time')
local world = require('openmw.world')
local types = require('openmw.types')

local function SleepCheck(data)
    world.mwscript.getGlobalScript("detd_sleepcheck_global").variables.CheckSleep = data
    end


    return {
        eventHandlers = {
          detdGlobalCheckSleep = SleepCheck
                }
            }