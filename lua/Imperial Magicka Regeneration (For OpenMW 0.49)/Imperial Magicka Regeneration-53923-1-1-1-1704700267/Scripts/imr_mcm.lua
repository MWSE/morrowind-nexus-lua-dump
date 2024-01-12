local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local async = require('openmw.async')

I.Settings.registerPage {
    key = "NMRSettingsMain",
    l10n = "NMRSettingsMain",
    name = "Imperial Magicka Regen",
    description = "These settings allow you to modify the behavior of Imperial Magicka Recovery."
}

I.Settings.registerPage {
    key = "NMRSettingsGuilds",
    l10n = "NMRSettingsGuilds",
    name = "Imperial Magicka Regen: Guilds",
    description = "When enabled, some guilds ranks will provide certain bonuses to Magicka regeneration."
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
            name = "Modification is enabled",
            description =
            "Uncheck to disable Imperial Magicka Recovery and its features.",
            default = true
        },
        {
            key = 'NMRbaseRegenTime',
            name = 'Base Regen Time',
            description = 'Specifies how fast Magicka regenerates (in seconds) to 100% when Intelligence is 1.',
            default = 200,
            renderer = 'number',
            argument = {
                min = 10,
                max = 1000,
                integer = true,
            },
        },
        {
            key = 'NMRfastRegenTime',
            name = 'Min Regen Time',
            description = 'Specifies how fast Magicka regenerates (in seconds) to 100% when Intelligence is 100. (100 Intelligence is the hard cap for this mod)',
            default = 140,
            renderer = 'number',
            argument = {
                min = 5,
                max = 1000,
                integer = true,
            },
        },
        {
            key = 'NMRMaxRegenPercentage',
            name = 'Max Regen Percentage',
            description = 'Sets the maximum percentage of Magicka regeneration allowed (0-100).\n\nDefault is 20 for a balanced experience with potions and scrolls. Advancing through Mages Guild ranks can grant up to +30%, and certain artifacts can further enhance this by up to 15%. (but not higher than 100%).',
            default = 20,
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
            key = "NMRFortifyMagicka",
            renderer = "checkbox",
            name = "Fortify Magicka effect",
            description =
            " If checked, the Fortify Magicka effect will be treated as your maximum Magicka for the purpose of regeneration.",
            default = false
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
        {
            key = "NMRAtronachSign",
            renderer = "checkbox",
            name = "Atronach sign",
            description =
            "If checked, the Atronach Sign will prevent Magicka regeneration.",
            default = true
        },
        {
            key = 'NMRAtronachMultiplier',
            name = 'Atronach sign multiplier',
            description = 'Magicka regeneration speed multiplier for the Atronach Sign.',
            default = 0.3, 
            renderer = 'select',
            argument = {
                disabled = false,
                l10n = 'LocalizationContext', 
                items = {0.1, 0.2, 0.3, 0.4, 0.5},
            },
        },
        {
            key = 'NMRrestHandler',
            name = 'Regenerate while Waiting/Resting',
            renderer = 'checkbox',
            description = 'If enabled, IMR will handle waiting and resting, suppressing vanilla resting regeneration. Should be working properly but disable if issues arise. Note: Atronach sign limits magicka regen during rest to Max Regen Percentage.',
            default = true
        },
    },
})

I.Settings.registerGroup({
    key = 'NMRSettingsGuildsPage', 
    page = 'NMRSettingsGuilds',
    l10n = 'NMRSettingsGuildsMain',
    name = 'Guilds bonuses',
    permanentStorage = true,
    settings = {
        {
            key = "NMRGuildsMages",
            renderer = "checkbox",
            name = "Mages Guild",
            description =
            "\nAdvancing in the Mages Guild ranks will increase the maximum % your Magicka can regenerate. Not applicable if Max Regen Percentage setting is 100%.\n\nApprentice: +2% to total Magicka that can be regenerated.\n.\n.\n.\nArch-Mage: +30% to total Magicka that can be regenerated.",
            default = true
        },
        {
            key = "NMRGuildsTelvanni",
            renderer = "checkbox",
            name = "House Telvanni",
            description =
            "\nAdvancing in the House Telvanni ranks will increase your Magicka regeneration speed.\n\nRetainer: +2% to your Magicka regeneration speed.\n.\n.\n.\nArchmagister: +20% to your Magicka regeneration speed.",
            default = true
        },
        {
            key = "NMRGuildsTemple",
            renderer = "checkbox",
            name = "Tribunal Temple",
            description =
            "\nAdvancing in the Tribunal Temple ranks will lessen the impact of fatigue penalties. Not applicable if Fatigue multiplier setting is disabled.\n\nNovice: 2% weaker penalty (with 0 Fatigue your Magicka regen speed multiplier will be 0.52 instead of 0.5).\n.\n.\n.\nPatriarch: 20% weaker penalty (with 0 Fatigue your Magicka regen speed multiplier will be 0.7 instead of 0.5).",
            default = true
        },
        {
            key = "NMRGuildsImperialCult",
            renderer = "checkbox",
            name = "Imperial Cult",
            description =
            "\nJoining the Imperial Cult gives you the Divine Resilience ability, boosting your Magicka regeneration speed when Health drops below 30%.\n\nNovice: 150% Magicka regeneration speed boost for 10 seconds.\n.\n.\n.\nPrimate: 400% Magicka regeneration speed boost for 10 seconds.",
            default = true
        },
        {
            key = "NMRGuildsSounds",
            renderer = "checkbox",
            name = "Notifications sounds",
            description =
            "\nTurn off to disable custom sounds for rank promotions in the guilds above.",
            default = true
        },
    },
})


