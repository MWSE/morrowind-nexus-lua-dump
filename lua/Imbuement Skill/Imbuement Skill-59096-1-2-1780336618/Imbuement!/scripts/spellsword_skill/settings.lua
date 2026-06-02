--[[
    Spellsword! Skill — Settings Page
    MENU-scope script. Registers all toggleable settings exposed in
    Options → Scripts → Spellsword! Skill.
]]

local I = require('openmw.interfaces')

local MODNAME = 'Spellsword'
local PAGE_KEY = 'SpellswordSkill'  -- distinct from base "ImbuleWeapon" page

I.Settings.registerPage {
    key = PAGE_KEY,
    l10n = MODNAME,
    name = 'PageName',
    description = 'PageDescription',
}

-- ─── General ────────────────────────────────────────────────────────────────

I.Settings.registerGroup {
    key = 'Settings_' .. MODNAME,
    page = PAGE_KEY,
    l10n = MODNAME,
    name = 'SettingsName',
    description = 'SettingsDescription',
    permanentStorage = true,
    settings = {
        {
            key = 'enabled',
            renderer = 'checkbox',
            name = 'SettingEnabled',
            description = 'SettingEnabledDescription',
            default = true,
        },
        {
            key = 'driveBaseElementalBuff',
            renderer = 'checkbox',
            name = 'SettingDriveBaseElementalBuff',
            description = 'SettingDriveBaseElementalBuffDescription',
            default = true,
        },
        {
            key = 'driveSpellStacking',
            renderer = 'checkbox',
            name = 'SettingDriveSpellStacking',
            description = 'SettingDriveSpellStackingDescription',
            default = true,
        },
        {
            key = 'driveActiveMagickaEfficiency',
            renderer = 'checkbox',
            name = 'SettingDriveActiveMagickaEfficiency',
            description = 'SettingDriveActiveMagickaEfficiencyDescription',
            default = true,
        },
        {
            key = 'driveCharges',
            renderer = 'checkbox',
            name = 'SettingDriveCharges',
            description = 'SettingDriveChargesDescription',
            default = true,
        },
    },
}

-- ─── Skill & Progression ────────────────────────────────────────────────────

I.Settings.registerGroup {
    key = 'Settings_' .. MODNAME .. '_Skill',
    page = PAGE_KEY,
    l10n = MODNAME,
    name = 'SkillGroupName',
    description = 'SkillGroupDescription',
    permanentStorage = true,
    settings = {
        {
            key = 'enableRaceBonuses',
            renderer = 'checkbox',
            name = 'SettingEnableRaceBonuses',
            description = 'SettingEnableRaceBonusesDescription',
            default = true,
        },
        {
            key = 'enableClassBonus',
            renderer = 'checkbox',
            name = 'SettingEnableClassBonus',
            description = 'SettingEnableClassBonusDescription',
            default = true,
        },
        {
            key = 'enableSkillBooks',
            renderer = 'checkbox',
            name = 'SettingEnableSkillBooks',
            description = 'SettingEnableSkillBooksDescription',
            default = true,
        },
        {
            key = 'xpOnApply',
            renderer = 'checkbox',
            name = 'SettingXpOnApply',
            description = 'SettingXpOnApplyDescription',
            default = true,
        },
        {
            key = 'xpOnChargeSpend',
            renderer = 'checkbox',
            name = 'SettingXpOnChargeSpend',
            description = 'SettingXpOnChargeSpendDescription',
            default = true,
        },
        {
            key = 'xpOnMagickaSpend',
            renderer = 'checkbox',
            name = 'SettingXpOnMagickaSpend',
            description = 'SettingXpOnMagickaSpendDescription',
            default = true,
        },
        {
            key = 'xpOnFirstUseFree',
            renderer = 'checkbox',
            name = 'SettingXpOnFirstUseFree',
            description = 'SettingXpOnFirstUseFreeDescription',
            default = true,
        },
        {
            key = 'xpMultiplier',
            renderer = 'number',
            name = 'SettingXpMultiplier',
            description = 'SettingXpMultiplierDescription',
            default = 100,
            argument = { min = 0, max = 500, integer = true },
        },
    },
}

-- ─── Mechanics (charges, efficiency, buff, stacking tuning) ────────────────

