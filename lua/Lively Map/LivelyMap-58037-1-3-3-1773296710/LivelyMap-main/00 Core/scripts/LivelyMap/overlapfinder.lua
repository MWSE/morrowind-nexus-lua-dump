--[[
LivelyMap for OpenMW.
Copyright (C) Erin Pentecost 2025

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

--- Given a set of whatever, return a list of subsets of those things
--- that overlap.

local util = require('openmw.util')

---@class RectExtent
---@field topLeft util.vector2
---@field bottomRight util.vector2

---@alias RectGetter fun(element: any): RectExtent

----------------------------------------------------------------
-- Union-Find (Disjoint Set)
----------------------------------------------------------------

---@class UnionFind
---@field parent any
---@field rank any
local UnionFind = {}
UnionFind.__index = UnionFind

---@return UnionFind
local function NewUnionFind()
    local self = {
        parent = {},
        rank = {},
    }
    setmetatable(self, UnionFind)
    return self
end

---@param self UnionFind
---@param x integer
---@return integer
function UnionFind.find(self, x)
    local p = self.parent[x]
    if p ~= x then
        self.parent[x] = self:find(p)
    end
    return self.parent[x]
end

---@param self UnionFind
---@param x integer
---@param y integer
function UnionFind.union(self, x, y)
    local rx = self:find(x)
    local ry = self:find(y)
    if rx == ry then
        return
    end

    local rankX = self.rank[rx]
    local rankY = self.rank[ry]

    if rankX < rankY then
        self.parent[rx] = ry
    elseif rankX > rankY then
        self.parent[ry] = rx
    else
        self.parent[ry] = rx
        self.rank[rx] = rankX + 1
    end
end

---@param self UnionFind
---@param x integer
function UnionFind.makeSet(self, x)
    self.parent[x] = x
    self.rank[x] = 0
end

----------------------------------------------------------------
-- Rectangle overlap
----------------------------------------------------------------

---@param a RectExtent
---@param b RectExtent
---@return boolean
local function rectsOverlap(a, b)
    -- Inclusive overlap (touching edges counts)
    return not (
        a.bottomRight.x < b.topLeft.x or
        a.topLeft.x > b.bottomRight.x or
        a.bottomRight.y < b.topLeft.y or
        a.topLeft.y > b.bottomRight.y
    )
end

----------------------------------------------------------------
-- OverlapFinder
----------------------------------------------------------------

---@class OverlapFinder
---@field _getRect RectGetter
---@field _elements any[]
---@field _rects RectExtent[]
---@field _uf UnionFind
local OverlapFinder = {}
OverlapFinder.__index = OverlapFinder


---@param getRect RectGetter
---@return OverlapFinder
local function NewOverlapFinder(getRect)
    if type(getRect) ~= "function" then
        error("OverlapFinder requires a rectangle getter function")
    end

    local self = {
        _getRect = getRect,
        _elements = {},
        _rects = {},
        _uf = NewUnionFind(),
    }
    setmetatable(self, OverlapFinder)
    return self
end

---@param self OverlapFinder
---@param element any
function OverlapFinder.AddElement(self, element)
    local rect = self._getRect(element)
    if not rect or not rect.topLeft or not rect.bottomRight then
        error("Rectangle getter returned invalid extent")
    end

    local index = #self._elements + 1
    self._elements[index] = element
    self._rects[index] = rect
    self._uf:makeSet(index)

    -- Test against all previous rectangles
    for i = 1, index - 1 do
        if rectsOverlap(rect, self._rects[i]) then
            self._uf:union(index, i)
        end
    end
end

---@param self OverlapFinder
---@return any[][]
function OverlapFinder.GetOverlappingSubsets(self)
    ---@type table<integer, any[]>
    local groups = {}

    for i = 1, #self._elements do
        local root = self._uf:find(i)
        local group = groups[root]
        if not group then
            group = {}
            groups[root] = group
        end
        group[#group + 1] = self._elements[i]
    end

    ---@type any[][]
    local result = {}
    for _, group in pairs(groups) do
        result[#result + 1] = group
    end

    return result
end

----------------------------------------------------------------
-- Module export
----------------------------------------------------------------

---@class export
---@field NewOverlapFinder fun(getRect: RectGetter): OverlapFinder
return {
    NewOverlapFinder = NewOverlapFinder,
}
