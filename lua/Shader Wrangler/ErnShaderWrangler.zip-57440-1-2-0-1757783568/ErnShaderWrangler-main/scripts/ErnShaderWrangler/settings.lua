--[[
ErnShaderWrangler for OpenMW.
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
local MOD_NAME = "ErnShaderWrangler"

local enabledOptions = { "fps", "never", "always" }

interfaces.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "name",
    description = "description"
}
interfaces.Settings.registerGroup {
    key = "Settings" .. MOD_NAME,
    page = MOD_NAME,
    l10n = MOD_NAME,
    name = "settings",
    permanentStorage = true,
    settings = {
        {
            key = "disableAt",
            renderer = "number",
            name = "disableAtName",
            description = "disableAtDesc",
            default = 20,
            argument = {
                min = 1,
                max = 200,
                integer = true,
            },
        },
        {
            key = "enableAt",
            renderer = "number",
            name = "enableAtName",
            description = "enableAtDesc",
            default = 30,
            argument = {
                min = 1,
                max = 200,
                integer = true,
            },
        },
        {
            key = "stddev",
            renderer = "number",
            name = "stddevName",
            description = "stddevDesc",
            default = 0.005,
            argument = {
                min = 0,
                max = 10,
                integer = false,
            },
        },
        {
            key = "interior",
            name = "interiorName",
            description = "interiorDescription",
            argument = { items = enabledOptions, l10n = MOD_NAME },
            default = enabledOptions[3],
            renderer = "select",
        },
        {
            key = "exterior",
            name = "exteriorName",
            description = "exteriorDescription",
            argument = { items = enabledOptions, l10n = MOD_NAME },
            default = enabledOptions[1],
            renderer = "select",
        },
        {
            key = "interiorShaders",
            name = "interiorShadersName",
            description = "interiorShadersDescription",
            default = 'bright',
            renderer = 'textLine',
        },
        {
            key = "exteriorShaders",
            name = "exteriorShadersName",
            description = "exteriorShadersDescription",
            default = 'bright',
            renderer = 'textLine',
        }, {
        key = "enableLogging",
        name = "enableLoggingName",
        default = false,
        renderer = "checkbox"
    }
    }
}

return storage.playerSection("Settings" .. MOD_NAME)