I.Settings.registerGroup {
    key = 'Settings_' .. MODNAME .. '_Mechanics',
    page = PAGE_KEY,
    l10n = MODNAME,
    name = 'MechanicsGroupName',
    description = 'MechanicsGroupDescription',
    permanentStorage = true,
    settings = {
        -- Charges
        {
            key = 'baseCharges',
            renderer = 'number',
            name = 'SettingBaseCharges',
            description = 'SettingBaseChargesDescription',
            default = 10,
            argument = { min = 1, max = 100, integer = true },
        },
        {
            key = 'chargesPerMilestone',
            renderer = 'number',
            name = 'SettingChargesPerMilestone',
            description = 'SettingChargesPerMilestoneDescription',
            default = 5,
            argument = { min = 0, max = 50, integer = true },
        },
        {
            key = 'milestoneInterval',
            renderer = 'number',
            name = 'SettingMilestoneInterval',
            description = 'SettingMilestoneIntervalDescription',
            default = 20,
            argument = { min = 5, max = 50, integer = true },
        },
        {
            key = 'maxCharges',
            renderer = 'number',
            name = 'SettingMaxCharges',
            description = 'SettingMaxChargesDescription',
            default = 35,
            argument = { min = 1, max = 999, integer = true },
        },
        -- Active mode magicka efficiency
        {
            key = 'activeStepPercent',
            renderer = 'number',
            name = 'SettingActiveStepPercent',
            description = 'SettingActiveStepPercentDescription',
            default = 10,
            argument = { min = 0, max = 50, integer = true },
        },
        {
            key = 'activeMaxReductionPercent',
            renderer = 'number',
            name = 'SettingActiveMaxReductionPercent',
            description = 'SettingActiveMaxReductionPercentDescription',
            default = 50,
            argument = { min = 0, max = 95, integer = true },
        },
        -- Elemental buff
        {
            key = 'baseElementalBuff',
            renderer = 'number',
            name = 'SettingBaseElementalBuff',
            description = 'SettingBaseElementalBuffDescription',
            default = 0.05,
            argument = { min = 0, max = 2, step = 0.01 },
        },
        {
            key = 'elementalStepPerMilestone',
            renderer = 'number',
            name = 'SettingElementalStepPerMilestone',
            description = 'SettingElementalStepPerMilestoneDescription',
            default = 0.05,
            argument = { min = 0, max = 1, step = 0.01 },
        },
        {
            key = 'maxElementalBuff',
            renderer = 'number',
            name = 'SettingMaxElementalBuff',
            description = 'SettingMaxElementalBuffDescription',
            default = 0.30,
            argument = { min = 0, max = 5, step = 0.01 },
        },
        -- Stacking
        {
            key = 'spellStackingUnlockLevel',
            renderer = 'number',
            name = 'SettingSpellStackingUnlockLevel',
            description = 'SettingSpellStackingUnlockLevelDescription',
            default = 50,
            argument = { min = 0, max = 100, integer = true },
        },
        {
            key = 'allowSpellStacking',
            renderer = 'checkbox',
            name = 'SettingAllowSpellStacking',
            description = 'SettingAllowSpellStackingDescription',
            default = true,
        },
    },
}

-- ─── Perks ──────────────────────────────────────────────────────────────────

