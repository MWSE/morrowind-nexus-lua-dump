-- ------------------------------ Evening Star : gifts_p --------------------
-- scripted gift logic. gift_1 (ability) and gift_3 (major perk spell) are
-- spell records granted in es_p; this file is for purely-scripted gifts.

-- ------------------------------ tunables ----------------------------------

local WARRIORS_CHARGE_PERCENT = 0.15

-- ------------------ warrior's charge (vivec gift 2) -----------
-- on combat start (G_combatTargetCount 0 -> >0) at follower+ tier with a
-- deity whose gift_2 is "warriors_charge", arm the next landed hit. on hit,
-- send a global event to apply % of base health as damage.

local lastCombatCount     = 0
local warriorsChargeArmed = false

local function trackWarriorsCharge()
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then
		warriorsChargeArmed = false
		lastCombatCount = 0
		return
	end
	local deity = ES.getCurrentDeity()
	if not deity or deity.gift_2 ~= "warriors_charge" then
		warriorsChargeArmed = false
		lastCombatCount = G_combatTargetCount or 0
		return
	end
	local level = ES.getDevotionLevel(ES.saveData.favor or 0)
	if level ~= "follower" and level ~= "devotee" then
		warriorsChargeArmed = false
		lastCombatCount = G_combatTargetCount or 0
		return
	end
	local count = G_combatTargetCount or 0
	if lastCombatCount == 0 and count > 0 then
		warriorsChargeArmed = true
	elseif count == 0 then
		warriorsChargeArmed = false
	end
	lastCombatCount = count
end
G_onFrameJobsSluggish.es_trackWarriorsCharge = trackWarriorsCharge

local function onLandedHit(target, attack)
	if not warriorsChargeArmed then return end
	if not target or not target:isValid() then return end
	warriorsChargeArmed = false

	core.sendGlobalEvent("EveningStar_warriorsCharge", {
		target  = target,
		percent = WARRIORS_CHARGE_PERCENT,
	})
	local deity = ES.getCurrentDeity()
	--if deity then
	--	messageBox(2, string.format("%s's Warrior's Charge strikes.", deity.name))
	--end
end
table.insert(G_landedHitJobs, onLandedHit)

-- ------------------------------ poet's charm (vivec gift 3) ---------------
-- prayer at devotee tier spawns the orb. two routes:
--   * shrine prayer (handled in es_prayer grantShrinePrayer) -- behind player
--   * pray power cast anywhere (handled here)   -- spawns in front
-- activating the orb arms the next NPC activation for the charm. cost is
-- paid only on a successful charm, deducted from this side when the global
-- confirms via the applied event. cell changes despawn the orb and end any
-- active charm -- see gifts_g for the global cleanup.

-- ------------------------------ sotha sil's reflection (gift 3) -----------
-- prayer at devotee tier spawns a light-blue orb. activating it applies a
-- 60s 100% Reflect to the player (engine-managed) and deducts 10% favor.
-- exposed for es_prayer grantShrinePrayer (shrine path) to call too.

local function spawnReflectionOrb(forward)
	if not ES.S.TOGGLE_ENABLED then return end
	local deity = ES.getCurrentDeity()
	if not deity or deity.gift_3 ~= "sothas_reflection" then return end
	if ES.getDevotionLevel(ES.saveData.favor or 0) ~= "devotee" then return end

	local cost = ES.C.GIFT_3_CAST_COST or 10
	if (ES.saveData.favor or 0) < cost then
		messageBox(3, "You lack the favor to invoke this gift.") -- no need for this, orb should only spawn if you are a devotee
		return
	end

	-- shrine prayer spawns behind (forward=false), pray power spawns in front
	local yaw = self.rotation:getYaw()
	local dir = util.vector3(math.sin(yaw), math.cos(yaw), 0):normalize()
	local sign = forward and 1 or -1
	local pos = self.position + dir * (120 * sign) + util.vector3(0, 0, 100)
	core.sendGlobalEvent("EveningStar_reflectionOrbSpawn", {
		position = pos,
		caster   = self.object,
	})
end
ES.spawnReflectionOrb = spawnReflectionOrb

-- favor cost paid when the global confirms the reflect was applied
G_eventHandlers.EveningStar_reflectionApplied = function()
	if not ES.S.TOGGLE_ENABLED then return end
	local deity = ES.getCurrentDeity()
	if not deity then return end
	local cost = ES.C.GIFT_3_CAST_COST or 10
	ES.modifyFavor(-cost, "g3_sothas_reflect")
	messageBox(2, string.format("You ponder the magicka around you as the great Wizard %s would.", deity.name))
	if ES.updateAbilities then ES.updateAbilities() end
end

-- orb expired without activation
G_eventHandlers.EveningStar_reflectionMissed = function()
	if not ES.S.TOGGLE_ENABLED then return end
	messageBox(3, "You do not ponder the orb.")
end

