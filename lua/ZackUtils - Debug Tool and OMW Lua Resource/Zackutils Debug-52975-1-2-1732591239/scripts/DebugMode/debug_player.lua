local cam, camera, core, self, nearby, types, ui, util, storage, async, input,
zackUtils, debug = require('openmw.interfaces').Camera, require('openmw.camera'),
    require('openmw.core'), require('openmw.self'),
    require('openmw.nearby'), require('openmw.types'),
    require('openmw.ui'), require('openmw.util'),
    require("openmw.storage"), require("openmw.async"),
    require("openmw.input"),
    require("scripts.ZackUtils.PlayerInterface").interface,
    require("openmw.debug")

    local markRecall = require("scripts.DebugMode.data.markRecall")
local windows = require("scripts.DebugMode.data.windows")

local Blockconstant = require("scripts.DebugMode.consolecheck_c")
local blockMode = Blockconstant.blockedMode
local commandData = require("scripts.debugmode.data.commands").interface
local commandBindings = {}
local globalVariables
local addItem = zackUtils.addItem
local omwAddonvalid = core.contentFiles.has("debugmode.omwaddon")
local lastCommand = nil
local inFreecam = false
local time = require('openmw_aux.time')
local calendar = require('openmw_aux.calendar')
local selectedId = nil
if core.API_REVISION < 41 then
    error("ZackUtils reports that the Game engine must be updated!")
end
local selectedActor = nil
local currentContextOb = nil

local storedCommand = nil

local tgm = false
local tcl = false

local zu

local I = require("openmw.interfaces")

local time = require('openmw_aux.time')

local outcommands = {
    "charsheet",
    "setpos", "getpos", "fixme", "setdelete", "disable", "enable", "kill",
    "killall", "feather", "killcreas", "dropall", "reloadlua", "findnamed",
    "help", "tgm", "coc", "compshare", "ex", "rlua", "additem", "addequip",
    "takeall", "seeall", "resurrect", "addspell","removespell", "lock", "unlock", "unlockall",
    "clearowner", "clearallowners", "placeatme", "placeatpc", "placeattarget",
    "fly", "exgame", "exitgame", "tcl", "setsun", "select", "prid", "moveto",
    "movetoid", "setgametime", "sethour", "SetPCCrimeLevel", "getpccrimelevel", "findrecord",
    "find", "findcell", "clearinv", "freecam", "findslavers", "buff", "psb", "ori",
    "getsimspeed", "setsimspeed", "purge", "tfc", "showdisabled", "playsound", "blacklist",
    "findsound", "setcampos", "resetcampos", "gotocampos", "gcp", "rcp", "scp", "getangle", "setangle", "getscale",
    "setscale", "travel", "trv", "ra", "shippos", "setpccrimelevel", "crimelevel", "buildairship", "buildship", "tfh",
    "togglefogofwar", "stealcell", "findnpc", "enableracemenu", "listitems", "journal", "setjournalindex",
    "getjournalindex", "set", "showvars", "toggleai", "tai", "tcb", "togglecollisionboxes", "togglescripts", "tscr",
    "togglepathgrid", "tpg", "togglenavmesh", "tnm", "addsoulgem","setdisposition", "enableplayercontrols", "music",
    "mark","recall","learnplayerspells"
}
local function WriteToConsole(text, error)
    if not core.isWorldPaused() then
        ui.showMessage(text)
    end
    if error == true then
        ui.printToConsole(text, ui.CONSOLE_COLOR.Error)
        return
    end
    ui.printToConsole(text, ui.CONSOLE_COLOR.Info)
end
local function WriteToConsoleEvent(data)
    WriteToConsole(data.text, data.error)
end
local function errorIfNoCF()
    if omwAddonvalid then return end
    local errorMessage = "Content file debugmode.omwaddon is missing! This command cannot be used without it."
    WriteToConsole(errorMessage, true)
    error(errorMessage)
end
local gameStarted = false
local playerSettings = storage.playerSection("SettingsDebugMode")
local safeGuardTriggered = false
local function safeGuard()
    if (playerSettings:get("EnableSafeguard") == false) then return end
    if safeGuardTriggered then
        error("safeguard")
    end
    if self.cell.name == "Imperial Prison Ship" then
        local errorM = string.format(
            "Safeguard attempted to prevent damage to real save, player is in starting prison ship"
        )
        safeGuardTriggered = true
        WriteToConsole(errorM, true)
        error(errorM)
        return false
    end
    -- This function attemps to prevent execution of commands that will permenently damage a world.
    local gt = core.getGameTime()
    local days = gt / time.day

    local playerName = types.NPC.record(self).name

    if string.sub(types.NPC.record(self).name:lower(), 1, 6) ~= "player" then
        local errorM = string.format(
            "Safeguard attempted to prevent damage to real save, player name does not start with player, but is %s",
            playerName)
        safeGuardTriggered = true
        WriteToConsole(errorM, true)
        error(errorM)
        return false
    end

    if (days > 7) then
        local errorM = string.format(
            "Safeguard attempted to prevent damage to real save, dayspassed is %i",
            days)
        safeGuardTriggered = true
        WriteToConsole(errorM, true)
        error(errorM)
        return false
    else
        print(days, " passed")
    end

    return true
end

local function setPosFunctions()
    core.sendGlobalEvent("setSetting", {
        key = "defaultCell",
        value = self.cell.name,
        player = self
    })
    core.sendGlobalEvent("setSetting", {
        key = "defaultPos",
        value = self.position.x .. "," .. self.position.y .. "," ..
            self.position.z,
        player = self
    })
end
playerSettings:subscribe(async:callback(function(section, key)
    if key then
        if (key == "setPos") then
            print(self.cell.name)
            setPosFunctions()
        elseif (key == "defaultPos" or key == "defaultCell") then
        elseif key == "EnableMusic" then
            local state = playerSettings:get(key)
            self:sendEvent("SetMusicState",state)
          --  print("music",state)
          print("Music state changed")
        else
            print('Value is changed:', key, '=', playerSettings:get(key))
            core.sendGlobalEvent("setSetting", {
                key = key,
                value = playerSettings:get(key),
                player = self
            })
        end
    end
end))
local function contains(tableb, value)
    for _, v in ipairs(tableb) do if v == value then return true end end
    return false
end
local function removeQuotes(str)
    if (str == nil) then
        return nil
    end
    local result = string.gsub(str, "[\"]", "")
    return result
end

local function onMessageSent(eventData) ui.showMessage(eventData) end
local function onMessageSent(eventData) ui.showMessage(eventData) end
local myMode = nil
local freeCam = false
local tempPlayer = nil

local function ReturnActorSwap(actor) tempPlayer = actor end
local selectedItem
local function removeFirstWordAndSpace(inputString)
    local _, _, remainingString = inputString:find("^%s*%w+%s*(.*)")
    return remainingString
