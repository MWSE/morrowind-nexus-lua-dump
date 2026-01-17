self = require('openmw.self')
types = require('openmw.types')
core = require('openmw.core')
I = require('openmw.interfaces')
storage = require('openmw.storage')
async = require('openmw.async')
Actor = types.Actor
anim = require('openmw.animation')
nearby = require('openmw.nearby')
time = require('openmw_aux.time')
require "scripts.Better Elemental Shields.settings"
local actorLuck = Actor.stats.attributes.luck(self)
-- GMST values

local ELEMENTS = {
	fire = {
		shield = 'fireshield',
		damage = 'firedamage',
		damageSpell = 'BES_eleshield_fire_dmg',
		vfx = 'meshes/kurp/s/vfx_k_h_sfire.nif',
		castVfx = 'meshes/kurp/s/vfx_k_c_sfire.nif',
		castVfxRev = 'meshes/kurp/s/vfx_k_c_sfire_rev.nif',
		attackerVfx = 'meshes/e/magic_hit_dst.nif',
		vfxDelay = 0.1,
		vfxSetting = 'SHOW_SHIELD_VFX',
	},
	frost = {
		shield = 'frostshield',
		damage = 'frostdamage',
		damageSpell = 'BES_eleshield_frost_dmg',
		vfx = 'meshes/kurp/s/vfx_k_h_sice.nif',
		castVfx = 'meshes/kurp/s/vfx_k_c_sice.nif',
		castVfxRev = 'meshes/kurp/s/vfx_k_c_sice_rev.nif',
		attackerVfx = 'meshes/e/magic_hit_frost.nif',
		vfxDelay = 0.4,
		vfxSetting = 'SHOW_SHIELD_VFX',
	},
	lightning = {
		shield = 'lightningshield',
		damage = 'shockdamage',
		damageSpell = 'BES_eleshield_shock_dmg',
		vfx = 'meshes/kurp/s/vfx_k_h_ssho.nif',
		castVfx = 'meshes/kurp/s/vfx_k_c_ssho.nif',
		castVfxRev = 'meshes/kurp/s/vfx_k_c_ssho_rev.nif',
		attackerVfx = 'meshes/e/lightningbolts.NIF',
		vfxDelay = 0.35,
		vfxSetting = 'SHOW_SHIELD_VFX',
	},
	normal = {
		shield = 'shield',
		-- No damage/damageSpell - normal shield doesn't damage attackers
		--vfx = 'meshes/kurp/s2/ShieldOnHit.nif',
		vfx = 'meshes/kurp/s2/ShieldHit.nif',
		hitVfx = 'meshes/kurp/s2/h/hand01_pshield.nif',
		castVfx = nil,
		castVfxRev = 'meshes/kurp/s2/ShieldOnHit.nif',
		vfxDelay = 0.5,
		vfxSetting = 'SHOW_BARRIER_VFX',
	},
}

-- Build lookup tables from ELEMENTS
local SHIELD_TO_ELEMENT = {}  -- fireshield -> element data
local EFFECT_TO_ELEMENT = {}  -- firedamage, fireshield, weaknesstofire, resistfire -> element data

for name, data in pairs(ELEMENTS) do
	data.name = name
	data.settingsPrefix = name:upper()  -- FIRE, FROST, LIGHTNING, NORMAL for settings lookup
	SHIELD_TO_ELEMENT[data.shield] = data
	-- Map damage effect to this element (only for damaging shields)
	if data.damage then
		EFFECT_TO_ELEMENT[data.damage] = data
	end
	EFFECT_TO_ELEMENT[data.shield] = data
