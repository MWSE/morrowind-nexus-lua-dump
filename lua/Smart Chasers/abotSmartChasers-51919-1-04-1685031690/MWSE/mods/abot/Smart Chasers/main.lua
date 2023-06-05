---@diagnostic disable: deprecated
--[[
Hostiles following through loading doors /abot
]]

-- begin configurable parameters
local defaultConfig = {
minDelay = 3, -- Min. sec delay before chasing player through doors (try and give player enough time to lock the exterior door)
delayDivider = 80, -- Delay divider. Delay before chasing player through doors = (distanceFromPlayerAtCOmbatStart / delayDivider) + minDelay
chaseEndMessage = true, -- Allow in game messages when relevant chasers actions happen
chaseStartMessage = false,
doorUnlockedMessage = false,
chaseLevel = 4, -- 0 = disabled, 1 = only if they see player using the door, 2 = only if they detect player, 3 = only if they are in AI distance range, 4 = always in maxDistance
chaseMaxHours = 24, -- max chase duration (hours)
chaseMaxDistance = 24576, -- max chase distance
followerMaxPlayerDistance = 3072, -- max distance from player of a player follower to be possibly chased
checkEnemySize = true, -- only enemies small enough will follow through doors
checkHandy = true, -- only handy creatures will follow through doors
vampireChase = false, -- vampires may chase player outside at daytime
fixMissingVampireSpells = true, -- fix vampires abilities if missing
--- nope does not work sunDamageKillingTime = 40, -- average number of seconds needed for Sun Damage to kill a (non player) vampire. 0 = vanilla
undeadChase = false, -- undead guarding tombs may chase player outside
useLockpicks = true, -- enemy may unlock doors by lockpicks and thieving skills
useMagic = true, -- enemy may unlock doors using spells and magic skills
checkMagicka = false, -- enemy magicka will influence enemy chance to successfully cast open spells
useEnchantment = true, -- enemy may unlock doors using enchanted objects
useBash = true, -- strong enemy may bash locks
minBashingStrength = 90, -- minimum strength needed to bash a door
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High, 4 = Max
-- MCM black/white lists are too slow, not using them for now
---blacklist = {}, -- blacklisted plugins/NPCs/Creatures
---whitelist = {}, -- whitelisted NPCs/Creatures
}
-- end configurable parameters


local author = 'abot'
local modName = 'Smart Chasers'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

--[[local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end]]

local config = mwse.loadConfig(configName, defaultConfig)
---assert(config)

 -- set/updated in modConfigReady()
local logLevel = config.logLevel
local fixMissingVampireSpells = config.fixMissingVampireSpells
---local sunDamageKillingTime = config.sunDamageKillingTime
local chaseLevel = config.chaseLevel
local chaseMaxDistance = config.chaseMaxDistance
local followerMaxPlayerDistance = config.followerMaxPlayerDistance

-- set in loaded()
local worldController, processManager
local unlockSound, bashSound, spellSound
local player, mobilePlayer
local tes3gmst_fPickLockMult

local function updateConfig() -- used in modConfigReady template.onClose
	logLevel = config.logLevel
	fixMissingVampireSpells = config.fixMissingVampireSpells
	---sunDamageKillingTime = config.sunDamageKillingTime
	chaseLevel = config.chaseLevel
	if chaseLevel >= 4 then
		chaseMaxDistance = config.chaseMaxDistance
	else
		chaseMaxDistance = processManager.aiDistance
	end
end

local enemies = {} -- enemies[string.lower(enemyRef.id)] true = in combat, nil = dead or deleted
local doPack = false

local function packEnemies()
	doPack = true
	local t = {}
	for k, v in pairs(enemies) do
		if v then
			t[k] = v
			enemies[k] = nil
		end
	end
	enemies = t
	doPack = false
end

--[[
 chasers table will be saved in game in player.data
 cellId = identifier of enemy original starting cell if interior e.g. "Ilunibi, Carcass of the Saint", "" if exterior
 pos = original enemy position, rounded to integer coordinates e.g. {x = -100, y = 2345678, z = -201}
 hours = stored initial hoursPassed (24 * DaysPassed + GameHour) when chasing through door started
 e.g. chasers[lcEnemyRefId] = {cellId = cid, pos = startPos, hours = getInGameHoursPassedFromGameStart()}
 ]]
local chasers = {} -- chasers[string.lower(enemyRef.id)]


--[[local function isBlacklisted(lcObjId, sourceMod, blacklist, funcPrefix)
	if blacklist[lcObjId] then
		if logLevel > 1 then
			mwse.log('%s: enemy "%s" is blacklisted, skip', funcPrefix, lcObjId)
		end
		return true
	end
	if sourceMod then
		if blacklist[string.lower(sourceMod)] then
			if logLevel > 1 then
				mwse.log('%s: enemy "%s" comes from blacklisted mod "%s", skip', funcPrefix, lcObjId, sourceMod)
			end
			return true
		end
	end
	return false
end

local function isWhitelisted(lcObjId, whitelist, funcPrefix)
	if whitelist[lcObjId] then
		if logLevel > 1 then
			mwse.log('%s: enemy "%s" is whitelisted, add', funcPrefix, lcObjId)
		end
		return true
	end
	return false
end

local function packAndRemoveBlacklistedEnemies()
	--- local blacklist = config.blacklist
	--- local sourceMod, lcObjId
	local obj, enemyRef
	local funcPrefix = string.format("%s packAndRemoveBlacklistedEnemies()", modPrefix)
	local t = {}
	for lcEnemyRefId, value in pairs(enemies) do
		if value then
			enemyRef = tes3.getReference(lcEnemyRefId)
			if enemyRef then
				obj = enemyRef.object
			else
				obj = tes3.getObject(lcEnemyRefId)
			end
			if not obj then
				if logLevel > 0 then
					mwse.log('%s: WARNING tes3.getObject("%s") failed', funcPrefix, lcEnemyRefId)
				end
			---else
				---lcObjId = string.lower(obj.id)
				---sourceMod = obj.sourceMod
			end
			---if not isBlacklisted(lcObjId, sourceMod, blacklist, funcPrefix) then
			t[lcEnemyRefId] = value
			---end
		end
	end
	enemies = t
end
]]

local tes3_actorType_creature = tes3.actorType.creature
local tes3_actorType_npc = tes3.actorType.npc

local tes3_creatureType_normal = tes3.creatureType.normal
local tes3_creatureType_undead = tes3.creatureType.undead
--[[local tes3_creatureType_daedra = tes3.creatureType.daedra
local tes3_creatureType_humanoid = tes3.creatureType.humanoid]]


local combatWhitelist = {'centurion','draugr','fabricant_hulking','frost_giant','goblin','guar',
'ice_troll','imperfect','spriggan','vivec_god','yagrum bagarn'}
local combatBlacklist = {'bat','wolf_bone','wolf_skeleton','hircine_spd','hircine_str'}

local function canPassThroughDoor(mobile, doorRef)
	local mobRef = mobile.reference
	local mobBounds = mobRef.object.boundingBox
	if not mobBounds then
		if logLevel > 1 then
			mwse.log('%s: canPassThroughDoor() mobile "%s" has no boundingBox, returning true', modPrefix, mobRef.id)
		end
		return true
	end
	local doorBounds = doorRef.object.boundingBox
	if not doorBounds then
		-- loading doors may be one-facing and have no boundingBox
		--- mwse.log('door "%s" has no boundingBox', doorRef.id)
		return true
	end

	local doorScale = doorRef.scale
	local mobScale = mobRef.scale * 0.8 -- assuming they can squeeze/bend a little
	local doorHeight = (doorBounds.max.z - doorBounds.min.z) * doorScale
	local mobHeight = (mobBounds.max.z - mobBounds.min.z) * mobScale
	if mobHeight > doorHeight then
		if logLevel > 1 then
			mwse.log('%s: mob height Z = %s > door height = %s', modPrefix, mobHeight, doorHeight)
		end
		return false
	end
	local doorWidth = doorBounds.max.y - doorBounds.min.y
	local doorWidth2 = doorBounds.max.x - doorBounds.min.x
	if doorWidth2 > doorWidth then
		doorWidth = doorWidth2
	end
	doorWidth = doorWidth * doorScale
	local mobWidth = (mobBounds.max.x - mobBounds.min.x) * mobScale
	if mobWidth > doorWidth then
		if logLevel > 1 then
			mwse.log('%s: mob width = %s > door width = %s', modPrefix, mobWidth, doorWidth)
		end
		return false
	end
	return true
end

local function isVampire(actorRef)
	local head = actorRef.baseObject.head
	if head then -- in my test it could be sometimes undefined /abot
		return head.vampiric
	else
		return false
	end
end

local function getObject(id)
	local obj = tes3.getObject(id)
	if not obj then
		mwse.log('%s: getObject("%s") failed ', modPrefix, id)
	end
	return obj
end

-- set in modConfigReady
local vampireSpells
local vampireSunDamage
local vampireSpecialSpells

local function fixVampireSpells(vampMob)
	local result = nil
	if vampMob:isAffectedByObject(vampireSunDamage) then
		return result
	end
	local vampRef = vampMob.reference
	for i = 1, #vampireSpells do
		tes3.addSpell({reference = vampRef, spell = vampireSpells[i]})
		result = true
	end
	local faction = vampRef.object.faction
	local lcFactionId
	if faction then
---@diagnostic disable-next-line: undefined-field
		lcFactionId = string.split(string.lower(faction.id), '_')[2]-- e.g. 'clan berne' --> 'berne'
		if logLevel > 2 then
			mwse.log('%s: fixVampireSpells "%s" lcFactionId = %s', modPrefix, vampRef.id, lcFactionId)
		end
	else
		local script = vampMob.object.script
		if script then
