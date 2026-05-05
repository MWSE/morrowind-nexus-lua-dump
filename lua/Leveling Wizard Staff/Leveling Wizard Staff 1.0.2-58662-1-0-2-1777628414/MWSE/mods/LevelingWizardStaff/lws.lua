local log = mwse.Logger.new()

---@meta
--- @class lwsLib
lws = {}

lws.wizardStaffId = "my_wizard_staff"
lws.wizardStaffEnchantmentId = "my_wizard_staff_enchantment"
lws.validStaffIds = require("LevelingWizardStaff.staves")

-- this injects the fields 'lws.effectType' and 'lws.effectDefinitions'
require("LevelingWizardStaff.effect_definitions")

lws.progression = {
	-- ###
	initial = 0,
	staffIntroDreamReceived = 1,
	staffReceived = 2,
	levelUpIntroDreamReceived = 3,
	halfSlotsFilledDreamReceived = 4,
	maxLevelReachedDreamReceived = 5,
}

---@alias lws.progression
--- | 'lws.progression.initial'
--- | 'lws.progression.staffIntroDreamReceived'
--- | 'lws.progression.staffReceived'
--- | 'lws.progression.levelUpIntroDreamReceived'
--- | 'lws.progression.halfSlotsFilledDreamReceived'
--- | 'lws.progression.maxLevelReachedDreamReceived'

---@param effectInfo lwsEffectInfo
---@param magnitude integer
---@return tes3effect
local function createEffect(effectInfo, magnitude)
	--- @type tes3effect
	return {
		id = effectInfo.type,
		object = tes3.getMagicEffect(effectInfo.type),
		---@diagnostic disable-next-line: assign-type-mismatch
		attribute = effectInfo.attribute,
		---@diagnostic disable-next-line: assign-type-mismatch
		skill = effectInfo.skill,
		min = magnitude,
		max = magnitude,
		rangeType = tes3.effectRange.self,
		duration = 0,
		radius = 0,
		cost = 0,
	}
end

---@param effectDefinition lwsEffectDefinition
---@param effectLevel integer
---@return tes3effect[]|nil
function lws.GetMagicEffects(effectDefinition, effectLevel)
	local magnitude = effectDefinition.magnitudes[effectLevel]
	if magnitude == nil then
		log:trace("lws.GetMagicEffects(...) failed. Could not find magnitude for effect-level %s.", effectLevel)
		return nil
	end

	--- @type tes3effect[]
	local effects = {}
	local effectCount = 0

	for effectInfoIndex, effectInfo in ipairs(effectDefinition.effectInfos) do
		if effectInfo ~= nil and effectInfo.type ~= nil and effectInfo.type >= 0 then
			effectCount = effectCount + 1 -- Since 'effectCount' starts a 0 that means the first element will be inserted at index 1 as is Lua convention and required by the calling code.
			effects[effectCount] = createEffect(effectInfo, magnitude)
		else
			log:trace("lws.GetMagicEffects(...) failed. lwsEffectInfo at index %s was not valid.", effectInfoIndex)
			return nil
		end
	end

	if effectCount > 0 then
		return effects
	else
		log:trace("lws.GetMagicEffects(...) failed. No effects found.")
		return nil
	end
end

---@return lwsModData
function lws.GetModData()
	if tes3.player then
		return tes3.player.data.levelingWizardStaff
	else
		---@diagnostic disable-next-line: return-type-mismatch
		return nil -- This is only needed for the MCM that may try to access this outside of a loaded game. During normal operation of the mod this should never happen so I kept the indicated return type nil-free.
	end
end

---@return boolean
function lws.CheckMaxLevelReached()
	local modData = lws.GetModData()

	if modData.staffFilledEnchantmentSlots < 8 then
		return false
	end

	for effectType, effectLevel in pairs(modData.staffEffectLevels) do
		local effectDefinition = lws.effectDefinitions[effectType]
		if effectDefinition.magnitudes[effectLevel + 1] ~= nil then
			return false
		end
	end

	return true
