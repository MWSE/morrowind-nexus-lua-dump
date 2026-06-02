local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local async = require('openmw.async')
local nearby = require('openmw.nearby')
local util = require('openmw.util')

local Actor = types.Actor
local l10n = core.l10n('GravityEnforcementAct', 'en')
local settings = require('scripts.gravity_enforcement_act.settings')
local crime = require('scripts.gravity_enforcement_act.crime')

local DEBUG_SPAM = false
local DEBUG_VENDOR_SPAM = false

local levitateStartZ = nil
local levitateLowestGroundZ = nil
local exhausted = false
local messageCooldowns = {}
local softPushTimer = 0
local softPushVelocity = 0
local levitationCooldownTimer = 0
local vendorConfigTimer = 0
local itemRuleHandledByActiveSpellId = {}
local lastLevitateDurationLeft = 0
local levitationWasActive = false
local pendingMagickaRestore = nil
local pendingMagickaRestoreTimer = 0
local knownCustomLevitationSpellIds = {}
local customLevitationSpellScanInitialized = false
local pendingCustomLevitationSpellWarning = false
local knownLevitationSpellEffectsById = {}
local applyFatigueDrain
local suppressAllLevitate
local isWhitelistedSource
local isRestrictedCell

local GENERAL_SECTION_KEY = 'SettingsPlayerGravityEnforcementAct_General'
local RESTRICTION_SECTION_KEY = 'SettingsPlayerGravityEnforcementAct_Restriction'
local ITEMS_SECTION_KEY = 'SettingsPlayerGravityEnforcementAct_Items'
local CRIME_SECTION_KEY = 'SettingsPlayerGravityEnforcementAct_Crime'
local FATIGUE_SECTION_KEY = 'SettingsPlayerGravityEnforcementAct_Fatigue'
local ALTITUDE_SECTION_KEY = 'SettingsPlayerGravityEnforcementAct_Altitude'
local SCALING_SECTION_KEY = 'SettingsPlayerGravityEnforcementAct_Scaling'
local TARHIEL_SECTION_KEY = 'SettingsPlayerGravityEnforcementAct_Tarhiel'
local VENDORS_SECTION_KEY = 'SettingsPlayerGravityEnforcementAct_Vendors'

local function setRendererArgument(sectionKey, key, disabled)
    if I.Settings and I.Settings.updateRendererArgument then
        I.Settings.updateRendererArgument(sectionKey, key, { disabled = disabled })
    end
end

local function updateGeneralUi()
    local allowCE = settings.getStored and settings.getStored('AllowLevitationFromConstantEffect', true)
        or settings.get('AllowLevitationFromConstantEffect', true)

    local crimeEnabled = settings.get('IllegalLevitationCrimeEnabled', true)
    local fatigueEnabled = settings.get('DrainFatigueWhileLevitating', true)
    local altitudeEnabled = settings.get('EnableAltitudeLimit', true)
    local alterationScaling = settings.get('AltitudeAlterationScaling', true)
    local encumbranceScaling = settings.get('AltitudeEncumbrancePenalty', true)
    local itemRulesEnabled = settings.get('ItemLevitationRulesEnabled', true)
    local vendorSuppressionEnabled = settings.get('VendorLevitateSuppressionEnabled', true)
    local vendorThinningEnabled = settings.get('VendorLevitationItemThinningEnabled', true)
    local randomSoftCancel = settings.get('TarhielRandomSoftCancel', false)
    local cooldownEnabled = settings.get('LevitationFailureCooldownEnabled', true)

    if not allowCE and settings.get('IncludeConstantEffectLevitation', true) ~= false then
        settings.set('IncludeConstantEffectLevitation', false)
    end

    -- General / CE
    setRendererArgument(GENERAL_SECTION_KEY, 'IncludeConstantEffectLevitation', not allowCE)

    -- Crime section
    local disableCrime = not crimeEnabled
    for _, key in ipairs({
        'IllegalLevitationCrimeRequireWitness',
        'IllegalLevitationCrimeRequireLineOfSight',
        'IllegalLevitationCrimeRequireFacing',
        'IllegalLevitationCrimeWitnessRadius',
        'IllegalLevitationCrimeBountyGold',
        'IllegalLevitationCrimeEscalationEnabled',
        'IllegalLevitationCrimeRepeatBountyGold',
        'IllegalLevitationCrimeMaxBountyGold',
        'IllegalLevitationCrimeOncePerCell',
    }) do
        setRendererArgument(CRIME_SECTION_KEY, key, disableCrime)
    end

    -- Fatigue section
    for _, key in ipairs({
        'StopLevitateOnZeroFatigue',
        'DrainFatigueOnlyInRestrictedAreas',
        'FatigueDrainPerSecond',
    }) do
        setRendererArgument(FATIGUE_SECTION_KEY, key, not fatigueEnabled)
    end

    -- Altitude section
    for _, key in ipairs({
        'AltitudeSoftLimit',
        'AltitudeHardLimit',
        'AltitudeSoftDrainMultiplier',
        'AltitudeSoftDownwardPressureMax',
    }) do
        setRendererArgument(ALTITUDE_SECTION_KEY, key, not altitudeEnabled)
    end

    -- Scaling section
    setRendererArgument(SCALING_SECTION_KEY, 'AltitudeAlterationScaling', not altitudeEnabled)
    setRendererArgument(SCALING_SECTION_KEY, 'AltitudeAlterationBonusMax', not altitudeEnabled or not alterationScaling)

    setRendererArgument(SCALING_SECTION_KEY, 'AltitudeEncumbrancePenalty', not altitudeEnabled)
    setRendererArgument(SCALING_SECTION_KEY, 'AltitudeEncumbrancePenaltyMax', not altitudeEnabled or not encumbranceScaling)

    -- Tarhiel section
    setRendererArgument(TARHIEL_SECTION_KEY, 'AllowTerrainCrawling', not altitudeEnabled)
    setRendererArgument(TARHIEL_SECTION_KEY, 'TarhielRandomSoftCancel', not altitudeEnabled)
    setRendererArgument(TARHIEL_SECTION_KEY, 'TarhielRandomSoftCancelChance', not altitudeEnabled or not randomSoftCancel)
    setRendererArgument(TARHIEL_SECTION_KEY, 'LevitationFailureCooldownSeconds', not cooldownEnabled)

    -- Item/source rules section
    for _, key in ipairs({
        'PotionLevitationMinAlteration',
        'PotionLevitationMinIntelligence',
        'PotionLevitationFailureChance',
        'PotionLevitationPowerMultiplier',

        'ScrollLevitationMinAlteration',
        'ScrollLevitationMinIntelligence',
        'ScrollLevitationFailureChance',
        'ScrollLevitationPowerMultiplier',

        'CustomSpellLevitationRulesEnabled',
        'CustomSpellLevitationMinAlteration',
        'CustomSpellLevitationMinIntelligence',
        'CustomSpellLevitationFailureChance',
        'CustomSpellLevitationPowerMultiplier',

        'CustomPotionLevitationPowerMultiplier',

        'ConstantEffectLevitationRulesEnabled',
        'ConstantEffectLevitationMinAlteration',
        'ConstantEffectLevitationMinIntelligence',
        'ConstantEffectLevitationFailureChance',

        'EnchantedItemLevitationRulesEnabled',
        'EnchantedItemLevitationMinAlteration',
        'EnchantedItemLevitationMinIntelligence',
        'EnchantedItemLevitationFailureChance',

        'ApprovedSpellLevitationRulesEnabled',
        'ApprovedSpellLevitationMinAlteration',
        'ApprovedSpellLevitationMinIntelligence',
        'ApprovedSpellLevitationFailureChance',

        'UnknownLevitationRulesEnabled',
        'UnknownLevitationMinAlteration',
        'UnknownLevitationMinIntelligence',
        'UnknownLevitationFailureChance',

        'LevitationItemFailureSkillReduction',
        'ApprovedLevitationSpellIds',
    }) do
        setRendererArgument(ITEMS_SECTION_KEY, key, not itemRulesEnabled)
    end

    if itemRulesEnabled then
        local disableCEItems = not allowCE
        setRendererArgument(ITEMS_SECTION_KEY, 'ConstantEffectLevitationRulesEnabled', disableCEItems)
        setRendererArgument(ITEMS_SECTION_KEY, 'ConstantEffectLevitationMinAlteration', disableCEItems)
        setRendererArgument(ITEMS_SECTION_KEY, 'ConstantEffectLevitationMinIntelligence', disableCEItems)
        setRendererArgument(ITEMS_SECTION_KEY, 'ConstantEffectLevitationFailureChance', disableCEItems)
    end

    -- Vendor section
	for _, key in ipairs({
		'VendorLevitateVanillaNpcIds',
	}) do
		setRendererArgument(VENDORS_SECTION_KEY, key, not vendorSuppressionEnabled)
	end

    -- Vendor item thinning lives in the Vendor section.
    for _, key in ipairs({
        'VendorLevitationItemMaxPotions',
        'VendorLevitationItemMaxScrolls',
        'VendorLevitationItemKeepAtLeast',
    }) do
        setRendererArgument(VENDORS_SECTION_KEY, key, not vendorThinningEnabled)
    end
