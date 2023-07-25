local storage = require("openmw.storage")
local self = require("openmw.self")
local types = require("openmw.types")

local playerSettings = storage.globalSection("SettingsDebugMode")
local util = require("openmw.util")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local badInv = nil
local badWait = -1
local eqCache = nil
local time = require('openmw_aux.time')
local calendar = require('openmw_aux.calendar')


local function setGameTime(desiredGameTime)
 
    local newMonth = tonumber(calendar.formatGameTime("%m", desiredGameTime)) - 1
    local newDaysPassed = math.floor(desiredGameTime / time.day)
    local newGameHour = tonumber(desiredGameTime - (newDaysPassed * time.day)) / time.hour
    local newDay = tonumber(calendar.formatGameTime("%d", desiredGameTime))
    print(newMonth, newGameHour, newDay, newDaysPassed)

    self.mwscript.newMonth = newMonth
    self.mwscript.newHour = newGameHour
    self.mwscript.newDaysPassed = newDaysPassed
    self.mwscript.newDay = newDay
    self.mwscript.newGameHour = newGameHour
    self.mwscript.doChange = 1
end

return {
    engineHandlers = {
    },
    eventHandlers = {
        setGameTime = setGameTime,
    }
}
