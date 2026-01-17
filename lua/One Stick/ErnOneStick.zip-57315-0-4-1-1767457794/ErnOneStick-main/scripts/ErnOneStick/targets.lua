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

-- targetWeight returns a big number if we are looking at the
-- entity and it is close.
local function targetWeight(entity)
    local facing = camera.viewportToWorldVector(util.vector2(0.5, 0.5)):normalize()
    local relativePos = (pself:getBoundingBox().center - entity:getBoundingBox().center)
    -- dot product returns 0 if at 90*, 1 if codirectional, -1 if opposite.
    local faceWeight = 100 * (4 + facing:dot(relativePos))
    return faceWeight / (relativePos:length())
end

local function xyFacing(v1, v2)
    return util.vector2(v1.x - v2.x, v1.y - v2.y):normalize()
end
local function xyCross(v1, v2)
    return v1.x * v2.y - v1.y * v2.x
end

function TargetCollection:sort()
    if self.sorted then
        return
    end
    self.sorted = true

    -- cast to list.
    local filtered = {}
    for _, e in ipairs(self.gameObjects) do
        if self.filterFn(e) then
            table.insert(filtered, e)
        end
    end
    self.gameObjects = filtered

    -- don't do anything if we don't have any targets
    if #self.gameObjects == 0 then
        --print("no objects")
        return
    end

    -- first, find the most-probable target.
    local bestTarget = nil
    local bestTargetWeight = 0
    for i, e in ipairs(self.gameObjects) do
        local w = targetWeight(e)
        if w > bestTargetWeight then
            bestTargetWeight = w
            bestTarget = e
        end
    end
    if bestTarget == nil then
        --print("no best object")
        return
    end

    -- next, sort all the objects by how left or right they are around that
    -- best target.
    -- close by left targets will be left of best,
    -- close by right targets will right of best.
    -- we do this by setting the weight of best to 0

    local bestTargetFacing = xyFacing(bestTarget:getBoundingBox().center, pself:getBoundingBox().center)
    local weight = {}
    for i, e in ipairs(self.gameObjects) do
        if e == bestTarget then
            weight[e.id] = 0
            --print(e.recordId .. " - BEST!")
        else
            local facing = xyFacing(e:getBoundingBox().center, pself:getBoundingBox().center)
            weight[e.id] = (-1) * xyCross(bestTargetFacing, facing)
            --print(e.recordId .. " - " .. weight[e.id] .. " facing(" .. tostring(facing) .. ")")
        end
    end
    --print(bestTarget.recordId .. " is best." .. " facing(" .. tostring(bestTargetFacing) .. ")")
    table.sort(self.gameObjects, function(a, b) return weight[a.id] < weight[b.id] end)
end

function TargetCollection:next(peek)
    self:sort()
    if #(self.gameObjects) == 0 then
        return nil
    end

    if not peek then
        self.currentIdx = self.currentIdx + 1
        if self.currentIdx > #(self.gameObjects) then
            self.currentIdx = 1
        end
    end

    -- make sure object is still ok.
    if self.filterFn(self.gameObjects[self.currentIdx]) ~= true then
        table.remove(self.gameObjects, self.currentIdx)
        return self:next()
    end
    return self.gameObjects[self.currentIdx]
end

function TargetCollection:previous(peek)
    self:sort()
    if #(self.gameObjects) == 0 then
        return nil
    end

    if not peek then
        self.currentIdx = self.currentIdx - 1
        if self.currentIdx <= 0 then
            self.currentIdx = #(self.gameObjects)
        end
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