---@diagnostic disable-next-line: undefined-field
			lcFactionId = string.split(string.lower(script.id), '_')[2] -- e.g. 'vampire_berne_boss' --> 'berne'
			if logLevel > 2 then
				mwse.log('%s: fixVampireSpells "%s" lcFactionId = %s', modPrefix, vampRef.id, lcFactionId)
			end
		end
	end
	if lcFactionId then
		local specialSpell = vampireSpecialSpells[lcFactionId]
		if specialSpell then
			tes3.addSpell({reference = vampRef, spell = specialSpell})
			result = true
		end
	end
	if result then
		if logLevel > 1 then
			mwse.log('%s: fixVampireSpells "%s" missing vampire spells fixed', modPrefix, vampRef.id)
		end
		return
	end
	return false
end

local lastDoorLockedId, lastDoorLockedRef

local function getCompanion(ref)
	local result
	local context = ref.context
	if context then
		result = context.companion
		if not result then
			result = context.Companion
		end
	end
	return result
end

local function getOneTimeMove(ref)
	local result
	local context = ref.context
	if context then
		result = context.oneTimeMove
		if not result then
			result = context.OneTimeMove
			if not result then
				result = context.onetimemove
			end
		end
	end
	return result
end

local tes3_animationState_dead = tes3.animationState.dead
local tes3_animationState_dying = tes3.animationState.dying

local function isDead(mobile)
	if mobile.isDead then
		return true
	end
	local health = mobile.health
	if health then
		if health.current then
			if health.current < 3 then
				if health.normalized <= 0.025 then
					if health.normalized > 0 then
						health.current = 0 -- kill when nearly dead, could be a glitch
					end
				end
				if health.current <= 0 then
					return true
				end
			end
		end
	end
	local actionData = mobile.actionData
	if not actionData then -- it may happen
		return false
	end
	local animState = actionData.animationAttackState
	if not animState then
		return false
	end
	if (animState == tes3_animationState_dead)
	or (animState == tes3_animationState_dying) then
		return true
	end
	return false
end

local function isValidMobile(mobile)
	local ref = mobile.reference
	if ref.disabled then
		return false
	end
	if ref.deleted then
		return false
	end
	if not mobile.hasFreeAction then
		return false
	end
	if isDead(mobile) then
		return false
	end
	if mobile == mobilePlayer then
		return false
	end

	if mobile.actorType == tes3_actorType_creature then -- 0 = creature
		local lcId = string.lower(ref.object.id)
		if not (lcId == 'ab01guguarpackmount') then -- this is a good one
			if string.startswith(lcId, 'ab01') then
-- ab01 prefix, probably some abot's creature having AIEscort package, skip
				return false
			end
			local creature = mobile.object -- tes3creature or tes3creatureInstance
			if creature then
				local script = creature.script
				if script then
					local lcId2 = string.lower(script.id)
					if string.startswith(lcId2, 'ab01') then -- ab01 prefix, probably some abot's creature having AIEscort package, skip
						if logLevel >= 3 then
							mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort package, skip", modPrefix, ref.id)
						end
						return false
					end
				end
			end
		end
	end
	return true
end

local tes3_aiPackage_follow = tes3.aiPackage.follow
local tes3_aiPackage_wander = tes3.aiPackage.wander
local tes3_aiPackage_escort = tes3.aiPackage.escort

local function isValidFollower(mobile)
	if not isValidMobile(mobile) then
		return false
	end
	local ref = mobile.reference

	local isCompanion = false
	local companion = getCompanion(ref)
	if companion then
		if companion == 1 then
			isCompanion = true
		end
	end

	local ai = tes3.getCurrentAIPackageId(mobile)
	if (ai == tes3_aiPackage_follow)
	or (ai == tes3_aiPackage_escort) then
		if isCompanion then
			return true
		end
		if not ref.object.isGuard then
			return true
		end
		return false
	elseif ai == tes3_aiPackage_wander then
		-- special case for wandering companions
		if isCompanion then
			local oneTimeMove = getOneTimeMove(ref)
			if oneTimeMove then
				if not (oneTimeMove == 0) then
-- assuming a companion scripted to do move-away using temporary aiwander
					return true
				end
			end
		end
	end

	return false
end

local function isSameCellOrExterior(cellA, cellB)
	if cellA == cellB then
		return true -- same cell
	end
	if cellA.isInterior
	or cellB.isInterior then
		return false -- different interiors/exterior
	end
	-- both exterior cells
	return true
end

local function isNotHandy(enemyMob)
	if enemyMob.actorType == tes3_actorType_creature then
		local crea = enemyMob.object
		if not crea.biped then
			if not crea.usesEquipment then
				if crea.type == tes3_creatureType_normal then
					local funcPrefix = string.format("%s isNotHandy()", modPrefix)
					local enemyRef = enemyMob.reference
					local enemyRefId = enemyRef.id
					local lcObjId = string.lower(enemyRef.object.id)
					if config.checkHandy then
						if logLevel > 2 then
							mwse.log('%s: not handy enemy creature "%s", skip', funcPrefix, enemyRefId)
						end
						return true
---@diagnostic disable-next-line: undefined-field
					elseif string.multifind(lcObjId, combatBlacklist, 1, true) then
						if logLevel > 2 then
							mwse.log('%s: enemy creature "%s" blacklisted, skip', funcPrefix, enemyRefId)
						end
						return true
---@diagnostic disable-next-line: undefined-field
					elseif not string.multifind(lcObjId, combatWhitelist, 1, true) then
						if logLevel > 3 then
							mwse.log('%s: not handy enemy creature "%s" not whitelisted, skip', funcPrefix, enemyRefId)
						end
						return true
					end
				end
			end
		end
	end
	return false
end

local function enemyTooBig(enemyMob, doorRef)
	if config.checkEnemySize
	and (not canPassThroughDoor(enemyMob, doorRef)) then
		if logLevel > 2 then
			local funcPrefix = string.format("%s isNotHandy()", modPrefix)
			local enemyRefId = enemyMob.reference.id
			mwse.log('%s: enemy "%s" is too big to pass through "%s", skip', funcPrefix, enemyRefId, doorRef.id)
		end
		return true
	end
	return false
end

-- combatStarted target alone is not reliable they may attack fireflies first instead of player
local function combatStarted(e)
	local enemyMob = e.actor
	if not enemyMob then
		return
	end
	if not mobilePlayer then
		return -- better safe than sorry
	end
	if enemyMob == mobilePlayer then
		return
	end

	local funcPrefix = string.format("%s combatStarted()", modPrefix)
	local enemyRef = enemyMob.reference
	local enemyRefId = enemyRef.id

	if not enemyMob.hasFreeAction then -- note docs are wrong this is not a function
		-- dead or paralyzed or stunned or otherwise unable to take action
		if logLevel > 1 then
			mwse.log('%s: enemy "%s" has no free action, skip', funcPrefix, enemyRefId)
		end
		return
	end

	--[[if isBlacklisted(lcObjId, enemyObj.sourceMod, config.blacklist, funcPrefix) then
		return
	end]]

	if isNotHandy(enemyMob) then
		return
	end

	local companion = getCompanion(enemyRef)
	if companion == 1 then
		if logLevel > 3 then
			mwse.log('%s: enemy "%s" is a companion probably using startcombat to reset the AI, skip', funcPrefix, enemyRefId)
		end
		return
	end

	local mobileTarget = e.target
	if not (mobileTarget == mobilePlayer) then
		local skip = true
		local playerPos = player.position
		local playerCell = player.cell
		local mobRef, mob
		local friendlyActors = mobilePlayer.friendlyActors
		for i = 1, #friendlyActors do
			mob = friendlyActors[i]
			if mob == mobileTarget then
				mobRef = mob.reference
				if isSameCellOrExterior(mobRef.cell, playerCell) then
					if mobRef.position:distance(playerPos) < followerMaxPlayerDistance then
						if isValidFollower(mob) then
							skip = false
							break
						end
					end
				end
			end
		end
		if skip then
			return
		end
	end

	-- target is player or nearby player follower from here
	if logLevel > 2 then
		mwse.log('%s: e.actor = %s, e.target = %s', funcPrefix, enemyMob.reference.id, mobileTarget.reference.id)
	end

	if lastDoorLockedId then
		if lastDoorLockedRef then

			if enemyTooBig(enemyMob, lastDoorLockedRef) then
				return
			end

			local enemyCell = enemyRef.cell
			local lastDoorLockedCell = lastDoorLockedRef.cell
			local lastDoorLockedPos = lastDoorLockedRef.position
			local destination = lastDoorLockedRef.destination
			local d

			if isSameCellOrExterior(lastDoorLockedCell, player.cell) then
				d = lastDoorLockedPos:distance(player.position)
				if d > chaseMaxDistance then
					if logLevel > 3 then
						mwse.log('%s: player distance from last locked door > %s, skip', funcPrefix, chaseMaxDistance)
					end
					return
				end

				if destination then
					local marker = destination.marker
					if marker then
						if isSameCellOrExterior(marker.cell, enemyCell) then
							d = marker.position:distance(enemyRef.position)
							if d > chaseMaxDistance then
								if logLevel > 3 then
									mwse.log('%s: enemy "%s" distance from last locked door destination > %s, skip', funcPrefix, enemyRefId, chaseMaxDistance)
								end
								return
							end
						end
					end
				else
					if isSameCellOrExterior(lastDoorLockedCell, enemyCell) then
						d = lastDoorLockedPos:distance(enemyRef.position)
						if d > chaseMaxDistance then
							if logLevel > 3 then
								mwse.log('%s: last not loading door locked, enemy and player in same cell, but enemy "%s" distance from door > %s, skip', funcPrefix, enemyRefId, chaseMaxDistance)
							end
							return
						end -- if isSameCellOrExterior(lastDoorLockedCell, enemyCell)
					end
				end -- if destination

			end	-- if isSameCellOrExterior(lastDoorLockedCell, player.cell)

		end -- if lastDoorLockedRef
	end -- if lastDoorLockedId

	if fixMissingVampireSpells then
		if isVampire(enemyRef) then
			fixVampireSpells(enemyMob)
		end
	end
 -- in combat. player activate event on a door will call checkDoorChasers(doorRef) that will use enemies
	local lcEnemyRefId = string.lower(enemyRefId)
	if logLevel > 3 then
		mwse.log('%s: enemies["%s"] = true', funcPrefix, lcEnemyRefId)
	end
	enemies[lcEnemyRefId] = true

