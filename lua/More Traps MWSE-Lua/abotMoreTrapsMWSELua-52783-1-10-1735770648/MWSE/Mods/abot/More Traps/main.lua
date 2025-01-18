local defaultConfig = {
lockChance = 50, -- chance to lock a suitable door
lockContChance = 50, -- chance to lock a suitable container
trapChance = 33, -- chance to trap a suitable door
trapContChance = 33, -- chance to trap a suitable container
spawnChance = 50, -- chance for non-direct damage traps to spawn a leveled critter
leveledTraps = 3, -- 0 = Unleveled, 1 = by Player Level, 2 = by Lock level, 3 = by Player and Lock level
lockTierStep = 20, -- 10 <= lockTierStep <= 25, 0 <= lockTier <= 3, lockLevel = (lockTier + 1) * lockTierStep
skipPersistent = true,
skipScripted = false,
trapDwemerBarrels = true,
lockDwemerBarrels = true,
trapBarrels = true,
lockBarrels = false,
interiorsOnly = false,
trapUrns = true,
lockUrns = false,
trapJars = true,
lockJars = false,
trapDesks = true,
lockDesks = true,
trapClosets = true,
lockClosets = true,
trapTables = true,
lockTables = true,
trapCrates = true,
lockCrates = false,
trapBaskets = false,
lockBaskets = false,
skipRestingIsIllegal = false,
skipExteriors = false,
trappedHint = 0, -- 0 = Off, 1 = Skill based, 2 = Always
trapDetectThreshold = 75, -- trap detection skill threashold
logLevel = 0, -- 0 = Off, 1 = Low, 2 = Medium, 3 = High, 4 = Very High, 5 = Max
debugLevel = 0, -- 0 = off, 1 = doors, 2 = doors, containers
}

local author = 'abot'
local modName = 'More Traps'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)
local trappedHint = 0
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4, logLevel5
local debugLevel = config.debugLevel

local idHelpMenu_name = tes3ui.registerID('HelpMenu_name')

-- reset in loaded()
local lastActivatedRef
local tes3gmst_fPickLockMult, tes3gmst_fTrapCostMult

local LnTDLockData = include('AdituV.DetectTrap.LockData')
if LnTDLockData then
	event.register('modConfigReady', function()
		local LnTDConfig = require('AdituV.DetectTrap.Config')
		if LnTDConfig
		and LnTDConfig.modEnabled then
			return
		end
		LnTDLockData = nil
	end)
end

local function uiObjectTooltip(e)
	--[[if trappedHint < 1 then
		return
	end]]
	local ref = e.reference
	if not ref then
-- Only valid for in-world objects. For inventory tiles it will always be nil
		return
	end
	local lockNode = ref.lockNode
	if not lockNode then
		return
	end
	local trap = lockNode.trap
	if not trap then
		return
	end
	local data = ref.data
	if not data then
		return
	end
	local ab01mt = data.ab01mt
	if not ab01mt then
		return
	end
	if ab01mt < 4 then
		return
	end
	local el = e.tooltip:findChild(idHelpMenu_name)
	if not el then
		return
	end
	local s, hint
	if ab01mt >= 7 then
		s = trap.name
		hint = '\n("' .. s .. '" detected)'
	else
		s = 'trapped'
		hint = ' ('..s..')'
	end
	if string.find(string.lower(el.text), string.lower(s), 1, true) then
		return
	end
	el.text = el.text .. hint
end

local function updateFromConfig() -- used in modConfigReady template.onClose
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	logLevel5 = logLevel >= 5
	if not (config.trappedHint == trappedHint) then
		trappedHint = config.trappedHint
		if event.isRegistered('uiObjectTooltip', uiObjectTooltip) then
			if trappedHint < 1 then
				event.unregister('uiObjectTooltip', uiObjectTooltip)
			end
		elseif trappedHint >= 1 then
			event.register('uiObjectTooltip', uiObjectTooltip)
		end
	end
	debugLevel = config.debugLevel
end
updateFromConfig()

local tes3_objectType_container = tes3.objectType.container
local tes3_objectType_door = tes3.objectType.door

local cellsBlackList = {'corprusarium','galerion'}

local function isCellBlacklisted(cell)
	local cellName = string.lower(cell.editorName)
	local s
	for i = 1, #cellsBlackList do
		s = cellsBlackList[i]
		if string.startswith(cellName, s) then
			return true
		end
	end
	return false
end

local targetsBlackList = {'chargen','ladder','invhlp'}

local function isTargetBlacklisted(lcObjId)
	local s
	for i = 1, #targetsBlackList do
		s = string.lower(targetsBlackList[i])
		if string.find(lcObjId, s, 1, true) then
			return true
		end
	end
	return false
end

local T3E = tes3.effect
local spawningEffectsDict = table.invert(
{T3E.blind, T3E.damageFatigue, T3E.drainFatigue,
T3E.drainAttribute,T3E.paralyze, T3E.silence, T3E.sound}
)

