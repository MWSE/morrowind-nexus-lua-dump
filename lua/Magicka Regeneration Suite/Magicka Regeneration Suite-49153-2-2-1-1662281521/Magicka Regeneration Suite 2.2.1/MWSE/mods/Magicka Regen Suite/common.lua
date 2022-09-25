local regenerationFormula = require("Magicka Regen Suite.regenerationType")
local config = require("Magicka Regen Suite.config").config

-- TODO
-- Fun fact: Fortify Attribute apparently affects the base value of the statistic, not just the current value.
-- Not sure if Fortify Skill works the same way. The only way to get the actual base value of an attribute is
-- to get it from the ref's npc record

local common = {}


local vampireScriptIDs = {
	["vampire_berne"] = true,
	["vampire_quarra"] = true,
	["vampire_aundae"] = true,
	["mararascript"] = true,
	["irarakscript"] = true,
	["mertascript"] = true,
	["mastriusscript"] = true,
}

local sunriseHour
local nightStarHour


event.register(tes3.event.initialized, function()
	local wc = tes3.worldController.weatherController
	sunriseHour = wc.sunriseHour
	nightStarHour = wc.sunsetHour + wc.sunsetDuration

	-- Disable vanilla magicka restoration on resting since this mod has its own calculation
	tes3.findGMST(tes3.gmst.fRestMagicMult).value = 0
end)

--- Returns `true` if the Player is in interior cell, excluding interiors behaving as exterior.
---@return boolean result
local function PCinInterior()
	local cell = tes3.player.cell
	return (cell.isInterior and not cell.behavesAsExterior)
end

--- Returns true if the `hour` is during night. If no `hour` is passed, the current in-game hour will be used.
---@param hour number?
---@return boolean result
local function isNight(hour)
    hour = hour or tes3.worldController.hour.value
    if (hour < sunriseHour or hour >= nightStarHour) then
        return true
    end

	return false
end

--- Returns `true` if `ref` is a Vampire.
---@param ref tes3reference Can be player, or NPC.
---@return boolean result
local function isVampire(ref)
	if ref == tes3.player
		and	tes3.findGlobal("PCVampire").value == 1 then

		return true
	else
		local obj = ref.baseObject and ref.baseObject or ref.object

		return (
			obj.head and (obj.head.vampiric and true or false) or
			tes3.isAffectedBy({ reference = ref, effect = tes3.effect.vampirism }) or
			ref.object.script and vampireScriptIDs[ref.object.script.id:lower()] or
			false
		)
	end
end

--- Returns `true` if the `ref` is stunted
---@param ref tes3reference
---@return boolean
local function stunted(ref)
	return tes3.isAffectedBy({ reference = ref, effect = tes3.effect.stuntedMagicka })
end

--- Returns the maximal amount of magicka an actor can currently have.
---@param reference tes3reference
---@return number
local function getMaxMagicka(reference)
	return (
		reference.mobile.magicka.base +
		tes3.getEffectMagnitude({
			reference = reference,
			effect = tes3.effect.fortifyMagicka
		})
	)
end

-- We store previously calculated values here not to calculate math.log() repeatedly.
local restoredCache = {
	morrowind = {},
	logarithmicINT = {}
}

