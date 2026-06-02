local logPrefix = "[Trap Sense]"

local configPackage = require("TrapSense.config")
local config = configPackage.config

require("TrapSense.mcm")

local detectedTraps = {}
local trapVFX = {}

local function debugLog(message)
	if config.debugLog then
		mwse.log("%s %s", logPrefix, message)
	end
end

local function getReferenceKey(reference)
	if not reference then
		return nil
	end

	return reference.id or tostring(reference)
end

local function isTrapDetected(reference)
	local key = getReferenceKey(reference)

	if not key then
		return false
	end

	return detectedTraps[key] == true
end

local function isPlayerActivator(e)
	return e.activator == tes3.player
end

local function isContainer(reference)
	return reference
		and reference.object
		and reference.object.objectType == tes3.objectType.container
end

local function getTrap(reference)
	if not reference then
		return nil
	end

	if not reference.lockNode then
		return nil
	end

	return reference.lockNode.trap
end

local function getSecuritySkill()
	if not tes3.mobilePlayer then
		return 0
	end

	local securitySkill = tes3.mobilePlayer.skills[tes3.skill.security + 1]

	if not securitySkill then
		debugLog("Could not read Security skill.")
		return 0
	end

	return securitySkill.current or 0
end

local function hasDetectEnchantmentActive()
	if not tes3.mobilePlayer then
		return false
	end

	local effects = tes3.mobilePlayer:getActiveMagicEffects({
		effect = tes3.effect.detectEnchantment,
	})

	return effects and #effects > 0
end

local function getDetectionChance()
	local security = getSecuritySkill()
	local maxChance = config.maxDetectChance or 95
	local chance = security

	if config.useDetectEnchantmentBonus and hasDetectEnchantmentActive() then
		local bonus = config.detectEnchantmentBonus or 25
		chance = chance + bonus

		debugLog(string.format(
			"Detect Enchantment active. Added bonus: %.1f",
			bonus
		))
	end

	if maxChance < 0 then
		maxChance = 0
	elseif maxChance > 100 then
		maxChance = 100
	end

	chance = math.min(chance, maxChance)

	if chance < 0 then
		chance = 0
	elseif chance > 100 then
		chance = 100
	end

	return chance
end

local function rollDetection()
	local chance = getDetectionChance()
	local roll = math.random(1, 100)

	debugLog(string.format("Detection roll: %d <= %.1f", roll, chance))

	return roll <= chance
end

local function removeTrapVFX(reference)
	local key = getReferenceKey(reference)

	if not key then
		return
	end

	local vfx = trapVFX[key]

	if not vfx then
		return
	end

	local success, removedCount = pcall(function()
		return tes3.removeVisualEffect({
			vfx = vfx,
		})
	end)

	trapVFX[key] = nil

	if success then
		debugLog(string.format("Removed trap VFX. Count=%s", tostring(removedCount)))
	else
		debugLog("Failed to remove trap VFX: " .. tostring(removedCount))
	end
end

local function applyTrapVFX(reference)
	if not config.showVFX then
		return
	end

	if not reference then
		return
	end

	local key = getReferenceKey(reference)

	if not key then
		return
	end

	-- Do not stack duplicate VFX on the same trapped object.
	if trapVFX[key] then
		return
	end

	local effectId = tes3.effect.detectEnchantment

	local success, vfx = pcall(function()
		return tes3.createVisualEffect({
			reference = reference,
			magicEffectId = effectId,
		})
	end)

	if success and vfx then
		trapVFX[key] = vfx
		debugLog("Applied trap VFX.")
	else
		debugLog("Failed to apply trap VFX.")
	end
end

local function updateTrapVFX(reference)
	if not reference then
		return
	end

	-- If VFX is disabled, remove any existing VFX from this reference.
	if not config.showVFX then
		removeTrapVFX(reference)
		return
	end

	-- If the trap is gone, remove the visual.
	if not getTrap(reference) then
		removeTrapVFX(reference)
		return
	end

	if isTrapDetected(reference) then
		applyTrapVFX(reference)
	end
end

local function playDiscoverySound(reference)
	if not config.playDiscoverySound then
		return
	end

	local soundId = config.discoverySound or "mysticism hit"

	if soundId == "" then
		return
	end

	local success, played = pcall(function()
		return tes3.playSound({
			sound = soundId,
			reference = reference,
			volume = config.discoverySoundVolume or 0.8,
			pitch = 1.0,
		})
	end)

	if success and played then
		debugLog("Played discovery sound: " .. soundId)
	else
		debugLog("Failed to play discovery sound: " .. soundId)
	end
end

local function markTrapDetected(reference)
	local key = getReferenceKey(reference)

	if key then
		detectedTraps[key] = true
		applyTrapVFX(reference)
		playDiscoverySound(reference)
	end
end

local function clearDetectedTrap(reference)
	local key = getReferenceKey(reference)

	if key then
		detectedTraps[key] = nil
	end

	removeTrapVFX(reference)
end

local function onActivate(e)
	if not config.enabled then
		return
	end

	if not isPlayerActivator(e) then
		return
	end

	local reference = e.target

	if not isContainer(reference) then
		return
	end

	local trap = getTrap(reference)

	if not trap then
		clearDetectedTrap(reference)
		return
	end

	-- If already detected, allow vanilla activation.
	-- The tooltip will still show (Trapped), but the player can choose to open it anyway.
	if isTrapDetected(reference) then
		updateTrapVFX(reference)
		debugLog("Trap already detected. Letting vanilla activation continue.")
		return
	end

	if rollDetection() then
		markTrapDetected(reference)

		if config.showMessages then
			tes3.messageBox("Trapped")
		end

		debugLog("Trap detected. Activation blocked.")
		return false
	end

	-- Failure means vanilla activation continues.
	-- If the trap triggers normally, Morrowind handles it.
	debugLog("Trap not detected. Letting vanilla activation continue.")
end

local function onObjectTooltip(e)
	if not config.enabled then
		return
	end

	local reference = e.reference

	if not reference then
		return
	end

	if not isTrapDetected(reference) then
		return
	end

	if not getTrap(reference) then
		clearDetectedTrap(reference)
		return
	end

	if not e.tooltip then
		return
	end

	e.tooltip:createLabel({
		text = "(Trapped)",
		color = tes3ui.getPalette("negative_color"),
	})

	updateTrapVFX(reference)
end

local function onTrapDisarm(e)
	if not config.enabled then
		return
	end

	local reference = e.reference

	if not reference then
		return
	end

	if not isTrapDetected(reference) then
		return
	end

	-- trapDisarm fires during the probe attempt.
	-- Check shortly after, so vanilla has time to remove the trap if disarm succeeded.
	timer.start({
		type = timer.simulate,
		duration = 0.1,
		callback = function()
			if not reference then
				return
			end

			if not getTrap(reference) then
				clearDetectedTrap(reference)
				debugLog("Trap disarmed. Removed detected state and VFX.")
			else
				debugLog("Trap disarm attempted, but trap is still present.")
			end
		end,
	})
end

local function onLoaded()
	detectedTraps = {}
	trapVFX = {}

	debugLog("Loaded.")
end

event.register(tes3.event.activate, onActivate)
event.register(tes3.event.uiObjectTooltip, onObjectTooltip)
event.register(tes3.event.trapDisarm, onTrapDisarm)
event.register(tes3.event.loaded, onLoaded)

mwse.log("%s Initialized.", logPrefix)