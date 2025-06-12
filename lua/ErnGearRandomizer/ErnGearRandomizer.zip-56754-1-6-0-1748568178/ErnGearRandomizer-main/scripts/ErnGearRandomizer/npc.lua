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
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local T = require("openmw.types")
local S = require("scripts.ErnGearRandomizer.settings")
local swapTable = require("scripts.ErnGearRandomizer.swaptable")

local swapMarker = storage.globalSection(S.MOD_NAME .. "SwapMarker")

if require("openmw.core").API_REVISION < 62 then
    error("OpenMW 0.49 or newer is required!")
end

local function swapItems(npc)
    -- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_types.html##(Actor)
    oldItems = T.Actor.getEquipment(npc)
    newItemRecordIDs = {}

    for slot, oldItem in pairs(oldItems) do
        if oldItem ~= nil then
            newSwapRecord = nil
            if T.Armor.objectIsInstance(oldItem) then
                newSwapRecord = swapTable.getArmorRecordID(oldItem)
            end
            if T.Clothing.objectIsInstance(oldItem) then
                newSwapRecord = swapTable.getClothingRecordID(oldItem)
            end
            if T.Weapon.objectIsInstance(oldItem) then
                newSwapRecord = swapTable.getWeaponRecordID(oldItem)
            end

            if newSwapRecord then
                newItemRecordIDs[slot] = newSwapRecord
            end
        end
    end

    core.sendGlobalEvent("LMswapItems", {
        actor = npc,
        oldItems = oldItems, 
        newItemRecordIDs = newItemRecordIDs,
    })
end

local function equipHandler(data)
    T.Actor.setEquipment(self, data)
end

local function onActive()
    id = self.id
    if id == false then
        S.debugPrint("npc doesn't have an id???")
        return
    end

    -- filters so things don't get out of hand
    if self.type ~= T.NPC then
        S.debugPrint("npc script not applied on an NPC")
        return
    end

    if swapMarker:get(id, true) then
        S.debugPrint("npc " .. id .. " already handled")
        return
    end

    if T.NPC.objectIsInstance(self) == false then
        S.debugPrint("not an instance!")
        return
    end
    if T.Actor.isDead(self) or T.Actor.isDeathFinished(self) then
        S.debugPrint("npc " .. id .. " is dead, won't swap")
        return
    end
    record = T.NPC.record(self)
    if record == nil then
        S.debugPrint("npc " .. id .. " has no record?")
        return
    end
    if record.isEssential then
        S.debugPrint("npc record " .. record.id .. " is essential, won't swap")
        return
    end
    for classPattern in S.classBan() do
        if string.find(string.lower(record.class), classPattern) ~= nil then
            S.debugPrint("npc record " .. record.id .. " has a banned class " .. record.class)
            return false
        end
    end

    swapItems(self)
end

return {
    eventHandlers = {
        LMequipHandler = equipHandler
    },
    engineHandlers = {
        onActive = onActive
    }
}
