--[[

Mod: Pharis' Magicka Regeneration
Author: Pharis

--]]

local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local util = require('openmw.util')

-- Mod info
local modInfo = require("Scripts.Pharis.PharisMagickaRegeneration.modInfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Settings
local generalSettings = storage.globalSection("SettingsGlobal" .. modName)
local gameplaySettings = storage.globalSection("SettingsGlobal" .. modName .. "Gameplay")

local enableLowMagickaRegenerationBoost
local baseMultiplier

local runOnSelf

-- Other variables
local Actor = types.Actor

local attributeStats = Actor.stats.attributes
local dynamicStats = Actor.stats.dynamic

-- Data saved and compared against each tick
local actorData = {
	-- prevGameTimeScale,
	-- prevGameTime
}

local regenTickSecondsPassed = 0

local regenSuppressed = false
local suppressRegenSecondsPassed = 0
local suppressRegenTotalSeconds

local function updateSettings()
	local modEnable = generalSettings:get("modEnable")
	local enablePlayerRegeneration = gameplaySettings:get("enablePlayerRegeneration")
	local enableNPCRegeneration = gameplaySettings:get("enableNPCRegeneration")
	local enableCreatureRegeneration = gameplaySettings:get("enableCreatureRegeneration")
	enableLowMagickaRegenerationBoost = gameplaySettings:get("enableLowMagickaRegenerationBoost")
	baseMultiplier = gameplaySettings:get("baseMultiplier")

	runOnSelf = modEnable and ((types.Player.objectIsInstance(self) and enablePlayerRegeneration)
									or (types.NPC.objectIsInstance(self) and enableNPCRegeneration)
									or (types.Creature.objectIsInstance(self) and enableCreatureRegeneration))

	-- Causes first tick after mod is re-enabled to be skipped to prevent huge amount of
	-- regen because of how much time has passed since mod was disabled
	if (not runOnSelf) then
		actorData = {}
	end
end

generalSettings:subscribe(async:callback(updateSettings))
gameplaySettings:subscribe(async:callback(updateSettings))
--[[
local function suppressRegen(seconds)
	if (seconds <= suppressRegenTotalSeconds - suppressRegenSecondsPassed) then return end

	suppressRegenSecondsPassed = 0
	suppressRegenTotalSeconds = seconds
	regenSuppressed = true
end]]

local function magickaRegenTick()
	if (not runOnSelf) then return end

	local magickaStat = dynamicStats.magicka(self)
	local currentMagickaCurrent = magickaStat.current
	local currentMagickaBase = magickaStat.base
	local magickaRatio = currentMagickaCurrent / currentMagickaBase
	local currentGameTimeScale = core.getGameTimeScale()
	local currentGameTime = core.getGameTime()

	if (magickaRatio >= 1.0)
		or (regenSuppressed)
		or (not actorData.prevGameTimeScale)
		or (not actorData.prevGameTime) then
		actorData.prevGameTimeScale = currentGameTimeScale
		actorData.prevGameTime = currentGameTime
		return
	end

	-- Fatigue
	-- Neutral fatigue ratio range [0.5, 0.75]
	local fatigueMultiplier = 1.0
	local fatigueStat = dynamicStats.fatigue(self)
	local fatigueRatio = math.max(0, fatigueStat.current / fatigueStat.base)
	util.clamp(fatigueRatio, 0, 1)

	if (fatigueRatio >= 0.5) and (fatigueRatio <= 0.75) then
		goto NeutralFatigue
	end

	if (fatigueRatio <= 0.25) then
		fatigueMultiplier = 0.5 + 1.4 * fatigueRatio
	elseif (fatigueRatio <= 0.5) then
		fatigueMultiplier = 0.7 + 0.6 * fatigueRatio
	elseif (fatigueRatio <= 0.9) then
		fatigueMultiplier = 0.5 + (fatigueRatio * 2 / 3)
	elseif (fatigueRatio <= 1.0) then
		fatigueMultiplier = -0.25 + (1.5 * fatigueRatio)
	end

	::NeutralFatigue::

	-- Willpower
	local currentWillpowerModified = attributeStats.willpower(self).modified
	local willpowerMultiplier
	if (currentWillpowerModified <= 40) then
		willpowerMultiplier = 1 + currentWillpowerModified / 40
	elseif (currentWillpowerModified <= 60) then
		willpowerMultiplier = -2 + currentWillpowerModified / 10
	elseif (currentWillpowerModified <= 85) then
		willpowerMultiplier = -6.8 + 0.18 * currentWillpowerModified
	elseif (currentWillpowerModified <= 100) then
		willpowerMultiplier = currentWillpowerModified / 10
	elseif (currentWillpowerModified <= 200) then
		willpowerMultiplier = 5 + currentWillpowerModified / 20
	elseif (currentWillpowerModified <= 300) then
		willpowerMultiplier = 11 + currentWillpowerModified / 50
	elseif (currentWillpowerModified <= 500) then
		willpowerMultiplier = 14 + currentWillpowerModified / 100
	else
		willpowerMultiplier = 16.5 + currentWillpowerModified / 200
	end

	willpowerMultiplier = math.max(willpowerMultiplier, 1)

	-- Regeneration Decay
	local lowMagickaRegenerationBoostMultiplier = 1.0
	if (enableLowMagickaRegenerationBoost) then
		lowMagickaRegenerationBoostMultiplier = 1 + ((1 - magickaRatio) / 2)
	end

	-- Apply multipliers
	local regenerationRate = 0.5 * baseMultiplier * fatigueMultiplier * willpowerMultiplier * lowMagickaRegenerationBoostMultiplier

	-- Magicka per game second * game seconds passed since last tick
	local magickaDelta = (regenerationRate / math.max(currentGameTimeScale, actorData.prevGameTimeScale, 1)) * (currentGameTime - actorData.prevGameTime)

	-- Prevent overflow
	magickaDelta = math.min(magickaDelta, currentMagickaBase - currentMagickaCurrent)

	if (magickaDelta > 0) then
		magickaStat.current = magickaStat.current + magickaDelta
	end

	actorData.prevGameTime = currentGameTime
	actorData.prevGameTimeScale = currentGameTimeScale
end

local function onUpdate(dt)
	if (not runOnSelf)
		or (dynamicStats.health(self).current <= 0)
		or (Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.StuntedMagicka)) then return end
--[[
	if (regenSuppressed) then
		suppressRegenSecondsPassed = suppressRegenSecondsPassed + dt

		if (suppressRegenSecondsPassed >= suppressRegenTotalSeconds) then
			suppressRegenSecondsPassed = 0
			suppressRegenTotalSeconds = nil
			regenSuppressed = false
		end
	end]]

	regenTickSecondsPassed = regenTickSecondsPassed + dt

	if (regenTickSecondsPassed >= 0.1) then
		regenTickSecondsPassed = 0
		magickaRegenTick()
	end
end

-- Interface will be done later
--[[
local interface = {
	version = 1,
	suppressRegen = suppressRegen,
	getSuppressRegenTotalSeconds = getSuppressRegenTotalSeconds,
	getSuppressionSecondsPassed = getSuppressionSecondsPassed,
	-- applyMultiplier
	-- applyDelta
}
]]
return {
	engineHandlers = {
		onActive = updateSettings,
		onUpdate = onUpdate
	},
	-- interfaceName = "PharisMagickaRegeneration",
	-- interface = interface
}