end
-- Additional effect mappings for elemental shields
EFFECT_TO_ELEMENT['weaknesstofire'] = ELEMENTS.fire
EFFECT_TO_ELEMENT['resistfire'] = ELEMENTS.fire
EFFECT_TO_ELEMENT['weaknesstofrost'] = ELEMENTS.frost
EFFECT_TO_ELEMENT['resistfrost'] = ELEMENTS.frost
EFFECT_TO_ELEMENT['weaknesstoshock'] = ELEMENTS.lightning
EFFECT_TO_ELEMENT['resistshock'] = ELEMENTS.lightning
-- Additional effect mappings for normal shield (defensive effects)
EFFECT_TO_ELEMENT['sanctuary'] = ELEMENTS.normal
EFFECT_TO_ELEMENT['reflect'] = ELEMENTS.normal
EFFECT_TO_ELEMENT['resistnormalweapons'] = ELEMENTS.normal
EFFECT_TO_ELEMENT['resistmagicka'] = ELEMENTS.normal
EFFECT_TO_ELEMENT['resistparalysis'] = ELEMENTS.normal
EFFECT_TO_ELEMENT['spellabsorption'] = ELEMENTS.normal

local SLOW_SPELL = 'BES_eleshield_slow'
local WEAK_SPELL = 'BES_eleshield_weak'

-- Sound ability spell ID prefix (BES_soundbuff_1 through BES_soundbuff_20)
local SOUND_ABILITY_PREFIX = 'BES_soundbuff_'
-- Shield ability spell ID prefix (BES_eleshield_armor_1 through BES_eleshield_armor_20)
local SHIELD_ABILITY_PREFIX = 'BES_eleshield_armor_'

-- Antilag: session storage to detect game restart (resets when game closes)
local sessionStorage = storage.playerSection('BES_session')
sessionStorage:setLifeTime(storage.LIFE_TIME.GameSession)

-- Track active VFX so we can remove them
local activeVfx = {}
for _, element in pairs(ELEMENTS) do
	activeVfx[element.shield] = false
end

-- Cached shield info (refreshed when simulation time changes)
local cachedShields = {}
local cacheTime = -1

