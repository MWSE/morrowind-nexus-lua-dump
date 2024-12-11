local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation
local playerSettings = storage.globalSection("SettingsDebugMode")
if world.players == nil then
  return
end
local function createRotation(x, y, z)
  if (core.API_REVISION < 40) then
    return util.vector3(x, y, z)
  else
    local rotate = util.transform.rotateZ(math.rad(z))
    return rotate
  end
end
local function checkSupermanMode()
  if #world.players == 0 then
    return
  end
  local supermanPath = 'scripts/DebugMode/superman.lua'
  local value = { path = supermanPath, setting = "EnableSupermanMode" }
  if (world.players[1]:hasScript(supermanPath) and not playerSettings:get(value.setting)) then
    world.players[1]:removeScript(value.path)
  elseif (not world.players[1]:hasScript(value.path) and playerSettings:get(value.setting)) then
    world.players[1]:addScript(value.path)
  end
end
local blackList = {}
local zackUtils = require("scripts.ZackUtils.GlobalInterface").interface
local gameStarted = false
local printToConsole = zackUtils.printToConsole
local player = zackUtils.getPlayer()

local disableNPCs = false
local alreadyTPedPlayer = false
local function onActorActive(actor)
  if (playerSettings:get("DisableNPCs") == true) then
    actor.enabled = false
  end
end
local function transferAllItems(data)
  local from = data.from
  local to = data.to
end
local function stringToVector3(str)
  local values = {}
  local current = ""
  for i = 1, #str do
    local c = str:sub(i, i)
    if c == "," then
      table.insert(values, tonumber(current))
      current = ""
    else
      current = current .. c
    end
  end
  table.insert(values, tonumber(current))
  return util.vector3(values[1], values[2], values[3])
end
local function WriteToConsole(text, error)
  local player = world.players[1]

  player:sendEvent("WriteToConsoleEvent", { text = text, error = error })
end
local function showVars(obj)
  if not obj then
    local globalVars = world.mwscript.getGlobalVariables(player)
    for key, value in pairs(globalVars) do
      WriteToConsole(key .. " = " .. tostring(value))
    end
  else
    local localScr = world.mwscript.getLocalScript(obj, player)
    if not localScr then
      WriteToConsole("\"" .. obj.recordId .. "\" does not have a script.")
    else
      WriteToConsole("Local variables for \"" .. obj.recordId .. "\"")
      for key, value in pairs(localScr.variables) do
        WriteToConsole(key .. " = " .. tostring(value))
      end
    end
  end
end
local function printGlobalVarValue(val, pass)
  local globalVars = world.mwscript.getGlobalVariables(player)
  if globalVars[val] then
    WriteToConsole(tostring(globalVars[val]))
  end
end
local function readVarValues(data)
  --variables
  local globalVars = world.mwscript.getGlobalVariables(world.players[1])
  local varIDs = {}
  for index, value in pairs(globalVars) do
    table.insert(varIDs, index)
  end
  world.players[1]:sendEvent("loadVariables", varIDs)
  if data then
    printGlobalVarValue(data)
  end
end
local alreadySentEvent = false
local function generateGrid(playerPosition, iterations)
  -- Table to store grid positions
  local gridPositions = {}

  -- Extract player position components
  local playerX, playerY, playerZ = playerPosition.x, playerPosition.y, playerPosition.z
  local distance = 200
  -- Fixed Z position
  local fixedZ = playerZ + 5000

  -- Generate grid positions
  for x = -iterations, iterations do
    for y = -iterations, iterations do
      local newPosition = {
        x = playerX + (x * distance),
        y = playerY + (y * distance),
        z = fixedZ
      }
      table.insert(gridPositions, util.vector3(newPosition.x, newPosition.y, newPosition.z))
    end
  end

  return gridPositions
end

local function makeGridOfFargoth(num)
  local positions = generateGrid(world.players[1].position, num or 20)
  for i, x in ipairs(positions) do
    local fargoth = world.createObject("fargoth")
    local health = types.Actor.stats.dynamic.health(fargoth)
    --health.base = 10000
    fargoth:sendEvent("setStat",{type = "health",value = 10000})
    fargoth:teleport(world.players[1].cell, x,nil,{onGround = false})
    async:newUnsavableSimulationTimer(0.1,function ()
      fargoth:teleport(world.players[1].cell, x,nil,{onGround = false})
      
    end)
  end
end
local function onPlayerAdded(player)
  checkSupermanMode()
  --  print("Got in game")
  if core.getGameTime() > 205239 then
    gameStarted = true
    alreadyTPedPlayer = true
    return
  end
  if (alreadyTPedPlayer == false and playerSettings:get("TPAtStart")) then
    local newPos = stringToVector3(playerSettings:get("defaultPos"))
    local newCell = (playerSettings:get("defaultCell"))
    player:teleport(newCell, newPos)
    alreadyTPedPlayer = true
  end
  if (gameStarted == false) then
    player:sendEvent("onLoadEvent")
    gameStarted = true
  end
  local check = core.getGMST("Fonts_Font_0")

  readVarValues()
  local doCheck = playerSettings:get("CheckForTruetypeFonts")
  if doCheck and check ~= "MysticCards" then
    WriteToConsole("TrueType fonts are not in use!", true)
    error("TrueType fonts are not in use!")
  end
