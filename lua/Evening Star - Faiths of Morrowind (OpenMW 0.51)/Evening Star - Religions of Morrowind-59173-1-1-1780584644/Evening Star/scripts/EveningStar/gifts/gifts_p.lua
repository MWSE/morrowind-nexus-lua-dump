-- ------------------------------ Evening Star : gifts_p --------------------
-- purely-scripted gift logic; gift_1 (ability) and gift_3 (perk spells) live in es_p

-- ------------------------------ tunables ----------------------------------

local WARRIORS_CHARGE_PERCENT = 0.15

-- ------------------------------ gift owner --------------------------------
-- find the active deity whose gift_<slot> == giftId -> (deity, deityId) or nil

local function activeDeityWithGift(slot, giftId)
	for _, deityId in ipairs(ES.saveData.activeDeities) do
		local deity = ES.getDeity(deityId)
		if deity and deity[slot] == giftId then
			return deity, deityId
		end
	end
	return nil
end

-- ------------------ warrior's charge (vivec gift 2) -----------
-- on combat start (follower+) with a warriors_charge deity, arm the next landed hit.
-- the hit sends a global event applying % of base health as damage.

local lastCombatCount     = 0
local warriorsChargeArmed = false

local function trackWarriorsCharge()
	local deity, deityId
	if ES.S.TOGGLE_ENABLED then
		deity, deityId = activeDeityWithGift("gift_2", "warriors_charge")
	end
	if not deity or ES.getDevotionLevel(deityId) < 2 then
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
end
table.insert(G_landedHitJobs, onLandedHit)

-- ------------------------------ poet's charm (vivec gift 3) ---------------
-- devotee orb; activating arms the next NPC activation for the charm.
-- cost is paid only on a successful charm, when the global sends the applied event.
-- cell change despawns the orb and ends active charms -- see gifts_g for cleanup.

-- shrine spawns behind the player, pray power in front; yawOffset fans multiple orbs out
local function spawnPoetsCharmOrb(forward, yawOffset)
	if not ES.S.TOGGLE_ENABLED then return end
	local deity, deityId = activeDeityWithGift("gift_3", "poets_charm")
	if not deity or ES.getDevotionLevel(deityId) < 3 then return end

	local yaw = self.rotation:getYaw() + (yawOffset or 0)
	local dir = util.vector3(math.sin(yaw), math.cos(yaw), 0):normalize()
	local sign = forward and 1 or -1
	local pos = self.position + dir * (120 * sign)
	core.sendGlobalEvent("EveningStar_poetsCharmSpawn", {
		position = pos,
		caster   = self.object,
	})
end
ES.spawnPoetsCharmOrb = spawnPoetsCharmOrb

-- ------------------------------ sotha sil's reflection (gift 3) -----------
-- devotee orb; activating applies a 60s 100% Reflect (engine-managed) and deducts favor.
-- exposed so es_prayer's shrine path can call it too.

local function spawnReflectionOrb(forward, yawOffset)
	if not ES.S.TOGGLE_ENABLED then return end
	local deity, deityId = activeDeityWithGift("gift_3", "sothas_reflection")
	if not deity or ES.getDevotionLevel(deityId) < 3 then return end
	
	local st = ES.saveData.deities[deityId]
	local cost = ES.C.GIFT_3_CAST_COST or 10
	if (st.favor or 0) < cost then
		messageBox(3, "You lack the favor to invoke this gift.") -- defensive; orb only spawns for devotees
		return
	end
	
	local yaw = self.rotation:getYaw() + (yawOffset or 0)
	local dir = util.vector3(math.sin(yaw), math.cos(yaw), 0):normalize()
	local sign = forward and 1 or -1
	local pos = self.position + dir * (120 * sign)
	core.sendGlobalEvent("EveningStar_reflectionOrbSpawn", {
		position = pos,
		caster   = self.object,
	})
end
ES.spawnReflectionOrb = spawnReflectionOrb

-- favor cost paid when the global confirms the reflect was applied
G_eventHandlers.EveningStar_reflectionApplied = function()
	if not ES.S.TOGGLE_ENABLED then return end
	local deity, deityId = activeDeityWithGift("gift_3", "sothas_reflection")
	if not deity then return end
	local cost = ES.C.GIFT_3_CAST_COST or 10
	ES.modifyFavor(deityId, -cost, "g3_sothas_reflect")
	messageBox(2, string.format("You ponder the magicka around you as the great Wizard %s would.", deity.name))
	ES.updateAbilities()
end

-- orb expired without activation
G_eventHandlers.EveningStar_reflectionMissed = function()
	if not ES.S.TOGGLE_ENABLED then return end
	messageBox(3, "You do not ponder the orb.")
end