end

local function setRestrictionPolicyRendererArgument(key, disabled)
    if I.Settings and I.Settings.updateRendererArgument then
        I.Settings.updateRendererArgument(RESTRICTION_SECTION_KEY, key, { disabled = disabled })
    end
end

local function updateRestrictionPolicyUi()
    local mode = settings.getStored and settings.getStored('RestrictionPolicyMode', 'ExtYesIntYes')
        or settings.get('RestrictionPolicyMode', 'ExtYesIntYes')

    local disableRestrictedExteriors = false
    local disableRestrictedInteriors = false
    local disableAllowedExteriors = false
    local disableAllowedInteriors = false

    if mode == 'ExtYesIntYes' then
        disableRestrictedExteriors = false
        disableRestrictedInteriors = false
        disableAllowedExteriors = true
        disableAllowedInteriors = true

    elseif mode == 'ExtYesIntNo' then
        disableRestrictedExteriors = false
        disableRestrictedInteriors = true
        disableAllowedExteriors = true
        disableAllowedInteriors = false

    elseif mode == 'ExtNoIntYes' then
        disableRestrictedExteriors = true
        disableRestrictedInteriors = false
        disableAllowedExteriors = false
        disableAllowedInteriors = true

    elseif mode == 'ExtNoIntNo' then
        disableRestrictedExteriors = true
        disableRestrictedInteriors = true
        disableAllowedExteriors = false
        disableAllowedInteriors = false
    end

    setRestrictionPolicyRendererArgument('RestrictedExteriorRegions', disableRestrictedExteriors)
    setRestrictionPolicyRendererArgument('RestrictedNamedInteriors', disableRestrictedInteriors)
    setRestrictionPolicyRendererArgument('AllowedExteriorRegions', disableAllowedExteriors)
    setRestrictionPolicyRendererArgument('AllowedNamedInteriors', disableAllowedInteriors)
	
	local exteriorAllowed =
		mode == 'ExtYesIntYes'
		or mode == 'ExtYesIntNo'

	setRestrictionPolicyRendererArgument('RestrictExteriorCities', not exteriorAllowed)	
end

local lastSettingsUiSnapshot = nil

local function getSettingsUiSnapshot()
    return table.concat({
        tostring(settings.get('AllowLevitationFromConstantEffect', true)),
        tostring(settings.get('IllegalLevitationCrimeEnabled', true)),
        tostring(settings.get('DrainFatigueWhileLevitating', true)),
        tostring(settings.get('EnableAltitudeLimit', true)),
        tostring(settings.get('AltitudeAlterationScaling', true)),
        tostring(settings.get('AltitudeEncumbrancePenalty', true)),
        tostring(settings.get('ItemLevitationRulesEnabled', true)),
        tostring(settings.get('VendorLevitateSuppressionEnabled', true)),
        tostring(settings.get('VendorLevitationItemThinningEnabled', true)),
        tostring(settings.get('TarhielRandomSoftCancel', false)),
        tostring(settings.get('LevitationFailureCooldownEnabled', true)),
        tostring(settings.get('RestrictionPolicyMode', 'ExtYesIntYes')),
    }, '|')
end

local function updateSettingsUiIfNeeded()
    if I.UI.getMode() == nil then
        return
    end

    local snapshot = getSettingsUiSnapshot()

    if snapshot == lastSettingsUiSnapshot then
        return
    end

    lastSettingsUiSnapshot = snapshot

    updateGeneralUi()
    updateRestrictionPolicyUi()
end

local function debugLog(msg)
    if settings.get('Debug', false) then
        print('[GravityEnforcementAct] ' .. msg)
    end
end

local function debugSpam(msg)
    if DEBUG_SPAM then
        debugLog(msg)
    end
end


local function showCooldownMessage(key, message, cooldown)
    cooldown = cooldown or 2.0

    if messageCooldowns[key] and messageCooldowns[key] > 0 then
        return
    end

    ui.showMessage(message)
    messageCooldowns[key] = cooldown
end

local function applyPreset(profile)
    local presetValues = settings.applyPreset(profile)
    if not presetValues then
        return
    end

    for k, v in pairs(presetValues) do
        settings.set(k, v)
    end
	lastSettingsUiSnapshot = nil

    -- Keep runtime overrides for the applied values so the gameplay logic
    -- sees the new preset immediately during the current game session.
    if profile == 'Default' then
        ui.showMessage("Settings reset to Default")
    else
        ui.showMessage("Preset applied: " .. profile)
    end
end

local lastPresetProfile = nil

local function presetMatchesCurrentSettings(profile)
    local presetValues = settings.applyPreset(profile)
    if not presetValues then
        return true
    end

    for k, v in pairs(presetValues) do
        if settings.get(k) ~= v then
            return false
        end
    end

    return true
end

local function switchPresetToCustom()
    if settings.setStored then
        settings.setStored('PresetProfile', 'Custom')
    else
        settings.set('PresetProfile', 'Custom')
    end

    lastPresetProfile = 'Custom'
    ui.showMessage("Preset changed to Custom")
end

local function applyPresetSelection()
    local getStored = settings.getStored or settings.get
    local profile = getStored('PresetProfile', 'Custom')

    -- First run only initializes the watcher. This prevents a saved preset
    -- from overwriting later manual tweaks every time the save loads.
    if lastPresetProfile == nil then
        lastPresetProfile = profile
        return
    end

    -- A changed selector means the user explicitly picked a preset. Apply it
    -- first, then future manual changes can be detected as Custom.
    if profile ~= lastPresetProfile then
        lastPresetProfile = profile

		if profile ~= 'Custom' then
			applyPreset(profile)
		else
			ui.showMessage("Preset changed to Custom")
		end

        return
    end

    -- If the selector still points at a preset, but any value controlled by
    -- that preset no longer matches, the settings are now custom.
    if profile ~= 'Custom' and not presetMatchesCurrentSettings(profile) then
        switchPresetToCustom()
        return
    end
end

local function startLevitationCooldown()
    if not settings.get('LevitationFailureCooldownEnabled', true) then
        return
    end

    levitationCooldownTimer = math.max(
        levitationCooldownTimer,
        settings.get('LevitationFailureCooldownSeconds', 5)
    )
end

local function getCellInfo()
    local cell = self.cell
    if not cell then
        return nil
    end

    return {
        obj = cell,
        id = string.lower(cell.id or ''),
        name = string.lower(cell.name or ''),
        region = string.lower(cell.region or ''),
        isExterior = cell.isExterior == true,
    }
end

local function isExcludedCell(cellInfo)
    if not cellInfo then
        return false
    end

    local excludedCells = settings.parseCsvSet(settings.get('ExcludedCells', ''))

    return excludedCells[cellInfo.id] == true
        or excludedCells[cellInfo.name] == true
end

local function actorHasLineOfSightToPlayer(actor)
    if not actor or not actor.position or not self.position then
        return false
    end

    local playerBox = self:getBoundingBox()
    local actorBox = actor:getBoundingBox()

    if not playerBox or not actorBox then
        return false
    end

    local playerCenter = playerBox.center
    local actorCenter = actorBox.center

    local castResult = nearby.castRay(actorCenter, playerCenter, {
        collisionType = nearby.COLLISION_TYPE.AnyPhysical,
        ignore = actor,
    })

    if castResult.hitObject ~= nil and castResult.hitObject.id == self.id then
        return true
    end

    local actorHead = actorBox.center + util.vector3(0, 0, actorBox.halfSize.z)
    local playerChest = playerBox.center + util.vector3(0, 0, playerBox.halfSize.z / 2)

    castResult = nearby.castRay(actorHead, playerChest, {
        collisionType = nearby.COLLISION_TYPE.AnyPhysical,
        ignore = actor,
    })

    if castResult.hitObject ~= nil and castResult.hitObject.id == self.id then
        return true
    end

    return false
end

local function actorIsFacingPlayer(actor)
    if not actor or not actor.position or not self.position then
        return false
    end

    if not actor.rotation then
        return true
    end

    local toPlayer = self.position - actor.position
    local distance = toPlayer:length()

    if distance <= 0 then
        return true
    end

    toPlayer = toPlayer / distance

    -- OpenMW actor forward direction.
    local forward = actor.rotation * util.vector3(0, 1, 0)

    -- 0.25 = fairly generous cone, roughly 75 degrees.
    return forward:dot(toPlayer) > 0.25
end

