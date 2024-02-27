local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local async = require('openmw.async')

I.Settings.registerPage {
    key = "SMESettingsBehavior",
    l10n = "SMESettingsBehavior",
    name = "Show Me Everything: Actor UI",
    description = "Behavior settings for the widget."
}

I.Settings.registerPage {
    key = "SMESettingsStyle",
    l10n = "SMESettingsStyle",
    name = "Show Me Everything: Visual",
    description = "Style settings for the widget."
}

I.Settings.registerPage {
    key = "SMEhitChance",
    l10n = "SMEhitChance",
    name = "Show Me Everything: Hit Chance",
    description = "Hit chance widget. Base of the code and idea by Safeicus Boxius."
}

I.Settings.registerGroup({
    key = 'SMESettingsBh', 
    page = 'SMESettingsBehavior',
    l10n = 'SMESettingsBehavior',
    name = 'Behavior',
    permanentStorage = true,
    settings = {
        {
            key = "SMEisActive",
            renderer = "checkbox",
            name = "Modification is enabled",
            description =
            "Uncheck to disable Show Me Everything widget. This setting controls whether the modification is active or not.",
            default = true
        },
        {
            key = "SMEClass",
            renderer = "checkbox",
            name = "Show NPC class",
            description =
            "If enabled, the widget will show the class of the NPC.",
            default = true
        },
        {
            key = 'SMELevel',
            renderer = "checkbox",
            name = "Show NPC level",
            description =
            "If enabled, the widget will show the level of the NPC.",
            default = true
        },
        {
            key = 'SMEHealth',
            renderer = "checkbox",
            name = "Show NPC health values",
            description =
            "If enabled, the widget will show the health values of the NPC.",
            default = true
        },
        {
            key = 'SMEDamage',
            renderer = "checkbox",
            name = "Show damage widget",
            description =
            "If enabled, every time you attack an NPC, damage values will be shown.",
            default = true
        },
        {
            key = 'SMERaycastLength',
            name = 'Raycast length',
            description = 'Controls the length of the Raycast. Higher values will let you pick farther targets but may cost you some performance. Default is 3000, values are from 1000 to 6000.',
            default = 3000,
            renderer = 'number',
            argument = {
                min = 1000,
                max = 6000,
                integer = true,
            },
        },
        {
            key = 'SMEShowDistance',
            name = 'Widget display distance',
            description = 'Controls the distance at which the widget will be displayed when looking at actors. Set to 192 for a display range similar to the vanilla game on activation. Values are from 192 to 1000.',
            default = 500,
            renderer = 'number',
            argument = {
                min = 192,
                max = 1000,
                integer = true,
            },
        },
        {
            key = 'SMEStance',
            renderer = "checkbox",
            name = "Only show in combat stance",
            description =
            "If enabled, the widget logic will be working in the background, but the widget will only be shown when you are in a combat stance or someone in the focus is taking damage.",
            default = false
        },
        {
            key = 'SMEonHit',
            renderer = "checkbox",
            name = "Only show on damage",
            description =
            "If enabled, the widget will only be shown when you hit an actor and deal damage to them. Overrides the previous setting",
            default = false
        },
        {
            key = 'SMEnotForDead',
            renderer = "checkbox",
            name = "Show the widget for dead actors",
            description =
            "If disabled, all dead actors will be ignored and widget will be shown only for alive (or undead) ones.",
            default = true
        },
    },
})

I.Settings.registerGroup({
    key = 'SMESettingsSt', 
    page = 'SMESettingsStyle',
    l10n = 'SMESettingsStyle',
    name = 'Visuals',
    permanentStorage = true,
    settings = {
        {
            key = 'SMEWidgetStyle',
            name = 'Visual preset for the widget',
            description = 'Here you can choose one of two presets for the widget.',
            default = 'Vanilla', 
            renderer = 'select',
            argument = {
                disabled = false,
                l10n = 'LocalizationContext', 
                items = {'Vanilla', 'Skyrim', 'Sky Nostalgy', 'Flat', 'Minimal Vanilla', 'Sixth House'},
            },
        },
    },
})

I.Settings.registerGroup({
    key = 'SMEHitChanceSettings', 
    page = 'SMEhitChance',
    l10n = 'SMEhitChance',
    name = 'Hit Chance widget settings.',
    permanentStorage = true,
    settings = {
        {
            key = "hitChanceIsActive",
            renderer = "checkbox",
            name = "Hit Chance indicator switch",
            description =
            "Uncheck to disable Hit Chance indicator. This setting controls whether the indicator will be shown or not.",
            default = true
        },
        {
            key = 'SMEhitChanceWidget',
            name = 'Visual preset for the Hit Chance widget',
            description = 'Here you can choose one of several presets for the widget.',
            default = 'Percent',
            renderer = 'select',
            argument = {
                disabled = false,
                l10n = 'LocalizationContext', 
                items = {'Percent', 'Circle', 'Scale'},
            },
        },
        {
            key = "SMEhitChanceReticle",
            renderer = "checkbox",
            name = "Hit Chance colored reticle",
            description =
            "If enabled, the reticle will be colored accordingly to the hit chance.",
            default = false
        },
    },
})


