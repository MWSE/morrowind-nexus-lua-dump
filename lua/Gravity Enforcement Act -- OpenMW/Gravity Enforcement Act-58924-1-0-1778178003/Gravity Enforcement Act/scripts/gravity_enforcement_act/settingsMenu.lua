local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_General',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'general_groupName',
    description = 'general_groupDesc',
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'Enabled',
            renderer = 'checkbox',
            name = 'enabled_name',
            description = 'enabled_desc',
            default = true,
        },
        {
            key = 'PresetProfile',
            renderer = 'select',
            name = 'presetProfile_name',
            description = 'presetProfile_desc',
            default = 'Default',
            argument = {
                l10n = 'GravityEnforcementAct',
                items = { 'Default', 'Custom', 'Vanilla', 'Regulated', 'Enforced' },
            },
        },
		{
			key = 'AllowLevitationFromPotions',
			renderer = 'checkbox',
			name = 'allowLevitationFromPotions_name',
			description = 'allowLevitationFromPotions_desc',
			default = true,
		},		
		{
			key = 'AllowLevitationFromScrolls',
			renderer = 'checkbox',
			name = 'allowLevitationFromScrolls_name',
			description = 'allowLevitationFromScrolls_desc',
			default = true,
		},		
		{
			key = 'AllowLevitationFromSpells',
			renderer = 'checkbox',
			name = 'allowLevitationFromSpells_name',
			description = 'allowLevitationFromSpells_desc',
			default = true,
		},
		{
			key = 'AllowLevitationFromEnchantedItems',
			renderer = 'checkbox',
			name = 'allowLevitationFromEnchantedItems_name',
			description = 'allowLevitationFromEnchantedItems_desc',
			default = true,
		},		
		{
			key = 'AllowLevitationFromConstantEffect',
			renderer = 'checkbox',
			name = 'allowLevitationFromConstantEffect_name',
			description = 'allowLevitationFromConstantEffect_desc',
			default = true,
		},
		{
			key = 'AllowLevitationFromUnknownSources',
			renderer = 'checkbox',
			name = 'allowLevitationFromUnknownSources_name',
			description = 'allowLevitationFromUnknownSources_desc',
			default = true,
		},			
        {
            key = 'IncludeConstantEffectLevitation',
            renderer = 'checkbox',
            name = 'includeConstantEffectLevitation_name',
            description = 'includeConstantEffectLevitation_desc',
            default = true,
        },
        {
            key = 'ExcludedCells',
            renderer = 'textLine',
            name = 'excludedCells_name',
            description = 'excludedCells_desc',
            default = '',
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_Restriction',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'restriction_groupName',
    description = 'restriction_groupDesc',
    permanentStorage = true,
    order = 2,
	settings = {
		{
			key = 'RestrictionPolicyMode',
			renderer = 'select',
			name = 'restrictionPolicyMode_name',
			description = 'restrictionPolicyMode_desc',
			default = 'ExtYesIntNo',
			argument = {
				l10n = 'GravityEnforcementAct',
				items = {
					'ExtYesIntYes',
					'ExtYesIntNo',
					'ExtNoIntYes',
					'ExtNoIntNo',
				},
			},
		},
		{
			key = 'RestrictExteriorCities',
			renderer = 'checkbox',
			name = 'restrictExteriorCities_name',
			description = 'restrictExteriorCities_desc',
			default = true,
		},		
		{
			key = 'RestrictedExteriorRegions',
			renderer = 'textLine',
			name = 'restrictedExteriorRegions_name',
			description = 'restrictedExteriorRegions_desc',
			default = '',
		},
		{
			key = 'RestrictedNamedInteriors',
			renderer = 'textLine',
			name = 'restrictedNamedInteriors_name',
			description = 'restrictedNamedInteriors_desc',
			default = '',
		},
		{
			key = 'AllowedExteriorRegions',
			renderer = 'textLine',
			name = 'allowedExteriorRegions_name',
			description = 'allowedExteriorRegions_desc',
			default = '',
		},
		{
			key = 'AllowedNamedInteriors',
			renderer = 'textLine',
			name = 'allowedNamedInteriors_name',
			description = 'allowedNamedInteriors_desc',
			default = '',
		},
	}
}

