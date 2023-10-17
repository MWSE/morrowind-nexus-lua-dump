-- TODO write code without a single comment - done
local core = require('openmw.core')
if not core.contentFiles.has(require("scripts.an_unexpected_start.modData").addonFileName) then
    return
end

local world = require('openmw.world')
local async = require('openmw.async')
local types = require('openmw.types')
local util = require('openmw.util')
local time = require('openmw_aux.time')
local Activation = require('openmw.interfaces').Activation
local commands = require("scripts.an_unexpected_start.scriptCommands")

local this = {}

local chargenNPCs = {
    ["chargen captain"] = {ref = nil, cell = {id = "Seyda Neen, Census and Excise Office", x = nil, y = nil, position = util.vector3(1366.27,-380.32,195.75)}, orientation = nil},
    ["chargen class"] = {ref = nil, cell = {id = "Seyda Neen, Census and Excise Office", x = nil, y = nil, position = util.vector3(242.30,-111.06,211.02)}, orientation = nil},
    ["usbd_chargen dock guard alt"] = {ref = nil, shouldDeleted = true, cell = {id = nil, x = -2, y = -9, position = util.vector3(-9797.83,-72522.74,125.52)}, orientation = nil},
    ["chargen name"] = {ref = nil, cell = {id = "Imperial Prison Ship", x = nil, y = nil, position = util.vector3(17.80,-66.11,-103.26)}, orientation = nil},
}
local chargenNPCs_count = 4

local defaultChargenCells = {
    ["Seyda Neen, Census and Excise Office"] = {id = "Seyda Neen, Census and Excise Office", position = util.vector3(0,0,0)},
    ["-2, -9"] = {x = -2, y = -9, position = util.vector3(-9797.83,-72522.74,125.52)},
}
local objectIdsToFinishScript = {
    ["chargen door captain"] = {{name = "done", val = 1}},
    ["chargen exit door"] = {{name = "done", val = 1}},
    ["chargen_shipdoor"] = {{name = "done", val = 1}},
    ["chargendoorjournal"] = {{name = "done", val = 1}},
    ["chargen barrel fatigue"] = {{name = "done", val = 1}},
    ["chargen door guard"] = {{name = "done", val = 1}},
    ["chargen class"] = {{name = "state", val = -1}},
    ["chargen captain"] = {{name = "done", val = 1}, {name = "state", val = -1}},
}
local chargenStatsSheet = "chargen statssheet"
local objectsToDeleteInChargenCell = {
    [chargenStatsSheet] = true,
}
local doorsToUnlockInChargenCell = {
    ["chargen door hall"] = true,
}

local guardRecords = {
    ["imperial guard"] = true,
}
local guards = {}
for id, _ in pairs(guardRecords) do
    table.insert(guards, id)
end

local config
if not config then
    config = {
        enabled = true,
        chanceToSpawnGuard = 0.5,
        spawnGuards = true,
        lockExit = false,
        onlyInACity = false,
    }
end

local state = 10 -- 10 when done

local mainQuestName = "a1_1_findspymaster"

local readyMessage = "You are ready to go."

local objectIdsToRemove = {} -- for guards

local newCell
local lastPlayerCellName

local loadStatus = {newGame = false, configLoaded = false}

local teleportionQueue = {}


function this.isInterior(cell)
    if cell and (cell.isExterior or cell:hasTag("QuasiExterior")) then
        return false
    end
    return true
end

function this.distance(vector1, vector2)
    local  a = (vector1.x - vector2.x)
    local  b = (vector1.y - vector2.y)
    local  c = (vector1.z - vector2.z)
    return math.sqrt(a * a + b * b + c * c)
end

function this.get2DDistance(vector1, vector2)
    if not vector1 or not vector2 then return 0 end
    return math.sqrt((vector2.x - vector1.x) ^ 2 + (vector2.y - vector1.y) ^ 2)
end

function this.faceActorToActor(actor, target)
    local vector1 = actor.position
    local vector2 = target.position
    local angle = math.atan2(vector2.x - vector1.x, vector2.y - vector1.y) ---@diagnostic disable-line: deprecated
    local rot = util.transform.rotateZ(angle)
    actor:teleport(actor.cell, vector1, {rotation = rot}) ---@diagnostic disable-line: unused-function, undefined-field