-- Spell element cache (static, spells don't change)
local spellDB = {}

-- Get info about an active elemental shield effect on self
local function getShieldInfo(element)
	local effectId = element.shield
	local activeEffects = Actor.activeEffects(self)
	local effect = activeEffects:getEffect(effectId)
	local magnitude = effect.magnitude
	if magnitude <= 0 then
		return nil
	end
	
	-- Find the min duration from active spells contributing to this effect
	local minDuration = math.huge
	if MAX_DURATION < 9999 then
		for _, spell in pairs(Actor.activeSpells(self)) do
			for _, spellEffect in pairs(spell.effects) do
				if spellEffect.id == effectId then
					local dur = spellEffect.duration
					if dur and dur < minDuration then
						minDuration = dur
					end
				end
			end
		end
	end
	-- Get element-specific settings
	local prefix = element.settingsPrefix
	local damageMult = _G[prefix.."_DAMAGE_MULT"] or 1
	local radiusMult = _G[prefix.."_RADIUS_MULT"] or 1
	local slowHalf = _G[prefix.."_SLOW_HALF"]
	local stunMult = _G[prefix.."_STUN_MULT"] or 0
	local weakMult = _G[prefix.."_WEAK_MULT"] or 0
	
	local radius = RADIUS * radiusMult * 22

	local damage = effect.magnitude * damageMult
	if math.random() < damage % 1 then
		damage = damage + 1
	end
	damage = math.floor(damage)
	
	local slow = 0
	if slowHalf and slowHalf > 0 then
		slow = (1 - 0.5 ^ (magnitude / slowHalf)) * 100
	end
	local stun = magnitude * stunMult / 100
	local weak = magnitude * weakMult
	if element.shield == "shield" then
		magnitude = magnitude - saveData.currentShieldMagnitude
	end
	return {
		element = element,
		effectId = effectId,
		magnitude = magnitude,
		minDuration = minDuration,
		radius = radius,
		damage = damage,
		stun = stun,
		slow = slow,
		weak = weak,
	}
end

-- Refresh cached shield info if simulation time changed
local function refreshShieldCache()
	local now = core.getSimulationTime()
	if now == cacheTime then
		return
	end
	cacheTime = now
	cachedShields = {}
	for _, element in pairs(ELEMENTS) do
		cachedShields[element.shield] = getShieldInfo(element)
	end
end

-- Get cached shield info (auto-refreshes if needed)
local function getCachedShield(element)
	refreshShieldCache()
	return cachedShields[element.shield]
end

-- Check spell for elemental effects (cached)
local function getSpellElements(spell)
	local spellId = spell.id
	if not spellDB[spellId] then
		spellDB[spellId] = {}
		local seen = {}
		for _, effect in pairs(spell.effects) do
			local element = EFFECT_TO_ELEMENT[effect.id]
			if element and not seen[element.name] then
				table.insert(spellDB[spellId], element)
				seen[element.name] = true
			end
		end
	end
	return spellDB[spellId]
end

-- Update sound buff based on selected spell matching active shields
local function updateSoundBuff()
	local spell = Actor.getSelectedSpell(self)
	local newBuff = 0
	
	if spell then
		for _, element in ipairs(getSpellElements(spell)) do
			local shieldInfo = getCachedShield(element)
			if shieldInfo then
				local buffMag = shieldInfo.magnitude * ELEMENT_CASTCHANCE_BONUS
				newBuff = math.floor(math.max(1, math.min(20, buffMag)))
				break
			end
		end
	end
	
	if newBuff ~= saveData.currentSoundBuff then
		local spells = Actor.spells(self)
		if saveData.currentSoundBuff > 0 then
			spells:remove(SOUND_ABILITY_PREFIX .. saveData.currentSoundBuff)
		end
		if newBuff > 0 then
			spells:add(SOUND_ABILITY_PREFIX .. newBuff)
		end
		saveData.currentSoundBuff = newBuff
	end
end

-- Check if VFX should be shown for this shield
local function shouldShowVfx(shieldInfo)
	if not shieldInfo then
		return false
	end
	if not _G[shieldInfo.element.vfxSetting] then
		return false
	end
	return shieldInfo.magnitude >= MIN_MAGNITUDE
	and (MAX_DURATION > 9998 or shieldInfo.minDuration <= MAX_DURATION)
end

-- Remove all active VFX
local function removeAllVfx()
	for _, element in pairs(ELEMENTS) do
		if activeVfx[element.shield] then
			local vfxId = 'eleshield_' .. element.shield
			anim.removeVfx(self, vfxId)
			activeVfx[element.shield] = false
		end
	end
end

-- Update VFX for all elemental shields
local function updateVfx()
	if not ENABLED then
		removeAllVfx()
		return
	end

	for _, element in pairs(ELEMENTS) do
		local shieldInfo = getCachedShield(element)
		local shouldShow = shouldShowVfx(shieldInfo)
		local vfxId = 'eleshield_' .. element.shield
		
		if shouldShow and not activeVfx[element.shield] then
			if element.castVfx then
				anim.addVfx(self, element.castVfx, {})
			end
			anim.addVfx(self, element.vfx, {
				loop = true,
				vfxId = vfxId,
				--bonename = 'Bip01',
			})
			activeVfx[element.shield] = true
		elseif not shouldShow and activeVfx[element.shield] then
			async:newUnsavableSimulationTimer(element.vfxDelay or 0.35, function()
				if not activeVfx[element.shield] then
					anim.removeVfx(self, vfxId)
				end
			end)
			activeVfx[element.shield] = false
			if element.castVfxRev then
				anim.addVfx(self, element.castVfxRev, {})
			end
		end
	end
end

-- Remove all shield abilities
local function removeAllShieldAbilities()
	if saveData.currentShieldMagnitude > 0 then
		local spells = Actor.spells(self)
		spells:remove(SHIELD_ABILITY_PREFIX .. saveData.currentShieldMagnitude)
		saveData.currentShieldMagnitude = 0
	end
end

-- Remove sound buff ability
local function removeSoundBuff()
	if saveData.currentSoundBuff > 0 then
		local spells = Actor.spells(self)
		spells:remove(SOUND_ABILITY_PREFIX .. saveData.currentSoundBuff)
		saveData.currentSoundBuff = 0
	end
end

-- Update shield armor ability on self based on highest elemental shield magnitude
local function updateShieldAbilities()
	if not ENABLED then
		removeAllShieldAbilities()
		removeSoundBuff()
		return
	end

	local spells = Actor.spells(self)
	local totalMag = 0
	
	for _, element in pairs(ELEMENTS) do
		local shieldInfo = getCachedShield(element)
		if shieldInfo then
			-- Only count damaging shields for armor bonus
			-- Normal shield already provides armor in vanilla, so skip it
			if element.damage then
				totalMag = totalMag + shieldInfo.magnitude
			end
		end
	end
	
	-- Handle torch toggle for fire shield
	local fireElement = ELEMENTS.fire
	local shouldShow = FIRE_LIGHT and activeVfx[fireElement.shield]
	if shouldShow and not saveData.hasTorch then
		--print("on")
		async:newUnsavableSimulationTimer(0.07, function()
			core.sendGlobalEvent("ElementalShields_toggleTorch", {self, true})
		end)
		saveData.hasTorch = true
	elseif not shouldShow and saveData.hasTorch then
		--print("off")
		async:newUnsavableSimulationTimer(0.22, function()
			core.sendGlobalEvent("ElementalShields_toggleTorch", {self, false})
		end)
		saveData.hasTorch = false
	end
	
	local shieldMult = SHIELD_MULT or 0.2
	local scaledMag = totalMag * shieldMult
	
	local desiredMag = 0
	if scaledMag > 0 then
		desiredMag = math.max(1, math.min(20, math.ceil(scaledMag / 2)))
	end
	
	if desiredMag ~= saveData.currentShieldMagnitude then
		if saveData.currentShieldMagnitude > 0 then
			spells:remove(SHIELD_ABILITY_PREFIX .. saveData.currentShieldMagnitude)
		end
		if desiredMag > 0 then
			spells:add(SHIELD_ABILITY_PREFIX .. desiredMag)
		end
		saveData.currentShieldMagnitude = desiredMag
	end
end


-- Helper to add stacked effects for magnitudes over 20
local function addStackedEffect(effects, spellId, magnitude, name)
	if math.random() < magnitude % 1 then
		magnitude = magnitude + 1
	end
	magnitude = math.floor(magnitude)
	
	while magnitude >= 1 do
		local effectIndex = math.max(0, math.min(19, magnitude - 1))
		table.insert(effects, {
			id = spellId,
			effects = { effectIndex },
			stackable = true,
			name = name,
		})
		magnitude = magnitude - 20
	end
end

local function buildEffectList(shieldInfo, target)
	local effects = {}
	local element = shieldInfo.element
	
	addStackedEffect(effects, element.damageSpell, shieldInfo.damage, 'Elemental Shield')
	--addStackedEffect(effects, SLOW_SPELL, calculateSpeedReduction(target, shieldInfo.slow), 'Elemental Shield Slow')
	addStackedEffect(effects, WEAK_SPELL, shieldInfo.weak, 'Physical weakness')

	return effects
end

-- Apply shield damage to a target
local function applyShieldDamage(target, distanceToActor)
	if not target then return end
	
	for _, element in pairs(ELEMENTS) do
		-- Skip non-damaging shields (like normal shield)
		if element.damage then
			local shieldInfo = getCachedShield(element)
			if shieldInfo and (not distanceToActor or distanceToActor < shieldInfo.radius) then 
				local stun = math.random() < shieldInfo.stun and shieldInfo.magnitude
				local luck
				if stun then
					luck = actorLuck.modified
				end
				target:sendEvent('ElementalShields_damage', {
					effects = buildEffectList(shieldInfo, target),
					vfx = element.attackerVfx,
					onlyHostile = distanceToActor and true,
					stun = stun,
					luck = luck,
					slow = shieldInfo.slow
				})
			end
		end
	end
end

-- Handle being hit - check shields and send damage to attacker
local function onHit(attack)
	if not ENABLED then
		return
	end
	
	if not attack.attacker then
		return
	end
	
	if BEHAVIOUR == "On Attack" or BEHAVIOUR == "On Hit" and attack.successful then
		-- ok
	else
		return
	end
	
	if attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee 
	or attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Ranged and DAMAGE_RANGED_ATTACKERS then
		-- ok
	else
		return
	end
	
	applyShieldDamage(attack.attacker)
end

-- Check for any active damaging elemental shield (for aura damage)
local function hasAnyDamagingShield()
	for _, element in pairs(ELEMENTS) do
		if element.damage and getCachedShield(element) then
			return true
		end
	end
	return false
end

-- Update cooldowns and apply damage to nearby enemies
local function updateNearbyDamage(dt)
	if not ENABLED then return end
	
	local playerHasAura = BEHAVIOUR == "On Nearby" and hasAnyDamagingShield()
	if not ACTORS_HAVE_AURA and not playerHasAura then
		return
	end
	
	local playerPos = self.position
	for _, actor in ipairs(nearby.actors) do
		if actor ~= self.object and Actor.stats.dynamic.health(actor).current > 0 then
			local distance = (actor.position - playerPos):length()
			
			-- Player's aura damages nearby actors
			if playerHasAura then
				local maxRadius = RADIUS * 22 * math.max(1, LIGHTNING_RADIUS_MULT)
				if distance <= maxRadius then
					applyShieldDamage(actor, distance)
				end
			end
			
			-- Actors' auras damage player
			if ACTORS_HAVE_AURA and distance <= ACTORS_RADIUS * 22 then
				local actorEffects = Actor.activeEffects(actor)
				
				for _, element in pairs(ELEMENTS) do
					-- Skip non-damaging shields (like normal shield)
					if element.damage then
						local effect = actorEffects:getEffect(element.shield)
						if effect and effect.magnitude > 0 then
							local magnitude = effect.magnitude * ACTORS_DAMAGE_MULT
							if math.random() < magnitude % 1 then
								magnitude = magnitude + 1
							end
							magnitude = math.min(20, math.floor(magnitude))
							
							if magnitude >= 1 then
								local activeSpells = Actor.activeSpells(self)
								activeSpells:add({
									id = element.damageSpell,
									effects = { magnitude - 1 },
									stackable = true,
									name = 'Elemental Shield',
								})
								anim.addVfx(self, element.attackerVfx)
							end
						end
					end
				end
			end
		end
	end
end
if I.Combat then
	I.Combat.addOnHitHandler(function(attack)
		onHit(attack)
	end)
end
local function onUpdate(dt)
	updateVfx()
	updateShieldAbilities()
	updateSoundBuff()
end

local function onElementalShieldDamage(data)
	if not data.damageSpell or not data.effectIndex then
		return
	end
	
	local activeSpells = types.Actor.activeSpells(self)
	
	activeSpells:add({
		id = data.damageSpell,
		effects = { data.effectIndex },
		stackable = true,
		name = 'Elemental Shield',
	})
	
	if data.vfx then
		anim.addVfx(self, data.vfx)
	end
end

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if skillId == "alteration" then
		async:newUnsavableSimulationTimer(0.01, onUpdate)
	end
end)