end



local function death(e)
	local lcEnemyRefId = string.lower(e.reference.id)
	if enemies[lcEnemyRefId] then
		enemies[lcEnemyRefId] = nil -- dead or deleted
		doPack = true
	end
end

local function isDayTime()
	local gameHour = worldController.hour.value
	local wec = worldController.weatherController
	local sunrise = wec.sunriseHour + wec.sunriseDuration
	local sunset = wec.sunsetHour + wec.sunsetDuration
	return (gameHour >= sunrise) and (gameHour <= sunset)
end

local function getInGameHoursPassedFromGameStart()
	local daysPassed = worldController.daysPassed.value
	local gameHour = worldController.hour.value
	return math.floor((daysPassed * 24) + gameHour + 0.5)
end

local tes3_objectType_lockpick = tes3.objectType.lockpick

local function getLockpick(actorRef)
	local stackObj, iData, condition
	local funcPrefix = string.format("%s getLockpick()", modPrefix)
	local found = false
	local inventory = actorRef.object.inventory
	local items = inventory.items
	local stack
	--- for _, stack in pairs(inventory) do -- inventory needs pairs!
	for i = 1, #items do
		stack = items[i]
		stackObj = stack.object
		if stackObj then
			if stackObj.objectType == tes3_objectType_lockpick then
				iData = stack.itemData
				if iData then
					condition = iData.condition
					if condition then
						if condition > 0 then
							condition = condition - 1
							stack.itemData.condition = condition -- decrease item condition as it would be be used
							found = true
							break
						else
							---mwscript.removeItem({reference = actorRef, item = stackObj, count = 1}) -- removes item with 0 uses left
							tes3.removeItem({reference = actorRef, item = stackObj, count = 1, updateGUI = false})
							return getLockpick(actorRef) -- look for another one
						end
					end
				else -- it is an unused one
					found = true
					break
				end
			end
		end
	end
	if found then
		if logLevel > 1 then
			mwse.log('%s: enemy "%s" using lockpick "%s"', funcPrefix, actorRef.id, stackObj.id)
		end
		return stackObj
	end
	return nil
end

local tes3_effect_open = tes3.effect.open
local tes3_effect_lock = tes3.effect.lock

local function getOpenSpell(actorRef, lockLevel)
	local spells = actorRef.object.spells
	if not spells then
		return nil, nil, nil
	end
	local t = {}
	local effectIndex, effect, mag, cha
	local found = false
	local funcPrefix = string.format("%s getOpenSpell()", modPrefix)
	for _, spl in pairs(spells) do
		---mwse.log("spl = %s", spl.id)
		if spl.isActiveCast or spl.alwaysSucceeds then
			effectIndex = spl:getFirstIndexOfEffect(tes3_effect_open)
			if effectIndex then
				if effectIndex >= 0 then -- returns -1 if not found
					---mwse.log("effectIndex = %s", effectIndex)
					effectIndex = effectIndex + 1
					effect = spl.effects[effectIndex]
					mag = math.floor((effect.min + effect.max) / 2)
					if spl.alwaysSucceeds then
						cha = 100
					elseif effect.cost > 0 then
						cha = spl:calculateCastChance({checkMagicka = config.checkMagicka, caster = actorRef})
					else
						cha = 100
					end
					if logLevel > 1 then
						mwse.log('%s: enemy "%s" spell "%s" magnitude = %s, chance = %s', funcPrefix, actorRef.id, spl.id, mag, cha)
					end
					if mag >= lockLevel then
						if cha >= 33 then
							table.insert(t, {spell = spl, magnitude = mag, chance = cha, mXc = mag * cha})
							found = true
						end
					end
				end
			end
		end
	end

	if found then
		table.sort(t, function(a,b) return a.mXc > b.mXc end) -- sort by descending magnitude * chance
		local t1 = t[1]
		local spell = t1.spell
		if logLevel > 1 then
			mwse.log('%s: enemy "%s" using spell "%s" ("%s")', funcPrefix, actorRef.id, spell.id, spell.name)
		end
		return spell, t1.magnitude, t1.chance
	end
	return nil, nil, nil
end

local tes3_enchantmentType_onUse = tes3.enchantmentType.onUse
local tes3_enchantmentType_castOnce = tes3.enchantmentType.castOnce

local function getOpenEnchantedItem(actorRef)
	local object, enchantment, castType, castOnce, effectIndex, effect, magnitude
	local inventory = actorRef.object.inventory

	local items = inventory.items
	local stack
	--- for _, stack in pairs(inventory) do -- inventory needs pairs!
	for i = 1, #items do
		stack = items[i]
		object = stack.object
		enchantment = object.enchantment
		if enchantment then
			effectIndex = enchantment:getFirstIndexOfEffect(tes3_effect_open) -- tes3_effect_open = 13
			if effectIndex then
				if effectIndex >= 0 then
					effectIndex = effectIndex + 1
					castType = enchantment.castType
					castOnce = (castType == tes3_enchantmentType_castOnce)
					if castOnce
					or (
						(castType == tes3_enchantmentType_onUse)
						and (stack.variables.charge >= enchantment.chargeCost)
					) then
						effect = enchantment.effects[effectIndex]
						magnitude = math.floor((effect.min + effect.max) / 2)
						if logLevel > 1 then
							mwse.log('%s getOpenEnchantedItem(): enemy "%s" using "%s" enchanted item', modPrefix, actorRef.id, object.id)
						end
						return object, magnitude, castOnce
					end
				end
			end
		end
	end
	return nil, 0, false
end

local function getCloseSound(obj)
	local closeSound = obj.closeSound
	if not closeSound then
		local openSound = obj.openSound
		if openSound then
			local s = openSound.id
			if s then
				s = string.gsub(s, '[Oo][Pp][En][Nn]', 'Close') -- replace 'Open' with 'Close', case insensitive
				closeSound = tes3.getSound(s) -- getObject does not work with sounds
				if not closeSound then
					s = 'Door Heavy Close'
					closeSound = tes3.getSound(s)
				end
			end
		end
	end
	return closeSound
end

local function playRefSound(ref, snd)
	local dist = ref.position:distance(player.position)
	local vol = math.max(1/(dist/3583 + 1), 0.4)
	tes3.playSound({sound = snd, volume = vol})
end

local function playDoorCloseSound(doorRef)
	local ref = doorRef
	if doorRef.destination then
		ref = doorRef.destination.marker
	end
	local closeSound = getCloseSound(doorRef.baseObject)
	if closeSound then
		playRefSound(ref, closeSound)
	end
end

local function getGenericName(name)
	if string.find(string.lower(name),"^[aeiou]") then
		return 'an ' .. name
	else
		return 'a ' .. name
	end
end

local tes3_objectType_creature = tes3.objectType.creature

local function getActorName(obj)
	if obj.baseObject then
		obj = obj.baseObject
	end
	local name = obj.name
	if name then
		local generic = false
		local cloneCount = obj.cloneCount
		if cloneCount then
			if cloneCount > 1 then
				generic = true
			end
		end
		if not generic then
			if obj.objectType == tes3_objectType_creature then
				generic = true
			end
		end
		if generic then
			name = getGenericName(name)
		end
	end
	return name
end

local function getActorRefName(ref)
	local name = ref.object.name
	local generic = true
	local companion = getCompanion(ref)
	if companion then
		if companion == 1 then
			generic = false
		end
	end
	if generic then
		if not (ref.object.objectType == tes3_objectType_creature) then
			local cloneCount = ref.baseObject.cloneCount
			if cloneCount < 2 then
				generic = false
			end
		end
	end
	if generic then
		name = getGenericName(name)
	end
	return name
end

local tes3_objectType_door = tes3.objectType.door

local function linkedDoors(doorRef, linkedDoorRef)
	if not doorRef then
		return false
	end
	if not linkedDoorRef then
		return false
	end
	local dest = doorRef.destination
	if not dest then
		return false
	end
	local marker = dest.marker
	if not (marker.cell == linkedDoorRef.cell) then
		return false
	end
	local markerPos = marker.position
	local linkedDoorPos = linkedDoorRef.position
	local d = markerPos:distance(linkedDoorPos)
	local funcPrefix = string.format("%s linkedDoors()", modPrefix)
	if d > 350 then
		if logLevel > 1 then
			mwse.log('%s: markerPos:distance(linkedDoorPos) > 350, not linked', funcPrefix)
		end
		return false
	end
	d = math.abs(linkedDoorPos.z - markerPos.z)
	if d > 192 then
		if logLevel > 1 then
			mwse.log('%s: math.abs(linkedDoorPos.z - markerPos.z) > 192, not linked', funcPrefix)
		end
		return false
	end
	return true
end

