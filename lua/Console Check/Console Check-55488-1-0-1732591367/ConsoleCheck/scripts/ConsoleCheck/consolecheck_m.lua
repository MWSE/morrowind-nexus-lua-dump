local input = require("openmw.input")
local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local menu = require("openmw.menu")
local constant = require("scripts.DebugMode.consolecheck_c")
local blockMode = constant.blockedMode
local function onKeyPress(k)
end

local playerName 
local playerChargenFinished = false
local function consoleIsBlocked()
    if menu.getState() == menu.STATE.NoGame then
        return false
    else
        if not playerName then
            --print("No player record")
            return false
        elseif playerName == constant.defaultPlayerName  and playerChargenFinished then
            --print("Player is named " .. constant)
            return false
        else
            --print("Player is not named player")
            return true
        end
    end
end
local function printBlockMessage()
   for i = 1, 100, 1 do
    
    ui.printToConsole(" ", ui.CONSOLE_COLOR.Error)
   end 

   ui.printToConsole("Use of the console is not currently allowed", ui.CONSOLE_COLOR.Error)
end

local function onInputAction(action)
    if action == input.ACTION.Console and consoleIsBlocked() then
        ui.setConsoleMode(blockMode)
        printBlockMessage()
    end
end

return {
    eventHandlers = {
        takePlayerName = function (data)
            playerChargenFinished = data.chargenDone
            playerName = data.name
        end
    },
    engineHandlers = {
        onKeyPress = onKeyPress,
        onInputAction = onInputAction,
        onConsoleCommand = function (mode)
            if mode == blockMode and consoleIsBlocked() then
                ui.setConsoleSelectedObject()	
                printBlockMessage()
            end
        end
    }
}