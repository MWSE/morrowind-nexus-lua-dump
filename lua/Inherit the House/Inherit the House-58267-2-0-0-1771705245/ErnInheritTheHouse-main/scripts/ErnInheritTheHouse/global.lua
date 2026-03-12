--[[
ErnInheritTheHouse for OpenMW.
Copyright (C) Erin Pentecost 2026

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

-- This file is in charge of tracking and exposing path information.
-- Interact with it via the interface it exposes.

local MOD_NAME = require("scripts.ErnInheritTheHouse.ns")
local types    = require("openmw.types")
local world    = require("openmw.world")

local function unsetOwner(obj)
    if obj.owner == nil then
        return
    end
    obj.owner.factionId = nil
    obj.owner.factionRank = nil
    obj.owner.recordId = nil
end

local function removeOwner(obj)
    print("Removing ownership on " .. tostring(obj.recordId))
    unsetOwner(obj)
    if types.Container.objectIsInstance(obj) then
        local inventory = types.Container.inventory(obj)
        if inventory:isResolved() then
            for _, itemInContainer in ipairs(inventory:getAll()) do
                unsetOwner(itemInContainer)
            end
        end
    end
end

local function onVacate(data)
    if not data.player then
        print("no player in data")
        return
    end
    if not data.cellID then
        print("no cellID in data")
        return
    end

    local cell = world.getCellById(data.cellID)

    print("Removing ownership...")
    local exteriors = {}
    for _, obj in ipairs(cell:getAll()) do
        removeOwner(obj)
        -- get outside door cells
        if types.Door.objectIsInstance(obj) then
            local destCell = types.Door.destCell(obj)
            if types.Door.isTeleport(obj) and (destCell ~= nil) then
                table.insert(exteriors, destCell)
            end
        end
    end

    -- set ownership on outside door
    for _, extCell in ipairs(exteriors) do
        for _, door in ipairs(extCell:getAll(types.Door)) do
            local destCell = types.Door.destCell(door)
            if types.Door.isTeleport(door) and (destCell == cell) then
                removeOwner(door)
            end
        end
    end
end

return {
    eventHandlers = {
        [MOD_NAME .. "onVacate"] = onVacate,
    },
}
