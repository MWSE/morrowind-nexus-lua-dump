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
local util = require('openmw.util')

local phi = 2 * math.pi
local eps = 1e-12

local function subtract(a, b)
    a = util.normalizeAngle(a)
    b = util.normalizeAngle(b)

    local diff = (b - a) % phi

    -- if > pi, go the negative way (diff - 2pi)
    if diff > math.pi then
        diff = diff - phi
    elseif math.abs(diff - math.pi) < eps then
        -- tie (exact half-turn): choose the positive rotation (+pi)
        diff = math.pi
    end
    return util.normalizeAngle(diff)
end

local function anglesAlmostEqual(a, b, tol)
    tol = tol or 1e-12
    return math.abs(subtract(a, b)) < tol
end

local function lerpAngle(startAngle, endAngle, t)
    startAngle = util.normalizeAngle(startAngle)
    endAngle = util.normalizeAngle(endAngle)

    local diff = (endAngle - startAngle) % phi

    -- if > pi, go the negative way (diff - 2pi)
    if diff > math.pi then
        diff = diff - phi
    elseif math.abs(diff - math.pi) < eps then
        -- tie (exact half-turn): choose the positive rotation (+pi)
        diff = math.pi
    end

    local result = startAngle + diff * t
    return util.normalizeAngle(result)
end

-- Tests (corrected expectations and modular comparisons)
local tests = {
    { name = "No change (t=0)",                  start = 0,               finish = math.pi / 2,      t = 0,   expected = 0 },
    { name = "Exact end (t=1)",                  start = 0,               finish = math.pi / 2,      t = 1,   expected = math.pi / 2 },
    { name = "Midway short path",                start = 0,               finish = math.pi / 2,      t = 0.5, expected = math.pi / 4 },
    { name = "Wrap around (cross -pi to pi)",    start = 3 * math.pi / 4, finish = -3 * math.pi / 4, t = 0.5, expected = math.pi },     -- canonical +pi
    { name = "Half-turn tie case",               start = 0,               finish = math.pi,          t = 0.5, expected = math.pi / 2 }, -- tie -> positive direction
    { name = "Negative to positive across wrap", start = -math.pi + 0.1,  finish = math.pi - 0.1,    t = 0.5, expected = math.pi }      -- canonical +pi (equivalent to -pi)
}

local passed = 0
for _, test in ipairs(tests) do
    local got = lerpAngle(test.start, test.finish, test.t)
    if anglesAlmostEqual(got, test.expected) ~= true then
        error("failed radian test: " .. test.name)
        return
    end
end

return {
    lerpAngle = lerpAngle,
    subtract = subtract,
    anglesAlmostEqual = anglesAlmostEqual,
}
