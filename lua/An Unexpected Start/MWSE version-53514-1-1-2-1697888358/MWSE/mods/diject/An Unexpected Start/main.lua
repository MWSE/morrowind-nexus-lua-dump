-- A single file? Yes!
local this = {}

local chargenNPCs = {
    ["chargen captain"] = {ref = nil, cell = {id = "Seyda Neen, Census and Excise Office", x = nil, y = nil, position = tes3vector3.new(1366.27,-380.32,195.75)}, orientation = tes3vector3.new(0.00,0.00,4.71)},
    ["chargen class"] = {ref = nil, cell = {id = "Seyda Neen, Census and Excise Office", x = nil, y = nil, position = tes3vector3.new(242.30,-111.06,211.02)}, orientation = tes3vector3.new(0.00,0.00,4.71)},
    ["chargen dock guard"] = {ref = nil, shouldDeleted = true, cell = {id = nil, x = -2, y = -9, position = tes3vector3.new(-9797.83,-72522.74,125.52)}, orientation = tes3vector3.new(0.00,0.00,2.20)},
    ["chargen name"] = {ref = nil, cell = {id = "Imperial Prison Ship", x = nil, y = nil, position = tes3vector3.new(17.80,-66.11,-103.26)}, orientation = tes3vector3.new(0.00,0.00,2.44)},
}
local chargenNPCs_count = 4

local defaultChargenCells = {
    ["Seyda Neen, Census and Excise Office"] = {id = "Seyda Neen, Census and Excise Office"},
    ["-2, -9"] = {x = -2, y = -9},
}
local objectIdsToFinishScript = {
    ["chargen door captain"] = {{name = "done", val = 1}},
    ["CharGen Exit Door"] = {{name = "done", val = 1}},
    ["chargen_shipdoor"] = {{name = "done", val = 1}},
    ["chargendoorjournal"] = {{name = "done", val = 1}},
    ["chargen barrel fatigue"] = {{name = "done", val = 1}},
    ["chargen door guard"] = {{name = "done", val = 1}},
    ["chargen class"] = {{name = "state", val = "-1"}},
    ["chargen captain"] = {{name = "done", val = "1"}, {name = "state", val = "-1"}},
}
local chargenStatsSheet = "chargen statssheet"
local objectsToDeleteInChargenCell = {
    [chargenStatsSheet] = true,
}
local doorsToUnlockInChargenCell = {
    ["chargen door hall"] = true,
}

local guards = {"Imperial Guard"}

local dataName = "an_unexpected_start_BD"
local configName = "AnUnexpectedStartByDiject"

chargenNPCs["chargen class"].ref = nil
chargenNPCs["chargen dock guard"].ref = nil
chargenNPCs["chargen name"].ref = nil
chargenNPCs["chargen captain"].ref = nil

local state = 0 -- 10 when done

local mainQuestName = "a1_1_findspymaster"
local levitationSpellName = "usbd_levitation_passive_spell"

local readyMessage = "You are ready to go."
local modName = "An Unexpected Start"

local newCell = nil

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function addMissing(toTable, fromTable)
    for label, val in pairs(fromTable) do
        if type(val) == "table" then
            if toTable[label] == nil then
                toTable[label] = deepcopy(val)
            else
                if type(toTable[label]) ~= "table" then toTable[label] = {} end
                addMissing(toTable[label], val)
            end
        elseif toTable[label] == nil then
            toTable[label] = val
        end
    end
end

local config = mwse.loadConfig(configName)
local defaultConfig = {
    enabled = false,
    chanceToSpawnGuard = 0.5,
    allowJustExit = true,
    onlyInACity = true,
    applyLevitation = true,
    delayBeforeStart = 0.5,
}
if not config then
    config = deepcopy(defaultConfig)
    mwse.saveConfig(configName, config)
else
    addMissing(config, defaultConfig)
end


---@param vector1 tes3vector3
---@param vector2 tes3vector3
---@return number
local function get2DDistance(vector1, vector2)
    if not vector1 or not vector2 then return 0 end
    return math.sqrt((vector2.x - vector1.x) ^ 2 + (vector2.y - vector1.y) ^ 2)
end

