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
local aux_util = require('openmw_aux.util')

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
    return
end

local function isFunction(obj)
    if type(obj) ~= "function" then
        error("not a function: " .. aux_util.deepToString(obj, 3))
        return false
    end
    return true
end

local coroutines = {}

local function addCoroutine(callback, data)
    isFunction(callback)
    if data == nil then
        error("data is nil")
    end
    table.insert(coroutines, {
        c = callback,
        data = data
    })
end

local function onUpdate()
    -- Only run one callback per frame.
    if #coroutines > 0 then
        local bag = table.remove(coroutines, 1)
        --settings.debugPrint("Running callback with data=".. aux_util.deepToString(bag.data, 2))
        bag.c(bag.data)
    end
end

local onSpottedCallbacks = {}
local spottedPlayerStatus = {}

-- onSpottedCallback adds a callback to be invoked whenever the player's Spotted status changes.
-- This could be used to power a trespassing mod or whatever else.
-- The params passed into the callback is a table with these fields:
-- - player
-- - spotted (boolean)
local function onSpottedChangeCallback(callback)
    isFunction(callback)
    table.insert(onSpottedCallbacks, callback)
    settings.debugPrint("Registered callback #" .. #onSpottedCallbacks .. " for onSpottedChangeCallback().")
end

local function __onSpotted(player, npc, cellID)
    if (spottedPlayerStatus[player.id] == true) then
        return
    end
    spottedPlayerStatus[player.id] = true

    for _, callback in ipairs(onSpottedCallbacks) do
        addCoroutine(callback, {
            player = player,
            npc = npc,
            spotted = true,
            cellID = cellID
        })
    end
end

local function __onNoWitnesses(player, cellID)
    if (spottedPlayerStatus[player.id] == false) then
        return
    end
    spottedPlayerStatus[player.id] = false

    for _, callback in ipairs(onSpottedCallbacks) do
        addCoroutine(callback, {
            player = player,
            spotted = false,
            cellID = cellID
        })
    end
end

local onStolenCallbacks = {}

-- onStolenCallback adds a callback to be invoked whenever the player steals an item.
-- This could be used to power a spawn-detectives mod or whatever.
-- The param is a list of tables. Each table has these fields:
-- - player
-- - itemInstance
-- - itemRecordID
-- - owner
-- - count (number in the stack that was stolen. at least 1.)
-- - cellID (cell the theft occurred in. might not be the player's current cell.)
-- - caught (boolean indicating if the player was caught stealing it)
local function onStolenCallback(callback)
    isFunction(callback)
    table.insert(onStolenCallbacks, callback)
    settings.debugPrint("Registered callback #" .. #onStolenCallbacks .. " for onStolenCallback().")
end

local function __onStolen(data)
    for _, callback in ipairs(onStolenCallbacks) do
        addCoroutine(callback, data)
    end
end

local onCellChangeCallbacks = {}

-- onCellChangeCallback adds a callback to be invoked whenever the Player
-- changes their current cell.
-- The param is a list of tables. Each table has these fields:
-- - player
-- - lastCellID
-- - newCellID
local function onCellChangeCallback(callback)
    isFunction(callback)
    table.insert(onCellChangeCallbacks, callback)
    settings.debugPrint("Registered callback #" .. #onCellChangeCallbacks .. " for onCellChangeCallbacks().")
end

local function __onCellChange(data)
    for _, callback in ipairs(onCellChangeCallbacks) do
        addCoroutine(callback, data)
    end
end

-- setItemsAllowed will set the InDialogue flag.
-- While this flag is true, any new items gained will not be counted as stolen.
-- This is not a permanent change. ErnBurglary will reset this flag if
-- the player's UI mode changes into, or out of, "Dialogue" mode.
-- This exists to allow for patching with Pause Control.
local function setItemsAllowed(player, allowed)
    player:sendEvent(settings.MOD_NAME .. "setItemsAllowed", {
        allowed = allowed
    })
end

return {
    interfaceName = settings.MOD_NAME,
    interface = {
        version = 1,
        setItemsAllowed = setItemsAllowed,
        onSpottedChangeCallback = onSpottedChangeCallback,
        onStolenCallback = onStolenCallback,
        onCellChangeCallback = onCellChangeCallback,
        __onSpotted = __onSpotted,
        __onNoWitnesses = __onNoWitnesses,
        __onStolen = __onStolen,
        __onCellChange = __onCellChange
    },
    engineHandlers = {
        onUpdate = onUpdate
    }
}
