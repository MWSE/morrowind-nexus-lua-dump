local defaultConfig = {
lockChance = 50, -- chance to lock a suitable container/door
trapChance = 33, -- chance to trap a suitable container/door
spawnChance = 50, -- chance for non-direct damage traps to spawn a leveled critter
leveledTraps = 3, -- 0 = Unleveled, 1 = by Player Level, 2 = by Lock level, 3 = by Player and Lock level
lockTierStep = 20, -- 10 <= lockTierStep <= 25, 0 <= lockTier <= 3, lockLevel = (lockTier + 1) * lockTierStep
skipPersistent = true,
skipScripted = false,
trapBarrels = true,
lockBarrels = false,
trapUrns = true,
lockUrns = false,
extraLootUrns = false,
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
trapBaskets = true,
lockBaskets = false,
skipRestingIsIllegal = false,
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
local logLevel = config.logLevel
local debugLevel = config.debugLevel

local logLevel1 = logLevel >= 1
local logLevel2 = logLevel >= 2
local logLevel3 = logLevel >= 3
local logLevel4 = logLevel >= 4
local logLevel5 = logLevel >= 5

-- reset in loaded()
local lastActivatedRef
local function loaded()
	lastActivatedRef = nil
end

local tes3_objectType_container = tes3.objectType.container
local tes3_objectType_door = tes3.objectType.door

local cellsBlackList = {'Corprusarium'}

local function isCellBlacklisted(cell)
	local cellName = string.lower(cell.editorName)
	local s
	for i = 1, #cellsBlackList do
		s = string.lower(cellsBlackList[i])
		if string.startswith(cellName, s) then
			return true
		end
	end
	return false
end

local targetsBlackList = {'chargen'}

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
local spawningEffects = {
T3E.blind,
T3E.damageFatigue,
T3E.drainFatigue,
T3E.drainAttribute,
T3E.paralyze,
T3E.silence,
T3E.sound,
}
local spawningEffectsDict = table.invert(spawningEffects)

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

local function getTimerRefs(e)
	local data = e.timer.data
	local handles = data.handles
	local handle
	local refs = {}
	for i = 1, #handles do
		handle = handles[i]
		if not handle then
			return
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
		local heightVec = tes3vector3.new(0, 0, 48)
		if not tes3.testLineOfSight({reference1 = ref, reference2 = targetRef, position1 = ref.position,
			height1 = heightVec, position2 = targetPos, height2 = heightVec}) then
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
---@diagnostic disable-next-line: param-type-mismatch
	local levCreaObj = levCreaList:pickFrom()
	if logLevel1 then
		mwse.log('%s: createLeveledCreature("%s", "%s") = %s', modPrefix, casterRef, targetRef, levCreaObj)
	end
	local ref = createReference(casterRef, targetRef, levCreaObj)
	return ref
end

local function ab01motrPT1(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	createLeveledCreature(refs[1], refs[2])
end

local function delayedSpawn(casterRef, targetRef, delaySec)
	timer.start({duration = delaySec, callback = 'ab01motrPT1',
		data = { handles = {tes3.makeSafeObjectHandle(casterRef), tes3.makeSafeObjectHandle(targetRef)} }
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
	if not trapSpellsDict[source.id] then
		return
	end
	if not lastActivatedRef then
		return
	end
	local funcPrefix = string.format("%s spellResist(e)", modPrefix)
	local effect = e.effect
	if logLevel2 then
		mwse.log('%s: target = "%s", spell = "%s" "%s", effect = %s "%s"',
			funcPrefix, target.id, source.id, source.name, effect.id, effect.object.name)
	end
	if not spawningEffectsDict[effect.id] then
		return
	end
	if config.spawnChance < math.random(100) then
		return
	end
	local lcObjId = string.lower(lastActivatedRef.object.id)
	local s = 'dae'
	if string.multifind(lcObjId, {'dwrv', 'dwem'}, 1, true) then
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

local function ab01motrPT2(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	if logLevel1 then
		mwse.log('%s: ab01motrPT2() "%s":activate("%s")', modPrefix, refs[1], refs[2])
	end
	refs[1]:activate(refs[2])
end

local function delayedActivate(activator, target, delaySec)
	timer.start({duration = delaySec, type = timer.real, callback = 'ab01motrPT2',
		data = { handles = {tes3.makeSafeObjectHandle(activator), tes3.makeSafeObjectHandle(target)} }
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

local function getTrapSpellId(lockTier)
	 -- 0 = Unleveled, 1 = by Player Level, 2 = by Lock level, 3 = by Player and Lock level
	local leveledTraps = config.leveledTraps
	if leveledTraps == 0 then
		local _, key = table.choice(trapSpellsDict)
		return key
	end
	local trapSpells = {}
	local playerLvl = tes3.player.object.level
	local i = 0
	local notByPlayerLvl = (leveledTraps == 2)
	local notByLockLvl = (leveledTraps == 3)
	for k, v in pairs(trapSpellsDict) do
		if notByPlayerLvl or (playerLvl >= v.minPlayerLvl) then
			if notByLockLvl or (lockTier >= v.minLockTier) then
				i = i + 1
				trapSpells[i] = k
				if logLevel3 then
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
		local _, key = table.choice(trapSpellsDict)
		return key
	end
	return table.choice(trapSpells)
end

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local function setTargetData(target, locked, trapped)
	local data = target.data
	if not data then
		target.data = {}
		data = target.data
	end
	local v = 0
	if locked then
		v = 1
	end
	if trapped then
		v = v + 2
	end
	if v == data.ab01mt then
		return
	end
	data.ab01mt = v
	target.modified = true
end

local function getTargetData(target)
	local locked = false
	local trapped = false
	if target.data then
		local v = target.data.ab01mt
		if v then
			local r = v % 2
			if r == 1 then
				locked = true
			end
			v = v - r
			if v == 2 then
				trapped = true
			end
		end
	end
	return locked, trapped
end

local function process(activator, target, delayActivate)
	local funcPrefix = string.format('%s process("%s", "%s")', modPrefix, activator, target)
	local targetId = target.id
	local cell = activator.cell
	local cellEditorName = cell.editorName

	justLocked = false
	justTrapped = false

	if logLevel4 then
		mwse.log('%s: e.activator = "%s", e.target = "%s"', funcPrefix, activator, targetId)
	end
	if cell.restingIsIllegal then
		if config.skipRestingIsIllegal then
			if logLevel2 then
				mwse.log('%s: cell "%s".restingIsIllegal, skip', funcPrefix, cellEditorName)
			end
			return
		end
	end

	local targetObj = target.baseObject

	local objType = targetObj.objectType
	local objTypeStr = mwse.longToString(objType)
	local isContainer = (objType == tes3_objectType_container)
	if not (
		isContainer
	 or (objType == tes3_objectType_door)
	) then
		if logLevel5 then
			mwse.log('%s: target %s "%s" is not a door/container, skip', funcPrefix, objTypeStr, targetId)
		end
		return
	end

	if not target.sourceMod then
		if logLevel2 then
			mwse.log('%s: target "%s" has no sourceMod, skip', funcPrefix, targetId)
		end
		return -- skip dynamic/portable targets
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

	lastActivatedRef = target

	local alreadyTrapped = false
	local alreadyLocked = false

	local lockNode = target.lockNode

	if lockNode then -- doors or containers not locked or trapped have lockNode nil

		local previouslyLocked, previouslyTrapped = getTargetData(target)
		local locked = lockNode.locked
		alreadyLocked = locked or previouslyLocked
		if alreadyLocked then
			if logLevel2 then
				if locked then
					mwse.log('%s: target "%s" already locked level = %s', funcPrefix, targetId, lockNode.level)
				elseif previouslyLocked then
					mwse.log('%s: target "%s" previously locked', funcPrefix, targetId)
				end
			end
		end

		local trapped = lockNode.trap
		alreadyTrapped = trapped or previouslyTrapped
		if alreadyTrapped then
			if logLevel2 then
				if trapped then
					mwse.log('%s: target "%s" already trapped with %s', funcPrefix, targetId, lockNode.trap.id)
				elseif previouslyTrapped then
					mwse.log('%s: target "%s" previously trapped', funcPrefix, targetId)
				end
			end
		end

		if alreadyLocked
		and alreadyTrapped then
			setTargetData(target, alreadyLocked, alreadyTrapped)
			if logLevel2 then
				mwse.log('%s: target "%s" already/previously locked and trapped, skip', funcPrefix, targetId)
			end
			return
		end
	end

	local canLock = false
	local canTrap = false
	local lockTier = 0

	local function processContainer()
		if debugLevel >= 2 then
			canLock = true
			canTrap = true
			lockTier = math.random(0, 3)
		end
		if string.multifind(lcObjId, {'food', 'ingred', 'empty', 'eggs'}, 1, true) then
			if logLevel2 then
				mwse.log('%s: target "%s" food|ingred|empty|eggs, skip', funcPrefix, targetId)
			end
			return
		end

		if string.multifind(lcObjId, {'chest', 'dwrv', 'dwem'}, 1, true) then
			if string.multifind(lcObjId, {'tomb', 'rare', 'gold', 'silver', 'barrel', 'keg'}, 1, true) then
				canLock = true
				canTrap = true
				lockTier = 2
				if logLevel2 then
					mwse.log('%s: target "%s" chest|dwrv', funcPrefix, targetId)
					mwse.log('%s: target "%s" tomb|rare|gold|silver|barrel|keg', funcPrefix, targetId)
				end
			end
		end

		if lockTier == 0 then
			if string.multifind(lcObjId, {'diamonds', 'gems'}, 1, true) then
				canLock = true
				canTrap = true
				lockTier = 3
				if logLevel2 then
					mwse.log('%s: target "%s" diamonds|gems', funcPrefix, targetId)
				end
			elseif string.multifind(lcObjId, {'barrel', 'keg'}, 1, true) then
				canTrap = config.trapBarrels
				canLock = config.lockBarrels
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" barrel|keg', funcPrefix, targetId)
				end
			elseif string.find(lcObjId, 'urn', 1, true) then
				canTrap = config.trapUrns
				canLock = config.lockUrns
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" urn', funcPrefix, targetId)
				end
				if config.extraLootUrns then
					--- if target.isEmpty then
					local inventory = target.object.inventory
					local itm = table.choice({'l_b_loot_tomb','l_b_loot_tomb01','l_b_loot_tomb02','l_b_loot_tomb03'})
					if inventory then
						local addedCount = tes3.addItem({reference = target, count = 1, item = itm})
						if addedCount then
							if addedCount > 0 then
								inventory:resolveLeveledItems()
								if logLevel2 then
									mwse.log('%s: "%s" leveled item added to "%s" urn', funcPrefix, itm, targetId)
								end
							end
						end
					end
				end
			elseif string.find(lcObjId, 'jar', 1, true) then
				canTrap = config.trapJars
				canLock = config.lockJars
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" jar', funcPrefix, targetId)
				end
			elseif string.find(lcObjId, 'desk', 1, true) then
				canTrap = config.trapDesks
				canLock = config.lockDesks
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" desk', funcPrefix, targetId)
				end
			elseif string.find(lcObjId, 'closet', 1, true) then
				canTrap = config.trapClosets
				canLock = config.lockClosets
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" closet', funcPrefix, targetId)
				end
			elseif string.find(lcObjId, 'table', 1, true) then
				canTrap = config.trapTables
				canLock = config.lockTables
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" table', funcPrefix, targetId)
				end
			elseif string.find(lcObjId, 'crate', 1, true) then
				canTrap = config.trapCrates
				canLock = config.lockCrates
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" crate', funcPrefix, targetId)
				end
			elseif string.find(lcObjId, 'basket', 1, true) then
				canTrap = config.trapBaskets
				canLock = config.lockBaskets
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" basket', funcPrefix, targetId)
				end
			end
		end -- if lockTier == 0

		if not cell.restingIsIllegal then
			if tes3.hasOwnershipAccess({target = target}) then -- free to use object activated
			 -- look for a free bed
				local culledCells = getActiveCellsCulled(target, 4096)
				local culledCell, obj
				local ok = false
				for i = 1, #culledCells do
					culledCell = culledCells[i]
					for ref in culledCell:iterateReferences(checkTypes) do
						if ref then
							obj = ref.baseObject
							objType = obj.objectType
							if (objType == tes3_objectType_npc)
							or (objType == tes3_objectType_creature) then
								if ref.mobile then
									if ref.mobile.fight >= 80 then
										if logLevel2 then
											mwse.log('%s: target "%s" is free but there is hostile "%s" in cell "%s", keep processing...',
												funcPrefix, targetId, ref.id, culledCell.editorName)
										end
										ok = true
										break
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

	local changed = false
	if not alreadyLocked then
		if objType == tes3_objectType_door then
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
			local rand = math.random(100)
			if config.lockChance >= rand then
				local lockLevel = (lockTier + 1) * config.lockTierStep
				tes3.lock({reference = target, level = lockLevel})
				if logLevel3 then
					mwse.log('%s: lockChance %s >= rand %s, locking target "%s" %s',
						funcPrefix, config.lockChance, rand, targetId, lockLevel)
				end
				changed = true
				justLocked = true
			end
		end
	end

	if not alreadyTrapped then
		if canTrap then
			local rand = math.random(100)
			if config.trapChance >= rand then
				local trapSpellId = getTrapSpellId(lockTier)
				tes3.setTrap({reference = target, spell = trapSpellId})
				if logLevel3 then
					mwse.log('%s: trapChance %s >= rand %s, trapping target "%s" with "%s"',
						funcPrefix, config.trapChance, rand, targetId, trapSpellId)
				end
				changed = true
				justTrapped = true
			end
		end
	end

	if changed then

		setTargetData(target, justLocked or alreadyLocked, justTrapped or alreadyTrapped)

		if delayActivate then
			-- delay must be enough for lock and trap to setup
			delayedActivate(activator, target, 0.25)
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
			return false -- skip this activate!
		end
	end

end

local function activate(e)
	if logLevel5 then
		if e.target.data then
			mwse.log('%s: activate(e) e.target.data.ab01mt = %s', modPrefix, e.target.data.ab01mt)
		end
	end
	e.claim = true -- need this as setting return is too slow
	local result = process(e.activator, e.target, true)
	e.claim = false
	return result
end

local function ab01motrPT3(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	local actorRef = refs[1]
	local targetRef = refs[2]
	local stack = tes3.getEquippedItem({actor = actorRef, objectType = tes3.objectType.probe})
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
	local actorRef = e.disarmer.reference
	local targetRef = e.reference
	process(actorRef, targetRef)
	if justTrapped then
		timer.start({duration = 0.25, type = timer.real, callback = 'ab01motrPT3',
			data = {chance = e.chance, trapPresent = true,
				handles = {tes3.makeSafeObjectHandle(actorRef), tes3.makeSafeObjectHandle(targetRef)}
			}
		})
		return false
	end
end

local function ab01motrPT4(e)
	local refs = getTimerRefs(e)
	if not refs then
		return
	end
	local actorRef = refs[1]
	local targetRef = refs[2]
	local stack = tes3.getEquippedItem({actor = actorRef, objectType = tes3.objectType.lockpick})
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
	local actorRef = e.picker.reference
	local targetRef = e.reference
	process(actorRef, targetRef)
	if justLocked then
		timer.start({duration = 0.25, type = timer.real, callback = 'ab01motrPT4',
			data = {chance = e.chance, lockPresent = true,
				handles = {tes3.makeSafeObjectHandle(actorRef), tes3.makeSafeObjectHandle(targetRef)}
			}
		})
		return false
	end
end

local function modConfigReady()
	local function createConfigVariable(varId)
		return mwse.mcm.createTableVariable{id = varId, table = config}
	end

	local template = mwse.mcm.createTemplate(mcmName)

	local function updateConfigVars()
		logLevel = config.logLevel
		logLevel1 = logLevel >= 1
		logLevel2 = logLevel >= 2
		logLevel3 = logLevel >= 3
		logLevel4 = logLevel >= 4
		logLevel5 = logLevel >= 5
		debugLevel = config.debugLevel
	end

	template.onClose = function()
		updateConfigVars()
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
		label = 'Lock Chance: %s%%',
		description = getDescription([[Default: %s.
Chance to lock a suitable container/door.]], 'lockChance'),
		variable = createConfigVariable('lockChance'),
		min = 0, max = 100, step = 1, jump = 5,
	})
	controls:createSlider({
		label = 'Trap Chance: %s%%',
		description = getDescription([[Default: %s.
Chance to trap a suitable container/door.]], 'trapChance'),
		variable = createConfigVariable('trapChance'),
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
Only process interior cells where you can freely rest (e.g. tombs, caves...)]], 'skipRestingIsIllegal'),
		variable = createConfigVariable('skipRestingIsIllegal')
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
Allow urns trapping.]], 'trapUrns'),
		variable = createConfigVariable('trapUrns')
	})
	controls:createYesNoButton({
		label = 'Lock Urns',
		description = getYesNoDescription([[Default: %s.
Allow urns locking.]], 'lockUrns'),
		variable = createConfigVariable('lockUrns')
	})
	controls:createYesNoButton({
		label = 'Add extra loot to Urns',
		description = getYesNoDescription([[Default: %s.
Add extra loot to urns.]], 'extraLootUrns'),
		variable = createConfigVariable('extraLootUrns')
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
Allow closets trapping.]], 'trapClosets'),
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
			updateConfigVars()
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

	timer.register('ab01motrPT1', ab01motrPT1)
	timer.register('ab01motrPT2', ab01motrPT2)
	timer.register('ab01motrPT3', ab01motrPT3)
	timer.register('ab01motrPT4', ab01motrPT4)
	event.register('activate', activate, {priority = 2000000}) -- high priority
	event.register('spellResist', spellResist)
	event.register('trapDisarm', trapDisarm)
	event.register('lockPick', lockPick)
	event.register('loaded', loaded)
	if tes3.getScript('ab01trapsAddTrapScript') then
		local s = string.format([[%s: WARNING: More Traps MWSE-Lua mod makes
abotMoreTraps.esp mod obsolete,
you should uninstall abotMoreTraps.esp.]], modPrefix)
		mwse.log(s)
		tes3.messageBox(s)
	end
	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)