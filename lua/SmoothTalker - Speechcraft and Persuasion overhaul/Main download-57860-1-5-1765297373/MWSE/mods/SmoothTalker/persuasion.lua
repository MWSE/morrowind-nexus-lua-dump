--[[
    Persuasion Module
    Handles core persuasion logic: attempts, effects, XP, and high-level flow
]]

local logger = require("logging.logger")
local log = logger.new{
    name = "SmoothTalker.Persuasion",
    logLevel = "INFO"
}

local persuasionModifiers = require("SmoothTalker.persuasionModifiers")
local persuasionResponses = require("SmoothTalker.persuasionResponses")
local patience = require("SmoothTalker.patience")
local npcParams = require("SmoothTalker.npcParams")
local config = require("SmoothTalker.config")
local unlocks = require("SmoothTalker.unlocks")

local persuasion = {}

-- ============================================================================
-- ILLEGAL STATUS ENUM
-- ============================================================================

persuasion.ILLEGAL_STATUS = {
	NO = "no",
	YES = "yes",
	YES_IF_FAILED = "yesIfFailed"
}

-- ============================================================================
-- UI CONFIGURATION
-- ============================================================================

persuasion.uiConfig = {
	actions = {
		{id = 1, action = "admire", label = "Admire", unlockFeature = unlocks.FEATURE.ACTION_ADMIRE},
		{id = 2, action = "intimidate", label = "Intimidate", unlockFeature = unlocks.FEATURE.ACTION_INTIMIDATE},
		{id = 3, action = "taunt", label = "Taunt", unlockFeature = unlocks.FEATURE.ACTION_TAUNT},
		{id = 4, action = "placate", label = "Placate", unlockFeature = unlocks.FEATURE.ACTION_PLACATE},
		{id = 5, action = "bond", label = "Bond", unlockFeature = unlocks.FEATURE.ACTION_BOND},
	},
	bribe = {
		action = "bribe",
		presets = {10, 100, 500, 1000}
	},
	-- Parameter configuration for UI display
	-- Uses npcParams accessor functions to ensure SmoothTalker controls value reading logic
	params = {
		{id = "disposition", label = "Disposition", unlockFeature = unlocks.FEATURE.STATUS_DISPOSITION, getValue = npcParams.getDisposition, max = 100},
		{id = "fight", label = "Fight", unlockFeature = unlocks.FEATURE.STATUS_FIGHT, getValue = npcParams.getFight, max = 100},
		{id = "alarm", label = "Alarm", unlockFeature = unlocks.FEATURE.STATUS_ALARM, getValue = npcParams.getAlarm, max = 100},
		{id = "flee", label = "Flee", unlockFeature = unlocks.FEATURE.STATUS_FLEE, getValue = npcParams.getFlee, max = 100},
		{id = "patience", label = "Patience", unlockFeature = unlocks.FEATURE.STATUS_PATIENCE, getValue = patience.getPatience, max = 100},
	}
}

-- ============================================================================
-- CALCULATION FUNCTIONS
-- ============================================================================

--- Clamp a value between min and max
--- @param value number
--- @param min number
--- @param max number
--- @return number
local function clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

-- Lookup table for player stat getters
local playerStatGetters = {
	speechcraft = function() return tes3.mobilePlayer.speechcraft.current end,
	personality = function() return tes3.mobilePlayer.personality.current end,
	luck = function() return tes3.mobilePlayer.luck.current end,
	reputation = function() return tes3.player.object.reputation end,
	level = function() return tes3.mobilePlayer.object.level end,
	strength = function() return tes3.mobilePlayer.strength.current end,
	mercantile = function() return tes3.mobilePlayer.mercantile.current end,
}

-- Lookup table for NPC stat getters
local npcStatGetters = {
	dispositionMod = function(npcRef) return 50 - (npcParams.getDisposition(npcRef) or 50) end,
	speechcraft = npcParams.getSpeechcraft,
	personality = npcParams.getPersonality,
	willpower = npcParams.getWillpower,
	fight = npcParams.getFight,
	level = npcParams.getLevel,
	hostility = function(npcRef) return npcParams.isNPCHostile(npcRef) and 1 or 0 end,
	factionRank = npcParams.getSameFactionRankDiff,
}