--[[
note: Ondusi's Unhinging scrolls (Open 40-60) are available in leveled lists at player level 6,
Ekash's Lock Slitter scrolls (Open 100) are available in leveled lists at player level 11
]]
local trapSpellsDict = {
["alad's caliginy"] = {minPlayerLvl = 1, minLockTier = 0},
["armor eater"] = {minPlayerLvl = 1, minLockTier = 0},
["clumsy touch"] = {minPlayerLvl = 1, minLockTier = 0},
["cruel noise"] = {minPlayerLvl = 1, minLockTier = 0},
["crushing burden touch"] = {minPlayerLvl = 1, minLockTier = 0},
["deadly poison"] = {minPlayerLvl = 11, minLockTier = 3},
["dread curse: agility"] = {minPlayerLvl = 1, minLockTier = 0},
["dread curse: personality"] = {minPlayerLvl = 1, minLockTier = 0},
["dread curse: willpower"] = {minPlayerLvl = 1, minLockTier = 0},
["flay spirit"] = {minPlayerLvl = 1, minLockTier = 0},
["knuckle luck"] = {minPlayerLvl = 1, minLockTier = 0},
["potent poison"] = {minPlayerLvl = 6, minLockTier = 2},
["trap_fire00"] = {minPlayerLvl = 6, minLockTier = 2},
["trap_fire_killer"] = {minPlayerLvl = 11, minLockTier = 3},
["trap_frost00"] = {minPlayerLvl = 6, minLockTier = 2},
["trap_frost_killer"] = {minPlayerLvl = 11, minLockTier = 3},
["trap_health00"] = {minPlayerLvl = 6, minLockTier = 2},
["trap_paralyze00"] = {minPlayerLvl = 1, minLockTier = 0},
["trap_poison00"] = {minPlayerLvl = 1, minLockTier = 1},
["trap_poison_killer"] = {minPlayerLvl = 11, minLockTier = 3},
["trap_shock00"] = {minPlayerLvl = 6, minLockTier = 2},
["trap_shock_killer"] = {minPlayerLvl = 11, minLockTier = 3},
["trap_silence00"] = {minPlayerLvl = 1, minLockTier = 0},
["weapon eater"] = {minPlayerLvl = 1, minLockTier = 0},
}
local trapSpellsArray = {}
for k, _ in pairs(trapSpellsDict) do
	table.insert(trapSpellsArray, k)
end
table.sort(trapSpellsArray)

local function getTimerRefs(e)
	local data = e.timer.data
	local handles = data.handles
	local refs = {}
	for i = 1, #handles do
		local handle = handles[i]
		if not handle then
			return
		end
		if not handle.valid then
			return -- it happens /abot
		end
		if not handle:valid() then
			return
		end
		refs[i] = handle:getObject()
	end
	if #refs == #handles then
		return refs
	end
	return
end

local function createReference(casterRef, targetRef, obj)
	local casterPos = casterRef.position
	local targetPos = targetRef.position
	local refPos = targetPos:copy()
	refPos.x = ((3 * targetPos.x) - casterPos.x) * 0.5
	refPos.y = ((3 * targetPos.y) - casterPos.y) * 0.5
	local ref = tes3.createReference({object = obj, position = refPos,
		orientation = targetRef.orientation:copy(), cell = targetRef.cell})
	if ref then
		---local heightVec = tes3vector3.new(0, 0, 48)
		local height = 48
		if not tes3.testLineOfSight({reference1 = ref, reference2 = targetRef, position1 = ref.position,
			---height1 = heightVec, position2 = targetPos, height2 = heightVec}) then
			height1 = height, position2 = targetPos, height2 = height}) then
				refPos.x = (targetPos.x + refPos.x) * 0.5
			refPos.y = (targetPos.y + refPos.y) * 0.5
		end
	end
	if logLevel1 then
		mwse.log('%s: createReference("%s", "%s", "%s") = "%s"', modPrefix, casterRef, targetRef, obj, ref)
	end
	return ref
end

local levCreaId
local function createLeveledCreature(casterRef, targetRef)
	local levCreaList = tes3.getObject(levCreaId)
	local skip = true
	local levCreaObj
	for _ = 1, 10 do
		levCreaObj = levCreaList:pickFrom()
		if levCreaObj.health >= 10 then
			skip = false
			break
		end
	end
	if skip then
		return
	end
	if logLevel1 then
		mwse.log('%s: createLeveledCreature("%s", "%s") = %s', modPrefix, casterRef, targetRef, levCreaObj)
	end
	return createReference(casterRef, targetRef, levCreaObj)
end

local function ab01motrpPT1(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	createLeveledCreature(refs[1], refs[2])
end

local function delayedSpawn(casterRef, targetRef, delaySec)
	local casterHandle = tes3.makeSafeObjectHandle(casterRef)
	local targetHandle = tes3.makeSafeObjectHandle(targetRef)
	timer.start({duration = delaySec, callback = 'ab01motrpPT1',
		data = { handles = {casterHandle, targetHandle} }
	})
end

local function spellResist(e)
	---mwse.log(tableToStr(e))
	local source = e.source
	if not source then
		return
	end
	local target = e.target
	if not target then
		return
	end
	if not trapSpellsDict[source.id:lower()] then
		return
	end
	if not lastActivatedRef then
		return
	end
	local effect = e.effect
	if logLevel2 then
		mwse.log('%s spellResist(e): target = "%s", spell = "%s" "%s", effect = %s "%s"',
			modPrefix, target.id, source.id, source.name, effect.id, effect.object.name)
	end
	if not spawningEffectsDict[effect.id] then
		return
	end
	if config.spawnChance < math.random(100) then
		return
	end
	local lcObjId = string.lower(lastActivatedRef.object.id)
	local s = 'dae'
	if string.multifind(lcObjId, {'dwrv', 'dwem', 'dwar'}, 1, true) then
		s = 'dwe'
	elseif string.multifind(lcObjId, {'tomb', 'urn'}, 1, true) then
		s = 'tomb'
	end
	---levCreaId = -- BAH 'in_%s_all_lev+2'leveled list does not work
	levCreaId = string.format('in_%s_all_lev+0', s)
	local sprigganupObj = tes3.getObject('sprigganup')
	if sprigganupObj then
		createReference(lastActivatedRef, target, sprigganupObj)
	end
	delayedSpawn(lastActivatedRef, target, 1) -- sprigganup effect takes 2 sec to complete
end

local skips = 0 -- reset in loaded()

local function loaded()
	lastActivatedRef = nil
	skips = 0
	tes3gmst_fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult)
	tes3gmst_fTrapCostMult = tes3.findGMST(tes3.gmst.fTrapCostMult)
end

