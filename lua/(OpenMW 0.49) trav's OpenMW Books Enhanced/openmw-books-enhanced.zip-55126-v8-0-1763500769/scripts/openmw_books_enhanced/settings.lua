local storage = require('openmw.storage')
local constants = require("scripts.openmw_books_enhanced.ui_layout.ui_constants")
local I = require('openmw.interfaces')
local async = require('openmw.async')
local constants = require("scripts.openmw_books_enhanced.ui_layout.ui_constants")

local l10nKey = 'openmw_books_enhanced'
local settingsPageKey = "SettingsTravOpenmwBooksEnhancedMainPage"

local S = {}

local settingToStorage = {}

function S.subscribeForChangesIn(settingKey, callbackOnSettingsChange)
    settingToStorage[settingKey]:subscribe(callbackOnSettingsChange)
end

local function floatSetting(settingKey, default, min, storageForThisSetting)
    S[settingKey] = function() return storageForThisSetting:get(settingKey) end
    settingToStorage[settingKey] = storageForThisSetting
    return {
        key = settingKey,
        renderer = 'number',
        name = settingKey,
        description = settingKey .. 'Description',
        default = default,
        argument =
        {
            disabled = false,
            min = min,
            integer = false
        },
    }
end

local function boolSetting(settingKey, default, storageForThisSetting)
    S[settingKey] = function() return storageForThisSetting:get(settingKey) end
    settingToStorage[settingKey] = storageForThisSetting
    return {
        key = settingKey,
        renderer = 'checkbox',
        name = settingKey,
        description = settingKey .. 'Description',
        default = default
    }
end

local function selectSetting(settingKey, default, listOfValues, storageForThisSetting)
    S[settingKey] = function() return storageForThisSetting:get(settingKey) end
    settingToStorage[settingKey] = storageForThisSetting
    return {
        key = settingKey,
        renderer = "select",
        name = settingKey,
        description = settingKey .. 'Description',
        default = default,
        argument = {
            l10n = l10nKey,
            items = listOfValues
        },
    }
end

local function colorSetting(settingKey, default, storageForThisSetting)
    S[settingKey] = function() return storageForThisSetting:get(settingKey) end
    settingToStorage[settingKey] = storageForThisSetting
    return {
        key = settingKey,
        renderer = 'color',
        name = settingKey,
        description = settingKey .. 'Description',
        default = default,
    }
end

I.Settings.registerPage({
    key = settingsPageKey,
    l10n = l10nKey,
    name = 'TravOpenmwBooksEnhancedModName',
    description = settingsPageKey .. "Description",
})

local documentWindowSettingsKey = "SettingsTravOpenmwBooksEnhanced_01Window"
local storageDocumentWindowSettings = storage.playerSection(documentWindowSettingsKey)
I.Settings.registerGroup({
    key = documentWindowSettingsKey,
    page = settingsPageKey,
    l10n = l10nKey,
    name = 'SettingsTravOpenmwBooksEnhanced_DocumentWindowSettings',
    permanentStorage = true,
    settings = {
        boolSetting('SettingsTravOpenmwBooksEnhanced_useRecommendedResolutionMultipliers', true,
            storageDocumentWindowSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_documentWindowWidthMultiplier',
            constants.documentWindowWidthMultiplier,
            0.9,
            storageDocumentWindowSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_documentWindowHeightMultiplier',
            constants.documentWindowHeightMultiplier,
            0.9,
            storageDocumentWindowSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_scrollbarWidth',
            constants.scrollbarWidth,
            4.0,
            storageDocumentWindowSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_scrollRatio',
            3.0,
            1.0,
            storageDocumentWindowSettings),
    },
})

local textSettingsKey = "SettingsTravOpenmwBooksEnhanced_02Text"
local storageTextSettings = storage.playerSection(textSettingsKey)
I.Settings.registerGroup({
    key = textSettingsKey,
    page = settingsPageKey,
    l10n = l10nKey,
    name = 'SettingsTravOpenmwBooksEnhanced_TextSettings',
    permanentStorage = true,
    settings = {
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_textDocumentNormalSize',
            constants.textDocumentNormalSize,
            10,
            storageTextSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_textDocumentPageNumberSize',
            constants.textDocumentPageNumberSize,
            10,
            storageTextSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_textDocumentButtonSize',
            constants.textDocumentButtonSize,
            10,
            storageTextSettings),
        selectSetting(
            'SettingsTravOpenmwBooksEnhanced_daedricDisplay',
            "SettingsTravOpenmwBooksEnhanced_daedricDisplay_normalDaedric",
            {
                "SettingsTravOpenmwBooksEnhanced_daedricDisplay_normalDaedric",
                "SettingsTravOpenmwBooksEnhanced_daedricDisplay_battlespireFont"
            },
            storageTextSettings),
    },
})

