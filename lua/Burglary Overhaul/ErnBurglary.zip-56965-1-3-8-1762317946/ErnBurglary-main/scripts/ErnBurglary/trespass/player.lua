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
local settings     = require("scripts.ErnBurglary.settings")
local interfaces   = require('openmw.interfaces')
local types        = require("openmw.types")
local core         = require("openmw.core")
local localization = core.l10n(settings.MOD_NAME)
local ui           = require('openmw.ui')
local pself        = require("openmw.self")

local function showTrespassingMessage(data)
    settings.debugPrint("showTrespassingMessage")
    if settings.quietMode() ~= true then
        ui.showMessage(localization("showTrespassingMessage", data))
    end
end

local function onConsoleCommand(mode, command, selectedObject)
    local function getSuffixForCmd(prefix)
        if string.sub(command:lower(), 1, string.len(prefix)) == prefix then
            return string.sub(command, string.len(prefix) + 1)
        else
            return nil
        end
    end
    local noTrespass = getSuffixForCmd("lua notrespass")

    if noTrespass ~= nil then
        settings.debugPrint("Processing notrespass command.")
        core.sendGlobalEvent(settings.MOD_NAME .. "onNoTrespass", {
            player = pself,
            selectedObject = selectedObject
        })
    end
end

return {
    eventHandlers = {
        [settings.MOD_NAME .. "showTrespassingMessage"] = showTrespassingMessage
    },
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
    }
}
