local async = require 'openmw.async'
local storage = require 'openmw.storage'
local time = require 'openmw_aux.time'
local util = require 'openmw.util'
local vfs = require 'openmw.vfs'

local I = require 'openmw.interfaces'

local ModInfo = require 'scripts.sw4.modinfo'

local iconNames = {}
local cursorIconNames = {}

for icon in vfs.pathsWithPrefix('textures/sw4/crosshair/') do
    if icon:find('.dds') then
        iconNames[#iconNames + 1] = icon:match(".*/(.-)%.")
    end
end

for icon in vfs.pathsWithPrefix('textures/sw4/cursor/') do
    if icon:find('.dds') then
        cursorIconNames[#cursorIconNames + 1] = icon:match(".*/(.-)%.")
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

local function LimitedPrecision(value)
    return tonumber(string.format("%.5f", value))
end

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'CoreGroup',
    page = ModInfo.name .. 'CorePage',
    order = 0,
    l10n = ModInfo.l10nName,
    name = 'Core',
    permanentStorage = true,
    settings = {
        Setting(
            'DebugEnable',
            'checkbox',
            {},
            'Show Debug Messages',
            'Displays debug messages in the (classic) console.',
            false
        ),
        Setting(
            'RightClickExit',
            'checkbox',
            {},
            'Right Click Menu Exit',
            'Use RMB to exit all menus',
            true
        ),
    }
}

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'QuickActionsGroup',
    page = ModInfo.name .. 'QuickActionsPage',
    order = 0,
    l10n = ModInfo.l10nName,
    name = 'Quick Actions',
    permanentStorage = true,
    settings = {
        Setting(
            'QuickCastEnable',
            'checkbox',
            {},
            'Enable Quick Casting',
            '',
            true
        ),
        Setting(
            'QuickCastNoTransition',
            'checkbox',
            {},
            'Skip Stance Transitions',
            'If enabled, skips equip/unequip animations during quick casting.',
            true
        ),
        Setting(
            'QuickWithKeys',
            'checkbox',
            { disabled = true },
            'Use QuickKeys for QuickCast',
            'Not yet implemented.',
            true
        ),
    }
}

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'BindingGroup',
    page = ModInfo.name .. 'CorePage',
    order = 1,
    l10n = ModInfo.l10nName,
    name = 'Key Bindings',
    permanentStorage = true,
    settings = {
        Setting(
            'SW4_TargetLockBinding',
            "inputBinding",
            { key = 'SW4_TargetLock', type = "action" },
            'Target Lock Toggle',
            'Keybind used to lock onto targets in combat.',
            'x'
        ),
        -- Setting(
        --     'SW4_WeaponCycle',
        --     "inputBinding",
        --     { key = 'SW4_WeaponCycle', type = "trigger" },
        --     'Weapon Cycle',
        --     'Switch between melee, ranged, or the last of the two used.',
        --     'v'
        -- ),
    }
}

local LockOnGroupName = 'SettingsGlobal' .. ModInfo.name .. 'LockOnGroup'