local imageSettingsKey = "SettingsTravOpenmwBooksEnhanced_03Image"
local storageImageSettings = storage.playerSection(imageSettingsKey)

local function updateWhenExpandImageToWidthIsSet()
    local isImageFitToPageWidthEnabled = storageImageSettings:get(
        'SettingsTravOpenmwBooksEnhanced_expandImageToWidth')
    I.Settings.updateRendererArgument(imageSettingsKey, 'SettingsTravOpenmwBooksEnhanced_expandThreshold',
        { disabled = not isImageFitToPageWidthEnabled })
end

I.Settings.registerGroup({
    key = imageSettingsKey,
    page = settingsPageKey,
    l10n = l10nKey,
    name = 'SettingsTravOpenmwBooksEnhanced_ImageSettings',
    permanentStorage = true,
    settings = {
        boolSetting(
            'SettingsTravOpenmwBooksEnhanced_colorBookcover',
            true,
            storageImageSettings),
        boolSetting(
            'SettingsTravOpenmwBooksEnhanced_expandImageToWidth',
            true,
            storageImageSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_expandThreshold',
            0.6,
            0.0,
            storageImageSettings),
        boolSetting(
            'SettingsTravOpenmwBooksEnhanced_shrinkImageToWidth',
            true,
            storageImageSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_imageSizeMult',
            1.85,
            0.9,
            storageImageSettings),
    },
})

local readStatusSettingsKey = "SettingsTravOpenmwBooksEnhanced_040BookReadStatus"
local storageReadStatusSettings = storage.playerSection(readStatusSettingsKey)

local function updateWhenReadStatusIsToggled()
    local isReadStatusDisabled = not storageReadStatusSettings:get(
        'SettingsTravOpenmwBooksEnhanced_enableReadStatusDetector')
    I.Settings.updateRendererArgument(
        readStatusSettingsKey,
        'SettingsTravOpenmwBooksEnhanced_readStatusIndicatorSize',
        { disabled = isReadStatusDisabled })
    I.Settings.updateRendererArgument(
        readStatusSettingsKey,
        'SettingsTravOpenmwBooksEnhanced_readStatusIndicatorColor',
        { disabled = isReadStatusDisabled })
    I.Settings.updateRendererArgument(
        readStatusSettingsKey,
        'SettingsTravOpenmwBooksEnhanced_readStatusIndicatorPosX',
        { disabled = isReadStatusDisabled })
    I.Settings.updateRendererArgument(
        readStatusSettingsKey,
        'SettingsTravOpenmwBooksEnhanced_readStatusIndicatorPosY',
        { disabled = isReadStatusDisabled })
end

I.Settings.registerGroup({
    key = readStatusSettingsKey,
    page = settingsPageKey,
    l10n = l10nKey,
    name = 'SettingsTravOpenmwBooksEnhanced_ReadStatusSettings',
    permanentStorage = true,
    settings = {
        boolSetting(
            'SettingsTravOpenmwBooksEnhanced_enableReadStatusDetector',
            true,
            storageReadStatusSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_readStatusIndicatorSize',
            32,
            10,
            storageReadStatusSettings),
        colorSetting(
            'SettingsTravOpenmwBooksEnhanced_readStatusIndicatorColor',
            constants.paperLikeColor,
            storageReadStatusSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_readStatusIndicatorPosX',
            0.505,
            0,
            storageReadStatusSettings),
        floatSetting(
            'SettingsTravOpenmwBooksEnhanced_readStatusIndicatorPosY',
            0.505,
            0,
            storageReadStatusSettings),
    },
})

local miscSettingsKey = "SettingsTravOpenmwBooksEnhanced_04Misc"
local storageMiscSettings = storage.playerSection(miscSettingsKey)

I.Settings.registerGroup({
    key = miscSettingsKey,
    page = settingsPageKey,
    l10n = l10nKey,
    name = 'SettingsTravOpenmwBooksEnhanced_MiscSettings',
    permanentStorage = true,
    settings = {
        boolSetting(
            'SettingsTravOpenmwBooksEnhanced_equipEnchantments',
            true,
            storageMiscSettings),
    },
})

storageImageSettings:subscribe(async:callback(updateWhenExpandImageToWidthIsSet))
storageReadStatusSettings:subscribe(async:callback(updateWhenReadStatusIsToggled))

return S