end

local initialData = {}

function this.saveInitialData(cell)
    if not cell then return end
    local saveActorData = function(ref)
        initialData[ref.id] = {}
        initialData[ref.id].enabled = ref.enabled
    end
    for _, ref in pairs(cell:getAll(types.NPC)) do
        saveActorData(ref)
    end
    for _, ref in pairs(cell:getAll(types.Creature)) do
        saveActorData(ref)
    end
    for _, ref in pairs(cell:getAll(types.Door)) do
        initialData[ref.id] = {}
        initialData[ref.id].enabled = ref.enabled
        initialData[ref.id].key = types.Lockable.getKeyRecord(ref)
        initialData[ref.id].lock = types.Lockable.getLockLevel(ref)
        initialData[ref.id].trap = types.Lockable.getTrapSpell(ref)
    end
end

function this.restoreInitialDataInChargenCell(cell)
    if not cell then return end
    for _, ref in pairs(cell:getAll(types.Door)) do
        if doorsToUnlockInChargenCell[ref.recordId] then
            types.Lockable.unlock(ref)
        end
    end
    for _, ref in pairs(cell:getAll()) do
        if objectsToDeleteInChargenCell[ref.recordId] then
            ref:remove()
        elseif objectIdsToFinishScript[ref.recordId] then
            local script = world.mwscript.getLocalScript(ref, world.players[1])
            if script then
                local variables = script.variables
                local vars = objectIdsToFinishScript[ref.recordId]
                for _, data in pairs(vars) do
                    if variables[data.name] then
                        variables[data.name] = data.val
                    end
                end
            end
        end
    end
end

function this.disableRemainingActors(cell)
    local disable = function(actor)
        if not chargenNPCs[actor.recordId] and not guardRecords[actor.recordId] and not initialData[actor.id] and
                types.Actor.stats.dynamic.health(actor).current > 0 then
            initialData[actor.id] = {}
            initialData[actor.id].enabled = actor.enabled
            actor.enabled = false
        end
    end
    for _, ref in pairs(cell:getAll(types.NPC)) do
        disable(ref)
    end
    for _, ref in pairs(cell:getAll(types.Creature)) do
        disable(ref)
    end
end

function this.resoreInitialData(cell)
    if not cell then return end
    local restoreActorData = function(ref)
        if initialData[ref.id] then
            ref.enabled = initialData[ref.id].enabled
            initialData[ref.id] = nil
        end
    end
    for _, ref in pairs(cell:getAll(types.NPC)) do
        restoreActorData(ref)
    end
    for _, ref in pairs(cell:getAll(types.Creature)) do
        restoreActorData(ref)
    end
    for _, ref in pairs(cell:getAll(types.Door)) do
        if initialData[ref.id] then
            ref.enabled = initialData[ref.id].enabled
            if initialData[ref.id].key then
                types.Lockable.setKeyRecord(ref, initialData[ref.id].key)
            end
            if types.Lockable.getLockLevel(ref) ~= initialData[ref.id].lock then
                if initialData[ref.id].lock == 0 then
                    types.Lockable.unlock(ref)
                else
                    types.Lockable.lock(ref, initialData[ref.id].lock)
                end
            end
            if initialData[ref.id].trap then
                types.Lockable.setTrapSpell(ref, initialData[ref.id].trap)
            end
            initialData[ref.id] = nil
        end
    end
    for _, ref in pairs(cell:getAll()) do
        if objectIdsToRemove[ref.id] then ref:remove() end
    end
end

function this.teleportToNextPositionInQueue()
    if #teleportionQueue > 0 then
        local cellData = teleportionQueue[1].cellData
        local cell = cellData.id and world.getCellByName(cellData.id) or world.getExteriorCell(cellData.x, cellData.y)
        table.remove(teleportionQueue, 1)
        world.players[1]:teleport(cell, cellData.position)
    end
end