local function hasIllegalLevitationWitness()
    if not settings.get('IllegalLevitationCrimeRequireWitness', true) then
        return true
    end

    local witnessRadius = settings.get('IllegalLevitationCrimeWitnessRadius', 1000)
    local actors = nearby.actors

    if not actors then
        debugLog('Illegal levitation not reported: nearby actor list unavailable.')
        return false
    end

    for _, actor in ipairs(actors) do

		if actor
			and actor:isValid()
			and actor.id ~= self.id
			and types.NPC.objectIsInstance(actor)
		then
            local alive = true
            local okHealth, health = pcall(function()
                return types.Actor.stats.dynamic.health(actor)
            end)

            if okHealth and health and health.current ~= nil and health.current <= 0 then
                alive = false
            end

            local hostile = false
            if types.Actor.isHostileTo then
                local okHostile, result = pcall(types.Actor.isHostileTo, actor, self)
                hostile = okHostile and result == true
            end

            local inRange = true
            if witnessRadius and witnessRadius > 0 then
                local dist = (actor.position - self.position):length()
                inRange = dist <= witnessRadius
            end

			if alive and not hostile and inRange then
				local requireLineOfSight = settings.get('IllegalLevitationCrimeRequireLineOfSight', true)
				local requireFacing = settings.get('IllegalLevitationCrimeRequireFacing', false)

				local hasLineOfSight =
					not requireLineOfSight
					or actorHasLineOfSightToPlayer(actor)

				local isFacing =
					not requireFacing
					or actorIsFacingPlayer(actor)

				if hasLineOfSight and isFacing then
					debugLog('Illegal levitation witness found: ' .. tostring(actor.recordId or actor.id or actor))
					return true
				end

				if not hasLineOfSight then
					debugSpam('Potential witness blocked by line of sight: ' .. tostring(actor.recordId or actor.id or actor))
				elseif not isFacing then
					debugSpam('Potential witness not facing player: ' .. tostring(actor.recordId or actor.id or actor))
				end
			end
        end
    end
    
    return false
end

local function getAlterationAltitudeBonus()
    if not settings.get('AltitudeAlterationScaling', true) then
        return 0
    end

    local alteration = types.NPC.stats.skills.alteration(self)
    if not alteration then
        return 0
    end

    local maxBonus = settings.get('AltitudeAlterationBonusMax', 400)
    local skill = math.max(0, math.min(100, alteration.modified or alteration.base or 0))

    return maxBonus * (skill / 100)
end

local function getEncumbranceAltitudePenalty()
    if not settings.get('AltitudeEncumbrancePenalty', true) then
        return 0
    end

    local inv = types.Actor.inventory(self)
    if not inv then
        return 0
    end

    local totalWeight = 0
    local allItems = inv:getAll()

    for _, item in ipairs(allItems) do
        local record = item.type.record(item)
        local weight = record and record.weight or 0
        totalWeight = totalWeight + (weight * (item.count or 1))
    end

    local strength = types.NPC.stats.attributes.strength(self)
    if not strength then
        return 0
    end

    local str = strength.modified or strength.base or 0
    local capacity = str * 5
    if capacity <= 0 then
        return 0
    end

    local ratio = math.max(0, math.min(1, totalWeight / capacity))
    local maxPenalty = settings.get('AltitudeEncumbrancePenaltyMax', 300)

    return maxPenalty * ratio
end

local function getLevitationMagnitudePhysicsFactor(itemPowerMultiplier)
    itemPowerMultiplier = itemPowerMultiplier or 1

    -- Item power multipliers are lower for weaker/nerfed sources.
    -- Convert that into a pressure amplifier:
    -- 1.00 -> 1.00
    -- 0.70 -> 1.30
    -- 0.50 -> 1.50
    -- 0.25 -> 1.75
    local factor = 1 + (1 - itemPowerMultiplier)

    return math.max(1.0, math.min(2.0, factor))
end

local function applyAltitudeLimit(dt, itemPowerMultiplier, effectPhysicsFactor)
    if not settings.get('EnableAltitudeLimit', true) then
        return
    end

    local pos = self.position
    if not pos then
        return
    end

	local relativeZ = nil
	local currentGroundZ = nil

	local cell = self.cell
	if cell and cell.isExterior and core.land and core.land.getHeightAt then
		local ok, groundZ = pcall(core.land.getHeightAt, pos, cell)

		if ok and groundZ then

			local baselineZ = groundZ
			local usingLiquidBaseline = false

			-- Lava meshes such as In_Lava_1024_01 are placed objects, not always cell waterLevel.
			-- If terrain probing gives a wildly different result at the moment levitation starts,
			-- trust the player's start position as the local surface baseline.
			if levitateLowestGroundZ == nil then
				local maxStartGroundDelta = 256

				if math.abs(pos.z - baselineZ) > maxStartGroundDelta then
					baselineZ = pos.z
					usingLiquidBaseline = true
				end
			end
			
			if settings.get('Debug', false) then
				self:sendEvent("GEA_debugMessage", string.format(
					"[LAVA CHECK]\ndeltaStart=%.1f\nusingLiquid=%s",
					math.abs(pos.z - baselineZ),
					tostring(usingLiquidBaseline)
				))
			end			
			
			if cell.waterLevel ~= nil then
				local liquidSurfaceZ = cell.waterLevel

				-- Use liquid baseline when the player is near the liquid surface,
				-- even if getHeightAt() returns nearby cliff terrain above/beside lava.
				local nearLiquidSurface =
					pos.z >= liquidSurfaceZ - 128
					and pos.z <= liquidSurfaceZ + 768

				if nearLiquidSurface then
					baselineZ = liquidSurfaceZ
					usingLiquidBaseline = true
				end
			end

			currentGroundZ = baselineZ
			
			if settings.get('Debug', false) then
				self:sendEvent("GEA_debugMessage", string.format(
					"[ALT DBG]\nposZ=%.1f\ngroundZ=%.1f\nbaselineZ=%.1f\nlowestZ=%.1f\nrelZ=%.1f",
					pos.z or -1,
					groundZ or -1,
					baselineZ or -1,
					levitateLowestGroundZ or -1,
					(pos.z - (levitateLowestGroundZ or baselineZ))
				))
			end			

			if usingLiquidBaseline then
				-- Non-terrain surface baseline: lava mesh / water surface.
				-- Never allow lowest-ground tracking to use lava bottom or nearby terrain.
				levitateLowestGroundZ = baselineZ
				relativeZ = pos.z - baselineZ
			else
				-- Normal exterior terrain rule.
				-- Important: do NOT lower this after levitation starts, or lava/steep terrain
				-- can poison the baseline and cause instant hard-limit failure.
				if levitateLowestGroundZ == nil then
					levitateLowestGroundZ = baselineZ
				end

				relativeZ = pos.z - levitateLowestGroundZ
			end
		end
	end

	if relativeZ == nil then
		-- Interior/fallback: old behavior.
		if levitateStartZ == nil then
			levitateStartZ = pos.z
		end

		relativeZ = pos.z - levitateStartZ
	end

	itemPowerMultiplier = itemPowerMultiplier or 1
	effectPhysicsFactor = effectPhysicsFactor or 1

	local sourceWeaknessPhysicsFactor = getLevitationMagnitudePhysicsFactor(itemPowerMultiplier)
	local magnitudePhysicsFactor = math.max(
		1.0,
		math.min(3.0, sourceWeaknessPhysicsFactor * effectPhysicsFactor)
	)

	local baseSoft = settings.get('AltitudeSoftLimit', 300)
	local baseHard = settings.get('AltitudeHardLimit', 600)

	debugSpam(string.format(
		"[ALT LIMIT] baseSoft=%.2f baseHard=%.2f multiplier=%.2f",
		baseSoft,
		baseHard,
		itemPowerMultiplier
	))

	local alterationBonus = getAlterationAltitudeBonus()
	local encumbrancePenalty = getEncumbranceAltitudePenalty()

	local softBeforeMultiplier = math.max(0, baseSoft + alterationBonus - encumbrancePenalty)
	local hardBeforeMultiplier = math.max(softBeforeMultiplier + 1, baseHard + alterationBonus - encumbrancePenalty)

	local soft = math.max(0, softBeforeMultiplier * itemPowerMultiplier)
	local hard = math.max(soft + 1, hardBeforeMultiplier * itemPowerMultiplier)

	debugSpam(string.format(
		"[ALT FINAL] softBefore=%.2f hardBefore=%.2f soft=%.2f hard=%.2f altBonus=%.2f encPenalty=%.2f",
		softBeforeMultiplier,
		hardBeforeMultiplier,
		soft,
		hard,
		alterationBonus,
		encumbrancePenalty
	))

	local localTerrainClearance = nil
	if currentGroundZ then
		localTerrainClearance = pos.z - currentGroundZ
	end

	local terrainCrawlBlocked =
		not settings.get('AllowTerrainCrawling', true)
		and localTerrainClearance ~= nil
		and localTerrainClearance < 96
		and relativeZ > hard

	if settings.get('Debug', false) then
		self:sendEvent("GEA_debugMessage", string.format(
			"[LIMIT]\nrelZ=%.1f soft=%.1f hard=%.1f",
			relativeZ or -1,
			soft or -1,
			hard or -1
		))
	end

	if relativeZ > hard then
		debugLog('Hard altitude limit reached')
		showCooldownMessage('hard_limit', "You cannot rise any higher.", 2.0)
		
		if terrainCrawlBlocked then
			showCooldownMessage('terrain_crawl_fail', "Your levitation collapses against the slope.", 2.0)
			suppressAllLevitate()
			return
		end		

		if settings.get('TarhielCancelAtHardLimit', true) then
			showCooldownMessage('hard_fail', "Your levitation collapses!", 2.0)
			suppressAllLevitate()
			return
		end

		local overshoot = relativeZ - hard
		softPushVelocity = softPushVelocity + 40
		core.sendGlobalEvent('GEA_SoftPushPlayer', {
			dz = overshoot + 24,
			clearance = 8
		})

		-- Do NOT return here.
		-- Hard-limit pushback should still continue into the soft-limit logic below,
		-- so Tarhiel random failure, soft fatigue drain, and pressure still apply.
	end

	if relativeZ <= soft then
		softPushVelocity = 0
		applyFatigueDrain(dt, 1)
		return
	end
		
	if relativeZ > soft then
		local factor = (relativeZ - soft) / math.max(1, (hard - soft))
		factor = math.max(0, math.min(1, factor))

		if settings.get('TarhielRandomSoftCancel', false) then
			local baseChancePerSecond = settings.get('TarhielRandomSoftCancelChance', 1) / 100

			-- factor is already 0 at soft limit and 1 at hard limit.
			-- Square it so failure ramps gently at first, then more near hard limit.
			local scaledFactor = factor * factor

			-- Respect the UI value: altitude only adds a soft proportional boost.
			local chancePerSecond =
				(baseChancePerSecond + (baseChancePerSecond * (1 - baseChancePerSecond) * 0.25 * scaledFactor))
				* magnitudePhysicsFactor

			if math.random() < chancePerSecond * dt then
				debugLog('Tarhiel soft-limit scaled random levitation failure')
				showCooldownMessage('soft_fail', "Your levitation suddenly fails.", 2.0)
				suppressAllLevitate()
				return
			end
		end	

		local softDrainMult = settings.get('AltitudeSoftDrainMultiplier', 8)
		local curve = factor * factor
		local extraMultiplier = (1 + (curve * softDrainMult)) * magnitudePhysicsFactor

		debugSpam(string.format(
			"Soft altitude pressure: relZ=%.2f soft=%.2f hard=%.2f factor=%.3f curve=%.3f magnitudePhysicsFactor=%.2f extraMult=%.2f",
			relativeZ,
			soft,
			hard,
			factor,
			curve,
			magnitudePhysicsFactor,
			extraMultiplier
		))

		applyFatigueDrain(dt, extraMultiplier)

		local maxPush = settings.get('AltitudeSoftDownwardPressureMax', 250.0)
		local minPush = 12.0

		-- Velocity-style downward pressure:
		-- instead of applying a fixed downward step every pulse,
		-- build downward speed while above soft limit.
		local targetVelocity = math.max(minPush, factor * maxPush * magnitudePhysicsFactor)
		local acceleration = maxPush * 3.0

		if softPushVelocity < targetVelocity then
			softPushVelocity = math.min(targetVelocity, softPushVelocity + acceleration * dt)
		else
			softPushVelocity = math.max(targetVelocity, softPushVelocity - acceleration * dt)
		end
		softPushVelocity = math.min(softPushVelocity, maxPush)
		softPushVelocity = softPushVelocity * 0.95

		if softPushTimer <= 0 then
			local pulseDt = 0.03
			local dz = softPushVelocity * pulseDt

			core.sendGlobalEvent('GEA_SoftPushPlayer', {
				dz = dz
			})

			softPushTimer = pulseDt
		end

		local msg = "You struggle to maintain altitude."

		if settings.get('ShowAltitudePressureMessages', false) then
			local pct = math.floor(factor * 100)
			msg = string.format(
				"%s (Altitude: %.0f%% of limit | Soft: %.0f | Hard: %.0f)",
				msg,
				pct,
				soft,
				hard
			)
		end

		showCooldownMessage('soft_pressure', msg, 2.0)
	end
