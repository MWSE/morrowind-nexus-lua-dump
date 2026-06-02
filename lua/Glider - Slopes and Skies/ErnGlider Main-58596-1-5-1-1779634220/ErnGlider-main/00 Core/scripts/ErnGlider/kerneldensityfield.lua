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

--- Second-order Wendland Kernel function.
--- This is a smooth function that will return 1 if r2 is 0,
--- and 0 if sqrt(r2) is greater than sizeRadius.
---@param r2 number squared distance to the kernel
---@param sizeRadius number size of the kernel
---@return number
local function wendlandC2(r2, sizeRadius)
    -- stop execution early, and before doing a sqrt,
    -- if we are outside the radius.
    if r2 >= sizeRadius * sizeRadius then
        return 0
    end

    local r = math.sqrt(r2)

    local q = r / sizeRadius
    local t = 1 - q

    local t2 = t * t
    local t4 = t2 * t2

    return t4 * (4 * q + 1)
end

---@class Kernel
---@field pos util.vector3
---@field fn fun(r2: number): number

local ScalarField   = {}
ScalarField.__index = ScalarField

function ScalarField.new()
    return setmetatable({
        ---@type table<string, Kernel>
        kernels = {},
        filter = function(pos, kern)
            return pos.z >= kern.pos.z
        end
    }, ScalarField)
end

---@param id string
---@param pos util.vector3
---@param radius number
---@param strength number
function ScalarField:addKernel(id, pos, radius, strength)
    ---@type Kernel
    local kern = {
        pos = pos,
        fn = function(r2)
            return wendlandC2(r2, radius) * strength
        end,
    }
    self.kernels[id] = kern
end

function ScalarField:reset()
    self.kernels = {}
end

---@param pos util.vector3
---@param fn fun(a: number, b: number): number
---@return number
function ScalarField:calculate(pos, fn)
    local out = 0
    for _, kern in pairs(self.kernels) do
        if self.filter(pos, kern) then
            local dist = (pos.x - kern.pos.x) ^ 2 + (pos.y - kern.pos.y) ^ 2
            out = fn(out, kern.fn(dist))
        end
    end
    return out
end

---@param pos util.vector3
---@return number
function ScalarField:sum(pos)
    return self:calculate(pos, function(a, b)
        return a + b
    end)
end

---@param pos util.vector3
---@return number
function ScalarField:max(pos)
    return self:calculate(pos, function(a, b)
        return math.max(a, b)
    end)
end

return {
    new = ScalarField.new,
}
