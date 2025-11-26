--[[
SHOP - Store & House Owner Patrol (NPC in interiors AI overhaul) for OpenMW.
Copyright (C) 2025 Łukasz Walczak

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
----------------------------------------------------------------------
-- Anti-Theft Guard AI  •  v0.9 PUBLIC TEST  •  OpenMW ≥ 0.49
----------------------------------------------------------------------
-- scripts/antitheftai/player_settings.lua
-- Forwards player-profile settings to the global script
-- Runs in the *player* context → openmw.world is NOT available.

local storage = require('openmw.storage')
local async   = require('openmw.async')
local core    = require('openmw.core')

local KEY      = 'SettingsSHOPset'
local section  = storage.playerSection(KEY)

local VARS_KEY = 'SettingsSHOPsetVars'
local varsSection = storage.playerSection(VARS_KEY)

-- send one key/value pair to the global script
local function push(key, sectionRef)
    core.sendGlobalEvent('SHOP_UpdateSetting', {
        key   = key,
        value = sectionRef:get(key)
    })
end

-- on game start: push every stored value once
async:newUnsavableSimulationTimer(0, function()
    for k, _ in pairs(section:asTable()) do
        push(k, section)
    end
    for k, _ in pairs(varsSection:asTable()) do
        push(k, varsSection)
    end
end)

-- whenever any setting changes, push the updated value
section:subscribe(async:callback(function(_, key)
    if key == nil then                -- whole section reset ⇒ resend all
        for k, _ in pairs(section:asTable()) do
            push(k, section)
        end
    else
        push(key, section)
    end
end))

-- whenever vars setting changes, push the updated value
varsSection:subscribe(async:callback(function(_, key)
    if key == nil then                -- whole section reset ⇒ resend all
        for k, _ in pairs(varsSection:asTable()) do
            push(k, varsSection)
        end
    else
        push(key, varsSection)
    end
end))