I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_Crime',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'crime_groupName',
    description = 'crime_groupDesc',
    permanentStorage = true,
    order = 3,
    settings = {
        {
            key = 'IllegalLevitationCrimeEnabled',
            renderer = 'checkbox',
            name = 'illegalLevitationCrimeEnabled_name',
            description = 'illegalLevitationCrimeEnabled_desc',
            default = true,
        },
		{
			key = 'IllegalLevitationSuppressInRestrictedAreas',
			renderer = 'checkbox',
			name = 'illegalLevitationSuppressInRestrictedAreas_name',
			description = 'illegalLevitationSuppressInRestrictedAreas_desc',
			default = true,
		},		
		{
			key = 'IllegalLevitationCrimeRequireWitness',
			renderer = 'checkbox',
			name = 'illegalLevitationCrimeRequireWitness_name',
			description = 'illegalLevitationCrimeRequireWitness_desc',
			default = true,
		},
		{
			key = 'IllegalLevitationCrimeRequireLineOfSight',
			renderer = 'checkbox',
			name = 'illegalLevitationCrimeRequireLineOfSight_name',
			description = 'illegalLevitationCrimeRequireLineOfSight_desc',
			default = true,
		},	
		{
			key = 'IllegalLevitationCrimeRequireFacing',
			renderer = 'checkbox',
			name = 'illegalLevitationCrimeRequireFacing_name',
			description = 'illegalLevitationCrimeRequireFacing_desc',
			default = false,
		},		
		{
			key = 'IllegalLevitationCrimeWitnessRadius',
			renderer = 'number',
			name = 'illegalLevitationCrimeWitnessRadius_name',
			description = 'illegalLevitationCrimeWitnessRadius_desc',
			default = 1000,
			min = 0,
			max = 5000,
		},		
        {
            key = 'IllegalLevitationCrimeBountyGold',
            renderer = 'number',
            name = 'illegalLevitationCrimeBountyGold_name',
            description = 'illegalLevitationCrimeBountyGold_desc',
            default = 250,
            min = 0,
            max = 10000,
        },
        {
            key = 'IllegalLevitationCrimeEscalationEnabled',
            renderer = 'checkbox',
            name = 'illegalLevitationCrimeEscalationEnabled_name',
            description = 'illegalLevitationCrimeEscalationEnabled_desc',
            default = true,
        },
        {
            key = 'IllegalLevitationCrimeRepeatBountyGold',
            renderer = 'number',
            name = 'illegalLevitationCrimeRepeatBountyGold_name',
            description = 'illegalLevitationCrimeRepeatBountyGold_desc',
            default = 150,
            min = 0,
            max = 10000,
        },
        {
            key = 'IllegalLevitationCrimeMaxBountyGold',
            renderer = 'number',
            name = 'illegalLevitationCrimeMaxBountyGold_name',
            description = 'illegalLevitationCrimeMaxBountyGold_desc',
            default = 1000,
            min = 0,
            max = 50000,
        },
        {
            key = 'IllegalLevitationCrimeOncePerCell',
            renderer = 'checkbox',
            name = 'illegalLevitationCrimeOncePerCell_name',
            description = 'illegalLevitationCrimeOncePerCell_desc',
            default = true,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_Fatigue',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'fatigue_groupName',
    description = 'fatigue_groupDesc',
    permanentStorage = true,
    order = 4,
    settings = {
        {
            key = 'DrainFatigueWhileLevitating',
            renderer = 'checkbox',
            name = 'drainFatigueWhileLevitating_name',
            description = 'drainFatigueWhileLevitating_desc',
            default = true,
        },
        {
            key = 'StopLevitateOnZeroFatigue',
            renderer = 'checkbox',
            name = 'stopLevitateOnZeroFatigue_name',
            description = 'stopLevitateOnZeroFatigue_desc',
            default = true,
        },
        {
            key = 'DrainFatigueOnlyInRestrictedAreas',
            renderer = 'checkbox',
            name = 'drainFatigueOnlyInRestrictedAreas_name',
            description = 'drainFatigueOnlyInRestrictedAreas_desc',
            default = false,
        },
        {
            key = 'FatigueDrainPerSecond',
            renderer = 'number',
            name = 'fatigueDrainPerSecond_name',
            description = 'fatigueDrainPerSecond_desc',
            default = 6,
            min = 0,
            max = 100,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_Altitude',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'altitude_groupName',
    description = 'altitude_groupDesc',
    permanentStorage = true,
    order = 5,
    settings = {
        {
            key = 'EnableAltitudeLimit',
            renderer = 'checkbox',
            name = 'enableAltitudeLimit_name',
            description = 'enableAltitudeLimit_desc',
            default = true,
        },
        {
            key = 'AltitudeSoftLimit',
            renderer = 'number',
            name = 'altitudeSoftLimit_name',
            description = 'altitudeSoftLimit_desc',
            default = 300,
            min = 0,
            max = 5000,
        },
        {
            key = 'AltitudeHardLimit',
            renderer = 'number',
            name = 'altitudeHardLimit_name',
            description = 'altitudeHardLimit_desc',
            default = 600,
            min = 0,
            max = 10000,
        },
        {
            key = 'AltitudeSoftDrainMultiplier',
            renderer = 'number',
            name = 'altitudeSoftDrainMultiplier_name',
            description = 'altitudeSoftDrainMultiplier_desc',
            default = 4,
            min = 0,
            max = 50,
        },
        {
            key = 'AltitudeSoftDownwardPressureMax',
            renderer = 'number',
            name = 'altitudeSoftDownwardPressureMax_name',
            description = 'altitudeSoftDownwardPressureMax_desc',
            default = 300,
            min = 0,
            max = 500,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_Scaling',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'scaling_groupName',
    description = 'scaling_groupDesc',
    permanentStorage = true,
    order = 6,
    settings = {
        {
            key = 'AltitudeAlterationScaling',
            renderer = 'checkbox',
            name = 'altitudeAlterationScaling_name',
            description = 'altitudeAlterationScaling_desc',
            default = true,
        },
        {
            key = 'AltitudeAlterationBonusMax',
            renderer = 'number',
            name = 'altitudeAlterationBonusMax_name',
            description = 'altitudeAlterationBonusMax_desc',
            default = 400,
            min = 0,
            max = 5000,
        },
        {
            key = 'AltitudeEncumbrancePenalty',
            renderer = 'checkbox',
            name = 'altitudeEncumbrancePenalty_name',
            description = 'altitudeEncumbrancePenalty_desc',
            default = true,
        },
        {
            key = 'AltitudeEncumbrancePenaltyMax',
            renderer = 'number',
            name = 'altitudeEncumbrancePenaltyMax_name',
            description = 'altitudeEncumbrancePenaltyMax_desc',
            default = 300,
            min = 0,
            max = 5000,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_Tarhiel',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'tarhiel_groupName',
    description = 'tarhiel_groupDesc',
    permanentStorage = true,
    order = 7,
    settings = {
        {
            key = 'TarhielCancelAtHardLimit',
            renderer = 'checkbox',
            name = 'tarhielCancelAtHardLimit_name',
            description = 'tarhielCancelAtHardLimit_desc',
            default = false,
        },
        {
            key = 'AllowTerrainCrawling',
            renderer = 'checkbox',
            name = 'allowTerrainCrawling_name',
            description = 'allowTerrainCrawling_desc',
            default = true,
        },
        {
            key = 'TarhielRandomSoftCancel',
            renderer = 'checkbox',
            name = 'tarhielRandomSoftCancel_name',
            description = 'tarhielRandomSoftCancel_desc',
            default = false,
        },
        {
            key = 'TarhielRandomSoftCancelChance',
            renderer = 'number',
            name = 'tarhielRandomSoftCancelChance_name',
            description = 'tarhielRandomSoftCancelChance_desc',
            default = 1,
            min = 0,
            max = 100,
        },
        {
            key = 'LevitationFailureCooldownEnabled',
            renderer = 'checkbox',
            name = 'levitationFailureCooldownEnabled_name',
            description = 'levitationFailureCooldownEnabled_desc',
            default = true,
        },
        {
            key = 'LevitationFailureCooldownSeconds',
            renderer = 'number',
            name = 'levitationFailureCooldownSeconds_name',
            description = 'levitationFailureCooldownSeconds_desc',
            default = 5,
            min = 0,
            max = 60,
        },
    }
}



I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_Items',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'items_groupName',
    description = 'items_groupDesc',
    permanentStorage = true,
    order = 8,
    settings = {
        { key = 'ItemLevitationRulesEnabled', renderer = 'checkbox', name = 'itemLevitationRulesEnabled_name', description = 'itemLevitationRulesEnabled_desc', default = true },
        { key = 'LevitationItemFailureSkillReduction', renderer = 'checkbox', name = 'levitationItemFailureSkillReduction_name', description = 'levitationItemFailureSkillReduction_desc', default = true },

        -- Potions
        { key = 'PotionLevitationMinAlteration', renderer = 'number', name = 'potionLevitationMinAlteration_name', description = 'potionLevitationMinAlteration_desc', default = 25, min = 0, max = 100 },
        { key = 'PotionLevitationMinIntelligence', renderer = 'number', name = 'potionLevitationMinIntelligence_name', description = 'potionLevitationMinIntelligence_desc', default = 35, min = 0, max = 200 },
        { key = 'PotionLevitationFailureChance', renderer = 'number', name = 'potionLevitationFailureChance_name', description = 'potionLevitationFailureChance_desc', default = 25, min = 0, max = 100 },
        { key = 'PotionLevitationPowerMultiplier', renderer = 'number', name = 'potionLevitationPowerMultiplier_name', description = 'potionLevitationPowerMultiplier_desc', default = 0.5, min = 0.05, max = 1 },
        { key = 'CustomPotionLevitationPowerMultiplier', renderer = 'number', name = 'customPotionLevitationPowerMultiplier_name', description = 'customPotionLevitationPowerMultiplier_desc', default = 0.25, min = 0.05, max = 1 },

        -- Scrolls
        { key = 'ScrollLevitationMinAlteration', renderer = 'number', name = 'scrollLevitationMinAlteration_name', description = 'scrollLevitationMinAlteration_desc', default = 35, min = 0, max = 100 },
        { key = 'ScrollLevitationMinIntelligence', renderer = 'number', name = 'scrollLevitationMinIntelligence_name', description = 'scrollLevitationMinIntelligence_desc', default = 50, min = 0, max = 200 },
        { key = 'ScrollLevitationFailureChance', renderer = 'number', name = 'scrollLevitationFailureChance_name', description = 'scrollLevitationFailureChance_desc', default = 15, min = 0, max = 100 },
        { key = 'ScrollLevitationPowerMultiplier', renderer = 'number', name = 'scrollLevitationPowerMultiplier_name', description = 'scrollLevitationPowerMultiplier_desc', default = 0.7, min = 0.05, max = 1 },

        -- Approved spells
        { key = 'ApprovedSpellLevitationRulesEnabled', renderer = 'checkbox', name = 'approvedSpellLevitationRulesEnabled_name', description = 'approvedSpellLevitationRulesEnabled_desc', default = true },
        { key = 'ApprovedSpellLevitationMinAlteration', renderer = 'number', name = 'approvedSpellLevitationMinAlteration_name', description = 'approvedSpellLevitationMinAlteration_desc', default = 30, min = 0, max = 100 },
        { key = 'ApprovedSpellLevitationMinIntelligence', renderer = 'number', name = 'approvedSpellLevitationMinIntelligence_name', description = 'approvedSpellLevitationMinIntelligence_desc', default = 35, min = 0, max = 200 },
        { key = 'ApprovedSpellLevitationFailureChance', renderer = 'number', name = 'approvedSpellLevitationFailureChance_name', description = 'approvedSpellLevitationFailureChance_desc', default = 0, min = 0, max = 100 },
        { key = 'ApprovedLevitationSpellIds', renderer = 'textLine', name = 'approvedLevitationSpellIds_name', description = 'approvedLevitationSpellIds_desc', default = '' },

        -- Custom spells
        { key = 'CustomSpellLevitationRulesEnabled', renderer = 'checkbox', name = 'customSpellLevitationRulesEnabled_name', description = 'customSpellLevitationRulesEnabled_desc', default = true },
        { key = 'CustomSpellLevitationMinAlteration', renderer = 'number', name = 'customSpellLevitationMinAlteration_name', description = 'customSpellLevitationMinAlteration_desc', default = 40, min = 0, max = 100 },
        { key = 'CustomSpellLevitationMinIntelligence', renderer = 'number', name = 'customSpellLevitationMinIntelligence_name', description = 'customSpellLevitationMinIntelligence_desc', default = 50, min = 0, max = 200 },
        { key = 'CustomSpellLevitationFailureChance', renderer = 'number', name = 'customSpellLevitationFailureChance_name', description = 'customSpellLevitationFailureChance_desc', default = 20, min = 0, max = 100 },
        { key = 'CustomSpellLevitationPowerMultiplier', renderer = 'number', name = 'customSpellLevitationPowerMultiplier_name', description = 'customSpellLevitationPowerMultiplier_desc', default = 0.35, min = 0.05, max = 1 },

        -- Enchanted items
        { key = 'EnchantedItemLevitationRulesEnabled', renderer = 'checkbox', name = 'enchantedItemLevitationRulesEnabled_name', description = 'enchantedItemLevitationRulesEnabled_desc', default = true },
        { key = 'EnchantedItemLevitationMinAlteration', renderer = 'number', name = 'enchantedItemLevitationMinAlteration_name', description = 'enchantedItemLevitationMinAlteration_desc', default = 35, min = 0, max = 100 },
        { key = 'EnchantedItemLevitationMinIntelligence', renderer = 'number', name = 'enchantedItemLevitationMinIntelligence_name', description = 'enchantedItemLevitationMinIntelligence_desc', default = 45, min = 0, max = 200 },
        { key = 'EnchantedItemLevitationFailureChance', renderer = 'number', name = 'enchantedItemLevitationFailureChance_name', description = 'enchantedItemLevitationFailureChance_desc', default = 15, min = 0, max = 100 },

        -- Constant-effect items
        { key = 'ConstantEffectLevitationRulesEnabled', renderer = 'checkbox', name = 'constantEffectLevitationRulesEnabled_name', description = 'constantEffectLevitationRulesEnabled_desc', default = false },
        { key = 'ConstantEffectLevitationMinAlteration', renderer = 'number', name = 'constantEffectLevitationMinAlteration_name', description = 'constantEffectLevitationMinAlteration_desc', default = 60, min = 0, max = 100 },
        { key = 'ConstantEffectLevitationMinIntelligence', renderer = 'number', name = 'constantEffectLevitationMinIntelligence_name', description = 'constantEffectLevitationMinIntelligence_desc', default = 70, min = 0, max = 100 },
        { key = 'ConstantEffectLevitationFailureChance', renderer = 'number', name = 'constantEffectLevitationFailureChance_name', description = 'constantEffectLevitationFailureChance_desc', default = 0, min = 0, max = 100 },

        -- Unknown sources
        { key = 'UnknownLevitationRulesEnabled', renderer = 'checkbox', name = 'unknownLevitationRulesEnabled_name', description = 'unknownLevitationRulesEnabled_desc', default = false },
        { key = 'UnknownLevitationMinAlteration', renderer = 'number', name = 'unknownLevitationMinAlteration_name', description = 'unknownLevitationMinAlteration_desc', default = 50, min = 0, max = 100 },
        { key = 'UnknownLevitationMinIntelligence', renderer = 'number', name = 'unknownLevitationMinIntelligence_name', description = 'unknownLevitationMinIntelligence_desc', default = 60, min = 0, max = 200 },
        { key = 'UnknownLevitationFailureChance', renderer = 'number', name = 'unknownLevitationFailureChance_name', description = 'unknownLevitationFailureChance_desc', default = 50, min = 0, max = 100 },
    }
}

I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_Vendors',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'vendors_groupName',
    description = 'vendors_groupDesc',
    permanentStorage = true,
    order = 9,
    settings = {
        {
            key = 'VendorLevitateSuppressionEnabled',
            renderer = 'checkbox',
            name = 'vendorLevitateSuppressionEnabled_name',
            description = 'vendorLevitateSuppressionEnabled_desc',
            default = true,
        },
        {
            key = 'VendorLevitateVanillaNpcIds',
            renderer = 'textLine',
            name = 'vendorLevitateVanillaNpcIds_name',
            description = 'vendorLevitateVanillaNpcIds_desc',
            default = '',
        },
        {
            key = 'VendorLevitationItemThinningEnabled',
            renderer = 'checkbox',
            name = 'vendorLevitationItemThinningEnabled_name',
            description = 'vendorLevitationItemThinningEnabled_desc',
            default = true,
        },
        {
            key = 'VendorLevitationItemMaxPotions',
            renderer = 'number',
            name = 'vendorLevitationItemMaxPotions_name',
            description = 'vendorLevitationItemMaxPotions_desc',
            default = 1,
            min = 1,
            max = 20,
        },
        {
            key = 'VendorLevitationItemMaxScrolls',
            renderer = 'number',
            name = 'vendorLevitationItemMaxScrolls_name',
            description = 'vendorLevitationItemMaxScrolls_desc',
            default = 1,
            min = 1,
            max = 20,
        },
        {
            key = 'VendorLevitationItemKeepAtLeast',
            renderer = 'number',
            name = 'vendorLevitationItemKeepAtLeast_name',
            description = 'vendorLevitationItemKeepAtLeast_desc',
            default = 1,
            min = 0,
            max = 20,
        },
    }
}

I.Settings.registerGroup {
    key = 'SettingsPlayerGravityEnforcementAct_Advanced',
    page = 'GravityEnforcementAct',
    l10n = 'GravityEnforcementAct',
    name = 'advanced_groupName',
    description = 'advanced_groupDesc',
    permanentStorage = true,
    order = 10,
    settings = {
        {
            key = 'WhitelistedSpellIds',
            renderer = 'textLine',
            name = 'whitelistedSpellIds_name',
            description = 'whitelistedSpellIds_desc',
            default = '',
        },
        {
            key = 'WhitelistedItemIds',
            renderer = 'textLine',
            name = 'whitelistedItemIds_name',
            description = 'whitelistedItemIds_desc',
            default = '',
        },
        {
            key = 'ShowAltitudePressureMessages',
            renderer = 'checkbox',
            name = 'showAltitudePressureMessages_name',
            description = 'showAltitudePressureMessages_desc',
            default = false,
        },
        {
            key = 'Debug',
            renderer = 'checkbox',
            name = 'debug_name',
            description = 'debug_desc',
            default = false,
        },
    }
}
