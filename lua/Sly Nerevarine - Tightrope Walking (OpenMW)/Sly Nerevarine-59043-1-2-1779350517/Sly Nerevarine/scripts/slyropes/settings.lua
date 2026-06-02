local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local cfg = require('scripts.slyropes.config')

local M = {}

local MODNAME = 'SlyNerevarine'
local L10N = 'SlyNerevarine'

M.PAGE_KEY = MODNAME
-- Settings groups should start with "Settings" by convention.
-- This group is registered only from the PLAYER context so the settings UI and
-- runtime code read/write the same player storage section.
M.GROUP_KEY = 'Settings_' .. MODNAME .. '_Debug'

local settingsRegistered = false
local registrationFailureLogged = false
local cache = {
    debugEnabled = cfg.DEBUG == true,
    logStateChanges = false,
    logMountRolls = false,
    logBalanceRolls = false,
    logSkillSnapshots = false,
    skillSnapshotInterval = cfg.LOG_SKILL_SNAPSHOT_INTERVAL_SECONDS or 1.0,
    logXpTicks = false,
}

local function isAlreadyRegisteredError(err)
    local text = string.lower(tostring(err or ''))
    return string.find(text, 'already', 1, true) ~= nil
        or string.find(text, 'registered', 1, true) ~= nil
        or string.find(text, 'duplicate', 1, true) ~= nil
end

local function registrationLog(msg)
    -- Only hard settings-registration failures are printed in release mode.
    -- Routine debug/balance output remains controlled by the in-game Debug settings.
    print('[Sly Nerevarine] settings: ' .. tostring(msg))
end

local function playerSettingsSection()
    local ok, section = pcall(function()
        return storage.playerSection(M.GROUP_KEY)
    end)
    if ok then
        return section
    end
    return nil
end

local function settingOrDefault(key, default)
    local section = playerSettingsSection()
    if not section or type(section.get) ~= 'function' then
        return default
    end

    local ok, value = pcall(function()
        return section:get(key)
    end)
    if not ok or value == nil then
        return default
    end

    return value
end

local function boolSetting(key, default)
    return settingOrDefault(key, default) == true
end

local function numberSetting(key, default, minValue, maxValue)
    local value = tonumber(settingOrDefault(key, default)) or default
    if minValue ~= nil and value < minValue then
        value = minValue
    end
    if maxValue ~= nil and value > maxValue then
        value = maxValue
    end
    return value
end

function M.isRegistered()
    return settingsRegistered == true
end

function M.register(source)
    if settingsRegistered then
        return true
    end

    if not I or not I.Settings then
        -- Settings may not be available during early script load. Retry silently from onFrame.
        return false
    end

    local pageOk, pageErr = pcall(function()
        I.Settings.registerPage {
            key = M.PAGE_KEY,
            l10n = L10N,
            name = 'PageName',
            description = 'PageDescription',
        }
    end)

    -- Page duplication is harmless when reloadlua re-runs script registration.
    -- Anything else should be visible in the log.
    if not pageOk and not isAlreadyRegisteredError(pageErr) then
        registrationLog('registerPage failed: ' .. tostring(pageErr))
        return false
    end

    local groupOk, groupErr = pcall(function()
        I.Settings.registerGroup {
            key = M.GROUP_KEY,
            page = M.PAGE_KEY,
            l10n = L10N,
            name = 'DebugGroupName',
            description = 'DebugGroupDescription',
            permanentStorage = false,
            order = 0,
            settings = {
                {
                    key = 'DebugEnabled',
                    renderer = 'checkbox',
                    name = 'DebugEnabledName',
                    description = 'DebugEnabledDescription',
                    default = false,
                },
                {
                    key = 'LogStateChanges',
                    renderer = 'checkbox',
                    name = 'LogStateChangesName',
                    description = 'LogStateChangesDescription',
                    default = false,
                },
                {
                    key = 'LogMountRolls',
                    renderer = 'checkbox',
                    name = 'LogMountRollsName',
                    description = 'LogMountRollsDescription',
                    default = true,
                },
                {
                    key = 'LogBalanceRolls',
                    renderer = 'checkbox',
                    name = 'LogBalanceRollsName',
                    description = 'LogBalanceRollsDescription',
                    default = true,
                },
                {
                    key = 'LogSkillSnapshots',
                    renderer = 'checkbox',
                    name = 'LogSkillSnapshotsName',
                    description = 'LogSkillSnapshotsDescription',
                    default = true,
                },
                {
                    key = 'SkillSnapshotInterval',
                    renderer = 'number',
                    name = 'SkillSnapshotIntervalName',
                    description = 'SkillSnapshotIntervalDescription',
                    default = 1.0,
                    argument = {
                        min = 0.25,
                        max = 10.0,
                    },
                },
                {
                    key = 'LogXpTicks',
                    renderer = 'checkbox',
                    name = 'LogXpTicksName',
                    description = 'LogXpTicksDescription',
                    default = false,
                },
            },
        }
    end)

    if not groupOk and not isAlreadyRegisteredError(groupErr) then
        registrationLog('registerGroup failed: ' .. tostring(groupErr))
        return false
    end

    settingsRegistered = true
    registrationFailureLogged = false
    return true
end

function M.refresh()
    local enabled = boolSetting('DebugEnabled', cfg.DEBUG == true)
    cache.debugEnabled = enabled
    cache.logStateChanges = enabled and boolSetting('LogStateChanges', cfg.LOG_STATE_CHANGES == true)
    cache.logMountRolls = enabled and boolSetting('LogMountRolls', cfg.LOG_MOUNT_ROLLS == true)
    cache.logBalanceRolls = enabled and boolSetting('LogBalanceRolls', cfg.LOG_BALANCE_ROLLS == true)
    cache.logSkillSnapshots = enabled and boolSetting('LogSkillSnapshots', cfg.LOG_SKILL_SNAPSHOTS == true)
    cache.skillSnapshotInterval = numberSetting('SkillSnapshotInterval', cfg.LOG_SKILL_SNAPSHOT_INTERVAL_SECONDS or 1.0, 0.25, 10.0)
    cache.logXpTicks = enabled and boolSetting('LogXpTicks', cfg.LOG_XP_TICKS == true)
end

function M.debugEnabled()
    return cache.debugEnabled == true
end

function M.logStateChanges()
    return cache.logStateChanges == true
end

function M.logMountRolls()
    return cache.logMountRolls == true
end

function M.logBalanceRolls()
    return cache.logBalanceRolls == true
end

function M.logSkillSnapshots()
    return cache.logSkillSnapshots == true
end

function M.skillSnapshotInterval()
    return cache.skillSnapshotInterval or 1.0
end

function M.logXpTicks()
    return cache.logXpTicks == true
end

return M
