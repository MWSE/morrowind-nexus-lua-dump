local ui = require('openmw.ui')
local util = require('openmw.util')
local self = require('openmw.self')
local core = require('openmw.core')
local storage = require('openmw.storage')

local I = require("openmw.interfaces")

local constant = require("scripts.DebugMode.consolecheck_c")
local blockMode = constant.blockedMode


local function printHelp()
    local msg = [[
This is the not so built-in Lua interpreter.
help() - print this message
exit() - exit Lua mode
selected - currently selected object (click on any object to change)
view(_G) - print content of the table `_G` (current environment)
    standard libraries (math, string, etc.) are loaded by default but not visible in `_G`
view(types, 2) - print table `types` (i.e. `openmw.types`) and its subtables (2 - traversal depth)]]
    ui.printToConsole(msg, ui.CONSOLE_COLOR.Info)
end

local function printToConsole(...)
    local strs = {}
    for i = 1, select('#', ...) do
        strs[i] = tostring(select(i, ...))
    end
    return ui.printToConsole(table.concat(strs, '\t'), ui.CONSOLE_COLOR.Info)
end
local myMode = nil
local lastSelected = nil
local function runConsoleCommand(command)
    if I.ConsoleCheck and I.ConsoleCheck.isConsoleBlocked() then
        return
    end
    self:sendEvent("onConsoleCommandEvent", { cmd = command, mode = myMode, selectedObject = lastSelected })
end


local function setSelected(obj)
    lastSelected = obj
    local ok, err = pcall(function() ui.setConsoleSelectedObject(obj) end)
    if ok then
        ui.printToConsole('Selected object changed', ui.CONSOLE_COLOR.Success)
    else
        ui.printToConsole(err, ui.CONSOLE_COLOR.Error)
    end
end
local function distanceBetweenPos(vector1, vector2)
    --Quick way to find out the distance between two vectors.
    --Very similar to getdistance in mwscript
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local env = {
    I = require('openmw.interfaces'),
    util = require('openmw.util'),
    storage = require('openmw.storage'),
    core = require('openmw.core'),
    types = require('openmw.types'),
    async = require('openmw.async'),
    nearby = require('openmw.nearby'),
    self = require('openmw.self'),
    input = require('openmw.input'),
    ui = require('openmw.ui'),
    camera = require('openmw.camera'),
    aux_util = require('openmw_aux.util'),
    debug = require('openmw.debug'),
    view = require('openmw_aux.util').deepToString,
    print = printToConsole,
    runConsoleCommand = runConsoleCommand,
    rcc = runConsoleCommand,
    getdistance = distanceBetweenPos,
    exit = exitLuaMode,
    help = printHelp,
    zu = I.ZackUtilsGBuildMode,
    setSelected = setSelected
}

local playerSettings = storage.playerSection("SettingsDebugModePC")
local playerSettingsG = storage.playerSection("SettingsDebugModePCG")
env._G = env
setmetatable(env, { __index = _G, __metatable = false })
_G = nil

local function printRes(...)
    if select('#', ...) >= 0 then
        printToConsole(...)
    end
end

local currentSelf = nil
local currentMode = ''
local function executeLuaCode(code)
    local fn
    local ok, err = pcall(function() fn = util.loadCode('return ' .. code, env) end)
    if ok then
        ok, err = pcall(function() printRes(fn()) end)
    else
        ok, err = pcall(function() util.loadCode(code, env)() end)
    end
    if not ok then
        ui.printToConsole(err, ui.CONSOLE_COLOR.Error)
    end
end

local function exitLuaMode()
    currentSelf = nil
    currentMode = ''
    ui.setConsoleMode('')
    ui.printToConsole('Lua mode OFF', ui.CONSOLE_COLOR.Success)
end

