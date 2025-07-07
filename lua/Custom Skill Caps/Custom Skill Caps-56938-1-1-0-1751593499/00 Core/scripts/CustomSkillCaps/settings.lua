-- Settings
local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local storage = require('openmw.storage')
local ui = require('openmw.ui')

local info = require('scripts.CustomSkillCaps.info')

local L = core.l10n(info.name)

local function sortAlphabetical(a, b)
    return a:lower() < b:lower()
end

local function capital(text)
    return text:gsub('^%l', string.upper)
end

input.registerTrigger {
    key = 'Progress' .. info.name,
    l10n = info.name
}

local modSettings = {
    basic = storage.playerSection('SettingsPlayer' .. info.name .. 'Basic'),
    version = storage.playerSection('SettingsPlayer' .. info.name .. 'Version')
}

I.Settings.registerPage {
    key = 'Page' .. info.name,
    l10n = info.name,
    name = 'PageName'
}

-- Something stupid to get around I.Settings.updateRendererArgument() replacing the entire table
local dependentArguments = {
    basic = {
        SharedSkillCap = {
            integer = true,
            min = 0
        },
        MajorSkillCap = {
            integer = true,
            min = 0
        },
        MinorSkillCap = {
            integer = true,
            min = 0
        },
        MiscSkillCap = {
            integer = true,
            min = 0
        }
    }
}

-- Dependent settings must belong to the same section as the settings they depend on
local dependentSettings = {
    basic = {
        SharedSkillCap = {SkillCapMethod = 'SharedCap'},
        MajorSkillCap = {SkillCapMethod = 'ClassCap'},
        MinorSkillCap = {SkillCapMethod = 'ClassCap'},
        MiscSkillCap = {SkillCapMethod = 'ClassCap'}
    }
}

-- Basic settings

local basicSettings = {
    {
        key = 'ProgressKey',
        renderer = 'inputBinding',
        name = 'ProgressKeyName',
        description = 'ProgressKeyDesc',
        default = '',
        argument = {type = 'trigger', key = 'Progress' .. info.name}
    },
    {
        key = 'SkillCapMethod',
        renderer = info.name .. 'Select',
        name = 'SkillCapMethodName',
        description = 'SkillCapMethodDesc',
        default = 'SharedCap',
        argument = {
            items = {'SharedCap', 'ClassCap', 'UniqueCap'},
            l10n = info.name
        }
    },
    {
        key = 'SharedSkillCap',
        renderer = 'number',
        name = 'SharedSkillCapName',
        default = 0,
        argument = dependentArguments.basic.SharedSkillCap
    },
    {
        key = 'MajorSkillCap',
        renderer = 'number',
        name = 'MajorSkillCapName',
        default = 0,
        argument = dependentArguments.basic.MajorSkillCap
    },
    {
        key = 'MinorSkillCap',
        renderer = 'number',
        name = 'MinorSkillCapName',
        default = 0,
        argument = dependentArguments.basic.MinorSkillCap
    },
    {
        key = 'MiscSkillCap',
        renderer = 'number',
        name = 'MiscSkillCapName',
        default = 0,
        argument = dependentArguments.basic.MiscSkillCap
    }
}

local skillList = {}

for i, skillRecord in ipairs(core.stats.Skill.records) do
    table.insert(skillList, skillRecord.id)
end

table.sort(skillList, sortAlphabetical)

for i, skillId in ipairs(skillList) do
    dependentArguments.basic[capital(skillId) .. 'Cap'] = {integer = true, min = 0}
    dependentSettings.basic[capital(skillId) .. 'Cap'] = {SkillCapMethod = 'UniqueCap'}
    table.insert(basicSettings, {
        key = capital(skillId) .. 'Cap',
        renderer = 'number',
        name = core.stats.Skill.record(skillId).name .. L('UniqueSkillCapName'),
        default = 0,
        argument = dependentArguments.basic[capital(skillId) .. 'Cap']
    })