local function getGroundZ(vector)
    local res = tes3.rayTest {
        position = vector,
        direction = tes3vector3.new(0, 0, -1),
        root = tes3.game.worldObjectRoot,
        useBackTriangles = true,
        maxDistance = 1000
    }
    if res == nil then
        res = tes3.rayTest {
            position = vector,
            direction = tes3vector3.new(0, 0, 1),
            root = tes3.game.worldObjectRoot,
            useBackTriangles = true,
            maxDistance = 1000
        }
    end
    if res ~= nil then
        return res.intersection.z
    end
    return nil
end

function this.randomPointInRadius(vector, radius, maxHeight)
    local new = vector:copy()
    local angle = math.random() * math.pi / 2
    for i = 0, math.pi / 2, math.pi / 16 do
        angle = angle + i
        new.x = vector.x + radius * math.cos(angle)
        new.y = vector.y + radius * math.sin(angle)
        if maxHeight then
            local groundZ = getGroundZ(new)
            if groundZ and math.abs(groundZ - vector.z) < maxHeight then
                new.z = groundZ
                return new
            end
        else
            break
        end
    end
    return new
end

function this.finishChargen()
    for id, data in pairs(chargenNPCs) do
        if data.shouldDeleted then
            data.ref:delete() ---@diagnostic disable-line: unused-function, undefined-field
        else
            local cell = tes3.getCell(data.cell)
            if not cell then goto continue end
            tes3.positionCell{reference = data.ref, cell = cell, position = data.cell.position, orientation = data.orientation,
                forceCellChange = true, suppressFader = false, teleportCompanions = true}
        end
        ::continue::
    end
    for cellName, cellPosData in pairs(defaultChargenCells) do
        local chargenCell = tes3.getCell(cellPosData)
        if not chargenCell then return end
        for ref in chargenCell:iterateReferences(tes3.objectType.door) do
            if doorsToUnlockInChargenCell[ref.baseObject.id] then
                tes3.unlock{reference = ref}
            end
        end
        local cell = tes3.player.cell
        local position = tes3.player.position:copy()
        local orientation = tes3.player.orientation:copy()
        tes3.positionCell{reference = tes3.player, cell = chargenCell, position = tes3vector3.new(0,0,0), orientation = tes3vector3.new(0,0,0),
                forceCellChange = true, suppressFader = true, teleportCompanions = true}
        for ref in chargenCell:iterateReferences() do
            if objectsToDeleteInChargenCell[ref.baseObject.id] then
                ref:delete()
            elseif objectIdsToFinishScript[ref.baseObject.id] and ref.context then
                local vars = objectIdsToFinishScript[ref.baseObject.id]
                local context = ref.context:getVariableData()
                for _, data in pairs(vars) do
                    if context[data.name] then
                        tes3.runLegacyScript{reference = ref, command = "set "..tostring(data.name).." to "..tostring(data.val)} ---@diagnostic disable-line: missing-fields
                        ref.modified = true
                    end
                end
            end
        end
        tes3.positionCell{reference = tes3.player, cell = cell, position = position, orientation = orientation,
            forceCellChange = true, suppressFader = true, teleportCompanions = true}
    end
end

function this.saveInitialData(cell)
    if not cell then return end
    for ref in cell:iterateReferences({tes3.objectType.npc, tes3.objectType.creature}) do
        local actorData = {}
        actorData.disabled = ref.disabled
        ref.data[dataName] = actorData
        ref.modified = true
    end
    for ref in cell:iterateReferences(tes3.objectType.door) do
        local doorData = {}
        if ref.lockNode then
            doorData.key = ref.lockNode.key and ref.lockNode.key.id or nil
            doorData.trap = ref.lockNode.trap and ref.lockNode.trap.id or nil
            doorData.level = ref.lockNode.level
        end
        ref.data[dataName] = doorData
        ref.modified = true
    end
end

function this.resoreInitialData(cell)
    if not cell then return end
    for ref in cell:iterateReferences({tes3.objectType.npc, tes3.objectType.creature}) do
        local actorData = ref.data[dataName]
        if actorData then
            if actorData.disabled then
                ref:disable()
            else
                ref:enable()
            end
            ref.data[dataName] = nil
            ref.modified = false
        else
            ref:delete()
        end
    end
    for ref in cell:iterateReferences(tes3.objectType.door) do
        local doorData = ref.data[dataName]
        if doorData then
            if doorData.level and doorData.level > 0 then
                tes3.lock{reference = ref, level = doorData.level}
            else
                tes3.unlock{reference = ref}
            end
            if doorData.key and ref.lockNode then
                ref.lockNode.key = tes3.getObject(doorData.key)
            end
            if doorData.trap and ref.lockNode then
                ref.lockNode.trap = tes3.getObject(doorData.trap)
            end
        end
        ref.data[dataName] = nil
        ref.modified = true
    end
