local self = require("openmw.self")
local types = require("openmw.types")
local input = require("openmw.input")
local ui = require("openmw.ui")
local constant = require("mwse.mods.zackhasacat.ConsoleCheck.consolecheck_c")
local blockMode = constant.blockedMode
local gameJustStarted = true

--common
local GAMEVERSION = {
    openMW48 = "openMW48",
    openMWDev = "openMWDev",
    mwse = "mwse",
}
local function getGameVersion()
    --TODO: add correct numbers here
    if tes3 then
        return GAMEVERSION.mwse
    elseif types.Player.getBirthSign then
        return GAMEVERSION.openMWDev
    else
        return GAMEVERSION.openMW48
    end
end
local function isCharGenFinished()
    if not types.Player.isCharGenFinished then
        return true
    else
        return types.Player.isCharGenFinished(self)
    end
end
local function getPlayerName()
    if getGameVersion() == GAMEVERSION.mwse then
        if not tes3.mobilePlayer or not tes3.mobilePlayer.object then
            return
        end
        return tes3.mobilePlayer.object.name
    else
        return self.type.record(self).name
    end
end
local function getPlayerBirthSign()
    if getGameVersion() == GAMEVERSION.openMW48 then
        return nil
    elseif getGameVersion() == GAMEVERSION.openMWDev then
        return types.Player.getBirthSign(self)
    elseif getGameVersion() == GAMEVERSION.mwse then
        local sign = tes3.mobilePlayer.birthsign
        if sign then
            return sign.id
        else
            return ""
        end
    end
end

local function isTestChar()
    if getGameVersion() == GAMEVERSION.openMW48 then --0.48
        local playerName = getPlayerName()
        local playerChargenFinished = isCharGenFinished()
        if playerName == constant.defaultPlayerName and playerChargenFinished then
            --print("Player is named player")
            return true
        else
            return false
        end
    elseif getGameVersion() == GAMEVERSION.mwse then

        local playerName = getPlayerName()
        if playerName and playerName:lower() == constant.defaultPlayerName:lower() then
            return true
        else
            return false
        end
    else
        if getPlayerBirthSign() == "" and isCharGenFinished() then
            return true
        else
            return false
        end
    end
end
local function isConsoleBlocked()
    local playerName = getPlayerName()
    if not playerName then
        --print("No player record")
        return false
    elseif isTestChar() then
        --print("Player is named player")
        return false
    else
        --print("Player is not named player")
        return true
    end
end

--common end
local playerChargenFinished = false
local function printBlockMessage()
    for i = 1, 100, 1 do
        ui.printToConsole(" ", ui.CONSOLE_COLOR.Error)
    end

    ui.printToConsole(constant.message, ui.CONSOLE_COLOR.Success)
end

local function onInputAction(action)
    if action == input.ACTION.Console and isConsoleBlocked() then
        ui.setConsoleMode(blockMode)
        printBlockMessage()
    end
end

local function onLoad(isInit)
    if isConsoleBlocked() then
        ui.setConsoleMode(blockMode)
        printBlockMessage()
    end
    gameJustStarted = false
    local myName = self.type.record(self).name
    if types.Player.sendMenuEvent then
        types.Player.sendMenuEvent(self, "takePlayerName",
            { name = myName, chargenDone = types.Player.isCharGenFinished(self) })
    end
end
return {
    interfaceName = "ConsoleCheck",
    interface = {
        isConsoleBlocked = isConsoleBlocked
    },
    engineHandlers = {
        onLoad = onLoad,
        onInit = function()
            local myName = self.type.record(self).name
            if types.Player.sendMenuEvent then
                types.Player.sendMenuEvent(self, "takePlayerName",
                    { name = myName, chargenDone = types.Player.isCharGenFinished(self) })
            end
        end,
        onInputAction = onInputAction,
        onConsoleCommand = function(mode,command)
            if mode == blockMode and isConsoleBlocked() then
                ui.setConsoleSelectedObject()
                printBlockMessage()
            end
            if command == "reloadlua" then
                
            end
        end
    }
}
