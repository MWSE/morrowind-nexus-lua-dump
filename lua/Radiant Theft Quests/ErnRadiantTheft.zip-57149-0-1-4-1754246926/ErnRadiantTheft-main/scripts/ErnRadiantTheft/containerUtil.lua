--[[
ErnRadiantTheft for OpenMW.
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
local settings = require("scripts.ErnRadiantTheft.settings")
local core = require("openmw.core")
local localization = core.l10n(settings.MOD_NAME)
local types = require("openmw.types")

local function hasAnySubstring(input, substrings)
    for _, token in ipairs(substrings) do
        if string.find(input, token) then
            return true
        end
    end
    return false
end


local goodContainerNames = {}
for token in string.gmatch(localization("goodContainerNames"), "[^,]+") do
    table.insert(goodContainerNames, string.lower(token))
end

local function lockable(container)
    local containerRecord = types.Container.record(container)
    if hasAnySubstring(string.lower(containerRecord.name), goodContainerNames) == true then
        return true
    end
    if types.Lockable.isLocked(container) == true then
        return true
    end
    return false
end

local function sortContainers(containers)
    local containerToWeight = {}
    local output = {}
    for _, cont in ipairs(containers) do
        -- sort lockable containers first
        local weight = 0
        if lockable(cont) == false then
            weight = weight + 1
        end
        containerToWeight[cont.id] = weight
        table.insert(output, cont)
    end
    table.sort(output, function(a, b) return containerToWeight[a.id] < containerToWeight[b.id] end)
    for _, c in ipairs(output) do
        settings.debugPrint(c.recordId .. " - " .. containerToWeight[c.id])
    end
    return output
end

return {
    sortContainers = sortContainers,
    lockable = lockable
}