end
local function setGlobalVarValue(data)
  local valueName = data.valueName
  local valueNum = data.valueNum
  local globalVars = world.mwscript.getGlobalVariables(player)
  local currentValue = globalVars[valueName]
  if not currentValue then
    WriteToConsole("No variable " .. valueName, true)
  else
    globalVars[valueName] = valueNum
    WriteToConsole("Changed " .. valueName .. " from " .. tostring(currentValue) .. " to " .. tostring(valueNum))
  end
end
local function getFirstDoorPos(cell, doorNum)
  if (doorNum == nil) then
    doorNum = 1
  end
  local doors = cell:getAll(types.Door)
  local foundDoor = 1
  for i, record in ipairs(doors) do         --find the door with the cell we want
    if (types.Door.isTeleport(record)) then --and types.Door.destCell(record).name == cellname) then
      local scell = types.Door.destCell(record)
      local sdoors = scell:getAll(types.Door)
      for i, rsecord in ipairs(sdoors) do --find the doors inside so we can get back to the outside
        if (types.Door.isTeleport(rsecord) and types.Door.destCell(rsecord).name == cell.name) then
          if (foundDoor == doorNum) then
            return { position = types.Door.destPosition(rsecord), rotation = types.Door.destRotation(rsecord) }
          else
            foundDoor = foundDoor + 1
          end
        end
      end
    end
  end
  doors = cell:getAll(types.ESM4Door)
  print(#doors, cell.name)
  for i, record in ipairs(doors) do --find the door with the cell we want
    --  if (types.Door.isTeleport(record) and types.Door.destCell(record).name == cellname) then
    local scell = types.ESM4Door.destCell(record)
    if (scell ~= nil) then
      local sdoors = scell:getAll(types.ESM4Door)
      for i, rsecord in ipairs(sdoors) do --find the doors inside so we can get back to the outside
        if (types.ESM4Door.isTeleport(rsecord) and types.ESM4Door.destCell(rsecord).name == cell.name) then
          local xdestPos = types.ESM4Door.destPosition(rsecord)
          local xdestRot = types.ESM4Door.destRotation(rsecord)

          return { position = types.ESM4Door.destPosition(rsecord), rotation = types.ESM4Door.destRotation(rsecord) }
        end
      end
    end
  end
  if #cell:getAll(types.Static) == 0 then
    print("No door found, using the first object")
    return cell:getAll()[1]
  end
  print("No door found, using the first static")
  return cell:getAll(types.Static)[1]
end
local function getInventory(object)
  --Quick way to get the inventory of an object, regardless of type
  if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
    return types.Actor.inventory(object)
  elseif (object.type == types.Container) then
    return types.Container.content(object)
  end
  return nil --Not any of the above types, so no inv
end

local function DebugEmptyInto(data)
  if (data.source == nil) then
    WriteToConsole("No selected object", true)
    return
  end
  local sourceInv = getInventory(data.source)
  if (sourceInv == nil) then
    WriteToConsole("Selected object does not have a inventory", true)
    return
  end
  local itemsMoved = 0
  local targetInv = getInventory(data.target)
  for index, item in ipairs(sourceInv:getAll()) do
    itemsMoved = itemsMoved + item.count
    item:moveInto(targetInv)
  end
  WriteToConsole(string.format("Moved %i items", itemsMoved))
end
local exemptActors = {}
local function addActorToExemption(actor)
  exemptActors[actor.id] = actor.id
end
local function killAll(data)
  local player = nil
  local filterType = nil
  local killedActors = 0
  if (data ~= nil) then
    if (data.filterType == "Creature") then
      filterType = types.Creature
    end
  end

  for index, actor in ipairs(world.activeActors) do
    if (actor.type ~= types.Player and not exemptActors[actor.id]) then
      if ((filterType == nil or filterType == actor.type) and types.Actor.stats.dynamic.health(actor).current > 0) then
        killedActors = killedActors + 1
        actor:sendEvent("setStat", { type = "health", value = 0 })
      end
    elseif (player == nil) then
      player = actor
    end
  end
  player:sendEvent("WriteToConsoleEvent", { text = string.format("Killed %d actors", killedActors), error = false })

  if (filterType ~= nil) then

  end
end
local function setOwner(data)
  data.object.owner.recordId = data.newOwnerId
end
local function setOwnerFaction(data)
  data.object.owner.factionId = data.newOwnerId
end
local function getActorById(id)
  for i, ref in ipairs(world.activeActors) do
    if (ref.id == id) then
      return ref
    end
  end
end
local function DebugActorSwap(data)
  if (data.currentActor == nil) then
    print("ID is nil")
    return
  else
    print(data.currentActor)
  end
  local doClone = data.doClone
  local currentActor = getActorById(data.currentActor)
  if (doClone and true == false) then
    local eqItems = {}
    for i, record in pairs(types.Actor.getEquipment(currentActor)) do
      table.insert(eqItems, i, record.recordId)
    end

    core.sendGlobalEvent("ZackUtilsAddItems",
      {
        itemIds = types.Actor.getEquipment(currentActor),
        actorId = currentActor.recordId,
        equip = true,
        actor = currentActor
      })

    return
  end
  local newActorId = data.newActorId
  if (currentActor == nil) then
    print("Target is nil")
    return
  elseif currentActor.type ~= types.NPC and currentActor.type ~= types.Creature and currentActor.type ~= types.Player then
    print("Target is not an actor: " .. currentActor.recordId)
    return
  end
  if (newActorId == nil) then
    print("No new ID")
    return
  end
  local newActor = I.ZackUtilsG.ZackUtilsCreateInterface(newActorId, currentActor.cell.name, currentActor.position,
    currentActor.rotation)

  local equip = types.Actor.getEquipment(currentActor)
  local badInv = {}
  for i, record in ipairs(types.Actor.inventory(newActor):getAll()) do
    table.insert(badInv, { id = record.recordId, count = record.count })
  end
  if (doClone == true) then
    local eqItems = {}
    for i, record in pairs(types.Actor.getEquipment(currentActor)) do
      table.insert(eqItems, record.recordId)
    end
    core.sendGlobalEvent("ZackUtilsAddItems",
      { itemIds = eqItems, actor = newActor, equip = true
      })
  else
    for i, record in ipairs(types.Actor.inventory(currentActor):getAll()) do
      record:moveInto(types.Actor.inventory(newActor))
    end
  end

  newActor:sendEvent("setBadItems", badInv)
  newActor:sendEvent("setEquipment", equip)
  currentActor:sendEvent("ReturnActorSwap", newActor)
  if (doClone == nil or doClone == false) then
    currentActor:remove()
  end
end
local foundItems = {}

local function findItemIndex(object)
  for index, value in ipairs(foundItems) do
    if (value == object) then
      return index
    end
  end
end
local newType = nil
local newTarget
local delay = -1
local function purgePaintings()
  local cellname = "Hestatur"
  local removed = 0
  for index, cell in ipairs(world.cells) do
    if string.sub(cell.name:lower(), 1, 8) == "hestatur" then
      for x, object in ipairs(cell:getAll(types.Miscellaneous)) do
        local result = string.match(object.id, "_(.*)")
        if string.sub(object.recordId, 1, 9) == "spok_hpic" then
          object:remove()
          removed = removed + 1
        end
      end
    end
  end
  local libra = world.getCellByName("Hestatur, Library"):getAll(types.Container)
  for index, object in ipairs(libra) do
    if (object.id == "4302_12") then
      for index, rec in ipairs(types.Book.records) do
        if string.sub(rec.id, 1, 3) == "bk_" and rec.isScroll == false and rec.mwscript == "" then
          local count = math.random(0, 5)
          if (count > 0) then
            local item = world.createObject(rec.id, count)
            item:moveInto(types.Container.content(object))
            item = world.createObject(rec.id, count)
            item:moveInto(types.Actor.inventory(I.ZackUtilsG.getPlayer()))
          end
        end
      end
    end
  end
  printToConsole(string.format("Removed %d references", removed))
end
local function findRecordByName(name)
  local recordList = I.ZackUtilsG.findObjectRecordByName(name)

  printToConsole("Searching, please wait...", "Info")
  for index, record in ipairs(recordList) do
    printToConsole(string.format("%s: %s", record.name, record.id))
  end
  printToConsole(string.format("Found %d records", #recordList))
end
local function setNPCDisposition(data)
  types.NPC.setBaseDisposition(data.actor, player, data.value, player)
end
local function addItemCommand(data)
  if (player == nil) then
    player = zackUtils.getPlayer()
  end
  local id = data.id
  local count = data.count
  if (count == nil) then
    count = 1
  end
  local target = data.target
  local soul = data.soul
  local record, obType = zackUtils.findObjectRecord(id)
  if (obType == nil) then
    WriteToConsole("No record found for " .. id, true)
    return
  end
  if (obType.baseType ~= types.Item) then
    print(obType)
    WriteToConsole("Invalid record entered", true)
    return
  end
  local newOb = world.createObject(record.id, count)
  if (zackUtils.getInventory(target) == nil) then
    WriteToConsole("Invalid object selected, defaulting to player inventory", true)
    target = player
  end
  if newOb.type == types.Miscellaneous and soul then
    types.Miscellaneous.setSoul(newOb, soul)
  end
  local targetInv = zackUtils.getInventory(target)
  newOb:moveInto(targetInv)
  local result = string.format("Created %i item %s, inserted it into inventory of %s", count, obType.record(newOb).name,
    target.type.record(target).name)
  WriteToConsole(result)
end

local function findAllRefs(targetName) --need to do a ray cast if no int cell is found
  targetName = targetName:lower()
  printToConsole("Searching, please wait...", "Info")
  local recordList = I.ZackUtilsG.findObjectRecordByName(targetName)

  newTarget = I.ZackUtilsG.findObjectRecord(targetName)
  if (newTarget == nil) then
    WriteToConsole("Unable to find record")
    return
  end
  delay = 1
end

local function findNPCbyId(id)
  for cellIndex, cell in ipairs(world.cells) do
    for index, npc in ipairs(cell:getAll(types.NPC)) do
      if npc.id == id then
        WriteToConsole("NPC found in: " .. npc.cell.name .. ", " .. npc.recordId)
      end
    end
  end
end

local function findAllRefs(targetName) --need to do a ray cast if no int cell is found
  targetName = targetName:lower()
  printToConsole("Searching, please wait...", "Info")
  local recordList = I.ZackUtilsG.findObjectRecordByName(targetName)

  newTarget = I.ZackUtilsG.findObjectRecord(targetName)
  if (newTarget == nil) then
    WriteToConsole("Unable to find record")
    return
  end
  delay = 1
end
local function onFrame(dt)
  if (delay > -1) then
    delay = delay + 1
    if (delay > 20) then
      for index, cell in ipairs(world.cells) do
        local cellname = cell.name
        if (cellname == nil or cellname == "") then
          cellname = cell.region
        end
        if (newType ~= nil and newType.baseType == types.Item) then
          for index, record in ipairs(cell:getAll(types.Container)) do
            if (types.Container.content(record):find(newTarget.id)) then
              table.insert(foundItems, record)
              printToConsole(string.format("Found %s in container %s in cell %s (%s) #%d",
                newTarget.id, types.Container.record(record).name, cellname, record.id, findItemIndex(record)))
            end
          end
          for index, record in ipairs(cell:getAll(types.NPC)) do
            if (types.Actor.inventory(record):find(newTarget.id)) then
              table.insert(foundItems, record)
              printToConsole(string.format("Found %s in actor %s in cell %s (%s) #%d",
                newTarget.id, record.recordId, cellname, record.id, findItemIndex(record)))
            end
          end
        end
        for index, record in ipairs(cell:getAll(newTarget.id)) do
          if (record.recordId == newTarget.id) then
            table.insert(foundItems, record)
            printToConsole(string.format("Found %s in cell %s (%s) #%d", newTarget.id, cellname, record.id,
              findItemIndex(record)))
          end
        end
      end

      printToConsole("Search completed.", "Success")
      delay = -1
      newTarget = nil
    end
  end
end
local function moveToId(id)
  local player = zackUtils.getPlayer()
  for index, value in ipairs(foundItems) do
    if (value.id == id or tostring(id) == tostring(index)) then
      player:teleport(value.cell, value.position)

      return
    end
  end
end
local function purgeMod(data) --need to do a ray cast if no int cell is found
  local objectToTeleport = data.objectToTeleport
  local cellname = data.cellname
  local removed = 0
  for index, cell in ipairs(world.cells) do
    for x, object in ipairs(cell:getAll()) do
      local result = string.match(object.id, "_(.*)")
      if (result == data or data == "all") then
        --  object:remove()
        object.enabled = false
        removed = removed + 1
      end
    end
  end
  printToConsole(string.format("Removed %d references", removed))
end
local foundCells = {}
local function TeleportToCell(cell, objectToTeleport, doorNum)
  local target = getFirstDoorPos(cell, doorNum)

  if (target ~= nil) then
    objectToTeleport:teleport(cell, target.position, { onGround = true, rotation = target.rotation })
    objectToTeleport:sendEvent("WriteToConsoleEvent",
      { text = "Teleported to exact match, " .. cell.name, error = false })
    return
  else
    print("Target is nil!")
  end
end
local disabledObjects = {}

local function setDisabledDebug(data)
  local object = data.object
  local state = data.state

  object.enabled = state
end
local function showDisabled(cell)
  disabledObjects = {}
  local player = player
  cell = player.cell
  for index, value in ipairs(cell:getAll()) do
    if (value.enabled == false) then
      table.insert(disabledObjects, value)
    end
  end
  for index, value in ipairs(disabledObjects) do
    WriteToConsole(string.format("%s: #%s", value.recordId, tostring(index)))
  end
  if (#disabledObjects == 0) then
    WriteToConsole("No objects are disabled in this cell")
  end
end
local function getSerializableEquip(eq)
  local ret = {}
  for key, value in pairs(eq) do
    ret[key] = value.recordId
  end
  return ret
end
local actorOpening = nil
local tempCont = nil



local function returnToActor()
  --time to return items to the actor
  for index, value in ipairs(I.ZackUtilsG.getInventory(actorOpening):getAll()) do
    if (value.recordId ~= "zhac_slave_bracer_left") then
      value:remove()
    end
  end
  local tryEquip = {}
  for index, item in ipairs(I.ZackUtilsG.getInventory(tempCont):getAll()) do
    if item.type == types.Weapon or item.type == types.Clothing or item.type == types.Armor then
      if (item.type == types.Armor and (item.type.records[item.recordId].type == types.Armor.TYPE.LGauntlet or types.Armor.records[item.recordId].type == types.Armor.TYPE.LBracer)) then
        --don't equip armor in place of bracer
      elseif (item.type == types.Clothing and types.Clothing.records[item.recordId].type == types.Clothing.TYPE.LGlove) then
      else
        table.insert(tryEquip, item.recordId)
      end
    end
    item:moveInto(I.ZackUtilsG.getInventory(actorOpening))
  end
  table.insert(tryEquip, "zhac_slave_bracer_left")
  actorOpening:sendEvent("equipItems", tryEquip)
  actorOpening = nil
  tempCont:remove()
  tempCont = nil
end

local function onUpdate(dt)
  local selected = world.players[1]
  --selected:setPosition(util.vector3(selected.position.x,selected.position.y + 1,selected.position.z ))
  if (actorOpening ~= nil) then
    returnToActor()
  end
end

local function CompShare(actor)
  local offsetPos = util.vector3(actor.position.x, actor.position.y, -10000)
  local newCont = I.ZackUtilsG.ZackUtilsCreateInterface("zhac_compshare_cont", actor.cell.name, offsetPos)
  local tempItems = {}
  local itemsToMove = {}
  local oldEq = getSerializableEquip(types.Actor.getEquipment(actor))
  for index, item in ipairs(I.ZackUtilsG.getInventory(actor):getAll()) do
    item:moveInto(I.ZackUtilsG.getInventory(newCont))
    local tempItem = world.createObject(item.recordId)
    table.insert(tempItems, tempItem)
  end
  for index, item in ipairs(tempItems) do
    item:moveInto(I.ZackUtilsG.getInventory(actor))
  end
  newCont:activateBy(player)
  actor:sendEvent("setEquipment", oldEq)
  tempCont = newCont
  actorOpening = actor
end
local function TravelEvent(data)
  local objectToTeleport = data.objectToTeleport
  local cellname = data.cellname:lower()
  local printOnly = data.printOnly
  local doorNum = data.number
  for index, value in ipairs(I.Debugmode_Travel) do
    local cellNames = { value.travel1destcellname, value.travel2destcellname, value.travel3destcellname,
      value.travel4destcellname }
    local positions = { value.travel1dest, value.travel2dest, value.travel3dest, value.travel4dest }
    local rotations = { value.travel1destrot, value.travel2destrot, value.travel3destrot, value.travel4destrot }
    for indx, dest in ipairs(cellNames) do
      if (dest ~= nil and dest:lower() == cellname) then
        local pos = positions[indx]

        objectToTeleport:teleport(dest, util.vector3(pos.x, pos.y, pos.z),
          { onGround = true, rotation = createRotation(0, 0, math.rad(rotations[indx].z)) })
        objectToTeleport:sendEvent("WriteToConsoleEvent",
          { text = "Teleported to exact match, " .. dest, error = false })
        return
      end
    end
  end
end
local function fixRotation(rot)
  if (rot.getPitch == nil) then
    return rot
  else
    return rot:getAnglesZXY()
  end
end
local function removeQuotes(str)
  if (str == nil) then
    return nil
  end
  local result = string.gsub(str, "[\"]", "")
  return result
end
local function stealCell(cellName)
  local cellList = {}
  if not cellName then
    cellList = foundCells
  else
    table.insert(cellList, world.getCellByName(cellName))
  end
  local lootCount = 0

  local playerInv = getInventory(world.players[1])
  for index, cell in ipairs(cellList) do
    for index, value in ipairs(cell:getAll()) do
      if (value.type.baseType == types.Actor or value.type == types.Container) and value.type ~= types.Player then
        getInventory(value):resolve()
        local inv = getInventory(value):getAll()
        for index, item in ipairs(inv) do
          lootCount = item.count + lootCount
          item:moveInto(playerInv)
        end
      elseif value.type.baseType == types.Item and value.type ~= types.Light then
        lootCount = value.count + lootCount
        value:moveInto(playerInv)
      elseif value.type == types.Light and value.type.record(value).isCarriable then
        lootCount = value.count + lootCount
        value:moveInto(playerInv)
      end
    end
  end
  WriteToConsole("Looted " .. tostring(lootCount) .. " Items")
end
local function distanceBetweenPos(vector1, vector2)
  --Quick way to find out the distance between two vectors.
  --Very similar to getdistance in mwscript
  local dx = vector2.x - vector1.x
  local dy = vector2.y - vector1.y
  local dz = vector2.z - vector1.z
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end
local function Debug_RAEvent(force)
  local count = 0
  for index, actor in ipairs(world.activeActors) do
    local cpos = actor.position
    local opos = actor.startingPosition
    local dist = distanceBetweenPos(cpos, opos)
    if ((dist < 500 or force) and actor.type ~= types.Player) then
      actor:teleport(actor.cell, actor.startingPosition, { rotation = actor.startingRotation, onGround = true })
      count = count + 1
    end
  end
  WriteToConsole("Reset " .. tostring(count) .. " actors")
end
local function COCEvent(data) --need to do a ray cast if no int cell is found
  local objectToTeleport = data.objectToTeleport
  local cellname = data.cellname
  if cellname == nil then
    cellname = ""
  else
    cellname = cellname:lower()
  end
  local printOnly = data.printOnly
  local doorNum = data.number
  if (#foundCells > 0) then
    for index, value in ipairs(foundCells) do
      if (index == doorNum or value.name == cellname) then
        TeleportToCell(value, objectToTeleport)
        return
      end
    end
  end
  for index, value in ipairs(I.Debugmode_Travel) do
    local cellNames = { value.travel1destcellname, value.travel2destcellname, value.travel3destcellname,
      value.travel4destcellname }
    local positions = { value.travel1dest, value.travel2dest, value.travel3dest, value.travel4dest }
    local rotations = { value.travel1destrot, value.travel2destrot, value.travel3destrot, value.travel4destrot }
    for indx, dest in ipairs(cellNames) do
      if (dest ~= nil and dest:lower() == cellname) then
        local pos = positions[indx]
        if (core.API_REVISION > 39) then
          objectToTeleport:teleport(dest, util.vector3(pos.x, pos.y, pos.z),
            { onGround = true, rotation = createRotation(0, 0, math.rad(rotations[indx].z)) })
        else
        end
        objectToTeleport:sendEvent("WriteToConsoleEvent",
          { text = "Teleported to exact match, " .. dest, error = false })
        return
      end
    end
  end
  if (printOnly == nil) then
    for index, cell in ipairs(world.cells) do
      if cell and (removeQuotes(cell.name:lower()) == cellname) then
        TeleportToCell(cell, objectToTeleport)
        return
      end
    end
  else
    foundCells = {}
  end
  for index, cell in ipairs(world.cells) do
    if cell then
      local startPos, endPos = string.find(removeQuotes(cell.name:lower()), cellname)
      if (startPos) then
        if (printOnly) then
          table.insert(foundCells, cell)
        else
          local target = getFirstDoorPos(cell, doorNum)

          if (target ~= nil) then
            objectToTeleport:teleport(cell, target.position, { onGround = true, rotation = target.rotation })
            objectToTeleport:sendEvent("WriteToConsoleEvent",
              { text = "Teleported to nearest match, " .. cell.name, error = false })
            return
          else
            target = cell:getAll(types.Static)
            objectToTeleport:teleport(cell, target.position, { onGround = true, rotation = target.rotation })
            objectToTeleport:sendEvent("WriteToConsoleEvent",
              { text = "Teleported to nearest match, " .. cell.name, error = false })
            return
          end
          local target = getFirstDoorPos(cell, doorNum)

          if (target ~= nil) then
            objectToTeleport:sendEvent("WriteToConsoleEvent",
              { text = "Teleporting to nearest match, " .. cell.name, error = false })
            objectToTeleport:teleport(cell, target.position, { onGround = true, rotation = target.rotation })
            return
          else
            print("Target is nil!")
          end
        end
      end
    end
  end
  if (printOnly) then
    if (#foundCells == 0) then
      WriteToConsole("No cells match search term", true)
    end
    for index, cell in ipairs(foundCells) do
      objectToTeleport:sendEvent("WriteToConsoleEvent",
        { text = cell.name .. ", #" .. tostring(index), error = false })
    end
    return
  end
  objectToTeleport:sendEvent("WriteToConsoleEvent", { text = "Cell wasn't found! " .. cellname .. ".", error = true })
  print("Cell not found!")
end

local time = require('openmw_aux.time')
local calendar = require('openmw_aux.calendar')
local function setGameTime(desiredGameTime, scr)
  local scr = world.mwscript.getGlobalScript("zhac_cmdscr", world.players[1])
  local newMonth = tonumber(calendar.formatGameTime("%m", desiredGameTime)) - 1
  local newDaysPassed = math.floor(desiredGameTime / time.day)
  local newGameHour = tonumber(desiredGameTime - (newDaysPassed * time.day)) / time.hour
  local newDay = tonumber(calendar.formatGameTime("%d", desiredGameTime))
  print(newMonth, newGameHour, newDay, newDaysPassed)

  scr.variables.newMonth = newMonth
  scr.variables.newHour = newGameHour
  scr.variables.newDaysPassed = newDaysPassed
  scr.variables.newDay = newDay
  scr.variables.newGameHour = newGameHour
end
local function onLoad(data)
  gameStarted = true
  if (data ~= nil and data.blackList ~= nil) then
    blackList = data.blackList
  end
  alreadyTPedPlayer = true
end
local scrVer = 10
local function setPlayerPosition(pos, rotZ)
  local scr = world.mwscript.getGlobalScript("zhac_s_setppos", world.players[1])
  scr.variables.px = pos.x
  scr.variables.py = pos.y
  scr.variables.pz = pos.z
  scr.variables.pr = math.deg(rotZ)
  scr.variables.domove = 1
end
local function mwScriptBridge2(data)
  local cmdId = data.cmdId
  local valNum = data.valNum
  local scr = world.mwscript.getGlobalScript("zhac_cmdscr", world.players[1])
  if scr.variables.version < scrVer then
    WriteToConsole("omwaddon file is outdated!")
    error("omwaddon file is outdated!")
  end
  if cmdId == 5 then
    setGameTime(valNum)
  elseif valNum then
    scr.variables.valNum = valNum
  end
  scr.variables.cmdId = cmdId
end
local function mwScriptBridge2NoVal(cmdId)
  local scr = world.mwscript.getGlobalScript("zhac_cmdscr", world.players[1])
  if scr.variables.version < scrVer then
    WriteToConsole("omwaddon file is outdated!")
    error("omwaddon file is outdated!")
  end
  scr.variables.cmdId = cmdId
end
local function runMWscriptBridge(data)
  local player = data.player
  local recordId = data.recordId
  local desiredGameTime = data.desiredGameTime
  local holdingCell = world.getCellByName("_DebugModeHoldingCell")

  for index, gob in ipairs(holdingCell:getAll()) do
    if (gob.recordId == recordId) then
      gob:teleport(player.cell, player.position)
      if (gob.recordId == "zhac_debugmode_gametime") then
        gob:sendEvent("setGameTime", desiredGameTime)
      end
      return
    end
  end
end
local function setSetting(data)
  local key = data.key
  local value = data.value
  local player = data.player
  playerSettings:set(key, value)
  if (player and key == "defaultCell" or key == "defaultPos") then
    player:sendEvent("returnSetting", { key = key, value = value })
  end
  checkSupermanMode()
end
local function setCellScale(cell, scale)
  for index, obj in ipairs(cell:getAll()) do
    if (not obj:isValid()) then
      obj:setScale(0)
    else
      local oldScale = 1
      local newPos = util.vector3((obj.startingPosition.x * oldScale) * scale,
        (obj.startingPosition.y * oldScale) * scale,
        (obj.startingPosition.z * oldScale) * scale)
      obj:teleport(cell, newPos)
      obj:setScale(scale)
    end
  end
end
local function setObjScale(data)
  data.object:setScale(data.scale)
end
local function isBlackListed(object)
  print(#blackList)
  if (object:isValid() == false) then
    print(object.id .. "is not valid")
    return true
  end
  for index, value in ipairs(blackList) do
    if (value == object.id or value == object.recordId) then
      print(object.id .. "is  blacklisted")
      return true
    end
  end
  print(object.id .. "is not blacklisted")
  return false
end
local function isBlacklisted(id)

end
local function BlacklistAdd(object)
  if (object:isValid()) then
    table.insert(blackList, object.recordId)
    for index, value in ipairs(object.cell:getAll(object.type)) do
      if (value.recordId == object.recordId and value.count > 0) then
        value:remove()
      end
    end
  else
    WriteToConsole("Object unable to be disabled", true)
  end
end
local function moveCellUp(obj)
  local offset = 10000
  for index, value in ipairs(obj.cell:getAll()) do
    if (value:isValid()) then
      value:teleport(obj.cell, util.vector3(value.position.x, value.position.y, value.position.z + offset))
      I.ZackUtilsG.getPlayer():teleport(obj.cell,
        util.vector3(value.position.x, value.position.y, value.position.z + offset))
    end
  end
end
local function getFoundCells()
  return foundCells
end
local function onSave(data)
  return { gameStarted = gameStarted, blackList = blackList, }
end
local function ZHAC_setLockLevel(data)
  local level = data.level
  local unlock = data.unlock
  local object = data.object

  if (level > 0) then
    object.type.lock(object, level)
  else
    object.type.unlock(object)
    object.type.setTrapSpell(object, nil)
  end
end

local function DoUnlock(object)
  ZHAC_setLockLevel({ level = 0, unlock = true, object = object })
end
local safeGuardTriggered = false
local function safeGuard()
  if (playerSettings:get("EnableSafeguard") == false) then return end
  if safeGuardTriggered then
    return false
  end
  if world.players[1].cell.name == "Imperial Prison Ship" then
    local errorM = string.format(
      "Safeguard attempted to prevent damage to real save, player is in starting prison ship"
    )
    safeGuardTriggered = true
    WriteToConsole(errorM, true)
    --error(errorM)
    return false
  end
  -- This function attemps to prevent execution of commands that will permenently damage a world.
  local gt = core.getGameTime()
  local days = gt / time.day

  local playerName = types.NPC.record(world.players[1]).name

  if string.sub(types.NPC.record(world.players[1]).name:lower(), 1, 6) ~= "player" then
    local errorM = string.format(
      "Safeguard attempted to prevent damage to real save, player name does not start with player, but is %s",
      playerName)
    safeGuardTriggered = true
    WriteToConsole(errorM, true)
    --error(errorM)
    return false
  end

  if (days > 7) then
    local errorM = string.format(
      "Safeguard attempted to prevent damage to real save, dayspassed is %i",
      days)
    safeGuardTriggered = true
    WriteToConsole(errorM, true)
    --error(errorM)
    return false
  else
    print(days, " passed")
  end

  return true
end
local function activateLockable(object, actor)
  if playerSettings:get("UnlockActivate") == true and safeGuard() == true then
    if object.type.isLocked(object) or object.type.getTrapSpell(object) ~= nil then
      ZHAC_setLockLevel({ level = 0, unlock = true, object = object })
    end
  end
  return true
end
local function countCells()
  local lockedNoKeys = 0
  local lockedWithKeys = 0

  for index, cell in ipairs(world.cells) do
    for index, obj in ipairs(cell:getAll()) do
      if obj.type == types.Door or obj.type == types.Container then
        if types.Lockable.isLocked(obj) then
          if types.Lockable.getKeyRecord(obj) then
            lockedWithKeys = lockedWithKeys + 1
          else
            lockedNoKeys = lockedNoKeys + 1
          end
        end
      end
    end
  end
  print("Locked With no key", lockedNoKeys)
  print("Locked With  key", lockedWithKeys)
end
local function dropAll(actor)
  if not actor then
    actor = world.players[1]
  end
  local inv = getInventory(actor)
  if not inv then
    return
  end
  for index, item in ipairs(inv:getAll()) do
    item:teleport(actor.cell, actor.position)
  end
end
local function cellCreateTest()
  local newCell = world.createInteriorCell('new_cell_id', true) -- takes in a cell id (string) and a value to force load the cell (boolean), returns the created cell
  local obj = world.createObject('ex_t_rock_coastal_01')
  obj:teleport('new_cell_id', util.vector3(0, 0, 0))
  world.players[1]:teleport(newCell.id, util.vector3(0, 0, 0))
end
--I.Activation.addHandlerForType(types.Container, activateLockable)
--I.Activation.addHandlerForType(types.Door, activateLockable)
return {
  interfaceName  = "DebugModeGlobal",
  interface      = {
    version = 1,
    CompShare = CompShare,
    getFoundCells = foundCells,
    setCellScale = setCellScale,
    moveCellUp = moveCellUp,
    isBlackListed = isBlackListed,
    setPlayerPosition = setPlayerPosition,
  },
  engineHandlers = {
    onActorActive = onActorActive,
    onPlayerAdded = onPlayerAdded,
    onLoad = onLoad,
    onUpdate = onUpdate,
    onSave = onSave,
  },
  eventHandlers  = {
    setNPCDisposition = setNPCDisposition,
    CompShare = CompShare,
    dropAll = dropAll,
    makeGridOfFargoth = makeGridOfFargoth,
    readVarValues = readVarValues,
    printGlobalVarValue = printGlobalVarValue,
    setGlobalVarValue = setGlobalVarValue,
    Debug_RAEvent = Debug_RAEvent,
    cellCreateTest = cellCreateTest,
    showVars = showVars,
    setSetting = setSetting,
    addActorToExemption = addActorToExemption,
    runMWscriptBridge = runMWscriptBridge,
    COCEvent = COCEvent,
    killAll = killAll,
    DebugActorSwap = DebugActorSwap,
    DoUnlock = DoUnlock,
    setOwner = setOwner,
    setOwnerFaction = setOwnerFaction,
    findAllRefs = findAllRefs,
    moveToId = moveToId,
    onFrame = onFrame,
    stealCell = stealCell,
    findNPCbyId = findNPCbyId,
    ZHAC_setLockLevel = ZHAC_setLockLevel,
    setCellScale = setCellScale,
    purgeMod = purgeMod,
    findRecordByName = findRecordByName,
    showDisabled = showDisabled,
    setDisabledDebug = setDisabledDebug,
    addItemCommand = addItemCommand,
    DebugEmptyInto = DebugEmptyInto,
    purgePaintings = purgePaintings,
    TravelEvent = TravelEvent,
    setObjScale = setObjScale,
    BlacklistAdd = BlacklistAdd,
    mwScriptBridge2 = mwScriptBridge2,
    mwScriptBridge2NoVal = mwScriptBridge2NoVal,
    countCells = countCells,
  },
}