I.Settings.registerGroup {
    key = LockOnGroupName,
    page = ModInfo.name .. 'CorePage',
    order = 2,
    l10n = ModInfo.name,
    name = 'Lock-On and Targeting',
    permanentStorage = true,
    settings = {
        Setting(
            'TargetLockToggle',
            'checkbox',
            {},
            'Enabled',
            'If set to false, target locking is completely disabled. Recommended to leave enabled.',
            true
        ),
        Setting(
            'SwitchOnDeadTarget',
            'checkbox',
            {},
            'Auto-Switch on Dead Target',
            'If the current target is dead, and this setting is true, a new one will be automatically selected once the dead target has been identified.',
            true
        ),
        Setting(
            'CheckLOS',
            'checkbox',
            {},
            'Use Line-of-Sight Checks',
            'If enabled, uses line of sight to break target locking if you can\'t see the enemy. DISabled by default to improve performance.',
            false
        ),
        Setting(
            'TargetMinSize',
            'number',
            { min = 0, max = 64, integer = true },
            'Minimum Target Size',
            'Size of the targeting icon at minimum distance.',
            32
        ),
        Setting(
            'TargetMinDistance',
            'number',
            { min = 0, max = 512, integer = true },
            'Minimum Target Distance',
            'Distance from the locked target at which the icon will be at minimum size.',
            256
        ),
        Setting(
            'TargetMaxSize',
            'number',
            { min = 0, max = 128, integer = true },
            'Maximum Target Size',
            'Size of the targeting icon at maximum distance.',
            128
        ),
        Setting(
            'TargetMaxDistance',
            'number',
            { min = 512, max = 7128, integer = true },
            'Maximum Target Distance',
            'Distance from the locked target at which the icon will be at minimum size.',
            3564
        ),
        Setting(
            'TargetLockIcon',
            'select',
            { items = iconNames,
                l10n = ModInfo.l10nName },
            'Target Lock Icon',
            'Icon used for target locking.\nCustom icons can be added in the relative VFS dir textures/sw4/crosshair.\nFor health coloration to work, it is suggested to make all icons black/white.',
            'starburst'
        ),
        Setting(
            'TargetColorF',
            'color',
            {},
            'Full Target Color',
            'Target Icon color when the targeted actor is at 100% health',
            util.color.hex('0df8cc')
        ),
        Setting(
            'TargetColorVH',
            'color',
            {},
            'Full Target Color',
            'Target Icon color when the targeted actor is between 80-100% health',
            util.color.hex('069e00')
        ),
        Setting(
            'TargetColorH',
            'color',
            {},
            'Very Healthy Target Color',
            'Target Icon color when the targeted actor is between 60-80% health',
            util.color.hex('047a00')
        ),
        Setting(
            'TargetColorW',
            'color',
            {},
            'Healthy Target Color',
            'Target Icon color when the targeted actor is between 40-60% health',
            util.color.hex('9e7100')
        ),
        Setting(
            'TargetColorVW',
            'color',
            {},
            'Wounded Target Color',
            'Target Icon color when the targeted actor is between 20-40% health',
            util.color.hex('4c3700')
        ),
        Setting(
            'TargetColorD',
            'color',
            {},
            'Dying Target Mix Color',
            'Target Icon color when the targeted actor is at 0% health',
            util.color.hex('4c0000')
        ),
    }
}

