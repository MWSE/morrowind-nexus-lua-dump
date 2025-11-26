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
local interfaces = require("openmw.interfaces")
local input = require('openmw.input')

interfaces.Settings.registerPage {
    key = MOD_NAME,
    l10n = MOD_NAME,
    name = "name",
    description = "description"
}

input.registerAction {
    key = MOD_NAME .. "LockButton",
    type = input.ACTION_TYPE.Boolean,
    l10n = MOD_NAME,
    defaultValue = false,
}

input.registerAction {
    key = MOD_NAME .. "ToggleButton",
    type = input.ACTION_TYPE.Boolean,
    l10n = MOD_NAME,
    defaultValue = false,
}


--require("scripts.ErnOneStick.settings.options")