end

local function iterLevitateSources()
    local activeSpells = Actor.activeSpells(self)
    local out = {}

    for _, spell in pairs(activeSpells) do
        for _, eff in pairs(spell.effects) do
            if eff.id == 'levitate' then
				local item = spell.item
				local itemRecordId = item and string.lower(item.recordId or '') or nil

				out[#out + 1] = {
					activeSpellId = spell.activeSpellId,
					id = string.lower(spell.id or ''),
					name = spell.name or '',
					fromEquipment = spell.fromEquipment == true,
					item = item,
					itemRecordId = itemRecordId,
					temporary = spell.temporary == true,
					duration = eff.duration,
					durationLeft = eff.durationLeft,
					effects = knownLevitationSpellEffectsById[string.lower(spell.id or '')] or spell.effects or {},
				}			
                break
            end
        end
    end

    return out
end

local function objectIsInstance(typeApi, object)
    if not typeApi or not typeApi.objectIsInstance or not object then
        return false
    end

    local ok, result = pcall(typeApi.objectIsInstance, object)
    return ok and result == true
end

local function itemRecordHasScrollFlag(item)
    if not item or not types.Book or not types.Book.record then
        return false
    end

    local ok, record = pcall(types.Book.record, item)
    if not ok or not record then
        return false
    end

    return record.isScroll == true
        or record.scroll == true
        or record.type == 'Scroll'
end

local function classifyLevitateSource(src)
    local srcId = string.lower(tostring(src and src.id or ''))
    local srcName = string.lower(tostring(src and src.name or ''))
    local itemId = string.lower(tostring(src and src.itemRecordId or ''))
    local hasItem = src and src.item ~= nil

    local function finish(sourceType, reason)
        return sourceType
    end

    -- Constant-effect equipment levitation.
    if src and src.fromEquipment and not src.temporary then
        return finish("constantEffect", "equipment")
    end

    -- OpenMW often exposes potion/scroll effects as temporary active spells,
    -- with the consumed item ID in src.id rather than src.item/itemRecordId.
    if itemId:match('^p_levitation_')
        or srcId:match('^p_levitation_')
        or srcName:find('rising force', 1, true)
    then
        return finish("potion", "potion id/name")
    end

    if itemId:match('^sc_')
        or srcId:match('^sc_')
        or srcName:find('scroll of ', 1, true)
    then
        return finish("scroll", "scroll id/name")
    end

    -- If OpenMW gives us the original item object, use the object type.
    if hasItem then
        if objectIsInstance(types.Potion, src.item) then
            return finish("potion", "potion object")
        end

        if objectIsInstance(types.Book, src.item) and itemRecordHasScrollFlag(src.item) then
            return finish("scroll", "scroll object")
        end

        return finish("enchantedItem", "item object")
    end

    -- Normal spell, including temporary cast effects that are not recognized as items.
    if src and src.temporary then
        return finish("spell", "temporary active spell")
    end

    return finish("unknown", "fallback")
end


local function sourceTypeAllowed(sourceType)
    if sourceType == 'spell' then
        return settings.get('AllowLevitationFromSpells', true)
    elseif sourceType == 'potion' then
        return settings.get('AllowLevitationFromPotions', true)
    elseif sourceType == 'scroll' then
        return settings.get('AllowLevitationFromScrolls', true)
    elseif sourceType == 'constantEffect' then
        return settings.get('AllowLevitationFromConstantEffect', true)
    elseif sourceType == 'enchantedItem' then
        return settings.get('AllowLevitationFromEnchantedItems', true)
    end

    return settings.get('AllowLevitationFromUnknownSources', true)
end

local function blockedLevitateSourceType(sources)
    for _, src in ipairs(sources) do
        local sourceType = classifyLevitateSource(src)

        if not sourceTypeAllowed(sourceType) then
            return sourceType, src
        end
    end

    return nil, nil
end

local function sourceTypeLabel(sourceType)
    if sourceType == 'spell' then return 'spell levitation' end
    if sourceType == 'potion' then return 'potion levitation' end
    if sourceType == 'scroll' then return 'scroll levitation' end
    if sourceType == 'constantEffect' then return 'constant-effect levitation' end
    if sourceType == 'enchantedItem' then return 'enchanted item levitation' end
    return 'this form of levitation'
end


local function actorSkillValue(skillName)
    local skill = types.NPC.stats.skills[skillName] and types.NPC.stats.skills[skillName](self)
    if not skill then
        return 0
    end
    return skill.modified or skill.base or 0
end

local function actorAttributeValue(attributeName)
    local attr = types.NPC.stats.attributes[attributeName] and types.NPC.stats.attributes[attributeName](self)
    if not attr then
        return 0
    end
    return attr.modified or attr.base or 0
end

local function currentMagickaValue()
    local magicka = Actor.stats.dynamic.magicka(self)
    if not magicka then
        return nil, nil
    end

    return magicka.current, magicka
end

local function isVanillaLevitationPotion(src)
    local id = src and src.itemRecordId or ''
    return id:match('^p_levitation_') ~= nil
end


local function spellIdIsListed(spellId, csv)
    local id = string.lower(tostring(spellId or ''))
    if id == '' then
        return false
    end

    local ids = settings.parseCsvSet(csv or '')
    return ids[id] == true
end

local function isBuiltInApprovedLevitationSpellId(spellId)
    local id = string.lower(tostring(spellId or ''))

	return id:match('^pxm_gea_') ~= nil
