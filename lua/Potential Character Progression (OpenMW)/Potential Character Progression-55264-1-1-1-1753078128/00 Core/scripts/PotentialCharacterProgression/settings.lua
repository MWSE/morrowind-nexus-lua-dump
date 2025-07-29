-- Settings
local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')

local info = require('scripts.PotentialCharacterProgression.info')
local mwData = require('scripts.' .. info.name .. '.mwdata')

local function sortAlphabetical(a, b)
    return a:lower() < b:lower()
end

local function capital(text)
    return text:gsub('^%l', string.upper)
end

local modSettings = {
    basicOld = storage.playerSection('SettingsPlayer' .. info.name),
    basic = storage.playerSection('SettingsPlayer' .. info.name .. 'Basic'),
    health = storage.playerSection('SettingsPlayer' .. info.name .. 'Health'),
    skill = storage.playerSection('SettingsPlayer' .. info.name .. 'Skill'),
    version = storage.playerSection('SettingsPlayer' .. info.name .. 'Version')
}

-- Settings version was mistakenly not saved in storage until 1.1.0
local storedSettingsVersion = modSettings.version:get('SettingsVersion')

-- Since there were multiple settings versions not saved in storage, need to check specific values to determine which one
if storedSettingsVersion == nil then
    if modSettings.health:get('RetroactiveHealth') ~= nil then
        storedSettingsVersion = 2
    else
        storedSettingsVersion = 1
    end
end

-- Can only set defaults for vanilla attributes
-- If future OpenMW features allow for adding attributes, this will help account for them
local function populateAttributes(defaults, value)
    local populatedAttributes = {}
    for i, attributeRecord in pairs(core.stats.Attribute.records) do
        populatedAttributes[attributeRecord.id] = defaults[attributeRecord.id] or value
    end
    return populatedAttributes
end

input.registerTrigger {
    key = 'Menu' .. info.name,
    l10n = info.name
}

I.Settings.registerPage {
    key = 'Page' .. info.name,
    l10n = info.name,
    name = 'PageName'
}

-- Something stupid to get around I.Settings.updateRendererArgument() replacing the entire table
local dependentArguments = {
    basic = {
        SharedAttributeCap = {
            integer = true,
            min = 0
        },
        FavoredAttributeCap = {
            integer = true,
            min = 0
        },
        UnfavoredAttributeCap = {
            integer = true,
            min = 0
        },
        UniqueAttributeCapValues = {
            integer = true,
            min = 0,
            max = nil
        }
    },
    health = {
        RetroactiveStartHealth = {},
        GradualRetroactiveHealth = {},
        GradualRetroactiveHealthIncrement = {
            integer = true,
            min = 1,
            max = nil
        },
        CustomHealthCoefficients = {
            l10n = info.name,
            integer = false,
            min = nil,
            max = nil
        },
        CustomGainMultiplier = {
            integer = false,
            min = 0,
            max = nil
        }
    },
    skill = {}
}

-- Dependent settings must belong to the same section as the settings they depend on
local dependentSettings = {
    basic = {
        SharedAttributeCap = {AttributeCapMethod = 'SharedCap'},
        FavoredAttributeCap = {AttributeCapMethod = 'FavoredCap'},
        UnfavoredAttributeCap = {AttributeCapMethod = 'FavoredCap'},
        UniqueAttributeCapValues = {AttributeCapMethod = 'UniqueCap'}
    },
    health = {
        RetroactiveStartHealth = {RetroactiveHealth = true},
        GradualRetroactiveHealth = {RetroactiveHealth = true},
        GradualRetroactiveHealthIncrement = {RetroactiveHealth = true, GradualRetroactiveHealth = true},
        CustomHealthCoefficients = {CustomHealth = true},
        CustomGainMultiplier = {CustomHealth = true}
    },
    skill = {}
}

-- Basic settings

