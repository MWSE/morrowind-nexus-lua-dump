--[[

Mod: Pharis' Magicka Regeneration
Author: Pharis

--]]

local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local time = require("openmw_aux.time")
local types = require("openmw.types")
local util = require('openmw.util')

if core.API_REVISION < 39 then
    error("This mod requires a newer version of OpenMW, please update.")
end

local modInfo = require("Scripts.Pharis.PharisMagickaRegeneration.modinfo")

local generalSettings = storage.globalSection("SettingsGlobal" .. modInfo.name)
local gameplaySettings = storage.globalSection("SettingsGlobal" .. modInfo.name .. "Gameplay")

local max = math.max
local min = math.min

local TICKINTERVAL = time.second / 10

local runOnSelf
local stopTickTimerFn

local magickaHandlers = {}

-- Data saved and compared against each tick
local prevGameTime = -1
local prevGameTimeScale = -1

local regenSuppressed = false
local suppressRegenSecondsPassed = 0
local suppressRegenTotalSeconds = -1

-- Superfluous? Yeah probably but this stuff is accessed
-- a lot by a script running on every active actor
local fatigueStat = types.Actor.stats.dynamic.fatigue(self)
local healthStat = types.Actor.stats.dynamic.health(self)
local magickaStat = types.Actor.stats.dynamic.magicka(self)
local willpowerStat = types.Actor.stats.attributes.willpower(self)
local activeEffects = types.Actor.activeEffects(self)
local StuntedMagicka = core.magic.EFFECT_TYPE.StuntedMagicka

---Temporarily halt all magicka regeneration for the duration of the timer. If 'force' is false or nil 'seconds' values less
---than or equal to remaining timer duration will be ignored and higher values will overwrite and reset current timer. Pass a
---'force' value of true to always overide regardless of current timer remaining time.
---@param seconds number Timer duration in seconds.
---@param force any boolean or nil Force override any current timer regardless of time remaining.
---@return boolean Whether suppression was successfully applied.
local function suppressRegen(seconds, force)
	if (not force) and (seconds <= suppressRegenTotalSeconds - suppressRegenSecondsPassed) then return false end
	suppressRegenSecondsPassed = 0
	suppressRegenTotalSeconds = seconds
	regenSuppressed = true
	return true
end

---Remove active regeneration suppression. This will have no effect on
---regeneration stopped by the Stunted Magicka effect. Be wary of
---possible incompatibilities with other mods using the interface.
local function removeSuppression()
	suppressRegenSecondsPassed = 0
	suppressRegenTotalSeconds = -1
	regenSuppressed = false
end