end

function this.faceActorToActor(actor, target)
    if not actor or not target then return end
    local angle = math.rad(actor.mobile:getViewToActor(target.mobile))
    local new = actor.orientation:copy()
    new.z = new.z + angle
    actor.orientation = new
end

function this.enableAllControls()
    tes3.runLegacyScript{command = "EnablePlayerViewSwitch"} ---@diagnostic disable-line: missing-fields
	tes3.runLegacyScript{command = "EnableVanityMode"} ---@diagnostic disable-line: missing-fields
    tes3.runLegacyScript{command = "enableplayercontrols"} ---@diagnostic disable-line: missing-fields
    tes3.runLegacyScript{command = "enablestatsmenu"} ---@diagnostic disable-line: missing-fields
    tes3.runLegacyScript{command = "enableinventorymenu"} ---@diagnostic disable-line: missing-fields
    tes3.runLegacyScript{command = "enablemagicmenu"} ---@diagnostic disable-line: missing-fields
    tes3.runLegacyScript{command = "enablemapmenu"} ---@diagnostic disable-line: missing-fields
    tes3.runLegacyScript{command = "enableplayerfighting"} ---@diagnostic disable-line: missing-fields
    tes3.runLegacyScript{command = "enableplayermagic"} ---@diagnostic disable-line: missing-fields
    tes3.runLegacyScript{command = "EnablePlayerJumping"} ---@diagnostic disable-line: missing-fields
end

local angleCounter = 0
local notOnGroundCounter = 0
local levitationEnabled = false
local lockLevitation = false
local levitationTimer
function this.levitation(timerData)
    if not config.applyLevitation then
        tes3.removeSpell{reference = tes3.player, spell = levitationSpellName, updateGUI = true}
        return
    end
    local xAngle = tes3.getPlayerEyeVector().z
    if xAngle and xAngle > 0.5 then
        angleCounter = angleCounter + 1
    else
        angleCounter = 0
    end
    local spotZ = getGroundZ(tes3.player.position)
    local onGround = spotZ and (tes3.player.position.z - getGroundZ(tes3.player.position)) < 5 or true
    if not levitationEnabled and tes3.mobilePlayer.isFalling then
        notOnGroundCounter = notOnGroundCounter + 1
    else
        notOnGroundCounter = 0
    end
    local function enableLevitation()
        if not levitationEnabled then
            tes3.addSpell{reference = tes3.player, spell = levitationSpellName, updateGUI = true}
            tes3.playSound{sound = "alteration hit"}
            levitationEnabled = true
        end
    end
    if angleCounter > 20 then
        enableLevitation()
    elseif notOnGroundCounter > 13 then
        enableLevitation()
        lockLevitation = true
    elseif onGround or not lockLevitation then
        tes3.removeSpell{reference = tes3.player, spell = levitationSpellName, updateGUI = true}
        lockLevitation = false
        levitationEnabled = false
    end
end