I.Settings.registerGroup {
    key = 'SettingsPlayer' .. info.name .. 'Basic',
    page = 'Page' .. info.name,
    order = 1,
    l10n = info.name,
    name = 'SettingsBasicName',
    permanentStorage = true,
    settings = {
        {
            key = 'MenuKey',
            renderer = info.name .. 'KeyBind',
            name = 'MenuKeyName',
            default = input.KEY.L
        },
        {
            key = 'JailExploit',
            renderer = 'checkbox',
            name = 'JailExploitName',
            description = 'JailExploitDesc',
            default = false
        },
        {
            key = 'AttributeCapMethod',
            renderer = info.name .. 'Select',
            name = 'AttributeCapMethodName',
            description = 'AttributeCapMethodDesc',
            default = 'SharedCap',
            argument = {
                items = {'SharedCap', 'FavoredCap', 'UniqueCap'},
                l10n = info.name
            }
        },
        {
            key = 'SharedAttributeCap',
            renderer = 'number',
            name = 'SharedAttributeCapName',
            default = 100,
            argument = dependentArguments.basic.SharedAttributeCap
        },
        {
            key = 'FavoredAttributeCap',
            renderer = 'number',
            name = 'FavoredAttributeCapName',
            default = 100,
            argument = dependentArguments.basic.FavoredAttributeCap
        },
        {
            key = 'UnfavoredAttributeCap',
            renderer = 'number',
            name = 'UnfavoredAttributeCapName',
            default = 100,
            argument = dependentArguments.basic.UnfavoredAttributeCap
        },
        {
            key = 'UniqueAttributeCapValues',
            renderer = info.name .. 'UniqueCaps',
            name = 'UniqueAttributeCapValuesName',
            default = populateAttributes(
                {
                    strength = 100,
                    intelligence = 100,
                    willpower = 100,
                    agility = 100,
                    speed = 100,
                    endurance = 100,
                    personality = 100,
                    luck = 100
                }, 
                100),
            argument = dependentArguments.basic.UniqueAttributeCapValues
        }
    }
}

-- Health settings

I.Settings.registerGroup {
    key = 'SettingsPlayer' .. info.name .. 'Health',
    page = 'Page' .. info.name,
    order = 2,
    l10n = info.name,
    name = 'SettingsHealthName',
    description = 'SettingsHealthDesc',
    permanentStorage = true,
    settings = {
        {
            key = 'RetroactiveHealth',
            renderer = 'checkbox',
            name = 'RetroactiveHealthName',
            description = 'RetroactiveHealthDesc',
            default = false
        },
        {
            key = 'RetroactiveStartHealth',
            renderer = 'checkbox',
            name = 'RetroactiveStartHealthName',
            description = 'RetroactiveStartHealthDesc',
            default = false,
            argument = dependentArguments.health.RetroactiveStartHealth
        },
        {
            key = 'GradualRetroactiveHealth',
            renderer = 'checkbox',
            name = 'GradualRetroactiveHealthName',
            description = 'GradualRetroactiveHealthDesc',
            default = false,
            argument = dependentArguments.health.GradualRetroactiveHealth
        },
        {
            key = 'GradualRetroactiveHealthIncrement',
            renderer = 'number',
            name = 'GradualRetroactiveHealthIncrementName',
            description = 'GradualRetroactiveHealthIncrementDesc',
            default = 5,
            argument = dependentArguments.health.GradualRetroactiveHealthIncrement
        },
        {
            key = 'CustomHealth',
            renderer = 'checkbox',
            name = 'CustomHealthName',
            description = 'CustomHealthDesc',
            default = false
        },
        {
            key = 'CustomHealthCoefficients',
            renderer = info.name .. 'Coefficients',
            name = 'CustomHealthCoefficientsName',
            description = 'CustomHealthCoefficientsDesc',
            default = populateAttributes(
                {
                    strength = 2,
                    intelligence = 0,
                    willpower = 1,
                    agility = 0,
                    speed = 0,
                    endurance = 4,
                    personality = 0,
                    luck = 0
                }, 
                0),
            argument = dependentArguments.health.CustomHealthCoefficients
        },
        {
            key = 'CustomGainMultiplier',
            renderer = 'number',
            name = 'CustomGainMultiplierName',
            description = 'CustomGainMultiplierDesc',
            default = 0.1,
            argument = dependentArguments.health.CustomGainMultiplier
        }
    }
}

-- Balance settings

