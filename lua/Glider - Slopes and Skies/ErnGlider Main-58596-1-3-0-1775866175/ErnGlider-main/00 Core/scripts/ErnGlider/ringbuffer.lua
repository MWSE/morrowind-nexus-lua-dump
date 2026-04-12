--[[
ErnGlider for OpenMW.
Copyright (C) 2026 Erin Pentecost

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

local RingBuffer   = {}
RingBuffer.__index = RingBuffer

local function emptyBuffer(size)
    local values = {}
    for _ = 1, size do
        table.insert(values, 0)
    end
    return values
end

function RingBuffer.new(size)
    return setmetatable({
        size   = size,
        values = emptyBuffer(size),
        index  = 1,
        sum    = 0,
        count  = 0,
    }, RingBuffer)
end

function RingBuffer:reset()
    self.index  = 1
    self.values = emptyBuffer(self.size)
    self.sum    = 0
    self.count  = 0
end

function RingBuffer:push(v)
    -- subtract value being overwritten
    if self.count == self.size then
        self.sum = self.sum - self.values[self.index]
    else
        self.count = self.count + 1
    end

    self.values[self.index] = v
    self.sum = self.sum + v
    self.index = self.index % self.size + 1
end

function RingBuffer:getAverage()
    if self.count == 0 then
        return 0
    end
    return self.sum / self.count
end

return {
    new = RingBuffer.new,
}
