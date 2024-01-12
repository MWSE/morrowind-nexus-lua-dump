local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local core = require('openmw.core')

I.Settings.registerPage {
    key = "NMRSettingsMain",
    l10n = "NMRSettingsMain",
    name = "Natural Magicka Recovery",
    description = "These settings allow you to modify the behavior of Natural Magicka Recovery."
}

I.Settings.registerGroup({
    key = 'NMRSettingsA', 
    page = 'NMRSettingsMain',
    l10n = 'NMRSettingsMain',
    name = 'Base Settings',
    permanentStorage = true,
    settings = {
        {
            key = "NMRisActive",
            renderer = "checkbox",
            name = "Recovery is enabled",
            description =
            "Uncheck to disable Natural Magicka Recovery and its features.",
            default = true
        },
        {
            key = 'NMRbaseRegenTime',
            name = 'Base Regen Time',
            description = 'Specifies how fast Magicka regenerates (in seconds) to 100% when Intelligence is 1.',
            default = 200,
            renderer = 'number',
            argument = {
                min = 1,
                max = 1000,
                integer = true,
            },
        },
        {
            key = 'NMRfastRegenTime',
            name = 'Min Regen Time',
            description = 'Specifies how fast Magicka regenerates (in seconds) to 100% when Intelligence is 100. (100 Intelligence is the hard cap for this mod)',
            default = 120,
            renderer = 'number',
            argument = {
                min = 1,
                max = 1000,
                integer = true,
            },
        },
        {
            key = 'NMRMaxRegenPercentage',
            name = 'Max Regen Percentage',
            description = 'Sets the maximum percentage of Magicka regeneration allowed (0-100).',
            default = 100,
            renderer = 'number',
            argument = {
                min = 0,
                max = 100,
                integer = true,
            },
        },
    },
})

I.Settings.registerGroup({
    key = 'NMRSettingsB', 
    page = 'NMRSettingsMain',
    l10n = 'NMRSettingsMain',
    name = 'Additions',
    permanentStorage = true,
    settings = {
        {
            key = "NMRIntRegen",
            renderer = "checkbox",
            name = "Intelligence-powered",
            description =
            "If checked, Intelligence will control Magicka regeneration. If unchecked, it will be controlled by Willpower.",
            default = true
        },
        {
            key = "NMRFatigueMult",
            renderer = "checkbox",
            name = "Fatigue multiplier",
            description =
            "If checked, Fatigue will influence Magicka regeneration, up to a modifier of 0.5 at zero Fatigue. Effectively limits your ability to spam spells while running or in combat.",
            default = true
        },
        {
            key = "NMRArtMultiplier",
            renderer = "checkbox",
            name = "Artifacts bonuses",
            description =
            "If enabled, specific artifacts and unique items will provide additional bonuses to Magicka regeneration.",
            default = true
        },
    },
})



local settings = {
    base = storage.playerSection('NMRSettingsA'),
    addons = storage.playerSection('NMRSettingsB'),
}

--variables
local atronachMultiplier = 1
local mcmInitializerDelay = 0
local timeToUpdateSettings = 40
local timeToUpdateTimer = 0

local function disableModification()
    local disabled = not settings.base:get('NMRisActive')
    I.Settings.updateRendererArgument('NMRSettingsA', 'NMRbaseRegenTime', {disabled = disabled})
    I.Settings.updateRendererArgument('NMRSettingsA', 'NMRfastRegenTime', {disabled = disabled})
    I.Settings.updateRendererArgument('NMRSettingsA', 'NMRMaxRegenPercentage', {disabled = disabled})

    I.Settings.updateRendererArgument('NMRSettingsB', 'NMRIntRegen', {disabled = disabled})
    I.Settings.updateRendererArgument('NMRSettingsB', 'NMRFatigueMult', {disabled = disabled})
    I.Settings.updateRendererArgument('NMRSettingsB', 'NMRArtMultiplier', {disabled = disabled})
    
end

disableModification()

settings.base:subscribe(async:callback(disableModification))

local function onFrame(dt)

    -- Equipped artifacts initialization on the first frame of onFrame
    if mcmInitializerDelay < 1 then

        mxRegenTimeLastCheck = settings.base:get('NMRbaseRegenTime')
        mnRegenTimeLastCheck = settings.base:get('NMRfastRegenTime')        
        mcmInitializerDelay = mcmInitializerDelay + 1
        return
    end
    if core.isWorldPaused() then
        timeToUpdateTimer = timeToUpdateTimer + 1
    end

    if timeToUpdateTimer > timeToUpdateSettings and core.isWorldPaused() then
        mxRegenTime = settings.base:get('NMRbaseRegenTime')
        mnRegenTime = settings.base:get('NMRfastRegenTime')
        if mxRegenTime ~= nil and mnRegenTime ~= nil then
        if mnRegenTime > mxRegenTime and mxRegenTimeLastCheck ~= mxRegenTime then
            settings.base:set('NMRbaseRegenTime', mnRegenTime)
            elseif mnRegenTime > mxRegenTime and mnRegenTimeLastCheck ~= mnRegenTime then
            settings.base:set('NMRfastRegenTime', mxRegenTime)
        end
        mxRegenTimeLastCheck = mxRegenTime
        mnRegenTimeLastCheck = mnRegenTime
        timeToUpdateSettings = 0
        end
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