---- pray power cast -> dispatch the deity's gift_3 effect at devotee tier.
---- poet's charm spawns an orb in front; sotha sil's reflection orb too.
ES.onPrayed = function()
	if not ES.S.TOGGLE_ENABLED then return end
	if not ES.saveData.currentDeity then return end

	local deity = ES.getCurrentDeity()
	if not deity then return end
	if ES.getDevotionLevel(ES.saveData.favor or 0) ~= "devotee" then return end

	if deity.gift_3 == "poets_charm" then
		local yaw = self.rotation:getYaw()
		local dir = util.vector3(math.sin(yaw), math.cos(yaw), 0):normalize()
		local pos = self.position + dir * 120 + util.vector3(0, 0, 80)
		core.sendGlobalEvent("EveningStar_poetsCharmSpawn", {
			position = pos,
			caster   = self.object,
		})
	elseif deity.gift_3 == "sothas_reflection" then
		spawnReflectionOrb(true) -- pray power: spawn in front
	end
end

G_eventHandlers.EveningStar_poetsCharmApplied = function(data)
	if not ES.S.TOGGLE_ENABLED then return end
	local deity = ES.getCurrentDeity()
	if not deity then return end
	local cost = ES.C.GIFT_3_CAST_COST or 10
	ES.modifyFavor(-cost, "g3_cast")
	local name = data and data.npcName or "your subject"
	messageBox(2, string.format("%s lends you his charm. %s is moved.", deity.name, name))
	if ES.updateAbilities then ES.updateAbilities() end
end

-- orb activated but the player wasn't aimed at an npc, or the orb expired.
G_eventHandlers.EveningStar_poetsCharmMissed = function()
	if not ES.S.TOGGLE_ENABLED then return end
	messageBox(3, "The Poet's Charm has worn off.") -- The moment passes; the charm fades
end

-- orb armed: feedback for the player after they activate the orb.
G_eventHandlers.EveningStar_poetsCharmArmed = function()
	if not ES.S.TOGGLE_ENABLED then return end
	messageBox(2, "You move with the swagger of the great Warrior-Poet Vivec himself. The next person you speak to will be Charmed.")
end

-- player cell change: tell global to despawn orbs / clear charms / armed.
table.insert(G_cellChangedJobs, function(prevCell)
	core.sendGlobalEvent("EveningStar_poetsCharmCellChanged", {
		player = self.object,
	})
end)

-- ------------------------------ healer's gift (almalexia gift 2) ----------
-- passive Restore Health ability granted to player and each companion while
-- traveling together. magnitude scales with tier:
--   follower -> es_tt_almalexia_g2_low  (1 hp/s)
--   devotee  -> es_tt_almalexia_g2_high (2 hp/s)
-- removed when no companions, tier dropped, or deity changed. companion
-- spellbook writes happen on the global side -- see gifts_g.

local HEALERS_GIFT_LOW  = "es_tt_almalexia_g2_low"
local HEALERS_GIFT_HIGH = "es_tt_almalexia_g2_high"

local function healersGiftDesired()
	if not ES.S.TOGGLE_ENABLED then return nil end
	if not ES.saveData.currentDeity then return nil end
	local deity = ES.getCurrentDeity()
	if not deity or deity.gift_2 ~= "healers_gift" then return nil end

	local sd = I.SunsDusk and I.SunsDusk.getSaveData and I.SunsDusk.getSaveData() or nil
	if not sd or (sd.countCompanions or 0) == 0 then return nil end

	local level = ES.getDevotionLevel(ES.saveData.favor or 0)
	if level == "follower" then return HEALERS_GIFT_LOW  end
	if level == "devotee"  then return HEALERS_GIFT_HIGH end
	return nil
end

-- reconcile the player's own ability against the desired state
local function reconcileHealersGiftSelf(desired)
	local spells = typesActorSpellsSelf
	local hasLow, hasHigh = false, false
	for _, sp in pairs(spells) do
		if sp.id == HEALERS_GIFT_LOW  then hasLow  = true end
		if sp.id == HEALERS_GIFT_HIGH then hasHigh = true end
	end
	if desired ~= HEALERS_GIFT_LOW  and hasLow  then spells:remove(HEALERS_GIFT_LOW)  end
	if desired ~= HEALERS_GIFT_HIGH and hasHigh then spells:remove(HEALERS_GIFT_HIGH) end
	if desired == HEALERS_GIFT_LOW  and not hasLow  then spells:add(HEALERS_GIFT_LOW)  end
	if desired == HEALERS_GIFT_HIGH and not hasHigh then spells:add(HEALERS_GIFT_HIGH) end
end

-- send the current desired state + companion list to global. throttled so
-- we only push when the desired ability id or companion count changes.
local lastDesired = nil
local lastCount   = -1

local function syncHealersGift()
	local desired = healersGiftDesired()
	reconcileHealersGiftSelf(desired)

	local sd = I.SunsDusk and I.SunsDusk.getSaveData and I.SunsDusk.getSaveData() or nil
	local count = sd and sd.countCompanions or 0

	if desired == lastDesired and count == lastCount then return end
	lastDesired, lastCount = desired, count

	local companions = {}
	if sd and sd.companions then
		for _, c in pairs(sd.companions) do
			if c and c:isValid() then
				table.insert(companions, c)
			end
		end
	end
	core.sendGlobalEvent("EveningStar_healersGiftSync", {
		companions = companions,
		desired    = desired,
	})
