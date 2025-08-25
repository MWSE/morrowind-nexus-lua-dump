--[[
ErnRadiantTheft for OpenMW.
Copyright (C) 2025 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local settings = require("scripts.ErnRadiantTheft.settings")
local common = require("scripts.ErnRadiantTheft.common")
local infrequent = require("scripts.ErnRadiantTheft.infrequent")
local cells = require("scripts.ErnRadiantTheft.cells")
local note = require("scripts.ErnRadiantTheft.note")
local macguffins = require("scripts.ErnRadiantTheft.macguffins")
local containerUtil = require("scripts.ErnRadiantTheft.containerUtil")
local core = require("openmw.core")
local localization = core.l10n(settings.MOD_NAME)
local interfaces = require('openmw.interfaces')
local async = require('openmw.async')
local world = require('openmw.world')
local types = require("openmw.types")
local util = require('openmw.util')
local aux_util = require('openmw_aux.util')
local storage = require('openmw.storage')

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

-- Init settings first to init storage which is used everywhere.
settings.initSettings()

local function defaultState()
    return {
        -- currentJobID is kept to maintain globally unique ids
        currentJobID = 0,
        -- players is a map of player-specific state to track.
        -- the index is the player id.
        players = {}
    }
end

local persistedState = defaultState()

local function saveState()
    return persistedState
end

local function loadState(saved)
    if (saved ~= nil) and (saved.players ~= nil) then
        persistedState = saved
        print("Loaded save data.")
    else
        persistedState = defaultState()
        print("Failed to load valid save data.")
    end
end

local function reset()
    print("Reset state!")
    persistedState = defaultState()
    for _, player in ipairs(world.players) do
        local quest = types.Player.quests(player)[common.questID]
        quest.stage = common.questStage.AVAILABLE
    end
end

settings.onReset(reset)

local function initPlayer(player)
    persistedState.players[player.id] = {
        -- each player has a list of jobs. lowest index is current one.
        jobs = {}
    }
end

local function savePlayerState(player, state)
    persistedState.players[player.id] = state
end

local function getPlayerState(player)
    if (persistedState == nil) or (persistedState.players == nil) then
        print("Reset state.")
        persistedState = defaultState()
    end
    local state = persistedState.players[player.id]
    if state == nil then
        settings.debugPrint("setting up new player state")
        initPlayer(player)
        state = persistedState.players[player.id]
    end
    return state
end

local function getExteriorCell(cell)
    if cell.isExterior or cell:hasTag("QuasiExterior") then
        return cell
    end
    for _, door in ipairs(common.shuffle(cell:getAll(types.Door))) do
        local destCell = types.Door.destCell(door)
        if (destCell ~= nil) and (destCell.isExterior or destCell:hasTag("QuasiExterior")) then
            return destCell
        end
    end
    return nil
end

local function getXY(cell)
    --local _, _, x, y = string.find(cell.id, "Esm3ExteriorCell:([-0-9]+):([-0-9]+)")
    return util.vector2(tonumber(cell.gridX), tonumber(cell.gridY))
end

local function getDistance(cellA, cellB)
    if cellA == nil or cellB == nil then
        settings.debugPrint("couldn't find cell")
        return 1
    end
    if cellA.worldSpaceId ~= cellB.worldSpaceId then
        --settings.debugPrint("different worldspaces for " .. cellA.name .. " and " .. cellB.name)
        return 100000
    end
    local dist = (getXY(cellA) - getXY(cellB)):length()
    --settings.debugPrint("distance from " .. cellA.name .. " to " .. cellB.name .. ": " .. tostring(dist))
    return dist
end

local function getDoors(cell)
    local doors = {}
    for _, door in ipairs(common.shuffle(cell:getAll(types.Door))) do
        local destCell = types.Door.destCell(door)
        if types.Door.isTeleport(door) and (destCell ~= nil) and (destCell.isExterior == false) and
            (destCell:hasTag("QuasiExterior") == false) then
            table.insert(doors, door)
        end
    end
    return doors
end

local function randomMacguffinForNPC(npcRecordId, forbiddenCategory)
    local record = types.NPC.record(npcRecordId)
    if record == nil then
        error("no record for npc: " .. npcRecordId)
    end

    local macguffin = nil
    for _, potenialMacguffin in ipairs(common.shuffle(macguffins.macguffins)) do
        if (forbiddenCategory ~= nil) and (forbiddenCategory == potenialMacguffin.category) then
            settings.debugPrint("Skipping repeated macguffin category " .. forbiddenCategory)
        elseif macguffins.filter(potenialMacguffin, record) then
            return potenialMacguffin
        end
    end
    settings.debugPrint("no suitable macguffins for npc: " .. npcRecordId)
    return nil
end

local function containerHasItem(container, itemRecordId)
    settings.debugPrint("checking if " .. container.recordId .. " has a " .. tostring(itemRecordId))
    return container.type.inventory(container):find(itemRecordId) ~= nil
end

local function setupMacguffinInCell(cell, forbiddenCategory)
    if cell == nil then
        error("failed to find cell")
        return nil
    end

    -- now we have to load the cell so we can get all the doors.
    -- pick a suitable interior cell.
    -- there should be owned containers in it.
    local bannedNPCs = {}
    local targetContainer = nil
    local macguffin = nil
    local mark = nil
    for _, container in ipairs(containerUtil.sortContainers(common.shuffle(cell:getAll(types.Container)))) do
        if (container.owner ~= nil) and (container.owner.recordId ~= nil) then
            local containerRecord = types.Container.record(container)
            if (containerRecord.isOrganic == false) and (containerRecord.isRespawning == false) and
                (bannedNPCs[container.owner.recordId] ~= true) and (containerRecord.mwscript == nil) then
                settings.debugPrint("Finding a macguffin for " .. container.owner.recordId .. "...")
                -- a stable container with an owner.
                macguffin = randomMacguffinForNPC(container.owner.recordId, forbiddenCategory)
                if macguffin ~= nil and (containerHasItem(container, macguffin.record.id) == false) then
                    local ownerRecord = types.NPC.record(container.owner.recordId)
                    if ownerRecord ~= nil then
                        settings.debugPrint("Found a macguffin for " .. container.owner.recordId .. ".")
                        mark = ownerRecord
                        targetContainer = container
                        break
                    else
                        bannedNPCs[container.owner.recordId] = true
                    end
                end
            end
        end
    end
    if macguffin == nil then
        settings.debugPrint("failed to find a macguffin in " .. cell.id)
        return nil
    end

    return {
        targetContainer = targetContainer,
        macguffin = macguffin,
        mark = mark
    }
end

local function setupMacguffinInCells(parentCell, forbiddenCategory)
    settings.debugPrint("Building a job somewhere in " .. parentCell.name .. "...")
    -- recurse down to depth of 3.
    -- add all cells to a list
    -- randomly select from list.
    -- this lets us get into cantons and under-skarr.

    local seenCellsSet = {}
    seenCellsSet[parentCell.name] = true

    local someCells = {}
    table.insert(someCells, parentCell)
    for _, door in ipairs(getDoors(parentCell)) do
        local childCell = types.Door.destCell(door)
        if seenCellsSet[childCell.name] ~= true then
            table.insert(someCells, childCell)
            seenCellsSet[childCell.name] = true
        end
        for _, otherDoor in ipairs(getDoors(childCell)) do
            local targetCell = types.Door.destCell(otherDoor)
            if seenCellsSet[targetCell.name] ~= true then
                table.insert(someCells, targetCell)
                seenCellsSet[targetCell.name] = true
            end
        end
    end

    for _, cell in ipairs(common.shuffle(someCells)) do
        settings.debugPrint("Building a job in " .. cell.name .. "...")
        local setup = setupMacguffinInCell(cell, forbiddenCategory)
        if setup ~= nil then
            settings.debugPrint("Built a job in " .. cell.name .. "!")
            return setup
        end
    end
    return nil
end

local function sortCells(player, allowedCells, previousJobs)
    -- get last 10 jobs.
    -- put these at the end of the list.
    -- also put far cells at the end of the list.
    if (previousJobs == nil) or (#previousJobs == 0) then
        return allowedCells
    end

    local myCell = getExteriorCell(player.cell)
    if myCell == nil then
        error("failed to determine exterior cell for player")
    end

    local cellToWeight = {}
    local output = {}
    for _, allowed in ipairs(allowedCells) do
        local weight = 0
        for i = 1, math.min(#previousJobs, 10), 1 do
            local previous = previousJobs[i]
            if allowed.id == previous.extCellID then
                -- we did this one already
                weight = weight + 10
            end
        end
        local distance = getDistance(myCell, allowed)
        if distance > settings.maxDistance() then
            weight = weight + 1 + math.random(0, math.ceil(distance - settings.maxDistance()))
        end
        cellToWeight[allowed.id] = weight
        table.insert(output, allowed)
    end
    table.sort(output, function(a, b) return cellToWeight[a.id] < cellToWeight[b.id] end)
    for _, c in ipairs(output) do
        settings.debugPrint(c.name .. " - " .. cellToWeight[c.id])
    end
    return output
end

local function newJob(player)
    if player == nil then
        error("player is nil")
        return
    elseif player.id == nil then
        error("player.id is nil")
        return
    end
    local state = getPlayerState(player)

    if state == nil then
        error("state is nil for player")
        return
    end

    -- make sure we don't get duplicates back-to-back.
    local previousJob = state.jobs[1]

    local forbiddenCategory = nil
    if previousJob ~= nil then
        forbiddenCategory = previousJob.category
    end

    -- determine parent cell.
    local possibleExtCells = sortCells(player, common.shuffle(cells.allowedCells), state.jobs)
    local parentCell = nil
    local setup = nil
    local distance = 1
    for _, cell in ipairs(possibleExtCells) do
        -- this is a potentially valid cell.
        parentCell = cell
        setup = setupMacguffinInCells(parentCell, forbiddenCategory)
        if setup ~= nil then
            -- success
            break
        end
    end
    if parentCell == nil then
        error("failed to find a parent cell")
        return
    end
    if setup == nil then
        error("failed to setup job")
        return
    end

    local targetContainer = setup.targetContainer
    local macguffin = setup.macguffin
    local mark = setup.mark

    -- make the new job (with a unique id)
    local macguffinInstance = world.createObject(macguffin.record.id, 1)
    persistedState.currentJobID = persistedState.currentJobID + 1
    local job = {
        jobID = persistedState.currentJobID,
        playerID = player.id,
        ownerRecordId = mark.id,
        extCellID = parentCell.id,
        targetContainerId = targetContainer.id,
        category = macguffin.category,
        type = macguffin.type,
        recordId = macguffin.record.id,
        itemInstance = macguffinInstance,
        distance = math.ceil(distance),
    }

    -- lock the container?
    if (types.Lockable.isLocked(targetContainer) == false) and (containerUtil.lockable(targetContainer)) then
        local playerRank = types.NPC.getFactionRank(player, "Thieves Guild")
        types.Lockable.lock(targetContainer, playerRank * 10)
        settings.debugPrint("locked target container")
    end

    -- place the macguffin
    macguffinInstance:moveInto(targetContainer)

    -- update current job
    table.insert(state.jobs, 1, job)
    savePlayerState(player, state)

    note.giveNote(player, #state.jobs, job.category, macguffin.record, mark, parentCell)
end

local function setBonus(player, amount)
    settings.debugPrint("setBonus: " .. amount)
    world.mwscript.getGlobalVariables(player)["ernradianttheft_questbonus"] = math.ceil(amount)
end

local function onMacguffinStolen(currentJob, data)
    settings.debugPrint("stole a macguffin")
    local quest = types.Player.quests(data.player)[common.questID]
    if quest.stage ~= common.questStage.STARTED then
        -- this can happen if the player places the quest item in an owned container
        -- and pulls it back out again. Don't change state in this case.
        settings.debugPrint("quest state is bad for job " .. currentJob.jobID .. ": " .. tostring(quest.stage))
        return
    end

    local playerRank = types.NPC.getFactionRank(data.player, "Thieves Guild")
    if (currentJob.distance == nil or currentJob.distance < 1) then
        currentJob.distance = 1
    end
    settings.debugPrint("dist: " .. currentJob.distance .. ", rank: " .. playerRank)

    -- we stole the right item.
    if data.caught then
        settings.debugPrint("job " .. currentJob.jobID .. " entered stolen_bad state")
        types.Player.quests(data.player)[common.questID]:addJournalEntry(common.questStage.STOLEN_BAD, data.player)

        setBonus(data.player, 150 + (75 * math.log(currentJob.distance)) + (5 * playerRank * playerRank))
    else
        settings.debugPrint("job " .. currentJob.jobID .. " entered stolen_good state")
        types.Player.quests(data.player)[common.questID]:addJournalEntry(common.questStage.STOLEN_GOOD, data.player)

        setBonus(data.player, 200 + (100 * math.log(currentJob.distance)) + (6 * playerRank * playerRank))
    end

    data.player:sendEvent(settings.MOD_NAME .. 'onMacguffinStolen', {})
end

local function onStolenCallback(stolenItemsData)
    settings.debugPrint("onStolenCallback(" .. aux_util.deepToString(stolenItemsData, 4) .. ")")

    for _, data in ipairs(stolenItemsData) do
        -- called when we steal an item.
        -- used to confirm that we stole the macguffin.
        -- the `caught` field will be used to determine if we get the full reward or not.
        -- used to confirm that the player didn't cheat by getting the item
        -- from somewhere else.
        -- settings.debugPrint("stole " .. tostring(data.itemRecord.id) .. " from " .. tostring(data.owner.recordId))

        local state = getPlayerState(data.player)
        if state == nil then
            error("player state is nil")
            return
        end

        local currentJob = state.jobs[1]
        -- settings.debugPrint("job: " .. aux_util.deepToString(currentJob, 4))
        if (currentJob == nil) or (currentJob.itemInstance.id ~= data.itemInstance.id) then
            settings.debugPrint("wrong item or bad data: " .. data.itemInstance.id)
        else
            onMacguffinStolen(currentJob, data)
            return
        end
    end
end

interfaces.ErnBurglary.onStolenCallback(onStolenCallback)

local restartCallback = async:registerTimerCallback(settings.MOD_NAME .. "_restart_quest_callback", function(data)
    if data.player == nil then
        error("no player for quest expiration")
        return
    end
    local quest = types.Player.quests(data.player)[common.questID]
    if quest.stage == common.questStage.RESTARTING then
        settings.debugPrint("restarting quest")
    else
        error("quest in bad state")
        return
    end
    -- try to reset journal since engine only accepts increasing numbers
    -- when modifying journal. these don't work.
    quest.finished = false
    quest.stage = common.questStage.AVAILABLE - 1
    quest:addJournalEntry(common.questStage.AVAILABLE, data.player)
    if data.stage == common.questStage.QUIT then
        data.player:sendEvent(settings.MOD_NAME .. 'onQuestAvailable', data)
    end
end)

local function onQuestUpdate(data)
    local quest = types.Player.quests(data.player)[common.questID]
    if data.stage == common.questStage.STARTED then
        settings.debugPrint("initializing new job")
        -- start up the new job.
        -- this will modify state, so we should exit after this.
        newJob(data.player)
    elseif quest.stage == common.questStage.COMPLETED or quest.stage == common.questStage.QUIT then
        if quest.stage == common.questStage.COMPLETED then
            -- delete the macguffin!
            local state = getPlayerState(data.player)
            if state == nil then
                quest.stage = common.questStage.AVAILABLE
                error("player state is nil")
                return
            end
            local previousJob = state.jobs[1]
            local inst = data.player.type.inventory(data.player):find(previousJob.recordId)
            settings.debugPrint("removing a " .. previousJob.recordId)
            inst:remove(1)
        end

        -- RESTARTING exists so we don't double-spawn the restartCallback.
        settings.debugPrint("setting up timer for job restart")
        quest.stage = common.questStage.RESTARTING
        if quest.stage == common.questStage.QUIT then
            -- Penalty for quiting is a three day wait.
            local waitTime = 60 * 60 * 24 * 3
            async:newGameTimer(waitTime, restartCallback, {
                player = data.player,
                stage = quest.stage,
            })
        else
            -- Near-instant for success.
            async:newGameTimer(1, restartCallback, {
                player = data.player,
                stage = quest.stage,
            })
        end

        quest.finished = true
    end
end

local function syncPlayer(player)
    local quest = types.Player.quests(player)[common.questID]
    if quest.stage < 1 then
        settings.debugPrint("quest not started")
        return
    end

    local state = getPlayerState(player)
    if state == nil then
        quest.stage = common.questStage.AVAILABLE
        error("player state is nil")
        return
    end
    -- monitor for inventory changes.
    -- use quest stage to bridge into mwscript, since mwscript doesn't
    -- know which item it is looking for.

    local currentJob = state.jobs[1]
    settings.debugPrint("checking player status. quest: " .. tostring(quest.stage) .. ". job: " ..
        aux_util.deepToString(currentJob, 4))

    if currentJob ~= nil then
        local hasMacguffin = containerHasItem(player, state.jobs[1].recordId)
        if (quest.stage == common.questStage.STOLEN_BAD) and (hasMacguffin == false) then
            quest.stage = common.questStage.STOLEN_BAD_LOST
            settings.debugPrint("lost the macguffin. " .. tostring(quest.stage))
        elseif (quest.stage == common.questStage.STOLEN_GOOD) and (hasMacguffin == false) then
            settings.debugPrint("lost the macguffin. " .. tostring(quest.stage))
            quest.stage = common.questStage.STOLEN_GOOD_LOST
        elseif (quest.stage == common.questStage.STOLEN_BAD_LOST) and (hasMacguffin) then
            settings.debugPrint("found the macguffin. " .. tostring(quest.stage))
            quest.stage = common.questStage.STOLEN_BAD
        elseif (quest.stage == common.questStage.STOLEN_GOOD_LOST) and (hasMacguffin) then
            settings.debugPrint("found the macguffin. " .. tostring(quest.stage))
            quest.stage = common.questStage.STOLEN_GOOD
        end
    end

    savePlayerState(player, state)
end

local function onActivate(object, actor)
    -- this is called before dialogue begins with an NPC.
    if types.NPC.objectIsInstance(object) then
        syncPlayer(actor)
    end
end

local function printPotentialCells()
    local dupe = {}
    local byRegion = {}
    local sortableRegions = {}
    for _, cell in ipairs(world.cells) do
        if (cell.name ~= "" and cell.name ~= nil and cell.isExterior or cell:hasTag("QuasiExterior")) then
            if byRegion[cell.region] == nil then
                byRegion[cell.region] = {}
                table.insert(sortableRegions, cell.region)
            end
            if dupe[cell.name] ~= true then
                if #cell:getAll(types.NPC) > 2 then
                    table.insert(byRegion[cell.region], cell.name)
                    dupe[cell.name] = true
                end
            end
        end
    end
    table.sort(sortableRegions)
    for _, region in ipairs(sortableRegions) do
        print("#REGION: " .. region)
        local cellList = byRegion[region]
        table.sort(cellList)
        for _, aCell in ipairs(cellList) do
            print(aCell)
        end
    end
end

-- used to build up cells/ id files.
-- uncomment to print all maybe-good target cells to the log.
--printPotentialCells()

return {
    eventHandlers = {
        [settings.MOD_NAME .. "onQuestUpdate"] = onQuestUpdate
    },
    engineHandlers = {
        onSave = saveState,
        onLoad = loadState,
        onActivate = onActivate
    }
}