local function onLoad(data)
	saveData = data or {
		hasTorch = false,
		currentShieldMagnitude = 0,
		currentSoundBuff = 0,
	}
	saveData.currentSoundBuff = 0
		
	for _, element in pairs(ELEMENTS) do
		local vfxId = 'eleshield_' .. element.shield
		anim.removeVfx(self, vfxId)
		activeVfx[element.shield] = false
	end

	local rnd = math.random()
	stopTimerFn = time.runRepeatedly(onUpdate, 0.5 * time.second, {
		type = time.SimulationTime,
		initialDelay = rnd
	})
	
	stopTimerFn2 = time.runRepeatedly(updateNearbyDamage, 1 * time.second, {
		type = time.SimulationTime,
		initialDelay = rnd + 0.25
	})
	
	-- Antilag: add and remove all VFX after the game is restarted (sessionStorage resets on quitting the game)
	if not sessionStorage:get('antilagDone') then
		sessionStorage:set('antilagDone', true)
		for _, element in pairs(ELEMENTS) do
			local vfxId = 'eleshield_' .. element.shield
			anim.addVfx(self, element.vfx, { loop = true, vfxId = vfxId })
		end
		async:newUnsavableSimulationTimer(0.01, function()
			for _, element in pairs(ELEMENTS) do
				local vfxId = 'eleshield_' .. element.shield
				anim.removeVfx(self, vfxId)
			end
		end)
	end
end


local function onSave()
	return saveData
end

return {
	engineHandlers = {
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
	},
}