local cam, camera, core, self, nearby, types, ui, util, storage, async, input, zackUtils =
    require('openmw.interfaces').Camera, require('openmw.camera'),
    require('openmw.core'), require('openmw.self'),
    require('openmw.nearby'), require('openmw.types'),
    require('openmw.ui'), require('openmw.util'),
    require("openmw.storage"), require("openmw.async"),
    require("openmw.input"), require("scripts.ZackUtils.PlayerInterface").interface

local commandData = require("scripts.debugmode.data.commands").interface

local addItem = zackUtils.addItem



local soundLines = require("scripts.ZackUtils.SoundLines")










local time = require('openmw_aux.time')
local calendar = require('openmw_aux.calendar')
local selectedId = nil

local selectedActor = nil
local currentContextOb = nil

local storedCommand = nil

local tgm = false
local tcl = false


local zu

local I = require("openmw.interfaces")

local time = require('openmw_aux.time')

local outcommands = {
     "setpos",
     "getpos",
     "fixme",
     "setdelete",
     "disable",
     "enable",
     "kill",
     "killall",
     "feather",
     "killcreas",
     "dropall",
     "reloadlua",
     "findnamed",
     "help",
     "tgm",
     "coc",
     "compshare",
     "ex",
     "rlua",
     "additem",
     "addequip",
     "takeall",
     "seeall",
     "resurrect",
     "addspell",
     "unlock",
     "unlockall",
     "clearowner",
     "clearallowners",
     "placeatme",
     "placeatpc",
     "placeattarget",
     "fly",
     "exgame",
     "exitgame",
     "tcl",
     "setsun",
     "select",
     "prid",
     "moveto",
     "movetoid",
     "setgametime",
     "sethour",
     "SetPCCrimeLevel",
     "findrecord",
     "find",
     "findcell",
     "clearinv",
     "freecam",
     "findslavers",
     "buff",
     "psb",
     "getsimspeed",
     "setsimspeed",
     "purge",
     "tfc",
     "showdisabled",
     "playsound",
     "findsound",

}
local function WriteToConsole(text, error)
     if error == true then
          ui.printToConsole(text, ui.CONSOLE_COLOR.Error)
          return
     end
     ui.printToConsole(text, ui.CONSOLE_COLOR.Info)
end
local function WriteToConsoleEvent(data)
     if data.error == true then
          ui.printToConsole(data.text, ui.CONSOLE_COLOR.Error)
          return
     end
     ui.printToConsole(data.text, ui.CONSOLE_COLOR.Info)
end
local gameStarted = false
local playerSettings = storage.playerSection("SettingsDebugMode")

local function safeGuard()
     if (playerSettings:get("EnableSafeguard") == false) then
          return
     end
     --This function attemps to prevent execution of commands that will permenently damage a world.
     local gt = core.getGameTime()
     local days = gt / time.day

     local playerName = types.NPC.record(self).name

     if string.sub(types.NPC.record(self).name:lower(), 1, 6) ~= "player" then
          local errorM = string.format(
               "Safeguard attempted to prevent damage to real save, player name does not start with player, but is %s",
               playerName)
          WriteToConsole(errorM, true)
          error(errorM)
          return false
     end



     if (days > 7) then
          local errorM = string.format("Safeguard attempted to prevent damage to real save, dayspassed is %i", days)
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
     for _, v in ipairs(tableb) do
          if v == value then
               return true
          end
     end
     return false
end
local function removeQuotes(str)
     local result = string.gsub(str, "[\"']", "")
     return result
end

local function onMessageSent(eventData)
     ui.showMessage(eventData)
end
local function onMessageSent(eventData) ui.showMessage(eventData) end
local myMode = nil
local freeCam = false
local tempPlayer = nil

local function ReturnActorSwap(actor)
     tempPlayer = actor
