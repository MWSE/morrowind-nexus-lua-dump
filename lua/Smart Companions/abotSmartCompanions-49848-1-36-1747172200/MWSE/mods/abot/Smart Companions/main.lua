--[[
Smart Companions
see modConfigReady() / MCM panel definition for features
]]

-- begin configurable parameters
local defaultConfig = {
allowLooting = 1, -- 0 = No, 1 = Yes, No Overburdening, 2 = Yes, Overburdening
minValueWeightRatio = 5,
alwaysLootOrganic = true, -- always loot from organic containers (e.g. plants) regardless of value/weight ratio
maxDistance = 384,
allowProbes = true,
allowLockpicks = true,
allowMagic = true,
fixAlarm = true, -- followers are given 0 Alarm
fixAcrobatics = true, -- follower NPCs are given high acrobatics
fixWaterBreathing = true, -- follower NPCs are given water breathing
fixAthletics = true, -- follower NPCs are given high athletics
clampLevitate = true,  -- followers constant levitate abilities/curses are clamped
fixConstEnch = true, -- try and fix followers constant enchantment items overflow
fixAnim = false, -- try and fix actor looping anim
skipActivatingFollowerWhileSneaking = true, -- self explaining
AIfixOnActivate = 1, -- 0 = No, 1 = Companions, 2 = Any follower, 3 = Any actor
transparencyFixOnActivate = false, -- try and fix follower transparency on activate
scenicTravelling = 2, -- 0 = No, 1 = Companions, 2 = Any follower
noFriendlyFireMagic = 4, -- 0 = No, 1 = Companions, 2 = Any follower, 3 = Companions, no aggro, 4 = Any follower, no aggro
noFriendlyFireDamage = 4, -- 0 = No, 1 = Companions, 2 = Any follower, 3 = Companions, no aggro, 4 = Any follower, no aggro
friendlyFireSoulTrapping = true,
autoWarp = 2, -- 0 = No, 1 = Companions, 2 = Any follower
warpDistance = 680,
warpFightingCompanions = false,
warpWaterWalk = 2, -- 0 = No, 1 = Companions, 2 = All followers
warpLevitate = 1, -- 0 = No, 1 = Companions, 2 = All followers
autoAttack = 1, -- 0. No - 1. Yes, Only current companions - 2. Yes, Any follower
ignoreMannequinAttacks = true, -- ignore attacks from creatures/npc emulating mannequins/targets/practice dummies
autoBurden = false, -- burden non-companion followers on combat start
autoMoveCC = true, -- automove followers on cell change
muteCC = 1, -- disable attack/hello voices on cell change 0. No - 1. Yes, Only current followers - 2. Yes, Any actor
scanIntervalTweak = true,
scanInterval = 0, -- make followers more reactive, increase it if causeing problems
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium 3 = High, 4 = Higher, 5 = Max
}
-- end configurable parameters

local author = 'abot'
local modName = 'Smart Companions'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

--[[local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end]]

local config = mwse.loadConfig(configName, defaultConfig)
assert(config) -- just to avoid Lua diagnostic complains

-- to be reset in loaded()
local worldController, inputController
local player
local mobilePlayer
local lastCompanionRef
local lastTargetRef
local tes3gmst_fPickLockMult, tes3gmst_fTrapCostMult


local T3OT = tes3.objectType
local BOOK_T = T3OT.book
local CONT_T = T3OT.container
local DOOR_T = T3OT.door
local LIGH_T = T3OT.light
local LKPK_T = T3OT.lockpick
local PROB_T = T3OT.probe

local validLootTypes = {
[T3OT.alchemy] = true, [T3OT.ammunition] = true, [T3OT.apparatus] = true,
[T3OT.armor] = true, [BOOK_T] = true, [T3OT.clothing] = true,
[CONT_T] = true, [DOOR_T] = true, [T3OT.ingredient] = true,
[LIGH_T] = true, [LKPK_T] = true, [T3OT.miscItem] = true,
[PROB_T] = true, [T3OT.repairItem] = true, [T3OT.weapon] = true,
}

---local readableObjectTypes = table.invert(T3OT)

-- refreshed in modConfigReady()
local muteCC
local noFriendlyFireDamage, noFriendlyFireDamageCO
local noFriendlyFireMagic, noFriendlyFireMagicCO
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4, logLevel5

-- bah, only 200 local variables supported in the main
local L = {}

function L.updateFromConfig()
	muteCC = config.muteCC
	noFriendlyFireDamage = config.noFriendlyFireDamage
	noFriendlyFireMagic = config.noFriendlyFireMagic
	noFriendlyFireDamageCO = (noFriendlyFireDamage == 1)
		or (noFriendlyFireDamage == 3)
	noFriendlyFireMagicCO = (noFriendlyFireMagic == 1)
			or (noFriendlyFireMagic == 3)

	if tes3.mobilePlayer then
		L.registerDamage(noFriendlyFireDamage > 0)
		L.registerspellResist(noFriendlyFireMagic > 0)
	end
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	logLevel5 = logLevel >= 5
end
L.updateFromConfig()

local tes3_animationState_dying = tes3.animationState.dying
local tes3_animationState_dead = tes3.animationState.dead

local function isDead(mob)
	local result = false
	if mob.isDead then
		result = true
	else
		local actionData = mob.actionData
		if actionData then
			local animState = actionData.animationAttackState
			if animState then
				if (animState == tes3_animationState_dying)
				or (animState == tes3_animationState_dead) then
					result = true
				end
			end
		end
	end
	local health = mob.health
	if not health then
		return result
	end
	local health_current = health.current
	if not health_current then
		return result
	end
	-- as we are here fix possible health.current glitches
	if result then
		if health_current > 0 then
			health.current = 0
		end
		return true
	end
	if (health.normalized <= 0.025) -- health ratio <= 0.25%
	and (health_current > 0)
	and (health_current < 3)
	and (health.normalized > 0) then
		health.current = 0 -- kill when nearly dead, could be a glitch
		return true
	end
	return result
end

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_escort = tes3.aiPackage.escort
--- local tes3_aiPackage_wander = tes3.aiPackage.wander -- 200 variable max limit hit
--- nope no room local tes3_aiPackage_none = tes3.aiPackage.none

local tes3_actorType_creature = tes3.actorType.creature
local tes3_actorType_npc = tes3.actorType.npc

-- mobile.inCombat alone is not reliable /abot
local function inCombat(mob)
	if mob.inCombat then
		return true
	end
	if mob.combatSession then
		return true
	end
	if mob.actionData then
		if mob.actionData.target then
			return true
		end
	end
	--[[if mob.isAttackingOrCasting then
		return true
	end]]
	return false
end

local function getSetRefVariable(ref, variableId, newValue)

	local script = ref.object.script
	if not script then
		return nil
	end
	local script_context = script['context']
	if not script_context then
		return nil
	end

	local funcPrefix
	if logLevel1 then
		if newValue then
			funcPrefix = string.format('%s: getSetRefVariable("%s", "%s", %s)',
				modPrefix, ref.id, variableId, newValue)
		else
			funcPrefix = string.format('%s: getSetRefVariable("%s", "%s")',
				modPrefix, ref.id, variableId)
		end
	end

	if ref.attachments then
		if ref.attachments.variables then
			if not ref.attachments.variables.script then
				if logLevel5 then
					mwse.log('%s: "%s".attachments.variables.script = nil', funcPrefix, ref.id)
				end
				return nil
			end
		else
			if logLevel5 then
				mwse.log('%s: "%s".attachments.variables = nil', funcPrefix, ref.id)
			end
			return nil
		end
	else
		--[[if logLevel4 then
			mwse.log('%s: "%s".attachments = nil', funcPrefix, ref.id)
		end]]
		return nil
	end

	if logLevel5 then
		mwse.log(funcPrefix)
	end

-- WARNING!!!
-- ref.object.script.context.variable is only safe to use to detect if variable exists,
-- not to get/set its value!!!

	local success, value = pcall(
		function ()
			return script_context[variableId]
		end
	)
	if not (success and value) then
		if logLevel5 then
			mwse.log('%s: "%s" script_context["%s"] = %s, success = %s',
				funcPrefix, ref.id, variableId, value, success)
		end
		return nil
	end

	local ref_context = ref['context']
	if not ref_context then
		return value
	end
	if logLevel5 then
		mwse.log('%s: ref_context = %s', funcPrefix, ref_context)
	end

	-- need more safety
	local val = ref_context[variableId]
	if not val then
		return value
	end
	value = val
	if logLevel4 then
		mwse.log('%s: ref_context["%s"] was %s)', funcPrefix, variableId, value)
	end

	if not newValue then
		return value
	end

	local succ2, val2 = pcall(
		function ()
			ref_context[variableId] = newValue
			return ref_context[variableId]
		end
	)
	if not (succ2 and val2) then
		return value
	end
	if logLevel4 then
		mwse.log('%s: context["%s"] is %s)', funcPrefix, variableId, val2)
	end
	return val2
end

local function getRefVariable(ref, variableId)
	return getSetRefVariable(ref, variableId)
end

local function setRefVariable(ref, variableId, value)
	return getSetRefVariable(ref, variableId, value)
end

local function getCompanionVar(ref)
	local result = getRefVariable(ref, 'companion')
	if logLevel4 then
		mwse.log('%s: getCompanionVar("%s") = %s', modPrefix, ref.id, result)
	end
	return result
end

local function isCompanion(mobRef)
	local result = false
	local companion = getCompanionVar(mobRef)
	if companion
	and (companion == 1) then
		result = true
	end
	if logLevel4 then
		mwse.log('%s: isCompanion("%s") = %s', modPrefix, mobRef.id, result)
	end
	return result
end

local function getMobAiFollowOrEscortTarget(mob)
	local aiPlanner = mob.aiPlanner
	if not aiPlanner then
		return
	end
	local aiPackage = aiPlanner:getActivePackage()
	if not aiPackage then
		return
	end
	local aiType = aiPackage.type
	if (aiType == tes3_aiPackage_follow)
	or (aiType == tes3_aiPackage_escort) then
		return aiPackage.targetActor
	end
end

local tes3_aiBehaviorState_attack = tes3.aiBehaviorState.attack
local tes3_aiBehaviorState_flee = tes3.aiBehaviorState.flee
local attackBehaviors = {[tes3_aiBehaviorState_attack] = 'attacking',
	[tes3_aiBehaviorState_flee] = 'fleeing from'}

local function targetIsFriendlyWith(targetMob, attackerMob,
		companionOnly)

	local targetMobRef = targetMob.reference
	local targetMobId = targetMobRef.id
	local attackerMobId = attackerMob.reference.id
	local actionData = targetMob.actionData
	if actionData then
		local target = actionData.target
		if target == attackerMob then
			local aiBehaviorState = actionData.aiBehaviorState
			if (aiBehaviorState == tes3_aiBehaviorState_attack)
			or (aiBehaviorState == tes3_aiBehaviorState_flee) then
				if logLevel3 then
					mwse.log('%s: targetIsFriendlyWith("%s", "%s") = false as "%s" is %s "%s"',
						modPrefix, targetMobId, attackerMobId, targetMobId,
						attackBehaviors[aiBehaviorState], attackerMobId)
				end
				return false
			end
		end
	end
	local targetMobAItarget = getMobAiFollowOrEscortTarget(targetMob)
	if not targetMobAItarget then
		if logLevel3 then
			mwse.log('%s: targetIsFriendlyWith("%s", "%s") = false as "%s" has no AIfollow/escort target',
				modPrefix, targetMobId, attackerMobId, targetMobId)
		end
		return false
	end
	if companionOnly then
		if ( not getCompanionVar(targetMobRef) ) then
			if logLevel3 then
				mwse.log([[%s: targetIsFriendlyWith("%s", "%s") = false as not getCompanionVar("%s")]],
					modPrefix, targetMobId, attackerMobId, targetMobId)
			end
			return false
		end
	end
	if targetMobAItarget == attackerMob then
		if logLevel3 then
			mwse.log([[%s: targetIsFriendlyWith("%s", "%s") = true as "%s".AItarget == "%s"]],
				modPrefix, targetMobId, attackerMobId, targetMobId, attackerMobId)
		end
		return true
	end
	local attackerMobAItarget = getMobAiFollowOrEscortTarget(attackerMob)
	if targetMobAItarget == attackerMobAItarget then
		if logLevel3 then
			mwse.log([[%s: targetIsFriendlyWith("%s", "%s") = true as "%s".AItarget == "%s".AItarget == "%s"]],
				modPrefix, targetMobId, attackerMobId, targetMobId, attackerMobId, targetMobAItarget.reference.id)
		end
		return true
	end
	if targetMob == attackerMobAItarget then
		if logLevel3 then
			mwse.log([[%s: targetIsFriendlyWith("%s", "%s") = true as "%s".AItarget == "%s"]],
				modPrefix, attackerMobId, targetMobId, attackerMobId, targetMobId)
		end
		return true
	end

	local result = false
	if logLevel2 then
		mwse.log([[%s: targetIsFriendlyWith("%s", "%s") = %s,
targetMobAItarget == "%s"]],
			modPrefix, targetMobId, attackerMobId, result,
			targetMobAItarget.reference.id)
	end
	return result
end

local function areFriendly(targetMob, attackerMob, companionOnly)
	local result = targetIsFriendlyWith(targetMob, attackerMob, companionOnly)
		or targetIsFriendlyWith(attackerMob, targetMob, companionOnly)
	if logLevel1 then
		mwse.log('%s: areFriendly("%s", "%s") = %s',
			modPrefix, targetMob.reference.id, attackerMob.reference.id, result)
	end
	return result
end

local function decreaseHitCount(mob)
	local hitCount = mob.friendlyFireHitCount
	if hitCount > 0 then
		--- hitCount = hitCount - 1 -- not enoygh it seems
		--- mob.friendlyFireHitCount = hitCount
		mob.friendlyFireHitCount = 0
		if logLevel3 then
			mwse.log('%s: decreaseHitCount("%s") hitCount reset from %s to %s',
				modPrefix, mob.reference.id, hitCount, mob.friendlyFireHitCount)
		end
	end
end

local tes3_effect_soultrap = tes3.effect.soultrap
local tes3_effect_npcSoulTrap = 10000 -- tes3.effect.npc.npcSoulTrap

local function damage(e)
	if e.damage <= 0 then
		-- e.damage seems to be negative for magic
		-- and setting it to 0 does not work
		return
	end
	if e.magicSourceInstance then
		-- delegate to spellResist(e)
		return
	end
	local targetMob = e.mobile
	local attackerMob = e.attacker
	if not attackerMob then
		return
	end
	---if not attackerMob.actorType then
		---return
	---end

	if attackerMob == targetMob then
		return -- do nothing on self applied
	end

	if (attackerMob == mobilePlayer)
	and config.friendlyFireSoultrapping then
		if tes3.isAffectedBy({reference = targetMob,
				effect = tes3_effect_soultrap})
		or tes3.isAffectedBy({reference = targetMob,
				effect = tes3_effect_npcSoulTrap}) then
			if not getCompanionVar(targetMob.reference) then
				if logLevel1 then
					mwse.log('%s: damage() from "%s" to "%s" friendlyFireSoultrapping, skip',
						modPrefix, attackerMob.reference.id, targetMob.reference.id)
				end
				return -- skip if player soultrapping target
			end
		end
	end

	if areFriendly(targetMob, attackerMob, noFriendlyFireDamageCO) then
		if logLevel1 then
			mwse.log('%s: damage() %.04f blocked damage from "%s" to "%s"',
				modPrefix, e.damage, attackerMob.reference.id, targetMob.reference.id)
		end
		---local health = targetMob.health
		---health.current = health.current - e.damage
		e.damage = 0 -- it is positive/working if not from magic
		if noFriendlyFireDamage >= 3 then
			decreaseHitCount(targetMob)
			targetMob:stopCombat(true)
		end
		return false
	end

	if logLevel2 then
		mwse.log('%s: damage() %.04f damage done from "%s" to "%s"',
			modPrefix, e.damage, attackerMob.reference.id, targetMob.reference.id)
	end

end

local hugePriority = 999999999999

local skipNotify = false
--- @param e uiActivatedEventData
local function uiActivatedMenuNotify(e)
	if skipNotify then
		skipNotify = false
		e.element:destroy()
	end
end


--- @param e spellResistEventData
local function spellResist(e)
	if e.resistedPercent >= 100 then
		return
	end
	local source = e.source
	assert(source)
	local targetRef = e.target
	if not targetRef then
		return
	end
	local targetMob = targetRef.mobile
	if not targetMob then
		return
	end
	local attackerRef = e.caster
	if not attackerRef then
		return
	end
	local attackerMob = attackerRef.mobile
	if not attackerMob then
		return
	end
	local effect = e.effect
	local magicEffect
	if effect then
		magicEffect = effect.object
	end
	if not magicEffect then
		---assert(magicEffect) --- test
		if logLevel1 then
			mwse.log('%s: spellResist() undefined e.effect', modPrefix)
		end
		local effects = source.effects
		assert(effects)
		local effectIndex = e.effectIndex
		if effectIndex then
			effect = effects[effectIndex]
		elseif logLevel1 then
			mwse.log('%s: spellResist() undefined e.effectIndex', modPrefix)
		end
		if effect then
			magicEffect = effect.object
		else
		    local eff, mageff
			for i = 1, #effects do
			    eff = effects[i]
				mageff = eff.object
			    if mageff.isHarmful
				and (not mageff.id == tes3_effect_soultrap)
				and (not mageff.id == tes3_effect_npcSoulTrap) then
				    magicEffect = mageff
					break
				end
			end
		end
	end
	if not magicEffect then
		return
	end
	if not magicEffect.isHarmful then
		return
	end
	if (magicEffect.id == tes3_effect_soultrap)
	or (magicEffect.id == tes3_effect_npcSoulTrap) then
		if logLevel1 then
			mwse.log('%s: spellResist() from "%s" to "%s" soulTrapping, skip',
				modPrefix, attackerMob.reference.id, targetMob.reference.id)
		end
		return
	end
	if attackerMob then
		if attackerMob == targetMob then
			return -- do nothing on self effect
		end
		if (attackerMob == mobilePlayer)
		and config.friendlyFireSoultrapping then
			if tes3.isAffectedBy({reference = targetRef,
					effect = tes3_effect_soultrap})
			or tes3.isAffectedBy({reference = targetRef,
					effect = tes3_effect_npcSoulTrap}) then
				if not getCompanionVar(targetRef) then
					if logLevel1 then
						mwse.log('%s: spellResist() from "%s" to "%s" friendlyFireSoultrapping, skip',
							modPrefix, attackerRef.id, targetRef.id)
					end
					return -- skip if player soultrapping target
				end
			end
		end
	end

	if areFriendly(targetMob, attackerMob, noFriendlyFireMagicCO) then
		skipNotify = true
		e.resistedPercent = 100
		if logLevel1 then
			mwse.log('%s: spellResist() "%s" harmful magic effext from "%s" fully resisted by "%s"',
				modPrefix, magicEffect.name, attackerRef.id, targetRef.id)
		end
		if noFriendlyFireMagic >= 3 then
			decreaseHitCount(targetMob)
		end
		e.claim = true
	end
end

local damageRegistered = false
function L.registerDamage(on)
	local params = {priority = hugePriority}
	if damageRegistered then
		if on then
			return
		end
		event.unregister('damage', damage, params)
		damageRegistered = false
	elseif on then
		event.register('damage', damage, params)
		damageRegistered = true
	end
end

