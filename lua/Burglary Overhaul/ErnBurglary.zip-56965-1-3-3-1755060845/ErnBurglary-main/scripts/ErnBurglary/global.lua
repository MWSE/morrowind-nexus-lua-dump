--[[
ErnBurglary for OpenMW.
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
local settings = require("scripts.ErnBurglary.settings")
local common = require("scripts.ErnBurglary.common")
local infrequent = require("scripts.ErnBurglary.infrequent")
local interfaces = require('openmw.interfaces')
local world = require('openmw.world')
local types = require("openmw.types")
local core = require("openmw.core")
local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local storage = require('openmw.storage')

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

-- Init settings first to init storage which is used everywhere.
settings.initSettings()

local function onNewGame()
    settings.onNewGame()
end

local persistedState = {}

local function thieveryKey(cellID, playerID)
    if (cellID == nil) or (cellID == "") then
        error("thieveryKey() bad cellID")
    end
    if (playerID == nil) or (playerID == "") then
        error("thieveryKey() bad playerID")
    end
    return "tk_" .. tostring(playerID) .. "_" .. tostring(cellID)
end

local function newCellState(cellID, playerID)
    local playerKey = playerID
    if playerID.id ~= nil then
        playerKey = playerID.id
    end
    return {
        cellID = cellID,
        playerID = playerKey,
        -- itemIDtoOwnership is map of item instance id to actor id.
        itemIDtoOwnership = {},
        -- spottedByActorId is a map of actor id -> true
        spottedByActorId = {},
        -- newItems is a map of new items the player picked up while in the cell.
        -- item id -> {item=item,count=(item.count),backupOwner=owner}
        newItems = {},
        -- startingBounty is the player's bounty when they enter a cell.
        startingBounty = 0
    }
end

local function getCellState(cellID, playerID)
    local playerKey = playerID
    if playerID.id ~= nil then
        playerKey = playerID.id
    end
    local cellState = persistedState[thieveryKey(cellID, playerKey)]
    -- settings.debugPrint("getCellState(...) for player: " .. tostring(playerID) .. ", cell: " .. tostring(cellID))
    -- settings.debugPrint("getCellState(" .. tostring(cellID) .. ", " .. tostring(playerID) .. "): " ..
    --                        aux_util.deepToString(cellState, 3))
    if cellState ~= nil then
        return cellState
    end
    return newCellState(cellID, playerKey)
end

local function saveCellState(cellState)
    -- settings.debugPrint("saveCellState(...) for player: " .. tostring(cellState.playerID) .. ", cell: " ..
    --                        tostring(cellState.cellID))
    -- settings.debugPrint("saveCellState(" .. aux_util.deepToString(cellState, 3) .. ")")
    persistedState[thieveryKey(cellState.cellID, cellState.playerID)] = cellState
end

local function clearCellState(cellState)
    settings.debugPrint("clearCellState(...) for player: " .. tostring(cellState.playerID) .. ", cell: " ..
        tostring(cellState.cellID))
    persistedState[thieveryKey(cellState.cellID, cellState.playerID)] =
        newCellState(cellState.cellID, cellState.playerID)
end

local function isBandit(player, actor)
    -- assume if they want to fight us on sight that they are a bandit.
    -- bandits won't report theft, so don't assign ownership to them.
    -- 30 is normal for friendly NPCs.
    -- chargen boat guard has 70!
    -- bandits have 90 and 0 disposition
    local fightStat = types.Actor.stats.ai.fight(actor).base
    local startDisposition = types.NPC.getBaseDisposition(actor, player)
    if fightStat >= 90 and startDisposition <= 40 then
        settings.debugPrint(actor.recordId .. " might be a bandit")
        return true
    end
    return false
end

-- trackOwnedItems resets state.itemIDtoOwnership.
local function trackOwnedItems(cellID, player)
    local playerID = player.id
    settings.debugPrint("trackOwnedItems(" .. tostring(cellID) .. ") start")

    local cell = world.getCellById(cellID)
    if cell == nil then
        error("bad cell " .. cellID)
        return
    end
    settings.debugPrint("Finding owned items in " .. cell.name)

    local cellState = getCellState(cellID, playerID)
    -- reset to empty.
    cellState.itemIDtoOwnership = {}

    -- Save ownership state for loose items and actor inventories.
    for _, item in ipairs(cell:getAll()) do
        if types.Item.objectIsInstance(item) then
            cellState.itemIDtoOwnership[item.id] = common.serializeOwner(item.owner)
        elseif types.NPC.objectIsInstance(item) and (isBandit(player, item) ~= true) then
            local backupOwner = {
                recordId = item.recordId
            }
            for k, v in pairs(common.getInventoryOwnership(types.NPC.inventory(item), backupOwner)) do
                if v.owner == nil then
                    -- Assume owner is the holder if not explicit.
                    cellState.itemIDtoOwnership[k.id] = {
                        recordId = item.recordId
                    }
                else
                    cellState.itemIDtoOwnership[k] = v.owner
                end
            end
            -- could do containers here, but they may not be resolved yet.
        end
    end

    saveCellState(cellState)

    settings.debugPrint("trackOwnedItems(" .. tostring(cellID) .. ") end")
end

local skipNextBountyIncrease = false
-- itemRecordIDtoOwnerOverride is a backup way to get owners for items.
local itemRecordIDtoOwnerOverride = {}

-- Save ownership data for containers when they are activated.
-- Adds elements to state.itemIDtoOwnership.
local function onActivate(object, actor)
    itemRecordIDtoOwnerOverride = {}

    if types.Player.objectIsInstance(actor) ~= true then
        return
    end

    if types.Container.objectIsInstance(object) then
        settings.debugPrint("onActivate(" .. tostring(object.id) .. ", player)")
        local containerRecord = types.Container.record(object)
        local inventory = types.Container.inventory(object)
        if (inventory:isResolved() ~= true) and (containerRecord.isOrganic == false) then
            -- We can't resolve organic containers because it breaks Graphic Herbalism
            -- in OpenMW 0.50. There's a race condition where the plant mesh is not updated.
            inventory:resolve()
            settings.debugPrint("resolved not-organic container " .. containerRecord.id)
            inventory = types.Container.inventory(object)
        end

        -- Objects in containers don't have owners.
        local owner = nil
        if common.serializeOwner(object.owner) ~= nil then
            owner = common.serializeOwner(object.owner)
            settings.debugPrint("got container owner: " .. aux_util.deepToString(owner))
        end

        -- track items in the container
        local cellState = getCellState(actor.cell.id, actor.id)
        for k, v in pairs(common.getInventoryOwnership(inventory, owner)) do
            if v.owner ~= nil then
                cellState.itemIDtoOwnership[k] = v.owner

                itemRecordIDtoOwnerOverride[v.item.recordId] = v.owner
                if string.match(v.item.recordId, "gold_.*") then
                    -- special case for stacks of gold.
                    itemRecordIDtoOwnerOverride["gold_001"] = v.owner
                end

                settings.debugPrint("tracked item in container: " .. k .. " has owner " .. aux_util.deepToString(owner))
            else
                settings.debugPrint("tracked item in container: " .. k .. " has no owner")
            end
        end
        saveCellState(cellState)
    elseif types.Item.objectIsInstance(object) then
        -- This is for Shop Around compliance.
        -- If we are picking up an item off a shelf, check to see if it still
        -- has ownership. If it doesn't, remove it from the tracked list.
        local owner = common.serializeOwner(object.owner)

        itemRecordIDtoOwnerOverride[object.recordId] = owner
        if string.match(object.recordId, "gold_.*") then
            -- special case for stacks of gold.
            itemRecordIDtoOwnerOverride["gold_001"] = owner
        end

        if owner == nil then
            -- remove from tracker
            local cellState = getCellState(actor.cell.id, actor.id)
            if cellState.itemIDtoOwnership[object.id] ~= nil then
                settings.debugPrint("Removing " .. object.recordId .. " from ownership tracking.")
                cellState.itemIDtoOwnership[object.id] = nil
                saveCellState(cellState)
            end
        end
    elseif types.NPC.objectIsInstance(object) then
        settings.debugPrint("activated " .. object.recordId)
        actor:sendEvent(settings.MOD_NAME .. "onNPCActivated", {
            npc = object
        })
    end

    -- settings.debugPrint("backup owners: " .. aux_util.deepToString(itemRecordIDtoOwnerOverride, 3))
end

-- onSpotted is called when a player is spotted by an NPC.
-- params:
-- player
-- cellID
-- npc
-- override
local function onSpotted(data)
    settings.debugPrint("onSpotted(" .. aux_util.deepToString(data) .. ")")
    local cellState = getCellState(data.cellID, data.player.id)
    cellState.spottedByActorId[data.npc.id] = true
    saveCellState(cellState)
    interfaces.ErnBurglary.__onSpotted(data.player, data.npc, data.cellID)
    if data.override then
        settings.setDisableDetection(true)
    end
end

-- params:
-- player
-- cellID
local function onCellEnter(data)
    settings.debugPrint("onCellEnter(" .. aux_util.deepToString(data) .. ")")

    -- clean up new cell
    -- wow this cell state pattern is gross
    -- local cellState = getCellState(data.cellID, data.player.id)
    -- clearCellState(cellState)

    -- save bounty
    local cellState = getCellState(data.cellID, data.player.id)
    local bounty = types.Player.getCrimeLevel(data.player)
    settings.debugPrint("read bounty: " .. tostring(bounty))
    cellState.startingBounty = bounty
    saveCellState(cellState)

    -- When we enter a cell, we need to persist ownership data
    -- for all items. We have to do this because ownership data
    -- is lost when the item is placed in the player's inventory.
    trackOwnedItems(data.cellID, data.player)

    -- settings.debugPrint("onCellEnter() done. new cell state: " ..
    --                        aux_util.deepToString(getCellState(data.cellID, data.player.id), 3))
end

local function npcIDsToInstances(cellState)
    local cellID = cellState.cellID
    local cell = world.getCellById(cellID)
    if cell == nil then
        error("bad cell " .. tostring(cellID))
    end

    local out = {}
    for _, npc in pairs(cell:getAll(types.NPC)) do
        if cellState.spottedByActorId[npc.id] == true then
            -- settings.debugPrint("found NPC instance " .. npc.id .. ": " .. aux_util.deepToString(npc))
            out[npc.id] = npc
        end
    end
    return out
end

local function filterDeadNPCs(npcIDtoInstanceMap)
    local out = {}
    for id, npcInstance in pairs(npcIDtoInstanceMap) do
        if types.Actor.isDead(npcInstance) or types.Actor.isDeathFinished(npcInstance) then
            settings.debugPrint("npc " .. npcInstance.id .. " is dead")
        else
            -- settings.debugPrint("npc " .. npcInstance.id .. " is NOT dead")
            out[id] = npcInstance
        end
    end
    return out
end

local function guardsExist(npcIDtoInstanceMap)
    for _, npcInstance in pairs(npcIDtoInstanceMap) do
        local record = types.NPC.record(npcInstance)
        if string.lower(record.class) == "guard" then
            return true
        end
    end
    return false
end

local function factionsOfNPCs(npcIDtoInstanceMap)
    local out = {}
    for _, npcInstance in pairs(npcIDtoInstanceMap) do
        for _, faction in ipairs(types.NPC.getFactions(npcInstance)) do
            out[faction] = true
            -- settings.debugPrint("added faction " .. faction)
        end
    end
    return out
end

local function increaseBounty(player, amount)
    local currentCrime = types.Player.getCrimeLevel(player)
    if amount < 0 then
        error("increaseBounty(player," .. amount .. ") would reduce bounty")
        return
    end
    print("Increased bounty by " .. amount)
    skipNextBountyIncrease = true
    types.Player.setCrimeLevel(player, currentCrime + amount)
    skipNextBountyIncrease = true
end

local function revertBounty(player, cellState)
    if settings.revertBounties() ~= true then
        return
    end

    local startingBounty = cellState.startingBounty
    local currentBounty = types.Player.getCrimeLevel(player)

    if currentBounty <= startingBounty then
        settings.debugPrint("bounty didn't increase, won't do anything")
        return
    end

    print("Reverting bounty from " .. currentBounty .. " to " .. startingBounty .. ".")
    types.Player.setCrimeLevel(player, startingBounty)
end

-- returns bounty to apply
local function handleTheftSeenByGuard(player, value)
    settings.debugPrint("handleTheftSeenByGuard(player, " .. value .. ")")
    local bounty = value * settings.bountyScale()
    print("Theft seen by guard increased bounty by " .. bounty .. ".")
    return bounty
end

-- returns bounty to apply
local function handleTheftFromNPC(player, npc, value)
    settings.debugPrint("handleTheftFromNPC(player, " .. npc.id .. ", " .. value .. ")")
    -- npc is an instance.
    local startDisposition = types.NPC.getBaseDisposition(npc, player)

    local dispoPenalty = math.min(startDisposition, value)
    types.NPC.modifyBaseDisposition(npc, player, -1 * dispoPenalty)

    local bounty = (value - dispoPenalty) * settings.bountyScale()

    print("Theft from " .. npc.recordId .. " dropped disposition by " .. dispoPenalty .. " from " .. startDisposition ..
        ", and increased bounty by " .. bounty .. ".")
    return bounty
end

-- returns bounty to apply
local function handleTheftFromFaction(player, faction, value)
    settings.debugPrint("handleTheftFromFaction(player, " .. faction .. ", " .. value .. ")")

    if settings.lenientFactions() then
        print("Theft from " .. faction .. " (lenient).")
        return value * settings.bountyScale()
    end

    local startReputation = types.NPC.getFactionReputation(player, faction)

    -- faction reputation is hard to fix. consider making
    -- this less a pain.
    local reputationPenalty = math.min(startReputation, value)
    types.NPC.modifyFactionReputation(player, faction, -1 * reputationPenalty)

    local bounty = (value - reputationPenalty) * settings.bountyScale()

    local expelled = false
    if bounty > 0 then
        for _, playerFaction in ipairs(types.NPC.getFactions(player)) do
            if playerFaction == faction then
                types.NPC.expel(player, playerFaction)
                player:sendEvent(settings.MOD_NAME .. "showExpelledMessage", {
                    faction = faction
                })
                expelled = true
            end
        end
    end

    print("Theft from " .. faction .. " dropped reputation by " .. reputationPenalty .. " from " .. startReputation ..
        ". Expelled: " .. tostring(expelled))

    return bounty
end

-- params:
-- player
-- cellID
local function resolvePendingTheft(data)
    settings.debugPrint("resolvePendingTheft() start")

    -- This is where the magic happens, when we resolve which items have
    -- been stolen, and from whom.
    local cellState = getCellState(data.cellID, data.player.id)

    -- settings.debugPrint("resolvePendingTheft() cell state: " .. aux_util.deepToString(cellState, 3))

    -- list of living actors that spotted the player.
    local spottedByActorInstance = filterDeadNPCs(npcIDsToInstances(cellState))
    local spottedByFactionID = factionsOfNPCs(spottedByActorInstance)
    -- if guards spotted you, they will always report it.
    local spottedByGuards = guardsExist(spottedByActorInstance)
    if spottedByGuards then
        settings.debugPrint("spotted by guards")
    end
    if data.redHanded then
        settings.debugPrint("caught red-handed, so assume at least guards got us.")
        -- this is a funny situation because the game detected the theft,
        -- but we might have not.
        spottedByGuards = true
    end

    local npcRecordToInstance = {}
    for _, instance in pairs(spottedByActorInstance) do
        -- this is missing people?
        npcRecordToInstance[instance.recordId] = instance
        settings.debugPrint("npcRecordToInstance[" .. instance.recordId .. "] = " .. aux_util.deepToString(instance))
    end

    local totalTheftValue = 0

    -- indexed by npc instance id
    local npcOwnerTheftValue = {}
    -- indexed by faction id
    local factionOwnerTheftValue = {}
    local guardTheftValue = 0

    local stolenCallBacks = {}

    settings.debugPrint("checking new items for theft...")
    -- build up value of all stolen goods
    for newItemID, newItemBag in pairs(cellState.newItems) do
        local newItem = newItemBag.item
        if newItem == nil then
            error("newItem is nil for id " .. tostring(newItemID))
        end
        if (newItem.type == nil) then
            error("newItem is bad for id " .. tostring(newItemID) .. ": " .. aux_util.deepToString(newItem, 2))
        end
        -- This is the non-deprecated way to get an object record:
        -- local objectRecord = object.type.records[object.recordId]
        local itemRecord = newItem.type.records[newItem.recordId]
        if (itemRecord == nil) then
            error("failed to get valid record for item: " .. aux_util.deepToString(newItem, 2))
        end

        local value = itemRecord.value
        if value == nil then
            error("value for " .. itemRecord.name .. " is nil")
        end
        if newItemBag.count > 1 then
            settings.debugPrint("multiplying value of " .. itemRecord.name .. " (" .. value .. ") by count " ..
                newItemBag.count .. ".")
            value = value * newItemBag.count
        end

        local owner = cellState.itemIDtoOwnership[newItem.id]

        if owner == nil then
            settings.debugPrint("using backup owner for " .. itemRecord.name)
            owner = newItemBag.backupOwner
        end

        if (owner == nil) then
            -- the item is not owned.
            settings.debugPrint("assessing " .. newItemBag.count .. " new item: " .. itemRecord.name .. "(" ..
                newItem.id .. "): not owned by anyone")
        elseif (owner.recordId ~= nil) then
            settings.debugPrint("assessing " .. newItemBag.count .. " new item: " .. itemRecord.name .. "(" ..
                newItem.id .. ") owned by " .. tostring(owner.recordId) .. "/" ..
                tostring(owner.factionId) .. "(" .. tostring(owner.factionRank) .. "), gp value: " ..
                value)
            -- the item is owned by an individual.
            -- if that individual is alive, they will report.
            -- instance can be nil if the actor is dead.
            local instance = npcRecordToInstance[owner.recordId]
            if (instance == nil) then
                settings.debugPrint("can't find actor instance for " .. tostring(owner.recordId))
                if spottedByGuards then
                    guardTheftValue = guardTheftValue + value
                    settings.debugPrint("theft spotted by guards")
                    totalTheftValue = totalTheftValue + value

                    table.insert(stolenCallBacks, {
                        player = data.player,
                        itemInstance = newItem,
                        itemRecord = itemRecord,
                        count = newItemBag.count,
                        owner = owner,
                        cellID = data.cellID,
                        caught = true
                    })
                else
                    table.insert(stolenCallBacks, {
                        player = data.player,
                        itemInstance = newItem,
                        itemRecord = itemRecord,
                        count = newItemBag.count,
                        owner = owner,
                        cellID = data.cellID,
                        caught = false
                    })
                end
            elseif (spottedByActorInstance[instance.id]) then
                settings.debugPrint("you were spotted taking " .. newItemBag.count .. " " .. itemRecord.name)
                totalTheftValue = totalTheftValue + value
                if npcOwnerTheftValue[instance.id] == nil then
                    npcOwnerTheftValue[instance.id] = 0
                end
                npcOwnerTheftValue[instance.id] = npcOwnerTheftValue[instance.id] + value

                table.insert(stolenCallBacks, {
                    player = data.player,
                    itemInstance = newItem,
                    itemRecord = itemRecord,
                    count = newItemBag.count,
                    owner = owner,
                    cellID = data.cellID,
                    caught = true
                })
            else
                table.insert(stolenCallBacks, {
                    player = data.player,
                    itemInstance = newItem,
                    itemRecord = itemRecord,
                    count = newItemBag.count,
                    owner = owner,
                    cellID = data.cellID,
                    caught = false
                })
            end
        elseif (owner.factionId ~= nil) and
            (common.atLeastRank(data.player, owner.factionId, owner.factionRank) == false) then
            settings.debugPrint("assessing " .. newItemBag.count .. " new item: " .. itemRecord.name .. "(" ..
                newItem.id .. ") owned by " .. tostring(owner.recordId) .. "/" ..
                tostring(owner.factionId) .. "(" .. tostring(owner.factionRank) .. "), gp value: " ..
                value)

            -- the item is owned by a faction.
            -- if any members of the faction spotted the player,
            -- they will report it.
            if ((spottedByFactionID[owner.factionId] == true) or spottedByGuards) then
                settings.debugPrint("you were spotted taking " .. itemRecord.name)
                totalTheftValue = totalTheftValue + value
                if factionOwnerTheftValue[owner.factionId] == nil then
                    factionOwnerTheftValue[owner.factionId] = 0
                end
                factionOwnerTheftValue[owner.factionId] = factionOwnerTheftValue[owner.factionId] + value

                table.insert(stolenCallBacks, {
                    player = data.player,
                    itemInstance = newItem,
                    itemRecord = itemRecord,
                    count = newItemBag.count,
                    owner = owner,
                    cellID = data.cellID,
                    caught = true
                })
            else
                table.insert(stolenCallBacks, {
                    player = data.player,
                    itemInstance = newItem,
                    itemRecord = itemRecord,
                    count = newItemBag.count,
                    owner = owner,
                    cellID = data.cellID,
                    caught = false
                })
            end
        end
    end

    local totalBounty = 0

    -- punish for npc theft
    for npcID, value in pairs(npcOwnerTheftValue) do
        totalBounty = totalBounty + handleTheftFromNPC(data.player, spottedByActorInstance[npcID], value)
    end
    -- punish for faction theft
    for factionID, value in pairs(factionOwnerTheftValue) do
        totalBounty = totalBounty + handleTheftFromFaction(data.player, factionID, value)
    end

    if guardTheftValue > 0 then
        totalBounty = totalBounty + handleTheftSeenByGuard(data.player, guardTheftValue)
    end

    -- TODO: use https://openmw.readthedocs.io/en/stable/reference/lua-scripting/interface_crimes.html#interface-crimes
    -- this would make crime penalties match vanilla.
    -- maybe just use this to find witnesses with wasCrimeSeen?

    if totalBounty > 0 then
        -- this spawns a popup message each time.
        -- that's why we only apply it once.
        increaseBounty(data.player, totalBounty)
    elseif totalTheftValue > 0 then
        -- tell player they were caught (when bounty did not increase).
        data.player:sendEvent(settings.MOD_NAME .. "showWantedMessage", {
            value = totalTheftValue
        })
    end

    -- clear stolen items tracking since we resolved them
    cellState.newItems = {}
    saveCellState(cellState)

    -- invoke callbacks
    if #stolenCallBacks > 0 then
        interfaces.ErnBurglary.__onStolen(stolenCallBacks)
    end
end

local function onCellExit(data)
    settings.debugPrint("onCellExit(" .. aux_util.deepToString(data) .. ")")

    -- This is where the magic happens, when we resolve which items have
    -- been stolen, and from whom.
    local cellState = getCellState(data.cellID, data.player.id)

    -- list of living actors that spotted the player.
    local spottedByActorInstance = filterDeadNPCs(npcIDsToInstances(cellState))

    local witnessesExist = false
    for _, instance in pairs(spottedByActorInstance) do
        witnessesExist = true
        break
    end

    -- we have to revert bounties between exiting a cell and entering a cell.
    if witnessesExist ~= true then
        revertBounty(data.player, cellState)
    end

    -- apply theft
    resolvePendingTheft(data)

    -- clean up old cell
    local cellState = getCellState(data.cellID, data.player.id)
    clearCellState(cellState)
end

local function onCellChange(data)
    if (data == nil) or (data.player == nil) then
        error("bad data")
    end
    if data.lastCellID ~= nil then
        onCellExit({
            player = data.player,
            cellID = data.lastCellID
        })
        -- lastCellID might be nil on load.
        interfaces.ErnBurglary.__onNoWitnesses(data.player, data.newCellID)
    end

    onCellEnter({
        player = data.player,
        cellID = data.newCellID
    })

    interfaces.ErnBurglary.__onCellChange(data)
end

-- params:
-- player
-- cellID
-- itemsList
local function onNewItems(data)
    -- this is not called when the game is paused.
    settings.debugPrint("onNewItems(" .. aux_util.deepToString(data) .. ")")
    local cellState = getCellState(data.cellID, data.player.id)
    for _, itemBag in ipairs(data.itemsList) do
        if (itemBag ~= nil) and (itemBag.item ~= nil) and itemBag.item:isValid() then
            if cellState.newItems[itemBag.item.id] ~= nil then
                -- check for stack change
                local oldCount = cellState.newItems[itemBag.item.id].count
                local newCount = oldCount + itemBag.count
                itemBag = {
                    item = itemBag.item,
                    count = newCount
                }
                settings.debugPrint("increased stack of new item " .. itemBag.item.recordId .. " from " .. oldCount ..
                    " to " .. newCount)
            end

            local backupOwner = itemRecordIDtoOwnerOverride[itemBag.item.recordId]
            if backupOwner ~= nil then
                settings.debugPrint("found backup owner of new item " .. itemBag.item.recordId .. ": " ..
                    aux_util.deepToString(backupOwner, 3))
                itemBag = {
                    item = itemBag.item,
                    count = itemBag.count,
                    backupOwner = backupOwner
                }
            end

            cellState.newItems[itemBag.item.id] = itemBag
        else
            settings.debugPrint("item is nil or invalid")
        end
    end
    saveCellState(cellState)
    itemRecordIDtoOwnerOverride = {}
end

local infrequentMap = infrequent.FunctionCollection:new()

-- This just fires off the "no more witnesses" message.
local function noWitnessCheck(dt)
    -- loop through all players and check if they have witnesses
    for _, player in ipairs(world.players) do
        local cellState = getCellState(player.cell.id, player.id)
        local spottedByActorInstance = filterDeadNPCs(npcIDsToInstances(cellState))
        local anyPresent = false
        for _, _ in pairs(spottedByActorInstance) do
            anyPresent = true
            break
        end
        if anyPresent == false then
            -- TODO: there's a big bug here.
            -- this also needs to fire when we enter the new cell,
            -- but before we get spotted by another NPC.
            interfaces.ErnBurglary.__onNoWitnesses(player, player.cell.id)
        end
    end
end

infrequentMap:addCallback("noWitnessCheck", 0.5, noWitnessCheck)

local function onUpdate(dt)
    if dt ~= 0 then
        infrequentMap:onUpdate(dt)
    end
end

-- monitor for bounty increases. if it goes up, resolve pending thefts.
local function onBountyIncreased(data)
    -- this var exists so we don't process cold-case thefts
    if skipNextBountyIncrease then
        settings.debugPrint("ignoring bounty increase")
        skipNextBountyIncrease = false
        return
    end

    -- loop through all players and check if they have witnesses

    local cellState = getCellState(data.player.cell.id, data.player.id)

    local oldBounty = data.oldBounty
    local newBounty = data.newBounty

    -- did bounty go up? if so, we got caught.
    -- grab the nearest NPC and add them to the spotted list.
    -- we do this to reconcile the game detecting a theft/crime where we might
    -- not have.
    local closestActor = nil
    local closestDistance = 100000000
    for _, actor in ipairs(data.player.cell:getAll(types.NPC)) do
        local distance = (data.player.position - actor.position):length2()
        if types.Actor.isDead(actor) or types.Actor.isDeathFinished(actor) then
            settings.debugPrint(actor.recordId .. " is dead")
        elseif (distance < closestDistance) then
            closestDistance = distance
            closestActor = actor
        end
    end
    if closestActor ~= nil then
        settings.debugPrint("bounty increased from " .. oldBounty .. " to " .. newBounty .. ". Assuming " ..
            closestActor.recordId .. " spotted us.")
        onSpotted({
            player = data.player,
            cellID = data.player.cell.id,
            npc = closestActor
        })
    end

    -- resolvePendingTheft might change bounty
    resolvePendingTheft({
        player = data.player,
        cellID = data.player.cell.id,
        redHanded = true
    })
end

local function onPaidBounty(data)
    settings.debugPrint("detected bounty payoff")
    local cellState = getCellState(data.player.cell.id, data.player.id)
    cellState.startingBounty = 0
    saveCellState(cellState)
end

local resendSpottedStatusCallback = async:registerTimerCallback(settings.MOD_NAME .. "_resendSpottedStatusCallback",
    function(data)
        for _, player in ipairs(world.players) do
            local cellState = getCellState(player.cell.id, player.id)
            for npcID, spotted in pairs(cellState.spottedByActorId) do
                if spotted then
                    settings.debugPrint("re-sending spotted status by " .. npcID)
                    onSpotted({
                        player = player,
                        cellID = player.cell.id,
                        npc = {
                            id = npcID
                        }
                    })
                end
            end
        end
    end)

local function saveState()
    return persistedState
end

local function loadState(saved)
    if saved == nil then
        persistedState = {}
    else
        persistedState = saved
        -- re-send spotted events on load.
        async:newGameTimer(0.1, resendSpottedStatusCallback, {})
    end
end

return {
    eventHandlers = {
        [settings.MOD_NAME .. "onSpotted"] = onSpotted,
        [settings.MOD_NAME .. "onCellChange"] = onCellChange,
        [settings.MOD_NAME .. "onNewItem"] = onNewItems,
        [settings.MOD_NAME .. "onPaidBounty"] = onPaidBounty,
        [settings.MOD_NAME .. "onBountyIncreased"] = onBountyIncreased
    },
    engineHandlers = {
        onSave = saveState,
        onLoad = loadState,
        onActivate = onActivate,
        onUpdate = onUpdate,
        onNewGame = onNewGame
    }
}