local function linkedDoorsSync(doorRef, linkedDoorRef)
	if not linkedDoors(doorRef, linkedDoorRef) then
		return false
	end
	local locked = tes3.getLocked({reference = doorRef})
	local data = linkedDoorRef.data
	if data	then
		local ab01locked = data.ab01locked
		if locked == ab01locked then
			return false -- linkedDoorRef already locked/unlocked by abotLoadingDoors mod
		end
	end
	local linkedLocked = tes3.getLocked({reference = linkedDoorRef})

	local function logMessage()
		local action
		if locked then
			action = 'locking'
		else
			action = 'unlocking'
		end
		mwse.log('%s linkedDoorsSync(): %s "%s" like linked "%s"', modPrefix, action, linkedDoorRef.id, doorRef.id)
	end

	if doorRef.lockNode then
		if not linkedDoorRef.lockNode then
			tes3.lock({reference = linkedDoorRef}) -- lock to create the lock node if not already present
			timer.start({type = timer.real, duration = 0.4, callback =
				function ()
					linkedDoorRef.lockLevel = doorRef.lockLevel
					if logLevel > 1 then
						logMessage()
					end
					if not locked then
						tes3.unlock({reference = linkedDoorRef})
					end
				end
			})
			return true
		end
	end
	if locked == linkedLocked then
		return false
	end
	if logLevel > 1 then
		logMessage()
	end
	if locked then
		tes3.lock({reference = linkedDoorRef})
	else
		tes3.unlock({reference = linkedDoorRef})
	end
	return true
end

local function unlockIfLocked(doorRef, linkedDoorRef)
	local lockNode = doorRef.lockNode
	if lockNode then
		if lockNode.locked then
			if lockNode.level > 0 then
				tes3.unlock({reference = doorRef})
				if linkedDoorRef then
					timer.start({type = timer.real, duration = 0.4, callback =
						function ()
							linkedDoorsSync(doorRef, linkedDoorRef)
						end
					})
				end
				return true
			end
		end
	end
	return false
end

local math_pi = math.pi
local half_pi = math_pi * 0.5

local function observerCanSeeTargetAtDistance(observerRef, targetRef, distance)
	if not isSameCellOrExterior(observerRef.cell, targetRef.cell) then
		return false
	end
	if distance > 8192 then -- at this distance no creature is visible
		return false
	end
	local radAngleTo = observerRef:getAngleTo(targetRef) -- 0 <= getAngleTo <= math.pi
	radAngleTo = math.abs(radAngleTo) -- not needed it seems but...
	if radAngleTo < half_pi then
		if tes3.testLineOfSight({reference1 = observerRef, reference2 = targetRef}) then
			return true
		end
	 end
	return false
end

local function playerCanSeeEnemyAtDistance(enemyRef, distance)
	return observerCanSeeTargetAtDistance(player, enemyRef, distance)
end

local function enemyCanSeePlayerAtDistance(enemyRef, distance)
	return observerCanSeeTargetAtDistance(enemyRef, player, distance)
end

local function doorCanBeOpened(doorRef, enemyMob)
	local doorDest = doorRef.destination
	if doorDest then
		local destMarker = doorDest.marker
		local destCell = destMarker.cell
		local enemyCell = enemyMob.cell
		if not (enemyCell == destCell) then
			return false
		end
	end

	local tryUnlock = false
	local lockLevel
	local lockNode = doorRef.lockNode
	if lockNode then
		if lockNode.locked then
			lockLevel = lockNode.level
			if lockLevel > 0 then
				tryUnlock = true
			else
				return false
			end
		end
	end
	if not tryUnlock then
		return true
	end

	local ok = false
	local doorSound
	local enemyRef = enemyMob.reference
	local enemyRefId = enemyRef.id
	local enemyName = getActorRefName(enemyRef)

	local doorId = doorRef.id
	local doorName = doorRef.object.name
	local funcPrefix = string.format("%s doorCanBeOpened()", modPrefix)

	if enemyMob.actorType == tes3_actorType_npc then
		local key = lockNode.key
		if key then
			if enemyRef.object.inventory:contains(key) then
				ok = true
			end
		end
		if not ok then
			if config.useLockpicks then
				local obj = getLockpick(enemyRef)
				if obj then
					local quality = obj.quality
					if not quality then
						quality = 0.25
					end
					local fPickLockMult = tes3gmst_fPickLockMult.value
					local agility = enemyMob.agility.current
					local luck = enemyMob.luck.current
					local security = enemyMob.security.current
					local x = (0.2 * agility) + (0.1 * luck) + security
					x = x * quality
					x = x + (fPickLockMult * lockLevel)
					if x > 0 then
						local roll = math.random(1, 100)
						if roll < x then
							ok = true
							if logLevel > 0 then
								mwse.log('%s: enemy "%s" managed to pick the "%s" door lock using a "%s"', funcPrefix, enemyRefId, doorId, obj.id)
							end
							if config.doorUnlockedMessage then
								tes3ui.showNotifyMenu('%s picked the %s lock', enemyName, doorName)
							end
							doorSound = unlockSound
						elseif logLevel > 0 then
							mwse.log('%s: enemy "%s" failed picking the "%s" door lock using a "%s"', funcPrefix, enemyRefId, doorId, obj.id)
						end -- if roll
					end -- if x > 0
				end -- if obj
			end -- if config.useLockpicks
		end -- if not ok
	end -- if enemyMob.actorType == tes3_actorType_npc

	if not ok then
		if config.useMagic then
			local spell, magnitude, chance = getOpenSpell(enemyRef, lockLevel)
			if spell then
				if magnitude >= lockLevel then
					local roll = math.random(1, 100)
					if roll < chance then
						ok = true
						if logLevel > 0 then
							mwse.log('%s: enemy "%s" managed to unlock door "%s" using a "%s" spell', funcPrefix, enemyRefId, doorId, spell.name)
						end
						if config.doorUnlockedMessage then
							tes3ui.showNotifyMenu('%s used a spell to unlock a %s', enemyName, doorName)
						end
						doorSound = spellSound
					elseif logLevel > 0 then
						mwse.log('%s: enemy "%s" failed unlocking door "%s" using a "%s" spell', funcPrefix, enemyRefId, doorId, spell.name)
					end -- if roll
				end -- if magnitude
			end --  if spell
		end -- if config.useMagic
	end -- if not ok

	if not ok then
		if config.useEnchantment then
			local object, magnitude, castOnce = getOpenEnchantedItem(enemyRef)
			if object then
				if magnitude >= lockLevel then
					ok = true
					if castOnce then
						mwscript.removeItem({reference = enemyRef, item = object, count = 1})
					end
					if logLevel > 0 then
						mwse.log('%s: enemy "%s" managed to unlock door "%s" using an enchanted "%s"', funcPrefix, enemyRefId, doorId, object.name)
					end
					if config.doorUnlockedMessage then
						tes3ui.showNotifyMenu('%s used an enchanteded item to unlock %s', enemyName, doorName)
					end
					doorSound = spellSound
				elseif logLevel > 0 then
					mwse.log('%s: enemy "%s" failed unlocking door "%s" using an enchanted "%s"', funcPrefix, enemyRefId, doorId, object.name)
				end -- magnitude
			end -- if object
		end -- config
	end -- if not ok

	if not ok then
		if config.useBash then
			local x = enemyMob.strength.current
			if x >= config.minBashingStrength then
				local roll = math.random(60, (lockLevel / 2) + 100)
				if roll < x then
					ok = true -- lock bash
					if logLevel > 0 then
						mwse.log('%s: enemy "%s" managed to bash door "%s"', funcPrefix, enemyRefId, doorId)
					end
					if config.doorUnlockedMessage then
						tes3ui.showNotifyMenu('%s managed to bash a %s', enemyName, doorName)
					end
					doorSound = bashSound
				elseif logLevel > 0 then
					mwse.log('%s: enemy "%s" failed bashing door "%s"', funcPrefix, enemyRefId, doorId)
				end -- if roll
			end -- if x
		end -- if config.useBash
	end

	if ok then
		if unlockIfLocked(doorRef, lastDoorLockedRef) then
			if not doorRef.destination then
				enemyRef:activate(doorRef)
			end
			if doorSound then
				playRefSound(doorRef, doorSound)
			end
		end
		timer.start({duration = 1.5, callback =
			function ()
				playDoorCloseSound(doorRef)
			end
		})
	end

	return ok

end


-- mobile.inCombat alone is not reliable /abot
local function inCombat(mobile)
	if mobile.inCombat then
		return true
	end
	if mobile.combatSession then
		return true
	end
	if mobile.actionData then
		if mobile.actionData.target then
			return true
		end
	end
	--[[if mobile.isAttackingOrCasting then
		return true
	end]]
	return false
end


local tes3_aiBehaviorState_attack = tes3.aiBehaviorState.attack
local tes3_aiBehaviorState_flee = tes3.aiBehaviorState.flee

local function sameCellOrDifferentKindOfCell(cellA, cellB)
	if cellA == cellB then
		return true -- same cell
	end
	if (not cellA.isInterior)
	and (not cellB.isInterior) then
		 -- both exterior cells
		 return true
	end
	if cellA.isInterior == cellB.isInterior then
		return false -- both interiors, but not the same cell
	end
	return true	-- interior, exterior or viceversa
end


-- mob.isPlayerDetected is not reliable enough on CellChanged
local function isPlayerDetected(mob)
	local mobRef = mob.reference
	local playerCell = player.cell
	local mobCell = mobRef.cell
	if mobCell == playerCell then
		return mob.isPlayerDetected
	end
	-- they could still be both in different named exteriors
	if not playerCell.isInterior then
		if not mobCell.isInterior then
			local dist = player.position:distance(mobRef.position)
			if dist <= 8192 then
				return mob.isPlayerDetected
			end
		end
	end
	return false