local spellResistRegistered = false
function L.registerspellResist(on)
	local params = {priority = hugePriority}
	if spellResistRegistered then
		if on then
			return
		end
		event.unregister('spellResist', spellResist, params)
		for i = 1, 3 do
			event.unregister('uiActivated', uiActivatedMenuNotify,
				{filter = 'MenuNotify' .. i, priority = hugePriority})
		end
		spellResistRegistered = false
	elseif on then
		for i = 1, 3 do
			event.register('uiActivated', uiActivatedMenuNotify,
				{filter = 'MenuNotify' .. i, priority = hugePriority})
		end
		event.register('spellResist', spellResist, params)
		spellResistRegistered = true
	end
end

-- special case for wandering destinations
-- e.g. companion scripted to do move-away using temporary aiwander
local function hasOneTimeMove(mobRef)
-- used by many companion scripts
	local result = getRefVariable(mobRef, 'oneTimeMove')
	if not result then
-- used by Striders Nest dests scripts
		result = getRefVariable(mobRef, 'c_move')
	end
	if not result then
-- used by some CMPartners scripts
		result = getRefVariable(mobRef, 'f_move')
	end
	if result
	and ( not (result == 0) ) then
		return true
	end
 -- used by some Lokken scripts
	result = getRefVariable(mobRef, 'wandertimer')
	if result
	and (result > 1) then
		return true
	end
	return false
end