end

---@param retriesRemaining integer
local function reEquipWizardStaff(retriesRemaining)
	local success = tes3.player.mobile:equip({ item = lws.wizardStaffId, playSound = false })
	if not success and retriesRemaining > 0 then
		timer.delayOneFrame(function()
			reEquipWizardStaff(retriesRemaining - 1)
		end)
	end
end

---@param effect tes3effect|nil
---@return string
local function effectToString(effect)
	if effect == nil then
		return "nil"
	end

	local effectName
	if effect.id < 0 then
		effectName = "unknown(" .. effect.id .. ")"
	else
		effectName = tes3.getMagicEffectName({ effect = effect.id, attribute = effect.attribute, skill = effect.skill })
	end

	local magnitudeString
	if effect.min == effect.max then
		magnitudeString = "" .. effect.min
	else
		magnitudeString = effect.min .. " to " .. effect.max
	end

	local effectString = effectName .. ": " .. magnitudeString

	return effectString
end

---@param effects tes3effect[]
---@return string
local function effectsArrayToString(effects)
	local result = "[ "

	for index, effect in ipairs(effects) do
		result = result .. effectToString(effect)
		if index < 8 then
			result = result .. ", "
		end
	end

	result = result .. "]"

	return result
end

---@param first tes3.skill|tes3.attribute|integer|nil
---@param second tes3.skill|tes3.attribute|integer|nil
---@return boolean
local function checkMatch(first, second)
	local firstInvalid = first == nil or first < 0
	local secondInvalid = second == nil or second < 0

	if firstInvalid then
		return secondInvalid
	else
		return first == second
	end
end

---@param enchantEffects tes3effect[]
---@param desiredEffect tes3effect
---@return integer
local function getMatchingIndex(enchantEffects, desiredEffect)
	for index, enchantEffect in ipairs(enchantEffects) do
		if enchantEffect.id == desiredEffect.id and checkMatch(enchantEffect.attribute, desiredEffect.attribute) and checkMatch(enchantEffect.skill, desiredEffect.skill) then
			return index
		end
	end
	return -1
end

---@param enchantEffects tes3effect[]
---@param claimedIndices table<integer, boolean>
---@return integer
local function getFreeIndex(enchantEffects, claimedIndices)
	for index, enchantEffect in ipairs(enchantEffects) do
		if enchantEffect.id < 0 and claimedIndices[index] == nil then
			return index
		end
	end
	return -1
end

---@param existingEffects tes3effect[]
---@param newEffects tes3effect[]
---@return table<integer, integer>|nil
local function buildEffectIndexmap(existingEffects, newEffects)
	local effectIndexMap = {}
	local claimedIndices = {}

	for newEffectIndex, newEffect in ipairs(newEffects) do
		local existingEffectIndex = nil

		local potentialIndex = getMatchingIndex(existingEffects, newEffect)
		if potentialIndex >= 0 then
			existingEffectIndex = potentialIndex
		else
			potentialIndex = getFreeIndex(existingEffects, claimedIndices)
			if potentialIndex >= 0 then
				existingEffectIndex = potentialIndex
			else
				return nil
			end
		end

		effectIndexMap[newEffectIndex] = existingEffectIndex
		claimedIndices[existingEffectIndex] = true
	end

	return effectIndexMap
end

---@param existingEffects tes3effect[]
---@param index integer
---@param newEffect tes3effect
local function modifyExistingEffect(existingEffects, index, newEffect)
	local existingEffect = existingEffects[index]

	local effectTextBefore = effectToString(existingEffect)
	existingEffect.id = newEffect.id
	existingEffect.min = newEffect.min
	existingEffect.max = newEffect.max
	existingEffect.attribute = newEffect.attribute
	existingEffect.skill = newEffect.skill
	local effectTextAfter = effectToString(existingEffect)

	log:debug("Changed effect at index %s: %s to %s", index, effectTextBefore, effectTextAfter)
end

