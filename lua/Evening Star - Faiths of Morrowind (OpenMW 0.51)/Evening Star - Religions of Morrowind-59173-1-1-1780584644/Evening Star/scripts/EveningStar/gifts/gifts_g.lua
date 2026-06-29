-- ------------------------------ Evening Star : gifts_g -------------------
-- global side of scripted gifts. both orbs have a 30s timeout and share the cell-change cleanup
-- poet's charm (gift 3): activating arms a 5-min disp-100 charm on the next NPC; cell change ends it.
-- sotha sil's reflection (gift 3): activating applies a 60s 100% Reflect; cell change only despawns an unused orb.

ES = ES or {}

-- ------------------------------ tunables ----------------------------------

local POETS_CHARM_ORB_ACTIVATOR    = "es_tt_vivec_g3_orb"
local POETS_CHARM_ORB_TIMEOUT      = 30        -- sim seconds before orb despawns
local POETS_CHARM_DURATION         = 5 * 60    -- game seconds (5 in-game min)
local POETS_CHARM_SPAWN_OFFSET_Z   = 115       -- spawn this much above the cast position

local REFLECTION_ORB_ACTIVATOR     = "es_tt_sothasil_g3_orb"
local REFLECTION_ORB_TIMEOUT       = 30        -- sim seconds before orb despawns
local REFLECTION_SPELL_ID          = "es_tt_sothasil_g3_reflect"
local REFLECTION_ORB_SPAWN_OFFSET_Z = 100      -- spawn this much above the cast position

local ORB_DESPAWN_VFX = {
	[POETS_CHARM_ORB_ACTIVATOR] = "meshes/e/magic_hit_rest.NIF",
	[REFLECTION_ORB_ACTIVATOR]  = "meshes/e/magic_hit_rest.NIF",
}

local ORB_DESPAWN_OFFSET = {
	[POETS_CHARM_ORB_ACTIVATOR] = v3(0, 0, -10),
	[REFLECTION_ORB_ACTIVATOR]  = v3(0, 0, -40),
}
-- ------------------------------ state -------------------------------------

-- ephemeral, in-flight orbs: { [orb.id] = { orb, caster, expiry, recordId, missedEvent } }
local activeOrbs = {}

-- armed players (orb activated, awaiting NPC activation): { [player.id] = true }
local armedPlayers = {}

-- per-save data on saveData.EveningStar; the onLoad hook seeds the sub-tables.
table.insert(G_onLoadJobs, function()
	saveData.EveningStar = saveData.EveningStar or {}
	saveData.EveningStar.poetsCharms = saveData.EveningStar.poetsCharms or {}
	saveData.EveningStar.activeOrbs = saveData.EveningStar.activeOrbs or {}
	saveData.EveningStar.healersGift = saveData.EveningStar.healersGift or {}
	activeOrbs = saveData.EveningStar.activeOrbs
end)

-- ------------------------------ helpers -----------------------------------

-- stable id: contentFile + last 6 hex chars;
-- matches what world.getObjectByFormId can look back up via core.getFormId.
local function stableId(obj)
	if not obj.contentFile then return obj.id end
	return obj.contentFile .. "/" .. obj.id:sub(-6)
end


local function despawnOrb(orb)
	if not orb or not orb:isValid() then return end
	local vfx = ORB_DESPAWN_VFX[orb.recordId] or "meshes/e/magic_hit_rest.NIF"
	local offset = ORB_DESPAWN_OFFSET[orb.recordId] or v3(0, 0, 0)
	world.vfx.spawn(vfx, orb.position + offset, {
		useAmbientLight = false,
	})
	orb:remove()
end

-- despawn this player's orbs; with recordId, only that orb type, so distinct gift orbs coexist.
-- used on cell change (all types) and when a new orb replaces its own type for that player.
local function despawnOrbsFor(player, recordId)
	for id, entry in pairs(activeOrbs) do
		if entry.caster == player and (not recordId or entry.recordId == recordId) then
			despawnOrb(entry.orb)
			activeOrbs[id] = nil
		end
	end
end

-- revert every active charm to its saved original disposition.
local function revertAllCharms(player)
	if not player or not player:isValid() then return end
	for key, charm in pairs(saveData.EveningStar.poetsCharms) do
		if charm.contentFile and charm.refHex then
			local formId = core.getFormId(charm.contentFile, tonumber(charm.refHex, 16))
			local npc = world.getObjectByFormId(formId)
			if npc and npc:isValid() then
				types.NPC.setBaseDisposition(npc, player, charm.originalDisp or 50)
			end
		end
		saveData.EveningStar.poetsCharms[key] = nil
	end