end
G_onFrameJobsSluggish.es_healersGiftSync = syncHealersGift

-- ------------------------------ mother's grace (almalexia gift 3) ---------
-- at devotee tier, once per game day: when health falls below 10% or a blow
-- would be fatal, snap back to full and pay favor. the global side also
-- trips the esp resurrect mwscript as a backstop for true death, since a
-- single killing blow can be resolved by the engine before this frame runs
-- and there is no way to resurrect from lua.

local MOTHERS_GRACE_THRESHOLD = 0.10           -- fraction of max health
local MOTHERS_GRACE_COOLDOWN  = 24 * 60 * 60   -- one game day in seconds

local mothersGraceHealth = types.Actor.stats.dynamic.health(self)

local function mothersGraceActive()
	if not ES.S.TOGGLE_ENABLED then return false end
	if not ES.saveData.currentDeity then return false end
	local deity = ES.getCurrentDeity()
	if not deity or deity.gift_3 ~= "mothers_grace" then return false end
	return ES.getDevotionLevel(ES.saveData.favor or 0) == "devotee"
end

local function tickMothersGrace(dt)
	if dt == 0 then return end
	if not mothersGraceActive() then return end

	-- daily cooldown
	local now = core.getGameTime()
	if (ES.saveData.mothersGraceReadyAt or 0) > now then return end

	-- must afford the cost
	local cost = ES.C.GIFT_3_REVIVE_COST or 15
	if (ES.saveData.favor or 0) < cost then return end

	-- below 10% threshold also covers a fatal blow (current <= 0)
	if mothersGraceHealth.current > mothersGraceHealth.base * MOTHERS_GRACE_THRESHOLD then return end

	-- full health here; esp resurrect + vfx happen global side
	mothersGraceHealth.current = mothersGraceHealth.base
	core.sendGlobalEvent("EveningStar_mothersGraceRevive", { player = self.object })

	ES.modifyFavor(-cost, "g3_mothers_grace")
	ES.saveData.mothersGraceReadyAt = now + MOTHERS_GRACE_COOLDOWN

	local deity = ES.getCurrentDeity()
	messageBox(2, string.format("%s the Gracious Mother saves you from near-death.", deity and deity.name or "Almalexia"))
	if ES.updateAbilities then ES.updateAbilities() end
end
G_onFrameJobs.es_mothersGrace = tickMothersGrace

-- ------------------------------ sotha sil's insight (gift 2) --------------
-- at follower+ tier, while a detect spell is active, mirror t_mysticism_insight
-- onto the player at a favor-scaled magnitude. a single detect spell is enough;
-- multiple don't stack. tracked by delta so it never clobbers other insight
-- sources, reconciled to 0 when ineligible, and stripped on save.

local INSIGHT_EFFECT   = "t_mysticism_insight"
local insightAvailable = core.magic.effects.records[INSIGHT_EFFECT]
local insightMagnitude = 0  -- our current contribution, cleared on save

-- favor-scaled insight while a detect spell is active, else 0
local function desiredInsight()
	if not ES.S.TOGGLE_ENABLED then return 0 end
	if not insightAvailable then return 0 end
	if not ES.saveData.currentDeity then return 0 end
	local deity = ES.getCurrentDeity()
	if not deity or deity.gift_2 ~= "es_tt_sothasil_g2" then return 0 end
	local level = ES.getDevotionLevel(ES.saveData.favor or 0)
	if level ~= "follower" and level ~= "devotee" then return 0 end

	-- strongest single detect spell gates the effect; magnitudes don't stack
	local detect = math.max(
		typesActorActiveEffectsSelf:getEffect("detectanimal").magnitude,
		typesActorActiveEffectsSelf:getEffect("detectenchantment").magnitude,
		typesActorActiveEffectsSelf:getEffect("detectkey").magnitude
	)
	local gate = math.min(1, detect / 10)
	-- favor 20 = 0, 60 = 10, 100 = 20 (tier gate keeps it 60+)
	return math.floor(gate * ((ES.saveData.favor or 0) - 20) / 4)
end

-- reconcile our tracked contribution toward the desired magnitude
local function trackInsight()
	local want  = desiredInsight()
	local delta = want - insightMagnitude
	if delta ~= 0 then
		typesActorActiveEffectsSelf:modify(delta, INSIGHT_EFFECT)
		insightMagnitude = want
	end
end
G_onFrameJobsSluggish.es_trackInsight = trackInsight

-- strip our contribution before save so it isn't baked into the savegame
table.insert(G_onSaveJobs, function()
	if insightMagnitude ~= 0 then
		typesActorActiveEffectsSelf:modify(-insightMagnitude, INSIGHT_EFFECT)
		insightMagnitude = 0
	end
end)