local settings = {
    main = storage.playerSection('NMRSettingsA'),
    additions = storage.playerSection('NMRSettingsB'),
    guilds = storage.playerSection('NMRSettingsGuildsPage'),
}



local atronachMultiplier = 1
local mcmInitializerDelay = 0
local timeToUpdateSettings = 0



local function updateTempleGuildIfFatigue()
    local disabled = not settings.additions:get('NMRFatigueMult')
    I.Settings.updateRendererArgument('NMRSettingsGuildsPage', 'NMRGuildsTemple', {disabled = disabled})

end

local function updateAtronachSign()
    local disabled = settings.additions:get('NMRAtronachSign')
    I.Settings.updateRendererArgument('NMRSettingsB', 'NMRAtronachMultiplier', {disabled = disabled, l10n = 'randomValue', items = {0.1, 0.2, 0.3, 0.4, 0.5}})

end

local function updateAtronachSignMult()
    if settings.additions:get('NMRAtronachMultiplier') and not settings.additions:get('NMRAtronachSign') then
        atronachMultiplier = settings.additions:get('NMRAtronachMultiplier')
        --print(atronachMultiplier)
    elseif settings.additions:get('NMRAtronachSign') then
        atronachMultiplier = 1
        --print(atronachMultiplier)
    end
end

local function disableModification()
    local disabled = not settings.main:get('NMRisActive')
    I.Settings.updateRendererArgument('NMRSettingsA', 'NMRbaseRegenTime', {disabled = disabled})
    I.Settings.updateRendererArgument('NMRSettingsA', 'NMRfastRegenTime', {disabled = disabled})
    I.Settings.updateRendererArgument('NMRSettingsA', 'NMRMaxRegenPercentage', {disabled = disabled})

    
    
end

updateAtronachSignMult()
updateTempleGuildIfFatigue()
updateAtronachSign()
disableModification()

settings.additions:subscribe(async:callback(updateTempleGuildIfFatigue))
settings.additions:subscribe(async:callback(updateAtronachSign))
settings.additions:subscribe(async:callback(updateAtronachSignMult))
settings.main:subscribe(async:callback(disableModification))

local function onFrame(dt)

    -- Equipped artifacts initialization on the first frame of onFrame
    if mcmInitializerDelay < 1 then

        mxRegenTimeLastCheck = settings.main:get('NMRbaseRegenTime')
        mnRegenTimeLastCheck = settings.main:get('NMRfastRegenTime')        
        mcmInitializerDelay = mcmInitializerDelay + 1
        return
    end
    if I.UI.getMode() == 'SettingsMenu' then
        timeToUpdateSettings = timeToUpdateSettings + 1
    end

    if timeToUpdateSettings > 40 and I.UI.getMode() == 'SettingsMenu' then
        mxRegenTime = settings.main:get('NMRbaseRegenTime')
        mnRegenTime = settings.main:get('NMRfastRegenTime')
        if mxRegenTime ~= nil and mnRegenTime ~= nil then
        if mnRegenTime > mxRegenTime and mxRegenTimeLastCheck ~= mxRegenTime then
            settings.main:set('NMRbaseRegenTime', mnRegenTime)
            elseif mnRegenTime > mxRegenTime and mnRegenTimeLastCheck ~= mnRegenTime then
            settings.main:set('NMRfastRegenTime', mxRegenTime)
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
