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
local MOD_NAME = require("scripts.ErnOneStick.ns")
local storage = require("openmw.storage")
local async = require("openmw.async")

local sections = {}

local GroupFunctions = {}

GroupFunctions.__index = function(table, key)
    if key == "subscribe" then
        return function(fn) table.group:subscribe(async:callback(fn)) end
    end
    local val = table.group:get(key)
    --print(table.name .. "." .. key .. "=" .. tostring(val))
    return val
end

function Group(name)
    if sections[name] ~= nil then
        print("get cached section " .. name)
        return sections[name]
    end

    print("get new section " .. name)
    local new = {
        name = name,
        group = storage.globalSection(name),
    }
    setmetatable(new, GroupFunctions)
    sections[name] = new
    return new
end

return {
    interfaceName = MOD_NAME .. "Group",
    interface = {
        version = 1,
        Group = Group,
    }
}