end

-- ------------------------------ orb spawn ---------------------------------

G_eventHandlers.EveningStar_poetsCharmSpawn = function(data)
	if not data or not data.position or not data.caster then return end
	if not data.caster:isValid() then return end
	
	-- only one poet orb per caster; replace any existing of this type
	despawnOrbsFor(data.caster, POETS_CHARM_ORB_ACTIVATOR)

	local orb = world.createObject(POETS_CHARM_ORB_ACTIVATOR, 1)
	orb:teleport(data.caster.cell, data.position + v3(0, 0, POETS_CHARM_SPAWN_OFFSET_Z), { onGround = false })
	activeOrbs[orb.id] = {
		orb         = orb,
		caster      = data.caster,
		expiry      = core.getSimulationTime() + POETS_CHARM_ORB_TIMEOUT,
		recordId    = POETS_CHARM_ORB_ACTIVATOR,
		missedEvent = "EveningStar_poetsCharmMissed",
	}
end

-- ------------------------------ reflection orb spawn ----------------------

G_eventHandlers.EveningStar_reflectionOrbSpawn = function(data)
	if not data or not data.position or not data.caster then return end
	if not data.caster:isValid() then return end
	
	despawnOrbsFor(data.caster, REFLECTION_ORB_ACTIVATOR)

	local orb = world.createObject(REFLECTION_ORB_ACTIVATOR, 1)
	orb:teleport(data.caster.cell, data.position + v3(0, 0, REFLECTION_ORB_SPAWN_OFFSET_Z), { onGround = false })
	activeOrbs[orb.id] = {
		orb         = orb,
		caster      = data.caster,
		expiry      = core.getSimulationTime() + REFLECTION_ORB_TIMEOUT,
		recordId    = REFLECTION_ORB_ACTIVATOR,
		missedEvent = "EveningStar_reflectionMissed",
	}
end

-- ------------------------------ orb activation ----------------------------
-- poet's charm orb -> arm caster for next NPC activation.
-- reflection orb -> apply the 60s reflect to caster, send back applied event.

I.Activation.addHandlerForType(types.Activator, function(object, actor)
	if not types.Player.objectIsInstance(actor) then return end
	local recordId = object.recordId:lower()
	
	if recordId == POETS_CHARM_ORB_ACTIVATOR then
		activeOrbs[object.id] = nil
		despawnOrb(object)
		
		armedPlayers[actor.id] = true
		actor:sendEvent("EveningStar_poetsCharmArmed")
		return false
	
	elseif recordId == REFLECTION_ORB_ACTIVATOR then
		activeOrbs[object.id] = nil
		despawnOrb(object)
		
		types.Actor.activeSpells(actor):add({
			id                = REFLECTION_SPELL_ID,
			effects           = { 0, 1 },
			ignoreReflect     = true,
			ignoreResistances = true,
			stackable         = false,
		})
		actor:sendEvent("EveningStar_reflectionApplied")
		return false
	end
end)