--- Calculate player effectiveness (total "skill") for any action
--- @param action string The action type (e.g., "admire", "bribe")
--- @param bribeAmount number|nil The bribe amount (if applicable)
--- @return number The player effectiveness score
local function calculatePlayerEffectiveness(action, bribeAmount)
	local multipliers = persuasionModifiers[action .. "PlayerMultipliers"]

	if not multipliers then
		error("No player multipliers found for action: " .. tostring(action))
	end

	local effectiveness = 0

	-- Special case: Bribe amount
	if action == "bribe" and bribeAmount then
		effectiveness = effectiveness + math.min(config.bribeMaxBonus, math.sqrt(bribeAmount) * persuasionModifiers.bribeAmountMultiplier)
	end

	-- Process each multiplier
	for stat, multiplier in pairs(multipliers) do
		local getter = playerStatGetters[stat]
		if getter then
			local value = getter()
			effectiveness = effectiveness + value * multiplier
		end
	end

	return effectiveness
end

--- Calculate task difficulty for any action
--- @param action string The action type (e.g., "admire", "bribe")
--- @param npcRef tes3reference The NPC reference
--- @return number The task difficulty score
local function calculateTaskDifficulty(action, npcRef)
	local multipliers = persuasionModifiers[action .. "NPCMultipliers"]

	if not multipliers then
		error("No NPC multipliers found for action: " .. tostring(action))
	end

	local difficulty = multipliers.baseDifficulty or 0

	-- Process each stat multiplier
	for stat, multiplier in pairs(multipliers) do
		if stat ~= "baseDifficulty" then
			local getter = npcStatGetters[stat]
			if getter then
				local value = getter(npcRef) or 0
				difficulty = difficulty + value * multiplier
			end
		end
	end

	difficulty = difficulty + persuasionModifiers.getClassModifier(npcRef, action)
	difficulty = difficulty + persuasionModifiers.getFactionModifier(npcRef, action)

	return difficulty
end

--- Get the success chance for a persuasion action
--- @param action string The action type (e.g., "admire", "bribe")
--- @param npcRef tes3reference The NPC reference
--- @param bribeAmount number|nil The bribe amount (if applicable)
--- @return number The success chance (0-100, clamped to min/max)
function persuasion.getSuccessChance(action, npcRef, bribeAmount)
	local playerEffectiveness = calculatePlayerEffectiveness(action, bribeAmount)
	local taskDifficulty = calculateTaskDifficulty(action, npcRef)
	local chance = 50 - taskDifficulty + playerEffectiveness - config.difficultyModifier

	return clamp(chance, config.minSuccessChance, config.maxSuccessChance)
end

-- ============================================================================
-- EFFECT CALCULATION
-- ============================================================================

--- Roll a random value between min and max
--- @param min number
--- @param max number
--- @return number
local function rollValue(min, max)
	return min + math.random(0, max - min)
end

--- Calculate an effect value from effect config
--- @param effectConfig table The effect configuration
--- @param npcRef tes3reference The NPC reference
--- @param bribeAmount number|nil The bribe amount (if applicable)
--- @return number The calculated effect value
local function calculateEffectValue(effectConfig, npcRef, bribeAmount)
	local value = 0

	-- Calculate base value
	if effectConfig.base then
		value = rollValue(effectConfig.base.min, effectConfig.base.max)
    end
	
    if effectConfig.amountMultiplier and bribeAmount then
		-- Special case: Bribe amount-based calculation
		local cappedAmount = math.min(bribeAmount, config.bribeEffectivenessCap)
		value = value + math.floor(math.sqrt(cappedAmount / 4) * effectConfig.amountMultiplier)
	end

	-- Apply player stat bonuses
	if effectConfig.player then
		local playerBonus = 0
		for stat, multiplier in pairs(effectConfig.player) do
			local getter = playerStatGetters[stat]
			if getter then
				local statValue = getter()
				playerBonus = playerBonus + (statValue * multiplier)
			end
		end
		value = value + math.floor(playerBonus)
	end

	-- Apply NPC stat bonuses
	if effectConfig.npc then
		local npcBonus = 0
		for stat, multiplier in pairs(effectConfig.npc) do
			local getter = npcStatGetters[stat]
			if getter then
				local statValue = getter(npcRef) or 0
				npcBonus = npcBonus + (statValue * multiplier)
			end
		end
		value = value + math.floor(npcBonus)
	end

	if effectConfig.clampMax ~= nil then
		value = math.min(effectConfig.clampMax, value)
	end
	if effectConfig.clampMin ~= nil then
		value = math.max(effectConfig.clampMin, value)
	end

	return value
