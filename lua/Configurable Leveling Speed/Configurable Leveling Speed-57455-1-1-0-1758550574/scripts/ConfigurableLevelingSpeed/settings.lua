local storage = require('openmw.storage')

local common = require('scripts.ConfigurableLevelingSpeed.common')

local globalSpeedKey = 'Settings01GlobalSpeed' .. common.metadata.modId
local classSpeedKey = 'Settings02ClassSpeed' .. common.metadata.modId
local individualSpeedKey = 'Settings03IndividualSpeed' .. common.metadata.modId
local magickaScalingKey = 'Settings04MagickaScaling' .. common.metadata.modId

local globalSpeedFromSetting = 'GlobalSpeedFromSetting'
local globalSpeedToSetting = 'GlobalSpeedToSetting'

local classSpeedMajorSetting = 'ClassSpeedMajorSetting'
local classSpeedMinorSetting = 'ClassSpeedMinorSetting'
local classSpeedMiscSetting = 'ClassSpeedMiscSetting'

local individualSpeedAcrobaticsSetting = 'IndividualSpeedAcrobaticsSetting'
local individualSpeedAlchemySetting = 'IndividualSpeedAlchemySetting'
local individualSpeedAlterationSetting = 'IndividualSpeedAlterationSetting'
local individualSpeedArmorerSetting = 'IndividualSpeedArmorerSetting'
local individualSpeedAthleticsSetting = 'IndividualSpeedAthleticsSetting'
local individualSpeedAxeSetting = 'IndividualSpeedAxeSetting'
local individualSpeedBlockSetting = 'IndividualSpeedBlockSetting'
local individualSpeedBluntWeaponSetting = 'IndividualSpeedBluntWeaponSetting'
local individualSpeedConjurationSetting = 'IndividualSpeedConjurationSetting'
local individualSpeedDestructionSetting = 'IndividualSpeedDestructionSetting'
local individualSpeedEnchantSetting = 'IndividualSpeedEnchantSetting'
local individualSpeedHandToHandSetting = 'IndividualSpeedHandToHandSetting'
local individualSpeedHeavyArmorSetting = 'IndividualSpeedHeavyArmorSetting'
local individualSpeedIllusionSetting = 'IndividualSpeedIllusionSetting'
local individualSpeedLightArmorSetting = 'IndividualSpeedLightArmorSetting'
local individualSpeedLongBladeSetting = 'IndividualSpeedLongBladeSetting'
local individualSpeedMarksmanSetting = 'IndividualSpeedMarksmanSetting'
local individualSpeedMediumArmorSetting = 'IndividualSpeedMediumArmorSetting'
local individualSpeedMercantileSetting = 'IndividualSpeedMercantileSetting'
local individualSpeedMysticismSetting = 'IndividualSpeedMysticismSetting'
local individualSpeedRestorationSetting = 'IndividualSpeedRestorationSetting'
local individualSpeedSecuritySetting = 'IndividualSpeedSecuritySetting'
local individualSpeedShortBladeSetting = 'IndividualSpeedShortBladeSetting'
local individualSpeedSneakSetting = 'IndividualSpeedSneakSetting'
local individualSpeedSpearSetting = 'IndividualSpeedSpearSetting'
local individualSpeedSpeechcraftSetting = 'IndividualSpeedSpeechcraftSetting'
local individualSpeedUnarmoredSetting = 'IndividualSpeedUnarmoredSetting'

local magickaScalingEnabledSetting = 'MagickaScalingEnabledSetting'
local magickaScalingRateSetting = 'MagickaScalingRateSetting'

local page = {
    key = common.metadata.modId,
    l10n = common.metadata.modId,
    name = common.metadata.modName,
    description = 'Configure leveling speed for skills on a global, major/minor/misc or individual basis. Values ' ..
        'are multiplicative with each other.',
}