I.Settings.registerGroup {
    key = 'SettingsPlayer' .. info.name .. 'Balance',
    page = 'Page' .. info.name,
    order = 3,
    l10n = info.name,
    name = 'SettingsBalanceName',
    description = 'SettingsBalanceDesc',
    permanentStorage = true,
    settings = {
        {
            key = 'PotentialPerSkill',
            renderer = 'number',
            name = 'PotentialPerSkillName',
            default = 0.5,
            argument = {
                min = 0.0
            }
        },
        {
            key = 'PotentialPerMinorSkill',
            renderer = 'number',
            name = 'PotentialPerMinorSkillName',
            default = 0.5,
            argument = {
                min = 0.0
            }
        },
        {
            key = 'PotentialPerMajorSkill',
            renderer = 'number',
            name = 'PotentialPerMajorSkillName',
            default = 0.5,
            argument = {
                min = 0.0
            }
        },
        {
            key = 'ExperiencePerLevel',
            renderer = 'number',
            name = 'ExperiencePerLevelName',
            default = 15,
            argument = {
                integer = true,
                min = 0.0
            }
        },
        {
            key = 'ExperienceCost',
            renderer = 'number',
            name = 'ExperienceCostName',
            default = 1,
            argument = {
                integer = true,
                min = 0
            }
        },
        {
            key = 'ExperienceCostOver',
            renderer = 'number',
            name = 'ExperienceCostOverName',
            default = 5,
            argument = {
                integer = true,
                min = 0
            }
        },
        {
            key = 'ExperienceCostFavored',
            renderer = 'number',
            name = 'ExperienceCostFavoredName',
            default = 1,
            argument = {
                integer = true,
                min = 0
            }
        },
        {
            key = 'ExperienceCostFavoredOver',
            renderer = 'number',
            name = 'ExperienceCostFavoredOverName',
            default = 2,
            argument = {
                integer = true,
                min = 0
            }
        },
        {
            key = 'LevelProgressPerSkill',
            renderer = 'number',
            name = 'LevelProgressPerSkillName',
            default = 1,
            argument = {
                integer = true,
                min = 0
            }
        },
        {
            key = 'LevelProgressPerMinorSkill',
            renderer = 'number',
            name = 'LevelProgressPerMinorSkillName',
            default = 1,
            argument = {
                integer = true,
                min = 0
            }
        },
        {
            key = 'LevelProgressPerMajorSkill',
            renderer = 'number',
            name = 'LevelProgressPerMajorSkillName',
            default = 1,
            argument = {
                integer = true,
                min = 0
            }
        }
    }
}

-- Skill settings

local skillSettings = {
    {
        key = 'CustomSkillAttributes',
        renderer = 'checkbox',
        name = 'CustomSkillAttributesName',
        description = 'CustomSkillAttributesDesc',
        default = false
    }
}

local skillDefaults = {
    acrobatics  = {strength = 3, intelligence = 0, willpower = 0, agility = 1, speed = 2, endurance = 1, personality = 0, luck = 1},
    armorer     = {strength = 4, intelligence = 0, willpower = 0, agility = 0, speed = 0, endurance = 3, personality = 0, luck = 1},
    axe         = {strength = 4, intelligence = 0, willpower = 0, agility = 1, speed = 0, endurance = 2, personality = 0, luck = 1},
    bluntweapon = {strength = 3, intelligence = 0, willpower = 2, agility = 1, speed = 1, endurance = 0, personality = 0, luck = 1},
    longblade   = {strength = 3, intelligence = 0, willpower = 0, agility = 2, speed = 1, endurance = 1, personality = 0, luck = 1},
    alchemy     = {strength = 0, intelligence = 5, willpower = 0, agility = 0, speed = 0, endurance = 1, personality = 1, luck = 1},
    conjuration = {strength = 0, intelligence = 4, willpower = 1, agility = 0, speed = 0, endurance = 0, personality = 2, luck = 1},
    enchant     = {strength = 0, intelligence = 6, willpower = 0, agility = 0, speed = 0, endurance = 0, personality = 1, luck = 1},
    security    = {strength = 0, intelligence = 3, willpower = 0, agility = 3, speed = 0, endurance = 0, personality = 1, luck = 1},
    alteration  = {strength = 0, intelligence = 2, willpower = 5, agility = 0, speed = 0, endurance = 0, personality = 0, luck = 1},
    destruction = {strength = 0, intelligence = 1, willpower = 6, agility = 0, speed = 0, endurance = 0, personality = 0, luck = 1},
    mysticism   = {strength = 0, intelligence = 2, willpower = 4, agility = 0, speed = 0, endurance = 0, personality = 1, luck = 1},
    restoration = {strength = 0, intelligence = 1, willpower = 4, agility = 0, speed = 0, endurance = 0, personality = 2, luck = 1},
    block       = {strength = 0, intelligence = 0, willpower = 0, agility = 3, speed = 2, endurance = 2, personality = 0, luck = 1},
    lightarmor  = {strength = 0, intelligence = 0, willpower = 1, agility = 3, speed = 3, endurance = 0, personality = 0, luck = 1},
    marksman    = {strength = 2, intelligence = 1, willpower = 0, agility = 4, speed = 0, endurance = 0, personality = 0, luck = 1},
    sneak       = {strength = 0, intelligence = 0, willpower = 0, agility = 4, speed = 2, endurance = 0, personality = 1, luck = 1},
    athletics   = {strength = 0, intelligence = 0, willpower = 1, agility = 0, speed = 4, endurance = 2, personality = 0, luck = 1},
    handtohand  = {strength = 1, intelligence = 0, willpower = 0, agility = 1, speed = 4, endurance = 1, personality = 0, luck = 1},
    shortblade  = {strength = 1, intelligence = 0, willpower = 0, agility = 2, speed = 4, endurance = 0, personality = 0, luck = 1},
    unarmored   = {strength = 0, intelligence = 0, willpower = 2, agility = 0, speed = 3, endurance = 2, personality = 0, luck = 1},
    heavyarmor  = {strength = 3, intelligence = 0, willpower = 0, agility = 0, speed = 0, endurance = 4, personality = 0, luck = 1},
    mediumarmor = {strength = 2, intelligence = 0, willpower = 0, agility = 1, speed = 0, endurance = 4, personality = 0, luck = 1},
    spear       = {strength = 1, intelligence = 0, willpower = 0, agility = 1, speed = 1, endurance = 4, personality = 0, luck = 1},
    illusion    = {strength = 0, intelligence = 1, willpower = 1, agility = 0, speed = 0, endurance = 0, personality = 5, luck = 1},
    mercantile  = {strength = 0, intelligence = 1, willpower = 0, agility = 0, speed = 0, endurance = 0, personality = 6, luck = 1},
    speechcraft = {strength = 0, intelligence = 0, willpower = 0, agility = 0, speed = 0, endurance = 0, personality = 7, luck = 1},
}