end

--- Calculate all effects for an action
--- @param action string The action type (e.g., "admire", "bribe")
--- @param npcRef tes3reference The NPC reference
--- @param success boolean Whether the attempt succeeded
--- @param bribeAmount number|nil The bribe amount (if applicable)
--- @return table List of {stat: string, value: number, temporary: boolean} effects
local function calculateEffects(action, npcRef, success, bribeAmount)
	local effectsConfig = persuasionModifiers[action .. "Effects"]

	if not effectsConfig then
		error("No effects config found for action: " .. tostring(action))
	end

	local results = {}
	local outcomeConfig = success and effectsConfig.success or effectsConfig.failure

	for _, effectConfig in ipairs(outcomeConfig) do
		-- Check lockFeature - if ANY are unlocked, skip this effect
		if effectConfig.lockFeature then
			local lockFeatures = type(effectConfig.lockFeature) == "table" and effectConfig.lockFeature or {effectConfig.lockFeature}
			local shouldSkip = false
			for _, feature in ipairs(lockFeatures) do
				if unlocks.isUnlocked(feature) then
					shouldSkip = true
					break
				end
			end
			if shouldSkip then
				goto continue
			end
		end

		-- Check unlockFeature - ALL must be unlocked to use this effect
		if effectConfig.unlockFeature then
			local unlockFeatures = type(effectConfig.unlockFeature) == "table" and effectConfig.unlockFeature or {effectConfig.unlockFeature}
			local allUnlocked = true
			for _, feature in ipairs(unlockFeatures) do
				if not unlocks.isUnlocked(feature) then
					allUnlocked = false
					break
				end
			end
			if not allUnlocked then
				goto continue
			end
		end

		table.insert(results, {
			stat = effectConfig.stat,
			value = calculateEffectValue(effectConfig, npcRef, bribeAmount),
			temporary = effectConfig.temporary or false
		})

		::continue::
	end

	return results
end

-- ============================================================================
-- XP CALCULATION AND AWARDING
-- ============================================================================

-- XP configuration
local xpConfig = {
    baseDifficultyDivisor = 10, -- Divide difficulty by this for bonus XP
}

--- Calculate XP to award for a persuasion attempt
--- @param action string The action type (e.g., "admire", "bribe")
--- @param success boolean Whether the attempt succeeded
--- @param npcRef tes3reference The NPC reference
--- @param bribeAmount number|nil The bribe amount (if applicable)
--- @return number The XP amount to award
local function calculatePersuasionXP(action, success, npcRef, bribeAmount)
    if not success then
        return config.xpFailure
    end

    -- Success: base XP + difficulty bonus
    local difficulty = calculateTaskDifficulty(action, npcRef)
    local difficultyBonus = (difficulty / xpConfig.baseDifficultyDivisor) * config.xpDifficultyBonus

    return config.xpBase + difficultyBonus
end

--- Award speechcraft XP to the player
--- @param amount number The XP amount to award
local function awardSpeechcraftXP(amount)
    if amount <= 0 then return end

    tes3.mobilePlayer:exerciseSkill(tes3.skill.speechcraft, amount)
end

-- ============================================================================
-- EFFECT APPLICATION
-- ============================================================================

--- Apply persuasion effects to NPC
--- @param action string The action type (e.g., "admire", "bribe")
--- @param npcRef tes3reference The NPC reference
--- @param success boolean Whether the attempt succeeded
--- @param bribeAmount number|nil The bribe amount (if applicable)
--- @return boolean True if any effect was applied
local function applyEffects(action, npcRef, success, bribeAmount)
    local effects = calculateEffects(action, npcRef, success, bribeAmount)

    local hadEffect = false

    for _, effect in ipairs(effects) do
        if effect.stat == "disposition" and effect.value ~= 0 then
            if npcParams.modDisposition(npcRef, effect.value, effect.temporary) then
                hadEffect = true
            end
        elseif effect.stat == "fight" and effect.value ~= 0 then
            if npcParams.modFight(npcRef, effect.value) then
                hadEffect = true
            end
        elseif effect.stat == "alarm" and effect.value ~= 0 then
            if npcParams.modAlarm(npcRef, effect.value, effect.temporary) then
                hadEffect = true
            end
        elseif effect.stat == "flee" and effect.value ~= 0 then
            if npcParams.modFlee(npcRef, effect.value) then
                hadEffect = true
            end
        elseif effect.stat == "patience" and effect.value ~= 0 then
            patience.modPatience(npcRef, effect.value)
            hadEffect = true
        end
    end

    return hadEffect
