local regenerationType = require("Magicka Regen Suite.regenerationType")
local config = require("Magicka Regen Suite.config")

local configCache = {}
local timeBeforeTravel = nil
local playerRefreshRate = 0.1
local fFatigueBase
local fFatigueMult

-- This function updates cached settings table
local function updateConfigCache(settings)
    if settings.eventType then
        settings.eventType = nil    -- Important, eventType shouldn't end up in configCache
    end
    if settings.version then
        settings.version = nil
    end
    configCache = table.copy(settings)

    for key, value in pairs(configCache) do
        if key == "regenerationType" or key == "useDecay" then
            --Nothing to do here
        elseif key == "magickaReturnSkyrim" or key == "magickaReturnMultOblivion" or key == "magickaReturnMultMorrowind" then
			configCache[key] = value / 1000
		elseif key == "decayExp" then
			configCache[key] = value / 10
		else
			configCache[key] = value / 100
		end
	end
end
-- This function return Total Magicka of a reference ref, which equals to base magicka + fortify magicka magnitude
local function maxMagicka(ref)
	return (ref.mobile.magicka.base + tes3.getEffectMagnitude{ reference = ref, effect = tes3.effect.fortifyMagicka })
end
-- This function returns True if reference is stunted
local function stunted(ref)
	return tes3.isAffectedBy{ reference = ref, effect = tes3.effect.stuntedMagicka }
end
-- Common fatigue term of mobile
local function fatigueTerm(mobile)
	return (fFatigueBase - fFatigueMult * (1 - mobile.fatigue.normalized))
end
-- This function restores the amount of Magicka to reference ref
local function restoreMagicka(ref, amount)
    tes3.modStatistic{ reference = ref, name = "magicka", current = amount }
end
-- This function returns reference to all actors in active cells, and optionally the player reference
local function actorsInActiveCells(includePlayer)
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
-- This function caluculates the amount of magicka a reference ref restores per second
local function MRS(ref, maxMana)
	local restored

	if configCache.regenerationType == regenerationType.morrowind then
		restored = maxMana * 0.01 * (configCache.magickaReturnBaseMorrowind + configCache.magickaReturnMultMorrowind * ref.mobile.willpower.current) * fatigueTerm(ref.mobile)

		if ref.mobile.inCombat then
			restored = restored * configCache.combatPenaltyMorrowind
		end

	elseif configCache.regenerationType == regenerationType.oblivion then
		restored = maxMana * 0.01 * (configCache.magickaReturnBaseOblivion + configCache.magickaReturnMultOblivion * ref.mobile.willpower.current)

	elseif configCache.regenerationType == regenerationType.skyrim then
		restored = maxMana * configCache.magickaReturnSkyrim

		if ref.mobile.inCombat then
			restored = restored * configCache.combatPenaltySkyrim
		end
	end

	if configCache.useDecay then
		restored = restored * ( 1 - ref.mobile.magicka.current / maxMana ) ^ configCache.decayExp
	end

	return restored * configCache.regSpeedModifier
end
-- This function test if magicka should be restored to a reference ref
local function test(ref, secondsPassed)
    -- NPCs and Creatures almost never have fortify magicka effect and they don't have birthsigns, so it is
	-- not necessary for them to have stunted() and maxMagicka() checks, but it is here for mod compatibility
    if stunted(ref) then return end

    local maxMana = maxMagicka(ref)

    if ref.mobile.magicka.current >= maxMana then return end

    local amount = MRS(ref, maxMana)

    if secondsPassed then
        amount = amount * secondsPassed
    end

    if (amount + ref.mobile.magicka.current) > maxMana then
        amount = maxMana - ref.mobile.magicka.current
        -- Clamp amount to not overflow
    end

    restoreMagicka(ref, amount)
end
local function processActors(includingPlayer, secondsPassed)
    for ref in actorsInActiveCells(includingPlayer) do
        if not ref.mobile then return end
        test(ref, secondsPassed)
    end
end


-- Regenerate magicka for Player, NPCs and Creatures in active cells based on time waited
local function waitMagicka(e)
	local hoursPassed = tes3.mobilePlayer.restHoursRemaining

	if e.count > 0 and e.hour > 1 then
        -- The sleep was interrupted
		hoursPassed = hoursPassed - (e.hour - 1)
	end

    processActors(true, hoursPassed * 3600)
end
-- Regenerate magicka for Player during travelling, no regen for NPCs and Creatures this time
-- because the Player has entered a new cell -> NPCs from last destination were unloaded
local function travelMagicka(e)
	if (not tes3.mobilePlayer.travelling) then    -- Get time before travelling
		timeBeforeTravel = tes3.getSimulationTimestamp()
	end

	if tes3.mobilePlayer.travelling then	-- Travel finished
		local hoursPassed = tes3.getSimulationTimestamp() - timeBeforeTravel
		timeBeforeTravel = nil

        test(tes3.player, hoursPassed * 3600)

        if e.companions then
            for ref in e.companions do
                test(ref, hoursPassed * 3600)
            end
        end
	end
end
local function actorRegen()
    processActors(false)
end
local function playerRegen()
    test(tes3.player, playerRefreshRate)
end
local function onMRS(e)
    local settings = table.copy(e)
    updateConfigCache(settings)
end

local function initialized()
    updateConfigCache(config.getConfig())
    -- We want do disable vanilla magicka restored on rest since this mod has its on calculation
    tes3.findGMST("fRestMagicMult").value = 0
	fFatigueBase = tes3.findGMST("fFatigueBase").value or 1.25
	fFatigueMult = tes3.findGMST("fFatigueMult").value or 0.5

	event.register("calcRestInterrupt", waitMagicka)
    event.register("calcTravelPrice", travelMagicka)
    event.register("loaded", function()
		timer.start{ iterations = -1, duration = 1, callback = actorRegen }
		timer.start{ iterations = -1, duration = playerRefreshRate, callback = playerRegen }
	end)
end


event.register("initialized", initialized)
event.register("modConfigReady", function()
	require("Magicka Regen Suite.mcm")
    event.register("MRS", onMRS)
end)