local skillList = {}

for i, skillRecord in ipairs(core.stats.Skill.records) do
    table.insert(skillList, skillRecord.id)
end

table.sort(skillList, sortAlphabetical)

for i, skillId in ipairs(skillList) do
    dependentArguments.skill[capital(skillId) .. 'Attributes'] = {l10n = info.name, integer = false, min = 0, max = nil}
    dependentSettings.skill[capital(skillId) .. 'Attributes'] = {CustomSkillAttributes = true}
    table.insert(skillSettings, {
        key = capital(skillId) .. 'Attributes',
        renderer = info.name .. 'SkillAttributes',
        name = core.stats.Skill.record(skillId).name .. '  ',
        default = populateAttributes(skillDefaults[skillId] or {}, 0),
        argument = dependentArguments.skill[capital(skillId) .. 'Attributes']
    })
end

I.Settings.registerGroup {
    key = 'SettingsPlayer' .. info.name .. 'Skill',
    page = 'Page' .. info.name,
    order = 4,
    l10n = info.name,
    name = 'SettingsSkillName',
    permanentStorage = true,
    settings = skillSettings
}

-- Data settings

I.Settings.registerGroup {
    key = 'SettingsPlayer' .. info.name .. 'Data',
    page = 'Page' .. info.name,
    order = 5,
    l10n = info.name,
    name = 'SettingsDataName',
    permanentStorage = true,
    settings = {
        {
            key = 'ClearData',
            renderer = info.name .. 'Button',
            name = 'ClearDataName',
            description = 'ClearDataDesc',
            default = 0,
            argument = {
                l10n = info.name,
                text = 'ClearDataButton'
            }
        }
    }
}

-- Debug settings

I.Settings.registerGroup {
    key = 'SettingsPlayer' .. info.name .. 'Debug',
    page = 'Page' .. info.name,
    order = 6,
    l10n = info.name,
    name = 'SettingsDebugName',
    permanentStorage = true,
    settings = {
        {
            key = 'DebugMode',
            renderer = 'checkbox',
            name = 'DebugModeName',
            description = 'DebugModeDesc',
            default = false
        }
    }
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
modSettings.health:subscribe(dependentCallback)
modSettings.skill:subscribe(dependentCallback)

-- Lists of moved/removed settings for each settings version
-- Used to migrate old setting values/inform player when a setting was removed

-- Settings to be migrated are not assumed to exist
local settingsMoved = {
    [1] = {},
    [2] = {
        RetroactiveHealth = function()
            local oldSetting = modSettings.basicOld:get('RetroactiveHealth')
            modSettings.health:set('RetroactiveHealth', oldSetting or false)
        end,
        RetroactiveStartHealth = function()
            local oldSetting = modSettings.basicOld:get('RetroactiveStartHealth')
            modSettings.health:set('RetroactiveStartHealth', oldSetting or false)
        end,
    },
    [3] = {
        BasicSettings = function()
            for k, v in pairs(modSettings.basicOld:asTable()) do
                modSettings.basic:set(k, v)
            end
        end,
        AttributeCap = function()
            local oldSetting = modSettings.basic:get('AttributeCap')
            modSettings.basic:set('SharedAttributeCap', oldSetting or 100)
        end,
        UniqueAttributeCap = function()
            local oldSetting = modSettings.basic:get('UniqueAttributeCap') 
            if oldSetting == true then
                modSettings.basic:set('AttributeCapMethod', 'UniqueCap')
            elseif oldSetting == false then
                modSettings.basic:set('AttributeCapMethod', 'SharedCap')
            end
        end
    }
}

local settingsRemoved = {
    [1] = {},
    [2] = {},
    [3] = {}
}

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