local function magickaRegenTick()
	local currentMagickaCurrent = magickaStat.current
	local currentMagickaBase = magickaStat.base
	local currentGameTimeScale = core.getGameTimeScale()
	local currentGameTime = core.getGameTime()

	-- Early out if current >= base, checking anything else is just a waste
	-- Still need to save data on skipped ticks so it doesn't get out of date
	-- which would trigger excessive regen on next successful tick
	if (currentMagickaCurrent >= currentMagickaBase)
		or (healthStat.current <= 0)
		or (regenSuppressed)
		or (activeEffects:getEffect(StuntedMagicka) ~= nil)
		or (prevGameTime == -1)
		or (prevGameTimeScale == -1) then
		prevGameTimeScale = currentGameTimeScale
		prevGameTime = currentGameTime
		return
	end

	-- Fatigue
	-- Neutral fatigue ratio range [0.5, 0.75]
	local fatigueMultiplier = 1.0
	local fatigueRatio = util.clamp(fatigueStat.current / fatigueStat.base, 0, 1)
	if (fatigueRatio < 0.5) then
		if (fatigueRatio <= 0.25) then
			fatigueMultiplier = 0.5 + 1.4 * fatigueRatio
		else
			fatigueMultiplier = 0.7 + 0.6 * fatigueRatio
		end
	elseif (fatigueRatio > 0.75) then
		if (fatigueRatio <= 0.9) then
			fatigueMultiplier = 0.5 + (fatigueRatio * 2 / 3)
		else
			fatigueMultiplier = -0.25 + (1.5 * fatigueRatio)
		end
	end

	-- Willpower
	local currentWillpowerModified = willpowerStat.modified
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

	willpowerMultiplier = max(willpowerMultiplier, 1)

	-- Regeneration Decay
	local lowMagickaRegenerationBoostMultiplier = gameplaySettings:get("enableLowMagickaRegenerationBoost") and 1 + ((1 - currentMagickaCurrent / currentMagickaBase) / 2) or 1

	-- Apply multipliers
	local regenerationRate = 0.5 * gameplaySettings:get("baseMultiplier") * fatigueMultiplier * willpowerMultiplier * lowMagickaRegenerationBoostMultiplier

	-- Magicka per game second * game seconds passed since last tick
	local calculatedMagicka = {delta = (regenerationRate / max(currentGameTimeScale, prevGameTimeScale, 1)) * (currentGameTime - prevGameTime)}

	-- Run all registered handlers before clamping
	for _, handler in ipairs(magickaHandlers) do
		handler(calculatedMagicka)
	end

	-- Prevent overflow
	local magickaDelta = min(calculatedMagicka.delta, currentMagickaBase - currentMagickaCurrent)

	if (magickaDelta > 0) then
		magickaStat.current = magickaStat.current + magickaDelta
	end

	prevGameTime = currentGameTime
	prevGameTimeScale = currentGameTimeScale
end

-- Logic for determining whether the actor the script is on should recieve magicka ticks.
-- This check runs when an actor becomes active or whenever any settings are changed
-- and will automatically start or stop the magicka tick timer
local function updateSelfRunState()
	runOnSelf = generalSettings:get("modEnable") and ((types.Player.objectIsInstance(self) and gameplaySettings:get("enablePlayerRegeneration"))
		or (types.NPC.objectIsInstance(self) and gameplaySettings:get("enableNPCRegeneration"))
		or (types.Creature.objectIsInstance(self) and gameplaySettings:get("enableCreatureRegeneration")))

	if (runOnSelf) then
		if (stopTickTimerFn) then return end
		stopTickTimerFn = time.runRepeatedly(
			magickaRegenTick,
			TICKINTERVAL
		)
		return
	end

	-- Causes first tick after mod is re-enabled to be skipped to prevent huge amount of
	-- regen because of how much time has passed since mod was disabled
	prevGameTime = -1
	prevGameTimeScale = -1

	if (stopTickTimerFn) then stopTickTimerFn() end
end

generalSettings:subscribe(async:callback(updateSelfRunState))
gameplaySettings:subscribe(async:callback(updateSelfRunState))

local function onUpdate(dt)
	-- Ignore runOnSelf and timer state here as suppression timer should run out regardless
	if (regenSuppressed) then
		suppressRegenSecondsPassed = suppressRegenSecondsPassed + dt
		if (suppressRegenSecondsPassed >= suppressRegenTotalSeconds) then removeSuppression() end
	end
end

---Get remaining time on regeneration suppression timer in seconds.
---@return number seconds
local function getSuppressionSecondsRemaining()
	return suppressRegenTotalSeconds ~= -1 and suppressRegenTotalSeconds - suppressRegenSecondsPassed or 0
end

---Add new handler that will be called every regeneration tick
---to edit the magicka delta for that tick after stat-based
---calculations are done. Magicka delta will be clamped to
---prevent overflow after all handlers are called.
---@param handler function The handler
local function addMagickaHandler(handler)
	magickaHandlers[#magickaHandlers + 1] = handler
end

local interface = {
	version = 1,
	suppressRegen = suppressRegen,
	removeSuppression = removeSuppression,
	getSuppressionSecondsRemaining = getSuppressionSecondsRemaining,
	addMagickaHandler = addMagickaHandler
}

return {
	engineHandlers = {
		onActive = updateSelfRunState,
		onUpdate = onUpdate
	},
	interfaceName = "PharisMagickaRegeneration",
	interface = interface
}
