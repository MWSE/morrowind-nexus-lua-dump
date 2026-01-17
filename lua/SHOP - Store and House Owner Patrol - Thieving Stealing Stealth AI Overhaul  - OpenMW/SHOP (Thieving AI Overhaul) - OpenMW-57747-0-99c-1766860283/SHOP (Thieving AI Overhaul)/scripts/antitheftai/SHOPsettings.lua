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
-- Anti-Theft Guard AI •  v0.98 PUBLIC TEST  •  shared settings helper  (OpenMW Lua ≥ 0.49)
----------------------------------------------------------------------

local storage = require('openmw.storage')
local I       = require('openmw.interfaces')

local PAGE_KEY    = 'AntiTheftPage'          -- UI page id
local GROUP_GEN   = 'SettingsSHOPset'        -- “General” group key
local GROUP_VARS  = 'SettingsSHOPsetVars'    -- “Variables” group key
local GROUP_TIMING = 'SettingsSHOPsetTiming' -- “Timing” group key
local GROUP_DISTANCES = 'SettingsSHOPsetDistances' -- “Distances” group key
local GROUP_COMPAT = 'SettingsSHOPsetCompatibility' -- “Compatibility” group key


-- 1) Register UI (only in contexts that expose I.Settings)
if I.Settings and I.Settings.registerPage then
    -- Page
    I.Settings.registerPage{
        key         = PAGE_KEY,
        l10n        = PAGE_KEY,
        name        = 'SHOP - Store Owner & House Patrol',
        description = 'SHOP v0.98 - Public Test\n Please report all bugs. \n Try to break the mod as much as possible.\n Let me know which Cells or NPCs MUST be disabled.\n Fit SHOP options below to your gamestyle likings.\n\n Made by skrow42',
    }

    -- General group
    I.Settings.registerGroup{
        key              = GROUP_GEN,
        l10n             = PAGE_KEY,
        page             = PAGE_KEY,
        name             = 'General',
        permanentStorage = true,  -- Changed to true to persist settings across game loads
        settings = {
            {
                key         = 'enableLogging',
                renderer    = 'checkbox',
                name        = 'Enable All Logging',
                description = 'Master switch. If disabled, no logs will be printed regardless of other debug settings. Decreases performance.',
                default     = false,
            },
            {
                key         = 'enableDebug',
                renderer    = 'checkbox',
                name        = 'Enable Player Debug Messages',
                description = 'Print F10 player-scripts logs to the console. Decreases performance.',
                default     = false,
            },
            {
                key         = 'enableGlobalDebug',
                renderer    = 'checkbox',
                name        = 'Enable Global Debug Messages',
                description = 'Print F10 global-scripts logs to the console. Decreases performance.',
                default     = false,
            },
            {
                key         = 'enableBedDetection',
                renderer    = 'checkbox',
                name        = 'Enable Bedroom Detection',
                description = 'If enabled, NPCs will react to the player going into their quarters.',
                default     = true,
            },
            {
                key         = 'enableDoorMechanics',
                renderer    = 'checkbox',
                name        = 'Enable Door Mechanics',
                description = 'If enabled, NPCs will react to door state changes (locking/unlocking) and investigate.',
                default     = true,
            },
            {
                key         = 'stunChanceDisplay',
                renderer    = 'select',
                name        = 'Stun Chance Display',
                description = 'How to display blackjack stun chance when approaching NPCs.',
                default     = 'contextual',
                argument    = {
                    l10n    = PAGE_KEY,
                    items   = {'off', 'exact', 'contextual'},
                    labels  = {'Off', 'Exact %', 'Contextual (Low/Med/High)'},
                },
            },
            {
                key         = 'addStunChanceSuffix',
                renderer    = 'checkbox',
                name        = 'Add Stun Chance Suffix',
                description = 'If enabled, adds dynamic suffix to contextual messages: (Low), (Medium), (High).',
                default     = true,
            },
            {
                key         = 'enableBlackjackSpawning',
                renderer    = 'checkbox',
                name        = 'Enable Blackjack & Keylock Script',
                description = 'Enable distribution of Blackjacks and Keylocks to TG merchants and random loot (1% chance).',
                default     = true,
            },
            {
                key         = 'disableHelloWhileFollowing',
                renderer    = 'checkbox',
                name        = 'Disable Hello While Following',
                description = 'Set Hello value to 0 while guard is following the player (restores default upon disbanding).',
                default     = true,
            },
        },
    }

    -- Variables group
    I.Settings.registerGroup{
        key              = GROUP_VARS,
        l10n             = PAGE_KEY,
        page             = PAGE_KEY,
        name             = 'Variables',
        permanentStorage = true,
        settings = {
            {
                key         = 'factionIgnoreRank',
                renderer    = 'number',
                name        = 'Faction Ignore Rank',
                description = 'Minimum guild rank that disables guard following inside guilds cells (1–10).',
                default     = 5,
                min         = 1,
                max         = 10,
                step        = 1,
            },
            {
                key         = 'losHalfCone',
                renderer    = 'number',
                name        = 'NPC Line of Sight radius',
                description = 'Set your preferred NPC detection range (degrees).',
                default     = 170,
                min         = 1,
                max         = 210,
                step        = 1,
            },
            {
                key         = 'chamHideLimit',
                renderer    = 'number',
                name        = 'Chameleon Hide Limit',
                description = 'Minimum magnitude of chameleon effect that launches hiding script.',
                default     = 1,
                min         = 1,
                max         = 100,
                step        = 1,
            },
            {
                key         = 'dispositionChange',
                renderer    = 'number',
                name        = 'Disposition Change Amount',
                description = 'Amount to subtract from all NPCs disposition in the cell when being followed by NPC and going hidden/being discovered (0-100). Default: -15 per NPC.',
                default     = 10,
                min         = 0,
                max         = 100,
                step        = 1,
            },
            {
                key         = 'removeDispositionOnce',
                renderer    = 'checkbox',
                name        = 'Remove Disposition only twice',
                description = 'When enabled, disposition penalty for discovery is applied only twice per cell visit (once for going hidden, once for being discovered) until leaving the cell.',
                default     = false,
            },
            {
                key         = 'dispositionFollowingIgnore',
                renderer    = 'number',
                name        = 'Disposition Following Ignore',
                description = 'Minimum disposition threshold (0-101). NPCs with disposition above this value will not start following the player. Set to 101 to disable.',
                default     = 90,
                min         = 0,
                max         = 101,
                step        = 1,
            },
            {
                key         = 'simulatedTravelSpeed',
                renderer    = 'number',
                name        = 'Simulated Travel Speed',
                description = '(Most Probably not working at the moment)Speed for NPC simulated travel when not loaded (units/second).',
                default     = 300.0,
                min         = 50.0,
                max         = 1000.0,
                step        = 10.0,
            },
            {
                key         = 'interiorAlarmRadius',
                renderer    = 'number',
                name        = 'Interior Alarm Radius',
                description = 'Radius for relaying alarm to other NPCs in interiors.(500-5000 units)',
                default     = 1000,
                min         = 500,
                max         = 5000,
                step        = 100,
            },
            {
                key         = 'exteriorAlarmRadius',
                renderer    = 'number',
                name        = 'Exterior Alarm Radius',
                description = 'Radius for relaying alarm to other NPCs in exteriors.(500-10000 units)',
                default     = 3500,
                min         = 500,
                max         = 10000,
                step        = 100,
            },

        },
    }

    -- Timing group
    I.Settings.registerGroup{
        key              = GROUP_TIMING,
        l10n             = PAGE_KEY,
        page             = PAGE_KEY,
        name             = 'Timing',
        permanentStorage = true,
        settings = {
            {
                key         = 'enterDelay',
                renderer    = 'number',
                name        = 'Enter Delay',
                description = 'Delay before NPC starts following you when entered interior cell (seconds).',
                default     = 2.0,
                min         = 0.1,
                max         = 10.0,
                step        = 0.1,
            },
            {
                key         = 'updatePeriod',
                renderer    = 'number',
                name        = 'Update Period',
                description = 'How often to update guard position and checks (seconds).',
                default     = 2.0,
                min         = 0.1,
                max         = 10.0,
                step        = 0.1,
            },
            {
                key         = 'searchWTimeMin',
                renderer    = 'number',
                name        = 'Search Wait Time Min',
                description = 'Minimum time to wait during search mode (seconds).',
                default     = 15.0,
                min         = 1.0,
                max         = 120.0,
                step        = 1.0,
            },
            {
                key         = 'searchWTimeMax',
                renderer    = 'number',
                name        = 'Search Wait Time Max',
                description = 'Maximum time to wait during search mode (seconds).',
                default     = 35.0,
                min         = 2.0,
                max         = 120.0,
                step        = 1.0,
            },
            {
                key         = 'losCheckInterval',
                renderer    = 'number',
                name        = 'LOS Check Interval',
                description = 'How often to check line of sight for guard recruitment (seconds).',
                default     = 2.0,
                min         = 0.1,
                max         = 10.0,
                step        = 0.1,
            },
            {
                key         = 'hierarchyCheckInterval',
                renderer    = 'number',
                name        = 'Hierarchy Check Interval',
                description = 'How often to check for better guard candidates (seconds).',
                default     = 2.0,
                min         = 0.1,
                max         = 10.0,
                step        = 0.1,
            },
            {
                key         = 'pathSampleInterval',
                renderer    = 'number',
                name        = 'Path Sample Interval',
                description = 'How often to sample NPC path waypoints (seconds).',
                default     = 2.0,
                min         = 0.1,
                max         = 10.0,
                step        = 0.1,
            },
            {
                key         = 'minWanderDelay',
                renderer    = 'number',
                name        = 'Min Wander Time',
                description = 'Minimum NPC wandering time (seconds).',
                default     = 35.0,
                min         = 1.0,
                max         = 900.0,
                step        = 1.0,
            },
            {
                key         = 'maxWanderDelay',
                renderer    = 'number',
                name        = 'Max Wander Time',
                description = 'Maximum NPC wandering time (seconds).',
                default     = 75.0,
                min         = 2.0,
                max         = 900.0,
                step        = 1.0,
            },
            {
                key         = 'fixedSearchTime',
                renderer    = 'number',
                name        = 'Fixed Search Time (debug purposes)',
                description = 'Fixed time for NPC search mode before returning home (seconds). Set to 0 to use the default randomised range.',
                default     = 0.0,
                min         = 0.0,
                max         = 300.0,
                step        = 1.0,
            },
        },
    }

    -- Distances group
    I.Settings.registerGroup{
        key              = GROUP_DISTANCES,
        l10n             = PAGE_KEY,
        page             = PAGE_KEY,
        name             = 'Distances',
        permanentStorage = true,
        settings = {
            {
                key         = 'searchWDist',
                renderer    = 'number',
                name        = 'Search Walk Distance',
                description = 'Maximum distance for guard to walk during search mode.',
                default     = 1000.0,
                min         = 1.0,
                max         = 5000.0,
                step        = 1.0,
            },
            {
                key         = 'pickRange',
                renderer    = 'number',
                name        = 'Pick Range',
                description = 'Maximum distance to pick a guard for following.',
                default     = 1000.0,
                min         = 1.0,
                max         = 5000.0,
                step        = 1.0,
            },
            {
                key         = 'desiredDistMin',
                renderer    = 'number',
                name        = 'Desired Distance Min',
                description = 'Minimum distance guard maintains from player.',
                default     = 100.0,
                min         = 1.0,
                max         = 500.0,
                step        = 1.0,
            },
            {
                key         = 'desiredDistMax',
                renderer    = 'number',
                name        = 'Desired Distance Max',
                description = 'Maximum distance guard maintains from player.',
                default     = 350.0,
                min         = 1.0,
                max         = 500.0,
                step        = 1.0,
            },
            {
                key         = 'losRange',
                renderer    = 'number',
                name        = 'LOS Range',
                description = 'Maximum distance for line of sight checks.',
                default     = 1000.0,
                min         = 1.0,
                max         = 5000.0,
                step        = 1.0,
            },
            {
                key         = 'detectionRange',
                renderer    = 'number',
                name        = 'Detection Range',
                description = 'NPC detection range for invisibility and chameleon removal.',
                default     = 175.0,
                min         = 50,
                max         = 500.0,
                step        = 1.0,
            },
        },
    }

    -- Compatibility group
    I.Settings.registerGroup{
        key              = GROUP_COMPAT,
        l10n             = PAGE_KEY,
        page             = PAGE_KEY,
        name             = 'Compatibility',
        permanentStorage = true,
        settings = {
            {
                key         = 'enableErnBurglarySpotted',
                renderer    = 'checkbox',
                name        = 'Enable ErnBurglary Spotted Integration',
                description = ' Invoke ErnBurglary spotted function when NPC starts following the player.\n Works only with ErnBurglary (Burglary Overhaul) v1.3.8 or higher.\n You MUST also turn "Disable Detection" option to YES in ErnBurglary.',
                default     = false,
            },
            {
                key         = 'disableScriptOnChargenNPCs',
                renderer    = 'checkbox',
                name        = 'Disable Script on Chargen NPCs',
                description = 'Disable the script for NPCs whose record ID contains "chargen".',
                default     = false,
            },
        },
    }


    -- Bounties group
    I.Settings.registerGroup{
        key              = 'SettingsSHOPsetBounties',
        l10n             = PAGE_KEY,
        page             = PAGE_KEY,
        name             = 'Bounties',
        permanentStorage = true,
        settings = {
            {
                key         = 'lockingDoorBounty',
                renderer    = 'number',
                name        = 'Locking Door Bounty',
                description = 'Bounty added when player locks a door while being followed. Set 0 to disable.',
                default     = 150,
                min         = 0,
                max         = 1000,
                step        = 1,
            },
            {
                key         = 'stunNPCBounty',
                renderer    = 'number',
                name        = 'Stun NPC Bounty',
                description = 'Bounty added when knocking out an NPC (if spotted). Set 0 to disable.',
                default     = 300,
                min         = 0,
                max         = 1000,
                step        = 1,
            },
        },
    }
end

-- 2) Return the correct storage section for the current context
local function section(key)
    if storage.playerSection then
        return storage.playerSection(key)   -- menu / player scripts
    else
        return storage.globalSection(key)   -- global & local scripts
    end
end

return {
    general = section(GROUP_GEN),
    vars    = section(GROUP_VARS),
    timing  = section(GROUP_TIMING),
    distances = section(GROUP_DISTANCES),
    compatibility = section(GROUP_COMPAT),
    bounties = section('SettingsSHOPsetBounties'),
}
