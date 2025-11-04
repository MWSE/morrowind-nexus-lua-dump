local async = require 'openmw.async'
local storage = require 'openmw.storage'
local util = require 'openmw.util'
local vfs = require 'openmw.vfs'

local I = require 'openmw.interfaces'
local ModInfo = require 'scripts.s3.target.modInfo'

local iconNames = {}

for icon in vfs.pathsWithPrefix('textures/s3/crosshair/') do
    if icon:find('.dds') then
        iconNames[#iconNames + 1] = icon:match('.*/(.-)%.')
    end
end

--- Shorthand to generate Setting tables for input into `I.Settings.registerGroup`'s `settings` argument.
---@param key string The (table) key of the setting
---@param renderer DefaultSettingRenderer The type of setting to create
---@param argument SettingRendererOptions The options for the setting renderer, specific to the `renderer` type
---@param name string The displayed name of the setting in the menu
---@param description string The description of the setting in the menu
---@param default any The default value of the setting
---@return table
local function Setting(key, renderer, argument, name, description, default)
    return {
        key = key,
        renderer = renderer,
        argument = argument,
        name = name,
        description = description,
        default = default,
    }
end

local LockOnGroupName = 'SettingsGlobal' .. ModInfo.name .. 'LockOnGroup'
I.Settings.registerGroup {
    key = LockOnGroupName,
    page = ModInfo.name,
    l10n = ModInfo.l10nName,
    order = 0,
    name = 'MainPageName',
    permanentStorage = true,
    settings = {
        Setting(
            'S3TargetLockBinding',
            'inputBinding',
            { key = 'S3TargetLock', type = 'trigger' },
            'S3TargetLockBindingName',
            'S3TargetLockBindingDesc',
            'z'
        ),

        Setting(
            'TargetLockToggle',
            'checkbox',
            {},
            'TargetLockToggleName',
            'TargetLockToggleDesc',

            true
        ),
        Setting(
            'SwitchOnDeadTarget',
            'checkbox',
            {},
            'SwitchOnDeadTargetName',
            'SwitchOnDeadTargetDesc',
            true
        ),
        Setting(
            'CheckLOS',
            'checkbox',
            {},
            'CheckLOSName',
            'CheckLOSDesc',
            false
        ),
        Setting(
            'EnableFlickSwitch',
            'checkbox',
            {},
            'EnableFlickSwitchName',
            'EnableFlickSwitchDesc',
            true
        ),
        Setting(
            'FlickSwitchDistance',
            'number',
            { integer = true, min = 16, max = 512, },
            'FlickSwitchDistanceName',
            'FlickSwitchDistanceDesc',
            64
        ),
        Setting(
            'EnableHitBounce',
            'checkbox',
            {},
            'EnableHitBounceName',
            'EnableHitBounceDesc',
            true
        ),
        Setting(
            'HitBounceSize',
            'number',
            { integer = true, min = 1, max = 32, },
            'HitBounceSizeName',
            'HitBounceSizeDesc',
            16
        ),
        Setting(
            'DisableLockWhenSheathing',
            'checkbox',
            {},
            'DisableLockWhenSheathingName',
            'DisableLockWhenSheathingDesc',
            false
        ),
        Setting(
            'LockOnCombatStart',
            'checkbox',
            {},
            'LockOnCombatStartName',
            'LockOnCombatStartDesc',
            false
        ),
        Setting(
            'TargetMinSize',
            'number',
            { min = 0, max = 64, integer = true },
            'TargetMinSizeName',
            'TargetMinSizeDesc',
            32
        ),
        Setting(
            'TargetMinDistance',
            'number',
            { min = 0, max = 512, integer = true },
            'TargetMinDistanceName',
            'TargetMinDistanceDesc',
            256
        ),
        Setting(
            'TargetMaxSize',
            'number',
            { min = 0, max = 128, integer = true },
            'TargetMaxSizeName',
            'TargetMaxSizeDesc',
            128
        ),
        Setting(
            'TargetMaxDistance',
            'number',
            { min = 512, max = 7128, integer = true },
            'TargetMaxDistanceName',
            'TargetMaxDistanceDesc',
            3564
        ),
        Setting(
            'TargetLockIcon',
            'select',
            { items = iconNames,
                l10n = ModInfo.l10nName },
            'TargetLockIconName',
            'TargetLockIconDesc',
            'starburst'
        ),
        Setting(
            'TargetColorF',
            'color',
            {},
            'TargetColorFName',
            'TargetColorFDesc',
            util.color.hex('0df8cc')
        ),
        Setting(
            'TargetColorVH',
            'color',
            {},
            'TargetColorVHName',
            'TargetColorVHDesc',
            util.color.hex('069e00')
        ),
        Setting(
            'TargetColorH',
            'color',
            {},
            'TargetColorHName',
            'TargetColorHDesc',
            util.color.hex('047a00')
        ),
        Setting(
            'TargetColorW',
            'color',
            {},
            'TargetColorWName',
            'TargetColorWDesc',
            util.color.hex('9e7100')
        ),
        Setting(
            'TargetColorVW',
            'color',
            {},
            'TargetColorVWName',
            'TargetColorVWDesc',
            util.color.hex('4c3700')
        ),
        Setting(
            'TargetColorD',
            'color',
            {},
            'TargetColorDName',
            'TargetColorDDesc',
            util.color.hex('4c0000')
        ),
    },
}

local settingNames = {
    'TargetLockIcon',
    'SwitchOnDeadTarget',
    'FlickSwitchDistance',
    'EnableFlickSwitch',
    'TargetColorF',
    'TargetColorVH',
    'TargetColorH',
    'TargetColorW',
    'TargetColorVW',
    'TargetColorD'
}

local LockOnGroup = storage.globalSection(LockOnGroupName)
LockOnGroup:subscribe(
    async:callback(
        function(groupName, _)
            local minSize, maxSize = LockOnGroup:get('TargetMinSize'), LockOnGroup:get('TargetMaxSize')
            local minDistance, maxDistance = LockOnGroup:get('TargetMinDistance'), LockOnGroup:get('TargetMaxDistance')
            local disabled = not LockOnGroup:get('TargetLockToggle')

            I.Settings.updateRendererArgument(groupName, 'TargetMinSize', { max = (maxSize - 1), disabled = disabled, })
            I.Settings.updateRendererArgument(groupName, 'TargetMaxSize', { min = minSize + 1, disabled = disabled, })
            I.Settings.updateRendererArgument(groupName, 'TargetMinDistance',
                { max = (maxDistance - 1), disabled = disabled, })
            I.Settings.updateRendererArgument(groupName, 'TargetMaxDistance',
                { min = minDistance + 1, disabled = disabled, })

            for _, settingName in ipairs(settingNames) do
                if settingName == 'TargetLockIcon' then
                    I.Settings.updateRendererArgument(groupName, settingName,
                        { disabled = disabled, items = iconNames, l10n = ModInfo.l10nName, })
                else
                    I.Settings.updateRendererArgument(groupName, settingName, { disabled = disabled })
                end
            end
        end
    )
)
