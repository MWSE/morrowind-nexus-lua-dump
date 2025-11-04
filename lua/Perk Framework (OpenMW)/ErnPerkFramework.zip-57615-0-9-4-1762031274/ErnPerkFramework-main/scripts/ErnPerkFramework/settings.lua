--[[
ErnPerkFramework for OpenMW.
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
local interfaces = require("openmw.interfaces")
local storage = require("openmw.storage")
local MOD_NAME = "ErnPerkFramework"

local function init()
    interfaces.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
    }
    interfaces.Settings.registerGroup {
        key = "Settings" .. MOD_NAME,
        page = MOD_NAME,
        l10n = MOD_NAME,
        name = "settings",
        permanentStorage = true,
        settings = {
            {
                key = "perksPerLevel",
                name = "perksPerLevelName",
                description = "perksPerLevelDescription",
                default = 1,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0,
                    max = 5,
                }
            },
            {
                key = "disable",
                name = "disableName",
                description = "disableDescription",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "enableLogging",
                name = "enableLoggingName",
                default = false,
                renderer = "checkbox",
            }
        }
    }
end

local lookupFuncTable = {
    __index = function(table, key)
        if key == "init" then
            return init
        elseif key == "MOD_NAME" then
            return MOD_NAME
        end
        -- fall through to settings section
        local val = table.section:get(key)
        if val ~= nil then
            return val
        else
            error("unknown setting " .. tostring(key))
        end
    end,
}

local container = {
    section = storage.playerSection("Settings" .. MOD_NAME)
}
setmetatable(container, lookupFuncTable)

return container