local settings = {
    behavior = storage.playerSection('SMESettingsBh'),
    style = storage.playerSection('SMESettingsSt'),
    hitChance = storage.playerSection('SMEHitChanceSettings'),
}

local stanceIsEnabled = false
local onHitIsEnabled = false

local function disableModification()
    local disabled = not settings.behavior:get('SMEisActive')
    I.Settings.updateRendererArgument('SMESettingsBh', 'SMEClass', {disabled = disabled})
    I.Settings.updateRendererArgument('SMESettingsBh', 'SMELevel', {disabled = disabled})
    I.Settings.updateRendererArgument('SMESettingsBh', 'SMEHealth', {disabled = disabled})
    I.Settings.updateRendererArgument('SMESettingsBh', 'SMEDamage', {disabled = disabled})
    I.Settings.updateRendererArgument('SMESettingsBh', 'SMEStance', {disabled = disabled})
    I.Settings.updateRendererArgument('SMESettingsBh', 'SMEonHit', {disabled = disabled})
    I.Settings.updateRendererArgument('SMESettingsBh', 'SMEnotForDead', {disabled = disabled})
    I.Settings.updateRendererArgument('SMESettingsBh', 'SMERaycastLength', {disabled = disabled})
    I.Settings.updateRendererArgument('SMESettingsBh', 'SMEShowDistance', {disabled = disabled})
    I.Settings.updateRendererArgument('SMESettingsSt', 'SMEWidgetStyle', {disabled = disabled, l10n = 'randomValue', items = {'Vanilla', 'Skyrim', 'Sky Nostalgy', 'Flat', 'Minimal Vanilla', 'Sixth House'}})
    
    
end

local function disableHitChance()
    local disabled = not settings.hitChance:get('hitChanceIsActive')
    I.Settings.updateRendererArgument('SMEHitChanceSettings', 'SMEhitChanceReticle', {disabled = disabled})
    I.Settings.updateRendererArgument('SMEHitChanceSettings', 'SMEhitChanceWidget', {disabled = disabled, l10n = 'randomValue', items = {'Percent', 'Circle', 'Scale'}})
    
    
end


disableModification()
disableHitChance()


settings.behavior:subscribe(async:callback(disableModification))
settings.hitChance:subscribe(async:callback(disableHitChance))


local mxRaycastLengthLastCheck = 0
local mxRaycastLengthThisCheck = 0
local raycastLength = 0
local timeToUpdateSettings = 0
local activateLength = 0
local onHitThisFrame
local onHitLastFrame
local onStanceThisFrame
local onStanceLastFrame


local function onFrame(dt)

    if I.UI.getMode() == 'SettingsMenu' then
        timeToUpdateSettings = timeToUpdateSettings + 1
    end

    if timeToUpdateSettings > 20 and I.UI.getMode() == 'SettingsMenu' then
        
        raycastLength = settings.behavior:get('SMERaycastLength')
        activateLength = settings.behavior:get('SMEShowDistance')

        if settings.behavior:get('SMERaycastLength') and raycastLength > 6000 then
            settings.behavior:set('SMERaycastLength', 6000)
        elseif settings.behavior:get('SMERaycastLength') and raycastLength < 1000 then
            settings.behavior:set('SMERaycastLength', 1000)
        end

        if settings.behavior:get('SMEShowDistance') and activateLength > 1000 then
            settings.behavior:set('SMEShowDistance', 1000)
        elseif settings.behavior:get('SMEShowDistance') and activateLength < 192 then
            settings.behavior:set('SMEShowDistance', 192)
        end
        onStanceThisFrame = settings.behavior:get('SMEStance')

        if settings.behavior:get('SMEonHit') and onStanceThisFrame == onStanceLastFrame and settings.behavior:get('SMEStance') then
            print(settings.behavior:get('SMEonHit'), settings.behavior:get('SMEStance'), onStanceThisFrame, onStanceLastFrame)
            settings.behavior:set('SMEStance', false)
            
        elseif settings.behavior:get('SMEonHit') and settings.behavior:get('SMEStance') then
            print(settings.behavior:get('SMEonHit'), settings.behavior:get('SMEStance'), onStanceThisFrame, onStanceLastFrame)
            settings.behavior:set('SMEonHit', false)
        end
        onStanceLastFrame = onStanceThisFrame
        timeToUpdateSettings = 0
    end

end

return {
    engineHandlers = {
        dt = dt,
        onUpdate = onUpdate,
        onFrame = onFrame,
        onLoad = onLoad,
    },
}