local LockOnGroup = storage.globalSection(LockOnGroupName)
LockOnGroup:subscribe(async:callback(function(groupName, _)
    local minSize, maxSize = LockOnGroup:get('TargetMinSize'), LockOnGroup:get('TargetMaxSize')
    local minDistance, maxDistance = LockOnGroup:get('TargetMinDistance'), LockOnGroup:get('TargetMaxDistance')
    local disabled = not LockOnGroup:get('TargetLockToggle')

    I.Settings.updateRendererArgument(groupName, 'TargetMinSize', { max = (maxSize - 1), disabled = disabled, })
    I.Settings.updateRendererArgument(groupName, 'TargetMaxSize', { min = minSize + 1, disabled = disabled, })
    I.Settings.updateRendererArgument(groupName, 'TargetMinDistance', { max = (maxDistance - 1), disabled = disabled, })
    I.Settings.updateRendererArgument(groupName, 'TargetMaxDistance', { min = minDistance + 1, disabled = disabled, })

    for _, settingName in ipairs { 'TargetLockIcon', 'SwitchOnDeadTarget', 'TargetColorF', 'TargetColorVH', 'TargetColorH', 'TargetColorW', 'TargetColorVW', 'TargetColorD' } do
        if settingName == 'TargetLockIcon' then
            I.Settings.updateRendererArgument(groupName, settingName,
                { disabled = disabled, items = iconNames, l10n = ModInfo.l10nName, })
        else
            I.Settings.updateRendererArgument(groupName, settingName, { disabled = disabled })
        end
    end
end))

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'CrosshairGroup',
    page = ModInfo.name .. 'CorePage',
    order = 3,
    l10n = ModInfo.name,
    name = 'Crosshair',
    permanentStorage = true,
    settings = {
        Setting(
            'ReplaceCrosshair',
            'checkbox',
            {},
            'Replace Crosshair',
            'Whether to use SW4\'s replacement crosshair or not.\nCrosshairs are stored as an 8x8 texture atlas.',
            true
        ),
        Setting(
            'CrosshairRow',
            'number',
            { min = 0, max = 7, integer = true, },
            'Crosshair Selection Row',
            'Crosshairs are stored as an 8x8 texture atlas. This setting determines what row the used crosshair is selected from.',
            7
        ),
        Setting(
            'CrosshairColumn',
            'number',
            { min = 0, max = 7, integer = true, },
            'Crosshair Selection Column',
            'Crosshairs are stored as an 8x8 texture atlas. This setting determines what column the used crosshair is selected from.',
            7
        ),
        Setting(
            'CrosshairSize',
            'number',
            { min = 0, max = 64, integer = true },
            'Crosshair Size',
            '',
            64
        ),
        Setting(
            'CrosshairColor',
            'color',
            {},
            'Crosshair Color',
            '',
            util.color.hex('0df8cc')
        ),
    },
}

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'BlasterGroupAutomatic',
    page = ModInfo.name .. 'BlasterPage',
    order = 0,
    l10n = ModInfo.l10nName,
    name = 'Blaster Settings',
    permanentStorage = true,
    settings = {
        Setting(
            'AutomaticBlastersEnable',
            'checkbox',
            {},
            'Enable Automatic Blasters',
            'Controls whether any blasters are capable of automatic fire. Whether a given weapon will fire automatically depends on the below settings.\nAlso suspends animation cancelling.',
            true
        ),
        Setting(
            'AutomaticRepeatersEnable',
            'checkbox',
            {},
            'Automatic Repeater Blasters',
            'Make all repeater blasters capable of automatic fire',
            true
        ),
        Setting(
            'AutomaticRepeatersCancelAnimations',
            'checkbox',
            {},
            'Repeaters Cancel Recoil',
            'Make all repeater blasters cancel their recoil animations when firing',
            true
        ),
        Setting(
            'AutomaticRiflesEnable',
            'checkbox',
            {},
            'Automatic Blaster Rifles',
            'Make all blaster rifles capable of automatic fire',
            true
        ),
        Setting(
            'AutomaticRiflesCancelAnimations',
            'checkbox',
            {},
            'Rifles Cancel Recoil',
            'Make all blaster rifles cancel their recoil animations when firing',
            true
        ),
        Setting(
            'AutomaticSnipersEnable',
            'checkbox',
            {},
            'Automatic Sniper Rifles',
            'Make all sniper rifles capable of automatic fire',
            true
        ),
        Setting(
            'AutomaticSnipersCancelAnimations',
            'checkbox',
            {},
            'Snipers Cancel Recoil',
            'Make all sniper blasters cancel their recoil animations when firing',
            true
        ),
        Setting(
            'AutomaticPistolsEnable',
            'checkbox',
            {},
            'Automatic Blaster Pistols',
            'Make all blaster pistols capable of automatic fire',
            true
        ),
        Setting(
            'AutomaticPistolsCancelAnimations',
            'checkbox',
            {},
            'Pistols Cancel Recoil',
            'Make all blaster pistols cancel their recoil animations when firing',
            true
        ),
    }
}