end

local function checkDoorChasers(doorRef)
-- called from the door activate event, process enemies table hopefully in the same frame before player changes cell

	local funcPrefix = string.format("%s checkDoorChasers()", modPrefix)

	if chaseLevel == 0 then
		return
	end

---@diagnostic disable-next-line: undefined-field
	if table.empty(enemies) then
		if logLevel > 2 then
			mwse.log("%s: no enemies, skip", funcPrefix)
		end
		return
	end

	doPack = true

	local doorDest = doorRef.destination

	local undeadChase = config.undeadChase
	local vampireChase = config.vampireChase

	local dayTime = isDayTime()

	local inGameHoursPassedFromGameStart = getInGameHoursPassedFromGameStart()

	local function processEnemy(lcEnemyRefId)
		local enemyRef = tes3.getReference(lcEnemyRefId)
		if not enemyRef then
			if logLevel > 1 then
				mwse.log('%s: enemy ref "%s" not found', funcPrefix, lcEnemyRefId)
			end
			return
		end
		local enemyRefId = enemyRef.id

		if logLevel > 1 then
			mwse.log('%s: checking enemy "%s"', funcPrefix, enemyRefId)
		end

		local enemyMob = enemyRef.mobile
		if not enemyMob then
			if logLevel > 1 then
				mwse.log('%s: mobile enemy "%s" not found', funcPrefix, lcEnemyRefId)
			end
			return
		end

		if not inCombat(enemyMob) then
			if logLevel > 0 then
				mwse.log('%s: enemy "%s" is not in combat any more, skip', funcPrefix, enemyRefId)
			end
			return
		end

		if not enemyMob.hasFreeAction then -- note docs are wrong this is not a function
			-- dead or paralyzed or stunned or otherwise unable to take action
			if logLevel > 0 then
				mwse.log('%s: enemy "%s" has no free action, skip', funcPrefix, enemyRefId)
			end
			return
		end

		if isDead(enemyMob) then -- better safe than sorry
			if logLevel > 0 then
				mwse.log('%s: enemy "%s" is dead, skip', funcPrefix, enemyRefId)
			end
			return
		end

		if chaseLevel <= 2 then
			if not isPlayerDetected(enemyMob) then
				if logLevel > 0 then
					mwse.log('%s: enemy "%s" cannot detect player, skip', funcPrefix, enemyRefId)
				end
				return
			end
		end

		local dist = enemyRef.position:distance(player.position)

		if chaseLevel == 1 then
			if not enemyCanSeePlayerAtDistance(enemyRef, dist) then
				if logLevel > 0 then
					mwse.log('%s: enemy "%s" cannot see player at %s distance, skip', funcPrefix, enemyRefId, dist)
				end
				return
			end
		end

		if isNotHandy(enemyMob) then
			return
		end

		if enemyTooBig(enemyMob, doorRef) then
			return
		end

		if doorDest then

			if doorDest.cell.isOrBehavesAsExterior then
				if not vampireChase then
					if dayTime then
						if enemyMob.actorType == tes3_actorType_npc then
							if isVampire(enemyRef) then
								if logLevel > 0 then
									mwse.log('%s: enemy "%s" is vampire, dayTime, skip', funcPrefix, enemyRefId)
								end
								return
							end
						end
					end
				end
				if not undeadChase then
					if enemyMob.actorType == tes3_actorType_creature then
						if enemyMob.object.type == tes3_creatureType_undead then
							if not enemyMob.cell.isOrBehavesAsExterior then
								local cellName = enemyMob.cell.id
---@diagnostic disable-next-line: undefined-field
								if string.multifind(string.lower(cellName), {'tomb','burial'}, 1, true) then
									if logLevel > 1 then
										mwse.log('%s: undead creature "%s" is not following outside "%s", skip', funcPrefix, enemyRefId, cellName)
									end
									return
								end
							end
						end
					end
				end
			end -- if doorDest.cell.isOrBehavesAsExterior

		end -- if doorDest

		if logLevel > 2 then
			mwse.log('%s: enemy "%s" distance from player = %s', funcPrefix, enemyRefId, dist)
		end

		if dist > chaseMaxDistance then
			if sameCellOrDifferentKindOfCell(enemyRef.cell, player.cell) then
				if logLevel > 1 then
					mwse.log('%s: enemy "%s" distance from player = %s > max distance = %s, skip', funcPrefix, enemyRefId, dist, chaseMaxDistance)
				end
				return
			end
		end

		if enemyMob.actionData.aiBehaviorState == tes3_aiBehaviorState_flee then
			return
		end

		-- try & follow player through door

		local function doChase()
			enemyRef = tes3.getReference(lcEnemyRefId) -- refresh it for safety
			if not enemyRef then
				if logLevel > 1 then
					mwse.log('%s callback: enemy ref "%s" not found', funcPrefix, lcEnemyRefId)
				end
				return
			end

			enemyMob = enemyRef.mobile
			if not enemyMob then
				if logLevel > 1 then
					mwse.log('%s callback: mobile enemy "%s" not found', funcPrefix, lcEnemyRefId)
				end
				return
			end
			local actorType = enemyMob.actorType
			if not actorType then
				if logLevel > 1 then
					mwse.log('%s callback: mobile enemy actor "%s" not found', funcPrefix, lcEnemyRefId)
				end
				return
			end

			local playerCell = player.cell
			local playerPos = player.position
			local enemyCell = enemyRef.cell
			local enemyPos = enemyRef.position

			local destMarker, destMarkerPos, d
			if doorDest then
				destMarker = doorDest.marker
				if destMarker then
					destMarkerPos = destMarker.position
				end
			end

			-- begin locked door management
			if lastDoorLockedId
			and lastDoorLockedRef then
				local lastDoorLockedCell = lastDoorLockedRef.cell
				if playerCell == lastDoorLockedCell then
					local lastDoorLockedPos = lastDoorLockedRef.position
					local check = false
					if enemyCell == lastDoorLockedCell then
						check = true
					elseif linkedDoors(doorRef, lastDoorLockedRef) then
						check = true
					end
					if check then
						d = lastDoorLockedPos:distance(playerPos)
						if d > chaseMaxDistance then
							if logLevel > 1 then
								mwse.log('%s callback: lastDoorLockedPos:distance(player.position) > %s, skip', funcPrefix, chaseMaxDistance)
							end
							return
						end

						if enemyTooBig(enemyMob, lastDoorLockedRef) then
							return
						end

						if not doorCanBeOpened(lastDoorLockedRef, enemyMob) then
							if logLevel > 1 then
								mwse.log('%s callback: not doorCanBeOpened("%s", "%s"), skip', funcPrefix, lastDoorLockedRef, enemyRefId)
							end
							return
						end
					end
				end

			end
			-- end locked door management

			if not doorDest then
				if logLevel > 1 then
					mwse.log('%s callback: "%s" door "%s" has no destination, skip', funcPrefix, enemyRefId, doorRef.id)
				end
				return
			end

			if logLevel > 3 then
				mwse.log('%s callback: lastDoorLockedRef = "%s", doorDest.marker.position = "%s"', funcPrefix, lastDoorLockedRef, destMarkerPos)
			end

			local chaser = chasers[lcEnemyRefId]
			local startCellId = ''
			local startCellPos = enemyPos:copy()

			if chaser then
				if (not enemyCell.isInterior)
				and (not playerCell.isInterior) then -- both enemy and player in exterior
					d = enemyPos:distance(playerPos)
					if d > chaseMaxDistance then
						if logLevel > 1 then
							mwse.log('%s callback: enemy "%s" distance from player = %s > max distance = %s, skip', funcPrefix, enemyRefId, d, chaseMaxDistance)
						end
						return
					end
				end
			else -- chaser not yet defined
				if enemyCell.isInterior then
					-- store enemy interior cell id before moving the enemy, and only if not already stored
					startCellId = enemyCell.id
				end
			end

			local ok
			if ( enemyCell.isInterior and (not playerCell.isInterior) )
			or ( (not enemyCell.isInterior) and playerCell.isInterior ) then
				ok = true
			--[[else
				local doorDestPlayerDist = destMarkerPos:distance(playerPos)
				local enemyPlayerDist = enemyPos:distance(playerPos)
				if doorDestPlayerDist < enemyPlayerDist then
					ok = true
				else
					if logLevel > 0 then
						mwse.log('%s callback: doorDestPlayerDist = %s >= enemyPlayerDist = %s, skip',
							funcPrefix, doorDestPlayerDist, enemyPlayerDist)
					end
					return
				end]]
			end
			if ok then
				local pos = destMarkerPos:copy()
				local ori = doorDest.marker.orientation:copy()
				local doorDestCell = doorDest.cell
				local doorRefCell = doorRef.cell
				local doorDestCellEditorName = doorDestCell.editorName
				if not tes3.positionCell({reference = enemyRef, cell = doorDestCell, position = pos, orientation = ori}) then
					if logLevel > 0 then
						mwse.log('%s callback: trying tes3.positionCell({reference = "%s", startCell = "%s", destCell = "%s", position = %s, orientation = %s}) failed',
							funcPrefix, enemyRefId, doorRefCell.editorName, doorDestCellEditorName, pos, ori)
					end
					return
				end
				if logLevel > 0 then
					mwse.log('%s callback: "%s" followed player through door "%s" from cell "%s" to cell "%s"',
						funcPrefix, enemyRefId, doorRef.id, doorRefCell.id, doorDestCellEditorName)
				end
			end

			if not (enemyMob.actionData.aiBehaviorState == tes3_aiBehaviorState_attack) then
				-- enforce more rapid fight in case
