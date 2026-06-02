local storage = require('openmw.storage')

local M = {}

local runtimeOverrides = {}

local NON_CONFIGURABLE_DEFAULTS = {
	['IllegalLevitationCrimeResetOnLegalArea'] = false,
	['IllegalLevitationCrimeMessageEnabled'] = true,
	['IllegalLevitationCrimeForceBounty'] = true,
	['VendorLevitatePatchIntervalSeconds'] = 2,
}

local GROUP_KEYS = {
    'SettingsPlayerGravityEnforcementAct_General',
    'SettingsPlayerGravityEnforcementAct_Restriction',
    'SettingsPlayerGravityEnforcementAct_Crime',
    'SettingsPlayerGravityEnforcementAct_Fatigue',
    'SettingsPlayerGravityEnforcementAct_Altitude',
    'SettingsPlayerGravityEnforcementAct_Scaling',
    'SettingsPlayerGravityEnforcementAct_Tarhiel',
	'SettingsPlayerGravityEnforcementAct_Items',
	'SettingsPlayerGravityEnforcementAct_Vendors',
    'SettingsPlayerGravityEnforcementAct_Advanced',

    -- legacy/base section last, only as fallback
    'SettingsPlayerGravityEnforcementAct',
}

local sections = {}
for _, key in ipairs(GROUP_KEYS) do
    sections[#sections + 1] = storage.playerSection(key)
end

local sectionByKey = {
	Enabled = sections[1],
	PresetProfile = sections[1],
	AllowLevitationFromPotions = sections[1],	
	AllowLevitationFromScrolls = sections[1],	
	AllowLevitationFromSpells = sections[1],
	AllowLevitationFromEnchantedItems = sections[1],	
	AllowLevitationFromConstantEffect = sections[1],	
	AllowLevitationFromUnknownSources = sections[1],	
	IncludeConstantEffectLevitation = sections[1],
	ExcludedCells = sections[1],

	RestrictionPolicyMode = sections[2],
	RestrictExteriorCities = sections[2],
	RestrictedExteriorRegions = sections[2],
	RestrictedExteriorCells = sections[2],
	RestrictedNamedInteriors = sections[2],
	AllowedExteriorRegions = sections[2],
	AllowedExteriorCells = sections[2],
	AllowedNamedInteriors = sections[2],

		IllegalLevitationCrimeEnabled = sections[3],
		IllegalLevitationSuppressInRestrictedAreas = sections[3],
		IllegalLevitationCrimeRequireWitness = sections[3],
		IllegalLevitationCrimeRequireLineOfSight = sections[3],
		IllegalLevitationCrimeRequireFacing = sections[3],
		IllegalLevitationCrimeWitnessRadius = sections[3],			
		IllegalLevitationCrimeBountyGold = sections[3],
		IllegalLevitationBounty = sections[3], -- legacy key, kept as fallback
		IllegalLevitationCrimeOncePerCell = sections[3],
		IllegalLevitationCrimeEscalationEnabled = sections[3],
		IllegalLevitationCrimeRepeatBountyGold = sections[3],
		IllegalLevitationCrimeMaxBountyGold = sections[3],

		DrainFatigueWhileLevitating = sections[4],
		StopLevitateOnZeroFatigue = sections[4],
		DrainFatigueOnlyInRestrictedAreas = sections[4],
		FatigueDrainPerSecond = sections[4],

		EnableAltitudeLimit = sections[5],
		AltitudeSoftLimit = sections[5],
		AltitudeHardLimit = sections[5],
		AltitudeSoftDrainMultiplier = sections[5],
		AltitudeSoftDownwardPressureMax = sections[5],

		AltitudeAlterationScaling = sections[6],
		AltitudeAlterationBonusMax = sections[6],
		AltitudeEncumbrancePenalty = sections[6],
		AltitudeEncumbrancePenaltyMax = sections[6],

		TarhielCancelAtHardLimit = sections[7],
		AllowTerrainCrawling = sections[7],
		TarhielRandomSoftCancel = sections[7],
		TarhielRandomSoftCancelChance = sections[7],
		LevitationFailureCooldownEnabled = sections[7],
		LevitationFailureCooldownSeconds = sections[7],

	ItemLevitationRulesEnabled = sections[8],
	PotionLevitationMinAlteration = sections[8],
	PotionLevitationMinIntelligence = sections[8],
	ScrollLevitationMinAlteration = sections[8],
	ScrollLevitationMinIntelligence = sections[8],
	PotionLevitationFailureChance = sections[8],
	ScrollLevitationFailureChance = sections[8],
	CustomSpellLevitationRulesEnabled = sections[8],
	CustomSpellLevitationMinAlteration = sections[8],
	CustomSpellLevitationMinIntelligence = sections[8],
	CustomSpellLevitationFailureChance = sections[8],
	ConstantEffectLevitationRulesEnabled = sections[8],
	ConstantEffectLevitationMinAlteration = sections[8],
	ConstantEffectLevitationMinIntelligence = sections[8],
	ConstantEffectLevitationFailureChance = sections[8],

	EnchantedItemLevitationRulesEnabled = sections[8],
	EnchantedItemLevitationMinAlteration = sections[8],
	EnchantedItemLevitationMinIntelligence = sections[8],
	EnchantedItemLevitationFailureChance = sections[8],

	ApprovedSpellLevitationRulesEnabled = sections[8],
	ApprovedSpellLevitationMinAlteration = sections[8],
	ApprovedSpellLevitationMinIntelligence = sections[8],
	ApprovedSpellLevitationFailureChance = sections[8],

	UnknownLevitationRulesEnabled = sections[8],
	UnknownLevitationMinAlteration = sections[8],
	UnknownLevitationMinIntelligence = sections[8],
	UnknownLevitationFailureChance = sections[8],

	LevitationItemFailureSkillReduction = sections[8],
	PotionLevitationPowerMultiplier = sections[8],
	ScrollLevitationPowerMultiplier = sections[8],
	CustomPotionLevitationPowerMultiplier = sections[8],
	CustomSpellLevitationPowerMultiplier = sections[8],
	ApprovedLevitationSpellIds = sections[8],
	VendorLevitationItemThinningEnabled = sections[9],
	VendorLevitationItemMaxPotions = sections[9],
	VendorLevitationItemMaxScrolls = sections[9],
	VendorLevitationItemKeepAtLeast = sections[9],

	VendorLevitateSuppressionEnabled = sections[9],
	VendorLevitateVanillaNpcIds = sections[9],

	WhitelistedSpellIds = sections[10],
	WhitelistedItemIds = sections[10],
	ShowAltitudePressureMessages = sections[10],
	Debug = sections[10],
}


function M.get(key, fallback)
    if NON_CONFIGURABLE_DEFAULTS[key] ~= nil then
        return NON_CONFIGURABLE_DEFAULTS[key]
    end

    local section = sectionByKey[key]
    if section then
        local v = section:get(key)
        if v ~= nil then
            return v
        end
    end

    if runtimeOverrides[key] ~= nil then
        return runtimeOverrides[key]
    end

    for _, section in ipairs(sections) do
        local v = section:get(key)
        if v ~= nil then
            return v
        end
    end

    return fallback
end

function M.set(key, value)
    runtimeOverrides[key] = value

    local section = sectionByKey[key]

    if not section then
        debug.traceback()
        return
    end

    section:set(key, value)
end

function M.getStored(key, fallback)
    local section = sectionByKey[key]

    if section then
        local v = section:get(key)
        if v ~= nil then
            return v
        end
    else
        for _, anySection in ipairs(sections) do
            local v = anySection:get(key)
            if v ~= nil then
                return v
            end
        end
    end

    return fallback
end

function M.setStored(key, value)
    local section = sectionByKey[key]

    if not section then
        debug.traceback()
        return
    end

    section:set(key, value)
end

local function trim(s)
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

function M.parseCsvSet(value)
    local result = {}
    if not value or value == '' then
        return result
    end

    for part in string.gmatch(value, '([^,]+)') do
        local v = trim(part)
        if v ~= '' then
            result[string.lower(v)] = true
        end
    end

    return result
end

local DEFAULT_PRESET_VALUES = {
    Enabled = true,
    PresetProfile = 'Default',
    AllowLevitationFromPotions = true,
    AllowLevitationFromScrolls = true,
    AllowLevitationFromSpells = true,
    AllowLevitationFromEnchantedItems = true,
    AllowLevitationFromConstantEffect = true,
    AllowLevitationFromUnknownSources = true,
    IncludeConstantEffectLevitation = true,
    ExcludedCells = '',
    RestrictionPolicyMode = 'ExtYesIntNo',
    RestrictExteriorCities = true,
    RestrictedExteriorRegions = '',
    RestrictedNamedInteriors = '',
    AllowedExteriorRegions = '',
    AllowedNamedInteriors = '',
    IllegalLevitationCrimeEnabled = true,
	IllegalLevitationSuppressInRestrictedAreas = true,
    IllegalLevitationCrimeRequireWitness = true,
    IllegalLevitationCrimeRequireLineOfSight = true,
    IllegalLevitationCrimeRequireFacing = false,
    IllegalLevitationCrimeWitnessRadius = 1000,
    IllegalLevitationCrimeBountyGold = 250,
    IllegalLevitationCrimeEscalationEnabled = true,
    IllegalLevitationCrimeRepeatBountyGold = 150,
    IllegalLevitationCrimeMaxBountyGold = 1000,
    IllegalLevitationCrimeOncePerCell = true,
    DrainFatigueWhileLevitating = true,
    StopLevitateOnZeroFatigue = true,
    DrainFatigueOnlyInRestrictedAreas = false,
    FatigueDrainPerSecond = 6,
    EnableAltitudeLimit = true,
    AltitudeSoftLimit = 300,
    AltitudeHardLimit = 600,
    AltitudeSoftDrainMultiplier = 4,
    AltitudeSoftDownwardPressureMax = 300,
    AltitudeAlterationScaling = true,
    AltitudeAlterationBonusMax = 400,
    AltitudeEncumbrancePenalty = true,
    AltitudeEncumbrancePenaltyMax = 300,
    TarhielCancelAtHardLimit = false,
    AllowTerrainCrawling = true,
    TarhielRandomSoftCancel = false,
    TarhielRandomSoftCancelChance = 1,
    LevitationFailureCooldownEnabled = true,
    LevitationFailureCooldownSeconds = 5,
    ItemLevitationRulesEnabled = true,
    LevitationItemFailureSkillReduction = true,
    PotionLevitationMinAlteration = 25,
    PotionLevitationMinIntelligence = 35,
    PotionLevitationFailureChance = 25,
    PotionLevitationPowerMultiplier = 0.5,
    CustomPotionLevitationPowerMultiplier = 0.25,
    ScrollLevitationMinAlteration = 35,
    ScrollLevitationMinIntelligence = 50,
    ScrollLevitationFailureChance = 15,
    ScrollLevitationPowerMultiplier = 0.7,
    ApprovedSpellLevitationRulesEnabled = true,
    ApprovedSpellLevitationMinAlteration = 30,
    ApprovedSpellLevitationMinIntelligence = 35,
    ApprovedSpellLevitationFailureChance = 0,
    ApprovedLevitationSpellIds = '',
    CustomSpellLevitationRulesEnabled = true,
    CustomSpellLevitationMinAlteration = 40,
    CustomSpellLevitationMinIntelligence = 50,
    CustomSpellLevitationFailureChance = 20,
    CustomSpellLevitationPowerMultiplier = 0.35,
    EnchantedItemLevitationRulesEnabled = true,
    EnchantedItemLevitationMinAlteration = 35,
    EnchantedItemLevitationMinIntelligence = 45,
    EnchantedItemLevitationFailureChance = 15,
    ConstantEffectLevitationRulesEnabled = false,
    ConstantEffectLevitationMinAlteration = 60,
    ConstantEffectLevitationMinIntelligence = 70,
    ConstantEffectLevitationFailureChance = 0,
    UnknownLevitationRulesEnabled = false,
    UnknownLevitationMinAlteration = 50,
    UnknownLevitationMinIntelligence = 60,
    UnknownLevitationFailureChance = 50,
    VendorLevitateSuppressionEnabled = true,
    VendorLevitateVanillaNpcIds = '',
    VendorLevitationItemThinningEnabled = true,
    VendorLevitationItemMaxPotions = 1,
    VendorLevitationItemMaxScrolls = 1,
    VendorLevitationItemKeepAtLeast = 1,
    WhitelistedSpellIds = '',
    WhitelistedItemIds = '',
    ShowAltitudePressureMessages = false,
    Debug = false,
}

function M.applyPreset(profile)
    if profile == 'Default' then
        return DEFAULT_PRESET_VALUES
    end

    if profile == 'Vanilla' then
        return {
            -- General
            Enabled = true,
            AllowLevitationFromPotions = true,
            AllowLevitationFromScrolls = true,
            AllowLevitationFromSpells = true,
            AllowLevitationFromEnchantedItems = true,
            AllowLevitationFromConstantEffect = true,
            AllowLevitationFromUnknownSources = true,
            IncludeConstantEffectLevitation = true,

            -- Restriction policy
			RestrictionPolicyMode = 'ExtYesIntNo',
			RestrictExteriorCities = false,

            -- Crime
            IllegalLevitationCrimeEnabled = false,		
			IllegalLevitationSuppressInRestrictedAreas = false,
			IllegalLevitationCrimeRequireWitness = true,
			IllegalLevitationCrimeRequireLineOfSight = true,
			IllegalLevitationCrimeRequireFacing = true,			
			IllegalLevitationCrimeWitnessRadius = 500,			
            IllegalLevitationCrimeBountyGold = 250,
            IllegalLevitationCrimeEscalationEnabled = false,
            IllegalLevitationCrimeRepeatBountyGold = 150,
            IllegalLevitationCrimeMaxBountyGold = 1000,
            IllegalLevitationCrimeOncePerCell = true,

            -- Fatigue
            DrainFatigueWhileLevitating = false,
            StopLevitateOnZeroFatigue = false,
            DrainFatigueOnlyInRestrictedAreas = false,
            FatigueDrainPerSecond = 0,

            -- Altitude
            EnableAltitudeLimit = true,
            AltitudeSoftLimit = 500,
            AltitudeHardLimit = 1000,
            AltitudeSoftDrainMultiplier = 0.5,
            AltitudeSoftDownwardPressureMax = 150,

            -- Scaling
            AltitudeAlterationScaling = true,
            AltitudeAlterationBonusMax = 500,
            AltitudeEncumbrancePenalty = false,
            AltitudeEncumbrancePenaltyMax = 200,

            -- Tarhiel mode
            TarhielCancelAtHardLimit = false,
            AllowTerrainCrawling = true,
            TarhielRandomSoftCancel = false,
            TarhielRandomSoftCancelChance = 1,
            LevitationFailureCooldownEnabled = false,
            LevitationFailureCooldownSeconds = 5,

            -- Item/source rules
            ItemLevitationRulesEnabled = false,

            PotionLevitationMinAlteration = 15,
            PotionLevitationMinIntelligence = 25,
            PotionLevitationFailureChance = 15,
            PotionLevitationPowerMultiplier = 1.0,

            ScrollLevitationMinAlteration = 25,
            ScrollLevitationMinIntelligence = 40,
            ScrollLevitationFailureChance = 5,
            ScrollLevitationPowerMultiplier = 1.0,

            CustomSpellLevitationRulesEnabled = false,
            CustomSpellLevitationMinAlteration = 30,
            CustomSpellLevitationMinIntelligence = 40,
            CustomSpellLevitationFailureChance = 10,
            CustomSpellLevitationPowerMultiplier = 1.0,

            CustomPotionLevitationPowerMultiplier = 1.0,

            ConstantEffectLevitationRulesEnabled = false,
            ConstantEffectLevitationMinAlteration = 50,
            ConstantEffectLevitationMinIntelligence = 60,
            ConstantEffectLevitationFailureChance = 0,

            EnchantedItemLevitationRulesEnabled = false,
            EnchantedItemLevitationMinAlteration = 25,
            EnchantedItemLevitationMinIntelligence = 35,
            EnchantedItemLevitationFailureChance = 5,

            ApprovedSpellLevitationRulesEnabled = false,
            ApprovedSpellLevitationMinAlteration = 20,
            ApprovedSpellLevitationMinIntelligence = 25,
            ApprovedSpellLevitationFailureChance = 0,

            UnknownLevitationRulesEnabled = false,
            UnknownLevitationMinAlteration = 40,
            UnknownLevitationMinIntelligence = 50,
            UnknownLevitationFailureChance = 40,

            LevitationItemFailureSkillReduction = false,

            -- Vendors
            VendorLevitationItemThinningEnabled = false,
            VendorLevitationItemMaxPotions = 99,
            VendorLevitationItemMaxScrolls = 99,
            VendorLevitationItemKeepAtLeast = 1,

            VendorLevitateSuppressionEnabled = false,

            -- Compatibility / advanced
            ShowAltitudePressureMessages = false,
            Debug = false,
        }

    elseif profile == 'Regulated' then
        return {
            -- General
            Enabled = true,
            AllowLevitationFromPotions = true,
            AllowLevitationFromScrolls = true,
            AllowLevitationFromSpells = true,
            AllowLevitationFromEnchantedItems = true,
            AllowLevitationFromConstantEffect = false,
            AllowLevitationFromUnknownSources = false,
            IncludeConstantEffectLevitation = false,

            -- Restriction policy
			RestrictionPolicyMode = 'ExtYesIntNo',
			RestrictExteriorCities = true,

            -- Crime
            IllegalLevitationCrimeEnabled = true,
			IllegalLevitationSuppressInRestrictedAreas = true,
			IllegalLevitationCrimeRequireWitness = true,
			IllegalLevitationCrimeRequireLineOfSight = true,			
			IllegalLevitationCrimeRequireFacing = false,
			IllegalLevitationCrimeWitnessRadius = 1000,			
            IllegalLevitationCrimeBountyGold = 250,
            IllegalLevitationCrimeEscalationEnabled = true,
            IllegalLevitationCrimeRepeatBountyGold = 150,
            IllegalLevitationCrimeMaxBountyGold = 1500,
            IllegalLevitationCrimeOncePerCell = true,

            -- Fatigue
            DrainFatigueWhileLevitating = true,
            StopLevitateOnZeroFatigue = true,
            DrainFatigueOnlyInRestrictedAreas = false,
            FatigueDrainPerSecond = 6,

            -- Altitude
            EnableAltitudeLimit = true,
            AltitudeSoftLimit = 300,
            AltitudeHardLimit = 600,
            AltitudeSoftDrainMultiplier = 4.0,
            AltitudeSoftDownwardPressureMax = 250,

            -- Scaling
            AltitudeAlterationScaling = true,
            AltitudeAlterationBonusMax = 400,
            AltitudeEncumbrancePenalty = true,
            AltitudeEncumbrancePenaltyMax = 300,

            -- Tarhiel mode
            TarhielCancelAtHardLimit = false,
            AllowTerrainCrawling = true,
            TarhielRandomSoftCancel = true,
            TarhielRandomSoftCancelChance = 5,
            LevitationFailureCooldownEnabled = true,
            LevitationFailureCooldownSeconds = 6,

            -- Item/source rules
            ItemLevitationRulesEnabled = true,

            PotionLevitationMinAlteration = 25,
            PotionLevitationMinIntelligence = 35,
            PotionLevitationFailureChance = 25,
            PotionLevitationPowerMultiplier = 0.65,

            ScrollLevitationMinAlteration = 35,
            ScrollLevitationMinIntelligence = 50,
            ScrollLevitationFailureChance = 15,
            ScrollLevitationPowerMultiplier = 0.8,

            CustomSpellLevitationRulesEnabled = true,
            CustomSpellLevitationMinAlteration = 40,
            CustomSpellLevitationMinIntelligence = 50,
            CustomSpellLevitationFailureChance = 20,
            CustomSpellLevitationPowerMultiplier = 0.45,

            CustomPotionLevitationPowerMultiplier = 0.4,

            ConstantEffectLevitationRulesEnabled = true,
            ConstantEffectLevitationMinAlteration = 60,
            ConstantEffectLevitationMinIntelligence = 70,
            ConstantEffectLevitationFailureChance = 0,

            EnchantedItemLevitationRulesEnabled = true,
            EnchantedItemLevitationMinAlteration = 35,
            EnchantedItemLevitationMinIntelligence = 45,
            EnchantedItemLevitationFailureChance = 15,

            ApprovedSpellLevitationRulesEnabled = true,
            ApprovedSpellLevitationMinAlteration = 30,
            ApprovedSpellLevitationMinIntelligence = 35,
            ApprovedSpellLevitationFailureChance = 0,

            UnknownLevitationRulesEnabled = false,
            UnknownLevitationMinAlteration = 50,
            UnknownLevitationMinIntelligence = 60,
            UnknownLevitationFailureChance = 50,

            LevitationItemFailureSkillReduction = true,

            -- Vendors
            VendorLevitationItemThinningEnabled = true,
            VendorLevitationItemMaxPotions = 2,
            VendorLevitationItemMaxScrolls = 2,
            VendorLevitationItemKeepAtLeast = 1,

            VendorLevitateSuppressionEnabled = true,

            -- Compatibility / advanced
            ShowAltitudePressureMessages = false,
            Debug = false,
        }

    elseif profile == 'Enforced' then
        return {
            -- General
            Enabled = true,
            AllowLevitationFromPotions = true,
            AllowLevitationFromScrolls = true,
            AllowLevitationFromSpells = true,
            AllowLevitationFromEnchantedItems = false,
            AllowLevitationFromConstantEffect = false,
            AllowLevitationFromUnknownSources = false,
            IncludeConstantEffectLevitation = false,

            -- Restriction policy
			RestrictionPolicyMode = 'ExtNoIntNo',
			RestrictExteriorCities = true,

            -- Crime
            IllegalLevitationCrimeEnabled = true,
			IllegalLevitationSuppressInRestrictedAreas = true,
			IllegalLevitationCrimeRequireWitness = true,
			IllegalLevitationCrimeRequireLineOfSight = true,
			IllegalLevitationCrimeRequireFacing = false,			
			IllegalLevitationCrimeWitnessRadius = 1500,			
            IllegalLevitationCrimeBountyGold = 500,
            IllegalLevitationCrimeEscalationEnabled = true,
            IllegalLevitationCrimeRepeatBountyGold = 300,
            IllegalLevitationCrimeMaxBountyGold = 5000,
            IllegalLevitationCrimeOncePerCell = false,

            -- Fatigue
            DrainFatigueWhileLevitating = true,
            StopLevitateOnZeroFatigue = true,
            DrainFatigueOnlyInRestrictedAreas = false,
            FatigueDrainPerSecond = 10,

            -- Altitude
            EnableAltitudeLimit = true,
            AltitudeSoftLimit = 200,
            AltitudeHardLimit = 400,
            AltitudeSoftDrainMultiplier = 8.0,
            AltitudeSoftDownwardPressureMax = 350,

            -- Scaling
            AltitudeAlterationScaling = true,
            AltitudeAlterationBonusMax = 250,
            AltitudeEncumbrancePenalty = true,
            AltitudeEncumbrancePenaltyMax = 500,

            -- Tarhiel mode
            TarhielCancelAtHardLimit = false,
            AllowTerrainCrawling = false,
            TarhielRandomSoftCancel = true,
            TarhielRandomSoftCancelChance = 12,
            LevitationFailureCooldownEnabled = true,
            LevitationFailureCooldownSeconds = 12,

            -- Item/source rules
            ItemLevitationRulesEnabled = true,

            PotionLevitationMinAlteration = 35,
            PotionLevitationMinIntelligence = 45,
            PotionLevitationFailureChance = 35,
            PotionLevitationPowerMultiplier = 0.5,

            ScrollLevitationMinAlteration = 45,
            ScrollLevitationMinIntelligence = 60,
            ScrollLevitationFailureChance = 25,
            ScrollLevitationPowerMultiplier = 0.7,

            CustomSpellLevitationRulesEnabled = true,
            CustomSpellLevitationMinAlteration = 50,
            CustomSpellLevitationMinIntelligence = 60,
            CustomSpellLevitationFailureChance = 30,
            CustomSpellLevitationPowerMultiplier = 0.35,

            CustomPotionLevitationPowerMultiplier = 0.25,

            ConstantEffectLevitationRulesEnabled = true,
            ConstantEffectLevitationMinAlteration = 70,
            ConstantEffectLevitationMinIntelligence = 80,
            ConstantEffectLevitationFailureChance = 10,

            EnchantedItemLevitationRulesEnabled = true,
            EnchantedItemLevitationMinAlteration = 45,
            EnchantedItemLevitationMinIntelligence = 55,
            EnchantedItemLevitationFailureChance = 25,

            ApprovedSpellLevitationRulesEnabled = true,
            ApprovedSpellLevitationMinAlteration = 40,
            ApprovedSpellLevitationMinIntelligence = 45,
            ApprovedSpellLevitationFailureChance = 10,

            UnknownLevitationRulesEnabled = true,
            UnknownLevitationMinAlteration = 60,
            UnknownLevitationMinIntelligence = 70,
            UnknownLevitationFailureChance = 60,

            LevitationItemFailureSkillReduction = true,

            -- Vendors
            VendorLevitationItemThinningEnabled = true,
            VendorLevitationItemMaxPotions = 1,
            VendorLevitationItemMaxScrolls = 1,
            VendorLevitationItemKeepAtLeast = 0,

            VendorLevitateSuppressionEnabled = true,

            -- Compatibility / advanced
            ShowAltitudePressureMessages = false,
            Debug = false,
        }
    end

    return nil
end

function M.clearOverrides()
    runtimeOverrides = {}
end

return M