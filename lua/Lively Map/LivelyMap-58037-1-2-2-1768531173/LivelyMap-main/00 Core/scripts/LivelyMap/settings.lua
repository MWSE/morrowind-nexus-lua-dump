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
local interfaces               = require("openmw.interfaces")
local storage                  = require("openmw.storage")
local MOD_NAME                 = require("scripts.LivelyMap.ns")
local util                     = require('openmw.util')
local input                    = require('openmw.input')

local psoGroupKey              = "Settings/" .. MOD_NAME .. "/pso"
local controlsGroupKey         = "Settings/" .. MOD_NAME .. "/controls"
local automaticGroupKey        = "Settings/" .. MOD_NAME .. "/automatic"
local mainGroupKey             = "Settings/" .. MOD_NAME

local toggleMapWindowActionKey = MOD_NAME .. "_ToggleMapWindow"

local function init()
    interfaces.Settings.registerPage {
        key = MOD_NAME,
        l10n = MOD_NAME,
        name = "name",
        description = "description",
    }

    input.registerAction {
        key = toggleMapWindowActionKey,
        type = input.ACTION_TYPE.Boolean,
        l10n = MOD_NAME,
        defaultValue = false,
    }

    interfaces.Settings.registerGroup {
        key = psoGroupKey,
        page = MOD_NAME,
        l10n = MOD_NAME,
        name = "psoName",
        description = "psoDescription",
        permanentStorage = true,
        settings = {
            {
                key = "psoUnlock",
                name = "psoUnlockName",
                description = "psoUnlockDescription",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "psoDepth",
                name = "psoDepthName",
                description = "psoDepthDescription",
                default = 0,
                renderer = "number",
                argument = {
                    integer = true,
                    min = 0,
                    max = 300,
                }
            },
            {
                key = "psoPushdownOnly",
                name = "psoPushdownOnlyName",
                description = "psoPushdownOnlyDescription",
                default = true,
                renderer = "checkbox",
            },
        }
    }

    interfaces.Settings.registerGroup {
        key = controlsGroupKey,
        page = MOD_NAME,
        l10n = MOD_NAME,
        name = "controlsName",
        description = "controlsDescription",
        permanentStorage = true,
        settings = {
            {
                key = "k_" .. toggleMapWindowActionKey,
                renderer = 'inputBinding',
                name = 'toggleMapWindowKeyBind',
                default = 'None1',
                argument = {
                    key = toggleMapWindowActionKey,
                    type = 'action',
                }
            },
            {
                key = "controllerButtons",
                name = "controllerButtonsName",
                description = "controllerButtonsDescription",
                default = true,
                renderer = "checkbox",
            },
        }
    }

    interfaces.Settings.registerGroup {
        key = automaticGroupKey,
        page = MOD_NAME,
        l10n = MOD_NAME,
        name = "automaticName",
        description = "automaticDescription",
        permanentStorage = true,
        settings = {
            {
                key = "autoMarkNamedExteriorCells",
                name = "autoMarkNamedExteriorCellsName",
                description = "autoMarkNamedExteriorCellsDescription",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "autoMarkFromJournal",
                name = "autoMarkFromJournalName",
                description = "autoMarkFromJournalDescription",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "autoMarkTemplesAndCults",
                name = "autoMarkTemplesAndCultsName",
                description = "autoMarkTemplesAndCultsDescription",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "autoMarkPrisons",
                name = "autoMarkPrisonsName",
                description = "autoMarkPrisonsDescription",
                default = false,
                renderer = "checkbox",
            },
        }
    }

    interfaces.Settings.registerGroup {
        key = mainGroupKey,
        page = MOD_NAME,
        l10n = MOD_NAME,
        name = "settings",
        permanentStorage = true,
        settings = {
            {
                key = "extendDetectRange",
                name = "extendDetectRangeName",
                description = "extendDetectRangeDescription",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "fog",
                name = "fogName",
                description = "fogDescription",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "drawLimitNeravarinesJourney",
                name = "drawLimitNeravarinesJourneyName",
                description = "drawLimitNeravarinesJourneyDescription",
                default = true,
                renderer = "checkbox",
            },
            {
                key = "volatileNeravarinesJourney",
                name = "volatileNeravarinesJourneyName",
                description = "volatileNeravarinesJourneyDescription",
                default = false,
                renderer = "checkbox",
            },
            {
                key = "iconScale",
                name = "iconScaleName",
                description = "iconScaleDescription",
                default = 1,
                renderer = "number",
                argument = {
                    integer = false,
                    min = 0.25,
                    max = 50,
                }
            },
            {
                key = "palleteColor1",
                name = "palleteColor1Name",
                renderer = MOD_NAME .. "color",
                default = util.color.hex("FFBE0B"),
            },
            {
                key = "palleteColor2",
                name = "palleteColor2Name",
                renderer = MOD_NAME .. "color",
                default = util.color.hex("FB5607"),
            },
            {
                key = "palleteColor3",
                name = "palleteColor3Name",
                renderer = MOD_NAME .. "color",
                default = util.color.hex("FF006E"),
            },
            {
                key = "palleteColor4",
                name = "palleteColor4Name",
                renderer = MOD_NAME .. "color",
                default = util.color.hex("8338EC"),
            },
            {
                key = "palleteColor5",
                name = "palleteColor5Name",
                renderer = MOD_NAME .. "color",
                default = util.color.hex("3A86FF"),
            },
            {
                key = "debug",
                name = "debugName",
                default = false,
                renderer = "checkbox",
            },
        }
    }
end

local lookupFuncTable = {
    __index = function(table, key)
        if key == "subscribe" then
            return function(callback)
                print("Subscribed to " .. tostring(table.groupKey) .. ".")
                return table.section.subscribe(table.section, callback)
            end
        elseif key == "section" then
            return table.section
        elseif key == "groupKey" then
            return table.groupKey
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

local mainContainer = {
    groupKey = mainGroupKey,
    section = storage.playerSection(mainGroupKey)
}
setmetatable(mainContainer, lookupFuncTable)

local psoContainer = {
    groupKey = psoGroupKey,
    section = storage.playerSection(psoGroupKey)
}
setmetatable(psoContainer, lookupFuncTable)

local controlsContainer = {
    groupKey = controlsGroupKey,
    section = storage.playerSection(controlsGroupKey)
}
setmetatable(controlsContainer, lookupFuncTable)

local automaticContainer = {
    groupKey = automaticGroupKey,
    section = storage.playerSection(automaticGroupKey)
}
setmetatable(automaticContainer, lookupFuncTable)

---@alias SettingContainer table

---@class Settings
---@field init fun()
---@field main SettingContainer
---@field pso SettingContainer
---@field automatic SettingContainer

---@type Settings
return {
    init = init,
    main = mainContainer,
    pso = psoContainer,
    controls = controlsContainer,
    automatic = automaticContainer,
}