end

-- ============================================================================
-- PERSUASION ATTEMPT
-- ============================================================================

--- Attempt a persuasion action
--- @param action string The action type (e.g., "admire", "bribe")
--- @param npcRef tes3reference The NPC reference
--- @param bribeAmount number|nil The bribe amount (if action is bribe)
--- @return boolean success Whether the attempt succeeded
function persuasion.attemptPersuasion(action, npcRef, bribeAmount)
    local successChance = persuasion.getSuccessChance(action, npcRef, bribeAmount)

    local roll = math.random(0, 99)
    local success = roll < successChance

    return success
end

-- ============================================================================
-- HIGH-LEVEL PERSUASION FLOW
-- ============================================================================

--- Perform a complete persuasion action
--- @param action string The action type (e.g., "admire", "bribe")
--- @param npcRef tes3reference The NPC reference
--- @param bribeAmount number|nil The bribe amount (if action is bribe)
--- @return table result { success: boolean, response: string, xpAwarded: number }
function persuasion.performAction(action, npcRef, bribeAmount)
    -- Check if patience is depleted
    local patienceDepleted = patience.isDepleted(npcRef)

    -- Attempt the persuasion
    local success = false
    local hadEffect = false
    local xpAwarded = 0

    if not patienceDepleted then
        success = persuasion.attemptPersuasion(action, npcRef, bribeAmount)

        hadEffect = applyEffects(action, npcRef, success, bribeAmount)
		if hadEffect then
        xpAwarded = calculatePersuasionXP(action, success, npcRef, bribeAmount)
        awardSpeechcraftXP(xpAwarded)
		end
    end

    -- Get response text
    local response = persuasionResponses.getRandomResponse(npcRef, action, success, bribeAmount)

    -- Trigger custom event
    --- @class SmoothTalkerPersuasionEventData
    local eventData = {
        actionType = action,
        success = success,
        npcRef = npcRef,
        amount = bribeAmount,
        patienceDepleted = patienceDepleted
    }
    event.trigger("SmoothTalker:PersuasionTriggered", eventData)

    return {
        success = success,
        response = response,
        xpAwarded = xpAwarded,
        patienceDepleted = patienceDepleted
    }
end

--- Calculate the persuasion modifier for a gift item
--- @param item tes3item The item to calculate modifier for
--- @param data tes3itemData|nil The item data (condition, etc.)
--- @return number The persuasion modifier value
function persuasion.calculateItemPersuasionModifier(item, data)
    local value = item.value

    if (data) then
        if (item.maxCondition) then
            value = value * (data.condition / item.maxCondition)
        elseif (item.time) then
            value = value * (data.timeLeft / item.time)
        end
    end

    return value * persuasionModifiers.giftItemValueMultiplier
end

--- Check if gifting an item is illegal
--- @param item tes3item The item to check
--- @param npcRef tes3reference The NPC reference
--- @return string The illegal status (persuasion.ILLEGAL_STATUS)
function persuasion.isGiftIllegal(item, npcRef)
    -- Check if item was stolen from this NPC
    local isStolen, stolenList = tes3.getItemIsStolen({ item = item})
    if isStolen then
        for _, stolenFrom in pairs(stolenList) do
			if stolenFrom.objectType == tes3.objectType.faction then
				if stolenFrom.id == npcRef.baseObject.faction.id then
					return persuasion.ILLEGAL_STATUS.YES
				end
			elseif stolenFrom.objectType == tes3.objectType.npc then
				if stolenFrom.id == npcRef.baseObject.id then
					return persuasion.ILLEGAL_STATUS.YES
				end
			end
        end
    end

    -- Check for contraband items
    for _, illegalItemId in ipairs(persuasionModifiers.illegalItems) do
        if item.id == illegalItemId then
            return persuasion.ILLEGAL_STATUS.YES_IF_FAILED
        end
    end

    return persuasion.ILLEGAL_STATUS.NO
end

return persuasion
