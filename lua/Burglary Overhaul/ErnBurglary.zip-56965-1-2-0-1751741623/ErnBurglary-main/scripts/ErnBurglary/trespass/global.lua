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
]] local settings = require("scripts.ErnBurglary.settings")
local interfaces = require('openmw.interfaces')
local types = require("openmw.types")
local aux_util = require('openmw_aux.util')
local common = require("scripts.ErnBurglary.common")
local core = require("openmw.core")

-- Track all persistedState we've ever picked up.
-- This is a map of "<player instance id> .. <key record id>" -> true.
-- Also contains "<player instance id>" -> <cell id they are currently trespassing in>
-- This lets us mark a door as safe even if the player removes the key at some point.
local persistedState = {}

local function saveState()
    return persistedState
end

local function loadState(saved)
    if saved == nil then
        persistedState = {}
    else
        persistedState = saved
    end
end

local function hasKey(door, actor)
    local keyRecord = types.Lockable.getKeyRecord(door)
    if keyRecord == nil then
        -- no key, so never allowed.
        settings.debugPrint("No key exists for door " .. door.id .. ".")
        return false
    end
    -- check if we previously had the key
    local mapKey = "key_" .. actor.id .. keyRecord.id
    if persistedState[mapKey] == true then
        settings.debugPrint("Remembered we have the key for " .. door.id .. ".")
        -- we had the key at one point.
        -- let them in.
        return true
    end
    -- check if we have the key right now.
    for _, item in ipairs(types.Actor.inventory(actor):getAll(types.Miscellaneous)) do
        if item.recordId == keyRecord.id then
            settings.debugPrint("We currently have the key for " .. door.id .. ".")
            -- memorize ownership of the key.
            persistedState[mapKey] = true
            -- let them in.
            return true
        end
    end
    settings.debugPrint("We don't have the key for " .. door.id .. ".")
    return false
end

local function setIsTrespassing(actor, destCell)
    -- we are trespassing!
    settings.debugPrint("Player " .. actor.id .. " is trespassing in " .. destCell.name .. " (" .. destCell.id .. ").")
    persistedState[actor.id] = destCell.id
    actor:sendEvent(settings.MOD_NAME .. "showTrespassingMessage", {})
end

local function cellHasOwnedItems(cell)
    for _, obj in ipairs(cell:getAll()) do
        if types.Container.objectIsInstance(obj) or types.Item.objectIsInstance(obj) then
            local owner = common.serializeOwner(obj.owner)
            if owner ~= nil then
                settings.debugPrint("Cell " .. cell.id .. " has an object owned by " ..
                                        aux_util.deepToString(owner, 2))
                return true
            end
        end
    end
    return false
end

local function onActivate(object, actor)

    if types.Player.objectIsInstance(actor) ~= true then
        return
    end

    if types.Door.objectIsInstance(object) then
        settings.debugPrint("onActivate(" .. tostring(object.id) .. ", player): " .. aux_util.deepToString(object, 3))
        if types.Door.isOpen(object) then
            -- this means we are closing the door.
            settings.debugPrint("door is open")
            return
        end
        local doorRecord = types.Door.records[object.recordId]
        if doorRecord.mwscript ~= nil then
            -- don't mess with scripted doors.
            settings.debugPrint("door has script")
            return
        end

        -- don't mess with non-teleport doors.
        local destCell = types.Door.destCell(object)
        if (types.Door.isTeleport(object) == false) or (destCell == nil) or (destCell.id == actor.cell.id) or
            (destCell.isExterior) or (destCell:hasTag("QuasiExterior")) then
            settings.debugPrint("door doesn't teleport into an interior")
            return
        end

        -- locked doors won't teleport us on activate
        if types.Lockable.isLocked(object) then
            settings.debugPrint("door is locked")
            return
        end

        -- If the door is owned, then we are always considered trespassing.
        if object.owner ~= nil then
            if object.owner.recordId ~= nil then
                settings.debugPrint("door is owned by " .. object.owner.recordId)
                setIsTrespassing(actor, destCell)
                return
            elseif (object.owner.factionId ~= nil) and
                (common.atLeastRank(actor, object.owner.factionId, object.owner.factionRank) == false) then
                settings.debugPrint("door is owned by " .. object.owner.factionId)
                setIsTrespassing(actor, destCell)
                return
            end
        end

        -- If the door has a key, we *might* be trespassing.
        -- Only consider us trespassing if we don't have the key,
        -- and if there is an owned item in the target cell.
        -- I check for owned items in order to exclude dungeons.
        local keyRecord = types.Lockable.getKeyRecord(object)
        if keyRecord ~= nil then
            settings.debugPrint("door has a key")
            if (hasKey(object, actor) ~= true) and (cellHasOwnedItems(destCell)) then
                setIsTrespassing(actor, destCell)
                return
            end
        end
    end
end

local function onCellChange(data)
    local trespassCellID = persistedState[data.player.id]
    if trespassCellID ~= nil then
        if data.newCellID ~= trespassCellID then
            settings.debugPrint("Player " .. data.player.id .. " is no longer trespassing in " .. trespassCellID .. ".")
            persistedState[data.player.id] = nil
        end
    end

end

interfaces.ErnBurglary.onCellChangeCallback(onCellChange)

local function onSpottedChange(data)
    -- TODO: fails when we change cell but the spot was calculated before we finished changing.
    -- we could stay spotted through a cell change.

    if data.spotted == false then
        return
    end
    settings.debugPrint("Player was spotted.")
    local trespassCellID = persistedState[data.player.id]
    if trespassCellID == nil then
        return
    end
    settings.debugPrint("Player was spotted trespassing in " .. trespassCellID .. ".")

    local fine = settings.trespassFine()
    if fine > 0 then
        local currentCrime = types.Player.getCrimeLevel(data.player)
        types.Player.setCrimeLevel(data.player, currentCrime + fine)
    end
end

interfaces.ErnBurglary.onSpottedChangeCallback(onSpottedChange)

return {
    eventHandlers = {},
    engineHandlers = {
        onSave = saveState,
        onLoad = loadState,
        onActivate = onActivate
    }
}