--- Returns the amount of magicka a reference would regenerate per second.
---@param actor tes3mobileNPC|tes3mobilePlayer
---@param base number The actor's base magicka.
---@return number result
local function getMagickaRestoredPerSecond(actor, base)
	local restored

	if config.regenerationFormula == regenerationFormula.morrowind then
		restored = restoredCache.morrowind[actor.willpower.current]
		if not restored then
			restoredCache.morrowind[actor.willpower.current] = math.max(
				math.log(math.max(actor.willpower.current, 0.01), config.baseMorrowind)
				* config.scaleMorrowind - config.capMorrowind,
				0
			)
			restored = restoredCache.morrowind[actor.willpower.current]
		end

		if actor.inCombat then
			restored = restored * config.combatPenaltyMorrowind
		end

	elseif config.regenerationFormula == regenerationFormula.oblivion then
		restored = (
			base * 0.01
			* (config.magickaReturnBaseOblivion + config.magickaReturnMultOblivion * actor.willpower.current)
		)

	elseif config.regenerationFormula == regenerationFormula.skyrim then
		restored = base * config.magickaReturnSkyrim

		if actor.inCombat then
			restored = restored * config.combatPenaltySkyrim
		end

	elseif config.regenerationFormula == regenerationFormula.logarithmicWILL then
		mwse.log("[Magicka Regeneration Suite]: unexpected if condition entered in %s.\nPlease report this to C3pa.", debug.traceback())
		return 0

	elseif config.regenerationFormula == regenerationFormula.logarithmicINT then
		restored = restoredCache.logarithmicINT[actor.intelligence.current]
		if not restored then
			restoredCache.logarithmicINT[actor.intelligence.current] = math.max(
				math.log(math.max(actor.intelligence.current, 0,01), config.INTBase)
				 * config.INTScale - config.INTb,
				0
			)
			restored = restoredCache.logarithmicINT[actor.intelligence.current]
		end

		if config.INTApplyCombatPenalty and actor.inCombat then
			restored = restored * config.INTCombatPenalty
		end

		if config.INTUseFatigueTerm then
			restored = restored * actor:getFatigueTerm()
		end
	end

	if config.useDecay then
		restored = restored * ( 1 - actor.magicka.current / base ) ^ config.decayExp
	end

	return restored * config.regSpeedModifier
end


--------- Exposed functions ---------


---Restores the apropriate amount of magicka to the `ref`.
---@param ref tes3reference
---@param secondsPassed number? If `nil`, `secondsPassed = 1` is used.
---@param alot boolean? You should pass `true` here when restoring magicka after resting or travelling.
---@return number restoredAmount
function common.restoreIf(ref, secondsPassed, alot)
	secondsPassed = secondsPassed or 1
    if stunted(ref) then return 0 end

    local base = getMaxMagicka(ref)
	local current = ref.mobile.magicka.current
	---@diagnostic disable-next-line param-type-mismatch
    local amount = getMagickaRestoredPerSecond(ref.mobile, base) * secondsPassed

	if alot then
		-- Don't restore more than maximum magicka
		if ref.mobile.magicka.current >= base then return 0 end

		amount = math.min(current + amount, base)
		tes3.setStatistic({ reference = ref, name = "magicka", current = amount })
	else
		if config.vampireChanges and isVampire(ref) then
			if PCinInterior() or isNight() then
				amount = amount * ( 1 + config.nightBonus )
			else
				amount = amount * ( 1 - config.dayPenalty )
			end
		end
		-- Don't restore more than maximum magicka
		if (current >= base and amount > 0) then return 0 end

		-- Clamp positive total values to not overflow
		-- Negative values shouldn't be clamped. If for example, a character just had Fortify Magicka effect worn off,
		-- then their current magicka can be higher than maximum magicka. In such scenario, maxMagicka - currentMagicka
		-- could be more negative than total yielding wrong result
		if amount > 0 then
			amount = math.min(amount, (base - current))
		end

		tes3.modStatistic({ reference = ref, name = "magicka", current = amount })
	end

	return amount
end

---Returns an iterator over all the NPCs, creatures, and optionally the player in all active cells. Used in a for loop.\
--- ```
--- for ref in common.getActors(false) do
---     ...
--- end
--- ```
---@param includePlayer boolean|nil If `false`, the player will be excluded.
---@return tes3reference[]
function common.getActors(includePlayer)
	---@diagnostic disable-next-line return-type-mismatch
    return coroutine.wrap(function()
        for _, cell in pairs(tes3.getActiveCells()) do
            for ref in cell:iterateReferences({ tes3.objectType.npc, tes3.objectType.creature }) do
                coroutine.yield(ref)
            end
	   end
        if includePlayer then
            coroutine.yield(tes3.player)
        end
    end)
end

---Restores magicka to all actors in active cells excluding the player
---@param secondsPassed number|nil If `nil`, `secondsPassed = 1` is used.
---@param alot boolean|nil You should pass `true` here when restoring magicka after resting or travelling.
function common.processActors(secondsPassed, alot)
	for actor in common.getActors(false) do
		if actor.mobile then
			common.restoreIf(actor, secondsPassed, alot)
		end
    end
end

return common