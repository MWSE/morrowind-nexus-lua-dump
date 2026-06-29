local async = require('openmw.async')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local cfg = require('scripts.cmc.config')

local M = {}
local initialized = false

local pageKey = 'CreatureMercyContagion'
local generalKey = 'Settings/CreatureMercyContagion/1_General'
local rewardsKey = 'Settings/CreatureMercyContagion/2_Rewards'
local behaviourKey = 'Settings/CreatureMercyContagion/3_Behaviour'
local debugKey = 'Settings/CreatureMercyContagion/4_Debug'

local groups = {
    {
        key = generalKey,
        page = pageKey,
        order = 1,
        l10n = pageKey,
        name = 'generalGroup_name',
        description = 'generalGroup_desc',
        permanentStorage = false,
        settings = {
            { key = 'autoLearnBaseSpells', default = false, renderer = 'checkbox', name = 'autoLearnBaseSpells_name', description = 'autoLearnBaseSpells_desc' },
            { key = 'showMessages', default = true, renderer = 'checkbox', name = 'showMessages_name', description = 'showMessages_desc' },
            { key = 'integrateSpellMerchants', default = true, renderer = 'checkbox', name = 'integrateSpellMerchants_name', description = 'integrateSpellMerchants_desc' },
            { key = 'integrateSpellTomes', default = true, renderer = 'checkbox', name = 'integrateSpellTomes_name', description = 'integrateSpellTomes_desc' },
        },
    },
    {
        key = rewardsKey,
        page = pageKey,
        order = 2,
        l10n = pageKey,
        name = 'rewardsGroup_name',
        description = 'rewardsGroup_desc',
        permanentStorage = false,
        settings = {
            { key = 'enableRewardUnlocks', default = true, renderer = 'checkbox', name = 'enableRewardUnlocks_name', description = 'enableRewardUnlocks_desc' },
            { key = 'enableDreamMessages', default = true, renderer = 'checkbox', name = 'enableDreamMessages_name', description = 'enableDreamMessages_desc' },
            { key = 'enableCarrierTraits', default = true, renderer = 'checkbox', name = 'enableCarrierTraits_name', description = 'enableCarrierTraits_desc' },
            { key = 'enableAntiBlightDamage', default = true, renderer = 'checkbox', name = 'enableAntiBlightDamage_name', description = 'enableAntiBlightDamage_desc' },
            { key = 'enableAreaSpreadRewards', default = true, renderer = 'checkbox', name = 'enableAreaSpreadRewards_name', description = 'enableAreaSpreadRewards_desc' },
            { key = 'enablePathConflict', default = true, renderer = 'checkbox', name = 'enablePathConflict_name', description = 'enablePathConflict_desc' },
            { key = 'rewardThreshold1', default = cfg.settingsDefaults.rewardThreshold1, renderer = 'number', name = 'rewardThreshold1_name', description = 'rewardThreshold1_desc', argument = { min = 1, max = 9999 } },
            { key = 'rewardThreshold2', default = cfg.settingsDefaults.rewardThreshold2, renderer = 'number', name = 'rewardThreshold2_name', description = 'rewardThreshold2_desc', argument = { min = 1, max = 9999 } },
            { key = 'rewardThreshold3', default = cfg.settingsDefaults.rewardThreshold3, renderer = 'number', name = 'rewardThreshold3_name', description = 'rewardThreshold3_desc', argument = { min = 1, max = 9999 } },
        },
    },
    {
        key = behaviourKey,
        page = pageKey,
        order = 3,
        l10n = pageKey,
        name = 'behaviourGroup_name',
        description = 'behaviourGroup_desc',
        permanentStorage = false,
        settings = {
            { key = 'enableSpeciesFriendship', default = true, renderer = 'checkbox', name = 'enableSpeciesFriendship_name', description = 'enableSpeciesFriendship_desc' },
            { key = 'enableAnimalAllies', default = true, renderer = 'checkbox', name = 'enableAnimalAllies_name', description = 'enableAnimalAllies_desc' },
        },
    },
    {
        key = debugKey,
        page = pageKey,
        order = 4,
        l10n = pageKey,
        name = 'debugGroup_name',
        description = 'debugGroup_desc',
        permanentStorage = false,
        settings = {
            { key = 'debugMessages', default = false, renderer = 'checkbox', name = 'debugMessages_name', description = 'debugMessages_desc' },
            { key = 'debugDamageMessages', default = false, renderer = 'checkbox', name = 'debugDamageMessages_name', description = 'debugDamageMessages_desc' },
        },
    },
}

local storages = {
    storage.playerSection(generalKey),
    storage.playerSection(rewardsKey),
    storage.playerSection(behaviourKey),
    storage.playerSection(debugKey),
}

local function value(section, key)
    local v = section and section:get(key)
    if v == nil then return cfg.settingsDefaults[key] end
    return v
end

function M.snapshot()
    local general = storage.playerSection(generalKey)
    local rewards = storage.playerSection(rewardsKey)
    local behaviour = storage.playerSection(behaviourKey)
    local debug = storage.playerSection(debugKey)
    return {
        autoLearnBaseSpells = value(general, 'autoLearnBaseSpells'),
        showMessages = value(general, 'showMessages'),
        integrateSpellMerchants = value(general, 'integrateSpellMerchants'),
        integrateSpellTomes = value(general, 'integrateSpellTomes'),
        enableRewardUnlocks = value(rewards, 'enableRewardUnlocks'),
        enableDreamMessages = value(rewards, 'enableDreamMessages'),
        enableCarrierTraits = value(rewards, 'enableCarrierTraits'),
        enableAntiBlightDamage = value(rewards, 'enableAntiBlightDamage'),
        enableAreaSpreadRewards = value(rewards, 'enableAreaSpreadRewards'),
        enablePathConflict = value(rewards, 'enablePathConflict'),
        rewardThreshold1 = value(rewards, 'rewardThreshold1'),
        rewardThreshold2 = value(rewards, 'rewardThreshold2'),
        rewardThreshold3 = value(rewards, 'rewardThreshold3'),
        enableSpeciesFriendship = value(behaviour, 'enableSpeciesFriendship'),
        enableAnimalAllies = value(behaviour, 'enableAnimalAllies'),
        debugMessages = value(debug, 'debugMessages'),
        debugDamageMessages = value(debug, 'debugDamageMessages'),
    }
end

function M.init()
    if initialized then return end
    if not I.Settings or not I.Settings.registerPage or not I.Settings.registerGroup then return end
    initialized = true
    I.Settings.registerPage {
        key = pageKey,
        l10n = pageKey,
        name = 'settingsPage_name',
        description = 'settingsPage_desc',
    }
    for _, group in ipairs(groups) do
        I.Settings.registerGroup(group)
    end
end

function M.subscribe(callback)
    if not callback then return end
    for _, section in ipairs(storages) do
        if section and section.subscribe then
            section:subscribe(async:callback(function()
                callback(M.snapshot())
            end))
        end
    end
end

return M