-- Needs better default values for the cooldowns
I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'BlasterGroupSpeed',
    page = ModInfo.name .. 'BlasterPage',
    order = 1,
    l10n = ModInfo.l10nName,
    name = 'Blaster Speed Settings',
    permanentStorage = true,
    settings = {
        Setting(
            'SpeedMultRepeater',
            'number',
            { min = 0.1, max = 50.0, integer = false },
            'Repeater Speed Bonus',
            'Animation speed multiplier for repeater blasters. Default: 10.0',
            10.0
        ),
        Setting(
            'RepeaterCooldownMin',
            'number',
            { min = 0.0, max = 0.5, integer = false },
            'Repeater Minimum Shot Delay',
            'Minimum delay in seconds between shots for repeater blasters.\nBe careful setting stupid values on this one.\nDefault: 0.0003',
            0.0003
        ),
        Setting(
            'RepeaterCooldownMax',
            'number',
            { min = 0.5, max = 5.0, integer = false },
            'Repeater Maximum Shot Delay',
            'Maximum delay in seconds between shots for repeater blasters.\nBe careful setting stupid values on this one.\nDefault: 0.0003',
            LimitedPrecision(time.second / 150)
        ),
        Setting(
            'SpeedMultRifle',
            'number',
            { min = 0.1, max = 50.0, integer = false },
            'Blaster Rifle Speed Multiplier',
            'Animation speed multiplier for blaster rifles. Default: 1.5',
            1.5
        ),
        Setting(
            'RifleCooldownMin',
            'number',
            { min = 0.0, max = 0.5, integer = false },
            'Rifle Minimum Shot Delay',
            'Minimum delay in seconds between shots for repeater blasters.\nBe careful setting stupid values on this one.\nDefault: 0.0003',
            0.0003
        ),
        Setting(
            'RifleCooldownMax',
            'number',
            { min = 0.5, max = 5.0, integer = false },
            'Rifle Maximum Shot Delay',
            'Maximum delay in seconds between shots for repeater blasters.\nBe careful setting stupid values on this one.\nDefault: 0.0003',
            LimitedPrecision(time.second / 50)
        ),
        Setting(
            'SpeedMultSniper',
            'number',
            { min = 0.1, max = 50.0, integer = false },
            'Sniper Speed Multiplier',
            'Animation speed multiplier for sniper blasters. Default: 0.5',
            0.5
        ),
        Setting(
            'SniperCooldownMin',
            'number',
            { min = 0.0, max = 0.5, integer = false },
            'Sniper Minimum Shot Delay',
            'Minimum delay in seconds between shots for sniper rifles.\nBe careful setting stupid values on this one.\nDefault: 0.0003',
            0.0003
        ),
        Setting(
            'SniperCooldownMax',
            'number',
            { min = 0.5, max = 5.0, integer = false },
            'Sniper Maximum Shot Delay',
            'Maximum delay in seconds between shots for sniper rifles.\nBe careful setting stupid values on this one.\nDefault: 1',
            LimitedPrecision(time.second / 1)
        ),
        Setting(
            'SpeedMultPistol',
            'number',
            { min = 0.1, max = 50.0, integer = false },
            'Pistol Speed Multiplier',
            'Animation speed multiplier for blaster pistols. Default: 2.5',
            2.5
        ),
        Setting(
            'PistolCooldownMin',
            'number',
            { min = 0.0, max = 0.5, integer = false },
            'Pistol Minimum Shot Delay',
            'Minimum delay in seconds between shots for blaster pistols.\nBe careful setting stupid values on this one.\nDefault: 0.0003',
            LimitedPrecision(time.second / 125)
        ),
        Setting(
            'PistolCooldownMax',
            'number',
            { min = 0.5, max = 5.0, integer = false },
            'Pistol Maximum Shot Delay',
            'Maximum delay in seconds between shots for blaster pistols.\nBe careful setting stupid values on this one.\nDefault: 0.0003',
            LimitedPrecision(time.second / 75)
        ),
    }
}

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'MoveTurnGroup',
    page = ModInfo.name .. 'CameraMovementPage',
    order = 0,
    l10n = ModInfo.l10nName,
    name = 'Movement Settings',
    permanentStorage = true,
    settings = {
        Setting(
            'Enabled',
            "checkbox",
            {},
            'Enabled',
            'If set to false, disables replacement character controls.\nWARNING: Changes to this setting require a reload or restart to take effect!',
            true
        ),
        Setting(
            'TurnByWheel',
            'checkbox',
            {},
            'Turn With Mouse Wheel',
            'If enabled, can turn whilst holding the mouse wheel and moving the mouse left or right. Respects mouse sensitivity setting.',
            true
        ),
        Setting(
            'UseQuickTurn',
            'checkbox',
            {},
            'Enable quick turning',
            'Double-tap the Move Backward input to do a 180 turn.',
            true
        ),
        Setting(
            'NoThirdPerson',
            'checkbox',
            {},
            'Disallow First Person',
            '',
            true
        ),
        Setting(
            'PitchLocked',
            'checkbox',
            {},
            'Lock Camera Pitch',
            'Locks camera pitch (Y axis) when outside combat.',
            true
        ),
        Setting(
            'CursorCamPitch',
            'number',
            { min = -180, max = 180, integer = true, },
            'Cursor Camera Pitch',
            'Vertical camera angle when cursor is visible, in degrees.\nRecommended value is between 20-45, values between -180 and 180 are accepted.',
            30
        ),
        Setting(
            'MoveRampUpTimeMax',
            'number',
            { min = 0.0, max = 5.0, integer = false },
            'Forward movement ramp time',
            'Time taken to reach full speed when running/walking.',
            1.0
        ),
        Setting(
            'MoveRampUpMinSpeed',
            "number",
            { min = 0.0, max = 1.0, integer = false },
            "Forward/Back Movement Minumum Speed",
            "Minimum speed when moving forward or backwards",
            0.05
        ),
        Setting(
            'MoveRampUpMaxSpeed',
            'number',
            { min = 0.0, 1.0, integer = false },
            'Forward Maximum Movement Speed',
            'Maximum percentage of movement speed when notholding the Run action.',
            0.85
        ),
        Setting(
            'MoveBackRampUpTimeMax',
            'number',
            { min = 0.0, max = 5.0, integer = false },
            'Backward Movement Maximum Ramp Time',
            'Duration over which movement speed increases when moving backwards',
            0.75
        ),
        Setting(
            'MoveBackRampUpMinSpeed',
            'number',
            { min = -5.0, max = 0.0, integer = false },
            'Backward Movement Min Speed',
            'Starting movement speed when moving backwards.',
            -0.25
        ),
        Setting(
            'MoveBackRampUpMaxSpeed',
            'number',
            { min = -5.0, max = -0.1, integer = false },
            'Backward Movement Max Speed',
            'Full speed of backwards movement as a percenatage.',
            -0.75
        ),
        Setting(
            'MoveRampDownTimeMax',
            'number',
            { min = 0.0, max = 5.0, integer = false },
            'Backward Movement Ramp Duration',
            'Ramp-up duration for movement speed when going backwards',
            1.0
        ),
        Setting(
            'MoveSpeedPeak',
            'number',
            { min = 0.001, max = 1.0, integer = false },
            'Peak Movement Speed',
            'Maximum overall forward movement speed as a percentage. Values over 1.0 are ignored by the engine.',
            1.0
        ),
        Setting(
            'TurnRampTimeMax',
            'number',
            { min = 0.0, max = 5.0, integer = false },
            'Turning Speed Ramp Duration',
            'When turning, the turn speed increases linearly over a period of time.\nThis setting defines that period of time.\nTo disable the ramp-up completely, set it to 0.0, or set the speeds to equal values.',
            1.0
        ),
        Setting(
            'TurnDegreesPerSecondMax',
            'number',
            { min = 1, max = 360, integer = true },
            'Maximum Turn Speed',
            'Max turn speed in degrees',
            180
        ),
        Setting(
            'TurnDegreesPerSecondMin',
            'number',
            { min = 1, max = 360, integer = true },
            'Minimum Turn Speed',
            'Minimum turn speed in degrees per second.',
            90
        ),
        Setting(
            'SideMovementMaxSpeed',
            'number',
            { min = 0.001, max = 1.0, integer = false },
            'Side Movement Max Speed',
            'Maximum speed when moving sideways, as a percentage.',
            0.75
        ),
        Setting(
            'QuickTurnMult',
            'number',
            { min = 1, max = 60, integer = true, },
            'Quick Turn Speed Multiplier',
            'Multiplier for turn speed when using quick turn. When set to 1, it will take a full second to turn all the way around.\nSet to 5, it will take 1/5th of a second, etc.',
            5
        ),
        Setting(
            'QuickTurnTimeWindow',
            'number',
            { min = 0.01, max = 1.0, },
            'Quick Turn Time Window',
            'Duration of time allowed between presses to engage a quick turn.',
            0.2
        ),
    }
}

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'CursorGroup',
    page = ModInfo.name .. 'CursorPage',
    order = 0,
    l10n = ModInfo.l10nName,
    name = 'Cursor Settings',
    permanentStorage = true,
    settings = {
        Setting(
            'IconName',
            'select',
            { items = cursorIconNames, l10n = ModInfo.l10nName },
            'Cursor Icon',
            '',
            'starburst'
        ),
        Setting(
            'StartFromCenter',
            'checkbox',
            {},
            'Reset Cursor Position',
            'If this setting is enabled, the cursor will always reset back to the center point when it is no longger visible.',
            false
        ),
        Setting(
            'ShowBanner',
            'checkbox',
            {},
            'Show Selection Banner',
            'When an object is highlighted by the SW4 cursor, its name (or destination, if it\'s a teleport door) will appear on screen.\nSet this to false, to hide that window entirely.',
            true
        ),
        Setting(
            'Sensitivity',
            'number',
            { min = 0.001, max = 10.0, integer = false, },
            'Cursor Sensitivity',
            '',
            1.0
        ),
        Setting(
            'TargetFlickThreshold',
            'number',
            { min = 50, max = 500, integer = true, },
            'Target Switch Flick Threshold',
            'Length of continuous mouse movement required to change locked targets.\nDoes not reset until mouse movement stops.',
            50
        ),
        Setting(
            'CursorSize',
            'number',
            { min = 8, max = 64, integer = true },
            'Cursor Size',
            '',
            32
        ),
        Setting(
            'XAnchor',
            'number',
            { min = 0.0, max = 1.0, integer = false },
            'X Axis Anchor',
            'Center point for the crosshair image on the X axis.\n0 is all the way to the left, while 1 is all the way to the right.',
            0.5
        ),
        Setting(
            'YAnchor',
            'number',
            { min = 0.0, max = 1.0, integer = false },
            'Y Axis Anchor',
            'Center point for the crosshair image on the Y axis.\n0 is all the way at the top, while 1 is all the way at the bottom.',
            0.5
        ),
        Setting(
            'BannerFontSize',
            'number',
            { min = 8, max = 40, integer = true },
            'Banner Font Size',
            'Font size of area/object names',
            24
        ),
        Setting(
            'DefaultColor',
            'color',
            {},
            'Default Color',
            'Cursor color when there is no highlighted object or it is non-interactive',
            util.color.hex('034a3d')
        ),
        Setting(
            'FriendlyActorColor',
            'color',
            {},
            'Friendly Color',
            'Cursor color for friendly actors',
            util.color.hex('0df8cc')
        ),
        -- This should probably be changed to explicitly being for enemies
        Setting(
            'FightingActorColor',
            'color',
            {},
            'Hostile Color',
            'Cursor color for actors in combat',
            util.color.hex('f80d39')
        ),
        Setting(
            'ServiceActorColor',
            'color',
            {},
            'Service/Vendor Cursor Color',
            'Cursor color for vendors/servicepeople',
            util.color.hex('f8cc0d')
        ),
        Setting(
            'LockedColor',
            'color',
            {},
            'Locked Cursor Color',
            'Cursor color for locked objects',
            util.color.hex('166305')
        ),
        Setting(
            'TeleportDoorColor',
            'color',
            {},
            'Teleport Door Cursor Color',
            'Cursor color for teleport doors.',
            util.color.hex('cc0df8')
        ),
    }
}
