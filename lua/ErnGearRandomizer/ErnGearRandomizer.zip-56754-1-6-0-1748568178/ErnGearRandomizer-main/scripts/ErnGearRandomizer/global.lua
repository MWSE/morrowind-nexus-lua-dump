--[[
ErnGearRandomizer for OpenMW.
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
local S = require("scripts.ErnGearRandomizer.settings")
local core = require("openmw.core")
local async = require('openmw.async')
local T = require("openmw.types")
local world = require("openmw.world")
local storage = require("openmw.storage")
local swapTable = require("scripts.ErnGearRandomizer.swaptable")

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

-- Init settings first to init storage which is used everywhere
S.initSettings()
-- Init swap table
swapTable.initTables()

local swapMarker = storage.globalSection(S.MOD_NAME .. "SwapMarker")
swapMarker:setLifeTime(storage.LIFE_TIME.GameSession)

local function delete(data)
    data:remove()
end

deleteCallback = async:registerTimerCallback("delete", delete)

local function swapItems(data)
    actor = data.actor
    oldItems = data.oldItems
    newItemRecordIDs = data.newItemRecordIDs

    mergedEquiplist = {}
    inventory = T.Actor.inventory(actor)

    for slot, oldItem in pairs(oldItems) do
        if newItemRecordIDs[slot] ~= nil then
            -- make a new item
            newItemInstance = world.createObject(newItemRecordIDs[slot])
            newItemInstance:moveInto(inventory)
            -- use it
            mergedEquiplist[slot] = newItemInstance
            -- delete old item in follow-up frame.
            -- this is to prevent flashing.
            async:newGameTimer(0.001, deleteCallback, oldItem)
            S.debugPrint("npc " .. actor.recordId .. ": " ..
            oldItem.recordId  .. " -> " .. newItemRecordIDs[slot] )    
        else
            -- use the existing item
            mergedEquiplist[slot] = oldItem
        end
    end

    actor:sendEvent("LMequipHandler", mergedEquiplist)

    -- mark swap as done
    if not S.debugMode then
        swapMarker:set(actor.id, true)
    end
end

local function saveState()
    return swapMarker:asTable()
end

local function loadState(saved)
    swapMarker:reset(saved)
end

local function resetSwapTables(data)
    S.debugPrint("Settings changed; recalculating swap tables.")
    swapTable.initTables()
end

return {
    eventHandlers = {
        LMswapItems = swapItems,
        LMmarkAsDone = markAsDone,
        LMresetSwapTables = resetSwapTables
    },
    engineHandlers = {
        onSave = saveState,
        onLoad = loadState
    }
}