---@diagnostic disable-next-line: param-type-mismatch
				enemyMob:startCombat(mobilePlayer)
				enemyMob.actionData.aiBehaviorState = tes3_aiBehaviorState_attack
			end

			if chaser then
				chaser.hours = inGameHoursPassedFromGameStart -- only update chase starting hour
			else
				-- store a new chaser
				chasers[lcEnemyRefId] = {cellId = startCellId, pos = startCellPos, hours = inGameHoursPassedFromGameStart}
			end

			enemies[lcEnemyRefId] = true

			if enemyMob.fight < 100 then
				if actorType == tes3_actorType_npc then
					if not enemyRef.object.isGuard then -- skip messing with guards
						enemyMob.fight = 100
					end
				else
					enemyMob.fight = 100
				end
			end

			if config.chaseStartMessage then
				d = destMarkerPos:distance(player.position)
				if d < 8192 then
					tes3ui.showNotifyMenu("You can hear %s chasing you!", getActorRefName(enemyRef))
				end
			end

			---updateLastDoorLocked()

		end -- doChase()

		local dur = (   dist / ( (enemyMob.speed.current + config.delayDivider) * 10 )  ) + config.minDelay

		doChase() -- no delay 1st time
		timer.start({duration = dur, iterations = 2, callback = doChase})

		if not doorDest then
			if logLevel > 1 then
				mwse.log('%s: "%s" door %s timer started duration = %s', funcPrefix, enemyRefId, doorRef.id, dur)
				end
			return
		end

		if logLevel > 1 then
			local start, dest
			local startCell = doorRef.cell
			local destCell = doorDest.cell
			if startCell.isInterior then
				start = startCell.id
			else
				start = startCell.editorName
			end
			if destCell.isInterior then
				dest = destCell.id
			else
				dest = destCell.editorName
			end
			mwse.log('%s: "%s" through door "%s" from cell "%s" to cell "%s" timer started duration = %s', funcPrefix, enemyRefId, doorRef.id, start, dest, dur)
		end

	end -- local function processEnemy


	for lcEnemyRefId, _ in pairs(enemies) do
		processEnemy(lcEnemyRefId)
	end

end


local function activate(e)
	local doorRef = e.target
	if not (doorRef.baseObject.objectType == tes3_objectType_door) then
		return
	end
	if not (e.activator == player) then
		return
	end
	if linkedDoorsSync(lastDoorLockedRef, doorRef) then
		-- if the linked door is lastDoorLockedRef, copy lock state from it
		timer.start({type = timer.real, duration = 0.55, callback =
			function ()
				event.trigger('activate', {activator = player, target = doorRef}, {filter = doorRef})
			end
		})
		return false -- wait for door to be locked/unlocked like lastDoorLockedRef before re-triggering activation
	end
	 -- else normal behavior
	if tes3.getLocked({reference = doorRef}) then
		return
	end
	checkDoorChasers(doorRef)
end


local spellTicked = false -- also reset in loaded()
local function spellTick(e)
	if not (e.caster == player) then
		return
	end
	local effectId = e.effectId
	if not (effectId == tes3_effect_open) then
		if not (effectId == tes3_effect_lock) then
			return
		end
	end
	if spellTicked then
		return
	end
	local doorRef = e.target
	if not (doorRef.baseObject.objectType == tes3_objectType_door) then
		return
	end
	spellTicked = true
	if effectId == tes3_effect_lock then
		lastDoorLockedRef = doorRef
		lastDoorLockedId = string.lower(lastDoorLockedRef.id)
	else -- unlocked, synchronize linked door if it is lastDoorLockedRef
		linkedDoorsSync(doorRef, lastDoorLockedRef)
	end
end


local function casted(e)
	if e.caster == player then
		local source = e.source
		local id
		for _, eff in ipairs(source.effects) do
			id = eff.id
			if (id == tes3_effect_open)
			or (id == tes3_effect_lock) then
				if logLevel > 2 then
					mwse.log("\n%s: casted(), magic = %s", modPrefix, source)
				end
				spellTicked = false
				return
			end
		end
	end
end


local function updateEnemiesAndChasers()
	local playerCell = player.cell
	local inGameHoursPassedFromGameStart = getInGameHoursPassedFromGameStart()
	local chaseMaxHours = config.chaseMaxHours

	local funcPrefix = string.format("%s updateEnemiesAndChasers()", modPrefix)

	local activechasers = {}

	local dayTime = isDayTime()

	local enemyRef, enemyMob -- updated by processChaser

	local chaseEndMessage = config.chaseEndMessage


	local function moveBackChaser(lcEnemyRefId, chaser)
		enemyRef = tes3.getReference(lcEnemyRefId)
		if not enemyRef then
			if logLevel > 1 then
				mwse.log('%s moveBackChaser: enemy ref "%s" not found', funcPrefix, lcEnemyRefId)
			end
			return
		end
		local cid = chaser.cellId
		local pos = chaser.pos
		local dest
		if cid == '' then
			dest = string.format('exterior %s', pos)
			tes3.positionCell({reference = enemyRef, position = pos})
		else
			dest = string.format('"%s" %s', cid, pos)
			tes3.positionCell({reference = enemyRef, cell = cid, position = pos})
		end
		if chaseEndMessage then
			if enemyRef then
				tes3ui.showNotifyMenu("You can't hear %s chasing you any more.", getActorRefName(enemyRef))
			end
		end
		if logLevel > 1 then
			mwse.log('%s: "%s" moved back to %s', funcPrefix, lcEnemyRefId, dest)
		end
	end


	local function processChaserWithDelay(lcEnemyRefId, chaser)

		enemyRef = tes3.getReference(lcEnemyRefId)

		if not enemyRef then
			local obj = tes3.getObject(lcEnemyRefId)
			if obj then
				if chaseEndMessage then
					tes3ui.showNotifyMenu( "You can't hear %s chasing you any more.", getActorName(obj) )
				end
			elseif logLevel > 0 then
				mwse.log('%s: WARNING tes3.getObject("%s") failed', funcPrefix, lcEnemyRefId)
			end
			if enemies[lcEnemyRefId] then
				enemies[lcEnemyRefId] = nil
				doPack = true
			end
			if logLevel > 1 then
				if chaser.cellId == '' then
					mwse.log('%s: stored chaser "%s" not found, removing from enemies/chasers', funcPrefix, lcEnemyRefId)
				else
					mwse.log('%s: stored chaser "%s".cellId ("%s") not found, removing from enemies/chasers', funcPrefix, lcEnemyRefId, chaser.cellId)
				end
			end
			return false
		end

		local dist = player.position:distance(enemyRef.position)

		if logLevel > 0 then
			mwse.log('%s: "%s" initial cell "%s" current distance from player = %s', funcPrefix, lcEnemyRefId, chaser.cellId, dist)
		end

		enemyMob = enemyRef.mobile
		if not enemyMob then
			return false
		end
		local mobCell = enemyRef.cell

		if isPlayerDetected(enemyMob)
		or enemyCanSeePlayerAtDistance(enemyRef, dist)
		or playerCanSeeEnemyAtDistance(enemyRef, dist) then

			if dayTime then
				if mobCell.isOrBehavesAsExterior then
					if isVampire(enemyRef) then
						if logLevel > 2 then
							mwse.log('%s: isVampire("%s")', funcPrefix, lcEnemyRefId)
						end
						if enemyMob.health.normalized < 0.9 then
							if logLevel > 2 then
								mwse.log('%s: "%s".health.normalized < 0.9', funcPrefix, lcEnemyRefId)
							end
							if enemyMob.hasFreeAction then
								if not isDead(enemyMob) then
									if logLevel > 1 then
										mwse.log('%s: "%s" teleporting away', funcPrefix, lcEnemyRefId)
									end
---@diagnostic disable-next-line: param-type-mismatch
									enemyMob:stopCombat(true)
									tes3.cast({target = enemyRef, reference = enemyRef, spell = 'touch dispel'}) -- a cheap on touch one
									return true
								end
							end
						end
					end
				end
			end

			if logLevel > 1 then
				mwse.log('%s: player can see "%s" at %s distance, no reset', funcPrefix, lcEnemyRefId, dist)
			end
			activechasers[lcEnemyRefId] = chaser
			enemies[lcEnemyRefId] = true
			return false
		end

		if dist > chaseMaxDistance then
			if playerCell.isInterior == mobCell.isInterior then
				if logLevel > 1 then
					mwse.log('%s: "%s" distance from player = %s > max distance = %s, reset', funcPrefix, lcEnemyRefId, dist, chaseMaxDistance)
				end
				return false
			end
		end

		if not enemyMob.hasFreeAction then --  paralyzed, dead, stunned, or otherwise unable to take action
			mwse.log('%s: enemy "%s" is not in combat any more, reset', funcPrefix, lcEnemyRefId)
			return false
		end

		if chaseLevel <= 2 then
			if not isPlayerDetected(enemyMob) then
				if logLevel > 0 then
					mwse.log('%s: enemy "%s" cannot detect player, reset', funcPrefix, lcEnemyRefId)
				end
				return false
			end
		end

		if dayTime then
			if mobCell.isOrBehavesAsExterior then
				if isVampire(enemyRef) then
					if logLevel > 0 then
						mwse.log('%s: enemy "%s" is vampire, dayTime, reset', funcPrefix, lcEnemyRefId)
					end
					return false
				end
			end
		end

		local hoursDiff = inGameHoursPassedFromGameStart - chaser.hours
		if hoursDiff > chaseMaxHours then
			if logLevel > 1 then
				mwse.log('%s: %s hours passed since "%s" started combat, reset', funcPrefix, hoursDiff, lcEnemyRefId)
			end
			return false
		end

		activechasers[lcEnemyRefId] = chaser
		enemies[lcEnemyRefId] = true
		return false
	end -- local function processChaser


	local delay, enRef, enMob
	for lcEnemyRefId, chaser in pairs(chasers) do
		delay = processChaserWithDelay(lcEnemyRefId, chaser)
		if delay
		or (not activechasers[lcEnemyRefId]) then
			enRef = tes3.getReference(lcEnemyRefId)
			if enRef then
				enMob = enRef.mobile
				if enMob then
					if enMob.hasFreeAction then
						if not isDead(enMob) then
							if delay then
								timer.start({duration = 2.5, callback = function() moveBackChaser(lcEnemyRefId, chaser) end})
							else
								moveBackChaser(lcEnemyRefId, chaser)
							end
						end
					end
				end
			end
		end
	end
	chasers = activechasers

