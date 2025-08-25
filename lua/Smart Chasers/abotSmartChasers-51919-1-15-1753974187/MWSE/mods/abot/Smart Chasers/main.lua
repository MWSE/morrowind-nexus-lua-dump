---@diagnostic disable: deprecated
--[[
Hostiles following through loading doors /abot
]]

-- begin configurable parameters
local defaultConfig = {
minDelay = 3, -- Min. sec delay before chasing player through doors (try and give player enough time to lock the exterior door)
delayDivider = 80, -- Delay divider. Delay before chasing player through doors = (distanceFromPlayerAtCOmbatStart / delayDivider) + minDelay
unlockDelay = 2, -- extra delay for unlocking the door
chaseEndMessage = true, -- Allow in game messages when relevant chasers actions happen
chaseStartMessage = false,
doorUnlockedMessage = false,
chaseLevel = 4, -- 0 = disabled, 1 = only if they see player using the door, 2 = only if they detect player, 3 = only if they are in AI distance range, 4 = Omly in maxDistance
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
assert(config)

local fixMissingVampireSpells, chaseLevel
local chaseMaxDistance, followerMaxPlayerDistance
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

-- set in loaded()
local worldController  --- , processManager -- nope
local unlockSound, bashSound, spellSound
local player, mobilePlayer
local tes3gmst_fPickLockMult

local function updateFromConfig() -- used in modConfigReady template.onClose
	fixMissingVampireSpells = config.fixMissingVampireSpells
	---sunDamageKillingTime = config.sunDamageKillingTime
	chaseLevel = config.chaseLevel
	if chaseLevel >= 4 then
		chaseMaxDistance = config.chaseMaxDistance
	else
		local processManager = worldController.mobManager.processManager
		chaseMaxDistance = processManager.aiDistance
	end
	followerMaxPlayerDistance = config.followerMaxPlayerDistance
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
end

-- enemies[string.lower(enemyRef.id)] true = in combat, nil = dead or deleted
local enemies = {}
local enemyCount = 0

local function addEnemy(lcId, ref)
	if enemies[lcId] then
		enemies[lcId] = ref
		return
	end
	enemies[lcId] = ref
	enemyCount = enemyCount + 1
	if logLevel4 then
		mwse.log('%s: addEnemy("%s")', modPrefix, lcId)
	end
end

local function removeEnemy(lcId)
	if enemies[lcId] then
		enemies[lcId] = nil
		enemyCount = enemyCount - 1
		if logLevel4 then
			mwse.log('%s: removeEnemy("%s")', modPrefix, lcId)
		end
		return true
	end
	return false
end

local function clearEnemies()
	enemies = {}
	enemyCount = 0
end

--[[local doPackEnemies = false
local function packEnemies()
	local t = {}
	enemyCount = 0
	for k, v in pairs(enemies) do
		t[k] = v
		enemyCount = enemyCount + 1
	end
	enemies = t
	doPackEnemies = false
end]]

local function getActorRef(lcRefId)
	local ref = enemies[lcRefId]
	if ref
	and (not ref.disabled)
	and (not ref.deleted) then
		return ref
	end
-- should hopefully be faster than tes3.getReference()
-- cons: 72 hours expire, enough for our use case
	local mobileActors = worldController.allMobileActors
	local mob
	for i = 1, #mobileActors do
		mob = mobileActors[i]
		ref = mob.reference
		if ref
		and (not ref.disabled)
		and (not ref.deleted) then
			---mese.log('ref = "%s"', ref)
			if string.lower(ref.id) == lcRefId then
				return ref
			end
		end
	end
	ref = tes3.getReference(lcRefId)
	if ref
	and (not ref.disabled)
	and (not ref.deleted) then
		return ref
	end
end

--[[
 chasers table will be saved in game in player.data
 cellId = identifier of enemy original starting cell if interior e.g. "Ilunibi, Carcass of the Saint", "" if exterior
 pos = original enemy position, rounded to integer coordinates e.g. {x = -100, y = 2345678, z = -201}
 hours = stored initial hoursPassed (24 * DaysPassed + GameHour) when chasing through door started
 e.g. chasers[lcEnemyRefId] = {cellId = cid, pos = startPos, hours = getInGameHoursFromGameStart()}
 ]]
local chasers = {} -- e.g. chasers[string.lower(enemyRef.id)] = {cellId = startCellId, pos = startCellPos, hours = hoursPassedSinceGameStart, fight = enemyMob.fight}

local tes3_actorType_creature = tes3.actorType.creature
local tes3_actorType_npc = tes3.actorType.npc

local tes3_creatureType_normal = tes3.creatureType.normal
local tes3_creatureType_undead = tes3.creatureType.undead
--[[local tes3_creatureType_daedra = tes3.creatureType.daedra
local tes3_creatureType_humanoid = tes3.creatureType.humanoid]]

local function startsWithListed(s, list)
	if not s then
		return false
	end
	local lcs = string.lower(s)
	local lcListElement
	for i = 1, #list do
		lcListElement = string.lower(list[i])
		if string.startswith(lcs, lcListElement) then
			return true
		end
	end
	return false
end

local function startsOrEndsWithListed(s, list)
	if not s then
		return false
	end
	local lcs = string.lower(s)
	local lcListElement
	for i = 1, #list do
		lcListElement = string.lower(list[i])
		if string.startswith(lcs, lcListElement)
		or string.endswith(lcs, lcListElement) then
			return true
		end
	end
	return false
end

-- include cell names prefix or suffix
local cellsBlackList = {'Corprusarium','Arena Pit'}

local function isCellBlacklisted(cell)
	return startsOrEndsWithListed(cell.id, cellsBlackList)
end

-- include mod name prefix
local modBlacklist = {'abotWhereAreAllBirds'}

local function isModBlacklisted(sourceMod)
	return startsWithListed(sourceMod, modBlacklist)
end

-- include lower case actor id
local chaserBlacklist = {'jac_jasmine','bat','wolf_bone','wolf_skeleton','hircine_spd','hircine_str'}
local handyWhitelist = {'centurion','draugr','fabricant_hulking','frost_giant',
'goblin','guar','ice_troll','imperfect','spriggan','vivec_god','yagrum bagarn'}


local function canPassThroughDoor(mobile, doorRef)
	local mobRef = mobile.reference
	local mobBounds = mobRef.object.boundingBox
	if not mobBounds then
		if logLevel2 then
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
	local doorSizeX = (doorBounds.max.x - doorBounds.min.x) * doorScale
	local doorSizeY = (doorBounds.max.y - doorBounds.min.y) * doorScale
	local doorSize = math.max(doorSizeX, doorSizeY)

	local mobHeight = (mobBounds.max.z - mobBounds.min.z) * mobScale
	local mobSizeX = (mobBounds.max.x - mobBounds.min.x) * mobScale
	local mobSizeY = (mobBounds.max.y - mobBounds.min.y) * mobScale
	local mobSize = math.min(mobSizeX, mobSizeY) -- and strafe

	if (mobHeight > doorHeight)
	and (mobSize > doorSize) then
		if logLevel2 then
			mwse.log([[%s: mob height = %s > door height = %s
mob size = %s > door size = %s]], modPrefix, mobHeight, doorHeight, mobSize, doorSize)
		end
		return false
	end
	return true
end

local function isVampire(actorRef)
	local mob = actorRef.mobile
	if mob
	and mob.hasVampirism then
		return true
	end
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
	local vampObj = vampRef.object
	local faction = vampObj.faction
	local lcFactionId
	if faction then
---@diagnostic disable-next-line: undefined-field
		lcFactionId = string.split(string.lower(faction.id), '_')[2]-- e.g. 'clan berne' --> 'berne'
		if logLevel3 then
			mwse.log('%s: fixVampireSpells "%s" lcFactionId = %s', modPrefix, vampRef.id, lcFactionId)
		end
	else
		local script = vampObj.script
		if script then
---@diagnostic disable-next-line: undefined-field
			lcFactionId = string.split(string.lower(script.id), '_')[2] -- e.g. 'vampire_berne_boss' --> 'berne'
			if logLevel3 then
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
		if logLevel2 then
			mwse.log('%s: fixVampireSpells "%s" missing vampire spells fixed', modPrefix, vampRef.id)
		end
		return
	end
	return false
end

local lastDoorLockedId, lastDoorLockedRef

local function getRefVariable(ref, variableId)
	local script = ref.object.script
	if not script then
		return nil
	end
	local context = script['context'] -- will this work better?
	---local context = ref['context']
	if not context then
		return nil
	end

	if ref.attachments
	and ref.attachments.variables
	and not ref.attachments.variables.script then
		return nil
	end

	if logLevel4 then
		mwse.log('%s: getRefVariable("%s", "%s") context = %s',
			modPrefix, ref.id, variableId, context)
	end
	-- need more safety
	local value = context[variableId]
	if value then
		if logLevel3 then
			mwse.log('%s: getRefVariable("%s", "%s") context["%s"] = %s)',
				modPrefix, ref.id, variableId, variableId, value)
		end
		return value
	end
	return nil
end

local function getCompanion(ref)
	return getRefVariable(ref, 'companion')
end

--[[local function isCompanion(ref)
	local companion = getCompanion(ref)
	if companion
	and (companion == 1) then
		return true
	end
	return false
end]]

local function hasCompanion(ref)
	if getCompanion(ref) then
		return true
	end
	return false
end

local function isDead(mobile)
	local result = false
	if mobile.isDead then
		result = true
	else
		local actionData = mobile.actionData
		if actionData then
			local animState = actionData.animationAttackState
			if animState then
				if (animState == tes3.animationState.dying)
				or (animState == tes3.animationState.dead) then
					result = true
				end
			end
		end
	end
	local health = mobile.health
	if health
	and health.current then
		if result then
			if health.current > 0 then
				health.current = 0
			end
		else
			if (health.normalized <= 0.025) -- health ratio <= 0.25%
			and (health.current > 0)
			and (health.current < 3)
			and (health.normalized > 0) then
				health.current = 0 -- kill when nearly dead, could be a glitch
				result = true
			end
		end
	end
	return result
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
-- ab01 prefix, probably some abot's creature with AIEscort/AIFollow package, skip
				return false
			end
			local creature = mobile.object -- tes3creature or tes3creatureInstance
			if creature then
				local script = creature.script
				if script then
					local lcId2 = string.lower(script.id)
					if string.startswith(lcId2, 'ab01') then
						-- ab01 prefix, probably some abot's creature
						-- with AIEscort/AIFollow package, skip
						if logLevel3 then
							mwse.log("%s: %s having ab01 prefix, probably some abot's creature with AIEscort/AIFollow package, skip", modPrefix, ref.id)
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

local function isValidFollower(mobile)
	if not isValidMobile(mobile) then
		return false
	end
	local ref = mobile.reference

	local ai = tes3.getCurrentAIPackageId(mobile)

	local aiPlanner = mobile.aiPlanner
	if aiPlanner then
		local activePackage = aiPlanner:getActivePackage()
		if activePackage then
			ai = activePackage.type
			if (ai == tes3_aiPackage_follow)
			or (ai == tes3_aiPackage_escort) then
				local targetActor = activePackage.targetActor
				if not (mobilePlayer == targetActor) then
					return false
				end
			end
		end
	end

	local hasComp = hasCompanion(ref)

	if ai == tes3_aiPackage_follow then
		if hasComp then
			return true
		end
		if not ref.object.isGuard then
			return true
		end
		return false
	elseif ai == tes3_aiPackage_escort then
		if hasComp then
			return true
		end
		return false
	elseif ai == tes3_aiPackage_wander
	and hasComp
	and hasOneTimeMove(ref) then
		-- special case for wandering destinations
		return true
	end
	return false
end

local function isBlacklistedOrNotHandy(mob)
	local funcPrefix = modPrefix..': isBlacklistedOrNotHandy()'
	local mobRef = mob.reference
	local mobRefId = mobRef.id
	local mobObj = mobRef.baseObject
	local mobCell = mobRef.cell
	if mobCell
	and isCellBlacklisted(mobCell) then
		if logLevel3 then
			mwse.log('%s: creature "%s" from blacklisted "%s" cell, skip', funcPrefix, mobRefId, mobCell.editorName)
		end
		return true
	end
	local sourceMod = mobObj.sourceMod
	if sourceMod
	and isModBlacklisted(sourceMod) then
		if logLevel3 then
			mwse.log('%s: creature "%s" from blacklisted "%s" mod, skip',
				funcPrefix, mobRefId, sourceMod)
		end
		return true
	end
	local lcObjId = string.lower(mobObj.id)
	if string.multifind(lcObjId, chaserBlacklist, 1, true) then
		if logLevel3 then
			mwse.log('%s: chaser "%s" blacklisted, skip', funcPrefix, mobRefId)
		end
		return true
	end
	if not (mob.actorType == tes3_actorType_creature) then
		return false
	end
	local crea = mob.reference.baseObject
	if crea.biped then
		return false
	end
	if crea.usesEquipment then
		return false
	end
	if not (crea.type == tes3_creatureType_normal) then
		return false
	end
	if string.multifind(lcObjId, handyWhitelist, 1, true) then
		return true
	end
	if config.checkHandy then
		if logLevel3 then
			mwse.log('%s: not handy creature "%s", skip', funcPrefix, mobRefId)
		end
		return true
	end
	return false
end

local function sameCellOrBothExteriors(cellA, cellB)
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

local function isChaserTooBig(mob, doorRef)
	if config.checkEnemySize
	and (not canPassThroughDoor(mob, doorRef)) then
		if logLevel3 then
			local funcPrefix = modPrefix..': isChaserTooBig()'
			local mobRefId = mob.reference.id
			mwse.log('%s: "%s" is too big to pass through "%s", skip', funcPrefix, mobRefId, doorRef.id)
		end
		return true
	end
	return false
end

local function round(x)
	return math.floor(x + 0.5)
end

local function getInGameHoursFromGameStart()
	local daysPassed = worldController.daysPassed.value
	local gameHour = worldController.hour.value
	return round( (daysPassed * 24) + gameHour )
end

local function updateDoorData(doorRef, locked)
	local data = doorRef.data
	if not data	then
		return
	end
	if data.ab01drlkhp then
		data.ab01drlkhp = getInGameHoursFromGameStart()
	end
	if data.ab01locked then
		data.ab01locked = locked
	end
end

local unlockDelay = 0

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

	local enemyRef = enemyMob.reference
	---assert(enemyRef)

	if enemyRef.disabled then
		return -- never say never
	end
	if enemyRef.deleted then
		return
	end

	local funcPrefix = modPrefix..' combatStarted()'
	local enemyRefId = enemyRef.id

	if not enemyMob.hasFreeAction then
		-- dead or paralyzed or stunned or otherwise unable to take action
		if logLevel2 then
			mwse.log('%s: enemy "%s" has no free action, skip', funcPrefix, enemyRefId)
		end
		return
	end

	if isBlacklistedOrNotHandy(enemyMob) then
		return
	end

	if hasCompanion(enemyRef) then
		if logLevel4 then
			mwse.log('%s: enemy "%s" is a companion, skip', funcPrefix, enemyRefId)
		end
		return
	end

	local mobileTarget = e.target
	if not mobileTarget then
		return
	end

	if not (mobileTarget == mobilePlayer) then
		local skip = true
		local playerPos = player.position
		local playerCell = player.cell
		local mobRef, mob
		local friendlyActors = mobilePlayer.friendlyActors
		for i = 1, #friendlyActors do
			mob = friendlyActors[i]
			if mob == enemyMob then
				if logLevel3 then
					mwse.log('%s: enemy "%s" is friendly, skip', funcPrefix, enemyRefId)
				end
				return
			end
			if mob == mobileTarget then
				mobRef = mob.reference
				if sameCellOrBothExteriors(mobRef.cell, playerCell)
				and (mobRef.position:distance(playerPos) < followerMaxPlayerDistance) then
					if isValidFollower(mob) then
						skip = false
						break
					end
				end
			end
		end
		if skip then
			return
		end
	end

	-- target is player or nearby player follower from here
	if logLevel3 then
		mwse.log('%s: e.actor = %s, e.target = %s', funcPrefix, enemyRefId, mobileTarget.reference.id)
	end

	local enemyCell = enemyRef.cell

	if lastDoorLockedId
	and lastDoorLockedRef then
		if isChaserTooBig(enemyMob, lastDoorLockedRef) then
			return
		end

		local lastDoorLockedCell = lastDoorLockedRef.cell
		local lastDoorLockedPos = lastDoorLockedRef.position
		local destination = lastDoorLockedRef.destination

		if sameCellOrBothExteriors(lastDoorLockedCell, player.cell) then
			unlockDelay = 0
			local d = lastDoorLockedPos:distance(player.position)
			if d > chaseMaxDistance then
				if logLevel4 then
					mwse.log('%s: player distance from last locked door > %s, skip', funcPrefix, chaseMaxDistance)
				end
				return
			end

			if destination then
				local marker = destination.marker
				if marker
				and sameCellOrBothExteriors(marker.cell, enemyCell) then
					d = marker.position:distance(enemyRef.position)
					if d > chaseMaxDistance then
						if logLevel4 then
							mwse.log('%s: enemy "%s" distance from last locked door destination > %s, skip', funcPrefix,enemyRefId, chaseMaxDistance)
						end
						return
					end
				end
			elseif sameCellOrBothExteriors(lastDoorLockedCell, enemyCell) then
				d = lastDoorLockedPos:distance(enemyRef.position)
				if d > chaseMaxDistance then
					if logLevel4 then
						mwse.log('%s: last not loading door locked, enemy and player in same cell, but enemy "%s" distance from door > %s, skip',
							funcPrefix, enemyRefId, chaseMaxDistance)
					end
					return
				end
			end
			unlockDelay = config.unlockDelay
		end	-- if sameCellOrBothExteriors(lastDoorLockedCell, player.cell)

	end -- if lastDoorLockedId

	if fixMissingVampireSpells
	and isVampire(enemyRef) then
		fixVampireSpells(enemyMob)
	end
 -- in combat. player activate event on a door will call checkDoorChasers(doorRef) that will use enemies
	local lcEnemyRefId = string.lower(enemyRefId)
	addEnemy(lcEnemyRefId, enemyRef)

	local chaser = chasers[lcEnemyRefId]
	local hoursPassedSinceGameStart = getInGameHoursFromGameStart()
	if chaser then -- only update chase starting hour
		chaser.hours = hoursPassedSinceGameStart
	else
		-- store a new chaser
		local startCellPos = enemyRef.position:copy()
		local startCellId = ''
		if enemyCell.isInterior then
			-- store enemy interior cell id before moving the enemy,
			-- and only if not already stored
			startCellId = enemyCell.id
		end
		chasers[lcEnemyRefId] = {cellId = startCellId,
			pos = startCellPos, hours = hoursPassedSinceGameStart, fight = round(enemyMob.fight)}
	end

end


local function death(e)
	local lcRefId = string.lower(e.reference.id)
	removeEnemy(lcRefId)
	---if removeEnemy(lcRefId) then
		---doPackEnemies = true
	---end
end

local function isDayTime()
	local gameHour = worldController.hour.value
	local wec = worldController.weatherController
	local sunrise = wec.sunriseHour + wec.sunriseDuration
	local sunset = wec.sunsetHour + wec.sunsetDuration
	return (gameHour >= sunrise) and (gameHour <= sunset)
end

local tes3_objectType_lockpick = tes3.objectType.lockpick
---local tes3_objectType_probe = tes3.objectType.probe

local function logObj(actorRef, obj)
	if not logLevel2 then
		return
	end
	local s
	if obj.objectType == tes3_objectType_lockpick then
		s = 'lockpick'
	else
		s = 'probe'
	end
	mwse.log('%s getThiefTool(): enemy "%s" using %s "%s"',
		modPrefix, actorRef.id, s, obj.id)
end

local function getThiefTool(actorRef, objectType)
	local inventory = actorRef.object.inventory
	if not inventory then
		return
	end
	local items = inventory.items
	for i = 1, #items do
		local stack = items[i]
		local obj = stack.object
		if (obj.objectType == objectType)
		and obj.name
		and ( not string.multifind(string.lower(obj.name),
				{'compass','sextant'}, 1, true) ) then
			local iData = stack.itemData
			if not iData then -- pristine
				iData = tes3.addItemData({to = actorRef, item = obj})
			end
			if iData then
				local condition = iData.condition
				if condition then
					if condition > 0 then
						condition = condition - 1
						-- decrease item condition as it would be be used
						iData.condition = condition
						logObj(actorRef, obj)
						return obj
					else
						-- removes item with 0 uses left
						tes3.removeItem({reference = actorRef, item = obj, count = 1, itemData = iData})
						-- look for another one
						return getThiefTool(actorRef, objectType)
					end
				end
			else -- should not happen but just in case...
				logObj(actorRef, obj)
				return obj
			end -- if iData
		end -- if (obj.objectType
	end -- for i
end

local function getLockpick(actorRef)
	return getThiefTool(actorRef, tes3_objectType_lockpick)
end

local tes3_effect_open = tes3.effect.open
local tes3_effect_lock = tes3.effect.lock
local tes3_effect_recall = tes3.effect.recall
local tes3_effect_almsiviIntervention = tes3.effect.almsiviIntervention
local tes3_effect_divineIntervention = tes3.effect.divineIntervention

local function getOpenSpell(actorRef, lockLevel)
	local spells = actorRef.object.spells
	if not spells then
		return nil, nil, nil
	end
	local t = {}
	local effectIndex, effect, mag, cha
	local found = false
	local funcPrefix = modPrefix..': getOpenSpell()'
	for _, spl in pairs(spells) do
		---mwse.log("spl = %s", spl.id)
		---if spl then
		if spl.isActiveCast
		or spl.alwaysSucceeds then
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
					if logLevel2 then
						mwse.log('%s: enemy "%s" spell "%s" magnitude = %s, chance = %s', funcPrefix, actorRef.id, spl.id, mag, cha)
					end
					if (mag >= lockLevel)
					and (cha >= 33) then
						table.insert(t, {spell = spl, magnitude = mag,
							chance = cha, mXc = mag * cha})
						found = true
					end
				end
			end
		end
	---end
	end

	if found then
		table.sort(t, function(a,b) return a.mXc > b.mXc end) -- sort by descending magnitude * chance
		local t1 = t[1]
		local spell = t1.spell
		if logLevel2 then
			mwse.log('%s: enemy "%s" using spell "%s" ("%s")', funcPrefix, actorRef.id, spell.id, spell.name)
		end
		return spell, t1.magnitude, t1.chance
	end
	return nil, nil, nil
end

local tes3_enchantmentType_onUse = tes3.enchantmentType.onUse
local tes3_enchantmentType_castOnce = tes3.enchantmentType.castOnce

local function getOpenEnchantedItem(actorRef)
	local inventory = actorRef.object.inventory

	local items = inventory.items
	for i = 1, #items do
		local stack = items[i]
		local object = stack.object
		local enchantment = object.enchantment
		if enchantment then
			local effectIndex = enchantment:getFirstIndexOfEffect(tes3_effect_open) -- tes3_effect_open = 13
			if effectIndex
			and (effectIndex >= 0) then
				effectIndex = effectIndex + 1
				local castType = enchantment.castType
				local castOnce = (castType == tes3_enchantmentType_castOnce)
				if castOnce
				or (
					(castType == tes3_enchantmentType_onUse)
					and (stack.variables.charge >= enchantment.chargeCost)
				) then
					local effect = enchantment.effects[effectIndex]
					local magnitude = math.floor((effect.min + effect.max) / 2)
					if logLevel2 then
						mwse.log('%s getOpenEnchantedItem(): enemy "%s" using "%s" enchanted item', modPrefix, actorRef.id, object.id)
					end
					return object, magnitude, castOnce
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
	local vol = math.max( 1 / (dist/3583 + 1), 0.4 )
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

local function playUnlockSound(doorRef)
	local ref = doorRef
	if doorRef.destination then
		ref = doorRef.destination.marker
	end
	playRefSound(ref, unlockSound)
end

local function getGenericName(name)
	if string.find(string.lower(name),"^[aeiou]") then
		return 'an ' .. name
	else
		return 'a ' .. name
	end
end

local tes3_objectType_creature = tes3.objectType.creature

--[[
local function getActorName(baseObj)
	local name = baseObj.name
	if name then
		local generic = false
		local cloneCount = baseObj.cloneCount
		if cloneCount then
			if cloneCount > 1 then
				generic = true
			end
		end
		if not generic then
			if baseObj.objectType == tes3_objectType_creature then
				generic = true
			end
		end
		if generic then
			name = getGenericName(name)
		end
	end
	return name
end
]]

local function getActorRefName(ref)
	local name = ref.object.name
	local generic = true
	if hasCompanion(ref) then
		generic = false
	end
	if generic
	and ( not (ref.object.objectType == tes3_objectType_creature) ) then
		local cloneCount = ref.baseObject.cloneCount
		if cloneCount < 2 then
			generic = false
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
	local funcPrefix = modPrefix..': linkedDoors()'
	if d > 350 then
		if logLevel2 then
			mwse.log('%s: markerPos:distance(linkedDoorPos) > 350, not linked', funcPrefix)
		end
		return false
	end
	d = math.abs(linkedDoorPos.z - markerPos.z)
	if d > 192 then
		if logLevel2 then
			mwse.log('%s: math.abs(linkedDoorPos.z - markerPos.z) > 192, not linked', funcPrefix)
		end
		return false
	end
	return true
end

-- OK. probably usimg handles for door references is overkill but
-- better safe than sorry as I'm using persistent timers anyway

local function handleToRef(handle)
	---assert(handle)
	if not handle then
		return
	end
	if not handle.valid then
		---assert(handle.valid)
		return
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end

local function getTimerRef(e)
	local timer = e.timer
	local data = timer.data
	local handle = data.handle
	local ref = handleToRef(handle)
	---assert(ref)
	return ref
end

local function getTimerRefs(e)
	local data = e.timer.data
	local handles = data.handles
	local refs = {}
	for i = 1, #handles do
		local ref = handleToRef(handles[i])
		---assert(ref)
		if ref then
			refs[i] = ref
		end
	end
	if #refs == #handles then
		return refs
	end
end

local function ab01smtchsPT1(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	local doorRef = refs[1]
	local linkedDoorRef = refs[2]
	if logLevel2 then
		local action = 'locking'
		if doorRef.locked then
			action = 'unlocking'
		end
		mwse.log('%s: linkedDoorsSync() ab01smtchsPT1 %s "%s" like linked "%s"',
			modPrefix, action, linkedDoorRef.id, doorRef.id)
	end
	linkedDoorRef.lockLevel = doorRef.lockLevel
	if not doorRef.locked then
		tes3.unlock({reference = linkedDoorRef})
		playUnlockSound(doorRef)
	end
	updateDoorData(linkedDoorRef, doorRef.locked)
end

local function linkedDoorsSync(doorRef, linkedDoorRef)
	if not linkedDoors(doorRef, linkedDoorRef) then
		return false
	end
	local locked = tes3.getLocked({reference = doorRef})
	updateDoorData(doorRef, locked)
	local linkedLocked = tes3.getLocked({reference = linkedDoorRef})
	if doorRef.lockNode
	and (not linkedDoorRef.lockNode) then
		local doorRefHandle = tes3.makeSafeObjectHandle(doorRef)
		local linkedDoorRefHandle = tes3.makeSafeObjectHandle(linkedDoorRef)
		tes3.lock({reference = linkedDoorRef}) -- lock to create the lock node if not already present
		timer.start({type = timer.real, duration = 0.4, callback = 'ab01smtchsPT1',
			data = { handles = {doorRefHandle, linkedDoorRefHandle} }
		})
		return true
	end
	updateDoorData(linkedDoorRef, locked) -- fixed 2025-04-29
	if locked == linkedLocked then
		return false
	end
	if logLevel2 then
		local action = 'unlocking'
		if locked then
			action = 'locking'
		end
		mwse.log('%s linkedDoorsSync(): %s "%s" like linked "%s"', modPrefix, action, linkedDoorRef.id, doorRef.id)
	end
	if locked then
		tes3.lock({reference = linkedDoorRef})
	else
		tes3.unlock({reference = linkedDoorRef})
	end
	return true
end

local function ab01smtchsPT2(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	local doorRef = refs[1]
	local linkedDoorRef = refs[2]
	if logLevel2 then
		mwse.log('%s: ab01smtchsPT2 linkedDoorsSync("%s", "%s")',
			modPrefix, doorRef, linkedDoorRef)
	end
	linkedDoorsSync(doorRef, linkedDoorRef)
end

local function unlockIfLocked(doorRef, linkedDoorRef)
	local lockNode = doorRef.lockNode
	if lockNode
	and lockNode.locked
	and (lockNode.level > 0) then
		tes3.unlock({reference = doorRef})
		updateDoorData(doorRef, false)
		if linkedDoorRef then
			local doorRefHandle = tes3.makeSafeObjectHandle(doorRef)
			local linkedDoorRefHandle = tes3.makeSafeObjectHandle(linkedDoorRef)
			timer.start({type = timer.real, duration = 0.4, callback = 'ab01smtchsPT2',
				data = { handles = {doorRefHandle, linkedDoorRefHandle} }
			})
		end
		return true
	end
	return false
end

local math_pi = math.pi
local half_pi = math_pi * 0.5

local function observerCanSeeTargetAtDistance(observerRef, targetRef, distance)
	if not sameCellOrBothExteriors(observerRef.cell, targetRef.cell) then
		return false
	end
	if distance > 8192 then -- at this distance no creature is visible
		return false
	end
	local radAngleTo = observerRef:getAngleTo(targetRef)
	radAngleTo = math.abs(radAngleTo) -- not needed it seems but...
	if radAngleTo < half_pi then
		return tes3.testLineOfSight({reference1 = observerRef,
			reference2 = targetRef})
	end
	return false
end

local function playerCanSeeEnemyAtDistance(enemyRef, distance)
	return observerCanSeeTargetAtDistance(player, enemyRef, distance)
end

local function enemyCanSeePlayerAtDistance(enemyRef, distance)
	return observerCanSeeTargetAtDistance(enemyRef, player, distance)
end

local function ab01smtchsPT3(e)
	local doorRef = getTimerRef(e)
	if not doorRef then
		return
	end
	if logLevel3 then
		mwse.log('%s: ab01smtchsPT3 playDoorCloseSound("%s")', modPrefix, doorRef)
	end
	playDoorCloseSound(doorRef)
end


local function canOpenAutoLockedDoor(doorRef, enemyRef)
	local data = doorRef.data
	if not data then
		return
	end
	local enemyName = enemyRef.object.name
	local doorCell = doorRef.cell
	if doorCell.isInterior
	and string.find(doorCell.id, enemyName, 1, true) then
		return true
	end
	local destination = doorRef.destination
	if not destination then
		return
	end
	local marker = destination.marker
	if not marker then
		return
	end
	if string.find(marker.cell.id, enemyName, 1, true) then
		return true
	end
end

local function doorCanBeOpened(doorRef, enemyMob)
	--[[local doorDest = doorRef.destination
	if doorDest then
		local destMarker = doorDest.marker
		local destCell = destMarker.cell
		local enemyCell = enemyMob.cell
		if not (enemyCell == destCell) then
			return false
		end
	end]]

	local tryUnlock = false
	local lockLevel
	local lockNode = doorRef.lockNode
	if lockNode
	and lockNode.locked then
		lockLevel = lockNode.level
		if lockLevel > 0 then
			tryUnlock = true
		else
			return false
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
	local funcPrefix = modPrefix..': doorCanBeOpened()'

	if enemyMob.actorType == tes3_actorType_npc then
		local key = lockNode.key
		if key
		and enemyRef.object.inventory:contains(key) then
			ok = true
		end
		if not ok then
			ok = canOpenAutoLockedDoor(doorRef, enemyRef)
		end
		if (not ok)
		and config.useLockpicks then
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
						if logLevel1 then
							mwse.log('%s: enemy "%s" managed to pick the "%s" door lock using a "%s"',
								funcPrefix, enemyRefId, doorId, obj.id)
						end
						if config.doorUnlockedMessage then
							tes3ui.showNotifyMenu('%s picked the %s lock', enemyName, doorName)
						end
						doorSound = unlockSound
					elseif logLevel1 then
						mwse.log('%s: enemy "%s" failed picking the "%s" door lock using a "%s"',
							funcPrefix, enemyRefId, doorId, obj.id)
					end -- if roll
				end -- if x > 0
			end -- if obj
		end -- if not ok
	end -- if enemyMob.actorType == tes3_actorType_npc

	if (not ok)
	and config.useMagic then
		local spell, magnitude, chance = getOpenSpell(enemyRef, lockLevel)
		if spell
		and (magnitude >= lockLevel) then
			local roll = math.random(1, 100)
			if roll < chance then
				ok = true
				if logLevel1 then
					mwse.log('%s: enemy "%s" managed to unlock door "%s" using a "%s" spell',
						funcPrefix, enemyRefId, doorId, spell.name)
				end
				if config.doorUnlockedMessage then
					tes3ui.showNotifyMenu('%s used a spell to unlock a %s', enemyName, doorName)
				end
				doorSound = spellSound
			elseif logLevel1 then
				mwse.log('%s: enemy "%s" failed unlocking door "%s" using a "%s" spell',
					funcPrefix, enemyRefId, doorId, spell.name)
			end -- if roll
		end --  if spell
	end -- if not ok

	if (not ok)
	and config.useEnchantment then
		local object, magnitude, castOnce = getOpenEnchantedItem(enemyRef)
		if object then
			if magnitude >= lockLevel then
				ok = true
				if castOnce then
					---mwscript.removeItem({reference = enemyRef, item = object, count = 1})
					tes3.removeItem({reference = enemyRef, item = object, count = 1})
				end
				if logLevel1 then
					mwse.log('%s: enemy "%s" managed to unlock door "%s" using an enchanted "%s"',
						funcPrefix, enemyRefId, doorId, object.name)
				end
				if config.doorUnlockedMessage then
					tes3ui.showNotifyMenu('%s used an enchanteded item to unlock %s', enemyName, doorName)
				end
				doorSound = spellSound
			elseif logLevel1 then
				mwse.log('%s: enemy "%s" failed unlocking door "%s" using an enchanted "%s"',
					funcPrefix, enemyRefId, doorId, object.name)
			end -- magnitude
		end -- if object
	end -- if not ok

	if (not ok)
	and config.useBash then
		local x = enemyMob.strength.current
		if x >= config.minBashingStrength then
			local roll = math.random(60, (lockLevel / 2) + 100)
			if roll < x then
				ok = true -- lock bash
				if logLevel1 then
					mwse.log('%s: enemy "%s" managed to bash door "%s"', funcPrefix, enemyRefId, doorId)
				end
				if config.doorUnlockedMessage then
					tes3ui.showNotifyMenu('%s managed to bash a %s', enemyName, doorName)
				end
				doorSound = bashSound
			elseif logLevel1 then
				mwse.log('%s: enemy "%s" failed bashing door "%s"', funcPrefix, enemyRefId, doorId)
			end -- if roll
		end -- if x
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
		timer.start({duration = 1.5, callback = 'ab01smtchsPT3',
			data = {handle = tes3.makeSafeObjectHandle(doorRef)}
		})
	end

	return ok

end


-- mobile.inCombat alone is not reliable /abot
local function isInCombat(mobile)
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

local function doChase(lcEnemyRefId, doorRef)
	local funcPrefix = modPrefix .. ': doChase()'
	local enemyRef = getActorRef(lcEnemyRefId) -- refresh it for safety
	if not enemyRef then
		if logLevel2 then
			mwse.log('%s callback: enemy ref "%s" not found', funcPrefix, lcEnemyRefId)
		end
		return
	end
	local enemyRefId = enemyRef.id
	local enemyMob = enemyRef.mobile
	if not enemyMob then
		if logLevel2 then
			mwse.log('%s callback: mobile enemy "%s" not found', funcPrefix, lcEnemyRefId)
		end
		return
	end
	local actorType = enemyMob.actorType
	if not actorType then
		if logLevel2 then
			mwse.log('%s callback: mobile enemy actor "%s" not found', funcPrefix, lcEnemyRefId)
		end
		return
	end

	-- refresh them just in case
	local playerCell = player.cell
	local playerPos = player.position

	local enemyCell = enemyRef.cell
	local enemyPos = enemyRef.position
	local doorDest = doorRef.destination

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
					if logLevel2 then
						mwse.log('%s callback: lastDoorLockedPos:distance(player.position) > %s, skip', funcPrefix, chaseMaxDistance)
					end
					return
				end

				if isChaserTooBig(enemyMob, lastDoorLockedRef) then
					return
				end

				if not doorCanBeOpened(lastDoorLockedRef, enemyMob) then
					if logLevel2 then
						mwse.log('%s callback: not doorCanBeOpened("%s", "%s"), skip', funcPrefix, lastDoorLockedRef, enemyRefId)
					end
					return
				end
			end
		end

	end
	-- end locked door management

	if not doorDest then
		if logLevel2 then
			mwse.log('%s callback: "%s" door "%s" has no destination, skip', funcPrefix, enemyRefId, doorRef.id)
		end
		return
	end

	if logLevel4 then
		if lastDoorLockedRef then
			mwse.log('%s callback: destMarkerPos = "%s", lastDoorLockedRef = "%s"',
				funcPrefix,	destMarkerPos, lastDoorLockedRef)
		else
			mwse.log('%s callback: destMarkerPos = "%s"', funcPrefix, destMarkerPos)
		end
	end

	local chaser = chasers[lcEnemyRefId]
	local startCellId = ''
	local startCellPos = enemyPos:copy()

	if chaser then
		if (not enemyCell.isInterior)
		and (not playerCell.isInterior) then -- both enemy and player in exterior
			d = enemyPos:distance(playerPos)
			if d > chaseMaxDistance then
				if logLevel2 then
					mwse.log('%s callback: enemy "%s" dist = %d > max distance = %d, skip', funcPrefix, enemyRefId, d, chaseMaxDistance)
				end
				return
			end
		end
	elseif enemyCell.isInterior then -- chaser not yet defined
		-- store enemy interior cell id before moving the enemy, and only if not already stored
		startCellId = enemyCell.id
	end

	if enemyCell.isInterior
	or playerCell.isInterior then
		local d = enemyPos:distance(destMarkerPos)
		---if d > 64 then
		if d > 128 then
			local pos = destMarkerPos:copy()
			local ori = doorDest.marker.orientation:copy()
			local doorDestCell = doorDest.cell
			local doorRefCell = doorRef.cell
			local doorDestCellEditorName = doorDestCell.editorName
			if not tes3.positionCell({reference = enemyRef, cell = doorDestCell,
					position = pos, orientation = ori}) then
				if logLevel1 then
					mwse.log('%s callback: trying tes3.positionCell({reference = "%s", startCell = "%s", destCell = "%s", position = %s, orientation = %s}) failed',
						funcPrefix, enemyRefId, doorRefCell.editorName, doorDestCellEditorName, pos, ori)
				end
				return
			end
			if logLevel1 then
				mwse.log('%s callback: "%s" followed player through door "%s" from cell "%s" to cell "%s"',
					funcPrefix, enemyRefId, doorRef.id, doorRefCell.id, doorDestCellEditorName)
			end
		end
	end

	local hoursPassedSinceGameStart = getInGameHoursFromGameStart()
	if chaser then -- only update chase starting hour
		chaser.hours = hoursPassedSinceGameStart
	else
		-- store a new chaser
		chasers[lcEnemyRefId] = {cellId = startCellId, pos = startCellPos, hours = hoursPassedSinceGameStart, fight = round(enemyMob.fight)}
	end

	addEnemy(lcEnemyRefId, enemyRef)

	if enemyMob.fight < 100 then
		if actorType == tes3_actorType_npc then
			if not enemyRef.object.isGuard then -- skip messing with guards
				enemyMob.fight = 100
			end
		else
			enemyMob.fight = 100
		end
	end

	if not (enemyMob.actionData.aiBehaviorState == tes3_aiBehaviorState_attack) then
		-- enforce more rapid fight in case
---@diagnostic disable-next-line: param-type-mismatch
		enemyMob:startCombat(mobilePlayer)
		enemyMob.actionData.aiBehaviorState = tes3_aiBehaviorState_attack
	end

	if config.chaseStartMessage then
		d = destMarkerPos:distance(player.position)
		if d < 8192 then
			tes3ui.showNotifyMenu("You can hear %s chasing you!", getActorRefName(enemyRef))
		end
	end

	---updateLastDoorLocked()

end -- doChase()


local function ab01smtchsPT4(e)
	local timer = e.timer
	local data = timer.data
	local handle = data.handle
	local doorRef = handleToRef(handle)
	if not doorRef then
		return
	end
	local lcEnemyRefId = data.lcId
	if logLevel3 then
		mwse.log('%s: ab01smtchsPT4 doChase("%s", "%s")', modPrefix, lcEnemyRefId, doorRef)
	end
	doChase(lcEnemyRefId, doorRef)
end

local function checkDoorChasers(doorRef)
-- called from the door activate event, process enemies table hopefully in the same frame before player changes cell

	local funcPrefix = modPrefix..': checkDoorChasers()'

	if chaseLevel == 0 then
		return
	end

	---if table.empty(enemies) then
	if enemyCount <= 0 then
		if logLevel3 then
			mwse.log("%s: no enemies, skip", funcPrefix)
		end
		return
	end

	---doPackEnemies = true

	local doorDest = doorRef.destination

	local undeadChase = config.undeadChase
	local vampireChase = config.vampireChase

	local dayTime = isDayTime()

	local function processEnemy(lcEnemyRefId)
		local enemyRef = getActorRef(lcEnemyRefId)
		if not enemyRef then
			if logLevel2 then
				mwse.log('%s: enemy ref "%s" not found', funcPrefix, lcEnemyRefId)
			end
			return
		end
		local enemyRefId = enemyRef.id

		if logLevel2 then
			mwse.log('%s: checking enemy "%s"', funcPrefix, enemyRefId)
		end

		local enemyMob = enemyRef.mobile
		if not enemyMob then
			if logLevel2 then
				mwse.log('%s: mobile enemy "%s" not found', funcPrefix, lcEnemyRefId)
			end
			return
		end

		if not isInCombat(enemyMob) then
			if logLevel1 then
				mwse.log('%s: enemy "%s" is not in combat any more, skip', funcPrefix, enemyRefId)
			end
			return
		end

		if not enemyMob.hasFreeAction then -- note docs are wrong this is not a function
			-- dead or paralyzed or stunned or otherwise unable to take action
			if logLevel1 then
				mwse.log('%s: enemy "%s" has no free action, skip', funcPrefix, enemyRefId)
			end
			return
		end

		if isDead(enemyMob) then -- better safe than sorry
			if logLevel1 then
				mwse.log('%s: enemy "%s" is dead, skip', funcPrefix, enemyRefId)
			end
			return
		end

		if chaseLevel <= 2 then
			if not isPlayerDetected(enemyMob) then
				if logLevel1 then
					mwse.log('%s: enemy "%s" cannot detect player, skip', funcPrefix, enemyRefId)
				end
				return
			end
		end

		if isBlacklistedOrNotHandy(enemyMob) then
			return
		end

		if isChaserTooBig(enemyMob, doorRef) then
			return
		end

		local hugeDist = 20000000000
		local dist = hugeDist
		local playerCell = player.cell
		local playerPos = player.position
		if sameCellOrBothExteriors(enemyRef.cell, playerCell) then
			dist = enemyRef.position:distance(playerPos)
			if logLevel2 then
				mwse.log('%s: sameCellOrBothExteriors("%s", "%s", dist = %d',
					funcPrefix, enemyRef.cell, playerCell, dist)
			end
		elseif doorDest then
			if sameCellOrBothExteriors(doorDest.cell, playerCell) then
				local marker = doorDest.marker
				if marker then
					local position = marker.position
					if position then
						dist = position:distance(playerPos)
						if logLevel2 then
							mwse.log('%s: sameCellOrBothExteriors("%s", "%s", dist = %d',
								funcPrefix, doorDest.cell, playerCell, dist)
						end
					end
				end
			end
		end
		if dist >= hugeDist then
			if logLevel1 then
				mwse.log('%s: enemy "%s" distance check failed, skip', funcPrefix, enemyRefId)
			end
			return
		end

		if doorDest
		and doorDest.cell.isOrBehavesAsExterior then
			if (not vampireChase)
			and dayTime
			and (enemyMob.actorType == tes3_actorType_npc)
			and isVampire(enemyRef) then
				if logLevel1 then
					mwse.log('%s: enemy "%s" is vampire, dayTime, skip', funcPrefix, enemyRefId)
				end
				return
			end
			if (not undeadChase)
			and (enemyMob.actorType == tes3_actorType_creature)
			and (enemyMob.object.type == tes3_creatureType_undead)
			and (not enemyMob.cell.isOrBehavesAsExterior) then
				local cellName = enemyMob.cell.id
---@diagnostic disable-next-line: undefined-field
				if string.multifind(string.lower(cellName), {'tomb','burial'}, 1, true) then
					if logLevel2 then
						mwse.log('%s: undead creature "%s" is not following outside "%s", skip', funcPrefix, enemyRefId, cellName)
					end
					return
				end
			end

		end -- if doorDest

		if (chaseLevel == 1)
		and ( not enemyCanSeePlayerAtDistance(enemyRef, dist) ) then
			if logLevel1 then
				mwse.log('%s: enemy "%s" cannot see player at %s distance, skip', funcPrefix, enemyRefId, dist)
			end
			return
		end

		if logLevel3 then
			mwse.log('%s: enemy "%s" dist = %d max dist = %d', funcPrefix, enemyRefId, dist, chaseMaxDistance)
		end

		if (dist > chaseMaxDistance)
		and sameCellOrDifferentKindOfCell(enemyRef.cell, player.cell) then
			if logLevel2 then
				mwse.log('%s: enemy "%s" "%s" dist = %d > max dist = %d, skip', funcPrefix, enemyRefId, dist, chaseMaxDistance)
			end
			return
		end

		if enemyMob.actionData.aiBehaviorState == tes3_aiBehaviorState_flee then
			return
		end


		-- try & follow player through door

		local k = (enemyMob.speed.current + config.delayDivider) * 10
		local dur = (dist / k) + config.minDelay + unlockDelay
		local iter = 2
		if unlockDelay > 0 then
			iter = iter + 1
		end
		---doChase(lcEnemyRefId, doorRef) -- no delay 1st time
		timer.start({duration = dur, iterations = iter, callback = 'ab01smtchsPT4',
			data = {lcId = lcEnemyRefId, handle = tes3.makeSafeObjectHandle(doorRef)}
		})

		if not doorDest then
			if logLevel2 then
				mwse.log('%s: "%s" door %s timer started duration = %s', funcPrefix, enemyRefId, doorRef.id, dur)
			end
			return
		end

		if logLevel2 then
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
			mwse.log('%s: "%s" through door "%s" from cell "%s" to cell "%s" timer started duration = %s',
				funcPrefix, enemyRefId, doorRef.id, start, dest, dur)
		end

	end -- local function processEnemy


	for lcEnemyRefId, _ in pairs(enemies) do
		processEnemy(lcEnemyRefId)
	end

end

local skips = 0
local function ab01smtchsPT5(e)
	local targetRef = getTimerRef(e)
	if not targetRef then
		return
	end
	if logLevel1 then
		mwse.log('%s: ab01smtchsPT5 "%s":activate("%s")',
			modPrefix, player, targetRef)
	end
	skips = 1
	player:activate(targetRef)
end

local function activate(e)
	local doorRef = e.target
	if not (doorRef.baseObject.objectType == tes3_objectType_door) then
		return
	end
	if not (e.activator == player) then
		return
	end
	if logLevel2 then
		mwse.log('%s: "%s" activate("%s") skips = %s',
			modPrefix, e.activator, doorRef, skips)
	end
	if skips > 0 then
		skips = skips - 1
		return
	end
	if linkedDoorsSync(lastDoorLockedRef, doorRef) then
		-- if the linked door is lastDoorLockedRef, copy lock state from it
		-- wait for door to be locked/unlocked like lastDoorLockedRef before re-triggering activation
		timer.start({duration = 0.55, type = timer.real, callback = 'ab01smtchsPT5',
			data = {handle = tes3.makeSafeObjectHandle(doorRef)}
		})
		return false
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
	if not (
		(effectId == tes3_effect_open)
		or (effectId == tes3_effect_lock)
	) then
		return
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

local function moveBackChaser(lcEnemyRefId)
	local funcPrefix = modPrefix .. ' moveBackChaser("' .. lcEnemyRefId .. '"): '
	local enemyRef = getActorRef(lcEnemyRefId)
	if not enemyRef then
		if logLevel2 then
			mwse.log(funcPrefix .. 'enemyRef not found')
		end
		return
	end
	local chaser = chasers[lcEnemyRefId]
	if not chaser then
		if logLevel2 then
			mwse.log(funcPrefix .. 'chaser not found')
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
	local enemyMob = enemyRef.mobile
	if enemyMob
	and chaser.fight then
		enemyMob.fight = chaser.fight
	end
	if config.chaseEndMessage then
		if enemyRef then
			tes3ui.showNotifyMenu("You don't think %s is chasing you any more.",
				getActorRefName(enemyRef))
		end
	end
	if logLevel2 then
		mwse.log(funcPrefix .. 'moved back to ' .. dest)
	end
end

local function ab01smtchsPT6(e)
	local timer = e.timer
	local data = timer.data
	local lcEnemyRefId = data.lcId
	if logLevel3 then
		mwse.log('%s: ab01smtchsPT6 moveBackChaser("%s")', modPrefix, lcEnemyRefId)
	end
	moveBackChaser(lcEnemyRefId)
end

--[[local function samePCCell(ref)
	local cell = ref.cell
	local playerCell = player.cell
	if cell == playerCell then
		return true
	end
	if cell.isExterior
	and playerCell.isExterior then
		return true
	end
end]]

local function updateEnemiesAndChasers()
	---local playerCell = player.cell
	local hoursPassedSinceGameStart = getInGameHoursFromGameStart()
	local chaseMaxHours = config.chaseMaxHours

	local funcPrefix = modPrefix..' updateEnemiesAndChasers()'

	local activeChasers = {}

	local dayTime = isDayTime()

	local enemyRef, enemyMob -- updated by processChaserWithDelay

	---local chaseEndMessage = config.chaseEndMessage

	local function processChaserWithDelay(lcEnemyRefId, chaser)

		enemyRef = getActorRef(lcEnemyRefId)

		if not enemyRef then
			local baseObj = tes3.getObject(lcEnemyRefId)
			if not baseObj then
				if logLevel1 then
					mwse.log('%s: WARNING tes3.getObject("%s") failed', funcPrefix, lcEnemyRefId)
				end
			---elseif chaseEndMessage then
				---tes3ui.showNotifyMenu( "You don't think %s is chasing you any more.",
					---getActorName(baseObj) )
			end
			---if removeEnemy(lcEnemyRefId) then
				---doPackEnemies = true
			---end
			removeEnemy(lcEnemyRefId)
			if logLevel2 then
				if chaser.cellId == '' then
					mwse.log('%s: stored chaser "%s" not found', funcPrefix, lcEnemyRefId)
				else
					mwse.log('%s: stored chaser "%s".cellId ("%s") not found', funcPrefix, lcEnemyRefId, chaser.cellId)
				end
			end
			return false
		end

		local dist = player.position:distance(enemyRef.position)

		if logLevel1 then
			mwse.log('%s: "%s" initial cell "%s" dist = %d',
				funcPrefix, lcEnemyRefId, chaser.cellId, dist)
		end

		enemyMob = enemyRef.mobile
		if not enemyMob then
			if logLevel1 then
				mwse.log('%s: "%s".mobile not available',
					funcPrefix, lcEnemyRefId)
			end
			return false
		end
		local mobCell = enemyRef.cell

		if isPlayerDetected(enemyMob)
		or enemyCanSeePlayerAtDistance(enemyRef, dist)
		or playerCanSeeEnemyAtDistance(enemyRef, dist) then

			if dayTime
			and mobCell.isOrBehavesAsExterior
			and isVampire(enemyRef) then
				if logLevel3 then
					mwse.log('%s: isVampire("%s")', funcPrefix, lcEnemyRefId)
				end
				if enemyMob.health.normalized < 0.9 then
					if logLevel3 then
						mwse.log('%s: "%s".health.normalized < 0.9', funcPrefix, lcEnemyRefId)
					end
					if enemyMob.hasFreeAction
					and ( not isDead(enemyMob) ) then
						if logLevel2 then
							mwse.log('%s: "%s" teleporting away', funcPrefix, lcEnemyRefId)
						end
---@diagnostic disable-next-line: param-type-mismatch
						enemyMob:stopCombat(true)
						-- a cheap on touch one
						tes3.cast({target = enemyRef, reference = enemyRef, spell = 'touch dispel'})
						return true
					end
				end
			end

			if logLevel2 then
				mwse.log('%s: player can see "%s" at %s distance, no reset', funcPrefix, lcEnemyRefId, dist)
			end
			activeChasers[lcEnemyRefId] = chaser
			addEnemy(lcEnemyRefId, enemyRef)
			return false
		end

		if dist > chaseMaxDistance then
			---if playerCell.isInterior == mobCell.isInterior then
				if logLevel2 then
					mwse.log('%s: "%s" dist = %d > max dist = %d, reset', funcPrefix, lcEnemyRefId, dist, chaseMaxDistance)
				end
				return false
			---end
		end

		if not enemyMob.hasFreeAction then --  paralyzed, dead, stunned, or otherwise unable to take action
			mwse.log('%s: enemy "%s" is not in combat any more, reset', funcPrefix, lcEnemyRefId)
			return false
		end

		if (chaseLevel <= 2)
		and ( not isPlayerDetected(enemyMob) ) then
			if logLevel1 then
				mwse.log('%s: enemy "%s" cannot detect player, reset', funcPrefix, lcEnemyRefId)
			end
			return false
		end

		if dayTime
		and mobCell.isOrBehavesAsExterior
		and isVampire(enemyRef) then
			if logLevel1 then
				mwse.log('%s: enemy "%s" is vampire, dayTime, reset', funcPrefix, lcEnemyRefId)
			end
			return false
		end

		local hoursDiff = hoursPassedSinceGameStart - chaser.hours
		if hoursDiff > chaseMaxHours then
			if logLevel2 then
				mwse.log('%s: %s hours passed since "%s" started combat, reset', funcPrefix, hoursDiff, lcEnemyRefId)
			end
			return false
		end

		activeChasers[lcEnemyRefId] = chaser
		addEnemy(lcEnemyRefId, enemyRef)
		return false
	end -- local function processChaser


	local delay
	for lcEnemyRefId, chaser in pairs(chasers) do
		if chaser then
			delay = processChaserWithDelay(lcEnemyRefId, chaser)
			if delay
			or (not activeChasers[lcEnemyRefId]) then
				local enRef = getActorRef(lcEnemyRefId)
				if enRef then
					local enMob = enRef.mobile
					if enMob
					and enMob.hasFreeAction
					and ( not isDead(enMob) ) then
						if delay then
							timer.start({duration = 2.5, callback = 'ab01smtchsPT6',
								data = {lcId = lcEnemyRefId}
							})
						else
							moveBackChaser(lcEnemyRefId)
						end
					end
				end
			end
		end
	end
	chasers = activeChasers

---@diagnostic disable-next-line: undefined-field
	if table.empty(chasers) then
		clearEnemies()
	---elseif doPackEnemies then
		---packEnemies()
	end

end


local function magicCasted(e)
	if not (e.caster == player) then
		return
	end
	local exteriorLike = player.cell.isOrBehavesAsExterior
	local source = e.source
	local effects = source.effects
	local eff, id
	for i = 1, #effects do
		eff = effects[i]
		id = eff.id
		if (id == tes3_effect_open)
		or (id == tes3_effect_lock) then
			if logLevel3 then
				mwse.log('\n%s: magicCasted(), magic = "%s"', modPrefix, source)
			end
			spellTicked = false
			return
		end
		if (id == tes3_effect_recall)
		or (id == tes3_effect_almsiviIntervention)
		or (id == tes3_effect_divineIntervention) then
			if exteriorLike then
				return -- skip as it will be handled by cellChanged()
			end
			timer.start({duration = 1, callback = updateEnemiesAndChasers})
			if logLevel3 then
				mwse.log('\n%s: magicCasted(), magic = "%s"', modPrefix, source)
			end
			return
		end
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

--- @param e objectInvalidatedEventData
local function objectInvalidated(e)
	if not (type(e.object) == 'userdata') then
		return -- bah hopefully this will be enough to skip weird data
	end
	local obj = e.object -- should be a tes3baseObject or a tes3reference
	if not obj then
		return
	end
	-- WTF how can e.object.id be nil/invalid? still it may happen
	local id = obj.id
	if not id then
		return
	end
	local lcObjId = string.lower(id)
	if not removeEnemy(lcObjId) then
		return
	end
	if logLevel2 then
		mwse.log('%s: objectInvalidated() enemies["%s"] dead or deleted',
			modPrefix, lcObjId)
	end
	---doPackEnemies = true
end

local function table2vec(t)
	return tes3vector3.new(t[1], t[2], t[3])
end

local function vec2table(v)
	return {round(v.x), round(v.y), round(v.z)}
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

local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	timer.register('ab01smtchsPT1', ab01smtchsPT1)
	timer.register('ab01smtchsPT2', ab01smtchsPT2)
	timer.register('ab01smtchsPT3', ab01smtchsPT3)
	timer.register('ab01smtchsPT4', ab01smtchsPT4)
	timer.register('ab01smtchsPT5', ab01smtchsPT5)
	timer.register('ab01smtchsPT6', ab01smtchsPT6)

	event.register('combatStarted', combatStarted)
	event.register('death', death)
	event.register('objectInvalidated', objectInvalidated)

	-- higher priority than More Traps!!!
	event.register('activate', activate, {priority = 2000010})

	event.register('magicCasted', magicCasted) -- spells, alchemy and enchanted items
	event.register('spellTick', spellTick)
	event.register('save', save)
	event.register('cellChanged', cellChanged)
	---event.register('spellResist', spellResistVampireSunDamage, {source = vampireSunDamage})
	---event.register('damage', damage)
	---logConfig(config, {indent = false})
end

local function clearEnemiesAndChasers()
	chasers = {}
	clearEnemies()
	lastDoorLockedId = nil
	lastDoorLockedRef = nil
	spellTicked = false
	unlockDelay = 0
end

local function loaded(e)
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	assert(worldController == tes3.worldController)
	tes3gmst_fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult)
	clearEnemiesAndChasers()
	initOnce()

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

	local numChasers = 0
	local ab01chasers = data.ab01chasers
	if ab01chasers then
		for k, v in pairs(ab01chasers) do
			if getActorRef(k) then
				chasers[k] = {cellId = v.cellId, pos = table2vec(v.pos), hours = v.hours}
				numChasers = numChasers + 1
			end
		end
	end

	if numChasers <= 0 then
		if logLevel3 then
			mwse.log("%s: loaded() chasers table empty", modPrefix)
		end
		return
	end

	-- dalayed to give the AI enough time to update
	timer.start({duration = 3 + math.random(), callback = updateEnemiesAndChasers})
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

local function onClose()
	updateFromConfig()
	if resetChasers then
		resetChasers = false
		clearEnemiesAndChasers()
	elseif tes3.player then
		updateEnemiesAndChasers()
	end
	mwse.saveConfig(configName, config, {indent = true})
end

local function modConfigReady()

	local usage = [[\nEnemies will try and use their available tools/abilities to open the linked doors if locked
by player nusing locking magic (e.g. Fenrick's Doorjam spell) or the door key if available.
Compatible with my Loading Doors linked doors synchronization mod.]]

	local delayFormulaDescr = [[Formula is:
Delay before chasing player through doors = distanceFromPlayerAtCombatStart / ( (enemySpeed + delayDivider) * 10 ) + minDelay (+ unlockDelay if locked)
So e.g. with minDelay 3, delayDivider 50 an enemy having 50 speed, 2048 units away from player will take
2048 / ( (50 + 50) * 10 ) + 3 = about 5 sec to chase the player through a loading door.]]
	local chaseMsgDescr = [[Allow in game messages when relevant chasers actions happen.]]

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	-- Preferences Page
	local sideBarPage = template:createSideBarPage({
		label = modName,
		showHeader = false,
		---description = [[Makes actors shift it.]],
		showReset = true,
		postCreate = function(self)
			local width1 = 1.2
			local width2 = 2 - width1 -- total width must be 2
			local sideBlock = self.elements.sideToSideBlock
			sideBlock.children[1].widthProportional = width1
			sideBlock.children[2].widthProportional = width2
		end
	})

	local sidebar = sideBarPage.sidebar
	sidebar:createInfo{text = [[Makes enemies able to follow you through loading doors.
Saves enemy state and resets enemy position when done.
It should allow player to try and lock enemies inside using lock spells/door key with the linked outside door.
Some enemies may be able to unlock/bash the door though.
Notes:
Changes to chasing state are usually triggered before saving, after reloading, after crossing exterior cells borders.
By default vampires will not follow you outside in broad daylight but you may still be able to lure them out during sunrise/dawn change time.
Sometimes vampire powers/sun damaged are not applied correctly in game so you may want to enable the available fix for that.]]}

	sideBarPage:createSlider({
		label = 'Min delay %s sec',
		configKey = 'minDelay'
		,min = 2, max = 10, step = 1, jump = 2,
		description = [[Minimum delay (in seconds) before enemy may follow you through a loading door.
It makes sense to set it high enough (e.g. 3 sec) to give player enough time to cast a lock spell on exterior door to try and lock in enemies.]]..delayFormulaDescr
	})

	sideBarPage:createSlider({
		label = 'Extra unlock delay %s',
		configKey = 'unlockDelay'
		,min = 0, max = 10, step = 1, jump = 2,
		description = [[Minimum extra delay (in seconds) before enemy may follow you through a locked loading door.]]..delayFormulaDescr
	})

	sideBarPage:createSlider({
		label = 'Delay divider %s',
		configKey = 'delayDivider'
		,min = 1, max = 200, step = 1, jump = 5,
		description = [[Delay divider.
The higher Delay divider, the faster enemies will be able to chase you through doors.]]..delayFormulaDescr
	})

	sideBarPage:createSlider({
		label = 'Max chase duration (hours) %s',
		configKey = 'chaseMaxHours'
		,min = 1, max = 71, step = 1, jump = 5,
		description = [[Max chase duration (hours).
Max hours before enemies will give up chasing you. You may want to tweak this according to your TimeScale settings.]]..delayFormulaDescr
	})

	sideBarPage:createYesNoButton({
		label = 'Vampires chase outside in full daylight',
		configKey = 'vampireChase',
		description = [[Allow vampire enemies to chase player outside in full daylight.]]..delayFormulaDescr
	})

	sideBarPage:createYesNoButton({
		label = 'Fix vampire spells if missing',
		configKey = 'fixMissingVampireSpells',
		description = [[Fix vampire spells if missing (e.g. missing Vampire Sun Damage and vampire stats increase).
Note that this may make some low level vampires more dangerous but extremely vulnerable to sun light.]]
	})

--- nope changing damage does not work
--- 	sideBarPage:createSlider({
--- 		label = 'Sun Damage Killing Time (sec)',
--- 		configKey = 'sunDamageKillingTime'
--- 		,min = 0, max = 200, step = 1, jump = 5,
--- 		description = [[0 = not changed from vanilla.
--- Average time in seconds needed for Sun Damage to kill a (non player) vampire.
--- It makes sense to set it > 0 if you use the "Fix vampire spells if missing" so low level vampires are not killed by Sun Damage in 5 seconds.]])
--- 	})

	sideBarPage:createYesNoButton({
		label = 'Tomb undeads chase outside',
		configKey = 'undeadChase',
		description = [[Allow non-vampire undead enemies protecting tombs to chase player outside.]]
	})
	sideBarPage:createYesNoButton({
		label = 'Creatures too big to pass through door frame cannot follow',
		configKey = 'checkEnemySize',
		description = [[Disallow creatures too big to pass through door frame to follow player.]]
	})
	sideBarPage:createYesNoButton({
		label = 'Only handy creature can open doors',
		configKey = 'checkHandy',
		description = [[Disallow non-handy creatures to open/follow through doors.]]
	})

	sideBarPage:createYesNoButton({
		label = 'Use lockpicks',
		configKey = 'useLockpicks',
		description = [[Enemies can use their lockpicks and thieving skills to try and unlock a loading door.]]..usage
	})

	sideBarPage:createYesNoButton({
		label = 'Use magic',
		configKey = 'useMagic',
		description = [[Allow enemies to use their known open spells (e.g. Ondusi's Open Door)
		to try and unlock a loading door.]]..usage
	})

	sideBarPage:createYesNoButton({
		label = 'Use magicka',
		configKey = 'checkMagicka',
		description = [[Enemy magicka will influence enemy chance to successfully cast open spells.
		Needs "Use magic" enabled too to be effective.
		As game AI usually consumes magicka mostly for offensive spells, this can make low level enemy casters
		more effective at using open spells to unlock doors.]]..usage
	})

	sideBarPage:createYesNoButton({
		label = 'Use enchanted items',
		configKey = 'useEnchantment',
		description = [[Allow enemies to use enchanted items (e.g. Scroll of Ekash's Lock Splitter)
		to try and unlock a loading door.]]..usage
	})

	sideBarPage:createYesNoButton({
		label = 'Use bash',
		configKey = 'useBash',
		description = [[Allow high strength enemies to try and bash a locked loading door.]]..usage
	})

	sideBarPage:createSlider({
		label = 'Min. Bashing Strength',
		configKey = 'minBashingStrength'
		,min = 50, max = 200, step = 1, jump = 5,
		description = [[Minimum strength needed to bash a door.]]
	})

	sideBarPage:createYesNoButton({
		label = 'End chase message',
		configKey = 'chaseEndMessage',
		description = chaseMsgDescr
	})
	sideBarPage:createYesNoButton({
		label = 'Start chase message',
		configKey = 'chaseStartMessage',
		description = chaseMsgDescr
	})
	sideBarPage:createYesNoButton({
		label = 'Door unlocked message',
		configKey = 'doorUnlockedMessage',
		description = chaseMsgDescr
	})

	sideBarPage:createDropdown({
		label = 'Chase level:',
		options = {
			{ label = '0. Chase disabled', value = 0 },
			{ label = '1. Only when able to see player', value = 1 },
			{ label = '2. Only when able to detect player', value = 2 },
			{ label = '3. Only in AI range', value = 3 },
			{ label = '4. Only in max chase distance', value = 4 },
		},
		configKey = 'chaseLevel',
		description = [[Limit enemies ability to chase player through loading doors:
1. Only when able to see player = only if they can see you
2. Only when able to detect player = only if they can detect you
3. Only in AI range = only if they are in AI distance range (for this setting to work you should set the standard game AI distance slider to the max = about 7000 game units.)
4. Only in max chase distance = only if they are in max chase distance range. This is the suggested setting coupled with at least default max chase distance.]]
	})

	sideBarPage:createDropdown({
		label = 'Logging level:',
		options = {
			{ label = '0. Off', value = 0 },
			{ label = '1. Low', value = 1 },
			{ label = '2. Medium', value = 2 },
			{ label = '3. High', value = 3 },
			{ label = '4. Max', value = 4 },
		},
		configKey = 'logLevel',
		description = [[Debug logging level.]]
	})

	sideBarPage:createSlider({
		label = 'Max chase distance %s',
		configKey = 'chaseMaxDistance'
		,min = 4096, max = 98304, step = 1, jump = 128,
		description = [[Max chase distance.
Only effective when previous "Chase level" option is set to "4. Only in max chase distance".]]
	})

	sideBarPage:createSlider({
		label = 'Max follower distance from player %s',
		configKey = 'followerMaxPlayerDistance'
		,min = 0, max = 4096, step = 1, jump = 128,
		description = [[Max distance from player or from a player follower to be possibly chased.']]
	})

	if logLevel4 then
		sideBarPage:createButton({
			label = 'WARNING meant to be used only if you know what you are doing',
			buttonText = 'Reset stored chasers/enemies',
			description = [[Only available when Logging level is set to Max.
Meant to be used only if you want to clean a saved game from the mod data.
This button will clean stored enemies starting cell coordinates, so after pressing it you can save the game to a clean state.
Before using it though be aware that if you have still some enemies out there currently chasing you,
they will not be able to go back to original starting cells automatically any more.]],
			callback = function()
				resetChasers = true
			end,
		})
	end
	mwse.mcm.register(template)
end
-- happens before initialized()
event.register('modConfigReady', modConfigReady)

event.register('initialized', function ()
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
	---assert(worldController)

	updateFromConfig() -- moved here as we need to wait for processManager initialized

	unlockSound = tes3.getSound('Open Lock')
	bashSound = tes3.getSound('Pack')
	spellSound = tes3.getSound('alteration hit')
	---sunDamageMagicEffect = tes3.getMagicEffect(tes3.effect.sunDamage)
	---assert(sunDamageMagicEffect)

	event.register('loaded', loaded)
end, {doOnce = true})