---comment
---@param effectDefinition lwsEffectDefinition
---@param newEffectLevel integer
---@return boolean
local function upgradeWizardStaffEnchantment(effectDefinition, newEffectLevel)
	local newEffects = lws.GetMagicEffects(effectDefinition, newEffectLevel)

	if newEffects == nil then
		log:trace("upgradeWizardStaffEnchantment(...) failed. New enchant-effects could not be found.")
		return false
	end

	---@type tes3enchantment
	local wizardStaffEnchantment = tes3.getObject(lws.wizardStaffEnchantmentId)

	local effectIndexMap = buildEffectIndexmap(wizardStaffEnchantment.effects, newEffects)
	if effectIndexMap == nil then
		log:trace("upgradeWizardStaffEnchantment(...) failed. Fitting indices for new effects were not found.")
		return false
	end

	for newEffectIndex, newEffect in ipairs(newEffects) do
		local existingEffectIndex = effectIndexMap[newEffectIndex]
		modifyExistingEffect(wizardStaffEnchantment.effects, existingEffectIndex, newEffect)
	end

	wizardStaffEnchantment.modified = true
	log:trace("upgradeWizardStaffEnchantment(...) succeeded.")
	return true
end

---@param level integer
---@return integer
function lws.CalculateMagickaForLevelUp(level)
	local baseCost = math.max(1, lws.Config.levelUpMagickaBase) -- required Magicka at level 0
	local targetLevel = math.max(1, lws.Config.targetLevel) -- target level where the required Magicka should be 'targetCost'
	local targetCost = math.max(baseCost + 1, lws.Config.levelUpMagickaAtTargetLevel) -- required Magicka for level "targetLevel"
	local t = math.clamp(level / targetLevel, 0, 1) -- interpolation factor between exponential and linear growth (0 --> fully exponential, 1 --> fully linear)

	local growthFactor = math.pow(targetCost / baseCost, 1 / targetLevel)
	local exp = baseCost * math.pow(growthFactor, level)

	local growthPerLevel = (targetCost - baseCost) / targetLevel
	local lin = baseCost + level * growthPerLevel

	local requiredMagicka = (1 - t) * exp + t * lin
	return math.ceil(requiredMagicka)
end

---@param effectDefinition lwsEffectDefinition
function lws.LevelUp(effectDefinition)
	log:debug("Leveling-Up the Leveling Wizard Staff")

	local modData = lws.GetModData()

	local currentEffectLevel = modData.staffEffectLevels[effectDefinition.type]
	local newEffectLevel = (currentEffectLevel or 0) + 1

	local success = upgradeWizardStaffEnchantment(effectDefinition, newEffectLevel)
	if success then
		log:debug("Leveling-Up succeeded")
	else
		log:debug("Leveling-Up failed")
		return
	end

	local magickaForLevelUp = lws.CalculateMagickaForLevelUp(modData.staffLevel + 1)
	modData.staffLevel = modData.staffLevel + 1
	modData.staffEffectLevels[effectDefinition.type] = newEffectLevel
	modData.staffMagickaAccumulated = math.max(0, modData.staffMagickaAccumulated - magickaForLevelUp)
	modData.staffLevelUpPending = false
	if currentEffectLevel == nil or currentEffectLevel == 0 then
		-- new effect was added
		local addedEnchantmentCount = #effectDefinition.effectInfos
		modData.staffFilledEnchantmentSlots = modData.staffFilledEnchantmentSlots + addedEnchantmentCount
	end

	if lws.CheckMaxLevelReached() then
		modData.staffMagickaAccumulated = 0
		modData.staffLevelUpPending = false
		modData.staffMaxLevelReached = true
		tes3.messageBox("Congratulations! Your Wizard Staff has reached its maximum strength.")
	end

	log:debug("Updated ModData: %s", modData)

	if modData.staffEquipped then
		tes3.player.mobile:unequip({ item = lws.wizardStaffId })
		reEquipWizardStaff(120)
	end
end
