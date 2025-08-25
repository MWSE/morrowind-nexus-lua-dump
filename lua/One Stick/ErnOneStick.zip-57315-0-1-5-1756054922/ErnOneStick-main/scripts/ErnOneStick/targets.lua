--[[
ErnOneStick for OpenMW.
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

local camera = require('openmw.camera')
local util = require('openmw.util')
local pself = require("openmw.self")

TargetCollection = {}

function TargetCollection:new(gameObjects, filterFn)
    local collection = {
        gameObjects = gameObjects,
        sorted = false,
        currentIdx = 0,
        filterFn = filterFn or function(e) return true end,
    }
    setmetatable(collection, self)
    self.__index = self
    return collection
end

function TargetCollection:sort()
    -- Objects we are facing are weighted highly.
    -- Objects that are closer are weighted highly.
    if self.sorted then
        return
    end

    -- cast to list. delay filtering
    local filtered = {}
    for _, e in ipairs(self.gameObjects) do
        table.insert(filtered, e)
    end
    self.gameObjects = filtered

    -- could maybe use camera.viewportToWorldVector(0.5, 0.5) instead to get facing.
    --local facing = pself.rotation:apply(util.vector3(0.0, 1.0, 0.0)):normalize()
    local facing = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    -- sort by most weight first
    local weight = {}
    for i, e in ipairs(self.gameObjects) do
        local relativePos = (pself.position - e.position)
        -- dot product returns 0 if at 90*, 1 if codirectional, -1 if opposite.
        local faceWeight = 100 * (4 + facing:dot(relativePos))
        weight[e.id] = faceWeight / (relativePos:length())
    end
    table.sort(self.gameObjects, function(a, b) return weight[a.id] < weight[b.id] end)
    self.sorted = true
end

function TargetCollection:next()
    self:sort()
    if #(self.gameObjects) == 0 then
        return nil
    end
    self.currentIdx = self.currentIdx + 1

    if self.currentIdx > #(self.gameObjects) then
        self.currentIdx = 1
    end

    -- make sure object is still ok.
    if self.filterFn(self.gameObjects[self.currentIdx]) ~= true then
        table.remove(self.gameObjects, self.currentIdx)
        return self:next()
    end
    return self.gameObjects[self.currentIdx]
end

function TargetCollection:previous()
    self:sort()
    if #(self.gameObjects) == 0 then
        return nil
    end
    self.currentIdx = self.currentIdx - 1
    if self.currentIdx <= 0 then
        self.currentIdx = #(self.gameObjects)
    end

    -- make sure object is still ok.
    if self.filterFn(self.gameObjects[self.currentIdx]) ~= true then
        table.remove(self.gameObjects, self.currentIdx)
        return self:previous()
    end
    return self.gameObjects[self.currentIdx]
end

return {
    TargetCollection = TargetCollection
}
