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

local vfs = require('openmw.vfs')
local markup = require('openmw.markup')

local merged = {}

local function hasSuffix(str, suffix)
    if #suffix == 0 then return true end
    return str:sub(- #suffix) == suffix
end

local function loadFile(fileName)
    local result = markup.loadYaml(fileName)
    for k, v in pairs(result) do
        merged[k] = v
    end
end


for fileName in vfs.pathsWithPrefix("scripts\\ErnGlider\\updraft") do
    if hasSuffix(fileName:lower(), ".yaml") then
        loadFile(fileName)
    end
end

return merged