local function ab01motrpPT2(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	local activatorRef = refs[1]
	local targetRef = refs[2]
	if logLevel1 then
		mwse.log('%s: ab01motrpPT2() "%s":activate("%s")', modPrefix, activatorRef, targetRef)
	end
	skips = 1
	activatorRef:activate(targetRef)
end

local function delayedActivate(activator, target, delaySec)
	local activatorHandle = tes3.makeSafeObjectHandle(activator)
	local targetHandle = tes3.makeSafeObjectHandle(target)
	timer.start({duration = delaySec, type = timer.real, callback = 'ab01motrpPT2',
		data = { handles = {activatorHandle, targetHandle} }
	})
end

local function getActiveCellsCulled(ref, maxDistanceFromRef)
-- active cells matrix example:
-- ^369
-- |258
-- |147
-- +----->
-- example
-- [1] = -3, -10 [2] = -3, -9 [3] = -3, -8
-- [4] = -2, -10 [5] = -2, -9 [6] = -2, -8
-- [7] = -1, -10 [8] = -1, -9 [9] = -1, -8
-- try marking cells that can be skipped

	local cells = {}

	local cell = ref.cell
	if cell.isInterior then
		cells[1] = cell
		return cells
	end

	if not maxDistanceFromRef then
		maxDistanceFromRef = 11585 -- math.floor(math.sqrt(8192*8192*2) + 0.5)
	elseif maxDistanceFromRef > 34756 then -- math.floor(math.sqrt((3*8192)*(3*8192)*2) + 0.5)
		maxDistanceFromRef = 34756
	end
	---assert(ref)
	local skip = {}
	local x = ref.position.x
	local y = ref.position.y
	local cellGridX = cell.gridX
	local cellGridY = cell.gridY

	local x0 = cellGridX * 8192
	local y0 = cellGridY * 8192
	local x1 = x0 + 8191
	local y1 = y0 + 8191

	-- skip cells depending on distance of target marker from cell borders
	local dx = x1 - x
	if dx > maxDistanceFromRef then
		skip[7] = true
		skip[8] = true
		skip[9] = true
	end

	dx = x - x0
	if dx > maxDistanceFromRef then
		skip[1] = true
		skip[2] = true
		skip[3] = true
	end

	local dy = y1 - y
	if dy > maxDistanceFromRef then
		skip[3] = true
		skip[6] = true
		skip[9] = true
	end
	dy = y - y0
	if dy > maxDistanceFromRef then
		skip[1] = true
		skip[4] = true
		skip[7] = true
	end

	local ac = tes3.getActiveCells()
	local c
	local j = 0
	for i = 1, 9 do
		c = ac[i]
		if not skip[i] then
			j = j + 1
			cells[j] = c
			---mwse.log("culledCell = %s", c.editorName)
		end
	end

	if (j == 0)
	or logLevel2 then
		local msg = "%s: getActiveCellsCulled(ref = %s, maxDistanceFromRef = %s)"
		if j == 0 then
			msg = msg .. " no cells found!"
		end
		mwse.log(msg, modPrefix, ref, maxDistanceFromRef)
	end

	return cells
end

local justLocked = false
local justTrapped = false

local tes3_objectType_activator = tes3.objectType.activator
local tes3_objectType_npc = tes3.objectType.npc
local tes3_objectType_creature = tes3.objectType.creature
local checkTypes = {tes3_objectType_npc, tes3_objectType_creature, tes3_objectType_activator}

local function arrayChoice(a)
	return a[math.random(#a)]
end

local function getTrapSpellId(lockTier)
	 -- 0 = Unleveled, 1 = by Player Level, 2 = by Lock level, 3 = by Player and Lock level
	local leveledTraps = config.leveledTraps
	if leveledTraps == 0 then
		return arrayChoice(trapSpellsArray)
	end
	local trapSpells = {}
	local playerLvl = tes3.player.object.level
	local notByPlayerLvl = (leveledTraps == 2)
	local notByLockLvl = (leveledTraps == 3)
	local i = 0
	for k, v in pairs(trapSpellsDict) do
		if notByPlayerLvl
		or (playerLvl >= v.minPlayerLvl) then
			if notByLockLvl
			or (lockTier >= v.minLockTier) then
				i = i + 1
				trapSpells[i] = k
				if logLevel4 then
					mwse.log('%s: getTrapSpellId() trapSpells[%s] = "%s" found for lockTier = %s, playerLvl = %s',
						modPrefix, i, k, lockTier, playerLvl)
				end
			end
		end
	end
	if i <= 0 then
		if logLevel1 then
			mwse.log('%s: WARNING getTrapSpellId() unable to find trap spell for lockTier = %s, playerLvl = %s',
				modPrefix, lockTier, playerLvl)
		end
		return arrayChoice(trapSpellsArray)
	end
	return arrayChoice(trapSpells)
end

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local function getSecurityPassed(target)
	local lockNode = target.lockNode
	if not lockNode then
		return 0
	end
	local trap = lockNode.trap
	if not trap then
		return 0
	end
	local npcMob = tes3.mobilePlayer
	local agility = npcMob.agility.current
	local luck = npcMob.luck.current
	local security = npcMob.security.current
	local quality = 0.25
	local stack = tes3.getEquippedItem({actor = npcMob,
		objectType = tes3.objectType.probe})
	if stack then
		quality = stack.object.quality
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
	-- note that if not 0, fTrapCostMult should be negative (usually -1)
	x = x + (fTrapCostMult * trapSpellPoints)
	if x > 0 then
		local roll = math.random(1, 100)
		if logLevel2 then
			mwse.log('%s: getSecurityPassed("%s") = %s', modPrefix, target.id, x)
		end		
		if roll <= x then
			if logLevel1 then
				mwse.log('%s: getSecurityPassed("%s") roll = %s < %s, passed',
					modPrefix, target.id, roll, x)
			end		
			return x
		end
	end
	return 0
end

--[[
local lockGlowEnchantment -- set in modConfigReady

local function updateNodes(sceneNode)
	sceneNode:update()
	sceneNode:updateEffects()
	---sceneNode:updateProperties()
end

local function getSetGlow(ref) -- out: nil = free, 1 = locked, 2 = trapped
	local sceneNode = ref.sceneNode
	local worldController = tes3.worldController
	local lockNode = ref.lockNode
	if not lockNode then
		return
	end
	local trap = lockNode.trap
	if trap
	and config.trappedHint then
		worldController:applyEnchantEffect(sceneNode, trap)
		updateNodes(sceneNode)
		return 2
	end
	local locked = lockNode.locked
	local effect = sceneNode:getEffect(ni.dynamicEffectType.textureEffect)
	if effect then
		sceneNode:detachEffect(effect)
		updateNodes(sceneNode)
	end
end
]]

local function getSetTargetData(target)
	local data = target.data
	if not data then
		target.data = {}
		data = target.data
	end
	local ab01mt = data.ab01mt
	if not ab01mt then
		local hint = 0
-- trappedHint 0 = Off, 1 = Skill based, 2 = Always, 3 = trap detect spell		
		if trappedHint == 1 then
			hint = getSecurityPassed(target)
		elseif trappedHint == 2 then
			hint = 100
		end
		ab01mt = 1
		if hint > 0 then
			local lockNode = target.lockNode
			if lockNode
			and lockNode.trap then
				if hint >= config.trapDetectThreshold then 
					ab01mt = 7
				else
					ab01mt = 3
				end
			end
		end
		data.ab01mt = ab01mt
		target.modified = true
	end
	---mwse.log('>>> data.ab01mt = %s', data.ab01mt)
	return ab01mt
end


local function getTargetData(target)
	local processed = false
	if target.data then
		local v = target.data.ab01mt
		if v then
			processed = v > 0
		end
	end
	return processed
end

local function isDead(mobile)
	if mobile.isDead then
		return true
	end
	local health = mobile.health
	if health
	and health.current
	and (health.current < 3) then
		if health.normalized <= 0.025 then
			if health.normalized > 0 then
				health.current = 0 -- kill when nearly dead, could be a glitch
			end
		end
		if health.current <= 0 then
			return true
		end
	end
	return false
end

local function find3(s1, s2, s3, needle)
	return string.find(s1, needle, 1, true)
	or string.find(s2, needle, 1, true)
	or string.find(s3, needle, 1, true)
end

local function findObj(obj, needle)
	return find3(string.lower(obj.id), string.lower(obj.mesh), string.lower(obj.name), needle)
end

local function multifind3(s1, s2, s3, pattern)
	return string.multifind(s1, pattern, 1, true)
	or string.multifind(s2, pattern, 1, true)
	or string.multifind(s3, pattern, 1, true)
end

local function multifindObj(obj, pattern)
	return multifind3(string.lower(obj.id), string.lower(obj.mesh), string.lower(obj.name), pattern)
end

local function process(activator, target, delayActivate)

	justLocked = false
	justTrapped = false
	lastActivatedRef = nil

	local funcPrefix = string.format('%s process("%s", "%s")', modPrefix, activator, target)
	if logLevel4 then
		mwse.log('%s: e.activator = "%s", e.target = "%s"', funcPrefix, activator, target)
	end
	if not activator then
		return
	end
	if not target then
		return
	end

	local targetId = target.id

	if not target.sourceMod then
		if logLevel5 then
			mwse.log('%s: target "%s" has no sourceMod, skip', funcPrefix, targetId)
		end
		return -- skip dynamic/portable targets
	end

	local targetObj = target.baseObject

	local objType = targetObj.objectType
	local objTypeStr = mwse.longToString(objType)
	local isContainer = (objType == tes3_objectType_container)
	local isDoor = (objType == tes3_objectType_door)
	if not (
		isContainer
	 or isDoor
	) then
		if logLevel5 then
			mwse.log('%s: target %s "%s" is not a door/container, skip', funcPrefix, objTypeStr, targetId)
		end
		return
	end

	---local previouslyProcessed, previouslyTrapped, previouslyLocked = getTargetData(target)
	local previouslyProcessed = getTargetData(target)
	if previouslyProcessed then
		if logLevel4 then
			mwse.log('%s: target "%s" previously processed, skip', funcPrefix, targetId)
		end
		return
	end

	local cell = activator.cell
	local cellEditorName = cell.editorName

	if cell.isOrBehavesAsExterior then
		if config.skipExteriors
		or cell.restingIsIllegal then
			if logLevel2 then
				mwse.log('%s: cell "%s" isOrBehavesAsExterior = %s, restingIsIllegal = %s, config.skipExteriors = %s, skip',
					funcPrefix, cellEditorName, cell.isOrBehavesAsExterior, cell.restingIsIllegal, config.skipExteriors)
			end
			return
		end
	end

	if cell.restingIsIllegal then
		if config.skipRestingIsIllegal then
			if logLevel2 then
				mwse.log('%s: cell "%s" restingIsIllegal = %s, config.skipRestingIsIllegal = %s, skip',
					funcPrefix, cellEditorName, cell.restingIsIllegal, config.skipRestingIsIllegal)
			end
			return
		end
	end

	local objId = targetObj.id
	local lcObjId = string.lower(objId)

	if targetObj.persistent
	and config.skipPersistent then
		if logLevel3 then
			mwse.log('%s: target "%s" is persistent, skip', funcPrefix, targetId)
		end
		return
	end

	if targetObj.script
	and config.skipScripted then
		if logLevel3 then
			mwse.log('%s: target "%s" is scripted, skip', funcPrefix, targetId)
		end
		return
	end

	if isContainer then
		if targetObj.organic then
			if logLevel3 then
				mwse.log('%s: target "%s" is an organic container, skip', funcPrefix, targetId)
			end
			return
		end
		if string.find(lcObjId, 'corpse', 1, true) then
			if logLevel3 then
				mwse.log('%s: target "%s" is a container corpse, skip', funcPrefix, targetId)
			end
			return
		end
	end

	if isTargetBlacklisted(lcObjId) then
		if logLevel1 then
			mwse.log('%s: target "%s" is blacklisted, skip', funcPrefix, targetId)
		end
		return
	end

	if isCellBlacklisted(cell) then
		if logLevel1 then
			mwse.log('%s: cell "%s" is blacklisted, skip', funcPrefix, cellEditorName)
		end
		return
	end

	if isDoor then
		local doorDest = target.destination
		if doorDest then
			local destCell = doorDest.cell
			if destCell.isOrBehavesAsExterior then
				if logLevel1 then
					local destCellEditorName = destCell.editorName
					mwse.log('%s: %s skipping loading-to-exterior "%s" door',
						funcPrefix, targetId, destCellEditorName)
				end
				return
			end
		end
	end

	lastActivatedRef = target

	local locked = false
	local trapped = false

	local lockNode = target.lockNode
	if lockNode then -- doors or containers not locked or trapped have lockNode nil
		locked = lockNode.locked
		if lockNode.trap then
			trapped = true
		end
		local level = lockNode.level
		if level == 1 then
			if logLevel2 then
				mwse.log('%s: target "%s" already marked as openable level = %s', funcPrefix, targetId, level)
			end
			return
		end
	end

	local canLock = false
	local canTrap = false

	if locked then
		if logLevel2 then
			mwse.log('%s: target "%s" already locked level = %s', funcPrefix, targetId, lockNode.level)
		end
	end

	if trapped then
		if logLevel2 then
			mwse.log('%s: target "%s" already trapped with %s', funcPrefix, targetId, lockNode.trap.id)
		end
	end

	if trapped
	and locked then
		if getSetTargetData(target) > 1 then
			if logLevel2 then
				mwse.log('%s: target "%s" trapped and locked, hinted, skip', funcPrefix, targetId)
			end
			return true
		end
		if logLevel2 then
			mwse.log('%s: target "%s" already trapped and locked, skip', funcPrefix, targetId)
		end
		return
	end

	local lockTier = 0
	local changed = false

	local function processContainer()
		if debugLevel >= 2 then
			canLock = true
			canTrap = true
			lockTier = math.random(0, 3)
		end

		if target.isEmpty then
			local rand = math.random(100)
			if rand <= 75 then
				if logLevel2 then
					mwse.log('%s: target "%s".isEmpty, skip', funcPrefix, targetId)
				end
				return
			end
		end

		if multifindObj(targetObj, {'food','ingred','empty','eggs'}) then
			if logLevel2 then
				mwse.log('%s: target "%s" food|ingred|empty|eggs, skip', funcPrefix, targetId)
			end
			return
		end

		if multifindObj(targetObj, {'chest','dwrv','dwem','dwar','_dw','nordic','coffer','cabinet','supply'}) then
			if multifindObj(targetObj, {'tomb','rare','gold','silver','barrel','keg',
					'treasure','diamond','gems','smuggler','ayl'}) then
				canLock = true
				canTrap = true
				lockTier = 2
				if logLevel2 then
					mwse.log('%s: target "%s" chest|dwrv|dwem|dwar|_dw|nordic|coffer|cabinet|supply', funcPrefix, targetId)
					mwse.log('%s: target "%s" tomb|rare|gold|silver|barrel|keg|treasure|diamond|gems|smuggler|ayl',
						funcPrefix, targetId)
				end
			end
		end

		if lockTier == 0 then
			if multifindObj(targetObj, {'diamond', 'gems', 'treasure'}) then
				canLock = true
				canTrap = true
				lockTier = 3
				if logLevel2 then
					mwse.log('%s: target "%s" diamond|gems|treasure', funcPrefix, targetId)
				end
			elseif multifindObj(targetObj, {'barrel', 'keg'}) then
				if multifindObj(targetObj, {'dwar', 'dwem', 'dwrv','_dw'}) then
					canTrap = config.trapDwemerBarrels
					canLock = config.lockDwemerBarrels
				else
					canTrap = config.trapBarrels
					canLock = config.lockBarrels
				end
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" barrel|keg', funcPrefix, targetId)
				end
			elseif multifindObj(targetObj, {'urn', 'coffin', 'reliquary'}) then
				if not findObj(targetObj, 'furn') then
					canTrap = config.trapUrns
					canLock = config.lockUrns
					lockTier = 1
					if logLevel2 then
						mwse.log('%s: target "%s" urn|coffin|reliquary', funcPrefix, targetId)
					end
				end
			elseif findObj(targetObj, 'jar') then
				canTrap = config.trapJars
				canLock = config.lockJars
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" jar', funcPrefix, targetId)
				end
			elseif findObj(targetObj, 'desk') then
				canTrap = config.trapDesks
				canLock = config.lockDesks
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" desk', funcPrefix, targetId)
				end
			elseif multifindObj(targetObj, {'closet', 'drawer'}) then
				canTrap = config.trapClosets
				canLock = config.lockClosets
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" closet|drawer', funcPrefix, targetId)
				end
			elseif findObj(targetObj, 'table') then
				canTrap = config.trapTables
				canLock = config.lockTables
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" table', funcPrefix, targetId)
				end
			elseif findObj(targetObj, 'crate') then
				canTrap = config.trapCrates
				canLock = config.lockCrates
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" crate', funcPrefix, targetId)
				end
			elseif findObj(targetObj, 'basket') then
				canTrap = config.trapBaskets
				canLock = config.lockBaskets
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" basket', funcPrefix, targetId)
				end
			end
		end -- if lockTier == 0

		if not cell.restingIsIllegal then
			if tes3.hasOwnershipAccess({target = target})
			or tes3.hasOwnershipAccess({target = target, reference = activator}) then -- free to use object activated
			 -- look for a free bed
				local culledCells = getActiveCellsCulled(target, 4096)
				local ok = false
				for i = 1, #culledCells do
					local culledCell = culledCells[i]
					for ref in culledCell:iterateReferences(checkTypes) do
						if ref then
							local obj = ref.baseObject
							local objType = obj.objectType
							if (objType == tes3_objectType_npc)
							or (
								(objType == tes3_objectType_creature)
								and culledCell.isInterior
							) then
								local mob = ref.mobile
								if mob then
									if mob.fight >= 80 then
										if not isDead(mob) then
											if logLevel2 then
												mwse.log('%s: target "%s" is free but there is hostile "%s" in cell "%s", keep processing...',
												funcPrefix, targetId, ref.id, culledCell.editorName)
											end
											ok = true
											break
										end
									end
								end
							elseif obj.name then
								local lcName = string.lower(obj.name)
								if string.find(lcName, 'bed', 1, true) then
									if not string.find(lcName, 'bedroll', 1, true) then -- bedrolls are often free regardless
										if tes3.hasOwnershipAccess({target = ref}) then
											if logLevel2 then
												mwse.log('%s: target "%s" is free and there is a free "%s" bed in cell "%s", skip',
													funcPrefix, targetId, ref.id, culledCell.editorName)
											end
											return
										end
									end
								end
							end
						end
					end -- for ref in culledCell:iterateReferences(checkTypes)
					if ok then
						break
					end
				end -- for i = 1, #culledCells

			end -- if tes3.hasOwnershipAccess
		end -- if not cell.restingIsIllegal

		return true
	end -- processContainer()

	if isContainer then
		if not processContainer() then
			return
		end
	else
		if string.find(lcObjId, 'door', 1, true) then
			if debugLevel >= 1 then
				canLock = true
				canTrap = true
				lockTier = math.random(0, 3)
			elseif string.multifind(lcObjId,{'dwe','dwrv'}, 1, true) then
				canLock = true
				canTrap = true
				lockTier = math.random(1, 3)
			elseif string.multifind(lcObjId,{'cavern_doors00','cavern_doors20'}, 1, true) then
				canLock = true
				canTrap = true
				lockTier = math.random(0, 2)
			end
			if (
				(canLock and logLevel2)
			 or (debugLevel > 0)
			) then
				mwse.log('%s: debug target "%s" door, canLock = %s, canTrap = %s', funcPrefix, targetId, canLock, canTrap, lockTier)
			end
		end
	end

	if not locked then
		local isDoor = (objType == tes3_objectType_door)
		if isDoor then
			if target.cell.isInterior then
				local destination = target.destination
				if destination then
					local destCell = destination.cell
					if destCell.isOrBehavesAsExterior then
						if logLevel3 then
							mwse.log('%s: target "%s" door destination "%s" isOrBehavesAsExterior, canLock = false', funcPrefix, targetId, destCell.editorName)
						end
						canLock = false
					end
				end
			end
		end
		if canLock then
			local lockChance = config.lockContChance
			if isDoor then
				lockChance = config.lockChance
			end
			local rand = math.random(100)
			if lockChance >= rand then
				local lockLevel = (lockTier + 1) * config.lockTierStep
				tes3.lock({reference = target, level = lockLevel})
				if logLevel3 then
					mwse.log('%s: lockChance %s >= rand %s, locking target "%s" %s',
						funcPrefix, lockChance, rand, targetId, lockLevel)
				end
				changed = true
				justLocked = true
			end
		end
	end

	if not trapped then
		if canTrap then
			local trapChance = config.trapContChance
			if isDoor then
				trapChance = config.trapChance
			end
			local rand = math.random(100)
			if trapChance >= rand then
				local trapSpellId = getTrapSpellId(lockTier)
				tes3.setTrap({reference = target, spell = trapSpellId})
				if logLevel3 then
					mwse.log('%s: trapChance %s >= rand %s, trapping target "%s" with "%s"',
						funcPrefix, trapChance, rand, targetId, trapSpellId)
				end
				changed = true
				justTrapped = true
			end
		end
	end

	if getSetTargetData(target) > 1 then
		if logLevel2 then
			mwse.log('%s: target "%s" trapped, hinted, skip', funcPrefix, targetId)
		end
		return true
	end

	if changed
	and delayActivate then
		-- delay must be enough for lock and trap to setup
		delayedActivate(activator, target, 0.27)
		local baseObj = target.baseObject
		if baseObj.objectType == tes3_objectType_container then
			local mesh = baseObj.mesh
			if mesh then
				local lcMesh = string.lower(mesh)
				lcMesh = back2slash(lcMesh)
				if string.find(lcMesh, 'ac/anim_', 1, true) then
					if logLevel3 then
						mwse.log("%s: animated container, no skip", funcPrefix)
						return
					end
				end
			end
		end
		return true -- signal to skip this activate!
	end

end -- process(activator, target, delayActivate)

local function activate(e)
	local funcPrefix = string.format("%s activate(e)", modPrefix)
	if skips > 0 then
		if logLevel2 then
			mwse.log('%s: skips = %s, return', funcPrefix, skips)
		end
		skips = skips - 1
		return
	end
	if logLevel5 then
		if e.target.data then
			mwse.log('%s: e.target.data.ab01mt = %s', funcPrefix, e.target.data.ab01mt)
		end
	end
	e.claim = true -- need this ASAP as setting it after process() is too slow
	if process(e.activator, e.target, true) then
		e.block = true
	else
		e.claim = false
	end
end

local tes3_objectType_probe = tes3.objectType.probe

local function ab01motrpPT3(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	local actorRef = refs[1]
	local targetRef = refs[2]
	local stack = tes3.getEquippedItem({actor = actorRef, objectType = tes3_objectType_probe})
	if not stack then
		return
	end
	event.trigger('trapDisarm', {chance = e.timer.data.chance, trapPresent = true,
		disarmer = actorRef.mobile, lockData = targetRef.lockNode,
		reference = targetRef, tool = stack.object, toolItemData = stack.itemData})

end

local function trapDisarm(e)
	if e.trapPresent then
		return
	end
	e.claim = true
	local actorRef = e.disarmer.reference
	local targetRef = e.reference
	process(actorRef, targetRef)
	if justTrapped then
		if logLevel3 then
			mwse.log("%s: trapDisarm() justTrapped, tes3.playSound({sound = 'Disarm Trap Fail'})", modPrefix)
		end
		tes3.playSound({sound = 'Disarm Trap Fail'})
		timer.start({duration = 0.25, type = timer.real, callback = 'ab01motrpPT3',
			data = {chance = e.chance, trapPresent = true,
				handles = {tes3.makeSafeObjectHandle(actorRef), tes3.makeSafeObjectHandle(targetRef)}
			}
		})
		e.block = true
		return
	end
	e.claim = false
end

local tes3_objectType_lockpick = tes3.objectType.lockpick

local function ab01motrpPT4(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	local actorRef = refs[1]
	local targetRef = refs[2]
	local stack = tes3.getEquippedItem({actor = actorRef, objectType = tes3_objectType_lockpick})
	if not stack then
		return
	end
	event.trigger('lockPick', {chance = e.timer.data.chance, lockPresent = true,
		picker = actorRef.mobile, lockData = targetRef.lockNode,
		reference = targetRef, tool = stack.object, toolItemData = stack.itemData})

end

local function lockPick(e)
	if e.lockPresent then
		return
	end
	e.claim = true
	local actorRef = e.picker.reference
	local targetRef = e.reference
	process(actorRef, targetRef)
	if justLocked then
		if logLevel3 then
			mwse.log("%s: lockPick() justlocked, tes3.playSound({sound = 'Open Lock Fail'})", modPrefix)
		end
		tes3.playSound({sound = 'Open Lock Fail'})
		timer.start({duration = 0.25, type = timer.real, callback = 'ab01motrpPT4',
			data = {chance = e.chance, lockPresent = true,
				handles = {tes3.makeSafeObjectHandle(actorRef), tes3.makeSafeObjectHandle(targetRef)}
			}
		})
		e.block = true
		return
	end
	e.claim = false
end

local function modConfigReady()
	local function createConfigVariable(varId)
		return mwse.mcm.createTableVariable{id = varId, table = config}
	end

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = true})
	end

	local info = [[More Traps
Dynamically/randomly locks/traps more (not yet interacted with) containers and doors.
Note:
Regardless of container type toggles,
organic/food/ingredient/empty containers should always be skipped and
lock/trap chances always applied for chests/barrels/rare/precious containers found in Dwemer ruins/tombs.]]

	local preferences = template:createSideBarPage{
		label = info,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = info})

	local controls = preferences:createCategory({})

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}
local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createSlider({
		label = 'Door Lock Chance: %s%%',
		description = getDescription([[Default: %s.
Chance to lock a suitable door.]], 'lockChance'),
		variable = createConfigVariable('lockChance'),
		min = 0, max = 100, step = 1, jump = 5,
	})
	controls:createSlider({
		label = 'Container Lock Chance: %s%%',
		description = getDescription([[Default: %s.
Chance to lock a suitable container.]], 'lockContChance'),
		variable = createConfigVariable('lockContChance'),
		min = 0, max = 100, step = 1, jump = 5,
	})
	controls:createSlider({
		label = 'Door Trap Chance: %s%%',
		description = getDescription([[Default: %s.
Chance to trap a suitable door.]], 'trapChance'),
		variable = createConfigVariable('trapChance'),
		min = 0, max = 100, step = 1, jump = 5,
	})
	controls:createSlider({
		label = 'Container Trap Chance: %s%%',
		description = getDescription([[Default: %s.
Chance to trap a suitable container.]], 'trapContChance'),
		variable = createConfigVariable('trapContChance'),
		min = 0, max = 100, step = 1, jump = 5,
	})
	controls:createSlider({
		label = 'Spawn Chance: %s%%',
		description = getDescription([[Default: %s.
Chance for non-direct damage traps to spawn a leveled critter.]], 'spawnChance'),
		variable = createConfigVariable('spawnChance'),
		min = 0, max = 100, step = 1, jump = 5,
	})

	local optionList = {'Unleveled', 'by Player level', 'by Lock level', 'by Player and Lock level'}
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

	local note1 = '\nNote: like anything else in this mod,\n'
..'it will only work after you have activated the container/door at least once.'

	controls:createDropdown({
		label = 'Leveled traps:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s
Options are in descending trap danger/thrill level order.]], 'leveledTraps'),
		variable = createConfigVariable('leveledTraps'),
	})

	controls:createSlider({
		label = 'Lock tier step',
		description = getDescription([[Default: %s.
Lock tier step, used to calculate lock level with formula:
lockLvl = (lockTier + 1) * lockTierStep,
having:
10 <= lockTierStep <= 25,
0 <= lockTier <= 3]], 'lockTierStep'),
		variable = createConfigVariable('lockTierStep'),
		min = 10, max = 25, step = 1, jump = 5,
	})

	controls:createYesNoButton({
		label = 'Skip interiors where resting is not allowed',
		description = getYesNoDescription([[Default: %s.
Only process interior cells where you can freely rest (e.g. tombs, caves...)
Note: exterior-like cells marked as "illegal to sleep" e.g. towns are not processed by default.]], 'skipRestingIsIllegal'),
		variable = createConfigVariable('skipRestingIsIllegal')
	})

	controls:createYesNoButton({
		label = 'Skip exteriors',
		description = getYesNoDescription([[Default: %s.
Only process interior cells.
Note: exterior-like cells marked as "illegal to sleep" e.g. towns are not processed by default.]], 'skipExteriors'),
		variable = createConfigVariable('skipExteriors')
	})

	controls:createYesNoButton({
		label = 'Skip persistent targets',
		description = getYesNoDescription([[Default: %s.
Skip processing persistent targets (as persistent references could be used by other scripts/quests and needing to be easily accessed from low level player).
Note that targets with identifier containing "chargen" string are always skipped.]], 'skipPersistent'),
		variable = createConfigVariable('skipPersistent')
	})
	controls:createYesNoButton({
		label = 'Skip scripted targets',
		description = getYesNoDescription([[Default: %s.
Skip processing scripted targets. It should be rarely needed, but option is here just in case.]], 'skipScripted'),
		variable = createConfigVariable('skipScripted')
	})

