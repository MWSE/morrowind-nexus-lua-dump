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


local zackUtils = require("scripts.ZackUtils.GlobalInterface").interface
local gameStarted = false
local printToConsole = zackUtils.printToConsole
local player = zackUtils.getPlayer()

local disableNPCs = false
local alreadyTPedPlayer = false
local function onActorActive(actor)
  print("actor active")
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
  local player = player

  player:sendEvent("WriteToConsoleEvent", { text = text, error = error })
end
local alreadySentEvent = false
local function onPlayerAdded(player)
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
end
local function getFirstDoorPos(cell)
  local doors = cell:getAll(types.Door)
  for i, record in ipairs(doors) do --find the door with the cell we want
    --  if (types.Door.isTeleport(record) and types.Door.destCell(record).name == cellname) then
    local scell = types.Door.destCell(record)
    local sdoors = scell:getAll(types.Door)
    for i, rsecord in ipairs(sdoors) do --find the doors inside so we can get back to the outside
      if (types.Door.isTeleport(rsecord) and types.Door.destCell(rsecord).name == cell.name) then
        local xdestPos = types.Door.destPosition(rsecord)
        local xdestRot = types.Door.destRotation(rsecord)

        return { position = types.Door.destPosition(rsecord), rotation = types.Door.destRotation(rsecord) }
      end
    end
    -- end
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
  return nil
end
local function getInventory(object)
  --Quick way to get the inventory of an object, regardless of type
  if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
    return types.Actor.inventory(object)
  elseif (object.type == types.Container) then
    return types.Container.content(object)
  end
  return nil   --Not any of the above types, so no inv
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
    if (actor.type ~= types.Player) then
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
  data.object.ownerRecordId = data.newOwnerId
end
local function setOwnerFaction(data)
  data.object.ownerFactionId = data.newOwnerId
end
local function DoUnlock(object)
  if (object.type == types.Door and types.Door.isTeleport(object)) then
    player:teleport(types.Door.destCell(object), types.Door.destPosition(object),
      { rotation = types.Door.destRotation(object), onGround = true })
    return
  end
  local newObject = world.createObject(object.recordId)

  newObject:teleport(object.cell, object.position, object.rotation)
  if (object.type == types.Container) then
    for index, item in ipairs(types.Container.content(object):getAll()) do
      item:moveInto(types.Container.content(newObject))
    end
  end
  object:remove()
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
local function findRecordByName(name)
  local recordList = I.ZackUtilsG.findObjectRecordByName(name)

  printToConsole("Searching, please wait...", "Info")
  for index, record in ipairs(recordList) do
    printToConsole(string.format("%s: %s", record.name, record.id))
  end
  printToConsole(string.format("Found %d records", #recordList))
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
  local record, obType = zackUtils.findObjectRecord(id)
  if (obType == nil) then
    WriteToConsole("No record found", true)
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
  local player = player
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
        object:remove()
        removed = removed + 1
      end
    end
  end
  printToConsole(string.format("Removed %d references", removed))
end
local foundCells = {}
local function TeleportToCell(cell, objectToTeleport)
  local target = getFirstDoorPos(cell)

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
      if (item.type == types.Armor and (item.type.record(item).type == types.Armor.TYPE.LGauntlet or types.Armor.record(item).type == types.Armor.TYPE.LBracer)) then
        --don't equip armor in place of bracer
      elseif (item.type == types.Clothing and types.Clothing.record(item).type == types.Clothing.TYPE.LGlove) then
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

local function COCEvent(data) --need to do a ray cast if no int cell is found
  local objectToTeleport = data.objectToTeleport
  local cellname = data.cellname
  local printOnly = data.printOnly

  if (#foundCells > 0) then
    for index, value in ipairs(foundCells) do
      if (tostring(index) == cellname or value.name == cellname) then
        TeleportToCell(value, objectToTeleport)
        return
      end
    end
  end
  if (printOnly == nil) then
    for index, cell in ipairs(world.cells) do
      if (cell.name:lower() == cellname:lower()) then
        TeleportToCell(cell, objectToTeleport)
        return
      end
    end
  else
    foundCells = {}
  end
  for index, cell in ipairs(world.cells) do
    local startPos, endPos = string.find(cell.name:lower(), cellname:lower())
    if (startPos) then
      if (printOnly) then
        table.insert(foundCells, cell)
      else
        local target = getFirstDoorPos(cell)

        if (target ~= nil) then
          objectToTeleport:teleport(cell, target.position, { onGround = true, rotation = target.rotation })
          objectToTeleport:sendEvent("WriteToConsoleEvent",
            { text = "Teleported to nearest match, " .. cell.name, error = false })
          return
        else
          print("Target is nil!")
        end
        local target = getFirstDoorPos(cell)

        if (target ~= nil) then
          objectToTeleport:teleport(cell, target.position, { onGround = true, rotation = target.rotation })
          objectToTeleport:sendEvent("WriteToConsoleEvent",
            { text = "Teleported to nearest match, " .. cell.name, error = false })
          return
        else
          print("Target is nil!")
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
  objectToTeleport:sendEvent("WriteToConsoleEvent", { text = "Cell wasn't found!", error = true })
  print("Cell not found!")
end

local function onLoad(data)
  gameStarted = true
  alreadyTPedPlayer = true
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
end
local function getFoundCells()
return foundCells
end
local function onSave(data)
return {gameStarted = gameStarted}
end
return {
  interfaceName  = "DebugModeGlobal",
  interface      = {
    version = 1,
    CompShare = CompShare,
    getFoundCells = foundCells
  },
  engineHandlers = {
    onActorActive = onActorActive,
    onPlayerAdded = onPlayerAdded,
    onLoad = onLoad,
    onUpdate = onUpdate,
  },
  eventHandlers  = {
    CompShare = CompShare,
    setSetting = setSetting,
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
    purgeMod = purgeMod,
    findRecordByName = findRecordByName,
    showDisabled = showDisabled,
    setDisabledDebug = setDisabledDebug,
    addItemCommand = addItemCommand,
    DebugEmptyInto = DebugEmptyInto,
  },
}
