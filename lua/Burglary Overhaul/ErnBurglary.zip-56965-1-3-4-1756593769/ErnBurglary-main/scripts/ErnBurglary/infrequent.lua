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

local FunctionCollection = {}
FunctionCollection.__index=FunctionCollection

function FunctionCollection:new()
    local new = {}
    setmetatable(new,FunctionCollection)
    return new
end

function FunctionCollection:addCallback(id, minDelta, callback)
    self[id] = {
        sum = math.random(0, minDelta),
        threshold = minDelta,
        callback = callback
    }
end

function FunctionCollection:onUpdate(dt)
    for k, v in pairs(self) do
        self[k].sum = v.sum + dt
        if self[k].sum > v.threshold then
            self[k].sum = self[k].sum % v.threshold
            v.callback(v.threshold)
        end
    end
end

function FunctionCollection:callAll()
    for k, v in pairs(self) do
        v.callback(v.threshold)
    end
end

return {
    FunctionCollection = FunctionCollection,
}