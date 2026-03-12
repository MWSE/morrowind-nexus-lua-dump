local I = require('openmw.interfaces')
local util = require("openmw.util")
local vfs = require("openmw.vfs")
local storage = require("openmw.storage")

local FileSelectInstances = {}

local FileSelect = {}
FileSelect.__index = FileSelect

function FileSelect:new(params)
    local instance = setmetatable({}, self)
    instance.key = params.key
    instance.description = params.description
    instance.folderPath = params.folderPath
    instance.withGroupingSuffix = params.withGroupingSuffix
    instance.settingsGroup = params.settingsGroup
    instance.cleanNames = {}
    instance.files = {}

    for filePath in vfs.pathsWithPrefix(instance.folderPath) do
        local fileName = filePath:match("([^/\\]+)$")
        local baseName = fileName:match("^(.-)%.") or fileName -- Remove file extension
        local cleanName, suffix = baseName, nil
        if instance.withGroupingSuffix then
            cleanName = baseName:match("^(.*)_") or baseName -- Match up to the last "_"
            suffix = baseName:sub(#cleanName + 2) -- +2 accounts for the underscore            
        end
        
        instance.cleanNames[cleanName] = true
        table.insert(instance.files, { cleanName = cleanName, fullPath = filePath, suffix = suffix })
    end

    FileSelectInstances[instance.key] = instance

    local items = {}    
    for cleanName, bool in pairs(instance.cleanNames) do
        table.insert(items, cleanName)
    end

    local default = params.default and instance.cleanNames[params.default] and params.default or items[1]

    return {
        key = instance.key,
        renderer = 'select',
        default = default,
        argument = {
            l10n = 'DynamicReticle',
            items = items,
        },
        name = instance.key,
        description = instance.description,
    }
end

function FileSelect:getFilePath(suffix)
    if not self.settings then
        self.settings = storage.playerSection(self.settingsGroup)
    end    
    local cleanName = self.settings:get(self.key)
    for _, file in ipairs(self.files) do
        if file.cleanName == cleanName and file.suffix == suffix then            
            return file.fullPath
        end
    end
    return nil
end


I.Settings.registerPage {
    key = 'DynamicReticlePage',
    l10n = 'DynamicReticle',
    name = 'Dynamic Reticle and Hit Markers',
    description = "~~ Animated reticle, hit markers and enemy hp widget. IMPORTANT: Some of the settings below are not reflected in-game unless you run a 'reloadlua' command in console (~ console) or restart the game",
}

I.Settings.registerGroup {
    key = 'DynamicReticleVisualSettings',
    page = 'DynamicReticlePage',
    l10n = 'DynamicReticle',
    name = 'Visuals',
    order = 1,
    permanentStorage = true,    
    settings = {
        FileSelect:new {
            key = 'Reticle',
            description = "Any image found in 'textures/dynamic reticle/reticles/' will be selectable here.",
            folderPath = "textures/dynamic reticle/reticles/",
            withGroupingSuffix = false,
            default = "angle_brackets",
            settingsGroup = 'DynamicReticleVisualSettings',
        },
        FileSelect:new {
            key = 'StealthArrows',
            description = "Any image found in 'textures/dynamic reticle/stealth/' will be selectable here.",
            folderPath = "textures/dynamic reticle/stealth/",
            withGroupingSuffix = true,
            settingsGroup = 'DynamicReticleVisualSettings',
        },
        {
            key = 'ReticleColor',
            renderer = 'color',
            default = util.color.hex("caa676"),            
            name = 'Reticle Color'
        },
        {
            key = 'ReticleOpacity',
            renderer = "number",
            default = 0.75,
            argument = {
                min = 0,
                max = 1
            },
            name = "Reticle Opacity"
        },
        {
            key = 'StowedReticleAlpha',
            renderer = "number",
            default = 0.3,
            argument = {
                min = 0,
                max = 1
            },
            name = "Stowed Reticle Opacity",
            description = "Change reticle transparency to this value (0-1 range) when a weapon or spell is readied."
        },
        {
            key = 'MissedReticleAlpha',
            renderer = "number",
            default = 0.3,
            argument = {
                min = 0,
                max = 1
            },
            name = "Missed Reticle Opacity",
            description = "Temporarily fades-out to this opacity level (0-1 range) when your attack misses."
        },
        {
            key = 'ReticleScale',
            renderer = "number",
            default = 0.75,
            argument = {
                min = 0,
                max = 10
            },
            name = "Reticle Size Multiplier"
        },
        {
            key = 'ReticleSneakScale',
            renderer = "number",
            default = 0.66,
            argument = {
                min = 0.1,
                max = 1
            },
            name = "Reticle Sneak Scale",
            description = "Adjust the size multiplier for the reticle when sneaking."
        },
        FileSelect:new {
            key = 'HitMarker',
            description = "Any image found in 'textures/dynamic reticle/hitmarkers/' will be selectable here.",
            folderPath = "textures/dynamic reticle/hitmarkers/",
            withGroupingSuffix = true,
            settingsGroup = 'DynamicReticleVisualSettings',
        },
        {
            key = 'HitMarkerColor',
            renderer = 'color',
            default = util.color.hex("edcc9f"),            
            name = 'Hit Marker Color'
        },
        {
            key = 'HitMarkerOpacity',
            renderer = "number",
            default = 1,
            argument = {
                min = 0,
                max = 1
            },
            name = "Hit Marker Opacity"
        },        
        {
            key = 'WeakHitMarkerOpacity',
            renderer = "number",
            default = 0,
            argument = {
                min = 0,
                max = 1
            },
            name = "Weak Hit Marker Opacity",
            description = "Weak hitmarkers are only used by CHIM2090 combat mod"
        },
        {
            key = "HitMarkerScale",
            renderer = "number",
            default = 0.75,
            argument = {
                min = 0,
                max = 10
            },
            name = "Hit Marker Size Multiplier"
        },
        {
            key = 'KillMarkerColor',
            renderer = 'color',
            default = util.color.hex("e82532"),
            name = 'Kill Marker Color'
        },        
        {
            key = 'SlowdownOnKillChance',
            renderer = 'number',
            default = 0.25,
            argument = {
                min = 0,
                max = 1
            },
            name = 'Slowdown On Kill Chance',
            description = 'A Chance that a slowdown effect will happen on kill. 0-1 range.'
        },
        {
            key = 'SlowdownOnKillDuration',
            renderer = 'number',
            default = 1,
            argument = {
                min = 0,
                max = 1000
            },
            name = 'Slowdown On Kill Duration',
            description = 'An overall slowdown duration multiplier.'
        },
        {
            key = 'ShowHpWidget',
            renderer = 'checkbox',
            default = true,
            name = 'Show Enemy HP Widget',
            description = "Displays a subtle enemy hp widget under the reticle in combat."
        },
        {
            key = 'HpWidgetColor',
            renderer = 'color',
            default = util.color.rgb(0.792, 0.651, 0.463),
            name = 'Hp Widget Color'
        },
        {
            key = 'HpWidgetOpacity',
            renderer = "number",
            default = 1,
            argument = {
                min = 0,
                max = 1
            },
            name = "Hp Widget Opacity"
        },
        {
            key = 'HpWidgetDamageColor',
            renderer = 'color',            
            default = util.color.hex("590211"),
            name = 'Hp Widget Damage Color'
        },
        {
            key = "HpWidgetScale",
            renderer = "number",
            default = 1.1,
            argument = {
                min = 0.1,
                max = 10
            },
            name = "Hp Widget Size Multiplier"
        }
    },
}

I.Settings.registerGroup {
    key = 'DynamicReticleSoundSettings',
    page = 'DynamicReticlePage',
    l10n = 'DynamicReticle',
    name = 'Sound',
    description = 'A bit of oomph',
    permanentStorage = true,
    order = 2,
    settings = {
        FileSelect:new {
            key = 'HitMarkerSound',
            description = "Any sound found in 'sounds/dynamic reticle/hitmarkers/' will be selectable here.",
            folderPath = "sounds/dynamic reticle/hitmarkers/",
            withGroupingSuffix = false,
            settingsGroup = 'DynamicReticleSoundSettings',
            default = "fps_meaty_hit",
        },
        FileSelect:new {
            key = 'DeathMarkerSound',
            description = "Any sound found in 'sounds/dynamic reticle/hitmarkers/' will be selectable here.",
            folderPath = "sounds/dynamic reticle/hitmarkers/",
            withGroupingSuffix = false,
            settingsGroup = 'DynamicReticleSoundSettings',
            default = "bass_stab",
        },
        {
            key = "HitMarkerVolume",
            renderer = "number",
            default = 2,
            argument = {
                min = 0,
                max = 10
            },
            name = "Hit Marker Sound Volume"
        },
        {
            key = "DeathMarkerVolume",
            renderer = "number",
            default = 2,
            argument = {
                min = 0,
                max = 10
            },
            name = "Death Marker Sound Volume"
        },
        {
            key = "MarkerSoundPitchMin",
            renderer = "number",
            default = 0.8,
            argument = {
                min = 0.1,
                max = 10
            },
            name = "Min Sound Pitch",
            description = "Minimum value of a randomised pitch. 1.0 = no pitch change. Affects both hit and kill marker sounds."
        },
        {
            key = "MarkerSoundPitchMax",
            renderer = "number",
            default = 1.2,
            argument = {
                min = 0,
                max = 10
            },
            name = "Max Sound Pitch",
            description = "Maximum value of a randomised pitch. 1.0 = no pitch change. Affects both hit and kill marker sounds."
        },
        {
            key = 'MeleeSound',
            renderer = 'checkbox',
            default = true,
            name = 'Play hit sound with Melee weapons'
        },
        {
            key = 'MarksmanSound',
            renderer = 'checkbox',
            default = true,
            name = 'Play hit sound with Marksman weapons'
        },
        {
            key = 'SpellcasterSound',
            renderer = 'checkbox',
            default = true,
            name = 'Play hit sound with spell casting'
        }
    },
}



return {
    fileSelectors = FileSelectInstances,
}