function this.prepareChargenCompletion()
    for id, data in pairs(chargenNPCs) do
        if data.shouldDeleted then
            -- data.ref:remove() ---@diagnostic disable-line: unused-function, undefined-field
            data.ref.enabled = false ---@diagnostic disable-line: unused-function, undefined-field, inject-field
        else
            if not data.cellRef then goto continue end
            data.ref:teleport(data.cellRef, data.position, {rotation = data.rotation, onGround = true}) ---@diagnostic disable-line: unused-function, undefined-field
        end
        ::continue::
    end
    for cellName, cellPosData in pairs(defaultChargenCells) do
        table.insert(teleportionQueue, {cellData = cellPosData})
    end
    local playerCell = world.players[1].cell
    local playerPos = world.players[1].position
    table.insert(teleportionQueue, {cellData = {
        id = not playerCell.isExterior and playerCell.id or nil,
        x = playerCell.isExterior and playerCell.gridX,
        y = playerCell.isExterior and playerCell.gridY,
        position = util.vector3(playerPos.x, playerPos.y, playerPos.z)
    }})
    world.players[1]:addScript("scripts/an_unexpected_start/teleportedHandler.lua")
    this.teleportToNextPositionInQueue()
end

function this.finishCharacterGeneration()
    this.enableAllControls()
    this.prepareChargenCompletion()
    this.resoreInitialData(newCell)
    commands.finishChargen()
    world.players[1]:sendEvent("usbd_removeLevitationScript")
    if state < 10 then
        local tm
        tm = time.runRepeatedly(function()
            if state < 10 then
                this.exitDoorActivation(nil, world.players[1])
            else
                tm()
            end
        end, 1 * time.second, {})
    end
end

function this.enableAllControls()
    commands.enableControls()
end

function this.getBackDoor(door)
    if types.Door.objectIsInstance(door) and types.Door.isTeleport(door) then
        local cell = types.Door.destCell(door)
        if not cell then return end
        local nearestDoor = nil
        local distance = math.huge
        local doorDestPos = types.Door.destPosition(door)
        for _, cdoor in pairs(cell:getAll(types.Door)) do
            if types.Door.isTeleport(cdoor) then
                local distBetween = this.distance(doorDestPos, cdoor.position)
                if types.Door.isTeleport(cdoor) and distBetween < distance then
                    distance = distBetween
                    nearestDoor = cdoor
                end
            end
        end
        return nearestDoor
    end
end