end
local function splitString(inputString)
    local result = {}
    local currentItem = ""
    local insideQuotes = false

    for i = 1, #inputString do
        local char = inputString:sub(i, i)

        if char == "'" or char == '"' then
            insideQuotes = not insideQuotes
            currentItem = currentItem .. char
        elseif char == " " and not insideQuotes then
            if currentItem ~= "" then
                table.insert(result, currentItem)
                currentItem = ""
            end
        else
            currentItem = currentItem .. char
        end
    end

    if currentItem ~= "" then table.insert(result, currentItem) end

    -- Check if the last item is a number and remove it along with the space in front
    local lastItem = result[#result]
    local lastItemNumber = tonumber(lastItem)
    local wholeStringMinusLastNumber = inputString
    if lastItemNumber then
        table.remove(result)
        wholeStringMinusLastNumber = inputString:sub(1,
            #inputString - #lastItem -
            1)
    end

    return result, lastItemNumber, removeFirstWordAndSpace(wholeStringMinusLastNumber)
end

local function padStrings(strings)
    -- Find the maximum length among all strings
    local maxLength = 0
    for _, str in ipairs(strings) do maxLength = math.max(maxLength, #str) end

    -- Pad each string with spaces to match the maximum length
    local paddedStrings = {}
    for _, str in ipairs(strings) do
        local padding = string.rep(" ", maxLength - #str)
        local paddedStr = str .. padding
        table.insert(paddedStrings, paddedStr)
    end

    return paddedStrings
end

local function splitStringWithInfo(str)
    local parts = {}
    local moreInfo = ""

    str = str:gsub(";", ",")

    local dotCount = select(2, str:gsub("%.", "", 1))

    for part in str:gmatch("[^.]+") do table.insert(parts, part) end

    if dotCount > 1 or parts[2] then
        moreInfo = parts[1] .. "." .. " (More Info Available)"
    else
        moreInfo = parts[1]
    end

    return parts, moreInfo
end

local function stringInList(str, list)
    local stringList = {}
    for word in list:gmatch("[^;]+") do table.insert(stringList, word) end

    for _, word in ipairs(stringList) do if str == word then return true end end

    return false
end

local lastSelected = nil
local savedCamData = {}
local origPos = nil
local origCell = nil
local function onConsoleCommand(mode, command, selectedObject)
    if I.ConsoleCheck and I.ConsoleCheck.isConsoleBlocked() then
        return
    end
    if mode == blockMode then
        return
    end
    if (zu == nil) then zu = I.ZackUtils end
    lastCommand = command
    local words = {}
    local numVal = -1
    local noNumStr
    lastSelected = selectedObject
    myMode = mode
    if (mode ~= "") then
        if command == 'luap' or
            (command == 'luas' and selectedObject == self.object) then
            self:sendEvent("OMWConsoleSetContext", self)
            return
        elseif command == 'luag' then
            self:sendEvent("OMWConsoleSetContext")
            return
        elseif command == 'luas' then
            currentContextOb = selectedObject.id
            if selectedObject then
                core.sendGlobalEvent('OMWConsoleStartLocal', {
                    player = self.object,
                    selected = selectedObject
                })
            else
                ui.printToConsole('No selected object', ui.CONSOLE_COLOR.Error)
            end
            return
        end
    end
    for word in command:gmatch("%S+") do table.insert(words, word) end
    words, numVal, noNumStr = splitString(command)
    local myTarget = selectedObject
    if (myTarget == nil) then
        myTarget = self
        selectedId = nil
    else
        selectedId = selectedObject.id
    end
    if (command == "luap" or command == "luas" or command == "luag") then
        storedCommand = command
    end
    local lowerCmd = words[1]:lower()
    for cmd, win in pairs(windows) do
        if lowerCmd == cmd then
            I.UI.setMode(win)
            return
        end
    end

    for index, value in ipairs(outcommands) do
        local restOf = string.sub(command, string.len(words[1]) + 2) -- this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it.
        local sanitizedStr = ""
        if (restOf ~= nil) then
            sanitizedStr = removeQuotes(restOf)
        end
        if (words[1]:lower() == value or words[1]:lower() == "lua" .. value) then
            if (value == "reloadlua" or value == "rlua") then
                if debug.reloadLua ~= nil then
                    debug.reloadLua()
                else
                    errorIfNoCF()
                    core.sendGlobalEvent("mwScriptBridge2", {
                        cmdId = 3
                    })
                end
            elseif value == "set" then
                local variableName = words[2]
                local variableValue = numVal
                core.sendGlobalEvent("setGlobalVarValue", { valueName = variableName, valueNum = variableValue })
            elseif (value == "tcl") then
                local currentVal = not debug.isCollisionEnabled()
                debug.toggleCollision()
                WriteToConsole("Player Collision -> " .. (currentVal and "On" or "Off"))
            elseif (value == "stealcell" and not words[2]) then
                core.sendGlobalEvent("stealCell", self.cell.name)
            elseif (value == "stealcell") then
                core.sendGlobalEvent("stealCell")
            elseif value == "exitgame" or value == "exgame" then
                WriteToConsole("Closing the game.")
                core.quit()
            elseif commandBindings[value:lower()] ~= nil then
                local outline, error = commandBindings[value:lower()](command)
                if outline and not error then
                    ui.printToConsole(
                        outline,
                        ui.CONSOLE_COLOR.Success)
                elseif outline and error then
                    ui.printToConsole(
                        outline,
                        ui.CONSOLE_COLOR.Error)
                end
            elseif value == "blacklist" then
                core.sendGlobalEvent("BlacklistAdd", selectedObject)
            elseif value == "help" and command == value then
                local firstPart = {}
                for index, value in ipairs(commandData.objectTypes) do
                    table.insert(firstPart, value.Command_Name)
                end
                firstPart = padStrings(firstPart)
                for index, value in ipairs(commandData.objectTypes) do
                    local desc = value.Description
                    local nonneeded, info = splitStringWithInfo(desc)
                    WriteToConsole(firstPart[index] .. ":" .. info)
                end
                ui.printToConsole(
                    "Help for available commands listed above. If it says 'more info available', then you can do the command 'help command' where command is the name of the command you need more info on",
                    ui.CONSOLE_COLOR.Success)
            elseif value == "help" and restOf ~= "" then
                local firstPart = {}
                local found = false
                for index, value in ipairs(commandData.objectTypes) do
                    if (stringInList(restOf, value.Command_Name)) then
                        local lines, info =
                            splitStringWithInfo(value.Description)
                        for index, line in ipairs(lines) do
                            WriteToConsole(line)
                        end
                        found = true
                    end
                end
                if (found == false) then
                    WriteToConsole(
                        "No help info for specified command. Type help for list of possible commands you can get info on.",
                        true)
                end
            elseif (value == "ex") then
                --   ui.printToConsole('Lua mode OFF', ui.CONSOLE_COLOR.Success)
                self:sendEvent("OMWConsoleExit")
            elseif value == "dropall" then
                core.sendGlobalEvent("dropAll", selectedActor)
            elseif value == "ra" then
                core.sendGlobalEvent("Debug_RAEvent", true)
            elseif value == "listitems" then
                local listedItems = {}
                for index, value in ipairs(nearby.items) do
                    if not listedItems[value.recordId] then
                        WriteToConsole(value.recordId, false)
                    end
                    listedItems[value.recordId] = true
                end
                for index, cont in ipairs(nearby.containers) do
                    for index, item in ipairs(types.Container.inventory(cont):getAll()) do
                        if not listedItems[item.recordId] then
                            WriteToConsole(item.recordId, false)
                        end
                        listedItems[item.recordId] = true
                    end
                end
            elseif (value == "coc") then
                local key = restOf 
                if key == "" or key == " " or not key then
                else
                    local recallMe = markRecall.isValidLocation(key)
                    if recallMe then
                            
                        local result = markRecall.runRecall(key)
                        WriteToConsole(result)
                        return
                    end
                end
                local stringBuild = words[2]
                for index, value in ipairs(words) do
                    if (index > 2) then
                        stringBuild = stringBuild .. " " .. value
                    end
                end

                core.sendGlobalEvent("COCEvent", {
                    objectToTeleport = self,
                    cellname = removeQuotes(stringBuild),
                    number = numVal
                })
            elseif (value == "travel" or value == "trv") then
                local stringBuild = words[2]
                for index, value in ipairs(words) do
                    if (index > 2) then
                        stringBuild = stringBuild .. " " .. value
                    end
                end

                core.sendGlobalEvent("TravelEvent", {
                    objectToTeleport = self,
                    cellname = removeQuotes(stringBuild),
                    number = numVal
                })
            elseif (value == "findcell") then
                core.sendGlobalEvent("COCEvent", {
                    objectToTeleport = self,
                    cellname = removeQuotes(restOf),
                    printOnly = true
                })
            elseif value == "journal" then
                local questId = words[2]
                local stage = numVal
                if not questId then
                    WriteToConsole("No quest ID provided", true)
                elseif not stage then
                    WriteToConsole("No stage provided")
                else
                    local questData = types.Player.quests(self)[questId]
                    if not questData then
                        WriteToConsole("No quest with ID " .. questId)
                    else
                        local success, result = pcall(function()
                            questData:addJournalEntry(stage, self)
                        end)
                        if success then
                            print(result)
                            WriteToConsole("Added journal entry for  " .. questId .. " at " .. tostring(stage))
                        else
                            WriteToConsole(
                                "No journal entry detected for quest " .. questId .. " at " .. tostring(stage), true)
                        end
                    end
                end
            elseif value == "music" then
                local state = restOf
                local setTo = false
                if state == nil or state == "" or state == " " then
                    setTo = not playerSettings:get("EnableMusic")
                elseif state == "on" then
                    setTo = true
                elseif state == "off" then
                    setTo = false
                end
                playerSettings:set("EnableMusic",setTo)
            elseif value == "setjournalindex" then
                local questId = words[2]
                local stage = numVal
                if not questId then
                    WriteToConsole("No quest ID provided", true)
                elseif not stage then
                    WriteToConsole("No stage provided", true)
                else
                    local questData = types.Player.quests(self)[questId]
                    if not questData then
                        WriteToConsole("No quest with ID " .. questId, true)
                    else
                        local success, result = pcall(function()
                            questData.stage = stage
                        end)
                        if success then
                            print(result)
                            WriteToConsole("Set quest " .. questId .. " to " .. tostring(stage))
                        else
                            WriteToConsole("Failure: " .. questId .. " at " .. tostring(stage), true)
                        end
                    end
                end
            elseif value == "getjournalindex" then
                local questId = words[2]
                if not questId then
                    WriteToConsole("No quest ID provided", true)
                else
                    local questData = types.Player.quests(self)[questId]
                    if not questData then
                        WriteToConsole("No quest with ID " .. questId, true)
                    else
                        WriteToConsole("Quest ID " .. questId .. " is at " .. questData.stage)
                    end
                end
            elseif (value == "showdisabled") then
                core.sendGlobalEvent("showDisabled")
            elseif value == "compshare" then

                if (selectedObject.type == types.NPC) or selectedObject.type == types.Creature then
                   I.UI.setMode(I.UI.MODE.Companion,{target = selectedObject})
                else
                    WriteToConsole("Invalid object selected", true)
                end
            elseif (value == "killall") then
                safeGuard()
                core.sendGlobalEvent("killAll")
            elseif value == "kill" then
                if (selectedObject ~= nil and selectedObject.type == types.NPC or
                        selectedObject.type == types.Creature) then
                    selectedObject:sendEvent("setStat",
                        { type = "health", value = 0 })
                    WriteToConsole("Killed " .. selectedObject.recordId)
                else
                    WriteToConsole("Invalid selection", true)
                end
            elseif value == "charsheet" then

            elseif (value == "moveto") then
                safeGuard()
                core.sendGlobalEvent("moveToActorEvent", {
                    objectToTeleport = myTarget,
                    targetName = removeQuotes(restOf:lower())
                })
            elseif (value == "select" or value == "prid") then
                safeGuard()
                core.sendGlobalEvent("moveToActorEvent", {
                    objectToTeleport = self,
                    targetName = restOf:lower(),
                    justReturn = true
                })
            elseif value == "getscale" then
                local scale = selectedObject.scale
                WriteToConsole("Scale: " .. tostring(scale))
            elseif value == "setscale" then
                core.sendGlobalEvent("setObjScale", { object = selectedObject, scale = numVal })
            elseif value == "setcampos" or value == "scp" then
                local camPos = restOf
                if camPos == nil or camPos == "" then
                    WriteToConsole("You must provide a position string", true)
                    return
                end
                local cameraPos = camera.getPosition()
                for i, value in ipairs(savedCamData) do
                    if (value.posName:lower() == camPos:lower()) then
                        table.remove(savedCamData, i)
                    end
                end
                table.insert(savedCamData, {
                    posName = camPos,
                    pos = cameraPos,
                    pitch = camera.getPitch(),
                    roll = camera.getRoll(),
                    yaw = camera.getYaw(),
                    cell = self.cell.name
                })
                WriteToConsole("Saved camera data for " .. camPos)
            elseif value == "resetcampos" or value == "rcp" then
                zu.teleportItemToCell(self, origCell, origPos)
                camera.setMode(camera.MODE.FirstPerson)
            elseif value == "gotocampos" or value == "gcp" then
                if restOf == nil or restOf == "" then
                    WriteToConsole("You must provide a position string", true)
                    return
                end
                for index, camData in ipairs(savedCamData) do
                    if (camData.posName:lower() == restOf:lower()) then
                        if (camera.getMode() ~= camera.MODE.Static) then
                            origCell = self.cell.name
                            origPos = self.position
                        end
                        if (self.cell.name ~= camData.cell) then
                            zu.teleportItemToCell(self, camData.cell,
                                util.vector3(
                                    camData.pos.x,
                                    camData.pos.y, 0))
                        end
                        camera.setMode(camera.MODE.Static)
                        camera.setStaticPosition(camData.pos)
                        camera.setRoll(camData.roll)
                        camera.setPitch(camData.pitch)
                        camera.setYaw(camData.yaw)
                        WriteToConsole("Moved to cam pos " .. camData.posName)
                    end
                end
            elseif (value == "seeall") then
                safeGuard()
                --   if(words[2] == "clothing") then
                core.sendGlobalEvent("createContainerFilledWithType", words[2])
            elseif (value == "addspell") then
                local info = zu.addSpell(restOf)
                zu.printToConsole(info)
            elseif (value == "removespell") then
                local info = zu.removeSpell(restOf)
                zu.printToConsole(info)
            elseif value == "showvars" then
                local targ = myTarget
                if targ == self then
                    targ = nil
                end
                core.sendGlobalEvent("showVars", targ)
            elseif value == "crimelevel" or value == "setpccrimelevel" then
                local lvl = numVal
                if not lvl then
                    local val = types.Player.getCrimeLevel(self)
                    WriteToConsole("Player crime level is " .. tostring(val))
                else
                    errorIfNoCF()
                    core.sendGlobalEvent("mwScriptBridge2", { cmdId = 2, valNum = numVal })
                    WriteToConsole("Setting Player crime level to " .. tostring(numVal))
                end
            elseif value == "getpccrimelevel" then
                local val = types.Player.getCrimeLevel(self)
                WriteToConsole("Player crime level is " .. tostring(val))
            elseif value == "tfh" then
                errorIfNoCF()
                core.sendGlobalEvent("mwScriptBridge2", { cmdId = 1, valNum = numVal })
                WriteToConsole("Toggling Full Help Mode ")
            elseif value == "togglefogofwar" then
                errorIfNoCF()
                core.sendGlobalEvent("mwScriptBridge2", { cmdId = 6, valNum = numVal })
                WriteToConsole("Toggling Fog Of War ")
            elseif value == "toggleai" or value == "tai" then
                debug.toggleAI()
                if debug.isAIEnabled() then
                    WriteToConsole("AI -> On")
                else
                    WriteToConsole("AI -> Off")
                end
            elseif value == "togglescripts" or value == "tscr" then
                debug.toggleMWScript()
                if debug.isMWScriptEnabled() then
                    WriteToConsole("Scripts -> On")
                else
                    WriteToConsole("Scripts -> Off")
                end
            elseif value == "tcb" or value == "togglecollisionboxes" then
                debug.toggleRenderMode(debug.RENDER_MODE.CollisionDebug)
                WriteToConsole("Toggled Collision Boxes")
            elseif value == "mark" then
                local key = restOf 
                if key == "" or key == " " or not key then
                    WriteToConsole("No key specified!",true)
                else
                    local result = markRecall.saveLocation(key)
                    WriteToConsole("Key: \"" .. key .. "\"")
                end
            elseif value == "recall" then
                local key = restOf 
                if key == "" or key == " " or not key then
                    WriteToConsole("No key specified!",true)
                else
                    local result = markRecall.runRecall(key)
                    WriteToConsole(result)
                    WriteToConsole("Key: \"" .. key .. "\"")
                end
            elseif value == "tpg" or value == "togglepathgrid" then
                debug.toggleRenderMode(debug.RENDER_MODE.Pathgrid)
                WriteToConsole("Toggled Pathgrid")
            elseif value == "tnm" or value == "togglenavmesh" then
                debug.toggleRenderMode(debug.RENDER_MODE.NavMesh)
                WriteToConsole("Toggled Navmesh")
            elseif value == "disable" or value == "enable" then
                local setTo = value == "enable"
                core.sendGlobalEvent("setDisabled",
                    { object = selectedObject, state = setTo })
                WriteToConsole(value .. "d " .. selectedObject.recordId)
            elseif value == "placeatpc" then
                local count = numVal or 1
                for i = 1, count, 1 do
                    I.ZackUtils.createItem(removeQuotes(noNumStr), self.cell,
                        self.position)
                end
            elseif value == "placeattarget" then
                local look = I.ZackUtils.getObjInCrosshairs(self, 10000).hitPos
                local target = self.position
                look = util.vector3(look.x, look.y, look.z + 100)
                if (look == nil) then
                    WriteToConsole("No point to place at!", true)
                else
                    I.ZackUtils.createItem(sanitizedStr, self.cell, look,
                        util.vector3(0, 0, self.rotation.z))
                end
            elseif value == "placeatme" then
                I.ZackUtils.createItem(sanitizedStr, myTarget.cell,
                    myTarget.position, myTarget.rotation)
            elseif value == "getpos" then
                local axis = words[2]
                if axis == "x" then
                    WriteToConsole("X Position: " ..
                        tostring(myTarget.position.x))
                elseif axis == "y" then
                    WriteToConsole("Y Position: " ..
                        tostring(myTarget.position.y))
                elseif axis == "z" then
                    WriteToConsole("Z Position: " ..
                        tostring(myTarget.position.z))
                end
            elseif value == "getangle" then
                local axis = words[2]
                if axis == "x" then
                    WriteToConsole("X Rotation: " ..
                        tostring(math.deg(myTarget.rotation.x)))
                elseif axis == "y" then
                    WriteToConsole("Y Rotation: " ..
                        tostring(math.deg(myTarget.rotation.y)))
                elseif axis == "z" then
                    WriteToConsole("Z Rotation: " ..
                        tostring(math.deg(myTarget.rotation.z)))
                end
            elseif value == "setangle" then
                local axis = numVal
                if (numVal == -1) then
                    WriteToConsole("No number provided!", true)
                    return
                end
                local num = math.rad(numVal)
                if axis == "x" then
                    I.ZackUtils.teleportItemToCell(myTarget.cell, myTarget.position,
                        util.vector3(num, myTarget.rotation.y, myTarget.rotation.z))
                elseif axis == "y" then
                    I.ZackUtils.teleportItemToCell(myTarget.cell, myTarget.position,
                        util.vector3(myTarget.rotation.x, num, myTarget.rotation.z))
                elseif axis == "z" then
                    I.ZackUtils.teleportItemToCell(myTarget.cell, myTarget.position,
                        util.vector3(myTarget.rotation.x, myTarget.rotation.y, num))
                end
            elseif (value == "setdelete" and selectedObject and selectedObject ~=
                    self) then
                I.ZackUtils.deleteItem(selectedObject)
            elseif value == "enableplayercontrols" then
                types.Player.setControlSwitch(self,types.Player.CONTROL_SWITCH.Controls,true)
                if restOf == "all" then
                    types.Player.setControlSwitch(self,types.Player.CONTROL_SWITCH.Controls,true)
                for index, value in pairs(types.Player.CONTROL_SWITCH) do
                    types.Player.setControlSwitch(self,value,true)
               
                end
                end
            elseif value == "learnplayerspells" then
       local spellList = {}
       local spells = types.Actor.spells(self)
       local count = 0
       for index, spell in ipairs(spells) do
           if spell.type == core.magic.SPELL_TYPE.Power or spell.type == core.magic.SPELL_TYPE.Spell then
            table.insert(spellList,spell.id)
            count = count + 1
           end
       end
       selectedObject:sendEvent("learnplayerspells",spellList)
            elseif value == "psb" then
                safeGuard()
                local spellcount = 0
                for index, value in ipairs(core.magic.spells.records) do
                    if (value.type == core.magic.SPELL_TYPE.Spell) then
                        types.Actor.spells(self):add(value)
                        spellcount = spellcount + 1
                    end
                end
                WriteToConsole("Added " .. tostring(spellcount) ..
                    " spells to player")
            elseif value == "setpos" then
                local axis = words[2]
                local pos = tonumber(words[3])
                core.sendGlobalEvent("setPos",
                    { actor = myTarget, axis = axis, pos = pos })
            elseif (value == "fly") then
                local hasSpell = zu.hasSpell("zhac_debug_fly")

                if (hasSpell) then
                    zu.removeSpell("zhac_debug_fly")
                    zu.printToConsole("Disabled Fly Mode")
                else
                    zu.addSpell("zhac_debug_fly", ui.CONSOLE_COLOR.Success)
                    zu.printToConsole("Enabled Fly Mode",
                        ui.CONSOLE_COLOR.Success)
                end
            elseif (value == "feather") then
                local spellName = "zhac_debug_feather"
                local hasSpell = zu.hasSpell(spellName)

                if (hasSpell) then
                    zu.removeSpell(spellName)
                    zu.printToConsole("Disabled Feather Ability")
                else
                    zu.addSpell(spellName, ui.CONSOLE_COLOR.Success)
                    zu.printToConsole("Enabled Feather Ability",
                        ui.CONSOLE_COLOR.Success)
                end
            elseif value == "find" then
                local recordId = sanitizedStr
                core.sendGlobalEvent("findAllRefs", recordId)
            elseif value == "findnpc" then
                local recordId = sanitizedStr
                core.sendGlobalEvent("findNPCbyId", recordId)
            elseif value == "movetoid" then
                local unid = sanitizedStr
                core.sendGlobalEvent("moveToId", unid)
            elseif value == "findrecord" then
                core.sendGlobalEvent("findRecordByName", restOf)
            elseif value == "setgametime" then
                safeGuard()
                errorIfNoCF()
                local newTime = tonumber(words[2])
                core.sendGlobalEvent("mwScriptBridge2", {
                    cmdId  = 5,
                    valNum = newTime,
                })
            elseif value == "setsimspeed" then

            elseif value == "getsimspeed" then

            elseif value == "purge" then
                safeGuard()
                core.sendGlobalEvent("purgeMod", restOf)
            elseif value == "sethour" then
                safeGuard()
                errorIfNoCF()
                local fnewTime = numVal
                local newDaysPassed = math.floor(core.getGameTime() / time.day)
                local newTime = newDaysPassed * time.day +
                    (fnewTime * time.hour)
                core.sendGlobalEvent("mwScriptBridge2", {
                    cmdId  = 5,
                    valNum = newTime,
                })
            elseif value == "freecam" and true == false then
                safeGuard()
                if (freeCam == false) then
                    I.ZackUtils.teleportItemToCell(self, self.cell.name,
                        util.vector3(self.position.x,
                            self.position.y,
                            self.position.z +
                            100))

                    -- camera.setMode(camera.MODE.Static)
                    input.setControlSwitch(input.CONTROL_SWITCH.ViewMode, false)
                    zu.addSpell("zhac_debug_fly")
                    core.sendGlobalEvent("DebugActorSwap", {
                        currentActor = self.id,
                        newActorId = self.recordId,
                        doClone = true
                    })
                    freeCam = true
                else
                    zu.removeSpell("zhac_debug_fly")
                    input.setControlSwitch(input.CONTROL_SWITCH.ViewMode, true)
                    tempPlayer = nil
                    freeCam = false
                end
            elseif (value == "resurrect") then
                if (types.Actor.stats.dynamic.health(self).current == 0) then
                    errorIfNoCF()
                    core.sendGlobalEvent("mwScriptBridge2NoVal", 4)
                else
                    if (selectedObject.id == self.id or selectedObject == nil) then
                        errorIfNoCF()
                        core.sendGlobalEvent("mwScriptBridge2NoVal", 4)
                    else
                        core.sendGlobalEvent("DebugActorSwap", {
                            currentActor = selectedObject.id,
                            newActorId = selectedObject.recordId
                        })
                    end
                end
            elseif (value == "killcreas") then
                core.sendGlobalEvent("killAll", { filterType = "Creature" })
            elseif (value == "tgm") then
                local currentVal = not debug.isGodMode()
                debug.toggleGodMode()
                WriteToConsole("God Mode -> " .. (currentVal and "On" or "Off"))
                return
            elseif value == "buff" then
                -- buff a bunch of stats
                for index, skill in pairs(core.SKILL) do
                    if (value == "set" .. skill) then
                        local num = (100000)
                        if (myTarget.type == self.type) then
                            types.NPC.stats.skills[skill](self).base = num
                            local val = types.NPC.stats.skills[skill](myTarget)
                                .modified
                            print(val)
                            WriteToConsole(skill .. ": " .. tostring(val))
                        end
                    end
                end
            elseif value == "debuff" then
                -- buff a bunch of stats
                for index, skill in pairs(types.NPC.stats.skills) do
                    types.NPC.stats.skills[index](self).base = 1
                end
                for index, attr in pairs(types.Actor.stats.attributes) do
                    types.Actor.stats.attributes[index](self).base = 1
                end
            elseif (value == "resurrect") then
                if (selectedObject.id == self.id) then
                    errorIfNoCF()
                    core.sendGlobalEvent("mwScriptBridge2NoVal", 4)
                else
                    core.sendGlobalEvent("DebugActorSwap", {
                        currentActor = selectedObject.id,
                        newActorId = selectedObject.recordId
                    })
                end
            elseif (value == "killcreas") then
                core.sendGlobalEvent("killAll", { filterType = "Creature" })
            elseif value == "ori" then

                --TODO: Make MWscript bridge for this
                if selectedObject == nil then
                    WriteToConsole("Error: no implicit reference")
                    return
                end

                local lines = {}
                local RefNum, fileNum = string.match(selectedObject.id, "(%d+)_(%d+)")
                local contentFile = selectedObject.contentFile
                local cell = selectedObject.cell.name
                local coordinates = tostring(selectedObject.position.x) ..
                    " " .. tostring(selectedObject.position.y) .. " " .. tostring(selectedObject.position.z)
                local model = ""
                if selectedObject.type.record(selectedObject).model ~= nil then
                    model = selectedObject.type.record(selectedObject).model
                end
                local idNumber = selectedObject.id--tonumber(string.match(selectedObject.id, "^(.-)_"))
                if idNumber:sub(1, 1) == "@" then
                    -- Remove the '@' and convert the rest to a number
                    local hex_part = idNumber:sub(2)
                    idNumber = tonumber(hex_part, 16) -- Convert from hex to decimal
                end
                idNumber = idNumber % 0x10000
                -- Add each line to the 'lines' table
                table.insert(lines, "Report time: " .. os.date("!%Y.%m.%d %H:%M:%S UTC"))
                table.insert(lines, "RefNum: " .. tostring(idNumber))
                if (selectedObject.contentFile) then

                    table.insert(lines, "Content file: " ..tostring( fileNum) .. " [" .. contentFile .. "]")
                    --`local str = core.getFormId(selectedObject.contentFile, idNumber):gsub('FormId:"', ''):gsub('"', '')
                    table.insert(lines, "FormID: \"" .. selectedObject.id .. "\"")
                end
                table.insert(lines, "RefID: \"" .. selectedObject.recordId .. "\"")

                table.insert(lines, "Cell: " .. cell)
                table.insert(lines, "Coordinates: " .. coordinates)
                table.insert(lines, "Model: " .. model)
                if (selectedObject.scale ~= 1) then
                    table.insert(lines, "Scale: " .. selectedObject.scale)
                end
                if (selectedObject.type.record(selectedObject).mwscript ~= nil) then
                    table.insert(lines, "Script: \"" .. selectedObject.type.record(selectedObject).mwscript .. "\"")
                end
                -- Output the 'lines' table
                for i, line in ipairs(lines) do
                    ui.printToConsole(line, ui.CONSOLE_COLOR.Success)
                end
            elseif value == "doabigbuff" then
                -- buff a bunch of stats
                for index, skill in pairs(core.SKILL) do
                    if (value == "set" .. skill) then
                        local num = (100000)
                        if (myTarget.type == self.type) then
                            types.NPC.stats.skills[skill](self).base = num
                            local val = types.NPC.stats.skills[skill](myTarget)
                                .modified
                            print(val)
                            WriteToConsole(skill .. ": " .. tostring(val))
                        end
                    end
                end
            elseif (value == "fixme") then
            elseif value == "clearowner" then
                if (selectedObject ~= nil and
                        (selectedObject.owner.recordId ~= nil or
                            selectedObject.owner.factionId ~= nil)) then
                    if (selectedObject.owner.recordId ~= nil) then
                        core.sendGlobalEvent("setOwner",
                            { object = selectedObject })
                        WriteToConsole("Removed owner " ..
                            selectedObject.owner.recordId)
                    end
                    if (selectedObject.owner.factionId ~= nil) then
                        core.sendGlobalEvent("setOwnerFaction",
                            { object = selectedObject })
                        WriteToConsole("Removed owner faction" ..
                            selectedObject.owner.factionId)
                    end
                elseif (selectedObject == nil) then
                    WriteToConsole("No selected item.", true)
                elseif (selectedObject.owner.recordId == nil) then
                    WriteToConsole("No owner to remove.", true)
                end
            elseif value == "clearallowners" then
                safeGuard()
                local ownerRemoved = 0
                for index, value in ipairs(nearby.items) do
                    if (value.owner.recordId ~= nil or value.owner.factionId ~=
                            nil) then
                        ownerRemoved = ownerRemoved + 1
                        core.sendGlobalEvent("setOwner", { object = value })
                        core.sendGlobalEvent("setOwnerFaction", { object = value })
                    end
                end
                for index, value in ipairs(nearby.containers) do
                    if (value.owner.recordId ~= nil or value.owner.factionId ~=
                            nil) then
                        ownerRemoved = ownerRemoved + 1
                        core.sendGlobalEvent("setOwner", { object = value })
                        core.sendGlobalEvent("setOwnerFaction", { object = value })
                    end
                end
                for index, value in ipairs(nearby.doors) do
                    if (value.owner.recordId ~= nil or value.owner.factionId ~=
                            nil) then
                        ownerRemoved = ownerRemoved + 1
                        core.sendGlobalEvent("setOwner", { object = value })
                        core.sendGlobalEvent("setOwnerFaction", { object = value })
                    end
                end
                WriteToConsole("Removed ownership data from " ..
                    tonumber(ownerRemoved) .. " objects.")
            elseif value == "lock" then
                if (numVal == -1) then
                    WriteToConsole("No lock level provided", true)
                elseif (selectedObject ~= nil and selectedObject.type == types.Door or
                        selectedObject.type == types.Container) then
                    core.sendGlobalEvent("ZHAC_setLockLevel", { object = selectedObject, level = numVal })
                elseif (selectedObject == nil) then
                    WriteToConsole("No object selected", true)
                else
                    WriteToConsole("Invalid object selected", true)
                end
            elseif (value == "unlock") then
                if (selectedObject ~= nil and selectedObject.type == types.Door or
                        selectedObject.type == types.Container) then
                    if (selectedObject.type.isLocked(selectedObject) == false and selectedObject.type.getTrapSpell(selectedObject) == nil) then
                        WriteToConsole("Object is not locked or trapped", true)
                    else
                        WriteToConsole("Unlocked object", false)

                        core.sendGlobalEvent("ZHAC_setLockLevel", { object = selectedObject, level = 0 })
                    end
                elseif (selectedObject == nil) then
                    WriteToConsole("No object selected", true)
                else
                    WriteToConsole("Invalid object selected", true)
                end
                -- replace the container with one that isn't locked. Transfer the items.

                -- IF it's a door, teleport the player to the target, or replace the door if it isn't a teleport door.
            elseif (value == "unlockall") then
                safeGuard()
                local unlockCount = 0
                for index, door in ipairs(nearby.doors) do
                    if (door.type.isLocked(door) == true) then
                        core.sendGlobalEvent("DoUnlock", door)
                        unlockCount = unlockCount + 1
                    end
                end
                for index, door in ipairs(nearby.containers) do
                    if (door.type.isLocked(door) == true) then
                        core.sendGlobalEvent("DoUnlock", door)
                        unlockCount = unlockCount + 1
                    end
                end
                WriteToConsole("Unlocked" .. tostring(unlockCount) ..
                    " objects.")
            elseif (value == "takeall") then
                core.sendGlobalEvent("DebugEmptyInto",
                    { source = selectedObject, target = self })
            elseif value == "setdisposition" then
                local val = numVal
                local target = selectedObject
                if target and target.type == types.NPC then
                    
                core.sendGlobalEvent("setNPCDisposition",{actor = target, value = val})
                else
                    WriteToConsole("Invalid target",true)
                end
            elseif value == "getdisposition" then
                local target = selectedObject
                if target and target.type == types.NPC then
                    local val = types.NPC.getDisposition(target,self)
               
                    WriteToConsole("Current disposition: " .. tostring(val))
                 else
                    WriteToConsole("Invalid target",true)
                end
            elseif value == "addsoulgem" then
                -- addsoulgem "golden saint"  misc_soulgem_grand 
                local str = splitString(restOf)
                local soulID = removeQuotes( str[1])
                local gemID = removeQuotes( str[2])
                local num = numVal
                print(soulID)
                print(gemID)
                local targetObject = selectedObject
                if (targetObject == nil) then targetObject = self end
                core.sendGlobalEvent("addItemCommand", {
                    id = gemID,
                    count = num or 1,
                    soul = soulID,
                    target = targetObject
                })
            elseif (value == "additem") then
                local targetObject = selectedObject
                if (targetObject == nil) then targetObject = self end
                local num = numVal
                --WriteToConsole("Attempting to additem for " .. words[2])
                core.sendGlobalEvent("addItemCommand", {
                    id = noNumStr,
                    count = num or 1,
                    target = targetObject
                })
            else
                if (myTarget.type == self.type or (myTarget.type ~= types.NPC and myTarget.type ~= types.Creature)) then
                    for skill, val in pairs(types.NPC.stats.skills) do
                        if (value == "set" .. skill) then
                            local num = tonumber(restOf)
                            if (myTarget.type == self.type) then
                                types.NPC.stats.skills[skill](self).base = num
                                local val =
                                    types.NPC.stats.skills[skill](self).modified
                                print(val)
                                WriteToConsole("Setting stats on " .. self.type.record(self).name)
                                WriteToConsole(skill .. ": " .. tostring(val))
                            elseif myTarget.type ~= types.NPC then
                                types.NPC.stats.skills[skill](self).base = num
                                local val =
                                    types.NPC.stats.skills[skill](self).modified
                                --print(val)
                                WriteToConsole("Invalid object selected, defaulting to player, Setting stats on " ..
                                    self.type.record(self).name)
                                WriteToConsole(skill .. ": " .. tostring(val))
                            end
                        end
                        if (value == "get" .. skill) then
                            print(skill)
                            if (myTarget == nil) then
                                WriteToConsole("Target not found!", true)
                                break
                            end
                            local val = types.NPC.stats.skills[skill](self)
                                .modified
                            print(val)
                            WriteToConsole(skill .. ": " .. tostring(val))
                        end
                    end
                    for attrib, _ in pairs(types.Actor.stats.attributes) do
                        if (value == "set" .. attrib) then
                            local num = tonumber(restOf)
                            -- if (myTarget.type == self.type) then
                            types.Actor.stats.attributes[attrib](self).base =
                                num
                            WriteToConsole("Setting stats on " .. self.type.record(self).name)
                            local val = types.Actor.stats.attributes[attrib](
                                self).base
                            WriteToConsole(attrib .. ": " .. tostring(val))
                            -- end
                        elseif (value == "get" .. attrib) then
                            print(attrib)
                            if (myTarget == nil) then
                                WriteToConsole("Target not found!", true)
                                break
                            end
                            WriteToConsole("Getting stats on " .. self.type.record(self).name)
                            local val = types.Actor.stats.attributes[attrib](
                                self).modified
                            print(val)
                            WriteToConsole(attrib .. ": " .. tostring(val))
                        end
                    end
                    local dynamicName = "health"
                    if (value == "get" .. dynamicName) then
                        WriteToConsole("Getting stats on " .. self.type.record(self).name)
                        local dynamic = types.Actor.stats.dynamic[dynamicName](
                            self)
                        WriteToConsole(dynamicName .. ": " ..
                            tostring(dynamic.base))
                    elseif (value == "set" .. dynamicName) then
                        local num = numVal

                        WriteToConsole("Setting stats on " .. self.type.record(self).name)
                        local dynamic = types.Actor.stats.dynamic[dynamicName](
                            self)

                        dynamic.base = num
                        dynamic.current = num
                        local val = dynamic.base
                        WriteToConsole(dynamicName .. ": " .. tostring(val))
                    end

                    dynamicName = "fatigue"
                    if (value == "get" .. dynamicName) then
                        WriteToConsole("Getting stats on " .. self.type.record(self).name)
                        local dynamic = types.Actor.stats.dynamic[dynamicName](
                            selectedActor)
                        WriteToConsole(dynamicName .. ": " ..
                            tostring(dynamic.base))
                    elseif (value == "set" .. dynamicName) then
                        local num = numVal
                        WriteToConsole("Setting stats on " .. self.type.record(self).name)

                        local dynamic = types.Actor.stats.dynamic[dynamicName](
                            selectedActor)

                        dynamic.base = num
                        dynamic.current = num
                        local val = dynamic.base
                        WriteToConsole(dynamicName .. ": " .. tostring(val))
                    end

                    dynamicName = "magicka"
                    if (value == "get" .. dynamicName) then
                        WriteToConsole("Getting stats on " .. self.type.record(self).name)
                        local dynamic = types.Actor.stats.dynamic[dynamicName](
                            selectedActor)
                        WriteToConsole(dynamicName .. ": " ..
                            tostring(dynamic.base))
                    elseif (value == "set" .. dynamicName) then
                        local num = numVal
                        WriteToConsole("Setting stats on " .. self.type.record(self).name)

                        local dynamic = types.Actor.stats.dynamic[dynamicName](
                            selectedActor)

                        dynamic.base = num
                        dynamic.current = num
                        local val = dynamic.base
                        WriteToConsole(dynamicName .. ": " .. tostring(val))
                    end
                else
                    myTarget:sendEvent("setStat", { stat = value, value = restOf })
                end
            end
        end
    end
    if globalVariables then
        for index, value in ipairs(globalVariables) do
            if value:lower() == lowerCmd then
                core.sendGlobalEvent("printGlobalVarValue", value)
            end
        end
    else
        core.sendGlobalEvent("readVarValues", lowerCmd)
    end
end

local function runConsoleCommand(command)
    self:sendEvent("onConsoleCommandEvent", {
        cmd = command,
        mode = myMode,
        selectedObject = lastSelected
    })
end
local function mysplit(inputstr, sep)
    if sep == nil then sep = "," end
    local t = {}
    local firstCommaIndex = string.find(inputstr, sep)
    if firstCommaIndex then
        local item1 = string.sub(inputstr, 1, firstCommaIndex - 1)
        local item2 = string.sub(inputstr, firstCommaIndex + 1)
        table.insert(t, item1)
        table.insert(t, item2)
    else
        table.insert(t, inputstr)
        table.insert(t, "")
    end
    return t
end

local prespeed = 0
local keyboundKeys = storage.playerSection("SettingsDebugModePCHotKeys")
local commandPickerName = "CommandPicker"
local function onKeyPress(key)
    if (core.isWorldPaused() == true) then return end


    for i = 1, 6, 1 do
        local settingVal = keyboundKeys:get("runLine" .. tostring(i))
        if (settingVal ~= "") then
            local lineData = mysplit(settingVal, ",")
            if #lineData > 1 then
                local keyStr = lineData[1]
                if (keyStr == tostring(key.code) or keyStr == key.symbol) then
                    local command = lineData[2]

                    runConsoleCommand(command)
                end
            end
        end
    end
    if key.symbol == "m" and not core.isWorldPaused() then
        I.MenuChoose_Main.openMenu(commandPickerName)
        local ctable = playerSettings:get("hotkeydCommands")
        if not ctable then
            ctable = {}
            playerSettings:set("hotkeydCommands", ctable)
        end
        for index, value in ipairs(ctable) do
            I.MenuChoose_Main.addMenuItem(value)
        end
        I.MenuChoose_Main.addMenuItem("Add Last used Command")
    end
end
local function ChooseMenu_Picked(data)
    local menuName = data.menuName
    local pickedName = data.pickedName
    if menuName == commandPickerName then
        if pickedName == "Add Last used Command" then
            if lastCommand then
                local ctable = playerSettings:get("hotkeydCommands")
                local ntable = {}
                for index, value in ipairs(ctable) do
                    table.insert(ntable, value)
                end
                table.insert(ntable, lastCommand)
                playerSettings:set("hotkeydCommands", ntable)
            else
                ui.showMessage("No last command")
            end
        else
            runConsoleCommand(pickedName)
        end
    end
end

local function returnSetting(data)
    local key = data.key
    local value = data.value

    playerSettings:set(key, value)
end
local function getNearbyById(id)
    local nearbyLs = {
        nearby.actors, nearby.activators, nearby.containers, nearby.doors,
        nearby.items
    }
    for index, ls in ipairs(nearbyLs) do
        for index, item in ipairs(ls) do
            -- print(#ls,"Tables")
            if (item.id == id) then
                print(item.id, id)
                return item
            end
        end
    end
    return nil
end
local function onSave()
    print("Game is saved!")
    return {
        gameStarted = gameStarted,
        mode = myMode,
        selectedId = selectedId,
        storedCommand = storedCommand,
        currentContextOb = currentContextOb,
        savedCamData = savedCamData,
    }
end
local function onFrame() core.sendGlobalEvent("onFrame") end
local function onLoad(data)
    if not data and core.getGameTime() > 205239 then
        gameStarted = true
    end
    if (data) then
        selectedId = data.selectedId
        storedCommand = data.storedCommand
        currentContextOb = data.currentContextOb
        gameStarted = true
        if (data.savedCamData == nil) then
            savedCamData = {}
        else
            savedCamData = data.savedCamData
        end
    end
    if (selectedId == self.id or storedCommand == "luap") then
        selectedActor = self
    else
        selectedActor = getNearbyById(currentContextOb)
    end
    -- if (storedCommand == "luag") then
    --   selectedActor = nil

    -- end
    for i, record in ipairs(playerSettings:asTable()) do
        core.sendGlobalEvent("setSetting", {
            key = record:match("%w+"),
            value = playerSettings:get(record),
            player = self
        })
    end
    local attribute = core.stats.Attribute.records
    local skill = core.stats.Skill.records
    for index, value in pairs(attribute) do
        local name = value.id
        table.insert(outcommands, "set" .. name)
        table.insert(outcommands, "get" .. name)
    end
    for index, value in pairs(skill) do
        local name = value.id
        table.insert(outcommands, "set" .. name)
        table.insert(outcommands, "get" .. name)
    end
    table.insert(outcommands, "sethealth")
    table.insert(outcommands, "setfatigue")
    table.insert(outcommands, "setmag")
    table.insert(outcommands, "setmagicka")
    table.insert(outcommands, "gethealth")
    table.insert(outcommands, "getfatigue")
    table.insert(outcommands, "getmag")
    table.insert(outcommands, "getmagicka")
    for cmd, value in pairs(windows) do
        table.insert(outcommands, cmd)
        print(cmd)
    end
    if (data) then
        myMode = data.mode

        if (myMode ~= nil) then
            print(myMode)
            ui.setConsoleMode(myMode)
            if (myMode == "Lua[Player]") then
                self:sendEvent("OMWConsoleSetContext", self)
            elseif (myMode == "Lua[Global]") then
                self:sendEvent("OMWConsoleSetContext", nil)
            elseif selectedActor ~= nil and myMode ~= "" then
                core.sendGlobalEvent('OMWConsoleStartLocal', {
                    player = self.object,
                    selected = selectedActor
                })
            end
        end
    end

    if (storedCommand == "luag") then selectedActor = nil end
    for i, record in ipairs(playerSettings:asTable()) do
        print(record:match("%w+"))
        core.sendGlobalEvent("setSetting", {
            key = record:match("%w+"),
            value = playerSettings:get(record),
            player = self
        })
    end
    self:sendEvent("DebugLoaded")
end
local function loadVariables(vars)
    globalVariables = vars
    for index, variable in ipairs(vars) do
        table.insert(outcommands, variable)
    end
end
local function onInit()
    print("Oninit" .. playerSettings:get("defaultContext"))
    local context = playerSettings:get("defaultContext")
    if (context == "MWScript") then
        -- do nothing, already there
        myMode = ""
    elseif (context == "Player") then
        myMode = "Lua[Player]"
        ui.setConsoleMode(myMode)
        self:sendEvent("OMWConsoleSetContext", self)
    elseif context == "Global" then
        myMode = "Lua[Global]"
        ui.setConsoleMode(myMode)
        self:sendEvent("OMWConsoleSetContext", nil)
    end

    for i, record in ipairs(playerSettings:asTable()) do
        print(record:match("%w+"))
        core.sendGlobalEvent("setSetting", {
            key = record:match("%w+"),
            value = playerSettings:get(record),
            player = self
        })
    end
    onLoad()
    --  core.sendGlobalEvent("purgePaintings")
end
local startSettings = storage.playerSection("SettingsDebugModePCStart")
local itemSettings = storage.playerSection("SettingsDebugModePCStartEq")
local function onLoadEvent()
    if (gameStarted) then return end
    ui.setConsoleSelectedObject(self)
    for i = 1, 6, 1 do
        local settingVal = startSettings:get("runLine" .. tostring(i))
        if (settingVal ~= "") then
            self:sendEvent("onConsoleCommandEvent", {
                mode = "Lua[Player]",
                cmd = settingVal,
                selectedObject = nil
            })
        end
    end
    local itemsToAdd = {}
    for i = 1, 6, 1 do
        local settingVal = itemSettings:get("ItemID" .. tostring(i))
        if (settingVal ~= "") then table.insert(itemsToAdd, settingVal) end
    end
    if (#itemsToAdd > 0) then I.ZackUtils.addItemsEquip(self, itemsToAdd) end
end
local function checkCommand(cmd)
    local words = {}

    for word in cmd:gmatch("%S+") do table.insert(words, word) end

    for index, value in ipairs(outcommands) do
        if (value == words[1]) then return false end
    end
    return true
end
local function setEquipment(equip) types.Actor.setEquipment(self, equip) end
local wasOverRiding = false
local prevWeapon = nil
local function findWeapon() return nil end
local equipdelay = -1
local prevStance = nil
local startTime = 0
local vertDist = 200
local function setOffset(i) vertDist = i end
local delay = 0
local mult = 0.01
local function selectReturn(obj) ui.setConsoleSelectedObject(obj) end
local lastCell = nil
local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw), -- y
        math.sin(pitch)        -- z
    )
end

local function getCameraDirData()
    local pos = camera.getPosition()
    local pitch = -(camera.getPitch() + camera.getExtraPitch())
    local yaw = camera.getYaw() + camera.getExtraYaw()

    return pos, anglesToV(pitch, yaw)
end

local function rotateVector2D(vector, angle)
    local cosAngle = math.cos(angle)
    local sinAngle = math.sin(angle)
    local x = vector.x * cosAngle - vector.y * sinAngle
    local y = vector.x * sinAngle + vector.y * cosAngle
    return util.vector3(x, y, vector.z)
end

local function getNextCamPos(rotationOffset, dist)
    local pos, v = getCameraDirData()

    if rotationOffset then
        v = rotateVector2D(v, rotationOffset)
    end

    --local dist = 50
    local ret = nearby.castRay(pos, pos + v * dist)

    --  if ret.hitPos == nil then
    return pos + v * dist
    --  else
    --      return ret.hitPos
    --  end
end
local speed = 0.1                    -- Initial speed value
local elapsedTime = 0                -- Elapsed time since the last key press
local startTime = core.getRealTime() -- Start time since the game started
local fallTime = 0
local baseFatigue = 0
local function onUpdate(dt)
    local myFatigue = types.Actor.stats.dynamic.fatigue(self).current
    if (myFatigue == 0 and core.getGameTime() > fallTime + 10) then
        baseFatigue = types.Actor.stats.dynamic.fatigue(self).base
        -- types.Actor.stats.dynamic.fatigue(self).base = 0
        fallTime = core.getGameTime()
    end
    if (types.Actor.stats.dynamic.fatigue(self).base == 0 and core.getGameTime() > fallTime + 2) then
        --  types.Actor.stats.dynamic.fatigue(self).base = baseFatigue
    end
    if camera.getMode() == camera.MODE.Static and inFreecam then
        local newPos = camera.getPosition()
        local nx, ny, nz = newPos.x, newPos.y, newPos.z
        local movementAngle = 0
        local keyPressed = false

        if input.isKeyPressed(input.KEY.W) then
            if input.isKeyPressed(input.KEY.A) then
                movementAngle = math.rad(45)
            else
                movementAngle = 0
            end
            keyPressed = true
        elseif input.isKeyPressed(input.KEY.S) then
            if input.isKeyPressed(input.KEY.A) then
                movementAngle = math.rad(-135)
            else
                movementAngle = math.rad(180)
            end
            keyPressed = true
        elseif input.isKeyPressed(input.KEY.D) then
            movementAngle = math.rad(-90)
            keyPressed = true
        elseif input.isKeyPressed(input.KEY.A) then
            movementAngle = math.rad(90)
            keyPressed = true
        end

        if keyPressed then
            local currentTime = core.getRealTime()
            local elapsedTime = currentTime - startTime
            local currentSpeed = speed * ((1 + elapsedTime) * 25) -- Adjust the speed increment factor as desired
            print(currentSpeed)
            camera.setStaticPosition(getNextCamPos(movementAngle, currentSpeed))
        else
            startTime = core.getRealTime() -- Reset start time if no key is pressed
        end

        camera.setPitch(camera.getPitch() + (input.getMouseMoveY() * mult))
        camera.setYaw(camera.getYaw() + (input.getMouseMoveX() * mult))
    end
    if (self.cell ~= lastCell) then
        if (playerSettings:get("DisableOwnership")) then
            for index, value in ipairs(nearby.items) do
                if (value.owner.recordId ~= nil or value.owner.factionId ~= nil) then
                    core.sendGlobalEvent("setOwner", { object = value })
                    core.sendGlobalEvent("setOwnerFaction", { object = value })
                end
            end
            for index, value in ipairs(nearby.containers) do
                if (value.owner.recordId ~= nil or value.owner.factionId ~= nil) then
                    core.sendGlobalEvent("setOwner", { object = value })
                    core.sendGlobalEvent("setOwnerFaction", { object = value })
                end
            end
            for index, value in ipairs(nearby.doors) do
                if (value.owner.recordId ~= nil or value.owner.factionId ~= nil) then
                    core.sendGlobalEvent("setOwner", { object = value })
                    core.sendGlobalEvent("setOwnerFaction", { object = value })
                end
            end
        end
    end
    if (tempPlayer ~= nil and self.id == "1_-1") then
        camera.setStaticPosition(util.vector3(tempPlayer.position.x,
            tempPlayer.position.y,
            tempPlayer.position.z + vertDist))
    end
    lastCell = self.cell
end

local function onConsoleCommandEvent(data)
    onConsoleCommand(data.mode, data.cmd, data.selectedObject)
end
local function addOutCommand(cmd, func)
    table.insert(outcommands, cmd:lower())
    if func then
        commandBindings[cmd:lower()] = func
    end
end
local function addGlobalCommand(cmd, eventName)
    table.insert(outcommands, cmd)
    commandBindings[cmd:lower()] = function(data) core.sendGlobalEvent(eventName, data) end
end
return {
    interfaceName = "DebugMode",
    interface = {
        version = 31,
        outcommands = outcommands,
        checkCommand = checkCommand,
        ReturnActorSwap = ReturnActorSwap,
        setOffset = setOffset,
        runConsoleCommand = runConsoleCommand,
        addOutCommand = addOutCommand,
    },
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onInit = onInit,
        onLoad = onLoad,
        onSave = onSave,
        onKeyPress = onKeyPress,
        onUpdate = onUpdate,
        onFrame = onFrame

    },
    eventHandlers = {
        onMessageSent = onMessageSent,
        returnSetting = returnSetting,
        onLoadEvent = onLoadEvent,
        WriteToConsole = WriteToConsole,
        WriteToConsoleEvent = WriteToConsoleEvent,
        ReturnActorSwap = ReturnActorSwap,
        setEquipment = setEquipment,
        selectReturn = selectReturn,
        loadVariables = loadVariables,
        onConsoleCommandEvent = onConsoleCommandEvent,
        ChooseMenu_Picked = ChooseMenu_Picked,
    }
}