function this.onSimulate(e)
    if chargenNPCs["chargen name"].ref and state == 2 and chargenNPCs["chargen name"].ref.context then
        local variables = chargenNPCs["chargen name"].ref.context:getVariableData()
        if variables and variables["state"] and variables["state"].value == 20 then
            tes3.runLegacyScript{command = "EnablePlayerControls"} ---@diagnostic disable-line: missing-fields
            tes3.runLegacyScript{command = "EnablePlayerJumping"} ---@diagnostic disable-line: missing-fields
            if chargenNPCs["chargen dock guard"].ref then
                local npc = chargenNPCs["chargen dock guard"].ref
                timer.start{duration = 5 + math.max(0, 4 - get2DDistance(npc.position, tes3.player.position) / 200), callback = function(tmData)
                    timer.start{duration = 1, iterations = -1, callback = function()
                        if state < 4 and npc then
                            tes3.setAITravel{reference = npc, destination = tes3.player.position, reset = true}
                        else
                            tmData.timer:cancel()
                        end
                    end}
                end}
            end
            state = state < 3 and 3 or state
        end
    end
    if chargenNPCs["chargen class"].ref and chargenNPCs["chargen class"].ref.context then
        local variables = chargenNPCs["chargen class"].ref.context:getVariableData()
        if variables and state >= 3 and state < 9 and variables["state"] then
            local value = variables["state"].value
            if value == 10 and state < 6 then
                this.faceActorToActor(chargenNPCs["chargen class"].ref, tes3.player)
                this.faceActorToActor(chargenNPCs["chargen dock guard"].ref, tes3.player)
                tes3.runLegacyScript{command = 'set state to 60', reference = chargenNPCs["chargen dock guard"].ref,}
                state = state < 6 and 6 or state
            elseif value == 20 then
                tes3.addItem{reference = tes3.player, item = chargenStatsSheet, count = 1}
                local pos = chargenNPCs["chargen captain"].ref.position ---@diagnostic disable-line: undefined-field, need-check-nil
                tes3.setAITravel{reference = chargenNPCs["chargen dock guard"].ref, destination = pos, reset = true} ---@diagnostic disable-line: undefined-field, need-check-nil, assign-type-mismatch
                state = state < 8 and 8 or state
            end
        end
    end
    if chargenNPCs["chargen dock guard"].ref and chargenNPCs["chargen class"].ref and state >= 3 and state < 5 and chargenNPCs["chargen dock guard"].ref.context then
        local variables = chargenNPCs["chargen dock guard"].ref.context:getVariableData()
        if variables and variables["state"] then
            local value = variables["state"].value
            if state == 3 and value == 30 then
                state = state < 4 and 4 or state
            elseif value == 50 and state == 4 then
                local ref = chargenNPCs["chargen dock guard"].ref  
                local pos = chargenNPCs["chargen class"].ref.position
                timer.start{duration = 7, callback = function()
                    tes3.setAITravel{reference = ref, destination = pos, reset = true}
                end}
                state = state < 5 and 5 or state
            end
        end
    end
    if tes3.isCharGenFinished() then
        event.unregister(tes3.event.simulate, this.onSimulate)
    end
end

function this.finishCharacterGeneration()
    this.enableAllControls()
    if tes3.worldController.charGenState.value >= 0 then
        tes3.worldController.charGenState.value = -1
    end
    this.finishChargen()
    this.resoreInitialData(newCell)
    event.unregister(tes3.event.cellChanged, this.finishCharacterGeneration)
    this.unregisterEvents()
    if levitationTimer then
        levitationTimer:cancel()
    end
    if state < 10 then
        timer.start{duration = 1, iterations = -1, callback = function(tmData)
            if state < 10 then
                this.forceChargenStep()
            else
                tmData.timer:cancel()
            end
        end}
    end
end

