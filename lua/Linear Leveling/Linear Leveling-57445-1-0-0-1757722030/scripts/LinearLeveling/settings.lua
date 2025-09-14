local storage = require('openmw.storage')

local common = require('scripts.LinearLeveling.common')

local skillIncreasesPerMultiplierKey = 'SettingsSkillIncreasesPerMultiplier' .. common.metadata.modId
local skillIncreaseValuesKey = 'SettingsSkillIncreaseValues' .. common.metadata.modId

local skillIncreasesPerMultiplierSetting = 'SkillIncreasesPerMultiplierSetting'
local majorSkillValueSetting = 'MajorSkillValueSetting'
local minorSkillValueSetting = 'MinorSkillValueSetting'
local miscSkillValueSetting = 'MiscSkillValueSetting'

local page = {
    key = common.metadata.modId,
    l10n = common.metadata.modId,
    name = common.metadata.modName,
    description = 'Default settings reflect vanilla progression. Change at your own risk.',
}

local skillIncreasesPerMultiplierGroup = {
    key = skillIncreasesPerMultiplierKey,
    page = common.metadata.modId,
    l10n = common.metadata.modId,
    name = 'Skill Increases Per Multiplier',
    description = 'The number of skill increases required to improve an attribute multiplier.',
    permanentStorage = false,
    settings = {
        {
            key = skillIncreasesPerMultiplierSetting,
            name = 'Number of Skill Increases',
            renderer = 'number',
            argument = { min = 0 },
            default = 2.5,
        },
    },
}

local skillIncreaseValuesGroup = {
    key = skillIncreaseValuesKey,
    page = common.metadata.modId,
    l10n = common.metadata.modId,
    name = 'Skill Increase Values',
    description = 'The amount a skill increase adds to attribute multiplier progression.',
    permanentStorage = false,
    settings = {
        {
            key = majorSkillValueSetting,
            name = 'Major Skill Value',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = minorSkillValueSetting,
            name = 'Minor Skill Value',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = miscSkillValueSetting,
            name = 'Misc Skill Value',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
    },
}

local function getSetting(group, setting)
    local settings = storage.playerSection(group)
    return settings:get(setting)
end

local function getSkillIncreasesPerMultiplier()
    return getSetting(skillIncreasesPerMultiplierKey, skillIncreasesPerMultiplierSetting)
end

local function getMajorSkillValue()
    return getSetting(skillIncreaseValuesKey, majorSkillValueSetting)
end

local function getMinorSkillValue()
    return getSetting(skillIncreaseValuesKey, minorSkillValueSetting)
end

local function getMiscSkillValue()
    return getSetting(skillIncreaseValuesKey, miscSkillValueSetting)
end

return {
    page = page,
    groups = {
        skillIncreasesPerMultiplierGroup,
        skillIncreaseValuesGroup,
    },
    getSkillIncreasesPerMultiplier = getSkillIncreasesPerMultiplier,
    getMajorSkillValue = getMajorSkillValue,
    getMinorSkillValue = getMinorSkillValue,
    getMiscSkillValue = getMiscSkillValue,
}