local function setContext(obj)
    ui.printToConsole('Lua mode ON, use exit() to return, help() for more info, or help for command info',
        ui.CONSOLE_COLOR.Success)
    if obj ~= nil and obj.id == self.id then
        currentMode = 'Lua[Player]'
        ui.printToConsole('Context: Player', ui.CONSOLE_COLOR.Success)
        executeLuaCode("zu = require('openmw.interfaces').ZackUtils")
        for i = 1, 6, 1 do
            local settingVal = playerSettings:get("runLine" .. tostring(i))
            if (settingVal ~= "") then
                self:sendEvent("onConsoleCommandEvent", { mode = currentMode, cmd = settingVal, selectedObject = nil })
            end
        end
    elseif obj then
        if not obj:isValid() then error('Object not available') end
        currentMode = 'Lua[' .. obj.recordId .. ']'
        ui.printToConsole('Context: Local[' .. tostring(obj) .. ']', ui.CONSOLE_COLOR.Success)
    else
        currentMode = 'Lua[Global]'
        ui.printToConsole('Context: Global', ui.CONSOLE_COLOR.Success)
        core.sendGlobalEvent('OMWConsoleEval',
            { player = self.object, code = "zu = require('openmw.interfaces').ZackUtilsG", selected = nil })
        for i = 1, 6, 1 do
            local settingVal = playerSettingsG:get("runLine" .. tostring(i))
            if (settingVal ~= "") then
                self:sendEvent("onConsoleCommandEvent", { mode = currentMode, cmd = settingVal, selectedObject = nil })
            end
        end
    end
    currentSelf = obj
    ui.setConsoleMode(currentMode)
end




local function onConsoleCommand(mode, cmd, selectedObject)
    if I.ConsoleCheck and I.ConsoleCheck.isConsoleBlocked() then
        return
    end
    if mode == blockMode then
        return
    end
    myMode = mode
    lastSelected = selectedObject
    if (I.DebugMode ~= nil and I.DebugMode.checkCommand(cmd) == false) then
        return
    end
    env.selected = selectedObject
    if mode == '' then
        cmd, arg = cmd:lower():match('(%w+) *(%w*)')
        if cmd == 'lua' then
            if arg == 'player' then
                cmd = 'luap'
            elseif arg == 'global' then
                cmd = 'luag'
            elseif arg == 'selected' then
                cmd = 'luas'
            else
                local msg = [[
Usage: 'lua player' or 'luap' - enter player context
       'lua global' or 'luag' - enter global context
       'lua selected' or 'luas' - enter local context on the selected object]]
                ui.printToConsole(msg, ui.CONSOLE_COLOR.Info)
            end
        end
        if cmd == 'luap' or (cmd == 'luas' and selectedObject == self.object) then
            setContext(self)
        elseif cmd == 'luag' then
            setContext()
        elseif cmd == 'luas' then
            if selectedObject then
                core.sendGlobalEvent('OMWConsoleStartLocal', { player = self.object, selected = selectedObject })
            else
                ui.printToConsole('No selected object', ui.CONSOLE_COLOR.Error)
            end
        end
    elseif mode == currentMode then
        if (cmd == "luag" or cmd == "luas" or cmd == "luap") then
            return
        end
        if cmd == 'exit()' then
            exitLuaMode()
        elseif currentSelf ~= nil and currentSelf.id == self.id then
            executeLuaCode(cmd)
            if env.selected ~= selectedObject then setSelected(env.selected) end
        elseif currentSelf then
            currentSelf:sendEvent('OMWConsoleEval', { player = self.object, code = cmd, selected = selectedObject })
        else
            core.sendGlobalEvent('OMWConsoleEval', { player = self.object, code = cmd, selected = selectedObject })
        end
    end
end

local function onConsoleCommandEvent(data)
     if I.ConsoleCheck and I.ConsoleCheck.isConsoleBlocked() then
        return
    end
    if data.mode == blockMode then
        return
    end
    onConsoleCommand(data.mode, data.cmd, data.selectedObject)
end
return {
    engineHandlers = { onConsoleCommand = onConsoleCommand },
    eventHandlers = {
        OMWConsolePrint = function(msg) ui.printToConsole(tostring(msg), ui.CONSOLE_COLOR.Info) end,
        OMWConsoleError = function(msg) ui.printToConsole(tostring(msg), ui.CONSOLE_COLOR.Error) end,
        OMWConsoleSetContext = setContext,
        OMWConsoleSetSelected = setSelected,
        OMWConsoleExit = exitLuaMode,
        OMWConsoleHelp = printHelp,
        onConsoleCommandEvent = onConsoleCommandEvent,
        runConsoleCommandEvent = runConsoleCommand,
    }
}