function this.journalEvent(e)
    if e.topic and e.topic.id:lower() == mainQuestName then
        local doors = {}
        for door in tes3.player.cell:iterateReferences(tes3.objectType.door) do
            if door.destination and not door.destination.cell.isInterior then
                tes3.unlock{reference = door}
                table.insert(doors, door)
            end
        end
        this.enableAllControls()
        state = 10
        if #doors > 0 and chargenNPCs["chargen captain"].ref then
            local destDoor = doors[math.random(#doors)]
            if destDoor then
                local destDoorPos = nil
                local distanceToDestRef = math.huge
                for ref in tes3.player.cell:iterateReferences(tes3.objectType.static) do
                    if ref.object.id == "DoorMarker" then
                        local dist = ref.position:distance(destDoor.position)
                        if distanceToDestRef > dist then
                            destDoorPos = ref.position
                            distanceToDestRef = dist
                        end
                    end
                end
                if destDoorPos then
                    tes3.setAITravel{reference = chargenNPCs["chargen captain"].ref, destination = destDoorPos, reset = true}
                end
            end
        end
        event.unregister(tes3.event.journal, this.journalEvent)
    end
end

function this.prepareCell(e)
    if not newCell or newCell.id ~= e.cell.id then return end
    this.saveInitialData(e.cell)
    timer.delayOneFrame(function()
        chargenNPCs["chargen name"].ref = nil
        chargenNPCs["chargen class"].ref = nil
        chargenNPCs["chargen dock guard"].ref = nil
        chargenNPCs["chargen captain"].ref = nil
        local chargenNPCIds = {"chargen name", "chargen dock guard", "chargen class", "chargen captain"}
        do
            local refForSpot = {}
            for ref in newCell:iterateReferences({tes3.objectType.npc, tes3.objectType.creature}) do
                if ref.baseObject.health > 0 then
                    ref:disable()
                    table.insert(refForSpot, ref)
                end
            end
            for _, id in ipairs(chargenNPCIds) do
                local params = chargenNPCs[id]
                if not params then goto continue end
                local oldRefId = math.random(#refForSpot)
                local oldRef = refForSpot[oldRefId]
                if id == "chargen dock guard" and chargenNPCs["chargen name"].ref then
                    local chargenNamePos = chargenNPCs["chargen name"].ref.position
                    local minDistance = math.huge
                    for refPos, ref in pairs(refForSpot) do
                        local mul = math.floor(math.abs(ref.position.z - chargenNamePos.z) / 100)
                        local distance = get2DDistance(ref.position, chargenNamePos) + 1000 * mul
                        if distance < minDistance and distance > 150 then
                            minDistance = distance
                            oldRefId = refPos
                            oldRef = ref
                        end
                    end
                end
                local npcCell = tes3.getCell(params.cell)
                if not npcCell then goto continue end
                local newRef = nil
                for ref in npcCell:iterateReferences(tes3.objectType.npc) do
                    if ref.baseObject.id == id then newRef = ref break end
                end
                if not newRef then goto continue end
                if chargenNPCs[newRef.baseObject.id].shouldDeleted then
                    newRef = tes3.createReference{object = id, position = oldRef.position, orientation = oldRef.orientation, cell = oldRef.cell}
                else
                    tes3.positionCell{reference = newRef, cell = oldRef.cell, position = oldRef.position, orientation = oldRef.orientation,
                        forceCellChange = false, suppressFader = false, teleportCompanions = true}
                end
                if chargenNPCs[id] then chargenNPCs[id].ref = newRef end
                table.remove(refForSpot, oldRefId)
                if #refForSpot == 0 then break end
                ::continue::
            end
            for _, ref in pairs(refForSpot) do
                if math.random() < config.chanceToSpawnGuard then
                    tes3.createReference{object = guards[math.random(#guards)], position = ref.position, orientation = ref.orientation, cell = ref.cell}
                end
            end
        end
        if chargenNPCs["chargen name"].ref then
            for door in newCell:iterateReferences(tes3.objectType.door) do
                if door.destination and (not config.allowJustExit or door.destination.cell.isInterior) then

                    tes3.lock{reference = door, level = 100}
                else
                    tes3.unlock{reference = door}
                end
                if door.lockNode then
                    door.lockNode.key = nil
                    door.lockNode.trap = nil
                end
            end

            event.register(tes3.event.cellChanged, this.finishCharacterGeneration)
            event.register(tes3.event.journal, this.journalEvent)

            local newPos = this.randomPointInRadius(chargenNPCs["chargen name"].ref.position, 35, 25)

            tes3.positionCell{reference = tes3.player, cell = newCell, position = chargenNPCs["chargen name"].ref.position,
                orientation = chargenNPCs["chargen name"].ref.orientation, forceCellChange = true, suppressFader = false, teleportCompanions = true}
            tes3.positionCell{reference = chargenNPCs["chargen name"].ref, cell = newCell, position = newPos, orientation = chargenNPCs["chargen name"].ref.orientation,
                forceCellChange = true, suppressFader = false, teleportCompanions = true}

            this.faceActorToActor(chargenNPCs["chargen name"].ref, tes3.player)
            this.faceActorToActor(tes3.player, chargenNPCs["chargen name"].ref)

            state = state < 2 and 2 or state
            event.unregister(tes3.event.cellChanged, this.prepareCell)
        end
    end)
end

function this.toRandomCell()
    local cells = {}
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        local count = 0
        for ref in cell:iterateReferences({tes3.objectType.npc, tes3.objectType.creature}) do
            if ref.baseObject.health > 0 then
                count = count + 1
            end
        end
        local hasToExDoor = false
        local cityCheck = not config.onlyInACity
        for door in cell:iterateReferences(tes3.objectType.door) do
            if door.destination and not door.destination.cell.isInterior then
                hasToExDoor = true
                if not cityCheck then
                    local doorCount = 0
                    for _, _ in door.destination.cell:iterateReferences(tes3.objectType.door) do
                        doorCount = doorCount + 1
                    end
                    if doorCount >= 5 then
                        cityCheck = true
                    end
                end
            end
        end
        if count >= chargenNPCs_count and hasToExDoor and cityCheck then
            table.insert(cells, cell)
        end
    end
    math.randomseed(os.time())
    newCell = cells[math.random(#cells)]
    if not newCell then return end
    tes3.positionCell{reference = tes3.player, cell = newCell, position = tes3vector3.new(0, 0, 0), orientation = tes3vector3.new(0, 0, 0),
        forceCellChange = true, suppressFader = true, teleportCompanions = true}
    state = state < 1 and 1 or state

    levitationTimer = timer.start{duration = 0.1, iterations = -1, callback = this.levitation}
end

function this.forceChargenStep()
    if state < 5 then
        tes3.runLegacyScript{command = "EnableRaceMenu"} ---@diagnostic disable-line: missing-fields
        state = 5
        return
    end
    if state < 7 then
        tes3.runLegacyScript{command = "EnableClassMenu"} ---@diagnostic disable-line: missing-fields
        state = 7
        return
    end
    if state < 8 then
        tes3.runLegacyScript{command = "EnableBirthMenu"} ---@diagnostic disable-line: missing-fields
        state = 8
        this.enableAllControls()
        return
    end
    if state < 9 then
        tes3.runLegacyScript{command = "EnableStatReviewMenu"} ---@diagnostic disable-line: missing-fields
        state = 9
        tes3.removeItem{reference = tes3.player, item = chargenStatsSheet, updateGUI = true}
        tes3.runLegacyScript{command = 'Journal, "A1_1_FindSpymaster", 1'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'player->AddItem, "bk_A1_1_DirectionsCaiusCosades", 1'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'player->AddItem,  "bk_a1_1_caiuspackage", 1'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'player->Additem, "Gold_001", 87'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'addtopic "Caius Cosades"'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'Addtopic "South Wall"'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'addtopic "specific place"'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'addtopic "someone in particular"'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'addtopic "services"'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'addtopic "my trade"'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'addtopic "little secret"'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'addtopic "latest rumors"'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = 'addtopic "little advice"'} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = '"CharGen Boat"->Disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen Boat Guard 1"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen Boat Guard 2"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen Dock Guard"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_cabindoor"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_chest_02_empty"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_crate_01"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_crate_01_empty"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_crate_01_misc01"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_crate_02"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_lantern_03_sway"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_ship_trapdoor"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_barrel_01"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_barrel_02"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGenbarrel_01_drinks"->disable'} ---@diagnostic disable-line: missing-fields
		tes3.runLegacyScript{command = '"CharGen_plank"->disable'} ---@diagnostic disable-line: missing-fields
        timer.start{duration = 0.5, callback = function()
            tes3.messageBox{message = readyMessage, duration = 10}
        end}
    end
    state = 10
    return true
end

function this.activateExit(e)
    if e.activator == tes3.player and e.target.object.objectType == tes3.objectType.door and e.target.destination and
            not e.target.destination.cell.isInterior and state < 10 then

        e.block = true
        e.claim = true
        local isFinished = this.forceChargenStep()
        if isFinished then
            event.unregister(tes3.event.activate, this.activateExit)
        end
    end
end

function this.unregisterEvents()
    if event.isRegistered(tes3.event.simulate, this.onSimulate) then
		event.unregister(tes3.event.simulate, this.onSimulate)
	end

    if event.isRegistered(tes3.event.journal, this.journalEvent) then
		event.unregister(tes3.event.journal, this.journalEvent)
	end

    if event.isRegistered(tes3.event.cellChanged, this.prepareCell) then
		event.unregister(tes3.event.cellChanged, this.prepareCell)
	end

    if event.isRegistered(tes3.event.simulate, this.onSimulate) then
		event.unregister(tes3.event.simulate, this.onSimulate)
	end

    if event.isRegistered(tes3.event.cellChanged, this.finishCharacterGeneration) then
		event.unregister(tes3.event.cellChanged, this.finishCharacterGeneration)
	end

    if event.isRegistered(tes3.event.activate, this.activateExit) then
		event.unregister(tes3.event.activate, this.activateExit)
	end
end

event.register(tes3.event.loaded, function(e)
    if not e.newGame or not config.enabled then return end
    chargenNPCs["chargen class"].ref = nil
    chargenNPCs["chargen dock guard"].ref = nil
    chargenNPCs["chargen name"].ref = nil
    chargenNPCs["chargen captain"].ref = nil
    newCell = nil
    state = 0

    this.unregisterEvents()

    event.register(tes3.event.cellChanged, this.prepareCell)
    event.register(tes3.event.simulate, this.onSimulate)
    if config.allowJustExit then event.register(tes3.event.activate, this.activateExit) end
    timer.start{duration = config.delayBeforeStart, callback = function() this.toRandomCell() end}
end)

event.register(tes3.event.initialized, function(e)
    if not tes3.getObject(levitationSpellName) then
        local spell = tes3.createObject{id = levitationSpellName, objectType = tes3.objectType.spell, castType = tes3.spellType.ability}
        spell.effects[1].id = tes3.effect.levitate
        spell.effects[1].max = 10
        spell.effects[1].min = 10
        spell.effects[1].rangeType = tes3.effectRange.self
    end
end)

local EasyMCM = require("easyMCM.EasyMCM")
function this.registerModConfig()
    local easyMCMData = {
        name = modName,
        onClose = (function()
            mwse.saveConfig(configName, config)
        end),
        pages = {
            {
                label = "Main",
                class = "Page",
                components = {
                    {
                        class = "Info",
                        label = "A mod that randomizes where you start the game.",
                        text = "",
                    },
                    {
                        class = "OnOffButton",
                        label = "Enable the mod",
                        inGameOnly = false,
                        variable = {
                            id = "enabled",
                            class = "TableVariable",
                            table = config,
                        },
                    },
                    {
                        class = "OnOffButton",
                        label = "Lock a exit from the starting location until the character generation sequence is complete",
                        inGameOnly = false,
                        variable = {
                            class = "Variable",
                            get = function(self)
                                return not config.allowJustExit
                            end,
                            set = function(self, val)
                                config.allowJustExit = not val
                            end,
                        },
                    },
                    {
                        class = "OnOffButton",
                        label = "Spawn imperial guards in large locations",
                        inGameOnly = false,
                        variable = {
                            class = "Variable",
                            get = function(self)
                                return config.chanceToSpawnGuard > 0
                            end,
                            set = function(self, val)
                                config.chanceToSpawnGuard = val and 0.5 or 0
                            end,
                        },
                    },
                    {
                        class = "OnOffButton",
                        label = "Try to start the game only in a location near a city",
                        inGameOnly = false,
                        variable = {
                            id = "onlyInACity",
                            class = "TableVariable",
                            table = config,
                        },
                    },
                    {
                        class = "OnOffButton",
                        label = "Apply levitation when you are falling or looking up",
                        description = "This setting allows you to bypass some locations that are impossible to complete without it",
                        inGameOnly = false,
                        variable = {
                            id = "applyLevitation",
                            class = "TableVariable",
                            table = config,
                        },
                    },
                    {
                        class = "Category",
                        components = {
                            {
                                class = "Info",
                                text = "Delay before the script starts. Increase it if the game freezes after the start. "..
                                    "Or decrease it if the start dialog from Jiub is skipped. Default is 0.5",
                            },
                            {
                                class = "TextField",
                                postCreate = function(self)
                                    self.elements.submitButton:destroy()
                                    self.elements.border.maxWidth = 100
                                    self.elements.inputField:register("destroy", function()
                                        local val = tonumber(self.elements.inputField.text)
                                        if not val then return end
                                        if val < 0.1 then val = 0.1 end
                                        if val > 5 then val = 5 end
                                        config.delayBeforeStart = val
                                    end)
                                end,
                                variable = EasyMCM.createVariable{
                                    numbersOnly = true,
                                    get = function(self)
                                        return config.delayBeforeStart
                                    end,
                                    set = function(self, strVal)
                                        local val = tonumber(strVal)
                                        if not val then return end
                                        if val < 0.1 then val = 0.1 end
                                        if val > 5 then val = 5 end
                                        config.delayBeforeStart = val
                                    end,
                                },
                            },
                        },
                    }
                },
            },
        },
    }
    local modConfigData = require("easyMCM.EasyMCM").registerModData(easyMCMData)
    mwse.registerModConfig(modName, modConfigData)
end

event.register(tes3.event.modConfigReady, this.registerModConfig)