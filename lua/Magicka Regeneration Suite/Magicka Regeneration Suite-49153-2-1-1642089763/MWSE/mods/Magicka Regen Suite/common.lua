local regenerationFormula = require("Magicka Regen Suite.regenerationType")
local config = require("Magicka Regen Suite.config").config


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

event.register("initialized", function()
	local wc = tes3.worldController.weatherController
	sunriseHour = wc.sunriseHour
	nightStarHour = wc.sunsetHour + wc.sunsetDuration

	-- Disable vanilla magicka restoration on resting since this mod has its own calculation
	tes3.findGMST(tes3.gmst.fRestMagicMult).value = 0
end)

local function PCinInterior()
	return (tes3.player.cell.isInterior and not tes3.player.cell.behavesAsExterior)
end

local function isNight(hour)
    hour = hour or tes3.worldController.hour.value
    if (hour < sunriseHour or hour >= nightStarHour) then
        return true
    end

	return false
end

local function isVampire(ref)
	local result = false

	if ref == tes3.player and
	tes3.findGlobal("PCVampire").value == 1 then

		result = true
	else
		local obj = ref.baseObject and ref.baseObject or ref.object

		result = tes3.isAffectedBy({ reference = ref, effect = tes3.effect.vampirism }) or
				ref.object.script and vampireScriptIDs[ref.object.script.id:lower()] or
				obj.head and (obj.head.vampiric and true or false) or
				false
	end

	return result
end

local function maxMagicka(ref)
	return (ref.mobile.magicka.base + tes3.getEffectMagnitude({ reference = ref, effect = tes3.effect.fortifyMagicka }))
end

local function stunted(ref)
	return tes3.isAffectedBy({ reference = ref, effect = tes3.effect.stuntedMagicka })
end

local function getMagickaRestoredPerSecond(ref, maxMana)
	local restored

	if config.regenerationFormula == regenerationFormula.morrowind then
		restored = maxMana * 0.01 * (config.magickaReturnBaseMorrowind + config.magickaReturnMultMorrowind * ref.mobile.willpower.current) * ref.mobile:getFatigueTerm()

		if ref.mobile.inCombat then
			restored = restored * config.combatPenaltyMorrowind
		end

	elseif config.regenerationFormula == regenerationFormula.oblivion then
		restored = maxMana * 0.01 * (config.magickaReturnBaseOblivion + config.magickaReturnMultOblivion * ref.mobile.willpower.current)

	elseif config.regenerationFormula == regenerationFormula.skyrim then
		restored = maxMana * config.magickaReturnSkyrim

		if ref.mobile.inCombat then
			restored = restored * config.combatPenaltySkyrim
		end

	elseif config.regenerationFormula == regenerationFormula.logarithmicWILL then
		restored = maxMana * 0.01 * config.WILLa * math.log(ref.mobile.willpower.current, config.WILLBase)

		if config.WILLApplyCombatPenalty and ref.mobile.inCombat then
			restored = restored * config.WILLCombatPenalty
		end

		if config.WILLUseFatigueTerm then
			restored = restored * ref.mobile:getFatigueTerm()
		end

	elseif config.regenerationFormula == regenerationFormula.logarithmicINT then
		restored = config.INTa * math.log(ref.mobile.intelligence.current, config.INTBase) - config.INTb

		if config.INTApplyCombatPenalty and ref.mobile.inCombat then
			restored = restored * config.INTCombatPenalty
		end

		if config.INTUseFatigueTerm then
			restored = restored * ref.mobile:getFatigueTerm()
		end
	end

	if config.useDecay then
		restored = restored * ( 1 - ref.mobile.magicka.current / maxMana ) ^ config.decayExp
	end

	return restored * config.regSpeedModifier
end


local common = {}

function common.restoreIf(ref, secondsPassed, alot)
    -- NPCs and Creatures almost never have fortify magicka effect and they don't have birthsigns, so it is
	-- not necessary for them to have stunted() and maxMagicka() checks, but it is here for mod compatibility
	-- For example, MWSE-Lua NPC Birthsigns by Abot gives birthsigns to NPCs, which can then have Atronach birthsign
    if stunted(ref) then return 0 end

    local maxMana = maxMagicka(ref)
    local amount = getMagickaRestoredPerSecond(ref, maxMana) * ( secondsPassed or 1 )

	if alot then
		-- Don't restore more than maximum magicka
		if (ref.mobile.magicka.current >= maxMana and amount >= 0) then return 0 end

		-- This is a hack to allow restoring a lot of magicka when character's current magicka is lower than 0.
		-- Without this, one rest could restore up to 0 magicka (from a negative value), while the second nap 
		-- would take the magicka to full.
		tes3.modStatistic({ reference = ref, name = "magicka", current = amount })

		if ref.mobile.magicka.current > maxMana then
			amount = amount - (ref.mobile.magicka.current - maxMana)
			tes3.setStatistic({
				reference = ref,
				current = maxMana,
				name = "magicka"
			})
		end
	else
		if config.vampireChanges and isVampire(ref) then
			if PCinInterior() or isNight() then
				amount = amount * ( 1 + config.nightBonus )
			else
				amount = amount * ( 1 - config.dayPenalty )
			end
		end
		-- Don't restore more than maximum magicka
		if (ref.mobile.magicka.current >= maxMana and amount >= 0) then return 0 end

		-- Clamp positive total values to not overflow
		-- Negative values shouldn't be clamped. If for example, a character just had Fortify Magicka effect worn off,
		-- then their current magicka can be higher than maximum magicka. In such scenario, maxMagicka - currentMagicka
		-- could be more negative than total yielding wrong result
		if amount > 0 then
			amount = math.min(amount, (maxMana - ref.mobile.magicka.current))
		end

		tes3.modStatistic({ reference = ref, name = "magicka", current = amount })
	end

	return amount
end

function common.getActors(includePlayer)
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

return common