end
local selectedItem

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

     if currentItem ~= "" then
          table.insert(result, currentItem)
     end

     -- Check if the last item is a number and remove it along with the space in front
     local lastItem = result[#result]
     local lastItemNumber = tonumber(lastItem)
     local wholeStringMinusLastNumber = inputString
     if lastItemNumber then
          table.remove(result)
          wholeStringMinusLastNumber = inputString:sub(1, #inputString - #lastItem - 1)
     end

     return result, lastItemNumber, wholeStringMinusLastNumber
end


local function padStrings(strings)
     -- Find the maximum length among all strings
     local maxLength = 0
     for _, str in ipairs(strings) do
          maxLength = math.max(maxLength, #str)
     end

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

     for part in str:gmatch("[^.]+") do
          table.insert(parts, part)
     end

     if dotCount > 1 or parts[2] then
          moreInfo = parts[1] .. "." .. " (More Info Available)"
     else
          moreInfo = parts[1]
     end

     return parts, moreInfo
end

local function stringInList(str, list)
     local stringList = {}
     for word in list:gmatch("[^;]+") do
          table.insert(stringList, word)
     end

     for _, word in ipairs(stringList) do
          if str == word then
               return true
          end
     end

     return false
end

local lastSelected = nil

local function onConsoleCommand(mode, command, selectedObject)
     if (zu == nil) then
          zu = I.ZackUtils
     end
     local words = {}
     local numVal = -1
     lastSelected = selectedObject
     myMode = mode
     if (mode ~= "") then
          if command == 'luap' or (command == 'luas' and selectedObject == self.object) then
               self:sendEvent("OMWConsoleSetContext", self)
               return
          elseif command == 'luag' then
               self:sendEvent("OMWConsoleSetContext")
               return
          elseif command == 'luas' then
               currentContextOb = selectedObject.id
               if selectedObject then
                    core.sendGlobalEvent('OMWConsoleStartLocal', { player = self.object, selected = selectedObject })
               else
                    ui.printToConsole('No selected object', ui.CONSOLE_COLOR.Error)
               end
               return
          end
     end
     for word in command:gmatch("%S+") do
          table.insert(words, word)
     end
     words, numVal = splitString(command)
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

     for index, value in ipairs(outcommands) do
          local restOf = string.sub(command, string.len(words[1]) + 2) --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it. --this variable contains the command string, minus the first word and the space after it.

          local sanitizedStr = removeQuotes(restOf)
          if (words[1] == value or words[1] == "lua" .. value) then
               if (value == "reloadlua" or value == "rlua") then
                    core.sendGlobalEvent("runMWscriptBridge", { player = self, recordId = "zhac_debugmode_resetlua" })
               elseif (value == "tcl") then
                    core.sendGlobalEvent("runMWscriptBridge", { player = self, recordId = "zhac_debugmode_tcl" })
                    tcl = not tcl
                    WriteToConsole("Toggled player collision. Should now be set to: " .. tostring(not tcl))
               elseif value == "exitgame" or value == "exgame" then
                    WriteToConsole("Closing the game.")
                    core.quit()
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
                              local lines, info = splitStringWithInfo(value.Description)
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
               elseif (value == "coc") then
                    core.sendGlobalEvent("COCEvent", { objectToTeleport = self, cellname = removeQuotes(restOf) })
               elseif (value == "findcell") then
                    core.sendGlobalEvent("COCEvent",
                         { objectToTeleport = self, cellname = removeQuotes(restOf), printOnly = true })
               elseif (value == "showdisabled") then
                    core.sendGlobalEvent("showDisabled")
               elseif value == "playsound" then
                    local numCheck = tonumber(restOf)
                    local checkString = restOf
                    for i, soun in ipairs(soundLines) do
                         if (checkString:lower() == value) or (numCheck ~= nil and numCheck == i) then
                              WriteToConsole("Playing sound " .. soun)
                              core.sendGlobalEvent("playSound", soun)
                         end
                    end
               elseif value == "findsound" and restOf == "" then
                    for i, soun in ipairs(soundLines) do
                         WriteToConsole(string.format("#%i: %s", i, soun))
                    end
               elseif value == "findsound" then
                    for i, soun in ipairs(soundLines) do
                         if string.find(soun, restOf) then
                              WriteToConsole(string.format("#%i: %s", i, soun))
                         end
                    end
               elseif value == "compshare" then
                    if (selectedObject.type == types.NPC) then
                         core.sendGlobalEvent("CompShare", selectedObject)
                    else
                         WriteToConsole("Invalid object selected", true)
                    end
               elseif (value == "killall") then
                    safeGuard()
                    core.sendGlobalEvent("killAll")
               elseif value == "kill" then
                    if (selectedObject ~= nil and selectedObject.type == types.NPC or selectedObject.type == types.Creature) then
                         selectedObject:sendEvent("setStat", { type = "health", value = 0 })
                         WriteToConsole("Killed " .. selectedObject.recordId)
                    else
                         WriteToConsole("Invalid selection", true)
                    end
               elseif (value == "moveto") then
                    safeGuard()
                    core.sendGlobalEvent("moveToActorEvent",
                         { objectToTeleport = myTarget, targetName = removeQuotes(restOf:lower()) })
               elseif (value == "select" or value == "prid") then
                    safeGuard()
                    core.sendGlobalEvent("moveToActorEvent",
                         { objectToTeleport = self, targetName = restOf:lower(), justReturn = true })
               elseif (value == "seeall") then
                    safeGuard()
                    --   if(words[2] == "clothing") then
                    core.sendGlobalEvent("createContainerFilledWithType", words[2])
               elseif (value == "addspell") then
                    local info = zu.addSpell(restOf)
                    zu.printToConsole(info)
               elseif value == "disable" or value == "enable" then
                    local setTo = value == "enable"
                    core.sendGlobalEvent("setDisabled", { object = selectedObject, state = setTo })
                    WriteToConsole(value .. "d " .. selectedObject.recordId)
               elseif value == "placeatpc" then
                    I.ZackUtils.createItem(removeQuotes(sanitizedStr), self.cell, self.position,
                         util.vector3(0, 0, self.rotation.z))
               elseif value == "placeattarget" then
                    local look = I.ZackUtils.getObjInCrosshairs(self, 10000).hitPos
                    local target = self.position
                    look = util.vector3(look.x, look.y, look.z + 100)
                    if (look == nil) then
                         WriteToConsole("No point to place at!", true)
                    else
                         I.ZackUtils.createItem(sanitizedStr, self.cell, look, util.vector3(0, 0, self.rotation.z))
                    end
               elseif value == "placeatme" then
                    I.ZackUtils.createItem(sanitizedStr, myTarget.cell, myTarget.position, myTarget.rotation)
               elseif value == "getpos" then
                    local axis = words[2]
                    if axis == "x" then
                         WriteToConsole("X Position: " .. tostring(myTarget.position.x))
                    elseif axis == "y" then
                         WriteToConsole("Y Position: " .. tostring(myTarget.position.y))
                    elseif axis == "z" then
                         WriteToConsole("Z Position: " .. tostring(myTarget.position.z))
                    end
               elseif (value == "setdelete" and selectedObject and selectedObject ~= self) then
                    I.ZackUtils.deleteItem(selectedObject)
               elseif value == "psb" then
                    safeGuard()
                    local spellcount = 0
                    for index, value in ipairs(core.magic.spells) do
                         if (value.type == core.magic.SPELL_TYPE.Spell) then
                              types.Actor.spells(self):add(value)
                              spellcount = spellcount + 1
                         end
                    end
                    WriteToConsole("Added " .. tostring(spellcount) .. " spells to player")
               elseif value == "setpos" then
                    local axis = words[2]
                    local pos = tonumber(words[3])
                    core.sendGlobalEvent("setPos", { actor = myTarget, axis = axis, pos = pos })
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
               elseif value == "movetoid" then
                    local unid = sanitizedStr
                    core.sendGlobalEvent("moveToId", unid)
               elseif value == "findrecord" then
                    core.sendGlobalEvent("findRecordByName", restOf)
               elseif value == "setgametime" then
                    safeGuard()
                    local newTime = tonumber(words[2])
                    core.sendGlobalEvent("runMWscriptBridge", {
                         player = self,
                         recordId = "zhac_debugmode_gametime",
                         desiredGameTime = newTime
                    })
               elseif value == "setsimspeed" then

               elseif value == "getsimspeed" then

               elseif value == "purge" then
                    safeGuard()
                    core.sendGlobalEvent("purgeMod", restOf)
               elseif value == "sethour" then
                    safeGuard()
                    local fnewTime = numVal
                    local newDaysPassed = math.floor(core.getGameTime() / time.day)
                    local newTime = newDaysPassed * time.day + (fnewTime * time.hour)
                    core.sendGlobalEvent("runMWscriptBridge", {
                         player = self,
                         recordId = "zhac_debugmode_gametime",
                         desiredGameTime = newTime
                    })
               elseif value == "freecam" then
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
                         I.ZackUtils.addItem(self, "zhac_playershrinker")
                         core.sendGlobalEvent("DebugActorSwap", {
                              currentActor = self.id,
                              newActorId = self.recordId,
                              doClone = true
                         })
                         freeCam = true
                    else
                         zu.removeSpell("zhac_debug_fly")
                         input.setControlSwitch(input.CONTROL_SWITCH.ViewMode, true)
                         I.ZackUtils.addItem(self, "zhac_playergrower")
                         I.ZackUtils.deleteItem(tempPlayer)
                         tempPlayer = nil
                         freeCam = false
                    end
               elseif (value == "resurrect") then
                    if (types.Actor.stats.dynamic.health(self).current == 0) then
                         core.sendGlobalEvent("runMWscriptBridge", {
                              player = self,
                              recordId = "zhac_debugmode_resurrectplayer"
                         })
                    else
                         if (selectedObject.id == self.id or selectedObject == nil) then
                              core.sendGlobalEvent("runMWscriptBridge", {
                                   player = self,
                                   recordId = "zhac_debugmode_resurrectplayer"
                              })
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
                    core.sendGlobalEvent("runMWscriptBridge", {
                         player = self,
                         recordId = "zhac_debugmode_tgm"
                    })
                    WriteToConsole("Toggled God Mode")
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
               elseif (value == "resurrect") then
                    if (selectedObject.id == self.id) then
                         core.sendGlobalEvent("runMWscriptBridge",
                              { player = self, recordId = "zhac_debugmode_resurrectplayer" })
                    else
                         core.sendGlobalEvent("DebugActorSwap",
                              { currentActor = selectedObject.id, newActorId = selectedObject.recordId })
                    end
               elseif (value == "killcreas") then
                    core.sendGlobalEvent("killAll", { filterType = "Creature" })
               elseif (value == "tgm") then
                    core.sendGlobalEvent("runMWscriptBridge", { player = self, recordId = "zhac_debugmode_tgm" })
                    tgm = not tgm
                    WriteToConsole("Toggled TGM. Should now be set to: " .. tostring(tgm))
                    return
               elseif value == "doabigbuff" then
                    --buff a bunch of stats
                    for index, skill in pairs(core.SKILL) do
                         if (value == "set" .. skill) then
                              local num = (100000)
                              if (myTarget.type == self.type) then
                                   types.NPC.stats.skills[skill](self).base = num
                                   local val = types.NPC.stats.skills[skill](myTarget).modified
                                   print(val)
                                   WriteToConsole(skill .. ": " .. tostring(val))
                              end
                         end
                    end
               elseif (value == "fixme") then
               elseif value == "clearowner" then
                    if (selectedObject ~= nil and (selectedObject.ownerRecordId ~= nil or selectedObject.ownerFactionId ~= nil)) then
                         if (selectedObject.ownerRecordId ~= nil) then
                              core.sendGlobalEvent("setOwner", { object = selectedObject })
                              WriteToConsole("Removed owner " .. selectedObject.ownerRecordId)
                         end
                         if (selectedObject.ownerFactionId ~= nil) then
                              core.sendGlobalEvent("setOwnerFaction", { object = selectedObject })
                              WriteToConsole("Removed owner faction" .. selectedObject.ownerFactionId)
                         end
                    elseif (selectedObject == nil) then
                         WriteToConsole("No selected item.", true)
                    elseif (selectedObject.ownerRecordId == nil) then
                         WriteToConsole("No owner to remove.", true)
                    end
               elseif value == "clearallowners" then
                    safeGuard()
                    local ownerRemoved = 0
                    for index, value in ipairs(nearby.items) do
                         if (value.ownerRecordId ~= nil or value.ownerFactionId ~= nil) then
                              ownerRemoved = ownerRemoved + 1
                              core.sendGlobalEvent("setOwner", { object = value })
                              core.sendGlobalEvent("setOwnerFaction", { object = value })
                         end
                    end
                    for index, value in ipairs(nearby.containers) do
                         if (value.ownerRecordId ~= nil or value.ownerFactionId ~= nil) then
                              ownerRemoved = ownerRemoved + 1
                              core.sendGlobalEvent("setOwner", { object = value })
                              core.sendGlobalEvent("setOwnerFaction", { object = value })
                         end
                    end
                    for index, value in ipairs(nearby.doors) do
                         if (value.ownerRecordId ~= nil or value.ownerFactionId ~= nil) then
                              ownerRemoved = ownerRemoved + 1
                              core.sendGlobalEvent("setOwner", { object = value })
                              core.sendGlobalEvent("setOwnerFaction", { object = value })
                         end
                    end
                    WriteToConsole("Removed ownership data from " .. tonumber(ownerRemoved) .. " objects.")
               elseif (value == "unlock") then
                    safeGuard()
                    if (selectedObject ~= nil and selectedObject.type == types.Door or selectedObject.type == types.Container) then
                         core.sendGlobalEvent("DoUnlock", selectedObject)
                         WriteToConsole("Tried to unlock: " .. selectedObject.type.record(selectedObject).name)
                    elseif (selectedObject == nil) then
                         WriteToConsole("No object selected", true)
                    else
                         WriteToConsole("Invalid object selected", true)
                    end
                    --replace the container with one that isn't locked. Transfer the items.

                    --IF it's a door, teleport the player to the target, or replace the door if it isn't a teleport door.
               elseif (value == "unlockall") then
                    safeGuard()
                    local unlockCount = 0
                    for index, door in ipairs(nearby.doors) do
                         if (types.Door.isTeleport(door) == false) then
                              core.sendGlobalEvent("DoUnlock", door)
                              unlockCount = unlockCount + 1
                         end
                    end
                    for index, door in ipairs(nearby.containers) do
                         core.sendGlobalEvent("DoUnlock", door)
                         unlockCount = unlockCount + 1
                    end
                    WriteToConsole("Tried to unlock " .. tostring(unlockCount) .. " objects.")
               elseif (value == "takeall") then
                    core.sendGlobalEvent("DebugEmptyInto", { source = selectedObject, target = self })
               elseif (value == "additem") then
                    local targetObject = selectedObject
                    if (targetObject == nil) then
                         targetObject = self
                    end
                    local splitText, num, idWhole = splitString(restOf)
                    core.sendGlobalEvent("addItemCommand", { id = idWhole, count = num, target = targetObject })
               else
                    if (myTarget.id == self.id) then
                         for index, skill in pairs(core.SKILL) do
                              if (value == "set" .. skill) then
                                   local num = tonumber(restOf)
                                   if (myTarget.type == self.type) then
                                        types.NPC.stats.skills[skill](self).base = num
                                        local val = types.NPC.stats.skills[skill](self)
                                            .modified
                                        print(val)
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
                         for index, attrib in pairs(core.ATTRIBUTE) do
                              if (value == "set" .. attrib) then
                                   local num = tonumber(restOf)
                                   --if (myTarget.type == self.type) then
                                   types.Actor.stats.attributes[attrib](self).base = num
                                   local val = types.Actor.stats.attributes[attrib](self)
                                       .base
                                   WriteToConsole(attrib .. ": " .. tostring(val))
                                   -- end
                              elseif (value == "get" .. attrib) then
                                   print(attrib)
                                   if (myTarget == nil) then
                                        WriteToConsole("Target not found!", true)
                                        break
                                   end
                                   local val = types.Actor.stats.attributes[attrib](self)
                                       .modified
                                   print(val)
                                   WriteToConsole(attrib .. ": " .. tostring(val))
                              end
                         end
                         local dynamicName = "health"
                         if (value == "get" .. dynamicName) then
                              local dynamic = types.Actor.stats.dynamic[dynamicName](self)
                              WriteToConsole(dynamicName .. ": " .. tostring(dynamic.base))
                         elseif (value == "set" .. dynamicName) then
                              local num = tonumber(restOf)

                              local dynamic = types.Actor.stats.dynamic[dynamicName](self)

                              dynamic.base = num
                              dynamic.current = num
                              local val = dynamic.base
                              WriteToConsole(dynamicName .. ": " .. tostring(val))
                         end

                         dynamicName = "fatigue"
                         if (value == "get" .. dynamicName) then
                              local dynamic = types.Actor.stats.dynamic[dynamicName](selectedActor)
                              WriteToConsole(dynamicName .. ": " .. tostring(dynamic.base))
                         elseif (value == "set" .. dynamicName) then
                              local num = tonumber(restOf)

                              local dynamic = types.Actor.stats.dynamic[dynamicName](selectedActor)

                              dynamic.base = num
                              dynamic.current = num
                              local val = dynamic.base
                              WriteToConsole(dynamicName .. ": " .. tostring(val))
                         end

                         dynamicName = "magicka"
                         if (value == "get" .. dynamicName) then
                              local dynamic = types.Actor.stats.dynamic[dynamicName](selectedActor)
                              WriteToConsole(dynamicName .. ": " .. tostring(dynamic.base))
                         elseif (value == "set" .. dynamicName) then
                              local num = tonumber(restOf)

                              local dynamic = types.Actor.stats.dynamic[dynamicName](selectedActor)

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
end


local function runConsoleCommand(command)
     self:sendEvent("onConsoleCommandEvent", { cmd = command, mode = myMode, selectedObject = lastSelected })
end
local function mysplit(inputstr, sep)
     if sep == nil then
          sep = ","
     end
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
local function onKeyPress(key)
     if(core.isWorldPaused() == true) then
          return
     end
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
end

local function returnSetting(data)
     local key = data.key
     local value = data.value

     playerSettings:set(key, value)
end
local function getNearbyById(id)
     local nearbyLs = { nearby.actors, nearby.activators, nearby.containers, nearby.doors, nearby.items }
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
     return { gameStarted = gameStarted,mode = myMode, selectedId = selectedId, storedCommand = storedCommand, currentContextOb = currentContextOb, }
end
local function onFrame()
     core.sendGlobalEvent("onFrame")
end
local function onLoad(data)
     if (data) then
          selectedId = data.selectedId
          storedCommand = data.storedCommand
          currentContextOb = data.currentContextOb
          gameStarted = data.gameStarted
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
     for index, value in pairs(core.ATTRIBUTE) do
          table.insert(outcommands, "set" .. value)
          table.insert(outcommands, "get" .. value)
     end
     for index, value in pairs(core.SKILL) do
          table.insert(outcommands, "set" .. value)
          table.insert(outcommands, "get" .. value)
     end
     table.insert(outcommands, "sethealth")
     table.insert(outcommands, "setfatigue")
     table.insert(outcommands, "setmag")
     table.insert(outcommands, "setmagicka")
     table.insert(outcommands, "gethealth")
     table.insert(outcommands, "getfatigue")
     table.insert(outcommands, "getmag")
     table.insert(outcommands, "getmagicka")
     if (data) then
          myMode = data.mode

          if (myMode ~= nil) then
               --print(myMode)
               ui.setConsoleMode(myMode)
               if (myMode == "Lua[Player]") then
                    self:sendEvent("OMWConsoleSetContext", self)
               elseif (myMode == "Lua[Global]") then
                    self:sendEvent("OMWConsoleSetContext", nil)
               else
                    core.sendGlobalEvent('OMWConsoleStartLocal', { player = self.object, selected = selectedActor })
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
end



local function onInit()
     print("Oninit" .. playerSettings:get("defaultContext"))
     local context = playerSettings:get("defaultContext")
     if (context == "MWScript") then
          --do nothing, already there
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
end
local startSettings = storage.playerSection("SettingsDebugModePCStart")
local itemSettings = storage.playerSection("SettingsDebugModePCStartEq")
local function onLoadEvent()
     if(gameStarted) then
          return
     end
     for i = 1, 6, 1 do
          local settingVal = startSettings:get("runLine" .. tostring(i))
          if (settingVal ~= "") then
               self:sendEvent("onConsoleCommandEvent", { mode = "Lua[Player]", cmd = settingVal, selectedObject = nil })
          end
     end
     local itemsToAdd = {}
     for i = 1, 6, 1 do
          local settingVal = itemSettings:get("ItemID" .. tostring(i))
          if (settingVal ~= "") then
               table.insert(itemsToAdd, settingVal)
          end
     end
     if (#itemsToAdd > 0) then
          I.ZackUtils.addItemsEquip(self, itemsToAdd)
     end
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
local function selectReturn(obj)
     ui.setConsoleSelectedObject(obj)
end
local lastCell = nil
local function onUpdate(dt)
     if (self.cell ~= lastCell) then
          if (playerSettings:get("DisableOwnership")) then
               for index, value in ipairs(nearby.items) do
                    if (value.ownerRecordId ~= nil or value.ownerFactionId ~= nil) then
                         core.sendGlobalEvent("setOwner", { object = value })
                         core.sendGlobalEvent("setOwnerFaction", { object = value })
                    end
               end
               for index, value in ipairs(nearby.containers) do
                    if (value.ownerRecordId ~= nil or value.ownerFactionId ~= nil) then
                         core.sendGlobalEvent("setOwner", { object = value })
                         core.sendGlobalEvent("setOwnerFaction", { object = value })
                    end
               end
               for index, value in ipairs(nearby.doors) do
                    if (value.ownerRecordId ~= nil or value.ownerFactionId ~= nil) then
                         core.sendGlobalEvent("setOwner", { object = value })
                         core.sendGlobalEvent("setOwnerFaction", { object = value })
                    end
               end
          end
     end
     if (tempPlayer ~= nil and self.id == "1_-1") then
          camera.setStaticPosition(util.vector3(tempPlayer.position.x, tempPlayer.position.y,
               tempPlayer.position.z + vertDist))
     end
     lastCell = self.cell
end

local function onConsoleCommandEvent(data)
     onConsoleCommand(data.mode, data.cmd, data.selectedObject)
end
return {
     interfaceName = "DebugMode",
     interface = {
          version = 1,
          outcommands = outcommands,
          checkCommand = checkCommand,
          ReturnActorSwap = ReturnActorSwap,
          setOffset = setOffset,
          runConsoleCommand = runConsoleCommand,
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
          onConsoleCommandEvent = onConsoleCommandEvent,
     }
}
