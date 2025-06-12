--[[
ErnSunderRandomizer for OpenMW.
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
local ui = require('openmw.ui')
local settings = require("scripts.ErnSunderRandomizer.settings")
local core = require("openmw.core")
local localization = core.l10n(settings.MOD_NAME)

interfaces.Settings.registerPage {
    key = settings.MOD_NAME,
    l10n = settings.MOD_NAME,
    name = "name",
    description = "description"
}

local function showHideMessage(data)
    settings.debugPrint("showHideMessage")
    msg = localization("hideMessage", {itemName=data.itemName})
    print(msg)
    ui.showMessage(msg)
end

return {
    eventHandlers = {
        LMshowHideMessage = showHideMessage
    },
}