-- spawn the gift_3 orbs for a set of prayed deities, fanned out so they don't clip when
-- you pray to several devotees at once. constant per-orb spacing keeps neighbors a fixed
-- distance apart at any count; the fan just widens, centered on facing.
-- forward = pray power (orbs in front), false = shrine (behind).
local ORB_FAN_SPACING = math.rad(35)
ES.spawnDevoteeOrbs = function(deities, forward)
	if not ES.S.TOGGLE_ENABLED then return end
	local orbs = {}
	for _, deity in ipairs(deities) do
		if deity and ES.getDevotionLevel(deity.id) == 3
			and (deity.gift_3 == "poets_charm" or deity.gift_3 == "sothas_reflection") then
			orbs[#orbs + 1] = deity
		end
	end
	for i, deity in ipairs(orbs) do
		local yawOffset = (i - 1 - (#orbs - 1) / 2) * ORB_FAN_SPACING
		if deity.gift_3 == "poets_charm" then
			spawnPoetsCharmOrb(forward, yawOffset)
		else
			spawnReflectionOrb(forward, yawOffset)
		end
	end
end

-- pray power cast: dispatch this deity's gift_3 orb (devotee tier), spawned in front
ES.onPrayed = function(deity)
	ES.spawnDevoteeOrbs({ deity }, true)
end

G_eventHandlers.EveningStar_poetsCharmApplied = function(data)
	if not ES.S.TOGGLE_ENABLED then return end
	local deity, deityId = activeDeityWithGift("gift_3", "poets_charm")
	if not deity then return end
	local cost = ES.C.GIFT_3_CAST_COST or 10
	ES.modifyFavor(deityId, -cost, "g3_cast")
	local name = data and data.npcName or "your subject"
	messageBox(2, string.format("%s lends you his charm. %s is moved.", deity.name, name))
	ES.updateAbilities()
end

-- orb activated but the player wasn't aimed at an npc, or the orb expired.
G_eventHandlers.EveningStar_poetsCharmMissed = function()
	if not ES.S.TOGGLE_ENABLED then return end
	messageBox(3, "The Poet's Charm has worn off.")
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
-- passive Restore Health for the player and each companion while traveling together.
-- magnitude scales with tier (follower low / devotee high); writes happen global side (gifts_g).

local HEALERS_GIFT_LOW  = "es_tt_almalexia_g2_low"
local HEALERS_GIFT_HIGH = "es_tt_almalexia_g2_high"

local function healersGiftDesired()
	if not ES.S.TOGGLE_ENABLED then return nil end
	local deity, deityId = activeDeityWithGift("gift_2", "healers_gift")
	if not deity then return nil end
	
	local sd = I.SunsDusk and I.SunsDusk.getSaveData and I.SunsDusk.getSaveData() or nil
	if not sd or (sd.countCompanions or 0) == 0 then return nil end
	
	local level = ES.getDevotionLevel(deityId)
	if level == 2 then return HEALERS_GIFT_LOW  end
	if level == 3 then return HEALERS_GIFT_HIGH end
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

-- push desired state + companion list to global, throttled to changes only.
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
-- devotee, once per game day: at <10% health or a fatal blow, heal to full and pay favor.
-- global also trips the esp resurrect mwscript as a backstop (a killing blow may resolve as fatal before this frame runs, and lua cannot resurrect).

local MOTHERS_GRACE_THRESHOLD = 0.10           -- fraction of max health
local MOTHERS_GRACE_COOLDOWN  = 24 * 60 * 60   -- one game day in seconds

local mothersGraceHealth = types.Actor.stats.dynamic.health(self)

local function tickMothersGrace(dt)
	if dt == 0 then return end
	if not ES.S.TOGGLE_ENABLED then return end
	-- mother's grace owner (almalexia-type) must be a devotee
	local deity, deityId = activeDeityWithGift("gift_3", "mothers_grace")
	if not deity or ES.getDevotionLevel(deityId) ~= 3 then return end
	local st = ES.saveData.deities[deityId]
	if not st then return end
	
	-- daily cooldown, per deity
	local now = core.getGameTime()
	if (st.mothersGraceReadyAt or 0) > now then return end
	
	-- must afford the cost
	local cost = ES.C.GIFT_3_REVIVE_COST or 15
	if (st.favor or 0) < cost then return end
	
	-- below 10% threshold also covers a fatal blow (current <= 0)
	if mothersGraceHealth.current > mothersGraceHealth.base * MOTHERS_GRACE_THRESHOLD then return end
	
	-- full health here; esp resurrect + vfx happen global side
	mothersGraceHealth.current = mothersGraceHealth.base
	core.sendGlobalEvent("EveningStar_mothersGraceRevive", { player = self.object })
	
	ES.modifyFavor(deityId, -cost, "g3_mothers_grace")
	st.mothersGraceReadyAt = now + MOTHERS_GRACE_COOLDOWN
	
	messageBox(2, string.format("%s the Gracious Mother saves you from near-death.", deity and deity.name or "Almalexia"))
	ES.updateAbilities()
end
G_onFrameJobs.es_mothersGrace = tickMothersGrace

-- ------------------------------ sotha sil's insight (gift 2) --------------
-- follower+: while a detect spell is active, add favor-scaled t_mysticism_insight (single detect is enough, no stacking).
-- delta-tracked so it never clobbers other insight sources;
-- reconciled to 0 when ineligible and stripped on save.

local INSIGHT_EFFECT   = "t_mysticism_insight"
local insightAvailable = core.magic.effects.records[INSIGHT_EFFECT]
local insightMagnitude = 0  -- our current contribution, cleared on save

-- favor-scaled insight while a detect spell is active, else 0
local function desiredInsight()
	if not ES.S.TOGGLE_ENABLED then return 0 end
	if not insightAvailable then return 0 end
	local deity, deityId = activeDeityWithGift("gift_2", "es_tt_sothasil_g2")
	if not deity then return 0 end
	if ES.getDevotionLevel(deityId) < 2 then return 0 end
	local st = ES.saveData.deities[deityId]
	
	-- strongest single detect spell gates the effect; magnitudes don't stack
	local detect = math.max(
		typesActorActiveEffectsSelf:getEffect("detectanimal").magnitude,
		typesActorActiveEffectsSelf:getEffect("detectenchantment").magnitude,
		typesActorActiveEffectsSelf:getEffect("detectkey").magnitude
	)
	local gate = math.min(1, detect / 10)
	-- favor 20 = 0, 60 = 10, 100 = 20 (tier gate keeps it 60+)
	return math.floor(gate * ((st.favor or 0) - 20) / 4)
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