-- ------------------------------ npc activation ----------------------------
-- if the activating player is armed, charm the npc, pay favor,
-- dialog still opens normally (we don't return false), otherwise no-op.

I.Activation.addHandlerForType(types.NPC, function(object, actor)
	if not types.Player.objectIsInstance(actor) then return end
	if not armedPlayers[actor.id] then return end
	armedPlayers[actor.id] = nil
	
	-- apply charm; remember original for revert
	local original = types.NPC.getBaseDisposition(object, actor)
	types.NPC.setBaseDisposition(object, actor, 100)
	
	saveData.EveningStar.poetsCharms[stableId(object)] = {
		contentFile  = object.contentFile,
		refHex       = object.id:sub(-6),
		originalDisp = original,
		revertAt     = core.getGameTime() + POETS_CHARM_DURATION,
	}
	
	actor:sendEvent("EveningStar_poetsCharmApplied", {
		npcName = (types.NPC.record(object) or {}).name,
	})
end)

-- ------------------------------ cell change cleanup -----------------------
-- on cell boundary: despawn all this player's orbs, clear armed state, and revert active charm dispositions.
-- active reflection buffs persist on their engine timer.

G_eventHandlers.EveningStar_poetsCharmCellChanged = function(data)
	if not data or not data.player then return end
	despawnOrbsFor(data.player)
	armedPlayers[data.player.id] = nil
	revertAllCharms(data.player)
end

-- ------------------------------ per-tick sweep ----------------------------
-- expire stale orbs and revert charms whose timer is up.

local nextSweep = 0
G_onUpdateJobs.es_poetsCharmSweep = function(dt)
	local now = core.getSimulationTime()
	if now < nextSweep then return end
	nextSweep = now + 0.5
	
	-- orb timeouts
	for id, entry in pairs(activeOrbs) do
		if not entry.orb or not entry.orb:isValid() or now >= entry.expiry then
			activeOrbs[id] = nil
			despawnOrb(entry.orb)
			if entry.missedEvent and entry.caster and entry.caster:isValid() then
				entry.caster:sendEvent(entry.missedEvent)
			end
		end
	end
	
	-- charm reverts (game time so the timer advances with rest / wait)
	local gameTime = core.getGameTime()
	local player = world.players[1]
	for key, charm in pairs(saveData.EveningStar.poetsCharms) do
		if charm.revertAt and gameTime >= charm.revertAt then
			if charm.contentFile and charm.refHex and player and player:isValid() then
				local formId = core.getFormId(charm.contentFile, tonumber(charm.refHex, 16))
				local npc = world.getObjectByFormId(formId)
				if npc and npc:isValid() then
					types.NPC.setBaseDisposition(npc, player, charm.originalDisp or 50)
				end
			end
			saveData.EveningStar.poetsCharms[key] = nil
		end
	end
end

-- ------------------------------ healer's gift (almalexia gift 2) ----------
-- companion spellbook sync.
-- gifts_p sends the desired ability id (low / high / nil) and the live companion list on change.
-- we reconcile each companion's spellbook and clean up companions that left the list.

local HEALERS_GIFT_LOW  = "es_tt_almalexia_g2_low"
local HEALERS_GIFT_HIGH = "es_tt_almalexia_g2_high"

local function hasSpell(spellList, spellId)
	for _, sp in pairs(spellList) do
		if sp.id == spellId then return true end
	end
	return false
end

G_eventHandlers.EveningStar_healersGiftSync = function(data)
	if not data then return end
	local state = saveData.EveningStar.healersGift
	
	local desired = data.desired -- spell id or nil
	
	-- index incoming companions by stable id
	local incoming = {}
	for _, c in ipairs(data.companions or {}) do
		if c and c:isValid() then
			incoming[stableId(c)] = c
		end
	end
	
	-- reconcile each incoming companion against desired
	for id, c in pairs(incoming) do
		local current        = state[id]
		local currentAbility = current and current.ability or nil
		if currentAbility ~= desired then
			local sp = types.Actor.spells(c)
			if currentAbility and hasSpell(sp, currentAbility) then
				sp:remove(currentAbility)
			end
			if desired then
				if not hasSpell(sp, desired) then sp:add(desired) end
				state[id] = {
					contentFile = c.contentFile,
					refHex      = c.id:sub(-6),
					ability     = desired,
				}
			else
				state[id] = nil
			end
		end
	end
	
	-- clean up companions previously tracked but no longer in the list
	for id, info in pairs(state) do
		if not incoming[id] then
			if info.contentFile and info.refHex then
				local formId = core.getFormId(info.contentFile, tonumber(info.refHex, 16))
				local actor  = world.getObjectByFormId(formId)
				if actor and actor:isValid() then
					local sp = types.Actor.spells(actor)
					if hasSpell(sp, HEALERS_GIFT_LOW)  then sp:remove(HEALERS_GIFT_LOW)  end
					if hasSpell(sp, HEALERS_GIFT_HIGH) then sp:remove(HEALERS_GIFT_HIGH) end
				end
			end
			state[id] = nil
		end
	end
end

-- ------------------------------ mother's grace (almalexia gift 3) ---------
-- player side already healed and paid favor.
-- here we trip the esp resurrect mwscript (the only way back from an engine-fatal blow) and play a burst.
-- no-op if the player never actually died.

G_eventHandlers.EveningStar_mothersGraceRevive = function(data)
	if not data or not data.player or not data.player:isValid() then return end
	
	world.mwscript.getGlobalVariables(data.player).eveningstar_resurrect = 1
	
	local health = types.Actor.stats.dynamic.health(data.player)
	health.current = health.base
	
	world.vfx.spawn("meshes/e/magic_hit_rest.NIF", data.player.position + v3(0, 0, 40), {
		useAmbientLight = false,
	})
end