---@diagnostic disable-next-line: undefined-field
	if table.empty(chasers) then
		enemies = {} ---getCleanedTable(enemies)
	elseif doPack then
		packEnemies()
	end

end



local function cellChanged(e)
	if not e.cell.isOrBehavesAsExterior then
		return
	end
	if not e.previousCell then
		return -- skip at game load
	end
	if e.previousCell.isOrBehavesAsExterior then
		-- cell and previousCell are both different isOrBehavesAsExterior cells
		updateEnemiesAndChasers()
	end
end



local function objectInvalidated(e)
	-- WTF how can e.object.id be nil? still it may happen
	local obj = e.object
	if obj then
		local id = obj.id
		if id then
			local lcObjId = string.lower(id)
			if enemies[lcObjId] then
				enemies[lcObjId] = nil -- dead or deleted
				doPack = true
			end
		end
	end
end

--[[
local function array2string(t)
	local s
	for _, v in ipairs(t) do
		if s then
			s = s .. ', '.. v
		else
			s = v
		end
	end
	return s
end

local function dict2string(t)
	local s, s1
	for k, v in pairs(t) do
		s1 = string.format('["%s"] = %s', k, v)
		if s then
			s = s .. s1
		else
			s = s1
		end
	end
	return s
end

local function table2vec(t)
	local v = tes3vector3.new(t[1], t[2], t[3])
	if logLevel > 1 then
		mwse.log("%s: table2vec(%s) = %s", modPrefix, array2string(t), v)
	end
	return v
end

local function vec2table(v)
	local t = {math.floor(v.x + 0.5), math.floor(v.y + 0.5), math.floor(v.z + 0.5)}
	if logLevel > 1 then
		mwse.log("%s: vec2table(%s) = %s", modPrefix, v, array2string(t))
	end
	return t
end
]]

local function table2vec(t)
	return tes3vector3.new(t[1], t[2], t[3])
end

local function vec2table(v)
	return {math.floor(v.x + 0.5), math.floor(v.y + 0.5), math.floor(v.z + 0.5)}
end

local function loaded(e)
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	worldController = tes3.worldController
	processManager = worldController.mobManager.processManager
	tes3gmst_fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult)

	enemies = {}
	chasers = {}
	lastDoorLockedId = nil
	lastDoorLockedRef = nil
	spellTicked = false

	if e.newGame then
		return
	end

	local data = player.data
	if not data then
		return
	end

	lastDoorLockedId = data.ab01lastDoorLockedId
	if lastDoorLockedId then
		lastDoorLockedRef = tes3.getReference(lastDoorLockedId)
		---updateLastDoorLocked()
	end

	local ab01chasers = data.ab01chasers
	if ab01chasers then
		for k, v in pairs(ab01chasers) do
			if tes3.getReference(k) then
				chasers[k] = {cellId = v.cellId, pos = table2vec(v.pos), hours = v.hours}
			end
		end
	end

---@diagnostic disable-next-line: undefined-field
	if table.empty(chasers) then
		if logLevel > 1 then
			mwse.log("%s: loaded() chasers table empty", modPrefix)
		end
		return
	end

	-- dalayed to give the AI enough time to update
	timer.start({duration = 3 + math.random(), callback = updateEnemiesAndChasers})
end

local function save()
	updateEnemiesAndChasers() -- cleanup before storing chasers
	---updateLastDoorLocked()
	local data = player.data
	if not data then
		player.data = {}
	end
	player.data.ab01lastDoorLockedId = lastDoorLockedId

	local t = {}
	for k, v in pairs(chasers) do
		t[k] = {cellId = v.cellId, pos = vec2table(v.pos), hours = v.hours}
	end
	player.data.ab01chasers = t
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

--[[ real problem is not sorting, but MCM java style coding + Lua strings = superslow

local tes3_objectType_npc = tes3.objectType.npc

local function getObjectsList(tes3_object_type, blacklist)
	local startTime = os.clock()
	local t = {}
	local lcObjId
	if blacklist then
		for obj in tes3.iterateObjects(tes3_object_type) do
			lcObjId = string.lower(obj.id)
			if not blacklist[lcObjId] then
				---table.insert(t, lcObjId)
				table.bininsert(t, lcObjId)
			end
		end
	else
		for obj in tes3.iterateObjects(tes3_object_type) do
			lcObjId = string.lower(obj.id)
			---table.insert(t, lcObjId)
			table.bininsert(t, lcObjId)
		end
	end
	---table.sort(t)
	mwse.log(">>> getObjectsList() elapsed time: %s sec", os.clock() - startTime)
	return t
end

local function getCreaturesBlacklist()
	return getObjectsList(tes3_objectType_creature)
end
local function getNPCsBlacklist()
	return getObjectsList(tes3_objectType_npc)
end
local function getCreaturesWhitelist()
	return getObjectsList(tes3_objectType_creature, config.blacklist)
end
local function getNPCsWhitelist()
	return getObjectsList(tes3_objectType_npc, config.blacklist)
end
]]

--[[ -- not working
local function spellResistVampireSunDamage(e)
	if fixMissingVampireSpells then
		if e.source == vampireSunDamage
		or e.sourceInstance == vampireSunDamage then
			e.sourceInstance:playVisualEffect({
				effectIndex = 0,
				position = e.target.position,
				---visual = 'VFX_DestructHit'
				visual = 'VFX_FireShield'
			})
			mwse.log('vampireSunDamage VFX')
		end
	end
end
 ]]

--[[ nope does not work
local sunDamageMagicEffect --set in modConfigReady()
local tes3_damageSource_magic = tes3.damageSource.magic
local function damage(e)
	if sunDamageKillingTime == 0 then
		return
	end
	if e.source == tes3_damageSource_magic then
		---local magicEffectInstance = e.magicEffectInstance
		---if magicEffectInstance then
			local ref = e.reference
			if ref == player then
				return
			end
			if isVampire(ref) then
				local newDamage = 0 - ( e.mobile.health.base * 0.00825 / sunDamageKillingTime)
				mwse.log("ref = %s, damage = %s, newDamage = %s, time = %s ms", ref.id, e.damage, newDamage, tes3.worldController.systemTime)
				e.damage = newDamage
			end
		---end
	end
end
]]

local resetChasers = false
local resetConfig = false