end

local function isApprovedLevitationSpellId(spellId)
	return isBuiltInApprovedLevitationSpellId(spellId)
		or spellIdIsListed(spellId, settings.get('ApprovedLevitationSpellIds', ''))
end

local function isUnapprovedLevitationSpellSource(sourceType, sourceId)
    return sourceType == 'spell'
        and not isApprovedLevitationSpellId(sourceId)
end

local function isCustomLevitationSpellSource(sourceType, sourceId)
    return settings.get('CustomSpellLevitationRulesEnabled', true)
        and isUnapprovedLevitationSpellSource(sourceType, sourceId)
end

local function isApprovedLevitationSpellSource(sourceType, sourceId)
    return sourceType == 'spell'
        and isApprovedLevitationSpellId(sourceId)
end

local function optionalRuleEnabledForSource(sourceType, sourceId)
    if sourceType == 'enchantedItem' then
        return settings.get('EnchantedItemLevitationRulesEnabled', true)
    elseif sourceType == 'constantEffect' then
        return settings.get('ConstantEffectLevitationRulesEnabled', false)
    elseif isApprovedLevitationSpellSource(sourceType, sourceId) then
        return settings.get('ApprovedSpellLevitationRulesEnabled', true)
    elseif sourceType == 'unknown' then
        return settings.get('UnknownLevitationRulesEnabled', false)
    end

    return false
end

local function spellHasLevitateEffect(spell)
    for _, effect in ipairs(spell and spell.effects or {}) do
        if effect.id == 'levitate' then
            return true
        end
    end

    return false
end