I.Settings.registerGroup {
    key = 'Settings_' .. MODNAME .. '_Perks',
    page = PAGE_KEY,
    l10n = MODNAME,
    name = 'PerksGroupName',
    description = 'PerksGroupDescription',
    permanentStorage = true,
    settings = {
        {
            key = 'enableAllPerks',
            renderer = 'checkbox',
            name = 'SettingEnableAllPerks',
            description = 'SettingEnableAllPerksDescription',
            default = true,
        },
        {
            key = 'enableLingeringImbue',
            renderer = 'checkbox',
            name = 'SettingEnableLingeringImbue',
            description = 'SettingEnableLingeringImbueDescription',
            default = true,
        },
        {
            key = 'enableArcaneFlow',
            renderer = 'checkbox',
            name = 'SettingEnableArcaneFlow',
            description = 'SettingEnableArcaneFlowDescription',
            default = true,
        },
        {
            key = 'arcaneFlowMagickaPerHit',
            renderer = 'number',
            name = 'SettingArcaneFlowMagickaPerHit',
            description = 'SettingArcaneFlowMagickaPerHitDescription',
            default = 2,
            argument = { min = 0, max = 50, integer = true },
        },
        {
            key = 'arcaneFlowCooldownSec',
            renderer = 'number',
            name = 'SettingArcaneFlowCooldownSec',
            description = 'SettingArcaneFlowCooldownSecDescription',
            default = 0.5,
            argument = { min = 0, max = 10, step = 0.1 },
        },
        {
            key = 'enablePerfectConduit',
            renderer = 'checkbox',
            name = 'SettingEnablePerfectConduit',
            description = 'SettingEnablePerfectConduitDescription',
            default = true,
        },
        {
            key = 'perfectConduitMagnitude',
            renderer = 'number',
            name = 'SettingPerfectConduitMagnitude',
            description = 'SettingPerfectConduitMagnitudeDescription',
            default = 20,
            argument = { min = 0, max = 200, integer = true },
        },
        {
            key = 'perfectConduitDurationSec',
            renderer = 'number',
            name = 'SettingPerfectConduitDurationSec',
            description = 'SettingPerfectConduitDurationSecDescription',
            default = 8,
            argument = { min = 1, max = 60, integer = true },
        },
        {
            key = 'enableArcaneOverdrive',
            renderer = 'checkbox',
            name = 'SettingEnableArcaneOverdrive',
            description = 'SettingEnableArcaneOverdriveDescription',
            default = true,
        },
        {
            key = 'arcaneOverdriveDurationSec',
            renderer = 'number',
            name = 'SettingArcaneOverdriveDurationSec',
            description = 'SettingArcaneOverdriveDurationSecDescription',
            default = 12,
            argument = { min = 1, max = 60, integer = true },
        },
        {
            key = 'arcaneOverdriveCooldownSec',
            renderer = 'number',
            name = 'SettingArcaneOverdriveCooldownSec',
            description = 'SettingArcaneOverdriveCooldownSecDescription',
            default = 90,
            argument = { min = 1, max = 600, integer = true },
        },
    },
}

-- ─── UI / tooltip ───────────────────────────────────────────────────────────

I.Settings.registerGroup {
    key = 'Settings_' .. MODNAME .. '_UI',
    page = PAGE_KEY,
    l10n = MODNAME,
    name = 'UiGroupName',
    description = 'UiGroupDescription',
    permanentStorage = true,
    settings = {
        {
            key = 'showMechanicTooltips',
            renderer = 'checkbox',
            name = 'SettingShowMechanicTooltips',
            description = 'SettingShowMechanicTooltipsDescription',
            default = true,
        },
        {
            key = 'showPerkTooltips',
            renderer = 'checkbox',
            name = 'SettingShowPerkTooltips',
            description = 'SettingShowPerkTooltipsDescription',
            default = true,
        },
        {
            key = 'tooltipUnlockedOnly',
            renderer = 'checkbox',
            name = 'SettingTooltipUnlockedOnly',
            description = 'SettingTooltipUnlockedOnlyDescription',
            default = false,
        },
        {
            key = 'showMilestonePreview',
            renderer = 'checkbox',
            name = 'SettingShowMilestonePreview',
            description = 'SettingShowMilestonePreviewDescription',
            default = true,
        },
        {
            key = 'showActiveModePreview',
            renderer = 'checkbox',
            name = 'SettingShowActiveModePreview',
            description = 'SettingShowActiveModePreviewDescription',
            default = true,
        },
        {
            key = 'imbueSpellCost',
            renderer = 'number',
            name = 'SettingImbueSpellCost',
            description = 'SettingImbueSpellCostDescription',
            default = 9,
            argument = { min = 1, max = 100, integer = true },
        },
        {
            key = 'debugMessages',
            renderer = 'checkbox',
            name = 'SettingDebugMessages',
            description = 'SettingDebugMessagesDescription',
            default = false,
        },
        {
            key = 'debugXpMessages',
            renderer = 'checkbox',
            name = 'SettingDebugXpMessages',
            description = 'SettingDebugXpMessagesDescription',
            default = false,
        },
        {
            key = 'debugOverrideMessages',
            renderer = 'checkbox',
            name = 'SettingDebugOverrideMessages',
            description = 'SettingDebugOverrideMessagesDescription',
            default = false,
        },
        {
            key = 'debugIntegrationMessages',
            renderer = 'checkbox',
            name = 'SettingDebugIntegrationMessages',
            description = 'SettingDebugIntegrationMessagesDescription',
            default = false,
        },
    },
}
