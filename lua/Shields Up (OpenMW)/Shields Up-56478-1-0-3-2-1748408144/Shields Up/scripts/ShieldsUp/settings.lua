-- scripts/ShieldsUp/settings.lua
local core = require('openmw.core')
local input = require('openmw.input')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local async = require('openmw.async') -- Needed for the renderer

local modInfo = require('scripts.ShieldsUp.modInfo') -- Assuming it's in a subfolder

-- Default Block Button (Right Mouse Button) - needed for default value in settings
local defaultBlockButton = 3

----------------------------------------------------------------------------------
-- CUSTOM RENDERER REGISTRATION
----------------------------------------------------------------------------------
if I.Settings and I.Settings.registerRenderer then
    I.Settings.registerRenderer('ShieldsUp/inputKeySelection', function(value, set)
        local name = 'No Key Set'
        if value ~= nil then
            local success, result = pcall(input.getKeyName, value)
            if success and result then
                name = result
            else
                name = 'Error: Invalid Key (' .. tostring(value) .. ')'
                -- Use print for logging during settings registration phase
                print("[ShieldsUp Settings] inputKeySelection: Failed to get key name for value: " .. tostring(value))
            end
        end
        return {
            template = I.MWUI.templates.box,
            content = ui.content {
                {
                    template = I.MWUI.templates.padding,
                    content = ui.content {
                        {
                            template = I.MWUI.templates.textEditLine,
                            props = {
                                text = name,
                            },
                            events = {
                                keyPress = async:callback(function(e)
                                    if e.code == input.KEY.Escape then return end
                                    set(e.code)
                                end),
                            },
                        },
                    },
                },
            },
        }
    end)
    print("[ShieldsUp Settings] Registered custom renderer 'ShieldsUp/inputKeySelection'.")
else
    print("[ShieldsUp Settings] ERROR: I.Settings.registerRenderer is not available.")
end
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- SETTINGS PAGE AND GROUPS REGISTRATION
----------------------------------------------------------------------------------
if I.Settings then
    I.Settings.registerPage({
        key = modInfo.name, -- Uses 'ShieldsUp' from modInfo
        l10n = modInfo.l10n,
        name = 'Shields Up', -- Display name of the page
        description = 'Improved vanilla block experience. By Xe',
    })

    I.Settings.registerGroup({
        key = 'Settings/' .. modInfo.name .. '/General',
        page = modInfo.name,
        order = 0, -- Explicit ordering
        l10n = modInfo.l10n,
        name = 'General Settings',
        permanentStorage = true,
        settings = {
            {
                key = 'blockBuffPercent',
                default = 50, -- Default value directly here
                renderer = 'number',
                name = 'Block Skill Buff (%)',
                description = 'Percentage to buff Block skill. Default: 50',
                argument = { integer = true, min = 0, max = 100 }
            },
            {
                key = 'weaponDebuffPercent',
                default = 40,
                renderer = 'number',
                name = 'Weapon Skill Debuff (%)',
                description = 'Percentage to debuff weapon skills. Default: 40',
                argument = { integer = true, min = 0, max = 100 }
            },
            {
                key = 'speedDebuffPercent',
                default = 50,
                renderer = 'number',
                name = 'Speed Debuff (%)',
                description = 'Percentage to debuff Speed attribute. Default: 50',
                argument = { integer = true, min = 0, max = 100 }
            },
        },
    })

    I.Settings.registerGroup({
        key = 'Settings/' .. modInfo.name .. '/Keybinds',
        page = modInfo.name,
        order = 1, -- Explicit ordering
        l10n = modInfo.l10n,
        name = 'Keybinds',
        permanentStorage = true,
        settings = {
            {
                key = 'blockKeybind', -- The setting key itself
                default = defaultBlockButton,
                renderer = 'ShieldsUp/inputKeySelection', -- Use the self-registered renderer
                name = 'Block Keybind',
                description = '"Reset" reverts to Right-Click. Controller uses (L1/LB) by default.',
            },
        },
    })
    print("[ShieldsUp Settings] Registered settings page and groups for " .. modInfo.name)
else
    print("[ShieldsUp Settings] ERROR: I.Settings interface not available. Settings registration skipped.")
end
----------------------------------------------------------------------------------

-- This script's sole purpose is to register settings UI.
-- No game logic or engine handlers here.