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
local MOD_NAME = require("scripts.ErnPerkFramework.settings").MOD_NAME
local interfaces = require('openmw.interfaces')
local log = require("scripts.ErnPerkFramework.log")
local core = require("openmw.core")
local ui = require("openmw.ui")
local localization = core.l10n(MOD_NAME)
local pself = require("openmw.self")
local util = require("openmw.util")

local sectionName = "perks"

local function initStatsWindowIntegration()
    if interfaces.StatsWindow then
        local sc = interfaces.StatsWindow.Constants
        log(nil, "StatsWindow found.")
        interfaces.StatsWindow.trackStat(MOD_NAME, function()
            -- this appears to work.
            return interfaces.ErnPerkFramework.getPlayerPerks()
        end)
        local lineBuilder = function(perkId)
            print("building line: " .. perkId)
            local perkRecord = interfaces.ErnPerkFramework.getPerks()[perkId]
            return {
                label = perkRecord:name(),
                tooltip = function()
                    return interfaces.StatsWindow.TooltipBuilders.TEXT({ text = perkRecord:description() })
                end,
                onClick = function()
                    pself:sendEvent(MOD_NAME .. "showPerkUI",
                        { visiblePerks = { perkId } })
                end,
            }
        end

        interfaces.StatsWindow.addSectionToBox(sectionName,
            sc.DefaultBoxes.RIGHT_SCROLL_BOX, {
                l10n = MOD_NAME,
                placement = {
                    type = sc.Placement.AFTER,
                    target = sc.DefaultSections.BIRTHSIGN,
                    priority = 1,
                },
                header = localization(sectionName),
                indent = true,
                sort = sc.Sort.LABEL_ASC,
                trackedStats = { [MOD_NAME] = true },
                builder = function()
                    -- debug
                    print("building perks stats section")
                    for _, id in ipairs(interfaces.StatsWindow.getStat(MOD_NAME)) do
                        interfaces.StatsWindow.addLineToSection(id, sectionName, lineBuilder(id))
                    end
                end,
            })
    else
        log(nil, "StatsWindow not found.")
    end
end



return {
    engineHandlers = {
        onInit = initStatsWindowIntegration,
        onLoad = initStatsWindowIntegration,
    }
}