local function isValidMobile(mob)
	local mobRef = mob.reference
	if not mobRef then
		if logLevel3 then
			assert(mobRef)
		end
		return false
	end
	if mobRef.disabled then
		return false
	end
	if mobRef.deleted then
		return false
	end
	if isDead(mob) then
		return false
	end
	if mob == mobilePlayer then
		return false
	end

	if mob.actorType == tes3_actorType_npc then
		return true
	end

	local mobObj = mobRef.object
	local lcId = string.lower(mobObj.id)
	if lcId == 'ab01guguarpackmount' then -- this is a good one
		return true
	end
	if string.startswith(lcId, 'ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort package, skip
		return false
	end
	local script = mobObj.script
	if script then
		local lcId2 = string.lower(script.id)
		if string.startswith(lcId2, 'ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort package, skip
			if logLevel3 then
				mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip", modPrefix, mobRef.id)
			end
			return false
		end
	end
	return true
end

-- 0 = invalid, 1 = follower, 2 = companion
local function validFollower(mob, anyFollower, checkWarpFightingCompanions)
	if (not mob.canMove) -- dead, knocked down, knocked out, hit stunned, or paralyzed.
	or (not isValidMobile(mob)) then
		return 0
	end
	local mobRef = mob.reference
	local mobIsCompanion = isCompanion(mobRef)
	local mobRefObj = mobRef.baseObject
	if checkWarpFightingCompanions then
		if not config.warpFightingCompanions then
			if mobIsCompanion
			or string.find(string.lower(mobRefObj.id), 'summon', 1, true) then
				if (not mob.canAct) -- drawing/sheathing their weapon, attacking, casting magic or using a lockpick or probe
				or inCombat(mob) then
					return 0
				end
			end
		end
	end

	local ai = tes3.getCurrentAIPackageId(mob)

	local aiPlanner = mob.aiPlanner
	if aiPlanner then
		local activePackage = aiPlanner:getActivePackage()
		if activePackage then
			ai = activePackage.type
			if (ai == tes3_aiPackage_follow)
			or (ai == tes3_aiPackage_escort) then
				local targetActor = activePackage.targetActor
				if not (mobilePlayer == targetActor) then
					return 0
				end
			end
		end
	end

	if (ai == tes3_aiPackage_follow)
	or (ai == tes3.aiPackage.none) then
	---if ai == tes3_aiPackage_follow then
		if mobIsCompanion then
			return 2
		end
		if anyFollower then
			if not mobRefObj.isGuard then -- better to skip guards, could be temporarily following
				return 1
			end
		end
		return 0
	elseif ai == tes3_aiPackage_escort then
		if mobIsCompanion then
			if logLevel5 then
				mwse.log('%s: "%s" aiescort mobIsCompanion = %s',
					modPrefix, mobRef.id, mobIsCompanion)
			end
			return 2
		end
		return 0
	elseif (ai == tes3.aiPackage.wander)
	and mobIsCompanion
	and hasOneTimeMove(mobRef) then
			-- special case for wandering destinations
		return 2
	end
	return 0
end

local function isValidScenicFollower(mob)
	local anyFollower = config.scenicTravelling >= 2
	if validFollower(mob, anyFollower) > 0 then
		local mobRef = mob.reference
		local boundSize_y = mob.boundSize.y * mobRef.scale
		if boundSize_y > 80 then -- skip big mesh actors
			if logLevel2 then
				mwse.log('%s: isValidScenicFollower("%s"), boundSize.y %s, skipped', modPrefix, mobRef.id, boundSize_y)
			end
			return false
		end
		if logLevel3 then
			mwse.log('%s: isValidScenicFollower("%s")', modPrefix, mobRef.id)
		end
		return true
	end
	return false
end

local function round(x)
	return math.floor(x + 0.5)
end


local travelType = 0 -- 0 = none, 1 = boat, 2 = strider, 3 = gondola

 -- reset in loaded()
-- e.g. travellers[lcMobRefId] = {inv = mob.invisibility, acro = mob.acrobatics.current, ns = tns}
-- store invisibility, acrobatics, nospread
local travellers = {}
local numTravellers = 0
local doPackTravellers = false
local busyPackingTravellers = false

local actorRefs = {}

--- @param e objectInvalidatedEventData
local function objectInvalidated(e)
	if not (type(e.object) == 'userdata') then
		return -- bah hopefully this will be enough to skip weird data
	end
	local obj = e.object -- should be a tes3baseObject or a tes3reference
	if not obj then
		return
	end
	local id = obj.id
	if not id then
		return
	end
	local lcObjId = string.lower(id)
	if actorRefs[lcObjId] then
		actorRefs[lcObjId] = nil
	end
end

local function getActorRef(lcRefId)
	local ref = actorRefs[lcRefId]
	if ref then
		return ref
	end
	--[[ -- nope no idea why it does not fucking work here for 2nd actor clone while scenic travelling
	-- should hopefully be faster than tes3.getReference()
	-- cons: 72 hours expire, enough for our use case
	local mobileActors = worldController.allMobileActors
	local mob
	for i = 1, #mobileActors do
		mob = mobileActors[i]
		ref = mob.reference
		if ref then
			---mwse.log('ref = "%s"', ref)
			if string.lower(ref.id) == lcRefId then
				actorRefs[lcRefId] = ref
				return ref
			end
		end
	end]]
	ref = tes3.getReference(lcRefId)
	actorRefs[lcRefId] = ref
	return ref
end

function L.packTravellers()
	busyPackingTravellers = true
	local t = {}
	numTravellers = 0
	for lcMobRefId, v in pairs(travellers) do
		if v.inv then
			local mobRef = tes3.getReference(lcMobRefId)
			if mobRef then
				local mob = mobRef.mobile
				if mob then
					t[lcMobRefId] = v
					numTravellers = numTravellers + 1
				end
			end
		end
	end
	travellers = t
	busyPackingTravellers = false
end

function L.cleanTravellers()
	numTravellers = 0
	for k, v in pairs(travellers) do
		if v then
			if v.inv then
				v.inv = nil
			end
			if v.acro then
				v.acro = nil
			end
			if v.ns then
				v.ns = nil
			end
			travellers[k] = nil
		end
	end
	travellers = {}
end


local warpers = {} -- e.g. warpers[lcMobId] = speed
local doPackWarpers = false
local packingWarpers = false

function L.packWarpers()
	if packingWarpers then
		return
	end
	packingWarpers = true
	local t = {}
	local mobRef
	for lcMobRefId, speed in pairs(warpers) do
		---assert(speed)
		if speed then
			mobRef = getActorRef(lcMobRefId)
			if mobRef then
				t[lcMobRefId] = speed
			end
			---warpers[lcMobRefId] = nil
		end
	end
	warpers = t
	packingWarpers = false
	doPackWarpers = false
end

local maxSavedPlayerPositions = 30

-- e.g. lastPlayerPositions[i] = {cellId = v.cellId, pos = getVec3FromTable3(v.pos)}
-- note: lastPlayerPositions[i].pos can be set to nil

local lastPlayerPositions = {}

local doPackLastPlayerPositions = false
local packingLastPlayerPositions = false
function L.packLastPlayerPositions()
	if packingLastPlayerPositions then
		return
	end
	packingLastPlayerPositions = true
	local t = {}
	local j = 0
	for _, v in ipairs(lastPlayerPositions) do
		if v.pos then
			j = j + 1
			t[j] = v
		end
	end
	lastPlayerPositions = t
	packingLastPlayerPositions = false
	doPackLastPlayerPositions = false
end

local scenicTravelAvailable
local ab01ssDest, ab01boDest, ab01goDest, ab01compMount

 -- cached globals, found in modConfigReady
local ab01ssDestGlob, ab01boDestGlob, ab01goDestGlob
local ab01goAngleGlob, NPCVoiceDistanceGlob, ab01compMountedGlob

-- reset in loaded()
local currMountRef, currMountHandle, lastMountFacing

function L.getCurrMountRef(travelType)
-- travelType 0 = none, 1 = boat, 2 = strider, 3 = gondola, 4 = guar
	local mountPrefixesDict = {['ab01bo'] = 1, ['ab01ss'] = 2, ['ab01go'] = 3, ['ab01gu'] = 4}
	local mobs = tes3.findActorsInProximity({reference = player, range = 2048})
	local ref
	for i = 1, #mobs do
		local mob = mobs[i]
		if mob then
			ref = mob.reference
			local obj = ref.baseObject
			local idPrefix = string.lower( string.sub(obj.id, 1, 6) )
			local mp = mountPrefixesDict[idPrefix]
			if mp
			and (mp == travelType) then
				if travelType == 4 then
					local localVar = getRefVariable(ref, 'ab01compMount')
					if localVar
					and (localVar == 3) then
						if logLevel2 then
							mwse.log('%s: getCurrMountRef(travelType = %s) = %s, ab01compMount = %s',
								modPrefix, travelType, ref, localVar)
						end
						return ref
					end
				else
					local localVar = getRefVariable(ref, 'with_player')
					if localVar
					and (localVar == 1) then
						if logLevel2 then
							mwse.log('%s: getCurrMountRef(travelType = %s) = %s, with_player = %s',
								modPrefix, travelType, ref, localVar)
						end
						return ref
					end
				end
			end
		end
	end
	if logLevel1 then
		mwse.log('%s: getCurrMountRef(travelType = %s) = %s', modPrefix, travelType, ref)
	end
end

function L.initScenicTravelAvailable()
	if ab01boDestGlob then
		ab01boDest = round(ab01boDestGlob.value)
	end
	if ab01ssDestGlob then
		ab01ssDest = round(ab01ssDestGlob.value)
	end
	if ab01goDestGlob then
		ab01goDest = round(ab01goDestGlob.value)
	end

	if ab01boDest then
		scenicTravelAvailable = true
	elseif ab01ssDest then
		scenicTravelAvailable = true
	elseif ab01goDest then
		scenicTravelAvailable = true
	elseif ab01compMountedGlob then
		scenicTravelAvailable = true
		ab01compMount = 0
		if currMountRef then
			local localVar = getRefVariable(currMountRef, 'ab01compMount')
			if localVar then
				ab01compMount = localVar
			end
		end
	else
		scenicTravelAvailable = false
	end
end

local travelParams = {
	[1] = {spell = 'ab01boSailAbility', spread = 32, maxInLine = 5}, -- boat/riverstrider
	[2] = {spell = 'ab01ssMountAbility', spread = 27, maxInLine = 5}, -- strider
	[3] = {spell = 'water walking (unique)', spread = 22, maxInLine = 1}, -- gondola
	[4] = {spell = 'ab01mountNPCAbility', spread = 40, maxInLine = 1}, -- guar
}

-- updated in startMoveTravellers()
local travelRadStep = 0

local function getCosSin(a, radStep)
	local radStep2 = radStep * 2
	local radStep3 = radStep * 3
	local cosa = {
		[1] = math.cos(a),
		[2] = math.cos(a - radStep),
		[3] = math.cos(a + radStep),
		[4] = math.cos(a - radStep2),
		[5] = math.cos(a + radStep2),
		[6] = math.cos(a - radStep3),
		[7] = math.cos(a + radStep3),
	}
	local sina = {
		[1] = math.sin(a),
		[2] = math.sin(a - radStep),
		[3] = math.sin(a + radStep),
		[4] = math.sin(a - radStep2),
		[5] = math.sin(a + radStep2),
		[6] = math.sin(a - radStep3),
		[7] = math.sin(a + radStep3),
	}
	return cosa, sina
end

local pi = math.pi
local double_pi = pi * 2

local function normalizedAngle(a)
	local a = a % double_pi
	if a > pi then
		a = a - double_pi
	elseif a < -pi then
		a = a + double_pi
	end
	return a
end

local function checkTravelFacing()
	if not currMountRef then
		return
	end
	if not lastMountFacing then
		return
	end
	if tes3.is3rdPerson() then
		return
	end
	local mountFacing = currMountRef.facing
	local dza = normalizedAngle(mountFacing - lastMountFacing)
	lastMountFacing = mountFacing
	local abs_dza = math.abs(dza)
	if abs_dza < 0.0017 then
		return
	end
	-- update player facing relative to scenic transport creature
	local player1stPerson = tes3.player1stPerson
	---local fade = false
	---local dur = abs_dza / 175
	local sts = worldController.simulationTimeScalar
	local a = normalizedAngle(player1stPerson.facing + dza)
	worldController.simulationTimeScalar = sts * 0.01
	---if dur > 0.016 then
		---fade = true
		---tes3.fadeOut({duration = dur})
	---end
	player1stPerson.facing = a
	---if fade then
		---dur = abs_dza / 35
		---tes3.fadeIn({duration = dur})
	---end
	worldController.simulationTimeScalar = sts
	if logLevel3 then
		mwse.log([[%s: checkTravelFacing() deltaAngleZ = %s,
currMountRef.facing = %s, player1stPerson.facing = %s]],
			modPrefix, math.deg(dza), math.deg(mountFacing),
			math.deg(player1stPerson.facing))
	end
end

local followersInLine = 1
local movingTravellers = false

local function moveTravellers()
	if tes3ui.menuMode() then
		return
	end
	if travelType <= 0 then
		return
	end
	if busyPackingTravellers then
		return
	end

	checkTravelFacing()

	local tp = travelParams[travelType]
	local dist = tp.spread
	local a1, a2
	if travelType == 3 then -- gondola
		a1 = ab01goAngleGlob.value
		a1 = math.rad(a1)
		a2 = a1 --- + math.pi
	else
		a1 = player.facing
		a2 = a1
	end

	local dd = dist
	local cosa, sina = getCosSin(a1, travelRadStep)
	local angleIndex = 1


	local pPos, mobPos
	for lcMobRefId, t in pairs(travellers) do
		local invalid = true
		if t -- needed safety
		and t.inv then
			---mwse.log(">>> id = %s, t.inv = %s", id, t.inv)
			local mobRef = getActorRef(lcMobRefId)
			if mobRef then -- safety as any fake summon npc could disappear
				mobPos = mobRef.position
---mwse.log(">>> mobRef = %s, mobPos = %s", mobRef, mobPos)
				invalid = false
				pPos = player.position
				mobPos.z = pPos.z
				-- move behind the player to not interfere with player scenic view
				mobPos.x = pPos.x - (dist * sina[angleIndex])
				mobPos.y = pPos.y - (dist * cosa[angleIndex])
				mobPos.z = pPos.z -- again
				mobRef.facing = a2 -- look front
				---mwse.log(">>> angleIndex = %d, dist = %d, x = %s, y = %s", angleIndex, dist, mobPos.x, mobPos.y)
				if angleIndex < followersInLine then
					angleIndex = angleIndex + 1
				else
					angleIndex = 1
					dist = dist + dd -- if more than followersInLine one more step behind and reset angle
					---mwse.log(">>> angleIndex = %d, dist = %d, dd = %s", angleIndex, dist, dd)
				end
			end -- if mobRef
		end -- if t
		if invalid then
			travellers[lcMobRefId].inv = nil -- flag to be invalid/packed
			doPackTravellers = true
			if numTravellers > 0 then
				numTravellers = numTravellers - 1
			else
				break
			end
		end
	end -- for

	checkTravelFacing() -- repetita iuvant

	if doPackTravellers then
		L.packTravellers()
	end
end

local tes3_effect_levitate = tes3.effect.levitate

local levitateSpell, waterWalkSpell, burdenSpell -- created in modConfigReady()

---local slowFallAmount = 1 -- updated in modConfigReady()

local function isMount(mobRef)
	if string.multifind(string.lower(mobRef.id),
			{'guar', 'horse', 'mount'}, 1, true) then
		return true
	end
	return false
end

-- set in initOnce()
local ab01mountNPCAbility

local forceStayOutsideDict = table.invert({'guar','guar_feral','guar_pack'})

local function isStayOutside(mob)
	local mobRef = mob.reference
	if mobRef then
		local lcId = string.lower(mobRef.baseObject.id)
		if forceStayOutsideDict[lcId] then
			return true
		end
		local stayoutside = getRefVariable(mobRef, 'stayoutside')
		if stayoutside
		and (stayoutside == 1) then
			return true
		end
	end
	return false
end

local function clampSpellEffect(spell, effectId, value)
	local effectIndex = spell:getFirstIndexOfEffect(effectId) -- zero based
	if effectIndex
	and (effectIndex >= 0) then -- returns -1 if not found
		local effect = spell.effects[effectIndex + 1]
		if effect.max > value then
			effect.max = value
		end
		if effect.min > effect.max then
			effect.min = effect.max
		end
	end
end

local clampedLevitateMobs = {} -- reset in loaded()

-- try to avoid companions constant levitate effect overflow on cell change
local function clampMobLevitate(ref)
	local lcRefId = string.lower(ref.id)
	if clampedLevitateMobs[lcRefId] then
		return
	end
	local spells = tes3.getSpells({target = ref, spellType = tes3.spellType.ability,
		getRaceSpells = false, getBirthsignSpells = false })
	for i = 1, #spells do
		clampSpellEffect(spells[i], tes3_effect_levitate, 5)
	end
	spells = tes3.getSpells({target = ref, spellType = tes3.spellType.curse,
		getRaceSpells = false, getBirthsignSpells = false })
	for i = 1, #spells do
		clampSpellEffect(spells[i], tes3_effect_levitate, 5)
	end
	clampedLevitateMobs[lcRefId] = true
end

local function isAffectedByEffect(mobile, effectId)
	local a = mobile:getActiveMagicEffects({effect = effectId})
	if a
	and (#a > 0) then
		return true
	end
	return false
end

local function warpFollowers()
	if config.autoWarp <= 0 then
		return
	end
	if packingWarpers then
		return
	end
	if packingLastPlayerPositions then
		return
	end
	local stepDist = 64
	local minDist = 72
	local dist = 62
	local dd = 58
	local anyFollower = config.autoWarp >= 2
	local warpDist = config.warpDistance

	local funcPrefix = modPrefix .. ' warpFollowers()'

	local angleIndex = 1
	local validFollowers = {}

	local friendlyActors = mobilePlayer.friendlyActors
	local numFollowers = 0
	local clampLevitate = config.clampLevitate

	for j = 1, #friendlyActors do
		local mob = friendlyActors[j]
		local valid = validFollower(mob, anyFollower, true)
		if valid > 0 then
			numFollowers = numFollowers + 1
			local mobRef = mob.reference
			validFollowers[numFollowers] = {r = mobRef, v = valid}
			if clampLevitate then
				clampMobLevitate(mobRef)
			end
		end
	end
	if numFollowers == 0 then
		return
	end

	local tes3_effect_slowFall = tes3.effect.slowFall
	local tes3_effect_waterWalking = tes3.effect.waterWalking

	local steps = 5
	local k_steps = numFollowers / steps
	local warpRadStep = math.rad(60 / k_steps)
	local maxAfterWarpDist = round( (dd * k_steps) + minDist )
	local pcAngleZ = player.facing
	local cosa, sina = getCosSin(pcAngleZ, warpRadStep)
	local playerPos = player.position
	local pcCell = player.cell
	local playerHasSlowfall = tes3.isAffectedBy({reference = mobilePlayer,
		effect = tes3_effect_slowFall})
	local playerLevitate = mobilePlayer.levitate

	local function sameCellOrExterior(cell_1_id, cell_2)
		return (cell_1_id == cell_2.id)
		or (
			(cell_1_id == '') -- stored cell_1_id == '' means cell1 is exterior
		and (not cell_2.isInterior)
		)
	end

	local pathGridPositions = {}
	local pathGrid = pcCell.pathGrid
	if pathGrid
	and pathGrid.isLoaded then
		local nodes = pathGrid.nodes
		local j = 0
		for i = 1, #nodes do
			local node = nodes[i]
			local connectedNodes = node.connectedNodes
			if connectedNodes
			and (#connectedNodes > 0) then
				j = j + 1
				pathGridPositions[j] = node.position:copy()
			end
		end
	end
	local bigNegative = 0.0 - (math.fhuge * 0.1)

	local function alignToPlayerZ(mobRef, downOnly)
		local mobPos = mobRef.position
		local mobPosZ = mobPos.z
		local dz = mobPosZ - player.position.z
		local dzHalved = dz * 0.5
		if dz > 5 then
			mobPos.z = mobPosZ - dzHalved
		end
		if downOnly then
			return
		end
		if dz < -5 then
			mobPos.z = mobPosZ - dzHalved
			return
		end
	end

	for j = 1, #validFollowers do
		-- better refresh them
		local vf = validFollowers[j]
		local mobRef = vf.r
		local mob = mobRef.mobile
		local valid = vf.v
		local mobIsCreature = (mob.actorType == tes3_actorType_creature)
		local ok = true
		if playerHasSlowfall then
			if mobIsCreature then
				if isMount(mobRef) then
					ok = false
				end
			else
				if (ab01mountNPCAbility
				and tes3.isAffectedBy({reference = mobRef,
---@diagnostic disable-next-line: assign-type-mismatch
					effect = tes3_effect_slowFall, object = ab01mountNPCAbility})
				) then
					-- e.g. npc riding a ab01guguarpackmount, as we are here, try and reduce bounding box so guar can be activated
					if not mobRef.data then
						mobRef.data = {}
					end
					if not mobRef.data.ab01bsy then
						mobRef.data.ab01bsy = mob.boundSize.y
						mob.boundSize.y = 16
					end
				elseif mobRef.data then
					local ab01bsy = mobRef.data.ab01bsy
					if ab01bsy then
						mob.boundSize.y = ab01bsy
						mobRef.data.ab01bsy = nil
					end
				end
			end
		end -- if playerHasSlowfall

		local lcMobRefId = string.lower(mobRef.id)
		if ok then
			if playerLevitate > 0 then
				local validLev = (valid >= config.warpLevitate)
				if movingTravellers then
					if validLev
					and (mob.levitate <= 0) then
						mob.levitate = 1
						mob.isFlying = true
					end
				elseif validLev then
					if ( not isAffectedByEffect(mob, tes3_effect_levitate) )
					and ( not mob:isAffectedByObject(levitateSpell) ) then
						tes3.addSpell({reference = mobRef, spell = levitateSpell})
						---if movingTravellers and mobIsCreature then
							---mob.invisibility = 1 -- setInvisible to avoid aggro cliffracers
						---end
					elseif mob.levitate <= 0 then  -- try and fix weird case <= 0 too
						if logLevel1
						and (mob.levitate < 0) then  -- try and fix weird case <= 0 too
							mwse.log('%s: warning "%s".levitate = %s, setting it to 1',
								modPrefix, lcMobRefId, mob.levitate)
						end
						mob.levitate = 1
					end
					if mob.fatigue.current > 0 then
						alignToPlayerZ(mobRef)
					end
				end
			else
				if (not (mob.levitate == 0))
				or isAffectedByEffect(mob, tes3_effect_levitate) then
					---if movingTravellers and mobIsCreature then
						---mob.invisibility = 0
					---end
					if (mobilePlayer.lastGroundZ < bigNegative) -- player on the ground
					and (mob.lastGroundZ > bigNegative) -- npc not on the ground
					and mob.isFalling then
						local z = player.position.z + 8
						if logLevel3 then
							mwse.log("%s: mobRef.position.z = %s set to %s", modPrefix, mobRef.position.z, z)
						end
						tes3.removeEffects({reference = mobRef, effect = tes3_effect_levitate})
						mob.levitate = 0
						mob.isFalling = false -- fix for stuck falling anim
						mobRef.position.z = z
					end
					if logLevel3 then
						mwse.log('%s: tes3.removeSpell({reference = "%s", spell = levitateSpell})', modPrefix, lcMobRefId)
					end
					mob.levitate = 0 -- important!
					mob.isFlying = false -- important!
					if mob:isAffectedByObject(levitateSpell) then
						tes3.removeSpell({reference = mobRef, spell = levitateSpell})
					else
						-- may conflict with removeSpellEffects in local script?
						tes3.removeEffects({reference = mobRef, effect = tes3_effect_levitate})
					end
				end
				local mobIsEncumbered = mob.encumbrance.normalized >= 1
				if mobIsEncumbered
				and (mob.fatigue.current > 0) then
					alignToPlayerZ(mobRef, true) -- if encumbered only align down
				end
			end

			--- check for waterwalking
			if mob:isAffectedByObject(waterWalkSpell) then
				if mobilePlayer.waterWalking <= 0 then
					tes3.removeSpell({reference = mobRef, spell = waterWalkSpell})
					mob.waterWalking = 0
					-- nope conflict with removeSpellEffects in local script
					-- tes3.removeEffects({reference = mobRef, effect = tes3_effect_waterWalking})
				end
			elseif mobilePlayer.waterWalking == 1 then
-- comparison with standard 1 is important as it may be used as flag with different walues e.g. in guar mod
				if not movingTravellers then
				---or mobIsCreature then
					if (valid >= config.warpWaterWalk)
					and (mob.waterWalking <= 0) -- try and fix weird case < 0 too
					and ( not isAffectedByEffect(mob, tes3_effect_waterWalking) ) then
						tes3.addSpell({reference = mobRef, spell = waterWalkSpell})
					end
				end
			end

			if (not mob:isAffectedByObject(burdenSpell))
			and (
				(not movingTravellers)
				---or mobIsCreature
			) then
				if not warpers[lcMobRefId] then
					local mobSpeed = mob.speed.current
					local newMobSpeed = mobilePlayer.speed.current * 1.1
					if newMobSpeed > 200 then
						newMobSpeed = 200
					elseif newMobSpeed < 40 then
						newMobSpeed = 40
					end
					if mobSpeed < newMobSpeed then
						warpers[lcMobRefId] = mobSpeed
						tes3.setStatistic({reference = mob, name = 'speed', current = newMobSpeed})
					end
				end

				pcCell = player.cell -- better refresh it?
				local mobCell = mob.cell
				local notInPlayerCell = not (pcCell == mobCell)

				local newPosFound = 0
				doPackLastPlayerPositions = false

				local mobPos = mobRef.position:copy()
				local doWarp = false

				if notInPlayerCell then
					if pcCell.isOrBehavesAsExterior then
						doWarp = true
					else -- pc in real interior
						if mobCell.isOrBehavesAsExterior then
							-- mob in exterior like
							if not isStayOutside(mob) then
								doWarp = true
							end
						else -- mob in real interior different from pc one
							doWarp = true
						end
					end
				else
					local d = mobPos:distance(playerPos)
					if d > warpDist then
						doWarp = true
					end
				end

				if doWarp then
					local ori = mobRef.orientation
					if notInPlayerCell then
						ori = ori:copy()
					else
						mobRef.facing = pcAngleZ
					end
					ori.z = pcAngleZ
					local boundSize_y = mob.boundSize.y * mobRef.scale
					if boundSize_y > 64 then
						dist = dist + dd -- double for big mesh actors
					end

					local v, v_pos

					local function isBehindPlayer(v_pos)
						if math.abs(mobilePlayer:getViewToPoint(v_pos)) > 105 then
							return true
						end
						return false
					end

					local size = #lastPlayerPositions
					local d = 0
					for i = size, 1, -1 do -- first we look in stored player positions stack
						v = lastPlayerPositions[i]
						v_pos = v.pos
						if v_pos
						and sameCellOrExterior(v.cellId, pcCell) then
							d = v_pos:distance(playerPos)
							if d >= minDist then -- too far, warp
								if d <= maxAfterWarpDist then -- only if at least half way
									if isBehindPlayer(v_pos) then
										if tes3.testLineOfSight({position1 = v_pos:copy(), height1 = 120,
											position2 = playerPos:copy(), height2 = 96}) then
											-- in a clear place
											mobPos.z = v_pos.z
											mobPos.x = v_pos.x
											mobPos.y = v_pos.y
											newPosFound = 2
											if logLevel3 then
												mwse.log('%s: newPosFound = %s, dist = %s', funcPrefix, newPosFound, d)
											end
											v.pos = nil
											doPackLastPlayerPositions = true
											break
										else
											if logLevel4 then
												mwse.log('%s: not tes3.testLineOfSight({position1 = v_pos, position2 = playerPos}), skip', funcPrefix)
											end
											v.pos = nil
											doPackLastPlayerPositions = true
										end
									else -- if d <= maxAfterWarpDist
										if logLevel4 then
											mwse.log('%s: not isBehindPlayer(v_pos), skip', funcPrefix)
										end
										v.pos = nil
										doPackLastPlayerPositions = true
									end
								else
									if logLevel5 then
										mwse.log('%s: v_pos:distance(playerPos) = %s > maxAfterWarpDist = %s, skip', funcPrefix, d, maxAfterWarpDist)
									end
									v.pos = nil
									doPackLastPlayerPositions = true
								end -- if d <= warpDist
							else
								if logLevel4 then
									mwse.log('%s: v_pos:distance(playerPos) = %s < minDist = %s, skip', funcPrefix, d, minDist)
								end
								v.pos = nil
								doPackLastPlayerPositions = true
							end -- if d >= stepDist
						else
							if logLevel3 then
								mwse.log('%s: not sameCellOrExterior("%s", "%s")', funcPrefix, v.cellId, pcCell.id)
							end
							v.pos = nil
							doPackLastPlayerPositions = true
						end -- if v.pos
					end -- for i

					if doPackLastPlayerPositions then
						L.packLastPlayerPositions()
					end

					if newPosFound > 0 then
						if notInPlayerCell then
							if logLevel2 then
								mwse.log(
'%s: newPosFound = %s notInPlayerCell tes3.positionCell({mobRef = "%s", pos = %s, ori.z = %.02f, cell = "%s"})',
funcPrefix, newPosFound, mobRef, mobPos, math.deg(ori.z), pcCell)
							end
							tes3.positionCell({reference = mobRef, position = mobPos,
								orientation = ori, cell = pcCell})
						else
							if logLevel2 then
								mwse.log(
'%s: newPosFound = %s InPlayerCell mobRef = "%s", pos = %s, ori.z = %.02fs',
funcPrefix, newPosFound, mobRef, mobPos, math.deg(ori.z))
							end
						end -- if notInPlayerCell

					else -- newPosFound == 0
						-- in case no previous player position available, we look for a path grid point
						local dz
						for i = 1, #pathGridPositions do
							v_pos = pathGridPositions[i]
							dz = math.abs(playerPos.z - v_pos.z)
							if dz <= 224 then
								d = v_pos:distance(playerPos)
								if (d >= minDist)
								and (d <= maxAfterWarpDist)
								and isBehindPlayer(v_pos) then
									newPosFound = 2
									table.remove(pathGridPositions, i)
									if notInPlayerCell then
										tes3.positionCell({reference = mobRef, position = v_pos,
											orientation = ori, cell = pcCell})
										if logLevel2 then
											mwse.log(
[[%s: newPosFound = %s, notInPlayerCell = %s, mobRef = "%s", pos = %s, ori.z = %.02f, cell = "%s"]],
funcPrefix, newPosFound, notInPlayerCell, mobRef, v_pos, math.deg(ori.z), pcCell.editorname)
										end
									else
										mobPos.z = v_pos.z
										mobPos.x = v_pos.x
										mobPos.y = v_pos.y
										if logLevel2 then
											mwse.log(
[[%s: newPosFound = %s, notInPlayerCell = %s, mobRef = "%s", pos = %s, ori.z = %.02f]],
funcPrefix, newPosFound, notInPlayerCell, mobRef, v_pos, math.deg(ori.z))
										end
									end
									doPackLastPlayerPositions = true
									break
								end
							end
						end

						-- in case no previous player position/path grid point available,
						-- we look for a point behind player
						if newPosFound == 0 then
							mobPos.x, mobPos.y, mobPos.z =
								playerPos.x - (dist * sina[angleIndex]),
								playerPos.y - (dist * cosa[angleIndex]), playerPos.z

							if math.abs(mobilePlayer:getViewToPoint(mobPos)) > 105 then
								-- only if at player shoulders
								if tes3.testLineOfSight({position1 = mobPos:copy(), height1 = 120,
									position2 = playerPos:copy(), height2 = 96}) then
									-- in a clear place
									local from = mobRef.position
									local to = mobPos
									from.x, from.y, from.z = to.x, to.y, to.z
									newPosFound = 1
								end
							end
						end
					end -- if newPosFound

					if newPosFound == 0 then
						if angleIndex < followersInLine then
							angleIndex = angleIndex + 1
						else
							angleIndex = 1
							dist = dist + dd -- if more than followersInLine one more step behind and reset angle
							if boundSize_y > 64 then
								dist = dist + dd -- double for big mesh actors
							end
							---mwse.log("angleIndex = %d, dist = %d, dd = %s", angleIndex, dist, dd)
						end -- if angleIndex < 5
					end

				end -- if d > warpDist

			end -- if not mob:isAffectedByObject(burdenSpell)

		else -- not ok
			local mobSpeed = warpers[lcMobRefId]
			if mobSpeed then
				tes3.setStatistic({reference = mob, name = 'speed', current = mobSpeed})
				warpers[lcMobRefId] = nil
				doPackWarpers = true
			end
		end -- if ok
	end -- for mob

	if doPackWarpers then
		L.packWarpers()
	end

	local size = table.size(lastPlayerPositions)
	local i = size
	if size >= maxSavedPlayerPositions then
		if logLevel4 then
			mwse.log('%s: %s > maxSavedPlayerPositions (%s)', funcPrefix, i, maxSavedPlayerPositions)
		end
		i = 0
		for j = 2, size do
			local v = lastPlayerPositions[j]
			if v then
				if v.pos then
					i = i + 1
					if logLevel4 then
						if i == 1 then
							local v2 = lastPlayerPositions[i]
							mwse.log('%s: 1 lastPlayerPositions[%s] = {cellId = "%s", pos = %s} removed',
								funcPrefix, i, v2.cellId, v2.pos)
						end
						mwse.log('%s: 2 lastPlayerPositions[%s] = {cellId = "%s", pos = %s} added',
							funcPrefix, i, v.cellId, v.pos)
					end
					lastPlayerPositions[i] = v
				end
			end
		end
	end
	local good = false
	if i > 1 then
		local prevPP = lastPlayerPositions[i]
		if prevPP then
			local lastPos = prevPP.pos
			if lastPos then
				local d = playerPos:distance(lastPos)
				if (d >= stepDist)
				and (d <= warpDist) then
					good = true
					if logLevel3 then
						mwse.log('%s: good lastPos: %s, playerPos: %s, playerPos:distance(lastPos) = %s',
							funcPrefix, lastPos, playerPos, d)
					end
				end
			end
		end
	else
		good = true
	end
	if good then
		i = i + 1
		if logLevel4 then
			mwse.log('%s: 3 lastPlayerPositions[%s] = {cellId = "%s", pos = %s}',
				funcPrefix, i, pcCell.id, playerPos)
		end
		-- store good previous player position
		local cid = ''
		if pcCell.isInterior then
			cid = pcCell.id
		end
		-- important to use a :copy() here!!!
		lastPlayerPositions[i] = {cellId = cid, pos = playerPos:copy()}
	end
end


local travelStopping = false -- set in travelStop(), used in timedTravelProcess to skip

local moveTravellersRegistered = false
function L.setMoveTravellers(on)
	if moveTravellersRegistered
	or event.isRegistered('simulate', moveTravellers) then
		if on then
			return
		end
		moveTravellersRegistered = false
		event.unregister('simulate', moveTravellers)
		return
	end
	if on then
		moveTravellersRegistered = true
		event.register('simulate', moveTravellers)
	end
end

function L.startMoveTravellers()
	local tp = travelParams[travelType]
	followersInLine = math.max( math.min(numTravellers, tp.maxInLine), 1 )
	travelRadStep = math.rad(170 / followersInLine)
	if logLevel2 then
		mwse.log("%s: startMoveTravellers() numTravellers = %s, followersInLine = %s, tp.maxInLine = %s",
			modPrefix, numTravellers, followersInLine, tp.maxInLine)
	end
	movingTravellers = true
	L.setMoveTravellers(movingTravellers)
	timer.start({duration = 1.0, callback = function ()
		currMountRef = L.getCurrMountRef(travelType)
		if currMountRef then
			currMountHandle = tes3.makeSafeObjectHandle(currMountRef)
			lastMountFacing = currMountRef.facing
		end
	end})
end


function L.stopMoveTravellers()
	if logLevel2 then
		mwse.log("%s: stopMoveTravellers()", modPrefix)
	end
	followersInLine = 5
	movingTravellers = false
	L.setMoveTravellers(movingTravellers)
	currMountRef = nil
	currMountHandle = nil
end

local tes3_effect_invisibility = tes3.effect.invisibility

---@param handle mwseSafeObjectHandle
local function handleToRef(handle)
	if not handle then
		return
	end
	if not handle.valid then
		return
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end

---@param e mwseTimerCallbackData
local function getTimerRef(e)
	local ref
	local timer = e.timer
	local data = timer.data
	if data then
		local handle = data.handle
		ref = handleToRef(handle)
	end
	return ref
end

---@param e mwseTimerCallbackData
local function ab01smcompPT1(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	mob.invisibility = 0
	mob:updateOpacity()
end

---@param mob tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
function L.resetTransparency(mob)
	tes3.applyMagicSource({
	-- apply a short chameleon/invisibility to try and fix appearance sometimes buggy after travelling with setinvisible
		reference = mob,
		name = "Negate Invisibility",
		effects = {  {id = tes3_effect_invisibility, duration = 1}, {id = tes3.effect.chameleon, duration = 2, min = 100, max = 100}, },
		bypassResistances = true
	})
	timer.start({ duration = 2.75, callback = 'ab01smcompPT1',
		data = {handle = tes3.makeSafeObjectHandle(mob.reference)}
	})
end

local function ab01smcompPT2()
	if logLevel3 then
		mwse.log("%s: ab01smcompPT2()", modPrefix)
	end
	L.stopMoveTravellers()
	local ability
	if travelType > 0 then
		local tp = travelParams[travelType]
		ability = tp.spell
	end
	for lcMobRefId, t in pairs(travellers) do
		if t -- needed safety
		and t.inv then
			local mobRef = getActorRef(lcMobRefId)
			if mobRef then
				local mob = mobRef.mobile
				if mob then
					if ability then
						if logLevel2 then
							mwse.log("%s: tes3.removeSpell({reference = %s, spell = %s}), invisibility = %s, acrobatics = %s, nospread = %s",
								modPrefix, mobRef.id, ability, t.inv, t.acro, t.ns)
						end
						tes3.removeSpell({reference = mob, spell = ability}) -- remove travelling spell
						---mwscript.removeSpell({reference = mob, spell = ability}) -- remove travelling spell
					end
					L.resetTransparency(mob)
					mob.invisibility = t.inv -- reset invisibility
					mob.blind = 0 -- oh well I guess curing them from blindness anyway is not bad
					mob:updateOpacity()
					mob.acrobatics.current = t.acro -- reset acrobatics
					---mob.movementCollision = true
					if t.ns > 0 then
						local nospread = setRefVariable(mobRef, 'nospread', 0)
						if nospread
						and logLevel3 then
							mwse.log("%s: %s nospread reset to 0", modPrefix, mobRef.id)
						end
					else
						local script = mobRef.object.script
						if script then
							if logLevel5 then
								mwse.log('%s: "%s" mwse.clearScriptOverride("%s")', modPrefix, mobRef.id, script.id)
							end
							mwse.clearScriptOverride(script.id)
						end
					end
					tes3.setAIFollow({reference = mob, target = player, reset = true})
				end
			end
		end
	end
	L.resetTransparency(mobilePlayer)
	L.cleanTravellers()
	travelType = 0
	L.initScenicTravelAvailable()
	travelStopping = false
end

function L.travelStop()
	if logLevel2 then
		mwse.log("%s: travelStop()", modPrefix)
	end

	local ppos = player.position:copy()
	local pori = player.orientation
	local pcell = player.cell
	local cellId = pcell.id
	local doLog = logLevel >= 2
	for lcMobRefId, t in pairs(travellers) do
		if t -- needed safety
		and t.inv then
			local mobRef = getActorRef(lcMobRefId)
			if mobRef then
				if doLog then
					mwse.log("%s: tes3.positionCell({reference = %s, cell = %s})", modPrefix, mobRef.id, cellId)
				end
				tes3.positionCell({reference = mobRef, position = ppos, orientation = pori, cell = pcell}) -- ensure followers move to player cell
			end
		end
	end
	-- small delay before removing spells/resetting acrobatics so followers are still positioned behind player by travel script
	-- and they don't get damaged from falling
	travelStopping = true

	timer.start({duration = 1, callback = 'ab01smcompPT2'})
end


local improvedAnimationSupportId = tes3.codePatchFeature.improvedAnimationSupport

-- set in modCongigReady()
local improvedAnimationSupport

---local tes3_compilerSource_console = tes3.compilerSource.console
local function playGroupIdle(mobRef)
-- As a special case, tes3.playAnimation{reference = ..., group = 0}
-- returns control to the AI, as the AI knows that is the actor's neutral idle state.
	tes3.playAnimation({reference = mobRef, group = 0})
	---tes3.runLegacyScript({reference = mobRef,
		---command = 'PlayGroup idle',
		---source = tes3_compilerSource_console})
end

local function aiWander0(mobRef)
	-- nope too many dancing companions
	--- tes3.setAIWander({reference = mobRef, duration = 0, idles = {40, 30, 20, 10, 0, 0, 0, 0}, reset = false})
	tes3.setAIWander({reference = mobRef, duration = 0, idles = {40, 0, 0, 0, 0, 0, 0, 0}, reset = true})
	---tes3.setAIWander({reference = mobRef, duration = 0, idles = {0, 0, 0, 0, 0, 0, 0, 0}, reset = true})
end

--[[
local function aiWander512(mobRef)
	tes3.setAIWander({reference = mobRef, duration = 1, range = 512, idles = {60, 40, 30, 0, 0, 0, 0, 0}, reset = true})
end
]]

local function wanderInPlace(mobRef)
	-- nope too many dancing companions around
	--- tes3.setAIWander({reference = mobRef, duration = 1, idles = {40, 30, 20, 10, 0, 0, 0, 0}, reset = true})
	tes3.setAIWander({reference = mobRef, duration = 1, idles = {40, 0, 0, 0, 0, 0, 0, 0}, reset = true})
end

-- reset in loaded()

local function nop()
end

function L.timedTravelProcess()
	if travelStopping then
		return
	end
	local boDest = 0
	if ab01boDestGlob then
		boDest = round(ab01boDestGlob.value)
	end
	local ssDest = 0
	if ab01ssDestGlob then
		ssDest = round(ab01ssDestGlob.value)
	end
	local goDest = 0
	if ab01goDestGlob then
		goDest = round(ab01goDestGlob.value)
	end

	local compMount = 0
	if ab01compMountedGlob then
		if currMountRef then
			local localVar = getRefVariable(currMountRef, 'ab01compMount')
			if localVar then
				compMount = localVar
			end
		end
	end

	local stop = false
	if travelType == 1 then -- boat
		if (boDest <= 0)
		and ab01boDest
		and (ab01boDest > 0) then
			stop = true
		end
	elseif travelType == 2 then -- strider
		if (ssDest <= 0)
		and ab01ssDest
		and (ab01ssDest > 0) then
			stop = true
		end
	elseif travelType == 3 then -- gondola
		if (goDest <= 0)
		and ab01goDest
		and (ab01goDest > 0) then
			stop = true
		end
	elseif travelType == 4 then -- guar
		if (compMount < 3)
		and ab01compMount
		and (ab01compMount == 3) then
			stop = true
		end
	end

	if stop then
		L.travelStop()
		return
	end

	if (travelType == 0)
	and ab01boDest
	and (not (boDest == ab01boDest)) then
		ab01boDest = boDest
		travelType = 1 -- boat
	end
	if (travelType == 0)
	and ab01ssDest
	and (not (ssDest == ab01ssDest)) then
		ab01ssDest = ssDest
		travelType = 2 -- strider
	end
	if (travelType == 0)
	and ab01goDest
	and (not (goDest == ab01goDest)) then
		ab01goDest = goDest
		travelType = 3 -- gondola
		ab01goAngleGlob.value = 10000 -- reset it
	end

	if (travelType == 0)
	and ab01compMount
	and (not (compMount == ab01compMount)) then
		ab01compMount = compMount
		travelType = 4 -- guar
	end

	if travelType == 0 then
		-- invalid
		return
	end

	local function getSpreads(mob) -- out spread, nospread
		local spread = nil
		local nospread = nil
		if not mob.canMove then
	-- dead, knocked down, knocked out, hit stunned, or paralyzed
			return spread, nospread
		end
		local mobRef = mob.reference
		if mobRef.disabled
		or mobRef.deleted
		or isDead(mob) then
			return spread, nospread
		end
		local script = mobRef.object.script
		if not script then
			return spread, nospread
		end
		local context = script['context']
		if context then
			spread = context['spread']
			nospread = context['nospread']
			if logLevel3 then
				mwse.log("%s: %s, spread = %s, nospread = %s", modPrefix, mobRef.id, spread, nospread)
			end
		end
		return spread, nospread
	end

	-- dummy function to override travellers script
	-- so they hopefully stop warping elsewhere if alone travelling

	local maxDist = 8192 ---34756
	local playerPos = player.position
	numTravellers = 0
	local friendlyActors = mobilePlayer.friendlyActors
	for i = 1, #friendlyActors do
		local mob = friendlyActors[i]
		if (mob.actorType == tes3_actorType_npc)
		and isValidScenicFollower(mob) then
			local mobRef = mob.reference
			local spread, nospread = getSpreads(mob)
			local tns = 0
			if spread -- companion script already providing scenic travelling
			and nospread then
				tns = 1
				-- set nospread to 1 in the local companion script so vanilla travelling code is skipped
				--- nope mobRef.object.script['context'].nospread = 1
				mobRef.context.nospread = 1
			end
			local dist = mobRef.position:distance(playerPos)
			if dist <= maxDist then
				local lcMobRefId = string.lower(mobRef.id)
				local traveller = travellers[lcMobRefId]
				local addIt = false
				if traveller then
					if traveller.inv then
						numTravellers = numTravellers + 1
						if travelType == 4 then
							break -- max one guar passenger
						end
					else
						addIt = true
					end
				else
					addIt = true
				end
				if addIt then
					-- hopefully local NPC script will stop warping in wander mode
					-- no more needed, I override the script
					---aiWander0(mobRef)
					wanderInPlace(mobRef)
					if tns == 0 then
						local script = mobRef.object.script
						if script then
							if logLevel5 then
								mwse.log('%s: "%s" mwse.overrideScript("%s", nop)', modPrefix, mobRef.id, script.id)
							end
							mwse.overrideScript(script.id, nop)
						end
					end
					if logLevel2 then
						mwse.log("%s: %s, dist = %s added to travellers", modPrefix, mobRef.id, dist)
					end
					playGroupIdle(mobRef)
					-- store invisibility, acrobatics, nospread of follower
					travellers[lcMobRefId] = {inv = mob.invisibility, acro = mob.acrobatics.current, ns = tns}
					numTravellers = numTravellers + 1
					if travelType == 4 then
						break -- max one guar passenger
					end
				end
			end
		end
	end
	if numTravellers > 0 then
		local ability = travelParams[travelType].spell
		local facing
		for lcMobRefId, t in pairs(travellers) do
			if t -- needed safety
			and t.inv then
				local mobRef = getActorRef(lcMobRefId)
				if mobRef then
					local mob = mobRef.mobile
					if mob then
						if logLevel2 then
							mwse.log("%s: tes3.addSpell({reference = %s, spell = %s}), invisibility = 1, acrobatics = 200, blind = 100", modPrefix, mobRef.id, ability)
						end
						---mwscript.addSpell({reference = mob, spell = ability})
						tes3.addSpell({reference = mobRef, spell = ability})
						mob.invisibility = 1 -- setInvisible to avoid aggro cliffracers
						mob.blind = 100 -- blind to avoid aggro
						mob.acrobatics.current = 200 -- high acrobatics to avoid damage if cell changed
						---mob1.movementCollision = false -- this works better especially with multiple guards but not while levitating
						-- note: the f* mobile.facing is read only!!!
						facing = player.facing
						if (travelType == 4)
						and currMountRef
						and lastMountFacing then
							facing = lastMountFacing
						end
						mobRef.facing = facing
						mobRef.position.z = player.position.z
						---wanderInPlace(mobRef)
					end -- if mob1
				end -- if mobRef1
			end -- if t
		end
		L.startMoveTravellers()
	end
end

local function fixWeight(w)
	if w then
		if w < 0 then
 -- try to avoid negative weights, could be fake items
 -- from mods trying to fix player negative encumbrance
			w = 10000000
		else
			if w < 0.0001 then
				w = 0.0001
			else
				w = math.round(w, 4)
			end
		end
	else
		w = 0.0001
	end
	return w
end

local function getRefWeight(stackRef)
	local weight = stackRef.baseObject.weight
	weight = fixWeight(weight)
	local count = stackRef.stackSize
	if not count then
		count = 1
	end
	weight = weight * count
	return weight
end

local function isLootable(obj, script)
	local skip = false
	local objType = obj.objectType
	--[[
	-- not sure how to use testActionFlag without a proper reference
	if not mobRef:testActionFlag(tes3_actionFlag_useEnabled) then
		return -- onactivate block present, skip disabling event on scripted activate
	end
	]]
	if not script then
		if type(obj) == 'table' then
-- hopefully this will avoid those pesky WARNING: An unknown object type was identified with a virtual table address of
			if logLevel3 then
				mwse.log('%s: isLootable("%s") type(obj) == "table", obj.script = "%s"', obj.id, obj.script)
			end
			script = obj.script
		end
	end
	if script then
		local context = script.context
		if context then
			local s = tostring(context) -- convert from script opcodes?
			if s
			and string.find(string.lower(s), 'onactivate', 1, true) then
				skip = true
				if (objType == CONT_T)
				and obj.organic then
					skip = false
				end
			end
		end
	end
	if skip then
		if logLevel3 then
			mwse.log("%s: isLootable('%s') false, scripted with OnActivate", modPrefix, obj.id)
		end
		return false -- scripted with OnActivate, not lootable
	end
	if (objType == LIGH_T) -- not scripted but...
	and obj.canCarry
	and obj.isOffByDefault
	and (obj.radius < 17) then
		return false -- light may be used as icon
	end
	return true
end

local function checkCrime(activatorRef, targetRef, targetValue)
	if tes3.hasOwnershipAccess({target = targetRef}) then
		return -- skip if player has ownership
	end
	if tes3.hasOwnershipAccess({reference = activatorRef, target = targetRef}) then
		return -- skip if actor has ownership
	end
	local mob = activatorRef.mobile
	---assert(mob)
	local hidden = mob.chameleon
	if mob.actorType >= tes3_actorType_npc then -- 0 = creature, 1 = NPC, 2 = player
		hidden = hidden + mob.sneak.current
	end
	local roll = math.random(1, 100)
	if hidden >= roll then
		return -- skip if not detected
	end

	local totalValue
	if targetValue then
		totalValue = targetValue
	else
		local obj = targetRef.baseObject
		local value = obj.value
		if not value then
			value = 1
		end
		local count = targetRef.stackSize
		if not count then
			count = 1
		end
		totalValue = value * count
	end
	local owner = tes3.getOwner({reference = targetRef})
	timer.frame.delayOneFrame(
		function()
			tes3.triggerCrime({type = tes3.crimeType.theft, victim = owner, value = totalValue})
		end
	)
end

local MWCAloaded = tes3.getFileExists("MWSE\\mods\\MWCA\\main.lua")
local GHerbLoaded = tes3.getFileExists("MWSE\\mods\\graphicHerbalism\\main.lua")

-- borrowed from Graphic Herbalism
-- Update and serialize the reference's HerbalismSwitch.
-- valid indexes are: 0 = default, 1 = picked, 2 = spoiled
local function updateHerbalismSwitch(contRef, index)
	if logLevel3 then
		mwse.log('%s: updateHerbalismSwitch(contRef = "%s", index = %s)', modPrefix, contRef.id, index)
	end
	-- valid indices are: 0=default, 1=picked, 2=spoiled
	local sceneNode = contRef.sceneNode
	if not sceneNode then
		return false
	end
	local switchNode = sceneNode:getObjectByName("HerbalismSwitch")
	if not switchNode then
		return false
	end
	-- bounds check in case mesh does not implement a spoiled state
	index = math.min(index, #switchNode.children - 1)
	switchNode.switchIndex = index
	-- only serialize if non-zero state (e.g. if picked or spoiled)

	---contRef.data.GH = (index > 0) and index or nil
	-- now I will rewrite this in a clear way without and/or shortcuts. /abot
	if index then
		if index <= 0 then
			index = nil
		end
	end
	if logLevel3 then
		mwse.log("%s: updateHerbalismSwitch() contRef.data.GH = %s)", modPrefix, index)
	end
	contRef.data.GH = index
	return true
end

local skipPlayerAltActivate = false -- set/reset to make player unable to Alt+activate for a short time

local function ab01smcompPT4()
	skipPlayerAltActivate = false
end

local function setSkipPlayerAltActivate()
	if skipPlayerAltActivate then
		return
	end
	skipPlayerAltActivate = true
	timer.start({ duration = 2.5, -- important to give enough duration else it may crash
		type = timer.real, callback = 'ab01smcompPT4'})
end

local function doActivate(activatorRef, targetRef)
	if logLevel3 then
		mwse.log('%s: doActivate(activatorRef = "%s", targetRef = "%s")', modPrefix, activatorRef.id, targetRef.id)
	end
	if targetRef then
		activatorRef:activate(targetRef)
	end
end

--[[
local function reevaluateEquipment(mob)
	if not mob then
		return
	end
	if tes3.mobilePlayer == mob then
		return
	end
	local actorType = mob.actorType -- 0 = creature, 1 = NPC, 2 = player
	local ob = mob.reference.baseObject
	if (actorType == tes3_actorType_npc)
	or (
		(actorType == tes3_actorType_creature) -- creature
		and ob.usesEquipment -- biped
	) then
		timer.delayOneFrame(
			function ()
				if ob then
					---if logLevel3 then
						---mwse.log("%s: before %s:reevaluateEquipment()", modPrefix, ob.id)
					---end
					ob:reevaluateEquipment() -- is this thing crashing? nope somewhere else
					---if logLevel3 then
						---mwse.log("%s: after %s:reevaluateEquipment()", modPrefix, ob.id)
					---end
				end
			end
		)
	end
end
]]

local niceLootMsg = {
[["Hey, some %s!"]],
[["I found some %s there!"]],
[["Let's see... great, some %s."]],
[["Wow, I found some %s."]],
[["Hmm... more %s."]],
[["There! some %s."]],
[["Some %s. How typical."]],
[["Some %s. How quaint."]],
[["Oh, joy. Some more %s."]],
[["Great, some %s!"]],
[["Right, I was just looking for some %s."]],
[["Hey, look what I've found, some %s!"]],
[["%s. I think we could sell some!"]],
[["Some %s. Could I keep this for myself?"]],
[["%s. I like this!"]],
[["Some %s. The more, the better."]],
[["Do you like some %s?"]],
[["And what do we have here? Some %s!"]],
[["Oh. It's been a long time since I've seen any %s."]],
[["%s. I want more!"]],
}

local function strip(s)
	return string.gsub(s, '!$', '')
end

local function triggerActivate(activatorRef, targetRef)
	if logLevel3 then
		mwse.log('%s: triggerActivate(activatorRef = "%s", targetRef = "%s")', modPrefix, activatorRef.id, targetRef.id)
	end
	event.trigger('activate', {activator = activatorRef, target = targetRef}, {filter = targetRef})
end

local function arrayChoice(a)
	return a[math.random(#a)]
end

local function companionLootContainer(companionRef, targetRef)
	if logLevel3 then
		mwse.log('%s: companionLootContainer(companionRef = "%s", targetRef = "%s")', modPrefix, companionRef.id, targetRef.id)
	end
	local companionMob = companionRef.mobile
	---assert(companionMob)
	local targetObj = targetRef.object
	local targetName = targetObj.name
	local inventory = targetObj.inventory

	if targetObj.organic
	or (not targetObj.isInstance) then
		local cloned = targetRef:clone() -- returns a boolean, autoupdates the reference
		if cloned then -- resolve container contents
			targetObj = targetRef.object --- important again to refresh it!!!
			targetName = targetObj.name
			inventory = targetObj.inventory
		else
			if logLevel > 0 then
				mwse.log("%s: companionLootContainer(companionRef = %s, targetRef = %s) targetRef:clone() failed", modPrefix, companionRef.id, targetRef.id)
			end
		end
	end
	if inventory then
		inventory:resolveLeveledItems()
	end

	local activatorName = companionRef.object.name
	if tes3.getLocked({reference = targetRef}) then
		tes3.playSound({sound = 'LockedChest', reference = targetRef})
		tes3ui.showNotifyMenu("%s: \"This %s is locked.\"", activatorName, targetName)
		return
	end

	if not inventory then
		return
	end

	-- transfer inventory to companion
	local vwMax = 0
	local niceLoot
	local items2transfer = {}
	local lootedCount = 0
	local inventoryCount = 0
	local encumb = companionMob.encumbrance
	local capacity = encumb.base - encumb.current
	local count, newCapacity, stackObj, value, weight, vw
	---local ab01goldWeight = tes3.getGlobal('ab01goldWeight')
	local variables, script

	local items = inventory.items
	local stack

	local function processStack(i)
		stack = items[i]
		if not stack then
			return
		end
		stackObj = stack.object
		if logLevel2 then
			mwse.log("%s: companionLootContainer item = %s", modPrefix, stackObj.id)
		end
		inventoryCount = inventoryCount + 1
		script = nil
		variables = stack.variables
		if variables then
			script = variables.script
		end
		if not isLootable(stackObj, script) then
			return
		end
		if logLevel3 then
			mwse.log("%s: companionLootContainer item = %s lootable", modPrefix, stackObj.id)
		end
		value = stackObj.value
		if not value then -- no value happens /abot
			return
		end
		weight = stackObj.weight
		--[[
		if string.lower(stackObj.id) == 'gold_001' then
			weight = 0.0001
			if ab01goldWeight then
				if ab01goldWeight > 0 then
					weight = ab01goldWeight
				end
			end
		end
		]]
		count = stack.count
		if not count then
			return
		end
		weight = fixWeight(weight)
		if logLevel2 then
			mwse.log("%s: companionLootContainer item = %s, value = %s, weight = %s, count = %s", modPrefix, stackObj.id, value, weight, count)
		end
		vw = value/weight
		if (vw >= config.minValueWeightRatio)
		or (
			targetObj.organic
			and config.alwaysLootOrganic
		) then
			count = math.abs(count)
			weight = weight * count
			newCapacity = capacity - weight
			if (newCapacity >= 1 )
			or (config.allowLooting > 1) then
				if vw > vwMax then
					vwMax = vw
					niceLoot = stackObj.name
				end
				table.insert(items2transfer, stack)
				lootedCount = lootedCount + 1
				capacity = newCapacity
			end
		end
	end

	--- for _, stack in pairs(inventory) do -- needs pairs!
	for i = 1, #items do
		processStack(i)
	end

	local companionActorType = companionMob.actorType
	local totalValue = 0

	local function skipActivateWhileTransfering()
		return false
	end

	if lootedCount > 0 then
		local settings = {priority = 100002}
		event.register('activate', skipActivateWhileTransfering, settings)
		for i = 1, #items2transfer do
			stack = items2transfer[i]
			stackObj = stack.object
			local num = math.abs(stack.count)
			totalValue = (stackObj.value * num) + totalValue
			if logLevel2 then
				mwse.log('%s: companionLootContainer tes3.transferItem({from = "%s", to = "%s", item = "%s", count = %s)',
					modPrefix, targetRef.id, companionRef.id, stackObj.id, num)
			end
			tes3.transferItem({from = targetRef, to = companionRef, item = stackObj, count = num,
				playSound = false, updateGUI = false, reevaluateEquipment = false})
		end

		if companionActorType == tes3_actorType_npc then -- NPC
			if niceLoot then
				tes3ui.showNotifyMenu( arrayChoice(niceLootMsg), strip(niceLoot) )
			end
			local i = math.random(100)
			local tnam = strip(targetName)
			if i > 75 then
				tes3ui.showNotifyMenu("%s:\n\"Let's see if we can find some decent loot with that %s.\"", activatorName, tnam)
			elseif i > 50 then
				tes3ui.showNotifyMenu("%s:\n\"%s, let's see what can be found with that %s.\"", activatorName, player.object.name, tnam)
			elseif i > 25 then
				tes3ui.showNotifyMenu("%s:\n\"All right, I'll check that %s.\"", activatorName, tnam)
			else
				tes3ui.showNotifyMenu("%s:\n\"I'll take care of this %s.\"", activatorName, tnam)
			end
		end

		tes3.updateInventoryGUI({reference = targetRef})
		tes3.updateMagicGUI({reference = targetRef})
		tes3.updateInventoryGUI({reference = companionRef})
		tes3.updateMagicGUI({reference = companionRef})

		tes3.playSound({sound = 'Item Misc Up', reference = companionRef})
		---reevaluateEquipment(companionMob)
		event.unregister('activate', skipActivateWhileTransfering, settings)

	elseif companionActorType == tes3_actorType_npc then
		local i = math.random(100)
		local playerName = player.object.name
		if capacity >= 1 then
			local tnam = strip(targetName)
			if i > 75 then
				tes3ui.showNotifyMenu("%s:\n\"Hmmm... nothing good with that %s.\"", activatorName, tnam)
			elseif i > 50 then
				tes3ui.showNotifyMenu("%s:\n\"%s, I think there is nothing more worth taking from that %s.\"", activatorName, playerName, tnam)
			elseif i > 25 then
				tes3ui.showNotifyMenu("%s:\n\"No good loot in the %s.\"", activatorName, tnam)
			else
				tes3ui.showNotifyMenu("%s:\n\"Hmmm... no luck this time.\"", activatorName)
			end
		else
			if i > 75 then
				tes3ui.showNotifyMenu("%s:\n\"I can't carry more than this!\"", activatorName)
			elseif i > 50 then
				tes3ui.showNotifyMenu("%s:\n\"%s, I am not your beast of burden!\"", activatorName, playerName)
			elseif i > 25 then
				tes3ui.showNotifyMenu("%s:\n\"Sorry %s but... no, I am already carrying a lot of things.\"", activatorName, playerName)
			else
				tes3ui.showNotifyMenu("%s:\n\"No, that's too heavy for me.\"", activatorName)
			end
		end
	end

	if targetObj.objectType == CONT_T then
		local lcId = string.lower(targetObj.id)
		if targetObj.organic
		and (not targetObj.script)
		and (not string.find(lcId, 'chest', 1, true)) then -- skip guild chests
			local gHerb = false
			local empty = (lootedCount >= inventoryCount)
			if GHerbLoaded then -- Graphic Herbalism loaded
				-- valid indexes are: 0 = default, 1 = picked, 2 = spoiled
				if empty then
					gHerb = updateHerbalismSwitch(targetRef, 2) -- spoiled
				elseif lootedCount > 0 then
					gHerb = updateHerbalismSwitch(targetRef, 1) -- picked
				end
			end
			if empty then
				if gHerb then
					targetRef.isEmpty = true
					targetObj.modified = false
				else
					local mesh = targetObj.mesh
					if mesh
					and string.find(mesh:lower(), 'flora', 1, true) then
						targetRef:disable()
					end
				end
			end

		elseif MWCAloaded then -- Morrowind Containers Animated loaded
			---mwse.log(">MWCAloaded")
			-- try and trigger animated container opening
			---triggerActivate(companionRef, targetRef)
			if logLevel3 then
				mwse.log('%s: companionLootContainer() MWCAloaded triggerActivate(%s, %s)', modPrefix, player, targetRef)
			end
			setSkipPlayerAltActivate()
			triggerActivate(player, targetRef)
			--- doActivate(player, targetRef) -- nope crashing
		end
	end -- if targetObj.objectType == CONT_T

	---targetObj:onInventoryClose(targetRef)
	targetRef:onCloseInventory()
	checkCrime(companionRef, targetRef, totalValue)

	if logLevel3 then
		mwse.log('%s: companionLootContainer() after checkCrime(companionRef = %s, targetRef = %s, totalValue = %s)', modPrefix, companionRef.id, targetRef.id, totalValue)
	end

end


local function getThiefTool(actorRef, objectType)
	local inventory = actorRef.object.inventory
	---assert(inventory)
	if inventory then
		---for _, stack in pairs(inventory) do
		local items = inventory.items
		for i = 1, #items do
			local stack = items[i]
			---assert(stack)
			local obj = stack.object
			---assert(obj)
			---if obj then
			if obj.objectType == objectType then
				if obj.name then
					if not string.multifind(string.lower(obj.name), {'compass','sextant'}, 1, true) then
						local iData = stack.itemData
						if iData then
							local condition = iData.condition
							if condition then
								if condition > 0 then
									condition = condition - 1
									stack.itemData.condition = condition -- decrease item condition as it would be be used
									return stack
								else
									---mwscript.removeItem({reference = actorRef, item = obj, count = 1}) -- removes item with 0 uses left
									tes3.removeItem({reference = actorRef, item = obj, count = 1}) -- removes item with 0 uses left
									return getThiefTool(actorRef, objectType) -- look for another one
								end
							end
						else -- it is an unused one
							return stack
						end
					end
				end
			end
			---end
		end
	end
	local s
	if objectType == LKPK_T then
		s = 'lockpick'
	else
		s = 'probe'
	end
	tes3ui.showNotifyMenu("%s:\n\"I don't have a %s.\"", actorRef.object.name, s)
	return nil
end

local function getLockpick(actorRef)
	return getThiefTool(actorRef, LKPK_T)
end

local function getProbe(actorRef)
	return getThiefTool(actorRef, PROB_T)
end

local function sneakForSec(mob, seconds)
	if not (mob.actorType == tes3_actorType_npc) then
		return
	end
	if not mob.isSneaking then
		mob.forceSneak = true
		timer.start({duration = seconds, callback = function ()
			if mob then
				mob.forceSneak = false
			end
		end})
	end
end

local tes3_effect_open = tes3.effect.open

local function getOpenSpell(actorRef)
	local spells = actorRef.object.spells
	if not spells then
		return nil, nil
	end
	local t = {}
	local found = false

	local funcPrefix = modPrefix .. ' getOpenSpell()'

	for _, spl in pairs(spells) do
		if spl then
			---mwse.log("spl = %s", spl.id)
			if spl.isActiveCast or spl.alwaysSucceeds then
				local effectIndex = spl:getFirstIndexOfEffect(tes3_effect_open)
				if effectIndex then
					if effectIndex >= 0 then -- returns -1 if not found
						---mwse.log("effectIndex = %s", effectIndex)
						effectIndex = effectIndex + 1
						local effect = spl.effects[effectIndex]
						local magnitude = math.floor( (effect.min + effect.max) * 0.5 )
						local chance
						if spl.alwaysSucceeds then
							chance = 100
						elseif effect.cost > 0 then
							chance = spl:calculateCastChance({checkMagicka = config.checkMagicka, caster = actorRef})
						else
							chance = 100
						end
						local mXc = magnitude * chance
						if logLevel3 then
							mwse.log("%s: magnitude = %s, chance = %s, magnitude * chance = %s", funcPrefix, magnitude, chance, mXc)
						end
						if mXc >= 60 then
							table.insert(t, {spell = spl, magnitudeXchance = mXc})
							found = true
						end
					end
				end
			end
		end
	end
	if found then
		 -- sort by descending cost * chance
		table.sort(t, function(a,b) return a.magnitudeXchance > b.magnitudeXchance end)
		local t1 = t[1]
		local spell = t1.spell
		if logLevel2 then
			mwse.log('%s: "%s" using spell "%s" ("%s")', funcPrefix, actorRef.id, spell.id, spell.name)
		end
		return t1.spell, t1.magnitudeXchance
	end
	return nil, nil
end

local function tryUnlock(npcRef, targetRef)
	local funcPrefix = modPrefix .. ' tryUnlock()'
	if logLevel2 then
		mwse.log('%s: npcRef = "%s", targetRef = "%s")', funcPrefix, npcRef.id, targetRef.id)
	end
	local lockNode = targetRef.lockNode
	if not lockNode then
		return true
	end
	local npcMob = npcRef.mobile
	if not npcMob then
		return false
	end
	if not (npcMob.actorType == tes3_actorType_npc) then
		return false
	end
	sneakForSec(npcMob, 3)
	local npcName = npcRef.object.name
	local targetName = targetRef.object.name
	local tnam = strip(targetName)
	local key = lockNode.key
	if key then
		---if mwscript.getItemCount({reference = npcRef, item = key}) > 0 then
		if npcRef.object.inventory:contains(key.id) then
			if lockNode.trap then
				lockNode.trap = nil
			end
			if lockNode.locked then
				tes3.unlock({reference = targetRef})
				tes3.playSound({sound = 'chest open', reference = targetRef})
				tes3ui.showNotifyMenu("%s:\n\"I opened the %s with the %s.\"", npcName, tnam, strip(key.name))
			end
			return true
		end
	end

	local agility = npcMob.agility.current
	local luck = npcMob.luck.current
	local security = npcMob.security.current

	if config.allowProbes then
		if lockNode.trap then
			local stack = getProbe(npcRef)
			if stack then
				local quality = stack.object.quality
				if not quality then
					quality = 0.25
				end
				local fTrapCostMult = tes3gmst_fTrapCostMult.value
				if not fTrapCostMult then
					fTrapCostMult = 0
				end
				local trapSpellPoints = lockNode.trap.magickaCost
				if not trapSpellPoints then
					trapSpellPoints = 0
				end
				local x = (0.2 * agility) + (0.1 * luck) + security
				x = x * quality
				x = x + (fTrapCostMult * trapSpellPoints) -- note that if not 0, fTrapCostMult should be negative (usually -1)
				if x > 0 then
					local roll = math.random(1, 100)
					if roll <= x then
						lockNode.trap = nil
						targetRef.modified = true
						tes3.playSound({sound = 'Disarm Trap', reference = targetRef})
						tes3ui.showNotifyMenu("%s:\n\"I managed to disarm the trapped %s with a probe!\"", npcName, tnam)
					else
						tes3.playSound({sound = 'Disarm Trap Fail', reference = targetRef})
						tes3ui.showNotifyMenu("%s:\n\"I failed to disarm the trapped %s.\"", npcName, tnam)
						if not lockNode.locked then
							if not targetRef.data then
								targetRef.data = {}
							end
							targetRef.data.ab01mt = 1 -- mark it as already processed for More Traps mod
							npcRef:activate(targetRef) -- trigger the trap!?
						end
					end
				else
					tes3ui.showNotifyMenu("%s:\n\"I can't disarm the trapped %s.\"", npcName, tnam)
				end
			end
		end
	end

	if config.allowLockpicks then
		if lockNode.locked then
		-- lockNode.level (number) The level of the lock.
			local stack = getLockpick(npcRef)
			if stack then
				local quality = stack.object.quality
				if not quality then
					quality = 0.25
				end
				local fPickLockMult = tes3gmst_fPickLockMult.value
				if not fPickLockMult then
					---assert(fPickLockMult)
					fPickLockMult = -1
				end
				local lockStrength = lockNode.level
				---assert(lockStrength)
				if lockStrength == 0 then
					lockStrength = 1000000 --  locked 0 things should be impossible to unlock
				end
				local x = (0.2 * agility) + (0.1 * luck) + security
				x = x * quality
				x = x + (fPickLockMult * lockStrength)
				if x > 0 then
					local roll = math.random(1, 100)
					if roll <= x then
						tes3.unlock({reference = targetRef})
						tes3.playSound({sound = 'Open Lock', reference = targetRef})
						tes3ui.showNotifyMenu("%s:\n\"I managed to unlock that %s.\"", npcName, targetName)
					else
						tes3.playSound({sound = 'LockedChest', reference = targetRef})
						tes3ui.showNotifyMenu("%s:\n\"I failed to unlock that %s.\"", npcName, targetName)
					end
				else
					tes3ui.showNotifyMenu("%s:\n\"I can't unlock that %s.\"", npcName, targetName)
				end
			end
		end
	end

	if config.allowMagic then
		if lockNode.locked then
			local spl, magnitudeXchance = getOpenSpell(npcRef)
			if spl and magnitudeXchance then
				tes3.cast({reference = npcRef, target = targetRef, spell = spl, instant = false, alwaysSucceeds = false})
			end
		end-- if lockNode.locked
	end -- if config.allowMagic

	if lockNode.locked
	or lockNode.trap then
		return false
	end
	return true
end


local function tryCompanionThievery(companionRef, targetRef)
	if logLevel2 then
		mwse.log('%s: tryCompanionThievery(companionRef = "%s", targetRef = "%s")', modPrefix, companionRef.id, targetRef.id)
	end
	local unlocked = tryUnlock(companionRef, targetRef)
	if unlocked then
		local obj = targetRef.baseObject
		local objType = obj.objectType
		if objType == CONT_T then
			if config.allowLooting > 0 then
				setSkipPlayerAltActivate()
				companionLootContainer(companionRef, targetRef)
			end
		elseif objType == DOOR_T then
			if not targetRef.destination then
				doActivate(lastCompanionRef, targetRef)
			end
		end
	end
end

local function canWalkTo(actorRef, targetRef)

	if not tes3.testLineOfSight({ reference1 = actorRef, reference2 = targetRef}) then
		return false
	end

	local rayStartPos = actorRef.position:copy()
	rayStartPos.z = rayStartPos.z + 32
	local targetPos = targetRef.position:copy()
	local bounds = targetRef.object.boundingBox
	if bounds then
		targetPos.z = (targetRef.scale * (bounds.max.z - bounds.min.z) * 0.5) + targetPos.z
	end
	local rayDir = targetPos - rayStartPos
	local rayHit = tes3.rayTest{ position = rayStartPos, direction = rayDir:normalized(),
		maxDistance = config.maxDistance, ignore = {actorRef, player} }
	if rayHit then
		if targetRef == rayHit.reference then
			return true -- actorRef should be able to walk to targetRef
		end
	end
	return false
end

local function takeMessageBox(activatorRef, targetRef)
	local targetName = targetRef.object.name
	---assert(targetName)
	if targetName == '' then
		return
	end
	local activatorName = activatorRef.object.name
	local activatorMob = activatorRef.mobile
	local activatorActorType = activatorMob.actorType
	local obj = targetRef.baseObject
	local targetType = obj.objectType
	local s1 = ''
	if targetType == CONT_T then
		s1 = 'care of '
	end
	local s2
	if activatorActorType == tes3_actorType_npc then
		s1 = 'care of '
		s2 = "%s:\n\"I'll take %sthe %s.\""
	elseif activatorActorType == tes3_actorType_creature then
		s1 = 'care of '
		s2 = "%s\ntakes %sthe %s."
	end
	if s2 then
		local s3 = strip(targetName)
		if logLevel2 then
			mwse.log(s2, activatorName, s1, s3)
		end
		tes3ui.showNotifyMenu(s2, activatorName, s1, s3)
	end
end


local function ab01smcompPT3(e)
	local ref = getTimerRef(e)
	if not ref then
		---assert(ref)
		return
	end
	if ref.disabled then
		---mwscript.setDelete({reference = ref, delete = true})
		ref:delete()
	end
end

local function deleteReference(ref)
	if ref.itemData then
		ref.itemData = nil
	end
	---mwscript.disable({reference = mobRef, modify = true})
	ref:disable()
	ref.position.z = ref.position.z + 16384 -- move after disable to try and update lights (and maybe get less problems with collisions when deleting?)
	---mwscript.enable({reference = mobRef, modify = true}) -- enable it after moving to hopefully refresh collision
	ref:enable()
	---mwscript.disable({reference = mobRef, modify = true}) -- finally disable
	ref:disable()
	local delaySec
	if ref.object.sourceMod then
		delaySec = 0.5 -- not a spawned thing, safe to setdelete immediately after movement
	else
		delaySec = 7.5 -- big delay, should be safe even for animated/playing sound spawned items
	end
	timer.start({ duration = delaySec, callback = 'ab01smcompPT3',
		data = {handle = tes3.makeSafeObjectHandle(ref)} })

end

local function takeItem(destActorRef, targetRef)
	local obj = targetRef.baseObject
	local data = targetRef.itemData
	local num = 1
	if data
	and data.count then
		num = math.abs(data.count)
	end
	takeMessageBox(destActorRef, targetRef)

	checkCrime(destActorRef, targetRef)
	tes3.playSound({reference = destActorRef, sound = 'Item Book Up'})

	---mwscript.addItem({reference = destActorRef, item = obj.id, count = num})
	tes3.addItem({reference = destActorRef, item = obj.id, count = num})
	deleteReference(targetRef)
end

local function multifind2(s1, s2, pattern)
	return string.multifind(s1, pattern, 1, true)
	or string.multifind(s2, pattern, 1, true)
end

function L.companionActivate(targetRef)
	local obj = targetRef.baseObject
	local lootType = obj.objectType
	if logLevel2 then
		mwse.log("%s: companionActivate(targetRef = %s, lootType = %s)",
			modPrefix, targetRef.id, mwse.longToString(lootType))
	end

	local function mayBeRevolvingDoor(doorRef, doorObj)
		local doorDest = doorRef.destination
		if doorDest then
			return false
		end
		if doorObj.script then
			return false
		end
		if tes3.getLocked({reference = doorRef}) then
			return false
		end
		if doorObj.persistent then
			return false
		end
		local doorCell = doorRef.cell
		if not doorCell then
			return false
		end
		if doorCell.isInterior then
			return false
		end
		local lockNode = doorRef.lockNode
		if lockNode
		and lockNode.level
		and (lockNode.level == 1) then -- door marked as openable
			return false
		end
		local doorId = string.lower(doorObj.id)
		local name = doorObj.name
		if multifind2(doorId, name, {'gate','slave','star'}) then
			return false -- special door
		end
		return true -- may be a revolving door
	end

	if lootType == DOOR_T then
		if mayBeRevolvingDoor(targetRef, obj) then
			return
		end
	end

	local targetMob = targetRef.mobile
	local weight
	if (not targetMob)
	and lootType then
		if not (
			(lootType == CONT_T)
			or (lootType == DOOR_T)
		) then
			weight = getRefWeight(targetRef)
		end
	end

	local companions = {}
	local maxDist = config.maxDistance

	local friendlyActors = mobilePlayer.friendlyActors
	for i = 1, #friendlyActors do
		local mob = friendlyActors[i]
		if not (mob == mobilePlayer) then
			---assert(mob)
			local mobileRef = mob.reference
			---assert(mobileRef)
			if isCompanion(mobileRef) then
				if logLevel3 then
					mwse.log("%s: getSpreads(%s) companion", modPrefix, mobileRef.id)
				end
				local dist = mob.position:distance(targetRef.position)
				if dist <= maxDist then
					if logLevel2 then
						mwse.log("%s: %s distance from %s = %s", modPrefix, mobileRef.id, targetRef.id, dist)
					end
					local encumb = mob.encumbrance
					---assert(encumb)
					local capacity = encumb.base - encumb.current
					if logLevel2 then
						mwse.log("%s: %s capacity = %s", modPrefix, mobileRef.id, capacity)
					end
					local security = 0
					if mob.actorType == tes3_actorType_npc then
						security = mob.security.current
					end
					table.insert(companions, {mobRef = mobileRef, cap = capacity, sec = security})
				end
			end
		end
	end

	table.sort(companions, function(a,b) return a.cap > b.cap end) -- sort by decreasing companion capacity first
	if (lootType == CONT_T)
	or (lootType == DOOR_T) then
		table.sort(companions, function(a,b) return a.sec > b.sec end) -- sort by decreasing companion security too
	end

	local overburdenAllowed = config.allowLooting > 1 -- 0 = No, 1 = Yes, No Overburdening, 2 = Yes, Overburdening
	local maxCapacity = 0

	lastCompanionRef = nil -- reset it
	for i = 1, #companions do
		local comp = companions[i]
		if overburdenAllowed
		or (comp.cap > 0) then
			maxCapacity = comp.cap
			lastCompanionRef = comp.mobRef
			break
		end
	end

	if not lastCompanionRef then
		return
	end

	local companionName = lastCompanionRef.object.name
	local playerName = player.object.name
	local itemName = targetRef.object.name
	local i = math.random(100)
	local companionIsNPC = (lastCompanionRef.mobile.actorType == 1)
	if weight
	and (maxCapacity <= weight) then
		local inam = strip(itemName)
		if config.allowLooting == 1 then -- 1 = Yes, No Overburdening
			if i > 75 then
				if companionIsNPC then
					tes3ui.showNotifyMenu("%s:\n\"I can't carry more than this!\"", companionName)
				else
					tes3ui.showNotifyMenu("%s cannot carry any more.\"", companionName)
				end
			elseif i > 50 then
				if companionIsNPC then
					tes3ui.showNotifyMenu("%s:\n\"%s, I am not your beast of burden!\"", companionName, playerName)
				else
					tes3ui.showNotifyMenu("%s would become overburdened.", companionName)
				end
			elseif i > 25 then
				if companionIsNPC then
					tes3ui.showNotifyMenu("%s:\n\"Sorry %s but... no, I can barely move already.\"", companionName, playerName)
				else
					tes3ui.showNotifyMenu("%s cannot carry the %s.\"", companionName, inam)
				end
			else
				if companionIsNPC then
					tes3ui.showNotifyMenu("%s:\n\"%s? Sorry, too heavy for me.\"", companionName, inam)
				else
					tes3ui.showNotifyMenu("%s loot is too heavy for %s.\"", inam, companionName)
				end
			end
			return -- skip
		elseif overburdenAllowed then
			if companionIsNPC then
				if i > 75 then
					tes3ui.showNotifyMenu("%s:\n\"I am sworn to carry your burdens.\"", companionName)
				elseif i > 50 then
					tes3ui.showNotifyMenu("%s:\n\"So you DO think I am your beast of burden.\"", companionName)
				elseif i > 25 then
					tes3ui.showNotifyMenu("%s:\n\"%s, I cannot move freely any more while carrying this %s.\"", companionName, playerName, inam)
				else
					tes3ui.showNotifyMenu("%s:\n\"You can't be serious! I am already overburdened.\"", companionName)
				end
			elseif i > 75 then
				tes3ui.showNotifyMenu("%s:\n\"%s is overburdened by the %s.\"", companionName, inam)
			end
		end
	end
	if logLevel3 then
		mwse.log("%s: maxCapacity = %s, lastCompanionRef = %s", modPrefix, maxCapacity, lastCompanionRef.id)
	end
	lastTargetRef = targetRef
	---assert(companionMob)

	if targetMob
	and targetMob.actorType then
		if config.allowLooting > 0 then
			companionLootContainer(lastCompanionRef, targetRef)
		end
		return
	end

	if weight then
		if config.allowLooting > 0 then
			if lootType == BOOK_T then -- special case for books
				takeItem(lastCompanionRef, targetRef) -- add one copy to inventory and delete the in-world original
			elseif canWalkTo(lastCompanionRef, targetRef) then -- should be able to walk to the target
				local companionMob = lastCompanionRef.mobile
				sneakForSec(companionMob, 3)
				if targetRef.itemData then
					takeItem(lastCompanionRef, targetRef) -- add one copy to inventory and delete the in-world original
				else
					---takeItem(lastCompanionRef, targetRef)
					---tes3.setAIActivate({ reference = lastCompanionRef, target = targetRef }) -- has problems with object.data?
					doActivate(lastCompanionRef, targetRef)
				end
			else -- force activation from distance
				if targetRef.itemData then
					takeItem(lastCompanionRef, targetRef) -- add one copy to inventory and delete the in-world original
				else
					---takeItem(lastCompanionRef, targetRef)
					doActivate(lastCompanionRef, targetRef)
				end
			end
		end
		return
	end

	if ( (lootType == CONT_T)
	or (lootType == DOOR_T) ) then
		tryCompanionThievery(lastCompanionRef, targetRef)
	end
end


local function checkCompanionActivate(targetRef)
	if logLevel2 then
		mwse.log('%s: checkCompanionActivate(targetRef = %s)', modPrefix, targetRef)
	end
	if not targetRef then
		return
	end
	local obj = targetRef.baseObject
	local lootType = obj.objectType
	if logLevel2 then
		local lt
		if lootType then
			lt = mwse.longToString(lootType)
		end
		mwse.log('%s: checkCompanionActivate(lootType = %s)', modPrefix, lt)
	end
	local mob = targetRef.mobile
	if not lootType then
		return
	end
	if mob or lootType then
		L.companionActivate(targetRef)
	end
end


local persContId = "com_chest_02_j'zhirr" ---'ab01smcompTempCont'
local persContObj -- set in modConfigReady()
local persContRef -- set in loaded()

local lightLoopSoundFixBusy = false

local function ab01smcompPT5(e)
	local ref = getTimerRef(e)
	if ref then
		-- move lights back to creature inventory
		if tes3.transferInventory({from = persContRef, to = ref,
				playSound = false, updateGUI = false, limitCapacity = false,
				reevaluateEquipment = false, equipProjectiles = false}) then
			if logLevel3 then
				mwse.log('%s: tes3.transferInventory({from = "%s", to = "%s"})',
					modPrefix, persContRef, ref)
			end
		end
	end
	lightLoopSoundFixBusy = false
end

local function lightLoopSoundFix(mobileCrea)
	if not persContRef then
		if logLevel > 0  then
			mwse.log('%s: lightLoopSoundFix() "%s" persistent container not found', modPrefix, persContId)
		end
	end
	local mobRef = mobileCrea.reference
	if logLevel2 then
		mwse.log('%s: lightLoopSoundFix("%s")', modPrefix, mobRef.id)
	end
	if lightLoopSoundFixBusy then
		return
	end
	lightLoopSoundFixBusy = true
	-- remove lights from creature inventory to stop looping sound bug

	-- cached here inside function only because weird Lua allows only max 200 local variables in the main
	local tes3_objectType_light = tes3.objectType.light

	local function onlyLights(item)
		return item.objectType == tes3_objectType_light
	end

	if tes3.transferInventory({from = mobRef, to = persContRef, filter = onlyLights,
			limitCapacity = false, playSound = false, updateGUI = false,
			reevaluateEquipment = false, equipProjectiles = false}) then
		if logLevel3 then
			mwse.log('%s: tes3.transferInventory({from = "%s", to = "%s"})',
				modPrefix, mobRef, persContRef)
		end
		timer.start({duration = 0.3, type = timer.real,	callback = 'ab01smcompPT5',
			data = {handle = tes3.makeSafeObjectHandle(mobRef)}
		})
		return
	end
	lightLoopSoundFixBusy = false
end

local tes3_dialogueType_voice = tes3.dialogueType.voice
---local tes3_dialogueType_topic = tes3.dialogueType.topic

local filteredDict = nil -- dictionary of actor ids to have filtered out attack/hello voices

local function infoFilter(e)
	if not e.passes then
		return -- early skip when not needed
	end
	if not filteredDict then
		return
	end
	local ref = e.reference
	if not ref then
		return
	end
	local dType = e.dialogue.type
	--[[if dType == tes3_dialogueType_topic then
		if isCompanion(e.reference) then
			local json = e.info:__tojson()
			if json then
				mwse.log(json)
			end
		end
		return
	end]]
	if not (dType == tes3_dialogueType_voice) then
		return -- only interested in voices
	end
	local dialogueId = e.dialogue.id
	if not (
		(dialogueId == 'Attack')
	 or (dialogueId == 'Hello')
	) then
	   return -- only interested in blocking Attack & Hello voices
	end
	if muteCC == 0 then
		return
	end
	local refId = ref.id
	if muteCC == 1 then
		if logLevel4 then
			mwse.log('%s: infoFilter("%s") %s muteCC == 1 filteredDict["%s"] = %s',
				modPrefix, refId, dialogueId, refId, filteredDict[refId])
		end
		if not filteredDict[refId] then
			return
		end
		filteredDict[refId] = nil
	end

	e.passes = false -- disable this voice

	if not logLevel3 then
		return
	end
	local spacing = ' '
	local s = e.info.text
	if s
	and ( string.len(s) > 30 ) then
		spacing = '\n'
	end
	mwse.log('%s: infoFilter("%s") muted [%s]:%s"%s"',
		modPrefix, refId, dialogueId, spacing, s)

end

local function ab01smcompPT6()
	filteredDict = nil
end

local function ab01smcompPT7(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	ref:enable()
end

local function ab01smcompPT8(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	mob:stopCombat(true)
	if not mob.isFlying then
		timer.start({duration = 0.075, type = timer.real, callback = 'ab01smcompPT7',
			data = {handle = tes3.makeSafeObjectHandle(ref)}
		})
		ref:disable()
	end
end

--[[
local function ab01smcompPT9(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	if logLevel3 then
		mwse.log('%s: ab01smcompPT9(e): reevaluating "%s" equipment', modPrefix, ref.id)
	end
	ref.object:reevaluateEquipment()
end
]]

function L.isValidNPC(ref)
	if not ref then
		return false
	end
	local mob = ref.mobile
	if not mob then
		return false
	end
	if not ref.sceneNode then
		return false
	end
	if ref.disabled then
		return false
	end
	if ref.deleted then
		return false
	end
	local obj = ref.baseObject
	local race = obj.race
	if not race then
		return false
	end
	if not race.isPlayable then
		return false -- not a playable race
	end
	local actorType = mob.actorType -- 0 = creature, 1 = NPC, 2 = player
	if actorType == tes3_actorType_npc then
		if isDead(mob) then
			return false
		end
		return true
	end
	return false
end

function L.isFollowingOrEscorting(mob, targetActor)
	if targetActor then
		local aiTargetMob = getMobAiFollowOrEscortTarget(mob)
		if targetActor == aiTargetMob then
			return true
		end
	end
	return false
end

local tes3_enchantmentType_constant = tes3.enchantmentType.constant

-- reset to false in cellChanged(e)
local skipConstEnchFix = false

local function fixRefConstEnch(ref)
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	local refObj = ref.object
	local inventory = refObj.inventory
	if not inventory then
		return
	end

	local tempData = ref.tempData
	if tempData
	and tempData.ab01smcmpscef then
		if skipConstEnchFix then
			return
		end
		tempData.ab01smcmpscef = nil
	end

	if not L.isValidNPC(ref) then
		return
	end

	if not L.isFollowingOrEscorting(mob, mobilePlayer) then
		return
	end
	local items = inventory.items
	local t = {}
	local count = 0
	local stack, obj, enchantment
	for i = 1, #items do
		stack = items[i]
		obj = stack.object
		enchantment = obj.enchantment
		if enchantment
		and (enchantment.castType == tes3_enchantmentType_constant) then
			count = count + 1
			t[count] = {id = obj.id, name = obj.name}
		end
	end
	if count <= 0 then
		return
	end
	local update = false
	local data, id, name
	for i = 1, #t do
		data = t[i]
		id = data.id
		name = data.name
		if refObj:hasItemEquipped(id) then
			update = true
			-- try and avoid triggering Better Clothes warnings spamming the log
			pcall( mob:unequip({item = id}) )
			pcall( mob:equip({item = id}) )
			if logLevel3 then
				mwse.log('%s: follower "%s" "%s" reequipping constant enchantment item "%s" "%s"',
				modPrefix, ref.id, ref.object.name, id, name)
			end
		end
	end
	if update then
		ref:updateEquipment()
		---timer.start({duration = 1, callback = 'ab01smcompPT9',
		---data = {handle = tes3.makeSafeObjectHandle(ref)} })
		skipConstEnchFix = true
		if not ref.tempData then
			ref.tempData = {}
		end
		ref.tempData.ab01smcmpscef = 1
	end
end

local maxScanInterval = 2

local function processScanInterval(ref)
	local mob = ref.mobile
	if not mob then
		return
	end
	local actorType = mob.actorType
	if not actorType then
		return
	end
	local scanInterval = mob.scanInterval
	if scanInterval then
		scanInterval = math.round(scanInterval, 1)
		if scanInterval > maxScanInterval then
			maxScanInterval = scanInterval
			if logLevel3 then
				mwse.log('%s: processScanInterval("%s") maxScanInterval increased to %s',
					modPrefix, ref.id, maxScanInterval)
			end
		end
	end
	local mobAItarget = getMobAiFollowOrEscortTarget(mob)
	if not mobAItarget then
		return
	end
	local mp = tes3.mobilePlayer
	if not mp then
		return
	end
	if not (mobAItarget == mp) then
		return
	end
	local minScanInterval = config.scanInterval
	if scanInterval <= minScanInterval then
		return
	end
	if logLevel3 then
		mwse.log('%s: processScanInterval("%s") follower scanInterval set to %s',
			modPrefix, ref.id, minScanInterval)
	end
	mob.scanInterval = minScanInterval
end

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local animBlacklist = {'sittin','scamp','lean','wait'}

local function isAnimBlacklisted(mobRef)
	local mesh = mobRef.object.mesh
	if not mesh then
		return false
	end
	if mesh == '' then
		return false
	end
	local s = string.lower(back2slash(mesh))
	if string.sub(s, 1, 3) == 'am/' then -- path starting with "am/", probably Antares' animation
		return true
	end
	if string.find(s, 'am_', 1, true) then -- am_ prefix somewhere in path, probably Antares'
		return true
	end
	if string.multifind(s, animBlacklist, 1, true) then
		return true
	end
	return false
end

local function checkIdleFix(mob)
	local mobRef = mob.reference
	if isAnimBlacklisted(mobRef) then
		return
	end
	local animationController = mob.animationController
	if animationController then -- could be nil
		if animationController.animationData.hasOverrideAnimations then
			return -- skip e.g. a drummer
		end
	end
	playGroupIdle(mobRef)
end

local tes3_actorType_player = tes3.actorType.player

local function referenceActivated(e)
	-- luckily this includes followers on cellchange
	local ref = e.reference
	local mob = ref.mobile
	if not mob then
		return
	end
	local actorType = mob.actorType
	if not actorType then
		return
	end	
	if actorType == tes3_actorType_player then
		return
	end
	if ref.disabled then
		return
	end
	if ref.deleted then
		return
	end
	if isDead(mob) then
		return
	end
	if config.fixAnim then
		checkIdleFix(mob)
	end
	if config.fixConstEnch then
		fixRefConstEnch(ref)
	end
	if config.scanIntervalTweak then
		processScanInterval(ref)
	end
end

--[[
local function combatFix(mob)
	local mobRef = mob.reference
	if not mobRef then
		return
	end
	filteredDict = {mobRef.id}
	---setInfoFilter(true) -- disable attack/greeting voices/subtitles. ab01smcompPT6 will re-enable them
	timer.start({duration = 1.1, type = timer.real, callback = 'ab01smcompPT6'})
	if logLevel3 then
		local refId = mobRef.id
		mwse.log('%s: combatFix() "%s":startCombat("%s")', modPrefix, refId, refId)
	end
	timer.start({duration = 0.1, type = timer.real, callback = 'ab01smcompPT8',
		data = {handle = tes3.makeSafeObjectHandle(mobRef)}
	})
	mob:startCombat(mob)
end
]]

function L.handsDown(mob)
	if mob.weaponReady then
		mob.weaponReady = false
	elseif mob.castReady then
		mob.castReady = false
	end
end

function L.resetAnimation(mob)
	local mobRef = mob.reference
	if isAnimBlacklisted(mobRef) then
		return
	end
	L.handsDown(mob)
-- 0 = invalid, 1 = follower, 2 = companion
	if validFollower(mob, true) == 0 then -- not a follower
		local animationController = mob.animationController
		if animationController then -- could be nil
			if animationController.animationData.hasOverrideAnimations then
				return -- skip e.g. a drummer
			end
		end
		-- wander 0 only if not a follower and not having some overridden animation
		aiWander0(mobRef)
	end
	playGroupIdle(mobRef)
end

local tes3_aiBehaviorState_walk = tes3.aiBehaviorState.walk


---@param mob tes3mobileActor
---@param actionData tes3actionData
function L.fixAiWalkDestinations(mob, actionData)
	if not actionData then
		return
	end
	if not mob then
		return
	end
	local ref = mob.reference
	if not ref then
		return
	end
	local aiBehaviorState = actionData.aiBehaviorState
	if not (aiBehaviorState == tes3_aiBehaviorState_walk) then
		return
	end
	local refPos = ref.position:copy()
	local v
	for _, field in ipairs({'lastPositionBeforeCombat', 'walkDestination'}) do
		v = actionData[field]
		if v
		and v:distance(refPos) > 34576 then -- 3 cells diagonal
			v.x = refPos.x
			v.y = refPos.y
			v.z = refPos.z
			if logLevel4 then
				mwse.log('%s: fixAiWalkDestination("%s") %s reset',
					modPrefix, ref.id, field)
			end
		end
	end
end

function L.fixActionData(mob)
	L.fixAiWalkDestinations(mob, mob.actionBeforeCombat)
	L.fixAiWalkDestinations(mob, mob.actionData)
end

function L.fixMobileAI(mob)
	if logLevel3 then
		mwse.log('%s: fixMobileAI("%s")', modPrefix, mob.reference.id)
	end

	if mob.actorType == tes3_actorType_creature then
		lightLoopSoundFix(mob)
	end

	mob:stopCombat(true)
	L.fixActionData(mob)

-- some NullCascade's wizardry
-- https://discord.com/channels/210394599246659585/381219559094616064/826742823218053130
-- does it still work? or does it conflict? it works (again?) it seems
---@diagnostic disable-next-line: undefined-field
	mwse.memory.writeByte({address = mwse.memory.convertFrom.tes3mobileObject(mob) + 0xC0, byte = 0x00})

	L.resetAnimation(mob)

	--[[
	-- disabled for now as NullCascade's wizardry works (again?)
	timer.start({duration = 1.5, callback =
		function ()
			combatFix(mob) -- note to self: the delay is important!
		end
	})
	]]
end

function L.addBurden(mob)
	if not mob:isAffectedByObject(burdenSpell) then
		if logLevel3 then
			mwse.log('%s: addBurden("%s")', mob.reference.id)
		end
		tes3.addSpell({reference = mob, spell = burdenSpell})
	end
end

function L.checkRemoveBurden(mob)
	local mobRef = mob.reference
	if logLevel5 then
		mwse.log('%s: checkRemoveBurden("%s")', modPrefix, mobRef)
	end
	if mob:isAffectedByObject(burdenSpell) then
		if logLevel3 then
			mwse.log('%s: checkRemoveBurden tes3.removeSpell({reference = "%s", spell = burdenSpell})', modPrefix, mobRef)
		end
		tes3.removeSpell({reference = mobRef, spell = burdenSpell})
		-- nope conflict with removeSpellEffects in local script
		-- tes3.removeEffects({reference = mobRef, effect = tes3.effect.burden})
	end
end

local fixFatiguedDict = {['lack_qac_aaiona'] = true, ['lack_qac_aandren'] = true,
['lack_qac_amelierelm'] = true, ['lack_qac_assassin'] = true}

function L.activate(e)
	local targetRef = e.target
	if not targetRef then
		return
	end

	local activatorRef = e.activator
	if not activatorRef then
		return -- it happens
	end

	if logLevel4 then
		mwse.log("%s: activate() activatorRef = %s, targetRef = %s", modPrefix, activatorRef.id, targetRef.id)
	end

	-- never say never
	if targetRef == player then
		return
	end

	local targetObj = targetRef.baseObject
	if activatorRef == player then
		local targetMob = targetRef.mobile
		local targetMobIsDead = false
		if targetMob
		and targetMob.actorType then
			L.checkRemoveBurden(targetMob)
			targetMobIsDead = isDead(targetMob)
			if not targetMobIsDead then
				local AIfixOnActivate = config.AIfixOnActivate
				local skipSneak = mobilePlayer.isSneaking
					and config.skipActivatingFollowerWhileSneaking
				local companion = getCompanionVar(targetRef)
				if (companion and (companion == 1))
				or isValidScenicFollower(targetMob) then
					  -- try and fix weird levitate glitches
					if mobilePlayer.levitate > 0 then
						if targetMob.levitate <= 0 then
							targetMob.levitate = 1
							targetMob.isFlying = true
						end
					elseif not (targetMob.levitate == 0) then
						targetMob.levitate = 0
						targetMob.isFlying = false
					end
					if AIfixOnActivate == 2 then
						L.fixMobileAI(targetMob)
					elseif AIfixOnActivate == 1 then
						if companion == 1 then
							L.fixMobileAI(targetMob)
						end
					end
					if config.transparencyFixOnActivate then
						L.resetTransparency(targetMob)
					end
					if targetMob.alarm > 0 then
						if config.fixAlarm then
							targetMob.alarm = 0
						end
					end
					if targetMob.actorType == tes3_actorType_npc then -- 0 = creature, 1 = NPC, 2 = player
						if targetMob.waterBreathing < 1 then
							if config.fixWaterBreathing then
								targetMob.waterBreathing = 1
							end
						end
						if targetMob.acrobatics.current < 200 then
							if config.fixAcrobatics then
								targetMob.acrobatics.current = 200
							end
						end
						if targetMob.athletics.current < 240 then
							if config.fixAthletics then
								targetMob.athletics.current = 240
							end
						end
					end
					if targetMob.fatigue.current <= 0 then
						local skip = fixFatiguedDict[string.lower(targetObj.id)]
						if skip then
							local knockout = getRefVariable(targetRef, 'knockout')
							if knockout
							and (knockout == 0) then
								skip = false
								-- set the variable else they will keep
								setRefVariable(targetRef, 'knockout', 1)
								if logLevel1 then
									mwse.log('%s: activate() resetting "%s" fatigue', modPrefix, targetObj.name)
								end
							end
						end
						if not skip then
							-- stand up from collapsed state
							targetMob.fatigue.current = targetMob.fatigue.base
						end
					end
					if mobilePlayer.isSneaking then
						if (targetMob.actorType == tes3_actorType_creature)
						and ( tes3.isAffectedBy({reference = mobilePlayer, effect = tes3.effect.slowFall}) )
						and isMount(targetRef) then
							return -- IMPORTANT!!! don't skip normal activate when riding a creature!!!
						end
						if skipSneak then
							return false
						end
					end -- if mobilePlayer.isSneaking
				elseif AIfixOnActivate == 3 then
					L.fixMobileAI(targetMob)
					if skipSneak then
						return false
					end
					return
				end -- if companion or follower
			end -- if not targetMobIsDead
		end -- if targetMob

		-- not (alive actor target) below

		if not inputController:isAltDown() then
			return
		end
		-- alt pressed below

		if skipPlayerAltActivate then
			-- nope it may still crash player can activate only normally to allow container animation, no more Alt process
			-- e.claim = true
			--- return false
			return
		end

		if targetMob
		and targetMob.actorType
		and (config.allowLooting > 0) then
			if targetMobIsDead then
				if isLootable(targetObj) then
					timer.start({ duration = 0.1,
						callback = function ()
							checkCompanionActivate(targetRef)
						end
					})
					-- skip standard activation this frame!
					---e.claim = true
					return false
				end
			elseif config.AIfixOnActivate > 0 then
				L.fixMobileAI(targetMob)
			end
			return
		end

		-- not a mob target below

		--[[ too restrictive
		local hasOnActivate = not targetRef:testActionFlag(tes3.actionFlag.useEnabled)
		if hasOnActivate then
			if logLevel2 then
				mwse.log("%s: activatorRef = %s, targetRef = %s hasOnActivate, skip", modPrefix, activatorRef.id, targetRef.id)
			end
			return
		end
		]]

		if tes3ui.menuMode() then
			return
		end

		local function getValidObjLootType(obj)
			local ot = obj.objectType
			if logLevel3 then
				mwse.log("%s: %s obj.objectType = %s", modPrefix, obj.id, mwse.longToString(ot))
			end
			if validLootTypes[ot] then
				return ot
			end
			return nil
		end

		if getValidObjLootType(targetObj) then
			if isLootable(targetObj) then
				timer.start({ duration = 0.1, type = timer.real,
					callback = function ()
						checkCompanionActivate(targetRef)
					end
				})
			end
			-- skip standard activation this frame!
			---e.claim = true
			return false
		end -- if getValidObjLootType(targetObj)
		return

	end -- if activatorRef == player


	-- not (activatorRef == player) below
	if not (activatorRef == lastCompanionRef) then
		return
	end

	if not (targetRef == lastTargetRef) then
		return
	end

	local objType = targetObj.objectType
	if objType == DOOR_T then
		return
	end

	if config.allowLooting == 0 then
		return
	end

	takeMessageBox(activatorRef, targetRef)
	checkCrime(activatorRef, targetRef)
end


local function combatStopped(e)
	if not mobilePlayer then
		return
	end
	local friendlyActors = mobilePlayer.friendlyActors
	if not friendlyActors then
		return
	end
	local actorMob = e.actor
	local playerStoppedCombat = (actorMob == mobilePlayer)
	if (not playerStoppedCombat)
	and (not config.fixConstEnch) then
		return
	end
	local actorRef = actorMob.reference
	for i = 1, #friendlyActors do
		local mob = friendlyActors[i]
		if not (mob == mobilePlayer) then
			if playerStoppedCombat then
				L.checkRemoveBurden(mob)
				L.fixActionData(mob)
				skipConstEnchFix = false
			elseif actorRef == mob.reference then
				if config.fixConstEnch then
					fixRefConstEnch(actorRef)
				end
			end
		end
	end
end

function L.isMountedAbotGuar(mob)
	local mobRef = mob.reference
	if not mobRef then
		return false
	end
	local lcId = string.lower(mobRef.object.id)
	if not (lcId == 'ab01guguarpackmount') then
		return false
	end

	local ab01compMount = getRefVariable(mobRef, 'ab01compMount')
	if ab01compMount
	and (ab01compMount == 3) then
		return true
	end
	return false
end

local dummies = {'dumm', 'mann', 'target', 'invis'}

function L.isDummy(mob)
	local mobRef = mob.reference
	local obj = mobRef.baseObject
	if multifind2(string.lower(obj.id), string.lower(obj.name), dummies) then
		return true
	end
	local race = obj.race
	if race then
		 -- check for invisible race NPC
		local chest = race.maleBody.chest
		if not chest then
			chest = race.femaleBody.chest
		end
		if not chest then
			return true
		end
		local mesh = chest.mesh
		if not mesh then
			return true
		end
		if mesh == '' then
			return true
		end
	end
	local mesh = obj.mesh
	if not mesh then
		return false
	end
	if mesh == '' then
		return false
	end
	if string.multifind(string.lower(mesh), dummies, 1, true) then
		return true
	end
	return false
end

local function combatStart(e)
	local attackerMob = e.actor
	if not attackerMob then
		return
	end
	local targetMob = e.target
	if not targetMob then
		return
	end
	--[[
	if attackerMob == targetMob then -- skip companions trying to reset AI
		if logLevel3 then
			mwse.log('%s: combatStart(e) e.actor == e.target == "%s", skip', modPrefix, attackerMob.reference.id)
		end
		return false
	end
	]]
	if not config.ignoreMannequinAttacks then
		return
	end
	if L.isDummy(attackerMob)
	or L.isDummy(targetMob) then
		return false
	end
end

local combatStartRegistered = false

function L.setCombatStart(on)
	if combatStartRegistered
	or event.isRegistered('combatStart', combatStart) then
		if on then
			return
		end
		combatStartRegistered = false
		event.unregister('combatStart', combatStart)
		return
	end
	if on then
		combatStartRegistered = true
		event.register('combatStart', combatStart)
	end
end

-- should replace diligent defenders but to work
-- when diligent defenders is present priority needs to be higher
local function combatStarted(e)
	local attackerMob = e.actor
	if not attackerMob then
		return
	end
	local targetMob = e.target
	if not targetMob then
		return
	end

	if attackerMob == targetMob then
		return
	end

	if (config.autoAttack == 0)
	and (not config.autoBurden)
	and (not config.fixConstEnch) then
		return
	end

	if not mobilePlayer then
		return
	end
	local friendlyActors = mobilePlayer.friendlyActors
	if not friendlyActors then
		return
	end

	local skip = true
	for i = 1, #friendlyActors do -- player included
		local mob = friendlyActors[i]
		if mob
		and (mob == targetMob) then
			skip = false
			break
		end
	end
	if skip then
		return
	end

	-- below: target is a friendly actor (player included)
	local anyFollower = config.autoAttack >= 2

	-- 0 = invalid, 1 = follower, 2 = companion
	local attackerIsFollower = (validFollower(attackerMob, anyFollower) > 0)
	if attackerIsFollower then
		return
	end
	for i = 1, #friendlyActors do
		local mob = friendlyActors[i]
		if mob
		and (not (mob == mobilePlayer))
		and (not (mob == attackerMob))
		and (not (mob == targetMob)) then
			local valid = validFollower(mob, anyFollower, true)
			if valid > 0 then
				if valid == 2 then -- companion
					if (not mob.isAttackingOrCasting)
					and (not inCombat(mob))
					and (not L.isMountedAbotGuar(mob)) then
						---mwscript.startCombat({reference = mob, target = attackerMob})
						mob:startCombat(attackerMob)
					end
				else -- follower
					if config.autoBurden then
						L.addBurden(mob)
					end
				end
				---if config.fixConstEnch then
					---fixRefConstEnch(ref)
				---end
			end
		end
	end
end

local combatStartedRegistered = false

function L.setCombatStarted(on)
	-- should replace diligent defenders but to work
	-- when diligent defenders is present priority needs to be higher
	local settings = {priority = 100}
	if combatStartedRegistered
	or event.isRegistered('combatStarted', combatStarted, settings) then
		if on then
			return
		end
		combatStartedRegistered = false
		event.unregister('combatStarted', combatStarted, settings)
		return
	end
	if on then
		combatStartedRegistered = true
		event.register('combatStarted', combatStarted, settings)
	end
end

function L.checkCombatRegistering()
	local combatStartOn = config.ignoreMannequinAttacks
	L.setCombatStart(combatStartOn)

	local combatStartedOn = (config.autoAttack > 0)
	or config.autoBurden
	or config.fixConstEnch
	L.setCombatStarted(combatStartedOn)
end

function L.save()
	---L.packTravellers()
	---L.packWarpers()
	local player_data = player.data
	player_data.ab01travelType = travelType
	player_data.ab01travellers = travellers
	player_data.ab01warpers = warpers

	local function getTable3FromVec3(v)
		return {round(v.x), round(v.y), round(v.z)}
	end

	local t = {}
	local doLog = logLevel >= 4
	local j = 0
	for i, v in ipairs(lastPlayerPositions) do
		if v.pos then
			local t3 = getTable3FromVec3(v.pos)
			local cId = v.cellId
			if doLog then
				mwse.log('%s: save() ab01lastPlayerPositions[%s] = { cellId = "%s", pos = {%s, %s, %s} }',
					modPrefix, i, cId, t3[1], t3[2], t3[3])
			end
			j = j + 1
			t[j] = {cellId = cId, pos = t3}
		end
	end
	player_data.ab01lastPlayerPositions = t
end


function L.autoMove()
	local moving = {}
	local anyFollower = config.autoWarp >= 2
	local warp2player = config.autoWarp > 0
	local playerSizeY = mobilePlayer.boundSize.y * player.scale
	local friendlyActors = mobilePlayer.friendlyActors
	local pcCell = player.cell
	local playerCellIsRealInterior = not pcCell.isOrBehavesAsExterior
	local count = 0
	filteredDict = {}
	timer.start({duration = 1.2, type = timer.real,
		callback = 'ab01smcompPT6'}) -- reset filteredDict to nil

	for i = 1, #friendlyActors do
		local mob = friendlyActors[i]
		local valid = validFollower(mob, anyFollower, true)
		if valid > 0 then
			local mobRef = mob.reference
			local mobCell = mobRef.cell

			local ok = true

			if ( not (pcCell == mobCell) )
			and playerCellIsRealInterior
			and mobCell.isOrBehavesAsExterior
			and isStayOutside(mob) then
				ok = false
			end

			if ok then
				count = count + 1
				moving[count] = mob
				filteredDict[mobRef.id] = count
			end
		end
	end

	if count <= 0 then
		return
	end

	local destPos, size, dist
	local right = false
	local aStep = math.rad(120) / count
	local a = player.facing
	local steps = 5
	local baseRadius = playerSizeY
	local k
	local j = 1
	local autoMoveCC = config.autoMoveCC
	for i = 1, count do
		local mob = moving[i]
		local mobRef = mob.reference
		if warp2player then
			destPos = player.position:copy()
		else
			destPos = mobRef.position:copy()
		end
		if autoMoveCC then
			size = mob.boundSize.y * mobRef.scale
			dist = (baseRadius + size) * 0.6
			if not playerCellIsRealInterior then
				if j < steps then
					j = j + 1
				else
					j = 1
					baseRadius = baseRadius + playerSizeY
				end
			end
			destPos.x = destPos.x - (dist * math.sin(a))
			destPos.y = destPos.y - (dist * math.cos(a))
		end
		if logLevel3 then
			mwse.log('%s: autoMove() tes3.positionCell({reference = "%s", cell = "%s", position = %s})',
				modPrefix, mobRef.id, pcCell.editorName, destPos)
		end
		--- aiWander0(mobRef) --  no better to keep follow package
		playGroupIdle(mobRef)
		tes3.positionCell({reference = mobRef, cell = pcCell,
			position = destPos, orientation = player.facing})
		k = i * aStep
		if right then
			a = a - k
		else
			a = a + k
		end
		right = not right
		--- wanderInPlace(mobRef) -- no better to keep follow package
	end
end

local function cellChanged(e)
	---actorRefs = {}
	if not e.previousCell then
		return
	end
	if (e.cell == e.previousCell)
	and (not e.cell.isInterior) then
		return -- odd, but it may happen
	end
	if travelType > 0 then
		return -- no warp while traveling
	end
	if e.cell.isInterior
	or e.previousCell.isInterior then
		lastPlayerPositions = {}
	end
	skipConstEnchFix = false
	if config.autoMoveCC
	or (config.autoWarp > 0) then
		L.autoMove()
	end
end

local initDone = false
function L.initOnce()
	if initDone then
		return
	end
	initDone = true
	ab01mountNPCAbility = tes3.getObject('ab01mountNPCAbility')
	timer.register('ab01smcompPT1', ab01smcompPT1)
	timer.register('ab01smcompPT2', ab01smcompPT2)
	timer.register('ab01smcompPT3', ab01smcompPT3)
	timer.register('ab01smcompPT4', ab01smcompPT4)
	timer.register('ab01smcompPT5', ab01smcompPT5)
	timer.register('ab01smcompPT6', ab01smcompPT6)
	timer.register('ab01smcompPT7', ab01smcompPT7)
	timer.register('ab01smcompPT8', ab01smcompPT8)
	---timer.register('ab01smcompPT9', ab01smcompPT9)

	event.register('save', L.save)
	event.register('cellChanged', cellChanged)
	event.register('combatStopped', combatStopped)

	local ab01compLevitate = tes3.getObject('ab01compLevitate')
	if ab01compLevitate then
---@diagnostic disable-next-line: param-type-mismatch
		local levitateEffectIndex = ab01compLevitate:getFirstIndexOfEffect(tes3_effect_levitate)
		if levitateEffectIndex
		and (levitateEffectIndex > 0) then -- -1 if not found
			local effect = ab01compLevitate.effects[levitateEffectIndex + 1] -- zero based
			if effect then
				effect.min = 5
				effect.max = 5
			end
		end
	end

	L.checkCombatRegistering()

-- high priority to try avoiding problems
-- if another mod does not properly check for activator being the player
-- Book Pickup mod has priority 10
	event.register('activate', L.activate, {priority = 100000})
	---event.register('infoFilter', infoFilter)
	event.register('infoFilter', infoFilter)
	event.register('referenceActivated', referenceActivated)
	event.register('objectInvalidated', objectInvalidated)

end

function L.loaded()
	local funcPrefix = modPrefix .. ' loaded()'
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer

	L.updateFromConfig()

	tes3gmst_fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult)
	tes3gmst_fTrapCostMult = tes3.findGMST(tes3.gmst.fTrapCostMult)
	lastCompanionRef = nil
	lastTargetRef = nil
	skipPlayerAltActivate = false
	lightLoopSoundFixBusy = false

	persContRef = tes3.getReference(persContId)
	if not persContRef then
		persContRef = tes3.createReference({
			object = persContObj,
			position = tes3vector3.new(-100, 0, 0),
			orientation = tes3vector3.new(0, 0, 0),
			cell = 'Seyda Neen, Census and Excise Office',
			persistent = true,
			modified = true, -- we want to store it if possible
		})
		if persContRef then
			local obj = persContRef.object
			if not obj.isInstance then
				local cloned = persContRef:clone() -- returns a boolean, autoupdates the reference
				if cloned then -- resolve container contents
					persContRef = tes3.getReference(persContId) -- unsure if needed but just in case
				end
			end
		end
		if not persContRef then
			mwse.log('%s: warning unable to create "%s" persistent container reference', funcPrefix, persContId)
		end

	end
	if not persContRef then
		mwse.log('%s: warning unable to find or create "%s" persistent container reference', funcPrefix, persContId)
	end

	L.stopMoveTravellers()
	travelType = 0
	
	local player_data = player.data
	local tv = player_data.ab01travellers
	if tv then
		travellers = tv
		L.packTravellers()
	else
		L.cleanTravellers()
	end

	warpers = player_data.ab01warpers
	if warpers then
		L.packWarpers()
	else
		warpers = {}
	end

	clampedLevitateMobs = {}

	lastPlayerPositions = {}

	L.initOnce()

	local ab01lastPlayerPositions = player_data.ab01lastPlayerPositions
	if ab01lastPlayerPositions then
		local function getVec3FromTable3(t)
			return tes3vector3.new(t[1], t[2], t[3])
		end
		local j = 0
		for _, v in ipairs(ab01lastPlayerPositions) do
			if v.pos then
				j = j + 1
				lastPlayerPositions[j] = {cellId = v.cellId, pos = getVec3FromTable3(v.pos)}
			end
		end
	end

	local ab01travelType = player_data.ab01travelType
	if ab01travelType then
		travelType = ab01travelType
		if (travelType > 0)
		and (numTravellers > 0) then
			if logLevel2 then
				mwse.log("%s: travelType = %s, numTravellers = %s", funcPrefix, travelType, numTravellers)
			end
			L.startMoveTravellers()
		end
	end

	local function startWarpFollowers()
		local dur = math.round(1.25 - (0.05 * math.random()), 3)
		if logLevel2 then
			mwse.log("%s: startWarpFollowers() timer.start({duration = %s, callback = warpFollowers, iterations = -1})",
				modPrefix, dur)
		end
		timer.start({duration = dur, callback = warpFollowers, iterations = -1})
	end

	startWarpFollowers()

	L.initScenicTravelAvailable()

	if scenicTravelAvailable then
		local function startTimedTravelProcess()
			local dur = math.round(1.55 - (0.1 * math.random()), 3)
			if logLevel2 then
				mwse.log("%s: startTimedTravelProcess() timer.start({duration = %s, callback = timedTravelProcess, iterations = -1})",
					modPrefix, dur)
			end
			timer.start({duration = dur, callback = L.timedTravelProcess, iterations = -1})

		end
		startTimedTravelProcess()
	elseif travelType > 0 then
		if numTravellers > 0 then
			if logLevel2 then
				mwse.log("%s: travelStop()", funcPrefix)
			end
			L.travelStop()
		end
	end

	currMountRef = nil
	if currMountHandle
	and currMountHandle.valid
	and currMountHandle:valid() then
		currMountRef = currMountHandle:getObject()
		lastMountFacing = currMountRef.facing
	end

	ab01smcompPT6() -- just for safety, should not be needed
end


function L.modConfigReady()

	local template = mwse.mcm.createTemplate({name = mcmName})

	local scanIntervalSlider

	template.onClose = function()

		if (config.autoWarp >= 2)
		and NPCVoiceDistanceGlob then -- NPCVoiceDistance = 750 by default
-- increase NPCVoiceDistanceGlob accordingly to avoid annoying "Hey! Wait for me"
			local v = round(config.warpDistance * 1.5)
			if NPCVoiceDistanceGlob.value < v then
				NPCVoiceDistanceGlob.value = v
			end
		end

		L.updateFromConfig()
		L.checkCombatRegistering()

		if scanIntervalSlider then
			scanIntervalSlider.max = maxScanInterval
		end

		mwse.saveConfig(configName, config, {indent = true})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage({
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			local el = self.elements.sideToSideBlock
			el.children[1].widthProportional = 1.3
			el.children[2].widthProportional = 0.7
		end
	})

	---local sidebar = preferences.sidebar
	---sidebar:createInfo{text = ""}

	local controls = preferences:createCategory({})

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	local optionList = {'No', 'Yes, No Overburdening', 'Yes, Overburdening'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	local function createConfigVariable(varId)
		return mwse.mcm.createTableVariable{id = varId,	table = config}
	end

	controls:createDropdown({
		label = 'Companions Looting:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
When enabled, Alt + activate to make your companions try and loot the target item/container/corpse
(with/without potential overburdening).]], 'allowLooting'),
		variable = createConfigVariable('allowLooting')
	})

	controls:createSlider({
		label = 'Minimum item Value/Weight ratio',
		description = getDescription([[Default: %s.
Minimum Value/Weight ratio for an item to be taken by a companion when looting a container.]], 'minValueWeightRatio'),
		variable = createConfigVariable('minValueWeightRatio')
		,min = 1, max = 100, step = 1, jump = 5
	})

	controls:createYesNoButton({
		label = 'Always loot from organic containers',
		description = getYesNoDescription([[Default: %s.
When enabled, companion NPCs will always loot from organic containers
(e.g. plants) regardless of the Minimum item Value/Weight ratio setting.]], 'alwaysLootOrganic'),
		variable = createConfigVariable('alwaysLootOrganic')
	})

	controls:createSlider({
		label = 'Max Loot Distance',
		description = getDescription([[Default: %s game units.
Maximum distance for an item to be activated by a companion.]], 'maxDistance'),
		variable = createConfigVariable('maxDistance')
		,min = 200, max = 1000, step = 1, jump = 5
	})

	optionList = {'No', 'Only current companions', 'Any follower', 'Any actor'}
	controls:createDropdown({
		label = 'Fix NPC/Creature AI on activate:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
Try and reset actors AI/animation/pose when activating them. Especially useful when they go crazy after teleporting around too much.
It should also try and fix the obnoxious attack sound looping bug often happening when follower creatures carry some light.]],
'AIfixOnActivate'),
		variable = createConfigVariable('AIfixOnActivate')
	})

local ffInfo = [[

Added on request for an alternative to "No More Friendly Fire" mod.

The standard followers behavior is to give advice and become hostile to player if you hit them 3 times.

The "No aggro" options do not increase the actor friendly hits counter.

Note: if you have >= 2 followers and you make one hostile, the other one will usually still attack you by default.
]]

	optionList = {'No', 'Only current companions', 'Any follower', 'Only current companions, no aggro', 'Any follower, no aggro'}
	controls:createDropdown({
		label = 'No (magic) friendly fire:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
No harmful magical friendly fire from/to selected actors.]] .. ffInfo,
'noFriendlyFireMagic'),
		variable = createConfigVariable('noFriendlyFireMagic'),
	})

	controls:createDropdown({
		label = 'No (non-magic) friendly fire:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
No (non magical) health damaging friendly fire from/to selected actors.]] .. ffInfo,
'noFriendlyFireDamage'),
		variable = createConfigVariable('noFriendlyFireDamage'),
	})

	controls:createYesNoButton({
		label = 'Allow player friendly fire soultrapping',
		description = getYesNoDescription([[Default: %s.
Allow player damage to non-companion friendly targets affected by soultrap.
Only effective with some previous friendly fire option enabled.]],
		'friendlyFireSoulTrapping'),
		variable = createConfigVariable('friendlyFireSoulTrapping')
	})

	optionList = {'No', 'Only current companions', 'Any follower'}
	controls:createDropdown({
		label = 'Auto attack enemies:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
An alternative to Diligent Defenders.
If enabled, it should override it having higher priority and delaying the event to next frame.]],
'autoAttack'),
		variable = createConfigVariable('autoAttack')
	})

	controls:createDropdown({
		label = 'Warp to player:',
		options = getOptions(),
		description = string.format([[Default: %s. %s.
Warp valid companions/followers (mostly) at player shoulders if distance from player is more than Max Warp Distance (%s).
An alternative to Easy Escort. Works better IMO so no reason to keep using Easy Escort any more, toggle is here anyway if you so prefer.
Note:
warping control from this MWSE-Lua mod does not override warping control from the companion vanilla script if present, they coexist, so results may vary.
]],
			defaultConfig.autoWarp, optionList[defaultConfig.autoWarp + 1], config.warpDistance),
		variable = createConfigVariable('autoWarp')
	})

	controls:createDropdown({
		label = 'Automatic Levitate when warping:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
Selected actors levitate like player when warping.]], 'warpLevitate'),
		variable = createConfigVariable('warpLevitate'),
	})

	controls:createDropdown({
		label = 'Automatic Water Walk when warping:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
Selected actors water walk like player when warping.]], 'warpWaterWalk'),
		variable = createConfigVariable('warpWaterWalk'),
	})

	controls:createSlider({
		label = 'Max Warp Distance',
		description = getDescription([[Default: %s game units.
Maximum distance before triggering warp to player]], 'warpDistance'),
		variable = createConfigVariable('warpDistance')
		,min = 512, max = 7200, step = 1, jump = 5
	})

	controls:createYesNoButton({
		label = 'Warp fighting companions',
		description = getYesNoDescription([[Default: %s.
When warping is enabled, this option should make them warp to player even during fights.
You can enable this if you want to avoid companions chasing enemies too far, or if they are in a big danger.]],
		'warpFightingCompanions'),
		variable = createConfigVariable('warpFightingCompanions')
	})

	controls:createYesNoButton({
		label = 'Automove followers on cell change',
		description = getYesNoDescription([[Default: %s.
Automove any followers around the player e.g. after using loading doors, after warping to a different cell so they overlap less with the player.]], 'autoMoveCC'),
		variable = createConfigVariable('autoMoveCC')
	})

	optionList = {'No', 'Yes, Only followers', 'Yes, Any actor'}
	controls:createDropdown({
		label = 'When Automove is enabled, skip Attack/Hello voices on cell change:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
Briefly disable Attack/Hello voices on cell change. Especially useful when you recall to crowded taverns. More noticeable if you play with subtitles enabled.]], 'muteCC'),
		variable = createConfigVariable('muteCC')
	})

	controls:createYesNoButton({
		label = 'Tweak followers AI Scan Interval',
		description = getYesNoDescription([[Default: %s.
Toggle to enable/disable followers AI Scan Interval tweaking below.]], 'scanIntervalTweak'),
		variable = createConfigVariable('scanIntervalTweak')
	})

	scanIntervalSlider = controls:createSlider({
		label = 'Min followers AI Scan Interval',
		description = getDescription([[Default: %s sec.
Minimum AI Scan Interval for followers. Lower should make followers more reactive but could be CPU intensive.
Increase it in case of problems.
Effective only when "Tweak followers AI Scan Interval" option is enabled.
Note: the real minimum scan interval used by the game seems to be AI Scan Interval + 1 so ebe at 0 setting actors will often still take half a second on average to react.
]], 'scanInterval'),
		variable = createConfigVariable('scanInterval')
		,min = 0, max = maxScanInterval, step = 0.1, jump = 1
	})

	optionList = {'Minimum', 'Low', 'Medium', 'High', 'Higher', 'Max'}
	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	controls:createYesNoButton({
		label = 'Ignore mannequin attacks',
		description = getYesNoDescription([[Default: %s.
Ignore attacks from creatures/npcs emulating mannequins/targets/practice dummies.
This way player followers should not attack them any more.]], 'ignoreMannequinAttacks'),
		variable = createConfigVariable('ignoreMannequinAttacks')
	})

	controls:createYesNoButton({
		label = 'Auto burden followers on combat',
		description = getYesNoDescription([[Default: %s.
Autoburden non-companion followers on combat start, so they are not running after enemies.
N.B.:
- it does not work when you set "Auto attack enemies" option to "2. Yes, Any follower".
- it can make escort mission too easy.]], 'autoBurden'),
		variable = createConfigVariable('autoBurden')
	})

	controls:createYesNoButton({
		label = 'Allow Companions to use Probes',
		description = getYesNoDescription([[Default: %s.
When enabled, companion NPCs are allowed to use their stats,
skill and probes to try and disarm traps on the target you Alt + activate.
Probes with no uses left should be automatically dropped.]], 'allowProbes'),
		variable = createConfigVariable('allowProbes')
	})

	controls:createYesNoButton({
		label = 'Allow Companions to use Lockpicks',
		description = getYesNoDescription([[Default: %s.
When enabled, companion NPCs are allowed to use their stats, skill and lockpicks
to try and open the target you Alt + activate.
lockpicks with no uses left should be automatically dropped.]], 'allowLockpicks'),
		variable = createConfigVariable('allowLockpicks')
	})

	controls:createYesNoButton({
		label = 'Allow Companions to use Open spells',
		description = getYesNoDescription([[Default: %s.
When enabled, companion NPCs are allowed to use their stats, skill and spells
to try and open the target you Alt + activate.]], 'allowMagic'),
		variable = createConfigVariable('allowMagic')
	})

	controls:createYesNoButton({
		label = 'Followers 0 Alarm',
		description = getYesNoDescription([[Default: %s.
When enabled, followers are given 0 alarm on activate if not already having it.
Useful to avoid annoying "Thief!" messages.]], 'fixAlarm'),
		variable = createConfigVariable('fixAlarm')
	})
	controls:createYesNoButton({
		label = 'Followers constant enchantment items fix',
		description = getYesNoDescription([[Default: %s.
When enabled, followers will unequip/reequip constant enchantment items on cell change, hopefully fixing constant enchantment effects overflow bug.]], 'fixConstEnch'),
		variable = createConfigVariable('fixConstEnch')
	})
	controls:createYesNoButton({
		label = 'Follower NPCs Water Breathing',
		description = getYesNoDescription([[Default: %s.
When enabled, follower NPCs are given water breathing on activate if not already having it.
Useful to avoid them getting drowned.]], 'fixWaterBreathing'),
		variable = createConfigVariable('fixWaterBreathing')
	})
	controls:createYesNoButton({
		label = 'Follower NPCs High Acrobatics',
		description = getYesNoDescription([[Default: %s.
When enabled, follower NPCs are given high acrobatics on activate if not already having it.
Useful to avoid them getting damaged on jumping or teleporting.]], 'fixAcrobatics'),
		variable = createConfigVariable('fixAcrobatics')
	})
	controls:createYesNoButton({
		label = 'Follower NPCs High Athletics',
		description = getYesNoDescription([[Default: %s.
When enabled, follower NPCs are given high athletics on activate if not already having it.
Useful to better adapt follower animation speed to player speed.]], 'fixAthletics'),
		variable = createConfigVariable('fixAthletics')
	})
	controls:createYesNoButton({
		label = 'Followers clamp levitate',
		description = getYesNoDescription([[Default: %s.
When enabled, followers constant levitate abilities/curses are clamped to min/max value = 5.
This should help avoiding possible levitate overflow to negative value on cell changes.]], 'clampLevitate'),
		variable = createConfigVariable('clampLevitate')
	})

	controls:createYesNoButton({
		label = 'Skip follower activation while sneaking/unconscious',
		description = getYesNoDescription([[Default: %s.
When enabled, you will not be able to activate a follower while you are sneaking or while the follower is unconscious,
avoiding the risk to trigger a pickpocket attempt crime reaction.]], 'skipActivatingFollowerWhileSneaking'),
		variable = createConfigVariable('skipActivatingFollowerWhileSneaking')
	})

	controls:createYesNoButton({
		label = 'Fix follower transparency on activate',
		description = getYesNoDescription([[Default: %s.
When enabled, try and fix follower transparency on activate.
You can try it if a follower keeps staying transparent without apparent reason.]], 'transparencyFixOnActivate'),
		variable = createConfigVariable('transparencyFixOnActivate')
	})
	controls:createYesNoButton({
		label = 'Looping actor animations fix',
		description = getYesNoDescription([[Default: %s.
When enabled, try and fix improperly looping actor animations.]], 'fixAnim'),
		variable = createConfigVariable('fixAnim')
	})

	controls:createButton({
		---label = 'Emergency stop travelling',
		buttonText = "Emergency stop travelling",
		description = "Force travelling stop in case something goes wrong and followers get stuck in travelling position.",
		inGameOnly = true, -- important as player variable may not be initialized yet
		callback = L.travelStop
	})

	mwse.mcm.register(template)

	---logConfig(config, {indent = false})