local function modConfigReady()

	vampireSpells = {
	[1] = getObject('Vampire Sun Damage'),
	[2] = getObject('Vampire Attributes'),
	[3] = getObject('Vampire Skills'),
	[4] = getObject('Vampire Immunities'),
	[5] = getObject('Vampire Touch'),
	[6] = getObject('Vampire Levitate'),
	}

	vampireSunDamage = vampireSpells[1]

	vampireSpecialSpells = {
		['aundae'] = getObject('Vampire Aundae Specials'),
		['berne'] = getObject('Vampire Berne Specials'),
		['quarra'] = getObject('Vampire Quarra Specials'),
	}

	worldController = tes3.worldController
	assert(worldController)
	processManager = worldController.mobManager.processManager
	assert(processManager)

	unlockSound = tes3.getSound('Open Lock')
	bashSound = tes3.getSound('Pack')
	spellSound = tes3.getSound('alteration hit')
	---sunDamageMagicEffect = tes3.getMagicEffect(tes3.effect.sunDamage)
	---assert(sunDamageMagicEffect)


	local usage = [[
Enemies will try and use their available tools/abilities to open the linked doors if locked
by player nusing locking magic (e.g. Fenrick's Doorjam spell) or the door key if available.
Compatible with my Loading Doors linked doors synchronization mod.]]

	local delayFormulaDescr = [[Formula is:
Delay before chasing player through doors = distanceFromPlayerAtCombatStart / ( (enemySpeed + delayDivider) * 10 ) + minDelay
So e.g. with minDelay 3, delayDivider 50 an enemy having 50 speed, 2048 units away from player will take
2048 / ( (50 + 50) * 10 ) + 3 = about 5 sec to chase the player through a loading door.]]
	local chaseMsgDescr = [[Allow in game messages when relevant chasers actions happen.]]

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		if resetConfig then
			resetConfig = false
---@diagnostic disable-next-line: undefined-field
			table.copy(defaultConfig, config)
		end
		updateConfig()
		if resetChasers then
			resetChasers = false
			chasers = {}
			enemies = {}
			lastDoorLockedId = nil
			lastDoorLockedRef = nil
		elseif tes3.player then
			updateEnemiesAndChasers()
		end
		mwse.saveConfig(configName, config, {indent = true})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label = "Preferences",
		postCreate = function(self)
			local width1 = 1.2
			local width2 = 2 - width1 -- total width must be 2
			local sideBlock = self.elements.sideToSideBlock
			sideBlock.children[1].widthProportional = width1
			sideBlock.children[2].widthProportional = width2
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{text = [[Makes enemies able to follow you through loading doors.
Saves enemy state and resets enemy position when done.
It should allow player to try and lock enemies inside using lock spells/door key with the linked outside door.
Some enemies may be able to unlock/bash the door though.
Notes:
Changes to chasing state are usually triggered before saving, after reloading, after crossing exterior cells borders.
By default vampires will not follow you outside in broad daylight but you may still be able to lure them out during sunrise/dawn change time.
Sometimes vampire powers/sun damaged are not applied correctly in game so you may want to enable the available fix for that.]]}

	local controls = preferences:createCategory({})

	---controls:createInfo({text = ""})

	controls:createSlider({
		label = "Min delay %s sec",
		variable = createConfigVariable("minDelay")
		,min = 3, max = 10, step = 1, jump = 2,
		description = string.format([[Minimum delay (in seconds) before enemy may follow you through a loading door (default: %s).
It makes sense to set it high enough (e.g. 3 sec) to give player enough time to cast a lock spell on exterior door to try and lock in enemies.
%s]], defaultConfig.minDelay, delayFormulaDescr)
	})

	controls:createSlider({
		label = "Delay divider %s",
		variable = createConfigVariable("delayDivider")
		,min = 1, max = 100, step = 1, jump = 5,
		description = string.format([[Delay divider (default: %s).
The higher Delay divider, the faster enemies will be able to chase you through doors.
%s]], defaultConfig.delayDivider, delayFormulaDescr)
	})

	controls:createSlider({
		label = "Max chase duration (hours) %s",
		variable = createConfigVariable("chaseMaxHours")
		,min = 1, max = 72, step = 1, jump = 5,
		description = string.format([[Max chase duration (hours). Default %s.
Max hours before enemies will give up chasing you. You may want to tweak this according to your TimeScale settings.]], defaultConfig.chaseMaxHours)
	})

	controls:createYesNoButton{
		label = "Vampires chase outside in full daylight",
		variable = createConfigVariable("vampireChase"),
		description = [[Allow vampire enemies to chase player outside in full daylight.]]
	}

	controls:createYesNoButton{
		label = "Fix vampire spells if missing",
		variable = createConfigVariable("fixMissingVampireSpells"),
		description = [[Fix vampire spells if missing (e.g. missing Vampire Sun Damage and vampire stats increase).
Note that this may make some low level vampires more dangerous but extremely vulnerable to sun light.]]
	}

--- nope changing damage does not work
--- 	controls:createSlider({
--- 		label = "Sun Damage Killing Time (sec)",
--- 		variable = createConfigVariable("sunDamageKillingTime")
--- 		,min = 0, max = 200, step = 1, jump = 5,
--- 		description = string.format([[Default: %s. 0 = not changed from vanilla.
--- Average time in seconds needed for Sun Damage to kill a (non player) vampire.
--- It makes sense to set it > 0 if you use the "Fix vampire spells if missing" so low level vampires are not killed by Sun Damage in 5 seconds.]],
--- defaultConfig.sunDamageKillingTime)
--- 	})

	controls:createYesNoButton{
		label = "Tomb undeads chase outside",
		variable = createConfigVariable("undeadChase"),
		description = [[Allow non-vampire undead enemies protecting tombs to chase player outside.]]
	}
	controls:createYesNoButton{
		label = "Creatures too big to pass through door frame cannot follow",
		variable = createConfigVariable("checkEnemySize"),
		description = [[Disallow creatures too big to pass through door frame to follow player.]]
	}
	controls:createYesNoButton{
		label = "Only handy creature can open doors",
		variable = createConfigVariable("checkHandy"),
		description = [[Disallow non-handy creatures to open/follow through doors.]]
	}

	controls:createYesNoButton{
		label = "Use lockpicks",
		variable = createConfigVariable("useLockpicks"),
		description = [[Enemies can use their lockpicks and thieving skills to try and unlock a loading door.]]..usage
	}

	controls:createYesNoButton{
		label = "Use magic",
		variable = createConfigVariable("useMagic"),
		description = [[Allow enemies to use their known open spells (e.g. Ondusi's Open Door)
		to try and unlock a loading door.]]..usage
	}

	controls:createYesNoButton{
		label = "Use magicka",
		variable = createConfigVariable("checkMagicka"),
		description = [[Enemy magicka will influence enemy chance to successfully cast open spells.
		Needs "Use magic" enabled too to be effective.
		As game AI usually consumes magicka mostly for offensive spells, this can make low level enemy casters
		more effective at using open spells to unlock doors.]]..usage
	}

	controls:createYesNoButton{
		label = "Use enchanted items",
		variable = createConfigVariable("useEnchantment"),
		description = [[Allow enemies to use enchanted items (e.g. Scroll of Ekash's Lock Splitter)
		to try and unlock a loading door.]]..usage
	}

	controls:createYesNoButton{
		label = "Use bash",
		variable = createConfigVariable("useBash"),
		description = [[Allow high strength enemies to try and bash a locked loading door.]]..usage
	}

	controls:createSlider({
		label = "Min. Bashing Strength",
		variable = createConfigVariable("minBashingStrength")
		,min = 50, max = 200, step = 1, jump = 5,
		description = string.format([[Minimum strength needed to bash a door. Default: %s]],
defaultConfig.minBashingStrength)
	})

	controls:createYesNoButton{
		label = "End chase message",
		variable = createConfigVariable("chaseEndMessage"),
		description = chaseMsgDescr
	}
	controls:createYesNoButton{
		label = "Start chase message",
		variable = createConfigVariable("chaseStartMessage"),
		description = chaseMsgDescr
	}
	controls:createYesNoButton{
		label = "Door unlocked message",
		variable = createConfigVariable("doorUnlockedMessage"),
		description = chaseMsgDescr
	}

	controls:createDropdown{
		label = "Chase level:",
		options = {
			{ label = "0. Chase disabled", value = 0 },
			{ label = "1. Only when able to see player", value = 1 },
			{ label = "2. Only when able to detect player", value = 2 },
			{ label = "3. Only in AI range", value = 3 },
			{ label = "4. Only in max chase distance", value = 4 },
		},
		variable = createConfigVariable("chaseLevel"),
		description = [[limit enemies ability to chase player through loading doors:
1. Only when able to see player = only if they can see you
2. Only when able to detect player = only if they can detect you
3. Only in AI range = only if they are in AI distance range (for this setting to work better it is suggested to set the standard game AI distance slider to the max = 7000)
4. Only in max chase distance = only if they are in max chase distance range]]
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Off", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
			{ label = "4. Max", value = 4 },
		},
		variable = createConfigVariable("logLevel"),
		description = [[Debug logging level. Default: 0. Off.]]
	}

	controls:createSlider({
		label = "Max chase distance %s",
		variable = createConfigVariable("chaseMaxDistance")
		,min = 4096, max = 98304, step = 1, jump = 128,
		description = string.format([[Max chase distance (default: %s).
Only effective when previous "Chase level" option is set to "4. Only in max chase distance"]], defaultConfig.chaseMaxDistance)
	})

	controls:createSlider({
		label = "Max follower distance from player %s",
		variable = createConfigVariable("followerMaxPlayerDistance")
		,min = 0, max = 4096, step = 1, jump = 128,
		description = string.format([[Max follower distance from player (default: %s).
		Max distance from player of a player follower to be possibly chased."]], defaultConfig.followerMaxPlayerDistance)
	})


	controls:createButton{
		label = "Reset MCM mod configuration to default values",
		buttonText = "Reset to default",
		description = "WARNING this will reset the whole MCM mod configuration panel to default values.",
		callback = function()
			resetConfig = true
		end,
	}

	if logLevel >= 4 then
		controls:createButton{
			label = "WARNING meant to be used only if you know what you are doing",
			buttonText = "Reset stored chasers/enemies",
			description = [[Only available when Logging level is set to Max.
Meant to be used only if you want to clean a saved game from the mod data.
This button will clean stored enemies starting cell coordinates, so after pressing it you can save the game to a clean state.
Before using it though be aware that if you have still some enemies out there currently chasing you,
they will not be able to go back to original starting cells automatically any more.]],
			callback = function()
				resetChasers = true
			end,
		}
	end


--[[template:createExclusionsPage{ -- too slow
		label = "Blacklist",
		description = "Select plugins / actors not allowed to chase player through loading doors (bypassing standard settings).",
		showAllBlocked = false,
		variable = createConfigVariable("blacklist"),
	    filters = {
			{label = "Plugins", type = "Plugin" },
			{label = "Creatures", type = "Object", objectType = tes3_objectType_creature},
			{label = "NPCs", type = "Object", objectType = tes3_objectType_npc},
		}
	}
	template:createExclusionsPage{
		label = "Whitelist",
		description = "Select actors allowed to chase player through loading doors (bypassing standard settings).",
		showAllBlocked = true,
		variable = createConfigVariable("whitelist"),
	    filters = {
			{label = "Creatures", type = "Object", objectType = tes3_objectType_creature},
			{label = "NPCs", type = "Object", objectType = tes3_objectType_npc},
		}
	}
]]

	mwse.mcm.register(template)

	event.register('combatStarted', combatStarted)
	event.register('death', death)
	event.register('objectInvalidated', objectInvalidated)
	event.register('activate', activate, {priority = 10000})
	event.register('magicCasted', casted) -- spells, alchemy and enchanted items
	event.register('spellTick', spellTick)
	event.register('save', save)
	event.register('loaded', loaded)
	event.register('cellChanged', cellChanged)
	---event.register('spellResist', spellResistVampireSunDamage, {source = vampireSunDamage})
	---event.register('damage', damage)
	---logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady) -- happens before initialized()