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
local common = require("scripts.ErnRadiantTheft.common")
local core = require("openmw.core")
local self = require("openmw.self")
local localization = core.l10n(settings.MOD_NAME)
local ui = require('openmw.ui')

settings.registerPage()

local function onQuestUpdate(questId, stage)
    if questId == common.questID then
        core.sendGlobalEvent(settings.MOD_NAME .. "onQuestUpdate", {
            player = self,
            questId = questId,
            stage = stage
        })
    end
end


local function onQuestAvailable(data)
    settings.debugPrint("onQuestAvailable")

    ui.showMessage(localization("questAvailable", {}))
end

local function onMacguffinStolen(data)
    settings.debugPrint("onMacguffinStolen")

    ui.showMessage(localization("macguffinStolen", {}))
end

return {
    eventHandlers = {
        [settings.MOD_NAME .. 'onQuestAvailable'] = onQuestAvailable
    },
    engineHandlers = {
        onQuestUpdate = onQuestUpdate
    }
}