-- trappedHint 0 = Off, 1 = Skill based, 2 = Always

	optionList = {'Off', 'Skill based', 'Always On'}
	controls:createDropdown({
		label = 'Trapped Hint:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s
Display a (trapped) hint.
Option 1. Skill based will use player skills + equipped probe to decide.
Personally I find enabling this option is against the challenge, but to each their own.]]..note1,
			'trappedHint'),
		variable = createConfigVariable('trappedHint'),
	})

	controls:createSlider({
		label = 'Trap detect Threshold',
		description = getDescription([[Default: %s.
The skill + probe score needed to be able to detect a trap.
Only effective when "Trapped Hint" option is set to "1. Skill based".]], 'trapDetectThreshold'),
		variable = createConfigVariable('trapDetectThreshold'),
		min = 20, max = 95, step = 1, jump = 5,
	})

	controls:createYesNoButton({
		label = 'Trap Dwemer Barrels',
		description = getYesNoDescription([[Default: %s.
Allow barrels trapping.]], 'trapDwemerBarrels'),
		variable = createConfigVariable('trapDwemerBarrels')
	})
	controls:createYesNoButton({
		label = 'Lock Dwemer Barrels',
		description = getYesNoDescription([[Default: %s.
Allow barrels locking.]], 'lockDwemerBarrels'),
		variable = createConfigVariable('lockDwemerBarrels')
	})

	controls:createYesNoButton({
		label = 'Trap Barrels',
		description = getYesNoDescription([[Default: %s.
Allow barrels trapping.]], 'trapBarrels'),
		variable = createConfigVariable('trapBarrels')
	})
	controls:createYesNoButton({
		label = 'Lock Barrels',
		description = getYesNoDescription([[Default: %s.
Allow barrels locking.]], 'lockBarrels'),
		variable = createConfigVariable('lockBarrels')
	})

	controls:createYesNoButton({
		label = 'Trap Urns',
		description = getYesNoDescription([[Default: %s.
Allow urns (and the like) trapping.]], 'trapUrns'),
		variable = createConfigVariable('trapUrns')
	})
	controls:createYesNoButton({
		label = 'Lock Urns',
		description = getYesNoDescription([[Default: %s.
Allow urns (and the like) locking.]], 'lockUrns'),
		variable = createConfigVariable('lockUrns')
	})
	controls:createYesNoButton({
		label = 'Trap Jars',
		description = getYesNoDescription([[Default: %s.
Allow jars trapping.]], 'trapJars'),
		variable = createConfigVariable('trapJars')
	})
	controls:createYesNoButton({
		label = 'Lock Jars',
		description = getYesNoDescription([[Default: %s.
Allow jars locking.]], 'lockJars'),
		variable = createConfigVariable('lockJars')
	})

	controls:createYesNoButton({
		label = 'Trap Desks',
		description = getYesNoDescription([[Default: %s.
Allow desk trapping.]], 'trapDesks'),
		variable = createConfigVariable('trapDesks')
	})
	controls:createYesNoButton({
		label = 'Lock Desks',
		description = getYesNoDescription([[Default: %s.
Allow desks locking.]], 'lockDesks'),
		variable = createConfigVariable('lockDesks')
	})

	controls:createYesNoButton({
		label = 'Trap Closets',
		description = getYesNoDescription([[Default: %s.
Allow closets (and the like) trapping.]], 'trapClosets'),
		variable = createConfigVariable('trapClosets')
	})
	controls:createYesNoButton({
		label = 'Lock Closets',
		description = getYesNoDescription([[Default: %s.
Allow closets locking.]], 'lockClosets'),
		variable = createConfigVariable('lockClosets')
	})

	controls:createYesNoButton({
		label = 'Trap Tables',
		description = getYesNoDescription([[Default: %s.
Allow tables trapping.]], 'trapTables'),
		variable = createConfigVariable('trapTables')
	})
	controls:createYesNoButton({
		label = 'Lock Tables',
		description = getYesNoDescription([[Default: %s.
Allow tables locking.]], 'lockTables'),
		variable = createConfigVariable('lockTables')
	})

	controls:createYesNoButton({
		label = 'Trap Crates',
		description = getYesNoDescription([[Default: %s.
Allow crates trapping.]], 'trapCrates'),
		variable = createConfigVariable('trapCrates')
	})
	controls:createYesNoButton({
		label = 'Lock Crates',
		description = getYesNoDescription([[Default: %s.
Allow crates locking.]], 'lockCrates'),
		variable = createConfigVariable('lockCrates')
	})

	controls:createYesNoButton({
		label = 'Trap Baskets',
		description = getYesNoDescription([[Default: %s.
Allow baskets trapping.]], 'trapBaskets'),
		variable = createConfigVariable('trapBaskets')
	})
	controls:createYesNoButton({
		label = 'Lock Baskets',
		description = getYesNoDescription([[Default: %s.
Allow baskets locking.]], 'lockBaskets'),
		variable = createConfigVariable('lockBaskets')
	})

	optionList = {'Off', 'Low', 'Medium', 'High', 'Very High', 'Max'}
	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s', 'logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	optionList = {'Off', 'Doors', 'Doors, Containers'}
	controls:createDropdown({
		label = 'Debug level:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s
Note: this is meant to be used mostly for testing traps,
not for normal playing!]], 'debugLevel'),
		variable = createConfigVariable('debugLevel'),
	})

	local function onButton(e)
		if e.button == 0 then -- Yes pressed
			config = table.deepcopy(defaultConfig)
			updateFromConfig()
		end
	end

	controls:createButton({
		---label = 'Reset',
		description = [[Reset to default configuration.
Only effective after exiting the MCM panel.]],
		buttonText = 'Reset to default',
		callback = function ()
			tes3.messageBox({
				message = 'Do you really want to reset all settings to default?',
				buttons = {'Yes', 'No'},
				callback = onButton
			})
		end
	})

	timer.register('ab01motrpPT1', ab01motrpPT1)
	timer.register('ab01motrpPT2', ab01motrpPT2)
	timer.register('ab01motrpPT3', ab01motrpPT3)
	timer.register('ab01motrpPT4', ab01motrpPT4)
	event.register('activate', activate, {priority = 2000000}) -- high priority
	event.register('spellResist', spellResist)
	event.register('trapDisarm', trapDisarm, {priority = 2000000})
	event.register('lockPick', lockPick, {priority = 2000000})
	event.register('loaded', loaded)
	if tes3.getScript('ab01trapsAddTrapScript') then
		local s = string.format([[%s: WARNING: More Traps MWSE-Lua mod makes
abotMoreTraps.esp mod obsolete,
you should uninstall abotMoreTraps.esp.]], modPrefix)
		mwse.log(s)
		tes3ui.showNotifyMenu(s)
	end

	---lockGlowEnchantment = tes3.getObject('daedric health_en')

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)