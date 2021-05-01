local configPath = "Magicka Regen Suite.config"
local timeBeforeTravel = nil
local fFatigueBase
local fFatigueMult
local config = require(configPath)
local b = {}
for i,v in pairs(config.getConfig()) do
	b[i] = v
end

-- Total magicka equals to base magicka + fortify magicka magnitude
local function maxMagicka (ref)
	return (ref.magicka.base + tes3.getEffectMagnitude{reference = ref, effect = tes3.effect.fortifyMagicka})
end
-- Common fatigue term
local function fatigueTerm (ref)
	return (fFatigueBase - fFatigueMult * (1 - ref.fatigue.normalized))
end
-- Return True if reference is stunted
local function stunted(ref)
	return tes3.isAffectedBy{reference = ref, effect = tes3.effect.stuntedMagicka}
end
-- Magicka restored per second
local function restoredMagicka(ref, maxMana)
	local restored
	local config = b

	-- Morrowind style regeneration
	if config.regenerationType == 0 then
		restored = maxMana * 0.01 * (config.fMagickaReturnBaseMorrowind + config.fMagickaReturnMultMorrowind * ref.willpower.current) * fatigueTerm(ref)

		if ref.inCombat then
			restored = restored * config.fCombatPenaltyMorrowind
		end

	-- Oblivion style regeneration
	elseif config.regenerationType == 1 then
		restored = maxMana * 0.01 * (config.fMagickaReturnBaseOblivion + config.fMagickaReturnMultOblivion * ref.willpower.current)

	-- Skyrim style regeneration
	elseif config.regenerationType == 2 then
		restored = maxMana * config.fMagickaReturnSkyrim

		if ref.inCombat then
			restored = restored * config.fCombatPenalty
		end
	end

	--Natural magicka regeneration formula:

	--restored = (ref.willpower.current / 100) * ( 1 - ref.magicka.current / maxMana ) ^ 2

	--Can be accomplished with Oblivion Style regeneration, with:
	--config.fMagickaReturnBaseOblivion = 0
	--config.fMagickaReturnMultOblivion = 0.01

	if config.bDecay then
		restored = restored * ( 1 - ref.magicka.current / maxMana ) ^ config.fDecayExp
	end

	return restored * config.regenerationSpeedModifier
end

-- Main magicka regeneration function for Player
local function regenMagickaPC()
	if stunted(tes3.player) then
		return
	end

	local maxMana = maxMagicka(tes3.mobilePlayer)
	local currentMana = tes3.mobilePlayer.magicka.current

	if ( currentMana < maxMana ) then
		-- Player's magicka is restored every 0.1 seconds
		currentMana = currentMana + restoredMagicka(tes3.mobilePlayer, maxMana) * 0.1

		tes3.setStatistic{
			reference = tes3.player,
			name = "magicka",
			current = math.clamp(currentMana, 0 , maxMana) --Magicka can't be lower then 0, even with Damage Magicka
		}
	end
end

-- Main magicka regeneration function for NPCs and Creatures
local function regenMagickaNPC()
	--NPCs and Creatures almost never have fortify magicka effect and they don't have birthsigns,
	--but checks are here for mod compatibility
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.actor, tes3.objectType.creature) do
		if ref.mobile then
			if stunted(ref.mobile.reference) then
				return
			end

			local maxMana = maxMagicka(ref.mobile)
			local currentMana = ref.mobile.magicka.current

			if ( currentMana < maxMana ) then
				currentMana = currentMana + restoredMagicka(ref.mobile, maxMana)

				tes3.setStatistic{
					reference = ref.mobile,
					name = "magicka",
					current = math.clamp(currentMana, 0, maxMana)
				}
			end
		end
	end
end

-- Regenerate magicka for Player and other NPCs and Creatures in Player's cell based on time waited
local function waitMagicka(e)
	local restHours = tes3.mobilePlayer.restHoursRemaining
	if e.count > 0 and e.hour > 1 then	--Hours passed if sleep was interrupted
		restHours = restHours - (e.hour - 1)
	end

	if (not stunted(tes3.player)) then
		local maxMana = maxMagicka(tes3.mobilePlayer)
		local currentMana = tes3.mobilePlayer.magicka.current

		if ( currentMana < maxMana ) then
			currentMana = currentMana + 3600 * restHours * restoredMagicka(tes3.mobilePlayer, maxMana)

			tes3.setStatistic{
				reference = tes3.player,
				name = "magicka",
				current = math.clamp(currentMana, 0, maxMana)
			}
		end
	end

	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.actor, tes3.objectType.creature) do
		if ref.mobile then
			if stunted(ref.mobile.reference) then
				return
			end

			local maxMana = maxMagicka(ref.mobile)
			local currentMana = ref.mobile.magicka.current

			if ( currentMana < maxMana ) then
				currentMana = currentMana + 3600 * restHours * restoredMagicka(ref.mobile, maxMana)

				tes3.setStatistic{
					reference = ref.mobile,
					name = "magicka",
					current = math.clamp(currentMana, 0, maxMana)
				}
			end
		end
	end
end

-- Regenerate magicka for Player during travelling, no regen for NPCs and Creatures this time
-- because the Player has entered a new cell -> NPCs from last destination were unloaded
local function travelMagicka()
	if (not tes3.mobilePlayer.travelling) then	--Time before travelling
		timeBeforeTravel = tes3.getSimulationTimestamp()
	end

	if tes3.mobilePlayer.travelling then	--Travel finished
		local hoursPassed = tes3.getSimulationTimestamp() - timeBeforeTravel
		timeBeforeTravel = nil

		if (not stunted(tes3.player)) then
			local maxMana = maxMagicka(tes3.mobilePlayer)
			local currentMana = tes3.mobilePlayer.magicka.current

			if ( currentMana < maxMana ) then
				currentMana = currentMana + 3600 * hoursPassed * restoredMagicka(tes3.mobilePlayer, maxMana)

				tes3.setStatistic{
					reference = tes3.player,
					name = "magicka",
					current = math.clamp(currentMana, 0, maxMana)
				}
			end
		end
	end
end

local function initialized()
	fFatigueBase = tes3.findGMST("fFatigueBase").value or 1.25
	fFatigueMult = tes3.findGMST("fFatigueMult").value or 0.5

	event.register("loaded", function()
		timer.start{iterations = -1, duration = 1, callback = regenMagickaNPC}
		timer.start{iterations = -1, duration = 0.1, callback = regenMagickaPC}
	end)
	event.register("calcRestInterrupt", waitMagicka)
	event.register("calcTravelPrice", travelMagicka)
end

event.register("initialized", initialized)
event.register("modConfigReady", function()
	require("Magicka Regen Suite.mcm")
end)