local function getPlayerSpellEntries()
    local spells = Actor.spells(self)
    local result = {}

    if not spells then
        return result
    end

    if spells.getAll then
        local ok, all = pcall(function()
            return spells:getAll()
        end)

        if ok and all then
            for _, spell in pairs(all) do
                result[#result + 1] = spell
            end

            return result
        end
    end

    for _, spell in pairs(spells) do
        result[#result + 1] = spell
    end

    return result
end

local function showPendingCustomLevitationSpellWarning()
    if not pendingCustomLevitationSpellWarning then
        return
    end

    -- Spellmaking/buying usually happens in a menu. Wait until gameplay resumes
    -- so the message is actually visible.
    if I.UI.getMode() ~= nil then
        return
    end

    pendingCustomLevitationSpellWarning = false

    showCooldownMessage(
        'custom_spell_acquisition_warning',
        'Guild spellmaking cannot stabilize self-made Levitation. This spell will be weaker and more unstable under the Gravity Enforcement Act.',
        6.0
    )
end

local function checkNewCustomLevitationSpells()
    if not settings.get('Enabled', true) then
        return
    end
    for _, spell in ipairs(getPlayerSpellEntries()) do
        local spellId = string.lower(tostring(spell.id or ''))

        if spellId ~= ''
            and spellHasLevitateEffect(spell)
            and isCustomLevitationSpellSource('spell', spellId)
        then
			knownLevitationSpellEffectsById[spellId] = spell.effects or {}
			
            if not knownCustomLevitationSpellIds[spellId] then
                knownCustomLevitationSpellIds[spellId] = true

                if customLevitationSpellScanInitialized then
                    pendingCustomLevitationSpellWarning = true
                    debugLog('New custom levitation spell detected: ' .. spellId)
                end
            end
        end
    end

    customLevitationSpellScanInitialized = true
    showPendingCustomLevitationSpellWarning()
end

local function effectNumber(value, fallback)
    value = tonumber(value)
    if value == nil then
        return fallback or 0
    end
    return value
end

local function levitateEffectDifficulty(effects)
    local bestMagnitude = 0
    local bestDuration = 0

    for _, effect in ipairs(effects or {}) do
        if effect.id == 'levitate' then
            local mag = 0

            if effect.magnitude ~= nil then
                mag = effectNumber(effect.magnitude, 0)
            elseif effect.magnitudeMin ~= nil or effect.magnitudeMax ~= nil then
                mag = math.max(
                    effectNumber(effect.magnitudeMin, 0),
                    effectNumber(effect.magnitudeMax, 0)
                )
            end

            bestMagnitude = math.max(bestMagnitude, mag)
            bestDuration = math.max(bestDuration, effectNumber(effect.duration, 0))
        end
    end

    local magnitudeExtra = math.max(0, bestMagnitude - 1) * 0.25
    local durationExtra = math.max(0, bestDuration - 30) * 0.05
    local extra = math.floor(math.min(50, magnitudeExtra + durationExtra) + 0.5)

    return extra, bestMagnitude, bestDuration
end

local function levitateMagnitudePhysicsFactorForSources(sources)
    local strongestMagnitude = 0
    local longestDuration = 0

    for _, src in ipairs(sources or {}) do
        local _, magnitude, duration = levitateEffectDifficulty(src.effects or {})
        strongestMagnitude = math.max(strongestMagnitude, magnitude or 0)
        longestDuration = math.max(longestDuration, duration or 0)
    end

    -- 10 pts or less: normal
    -- ~70 pts: noticeably harder
    -- ~130 pts: about double instability
    local magnitudeFactor = 1 + math.min(1.0, math.max(0, strongestMagnitude - 10) / 120)

    -- Long duration adds a small extra strain, capped.
    local durationFactor = 1 + math.min(0.25, math.max(0, longestDuration - 30) / 240)

    local factor = math.min(2.25, magnitudeFactor * durationFactor)

	debugSpam(string.format(
		"[MAG PHYSICS] magnitude=%.1f duration=%.1f factor=%.2f",
		strongestMagnitude,
		longestDuration,
		factor
	))

    return factor
end

local function levitationRequirementValues(sourceType, effects, sourceId)
    local minAlteration
    local minIntelligence

    if sourceType == 'potion' then
        minAlteration = settings.get('PotionLevitationMinAlteration', 25)
        minIntelligence = settings.get('PotionLevitationMinIntelligence', 40)
    elseif sourceType == 'scroll' then
        minAlteration = settings.get('ScrollLevitationMinAlteration', 35)
        minIntelligence = settings.get('ScrollLevitationMinIntelligence', 50)
    elseif isCustomLevitationSpellSource(sourceType, sourceId) then
        minAlteration = settings.get('CustomSpellLevitationMinAlteration', 60)
        minIntelligence = settings.get('CustomSpellLevitationMinIntelligence', 50)
    elseif sourceType == 'constantEffect' and settings.get('ConstantEffectLevitationRulesEnabled', false) then
        minAlteration = settings.get('ConstantEffectLevitationMinAlteration', 40)
        minIntelligence = settings.get('ConstantEffectLevitationMinIntelligence', 50)
    elseif sourceType == 'enchantedItem' and settings.get('EnchantedItemLevitationRulesEnabled', true) then
        minAlteration = settings.get('EnchantedItemLevitationMinAlteration', 35)
        minIntelligence = settings.get('EnchantedItemLevitationMinIntelligence', 45)
    elseif isApprovedLevitationSpellSource(sourceType, sourceId) and settings.get('ApprovedSpellLevitationRulesEnabled', true) then
        minAlteration = settings.get('ApprovedSpellLevitationMinAlteration', 30)
        minIntelligence = settings.get('ApprovedSpellLevitationMinIntelligence', 35)
    elseif sourceType == 'unknown' and settings.get('UnknownLevitationRulesEnabled', false) then
        minAlteration = settings.get('UnknownLevitationMinAlteration', 40)
        minIntelligence = settings.get('UnknownLevitationMinIntelligence', 50)
    else
        return nil, nil, 0, 0, 0
    end

    local extra, magnitude, duration = levitateEffectDifficulty(effects)
	minAlteration = math.max(0, minAlteration + extra)
	minIntelligence = math.max(0, minIntelligence + extra)

    return minAlteration, minIntelligence, extra, magnitude, duration
end

local function itemRequirementFailureReason(sourceType, effects, sourceId)
    if not settings.get('Enabled', true) then
        return nil
    end
    local customSpell = isCustomLevitationSpellSource(sourceType, sourceId)

    if not customSpell and shouldSkipSkillAttributeChecksForSource(sourceType) then
        if not saneMagicSkipLogged[sourceType] then
            debugLog('Skipping item requirement checks for ' .. tostring(sourceType) .. ' because Sane Magic is present.')
            saneMagicSkipLogged[sourceType] = true
        end
        return nil
    end
	
    local minAlteration, minIntelligence, scalingExtra, effectMagnitude, effectDuration = levitationRequirementValues(sourceType, effects, sourceId)
    if not minAlteration or not minIntelligence then
        return nil
    end

    local alteration = actorSkillValue('alteration')
    local intelligence = actorAttributeValue('intelligence')

    if alteration >= minAlteration and intelligence >= minIntelligence then
        return nil
    end

    debugLog(string.format(
        "Item requirement failed: source=%s alteration=%.0f requiredAlteration=%d intelligence=%.0f requiredIntelligence=%d scalingExtra=%d levitateMagnitude=%.1f levitateDuration=%.1f",
        tostring(sourceType),
        alteration,
        minAlteration,
        intelligence,
        minIntelligence,
        scalingExtra,
        effectMagnitude,
        effectDuration
    ))

    local sourceWord
    if sourceType == 'potion' then
        sourceWord = 'potion'
    elseif sourceType == 'scroll' then
        sourceWord = 'scroll'
	elseif customSpell then
		sourceWord = 'custom spell'
	elseif sourceType == 'constantEffect' then
		sourceWord = 'constant-effect enchantment'
	elseif sourceType == 'enchantedItem' then
		sourceWord = 'enchanted item'
	elseif isApprovedLevitationSpellSource(sourceType, sourceId) then
		sourceWord = 'levitation spell'
	elseif sourceType == 'unknown' then
		sourceWord = 'unknown source'
	else
		sourceWord = 'source'
	end

    return string.format(
        "You lack the discipline to bind the %s's levitation magic (requires Alteration %d / Intelligence %d; you have %d / %d).",
        sourceWord,
        minAlteration,
        minIntelligence,
        alteration,
        intelligence
    )
end

local function itemFailureChance(sourceType, sourceId)
    if not settings.get('Enabled', true) then
        return 0
    end
    local chance = 0
    local customSpell = isCustomLevitationSpellSource(sourceType, sourceId)

    if sourceType == 'potion' then
        chance = settings.get('PotionLevitationFailureChance', 15)
    elseif sourceType == 'scroll' then
        chance = settings.get('ScrollLevitationFailureChance', 10)
    elseif customSpell then
        chance = settings.get('CustomSpellLevitationFailureChance', 20)
	elseif sourceType == 'constantEffect' then
		if settings.get('ConstantEffectLevitationRulesEnabled', false) then
			chance = settings.get('ConstantEffectLevitationFailureChance', 0)
		end
	elseif sourceType == 'enchantedItem' then
		if settings.get('EnchantedItemLevitationRulesEnabled', true) then
			chance = settings.get('EnchantedItemLevitationFailureChance', 5)
		end
	elseif isApprovedLevitationSpellSource(sourceType, sourceId) then
		if settings.get('ApprovedSpellLevitationRulesEnabled', true) then
			chance = settings.get('ApprovedSpellLevitationFailureChance', 0)
		end
	elseif sourceType == 'unknown' then
		if settings.get('UnknownLevitationRulesEnabled', false) then
			chance = settings.get('UnknownLevitationFailureChance', 0)
		end
	end

	if settings.get('LevitationItemFailureSkillReduction', true) and (customSpell or not shouldSkipSkillAttributeChecksForSource(sourceType)) then
		local alteration = actorSkillValue('alteration')
		local intelligence = actorAttributeValue('intelligence')

		-- Alteration matters most; Intelligence helps but less strongly.
		-- At high control, failure chance is reduced but never fully removed.
		local control = math.max(alteration, intelligence * 0.5)
		local reduction = math.min(0.85, control / 125)

		chance = chance * (1 - reduction)

		debugLog(string.format(
			"Item levitation failure scaling: source=%s alteration=%.1f intelligence=%.1f control=%.1f reduction=%.2f finalChance=%.2f",
			tostring(sourceType),
			alteration,
			intelligence,
			control,
			reduction,
			chance
		))
	elseif settings.get('LevitationItemFailureSkillReduction', true) then
		debugLog('Skipping item failure skill scaling for ' .. tostring(sourceType) .. ' because Sane Magic is present.')
	end

    return math.max(0, math.min(100, chance))
end

local function itemPowerMultiplierForSources(sources)
    local multiplier = 1

    for _, src in ipairs(sources) do
        local sourceType = classifyLevitateSource(src)
        local isApproved = isApprovedLevitationSpellId(src.id)
        local isCustom = isCustomLevitationSpellSource(sourceType, src.id)

        if settings.get('Debug', false) then
            debugSpam(string.format(
                "[POWER CHECK] type=%s | id=%s | approved=%s | custom=%s",
                tostring(sourceType),
                tostring(src.id),
                tostring(isApproved),
                tostring(isCustom)
            ))
        end

        if sourceType == 'potion' then
            if isVanillaLevitationPotion(src) then
                multiplier = math.min(multiplier, settings.get('PotionLevitationPowerMultiplier', 0.5))
            else
                multiplier = math.min(multiplier, settings.get('CustomPotionLevitationPowerMultiplier', 0.25))
            end

        elseif sourceType == 'scroll' then
            multiplier = math.min(multiplier, settings.get('ScrollLevitationPowerMultiplier', 0.7))

        elseif isCustom then
            local customMult = settings.get('CustomSpellLevitationPowerMultiplier', 0.35)

            if settings.get('Debug', false) then
                debugSpam(string.format(
                    "[POWER APPLY] CUSTOM SPELL → applying multiplier %.2f",
                    customMult
                ))
            end

            multiplier = math.min(multiplier, customMult)
        end
    end

    if settings.get('Debug', false) then
        debugSpam(string.format(
            "[POWER FINAL] multiplier=%.2f",
            multiplier
        ))
    end

    return math.max(0.05, math.min(1, multiplier))
end

local function checkLevitationItemRules(sources)
    if not settings.get('Enabled', true) then
        return false
    end
    if not settings.get('ItemLevitationRulesEnabled', true) then
        return false
    end

    for _, src in ipairs(sources) do
        local sourceType = classifyLevitateSource(src)

		if sourceType == 'potion' or sourceType == 'scroll' or isCustomLevitationSpellSource(sourceType, src.id) or optionalRuleEnabledForSource(sourceType, src.id) then
            local key = tostring(src.activeSpellId or src.id or '') .. ':' .. tostring(src.itemRecordId or '')

            if key ~= ':' and not itemRuleHandledByActiveSpellId[key] then
                itemRuleHandledByActiveSpellId[key] = true

				local requirementFailureMessage = itemRequirementFailureReason(sourceType, src.effects, src.id)
				if requirementFailureMessage then
					showCooldownMessage(
						'item_requirement_failed_' .. sourceType,
						requirementFailureMessage,
						2.0
					)
					suppressAllLevitate(false)
					return true
				end

                local chance = itemFailureChance(sourceType, src.id)
                if chance > 0 and math.random() < (chance / 100) then
                    local alteration = actorSkillValue('alteration')
                    local intelligence = actorAttributeValue('intelligence')
                    local control = math.max(alteration, intelligence * 0.5)
                    local msg

                    if control < 30 then
                        msg = "You struggle to control the levitation magic, and it collapses."
                    elseif control < 60 then
                        msg = "The levitation magic falters and fades."
                    else
                        msg = "The levitation magic flickers unexpectedly and fails."
                    end

                    if sourceType == 'potion' then
                        msg = msg:gsub("levitation magic", "potion's levitation magic")
                    elseif sourceType == 'scroll' then
                        msg = msg:gsub("levitation magic", "scroll's levitation magic")
                    elseif isCustomLevitationSpellSource(sourceType, src.id) then
                        msg = msg:gsub("levitation magic", "custom spell's levitation magic")
                    end

                    debugLog(string.format(
                        "Item random failure: source=%s alteration=%.0f intelligence=%.0f control=%.1f finalChance=%.2f",
                        tostring(sourceType),
                        alteration,
                        intelligence,
                        control,
                        chance
                    ))

                    showCooldownMessage(
                        'item_random_failed_' .. sourceType,
                        msg,
                        2.0
                    )
                    suppressAllLevitate()
                    return true
                end
            end
        end
    end

    return false
end

local function selectedLevitationCastSource()
    local spell = self.type.getSelectedSpell and self.type.getSelectedSpell(self) or nil
    local item = self.type.getSelectedEnchantedItem and self.type.getSelectedEnchantedItem(self) or nil

    if spell then
        if spell.type == core.magic.SPELL_TYPE.Power then
            return nil
        end

        if spell.type ~= core.magic.SPELL_TYPE.Spell then
            return nil
        end

        if spell.alwaysSucceedFlag then
            return nil
        end

        local hasLevitateEffect = false
        for _, effect in ipairs(spell.effects or {}) do
            if effect.id == 'levitate' then
                hasLevitateEffect = true
                break
            end
        end

        if hasLevitateEffect then
			local spellId = string.lower(tostring(spell.id or ''))

			return {
				sourceType = 'spell',
				effects = knownLevitationSpellEffectsById[spellId] or spell.effects or {},
				id = spellId,
				name = spell.name or '',
			}
        end
    end

    if item then
        local okRecord, itemRecord = pcall(item.type.record, item)
        if not okRecord or not itemRecord or not itemRecord.enchant then
            return nil
        end

        local enchant = core.magic.enchantments.records[itemRecord.enchant]
        if not enchant or not enchant.effects then
            return nil
        end

        local hasLevitateEffect = false
        for _, effect in ipairs(enchant.effects or {}) do
            if effect.id == 'levitate' then
                hasLevitateEffect = true
                break
            end
        end

        if not hasLevitateEffect then
            return nil
        end

        local sourceType = 'enchantedItem'
        if objectIsInstance(types.Book, item) and itemRecordHasScrollFlag(item) then
            sourceType = 'scroll'
        end

        return {
            sourceType = sourceType,
            effects = enchant.effects or {},
            id = string.lower(tostring(itemRecord.id or item.recordId or '')),
            name = itemRecord.name or item.name or '',
            item = item,
        }
    end

    return nil
end

local castingBlockedByGEA = false

local function blockSelectedLevitationUse(reasonKey, message, magickaBefore)
    debugLog('Pre-blocking levitation use: ' .. tostring(reasonKey))
    showCooldownMessage(reasonKey, message, 1.0)

    if self.type.setStance and self.type.STANCE and self.type.STANCE.Nothing then
        self.type.setStance(self, self.type.STANCE.Nothing)
    end

    self.controls.use = 0

    if self.type.setSelectedSpell then
        self.type.setSelectedSpell(self, nil)
    end

    if magickaBefore then
        pendingMagickaRestore = magickaBefore
        pendingMagickaRestoreTimer = 0.5
    end
    castingBlockedByGEA = true
    return false
end

input.bindAction('Use', async:callback(function(dt, use)
    if not settings.get('Enabled', true) then
        return use
    end

    if I.UI.getMode() ~= nil then
        return use
    end

    local isSpellStance = self.type.getStance and self.type.getStance(self) == self.type.STANCE.Spell
    local quickCast = self.controls.use == 1 and isSpellStance
    local normalCast = isSpellStance and use and dt > 0

    if not quickCast and not normalCast then
        castingBlockedByGEA = false
        return use
    end

    if castingBlockedByGEA then
        return false
    end

    local selected = selectedLevitationCastSource()
    if not selected then
        return use
    end

    if isWhitelistedSource({ selected }) then
        return use
    end

    local magickaBefore = currentMagickaValue()
    local cellInfo = getCellInfo()

    -- Restricted-area suppression must win over cooldown, source-type blocks,
    -- and item/spell requirement checks. This keeps the player-facing reason
    -- consistent: the law/suppression blocked levitation first.
    if not isExcludedCell(cellInfo) and isRestrictedCell and isRestrictedCell(cellInfo) then
        return blockSelectedLevitationUse(
            'suppression_preuse',
            l10n('levitationSuppressed_message'),
            magickaBefore
        )
    end

    if levitationCooldownTimer > 0 then
        return blockSelectedLevitationUse(
            'levitation_cooldown_preuse',
            string.format('Levitation is unstable. Try again in %.1f seconds.', levitationCooldownTimer),
            magickaBefore
        )
    end

    if not sourceTypeAllowed(selected.sourceType) then
        return blockSelectedLevitationUse(
            'blocked_source_preuse_' .. tostring(selected.sourceType),
            'Gravity Enforcement Act blocks ' .. sourceTypeLabel(selected.sourceType) .. '.',
            magickaBefore
        )
    end

    if settings.get('ItemLevitationRulesEnabled', true) then
        local requirementFailureMessage = itemRequirementFailureReason(selected.sourceType, selected.effects, selected.id)
        if requirementFailureMessage then
            return blockSelectedLevitationUse(
                'item_requirement_failed_preuse_' .. tostring(selected.sourceType),
                requirementFailureMessage,
                magickaBefore
            )
        end
    end

    return use
end), {})

local function hasLevitate()
    local effect = Actor.activeEffects(self):getEffect('levitate')
    return effect and effect.magnitude and effect.magnitude > 0
end

isWhitelistedSource = function(sources)
    local spellWhitelist = settings.parseCsvSet(settings.get('WhitelistedSpellIds', ''))
    local itemWhitelist = settings.parseCsvSet(settings.get('WhitelistedItemIds', ''))

    for _, src in ipairs(sources) do
        if src.id ~= '' and spellWhitelist[src.id] then
            return true
        end
        if src.itemRecordId and itemWhitelist[src.itemRecordId] then
            return true
        end
    end

    return false
end

local function analyzeLevitateSources(sources)
    local info = {
        hasCE = false,
        hasNormal = false,
        ceSources = {},
        normalSources = {},
    }

    for _, src in ipairs(sources) do
        if src.fromEquipment and not src.temporary then
            info.hasCE = true
            info.ceSources[#info.ceSources + 1] = src
        else
            info.hasNormal = true
            info.normalSources[#info.normalSources + 1] = src
        end
    end

    return info
end

local EXTERIOR_CITY_AREAS = settings.parseCsvSet(table.concat({
    -- Morrowind / Tribunal / Bloodmoon
    'Balmora',
    'Ald-ruhn',
    'Ald-ruhn, Manor District',
    'Vivec',
    'Vivec, Foreign Quarter',
    'Vivec, Hlaalu',
    'Vivec, Redoran',
    'Vivec, Telvanni',
    'Vivec, Arena',
    'Vivec, St. Delyn',
    'Vivec, St. Olms',
    'Sadrith Mora',
    'Wolverine Hall',
    'Tel Vos',
    'Vos',
    'Gnisis',
    'Seyda Neen',
    'Pelagiad',
    'Caldera',
    'Maar Gan',
    'Molag Mar',
    'Ebonheart',
    'Dagon Fel',
    'Gnaar Mok',
    'Hla Oad',
    'Khuul',
    'Ald Velothi',
    'Suran',
    'Raven Rock',

    -- Tamriel Rebuilt / mainland Morrowind
    'Old Ebonheart',
    'Firewatch',
    'Narsis',
    'Necrom',
    'Helnim',
    'Port Telvannis',
    'Almas Thirr',
    'Akamora',
    'Andothren',
    'Dondril',
    'Kragenmoor',
    'Teyn',
    'Ranyon-ruhn',
    'Sailen',
    'Gah Sadrith',
    'Llothanis',
    'Baan Malur',

    -- Skyrim: Home of the Nords
    'Karthwasten',
    'Dragonstar',
    'Karthgad',
    'Falkirstad',
    'Haafingar',
    'Baurichal',

    -- Project Cyrodiil / Imperial City of Cyrodiil
    'Anvil',
    'Brina Cross',
    'Charach',
    'Sutch',
    'Seppaki',
    'Thresvy',
    'Imperial City',
    'Cyrodiil City',
}, ', '))

local TELVANNI_ALLOWED_AREAS = settings.parseCsvSet(table.concat({
	-- Vvardenfell Telvanni settlements
	'Sadrith Mora',
	'Tel Aruhn',
	'Tel Branora',
	'Tel Fyr',
	'Tel Mora',
	'Tel Vos',
	'Vos',
	'Tel Uvirith',

	-- Tamriel Rebuilt / mainland Telvanni settlements
	'Port Telvannis',
	'Firewatch',
	'Helnim',
	'Ranyon-ruhn',
	'Sailen',
	'Gah Sadrith',
}, ', '))

local function isTelvanniAllowedCell(cellInfo)
	if not cellInfo then
		return false
	end

	if TELVANNI_ALLOWED_AREAS[cellInfo.region]
		or TELVANNI_ALLOWED_AREAS[cellInfo.id]
		or TELVANNI_ALLOWED_AREAS[cellInfo.name]
	then
		return true
	end

	local id = cellInfo.id or ''
	local name = cellInfo.name or ''

	return id:find('tel ', 1, true) ~= nil
		or name:find('tel ', 1, true) ~= nil
		or id:find('telvanni', 1, true) ~= nil
		or name:find('telvanni', 1, true) ~= nil
end

isRestrictedCell = function(cellInfo)
    if not cellInfo then
        return false
    end
	
	if isTelvanniAllowedCell(cellInfo) then
		return false
	end	

    local mode = settings.get('RestrictionPolicyMode', 'ExtYesIntYes')

    local exteriorAllowed =
        mode == 'ExtYesIntYes'
        or mode == 'ExtYesIntNo'

    local interiorAllowed =
        mode == 'ExtYesIntYes'
        or mode == 'ExtNoIntYes'

    if cellInfo.isExterior then
		if exteriorAllowed then
			local restrictedExteriorAreas = settings.parseCsvSet(settings.get('RestrictedExteriorRegions', ''))
			local legacyRestrictedExteriorCells = settings.parseCsvSet(settings.get('RestrictedExteriorCells', ''))

			local isBuiltInCity =
				settings.get('RestrictExteriorCities', true)
				and (
					EXTERIOR_CITY_AREAS[cellInfo.region]
					or EXTERIOR_CITY_AREAS[cellInfo.id]
					or EXTERIOR_CITY_AREAS[cellInfo.name]
				)

			local isUserRestrictedExterior =
				restrictedExteriorAreas[cellInfo.region]
				or restrictedExteriorAreas[cellInfo.id]
				or restrictedExteriorAreas[cellInfo.name]
				or legacyRestrictedExteriorCells[cellInfo.id]
				or legacyRestrictedExteriorCells[cellInfo.name]

			if isBuiltInCity or isUserRestrictedExterior then
				return true
			end

			return false
		end

        local allowedExteriorAreas = settings.parseCsvSet(settings.get('AllowedExteriorRegions', ''))
        local legacyAllowedExteriorCells = settings.parseCsvSet(settings.get('AllowedExteriorCells', ''))

        if allowedExteriorAreas[cellInfo.region]
            or allowedExteriorAreas[cellInfo.id]
            or allowedExteriorAreas[cellInfo.name]
            or legacyAllowedExteriorCells[cellInfo.id]
            or legacyAllowedExteriorCells[cellInfo.name]
        then
            return false
        end

        return true
    end

    if interiorAllowed then
        local restrictedInteriors = settings.parseCsvSet(settings.get('RestrictedNamedInteriors', ''))

        if restrictedInteriors[cellInfo.id] or restrictedInteriors[cellInfo.name] then
            return true
        end

        return false
    end

    local allowedInteriors = settings.parseCsvSet(settings.get('AllowedNamedInteriors', ''))

    if allowedInteriors[cellInfo.id] or allowedInteriors[cellInfo.name] then
        return false
    end

    if cellInfo.name ~= '' then
        return true
    end

    return false
end

local function maybeWarn(cellInfo)
    if not cellInfo then
        return
    end

    showCooldownMessage(
        'suppression',
        l10n('levitationSuppressed_message'),
        2.0
    )
end

suppressAllLevitate = function(startCooldown)
    if startCooldown ~= false then
        startLevitationCooldown()
    end
	
    local activeSpells = Actor.activeSpells(self)

    for _, src in ipairs(iterLevitateSources()) do
        if src.temporary and src.activeSpellId then
            debugLog("Removing levitate active spell source: " .. tostring(src.activeSpellId))
            activeSpells:remove(src.activeSpellId)
        end
    end

    -- Fallback: remove the effect layer too.
    Actor.activeEffects(self):remove('levitate')
end

applyFatigueDrain = function(dt, multiplier)
    if not settings.get('DrainFatigueWhileLevitating', true) then
        return
    end

    local baseDrainPerSecond = settings.get('FatigueDrainPerSecond', 6)
    if baseDrainPerSecond <= 0 then
        return
    end

    multiplier = multiplier or 1

    local fatigue = Actor.stats.dynamic.fatigue(self)
    if not fatigue then
        return
    end

    local amount = baseDrainPerSecond * multiplier * dt
    local newValue = fatigue.current - amount

    fatigue.current = math.max(0, newValue)

    if newValue <= 0 then
        if not exhausted then
            exhausted = true

            if settings.get('StopLevitateOnZeroFatigue', true) then
                debugLog('Levitation collapsed from exhaustion')
				showCooldownMessage('fatigue_fail', "You are too exhausted to keep levitating.", 2.0)
				suppressAllLevitate()
            end
        end
    end

    if newValue > 0 then
        exhausted = false
    end
end

local function sendVendorLevitateConfig(dt, force)
	vendorConfigTimer = math.max(0, (vendorConfigTimer or 0) - (dt or 0))

	if not force and vendorConfigTimer > 0 then
		return
	end

	vendorConfigTimer = 1.0

    core.sendGlobalEvent("GEA_UpdateVendorLevitateConfig", {
		enabled = settings.get('Enabled', true)
			and settings.get("VendorLevitateSuppressionEnabled", true),
        interval = 2,
		debug = settings.get("Debug", false) and DEBUG_VENDOR_SPAM,
        vanillaNpcIds = settings.get("VendorLevitateVanillaNpcIds", ""),
		thinItems = settings.get('Enabled', true)
			and settings.get("VendorLevitationItemThinningEnabled", true),
        maxPotions = settings.get("VendorLevitationItemMaxPotions", 1),
        maxScrolls = settings.get("VendorLevitationItemMaxScrolls", 1),
        keepAtLeast = settings.get("VendorLevitationItemKeepAtLeast", 1),
    })
end

local function onUpdate(dt)
    applyPresetSelection()
    updateSettingsUiIfNeeded()
    sendVendorLevitateConfig(dt)
	
	if not settings.get('Enabled', true) then
		return
	end
	
	if pendingMagickaRestore and pendingMagickaRestoreTimer > 0 then
		pendingMagickaRestoreTimer = math.max(0, pendingMagickaRestoreTimer - dt)

		local current, magicka = currentMagickaValue()
		if magicka and current and pendingMagickaRestore then
			magicka.current = math.max(current, pendingMagickaRestore)
		end

		if pendingMagickaRestoreTimer <= 0 then
			pendingMagickaRestore = nil
		end
	end	
	
	checkNewCustomLevitationSpells()
	
	for key, timeLeft in pairs(messageCooldowns) do
		messageCooldowns[key] = math.max(0, timeLeft - dt)
	end	

	softPushTimer = math.max(0, softPushTimer - dt)
	levitationCooldownTimer = math.max(0, levitationCooldownTimer - dt)

	if not hasLevitate() then
		if levitationWasActive then
			debugLog('Levitation ended; starting cooldown.')
			startLevitationCooldown()
		end

		levitationWasActive = false
		levitateStartZ = nil
		levitateLowestGroundZ = nil
		softPushVelocity = 0
		lastLevitateDurationLeft = 0
		itemRuleHandledByActiveSpellId = {}
		crime.reset()
		exhausted = false
		return
	end

	local sources = iterLevitateSources()
	
	local cellInfo = getCellInfo()

	if not hasLevitate() then
		lastLevitateDurationLeft = 0
	end	
	
	if isWhitelistedSource(sources) then
		debugLog('Levitate source is whitelisted.')
		return
	end
	
	if isExcludedCell(cellInfo) then
		debugLog('Cell excluded from Gravity Enforcement Act: ' .. tostring(cellInfo.id ~= '' and cellInfo.id or cellInfo.name))
		levitateStartZ = nil
		levitateLowestGroundZ = nil
		softPushVelocity = 0
		softPushTimer = 0
		return
	end

	local info = analyzeLevitateSources(sources)
	local hasCE = info.hasCE
	local hasNormal = info.hasNormal

	local includeCE = settings.get('IncludeConstantEffectLevitation', true)
	local managedLevitation = hasNormal or (hasCE and includeCE)

	-- If the only levitation source is CE and CE is excluded, ignore it.
	if not managedLevitation then
		return
	end

	local restricted = isRestrictedCell(cellInfo)

	-- Suppression has priority over every other levitation-control system unless it's allowed in settings:
	-- cooldown, blocked source type, item requirements/failure, fatigue, and altitude.
	if restricted then
		local suppressRestrictedLevitation = settings.get('IllegalLevitationSuppressInRestrictedAreas', true)

		debugLog('Restricted levitation detected in cell: ' .. tostring(cellInfo and cellInfo.id or 'nil'))

		if hasIllegalLevitationWitness() then
			crime.commitIllegalLevitation(cellInfo, showCooldownMessage, {
				enabled = settings.get("IllegalLevitationCrimeEnabled", true),
				bounty = settings.get("IllegalLevitationBounty", 100),
				debug = settings.get("Debug", false),
			})
		end

		if suppressRestrictedLevitation then
			suppressAllLevitate()
			maybeWarn(cellInfo)
			return
		end
	end

	if levitationCooldownTimer > 0 then
		suppressAllLevitate(false)
		showCooldownMessage(
			'levitation_cooldown',
			string.format("Levitation is unstable. Try again in %.1f seconds.", levitationCooldownTimer),
			1.0
		)
		return
	end

	local blockedSourceType = blockedLevitateSourceType(sources)
	if blockedSourceType then
		debugLog('Suppressing blocked levitation source type: ' .. tostring(blockedSourceType))
		showCooldownMessage(
			'blocked_source_' .. tostring(blockedSourceType),
			'Gravity Enforcement Act blocks ' .. sourceTypeLabel(blockedSourceType) .. '.',
			2.0
		)
		suppressAllLevitate(false)
		return
	end

	if checkLevitationItemRules(sources) then
		return
	end
	
	local currentDuration = 0

	for _, src in ipairs(sources) do
		currentDuration = math.max(currentDuration, src.durationLeft or 0)
	end

	-- detect recast / refresh
	if currentDuration > lastLevitateDurationLeft + 0.5 then
		if levitationCooldownTimer > 0 then
			debugLog('Blocking levitation refresh during cooldown')

			suppressAllLevitate(false)
			showCooldownMessage(
				'levitation_cooldown_refresh',
				'You cannot extend levitation yet.',
				1.0
			)

			return
		end
	end

	lastLevitateDurationLeft = currentDuration

	-- From this point on, levitation is valid/usable rather than merely a blocked attempt.
	-- When it ends naturally later, the cooldown should apply.
	levitationWasActive = true

	local restrictedOnlyDrain = settings.get('DrainFatigueOnlyInRestrictedAreas', false)
	local shouldApplyDrain = (not restrictedOnlyDrain) or restricted

	if shouldApplyDrain then
		local itemPowerMultiplier = itemPowerMultiplierForSources(sources)
		local effectPhysicsFactor = levitateMagnitudePhysicsFactorForSources(sources)

		applyAltitudeLimit(dt, itemPowerMultiplier, effectPhysicsFactor)
	end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