local globalSpeedGroup = {
    key = globalSpeedKey,
    page = common.metadata.modId,
    l10n = common.metadata.modId,
    name = 'Global Leveling Speed',
    description = 'The leveling speed that applies to all skills. Set From and To to different numbers for ' ..
        'exponential scaling, or to the same number for constant scaling.',
    permanentStorage = false,
    settings = {
        {
            key = globalSpeedFromSetting,
            name = 'From (Speed at Level 0)',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = globalSpeedToSetting,
            name = 'To (Speed at Level 100)',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
    },
}

local classSpeedGroup = {
    key = classSpeedKey,
    page = common.metadata.modId,
    l10n = common.metadata.modId,
    name = 'Class Skill Leveling Speed',
    description = 'The leveling speed that applies to major, minor or misc skill groups.',
    permanentStorage = false,
    settings = {
        {
            key = classSpeedMajorSetting,
            name = 'Major Skills',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = classSpeedMinorSetting,
            name = 'Minor Skills',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = classSpeedMiscSetting,
            name = 'Misc Skills',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
    },
}

local individualSpeedGroup = {
    key = individualSpeedKey,
    page = common.metadata.modId,
    l10n = common.metadata.modId,
    name = 'Individual Skill Leveling Speed',
    description = 'The leveling speed that applies to individual skills.',
    permanentStorage = false,
    settings = {
        {
            key = individualSpeedAcrobaticsSetting,
            name = 'Acrobatics',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedAlchemySetting,
            name = 'Alchemy',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedAlterationSetting,
            name = 'Alteration',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedArmorerSetting,
            name = 'Armorer',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedAthleticsSetting,
            name = 'Athletics',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedAxeSetting,
            name = 'Axe',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedBlockSetting,
            name = 'Block',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedBluntWeaponSetting,
            name = 'Blunt Weapon',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedConjurationSetting,
            name = 'Conjuration',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedDestructionSetting,
            name = 'Destruction',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedEnchantSetting,
            name = 'Enchant',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedHandToHandSetting,
            name = 'Hand to Hand',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedHeavyArmorSetting,
            name = 'Heavy Armor',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedIllusionSetting,
            name = 'Illusion',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedLightArmorSetting,
            name = 'Light Armor',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedLongBladeSetting,
            name = 'Long Blade',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedMarksmanSetting,
            name = 'Marksman',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedMediumArmorSetting,
            name = 'Medium Armor',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedMercantileSetting,
            name = 'Mercantile',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedMysticismSetting,
            name = 'Mysticism',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedRestorationSetting,
            name = 'Restoration',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedSecuritySetting,
            name = 'Security',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedShortBladeSetting,
            name = 'Short Blade',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedSneakSetting,
            name = 'Sneak',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedSpearSetting,
            name = 'Spear',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedSpeechcraftSetting,
            name = 'Speechcraft',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
        {
            key = individualSpeedUnarmoredSetting,
            name = 'Unarmored',
            renderer = 'number',
            argument = { min = 0 },
            default = 1,
        },
    },
}

local magickaScalingGroup = {
    key = magickaScalingKey,
    page = common.metadata.modId,
    l10n = common.metadata.modId,
    name = 'Magicka Scaling',
    description = 'Enable to scale magicka skill growth by spell cost. In vanilla, all spells give 1 XP per cast, ' ..
        'regardless of cost.',
    permanentStorage = false,
    settings = {
        {
            key = magickaScalingEnabledSetting,
            name = 'Enabled',
            renderer = 'checkbox',
            default = false,
        },
        {
            key = magickaScalingRateSetting,
            name = 'XP Per Magicka',
            renderer = 'number',
            argument = { min = 0 },
            default = 0.2,
        },
    },
}

local function getSetting(group, setting)
    local settings = storage.playerSection(group)
    return settings:get(setting)
end

local function getGlobalSpeed()
    return {
        from = getSetting(globalSpeedKey, globalSpeedFromSetting),
        to = getSetting(globalSpeedKey, globalSpeedToSetting),
    }
end

local function getClassSpeed()
    return {
        major = getSetting(classSpeedKey, classSpeedMajorSetting),
        minor = getSetting(classSpeedKey, classSpeedMinorSetting),
        misc = getSetting(classSpeedKey, classSpeedMiscSetting),
    }
end

--- Uses lowercase skill names to match OpenMW's skill IDs.
--- @return table
local function getIndividualSpeed()
    return {
        acrobatics = getSetting(individualSpeedKey, individualSpeedAcrobaticsSetting),
        alchemy = getSetting(individualSpeedKey, individualSpeedAlchemySetting),
        alteration = getSetting(individualSpeedKey, individualSpeedAlterationSetting),
        armorer = getSetting(individualSpeedKey, individualSpeedArmorerSetting),
        athletics = getSetting(individualSpeedKey, individualSpeedAthleticsSetting),
        axe = getSetting(individualSpeedKey, individualSpeedAxeSetting),
        block = getSetting(individualSpeedKey, individualSpeedBlockSetting),
        bluntweapon = getSetting(individualSpeedKey, individualSpeedBluntWeaponSetting),
        conjuration = getSetting(individualSpeedKey, individualSpeedConjurationSetting),
        destruction = getSetting(individualSpeedKey, individualSpeedDestructionSetting),
        enchant = getSetting(individualSpeedKey, individualSpeedEnchantSetting),
        handtohand = getSetting(individualSpeedKey, individualSpeedHandToHandSetting),
        heavyarmor = getSetting(individualSpeedKey, individualSpeedHeavyArmorSetting),
        illusion = getSetting(individualSpeedKey, individualSpeedIllusionSetting),
        lightarmor = getSetting(individualSpeedKey, individualSpeedLightArmorSetting),
        longblade = getSetting(individualSpeedKey, individualSpeedLongBladeSetting),
        marksman = getSetting(individualSpeedKey, individualSpeedMarksmanSetting),
        mediumarmor = getSetting(individualSpeedKey, individualSpeedMediumArmorSetting),
        mercantile = getSetting(individualSpeedKey, individualSpeedMercantileSetting),
        mysticism = getSetting(individualSpeedKey, individualSpeedMysticismSetting),
        restoration = getSetting(individualSpeedKey, individualSpeedRestorationSetting),
        security = getSetting(individualSpeedKey, individualSpeedSecuritySetting),
        shortblade = getSetting(individualSpeedKey, individualSpeedShortBladeSetting),
        sneak = getSetting(individualSpeedKey, individualSpeedSneakSetting),
        spear = getSetting(individualSpeedKey, individualSpeedSpearSetting),
        speechcraft = getSetting(individualSpeedKey, individualSpeedSpeechcraftSetting),
        unarmored = getSetting(individualSpeedKey, individualSpeedUnarmoredSetting),
    }
end

local function getMagickaScaling()
    return {
        enabled = getSetting(magickaScalingKey, magickaScalingEnabledSetting),
        rate = getSetting(magickaScalingKey, magickaScalingRateSetting),
    }
end

return {
    page = page,
    groups = {
        globalSpeedGroup,
        classSpeedGroup,
        individualSpeedGroup,
        magickaScalingGroup,
    },
    getGlobalSpeed = getGlobalSpeed,
    getClassSpeed = getClassSpeed,
    getIndividualSpeed = getIndividualSpeed,
    getMagickaScaling = getMagickaScaling,
}