end
event.register('modConfigReady', L.modConfigReady)


event.register('initialized', function ()
	worldController = tes3.worldController
	inputController = worldController.inputController
	improvedAnimationSupport = tes3.hasCodePatchFeature(improvedAnimationSupportId)

	local function createSpell(spellId, spellName, spellEffects)
		return tes3.createObject({objectType = tes3.objectType.spell,
			id = spellId,
			name = spellName,
			---castType = tes3.spellType.curse, -- curses should be less sticky but nope
			castType = tes3.spellType.ability,
			alwaysSucceeds = true,
			sourceLess = true,
			effects = spellEffects,
			modified = true, -- we want to store it if possible
		})
	end

	-- low levitate speed else it may overflow
	levitateSpell = createSpell('ab01smcompLevitate', 'Warping',
		{{id = tes3_effect_levitate, min = 5, max = 5}})

	waterWalkSpell = createSpell('ab01smcompWaterwalking', 'Water Walking',
		{{id = tes3.effect.waterWalking, min = 1, max = 1}})
		burdenSpell = createSpell('ab01smcompBurdened', 'Still',
		{{id = tes3.effect.burden, min = 2000000000, max = 2000000000}})

	ab01ssDestGlob = tes3.findGlobal('ab01ssDest')
	ab01boDestGlob = tes3.findGlobal('ab01boDest')
	ab01goDestGlob = tes3.findGlobal('ab01goDest')
	ab01goAngleGlob = tes3.findGlobal('ab01goAngle')
	ab01compMountedGlob = tes3.findGlobal('ab01compMounted')

	NPCVoiceDistanceGlob = tes3.findGlobal('NPCVoiceDistance')

	persContObj = tes3.createObject({
	  objectType = tes3.objectType.container,
	  id = persContId,
	  name = '',
	  ---mesh = 'o\\contain_com_sack_02.nif',
	  mesh = 'EditorMarker.NIF',
	  capacity = 999999999999999999,
	  persistent = true,
	  modified = true, -- we want to store it if possible
	})
	---assert(persContObj)

	L.initScenicTravelAvailable()

	event.register('loaded', L.loaded)
end, {doOnce = true})


--[[ some security info
x = 0.2 * pcAgility + 0.1 * pcLuck + securitySkill
x *= pickQuality * fatigueTerm
x += fPickLockMult * lockStrength

if x <= 0: fail and report impossible
roll 100, if roll <= x then open lock else report failure

356
On probing a trap
x = 0.2 * pcAgility + 0.1 * pcLuck + securitySkill
x += fTrapCostMult * trapSpellPoints
x *= probeQuality * fatigueTerm

if x <= 0: fail and report impossible
roll 100, if roll <= x then untrap else report failure
]]