end

I.Settings.registerGroup {
    key = 'SettingsPlayer' .. info.name .. 'Basic',
    page = 'Page' .. info.name,
    order = 1,
    l10n = info.name,
    name = 'SettingsBasicName',
    permanentStorage = true,
    settings = basicSettings
}

-- Dependent Settings

-- Need to search this data from both directions
-- Automatically construct a reversed table
local dependedSettings = {}
for groupName, dependentKeys in pairs(dependentSettings) do
    dependedSettings[groupName] = {}
    for dependentKey, dependedKeys in pairs(dependentKeys) do
        for dependedKey, _ in pairs(dependedKeys) do
            if dependedSettings[groupName][dependedKey] ~= nil then
                table.insert(dependedSettings[groupName][dependedKey], dependentKey)
            else
                dependedSettings[groupName][dependedKey] = {dependentKey}
            end
        end
    end
end

local function dependentFunction(sectionKey, changedKey)
    local groupName = sectionKey:gsub('SettingsPlayer' .. info.name, ''):lower()
    if changedKey ~= nil and dependedSettings[groupName][changedKey] ~= nil then
        for _, dependentKey in pairs(dependedSettings[groupName][changedKey]) do
            local disabled = false
            for dependedKey, value in pairs(dependentSettings[groupName][dependentKey]) do
                if modSettings[groupName]:get(dependedKey) ~= value then
                    disabled = true
                end
            end
            local argument = dependentArguments[groupName][dependentKey]
            argument.disabled = disabled
            I.Settings.updateRendererArgument(sectionKey, dependentKey, argument)
        end
    end
end

local dependentCallback = async:callback(dependentFunction)

-- Initialize disabled state of dependent settings
for groupName, dependedKeys in pairs(dependedSettings) do
    local sectionKey = 'SettingsPlayer' .. info.name .. capital(groupName) 
    for dependedKey, _ in pairs(dependedKeys) do
        dependentFunction(sectionKey, dependedKey)
    end
end

modSettings.basic:subscribe(dependentCallback)

-- Information about moved/removed settings for each settings version
-- Used to migrate old setting values/inform player when a setting was removed

-- Settings to be migrated are not assumed to exist
local settingsMoved = {
    [1] = {},
    [2] = {
        SkillCap = function()
            local oldSetting = modSettings.basic:get('SkillCap')
            modSettings.basic:set('SharedSkillCap', oldSetting or 0)
        end,
        UniqueSkillCap = function()
            local oldSetting = modSettings.basic:get('UniqueSkillCap')
            if oldSetting == true then
                modSettings.basic:set('SkillCapMethod', 'UniqueCap')
            elseif oldSetting == false then
                modSettings.basic:set('SkillCapMethod', 'SharedCap')
            end
        end
    }
}

local settingsRemoved = {
    [1] = {},
    [2] = {}
}

-- Settings version was mistakenly not saved in storage in 1.0.0
local storedSettingsVersion = modSettings.version:get('SettingsVersion') or 1

if info.settingsVersion > (storedSettingsVersion) then
    local removedText = ''
    for i = storedSettingsVersion + 1, info.settingsVersion, 1 do
        for _, settingKey in pairs(settingsRemoved[i]) do
            removedText = removedText .. '\n' .. L(settingKey .. 'Name')
        end
        for _, migrateFunction in pairs(settingsMoved[i]) do
            migrateFunction()
        end
    end
    if removedText ~= '' then
        ui.showMessage(L('SettingsVersionNew') .. removedText, {showInDialogue = false})
        print(L('SettingsVersionNew') .. removedText) 
    end
elseif info.settingsVersion < (storedSettingsVersion) then
    ui.showMessage(L('SettingsVersionOld'), {showInDialogue = false})
    print(L('SettingsVersionOld'))
end

modSettings.version:set('SettingsVersion', info.settingsVersion)