function this.onSimulate()
    if chargenNPCs["chargen name"].ref and state == 2 then
        local script = world.mwscript.getLocalScript(chargenNPCs["chargen name"].ref, world.players[1])
        if script then
            local variables = script.variables
            if variables and variables["state"] == 20 then
                world.players[1]:sendEvent('usbd_enableControls', {control = "Controls", value = true})
                world.players[1]:sendEvent('usbd_enableControls', {control = "Jumping", value = true})
                if chargenNPCs["usbd_chargen dock guard alt"].ref then
                    local npc = chargenNPCs["usbd_chargen dock guard alt"].ref
                        async:newUnsavableSimulationTimer(5 + math.max(0, 4 - this.get2DDistance(npc.position, world.players[1].position) / 200), function()
                        local tm
                        tm = time.runRepeatedly(function()
                            if state < 4 and npc and npc:isValid() then
                                npc:sendEvent('StartAIPackage', {type='Travel', destPosition = world.players[1].position})
                            else
                                tm()
                            end
                        end, 1 * time.second, {})
                    end)
                end
                state = state < 3 and 3 or state
            end
        end
    end
    if chargenNPCs["chargen class"].ref then
        local script = world.mwscript.getLocalScript(chargenNPCs["chargen class"].ref, world.players[1])
        if script then
            local variables = script.variables
            if variables and state >= 3 and state < 9 and variables["state"] then
                local value = variables["state"]
                if value == 10 and state < 6 then
                    -- this.faceActorToActor(chargenNPCs["chargen class"].ref, world.players[1])
                    -- this.faceActorToActor(chargenNPCs["usbd_chargen dock guard alt"].ref, world.players[1])
                    state = state < 6 and 6 or state
                elseif value == 30 then
                    local item = world.createObject(chargenStatsSheet, 1)
                    item:moveInto(types.Actor.inventory(world.players[1]))
                    local pos = chargenNPCs["chargen captain"].ref.position ---@diagnostic disable-line: undefined-field, need-check-nil
                    chargenNPCs["usbd_chargen dock guard alt"].ref:sendEvent('StartAIPackage', {type='Travel', destPosition = pos}) ---@diagnostic disable-line: undefined-field, need-check-nil
                    state = state < 8 and 8 or state
                    variables["state"] = -1
                end
            end
        end
    end
    if chargenNPCs["usbd_chargen dock guard alt"].ref and chargenNPCs["chargen class"].ref and state >= 3 and state < 5 then
        local script = world.mwscript.getLocalScript(chargenNPCs["usbd_chargen dock guard alt"].ref, world.players[1])
        if script then
            local variables = script.variables
            if variables and variables["state"] then
                local value = variables["state"]
                if state == 3 and value == 30 then
                    state = state < 4 and 4 or state
                elseif value == 50 and state == 4 then
                    local ref = chargenNPCs["usbd_chargen dock guard alt"].ref
                    local pos = chargenNPCs["chargen class"].ref.position ---@diagnostic disable-line: undefined-field, need-check-nil
                    async:newUnsavableSimulationTimer(7, function()
                        if ref and ref:isValid() then
                            ref:sendEvent('StartAIPackage', {type='Travel', destPosition = pos}) ---@diagnostic disable-line: undefined-field, need-check-nil
                        end
                    end)
                    state = state < 5 and 5 or state
                end
            end
        end
    end
    if chargenNPCs["chargen captain"].ref and state == 8  then
        local quests = types.Player.quests(world.players[1])
        local isMainQuestStarted = false
        for _, quest in pairs(quests) do
            if quest.id == mainQuestName then
                isMainQuestStarted = true
                break
            end
        end
        if isMainQuestStarted then
            local doors = {}
            for _, door in pairs(world.players[1].cell:getAll(types.Door)) do
                if types.Door.isTeleport(door) and not this.isInterior(types.Door.destCell(door)) then
                    types.Lockable.unlock(door)
                    table.insert(doors, door)
                end
            end
            this.enableAllControls()
            state = 10
            if #doors > 0 and chargenNPCs["chargen captain"].ref then
                local destDoor = doors[math.random(#doors)]
                if destDoor then
                    local nearestDoor = nil
                    local distanceToDestRef = math.huge
                    for _, ref in pairs(world.players[1].cell:getAll(types.Door)) do
                        local dist = this.distance(ref.position, destDoor.position)
                        if distanceToDestRef > dist then
                            nearestDoor = ref
                            distanceToDestRef = dist
                        end
                    end
                    if nearestDoor then
                        local backDoor = this.getBackDoor(nearestDoor)
                        local pos = backDoor and types.Door.destPosition(backDoor) or nearestDoor.position
                        chargenNPCs["chargen captain"].ref:sendEvent('StartAIPackage', {type='Travel', destPosition = pos}) ---@diagnostic disable-line: undefined-field, need-check-nil
                    end
                end
            end
        end
    end
    if lastPlayerCellName ~= world.players[1].cell.name and lastPlayerCellName == newCell.name then
        this.finishCharacterGeneration()
    end
    lastPlayerCellName = world.players[1].cell.name
    if types.Player.isCharGenFinished(world.players[1]) then
        this.simulateTimer() -- stop the timer
    end
end

function this.exitDoorActivation(door, actor)
    if actor.type ~= types.Player then return end
    if state > 0 and state < 10 then
        if state < 5 then
            commands.raceMenu()
            state = 5
            return false
        end
        if state < 7 then
            commands.classMenu()
            state = 7
            return false
        end
        if state < 8 then
            commands.birthMenu()
            state = 8
            this.enableAllControls()
            return false
        end
        if state < 9 then
            commands.statReviewMenu()
            state = 10
            local inventory = types.Actor.inventory(actor)
            local statsSheetCount = inventory:countOf(chargenStatsSheet)
            if statsSheetCount > 0 then
                inventory:find(chargenStatsSheet):remove(statsSheetCount)
            end
            commands.addFindspymasterQuest()
            async:newUnsavableSimulationTimer(0.2, function()
                world.players[1]:sendEvent("usbd_showMessage", {message = readyMessage})
            end)
            return false
        end
        state = 10
    end
end

function this.prepareCell(cell)
    this.saveInitialData(cell)
    chargenNPCs["chargen name"].ref = nil
    chargenNPCs["chargen class"].ref = nil
    chargenNPCs["usbd_chargen dock guard alt"].ref = nil
    chargenNPCs["chargen captain"].ref = nil
    local chargenNPCIds = {"chargen name", "usbd_chargen dock guard alt", "chargen class", "chargen captain"}
    do
        local refForSpot = {}
        for _, ref in pairs(cell:getAll(types.NPC)) do
            if types.Actor.stats.dynamic.health(ref).current > 0 then
                ref.enabled = false
                table.insert(refForSpot, ref)
            end
        end
        for _, ref in pairs(cell:getAll(types.Creature)) do
            if types.Actor.stats.dynamic.health(ref).current > 0 then
                ref.enabled = false
                table.insert(refForSpot, ref)
            end
        end
        local chargenNamePos
        for _, id in ipairs(chargenNPCIds) do
            local params = chargenNPCs[id]
            if not params then goto continue end
            local oldRefId = math.random(#refForSpot)
            local oldRef = refForSpot[oldRefId]
            if id == "usbd_chargen dock guard alt" and chargenNamePos then
                local minDistance = math.huge
                for refPos, ref in pairs(refForSpot) do
                    local mul = math.floor(math.abs(ref.position.z - chargenNamePos.z) / 100)
                    local distance = this.get2DDistance(ref.position, chargenNamePos) + 1000 * mul
                    if distance < minDistance and distance > 150 then
                        minDistance = distance
                        oldRefId = refPos
                        oldRef = ref
                    end
                end
            end
            local npcCell = params.cell.id and world.getCellByName(params.cell.id) or world.getExteriorCell(params.cell.x, params.cell.y)
            if not npcCell then goto continue end
            local newRef = nil
            for _, ref in pairs(npcCell:getAll(types.NPC)) do
                if ref.recordId == id then newRef = ref break end
            end
            if chargenNPCs[id].shouldDeleted then
                newRef = world.createObject(id, 1)
            end
            if not newRef then goto continue end
            if chargenNPCs[id] then
                chargenNPCs[id].ref = newRef
                chargenNPCs[id].position = newRef.position
                chargenNPCs[id].rotation = newRef.rotation
                chargenNPCs[id].cellRef = newRef.cell
            end
            newRef:teleport(cell, oldRef.position, {rotation = oldRef.rotation, onGround = true})
            if id == "chargen name" then chargenNamePos = oldRef.position end
            table.remove(refForSpot, oldRefId)
            if #refForSpot == 0 then break end
            ::continue::
        end
        for _, ref in pairs(refForSpot) do
            if math.random() < config.chanceToSpawnGuard then
                local guard = world.createObject(guards[math.random(#guards)], 1)
                guard:teleport(cell, ref.position, {rotation = ref.rotation, onGround = true})
                objectIdsToRemove[guard.id] = true
            end
        end
    end
    if chargenNPCs["chargen name"].ref then
        for _, door in pairs(cell:getAll(types.Door)) do
            if types.Door.isTeleport(door) and (config.lockExit or this.isInterior(types.Door.destCell(door))) then
                types.Lockable.lock(door, 100)
            else
                types.Lockable.unlock(door)
            end
            if types.Door.isTeleport(door) and not config.lockExit and not this.isInterior(types.Door.destCell(door)) then
                door:teleport(cell, door.position, {rotation = door.rotation})
                Activation.addHandlerForObject(door, this.exitDoorActivation)
            end
            types.Lockable.setTrapSpell(door, nil)
            types.Lockable.setKeyRecord(door, nil)
        end

        world.players[1]:addScript("scripts/an_unexpected_start/levitation.lua")
        chargenNPCs["chargen name"].ref:sendEvent("usbd_teleportToAndRotate", {reference = world.players[1]}) ---@diagnostic disable-line: undefined-field, need-check-nil
        state = state < 2 and 2 or state
        this.simulateTimer = time.runRepeatedly(this.onSimulate, 0.1 * time.second, {})
        async:newUnsavableSimulationTimer(5, function()
            this.disableRemainingActors(cell)
        end)
    end
end

function this.toRandomCell()
    local cells = {}
    for _, cell in pairs(world.cells) do
        if not this.isInterior(cell) then goto continue end
        local count = 0
        for _, ref in pairs(cell:getAll(types.NPC)) do
            if types.Actor.stats.dynamic.health(ref).current > 0 then
                count = count + 1
            end
        end
        for _, ref in pairs(cell:getAll(types.Creature)) do
            if types.Actor.stats.dynamic.health(ref).current > 0 then
                count = count + 1
            end
        end
        local hasToExDoor = false
        local cityCheck = not config.onlyInACity
        for _, door in pairs(cell:getAll(types.Door)) do
            if types.Door.isTeleport(door) and not this.isInterior(types.Door.destCell(door)) then
                hasToExDoor = true
                if not cityCheck then
                    local doorCount = 0
                    for _, _ in pairs(types.Door.destCell(door):getAll(types.Door)) do
                        doorCount = doorCount + 1
                    end
                    if doorCount >= 5 then
                        cityCheck = true
                    end
                else
                    break
                end
            end
        end
        if count >= chargenNPCs_count and hasToExDoor and cityCheck then
            table.insert(cells, cell)
        end
        ::continue::
    end
    math.randomseed(os.time())
    newCell = cells[math.random(#cells)]
    if not newCell then return end

    this.prepareCell(newCell)

    state = state < 1 and 1 or state
end

local function tryToStartNewGame()
    if loadStatus.newGame and loadStatus.configLoaded and config.enabled then
        state = 0
        this.toRandomCell()
    end
end

local function onNewGame()
    loadStatus.newGame = true
    tryToStartNewGame()
end

local function teleport(dt)
    if not dt then return end
    for _, data in pairs(dt) do
        local ref = data.reference
        local position = data.position
        local cellData = data.cell
        if not ref or not position or not cellData then return end
        local cell = data.cell.isExterior and world.getExteriorCell(data.cell.gridX, data.cell.gridY) or world.getCellByName(data.cell.name)
        ref:teleport(cell, position, {rotation = data.rotation, onGround = true})
    end
end

local function usbd_loadConfig(data)
    if data.config then
        for n, v in pairs(data.config) do
            config[n] = v
        end
    end
    loadStatus.configLoaded = true
    tryToStartNewGame()
end

local function usbd_objectTeleported(params)
    local reference = params.reference
    if not reference then return end
    if reference.type == types.Player then
        if #teleportionQueue > 0 then
            local player = world.players[1]
            local chargenCell = player.cell
            for _, ref in pairs(chargenCell:getAll(types.Door)) do
                if doorsToUnlockInChargenCell[ref.recordId] then
                    types.Lockable.unlock(ref)
                end
            end
            for _, ref in pairs(chargenCell:getAll()) do
                if objectsToDeleteInChargenCell[ref.recordId] then
                    ref:remove()
                elseif objectIdsToFinishScript[ref.recordId] then
                    local script = world.mwscript.getLocalScript(ref, player)
                    if script then
                        local variables = script.variables
                        local vars = objectIdsToFinishScript[ref.recordId]
                        for _, data in pairs(vars) do
                            if variables[data.name] then
                                variables[data.name] = data.val
                            end
                        end
                    end
                end
            end
            this.teleportToNextPositionInQueue()
        else
            world.players[1]:removeScript("scripts/an_unexpected_start/teleportedHandler.lua")
        end
    end
end

local function usbd_removeScript(data)
    if not data.reference or not data.scriptName then return end
    data.reference:removeScript(data.scriptName)
end

return {
    engineHandlers = {
        onNewGame = async:callback(onNewGame),
    },
    eventHandlers = {
        usbd_teleport = async:callback(teleport),
        usbd_loadConfig = usbd_loadConfig,
        usbd_objectTeleported = async:callback(usbd_objectTeleported),
        usbd_removeScript = async:callback(usbd_removeScript),
    },
}