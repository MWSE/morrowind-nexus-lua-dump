local defaultConfig = {
lockChance = 50, -- chance to lock a suitable container/door
trapChance = 40, -- chance to trap a suitable container/door
spawnChance = 50, -- chance for non-direct damage traps to spawn a leveled critter
trapBarrels = true,
lockBarrels = false,
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
trapBaskets = true,
lockBaskets = false,
skipRestingIsIllegal = false,
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High
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
---local logLevel5 = logLevel >= 5

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

local trapSpells = {
'trap_fire00',
'trap_fire_killer',
'trap_frost00',
'trap_frost_killer',
'trap_health00',
'trap_poison00',
'trap_poison_killer',
'trap_shock00',
'trap_shock_killer',
'trap_paralyze00',
'trap_silence00',
"alad's caliginy",
'clumsy touch',
'cruel noise',
'crushing burden touch',
}
local trapSpellsDict = table.invert(trapSpells)

local function getTimerRefs(e)
	local data = e.timer.data
	local handles = data.handles
	local handle
	local refs = {}
	for i = 1, #handles do
		handle = handles[i]
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
		local heightVec = {0, 0, 48}
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

local function process(activator, target, activate)
	local funcPrefix = string.format('%s process("%s", "%s")', modPrefix, activator, target)
	local targetId = target.id
	local cell = activator.cell
	local cellEditorName = cell.editorName

	if logLevel4 then
		mwse.log('%s: e.activator = "%s", e.target = "%s"', funcPrefix, activator, targetId)
	end
	if isCellBlacklisted(cell) then
		if logLevel1 then
			mwse.log('%s: cell "%s" is blacklisted, skip', funcPrefix, cellEditorName)
		end
		return
	end
	if cell.restingIsIllegal then
		if config.skipRestingIsIllegal then
			if logLevel2 then
				mwse.log('%s: cell "%s".restingIsIllegal, skip', funcPrefix, cellEditorName)
			end
			return
		end
	end

	local targetObj = target.object
	local objType = targetObj.objectType
	local objTypeStr = mwse.longToString(objType)
	local isContainer = (objType == tes3_objectType_container)
	if not (
		isContainer
	 or (objType == tes3_objectType_door)
	) then
		if logLevel1 then
			mwse.log('%s: target %s "%s" is not a door/container, skip', funcPrefix, objTypeStr, targetId)
		end
		return
	end
	if target.modified then
		if logLevel2 then
			if activator == tes3.player then
				mwse.log('%s: target "%s" already modified, skip', funcPrefix, targetId)
			end
		end
		return
	end
	if not target.sourceMod then
		if logLevel2 then
			mwse.log('%s: target "%s" has no sourceMod, skip', funcPrefix, targetId)
		end
		return -- skip dynamic/portable targets
	end

	if isContainer then
		if targetObj.organic then
			if logLevel2 then
				mwse.log('%s: target "%s" is an organic container, skip', funcPrefix, targetId)
			end
			return
		end
	end

	if not cell.restingIsIllegal then
		if tes3.hasOwnershipAccess({target = target}) then -- free to use object activated
			 -- look for a free bed
			local culledCells = getActiveCellsCulled(target, 4096)
			local culledCell, obj
			for i = 1, #culledCells do
				culledCell = culledCells[i]
				for ref in culledCell:iterateReferences(tes3_objectType_activator) do
					if ref then
						obj = ref.object
						if obj.name then
							if string.find(string.lower(obj.name), 'bed', 1, true) then
								if tes3.hasOwnershipAccess({target = ref}) then
									if logLevel2 then
										mwse.log('%s: target "%s" is free and there is a free "%s" bed in cell "%", skip',
											funcPrefix, targetId, ref.id, culledCell.editorName)
									end
									return
								end
							end
						end
					end
				end
			end
		end
	end

	lastActivatedRef = target

	local alreadyTrapped = false
	local alreadyLocked = false

	local lockNode = target.lockNode

	if lockNode then -- doors or containers not locked or trapped have lockNode nil
		local locked = lockNode.locked
		if locked then
			alreadyLocked = true
			if logLevel2 then
				mwse.log('%s: target "%s" lock level = %s', funcPrefix, targetId, lockNode.level)
			end
		end
		if lockNode.trap then
			alreadyTrapped = true
			if logLevel2 then
				mwse.log('%s: target "%s" trap = %s', funcPrefix, targetId, lockNode.trap.id)
			end
		end
		if alreadyLocked
		and alreadyTrapped then
			if logLevel2 then
				mwse.log('%s: target "%s" already locked and trapped, skip', funcPrefix, targetId)
			end
			return
		end
	end

	local canLock = false
	local canTrap = false
	local lockTier = 0

	local lcObjId = string.lower(targetObj.id)

	if isContainer then
		if debugLevel >= 2 then
			canLock = true
			canTrap = true
			lockTier = math.random(0, 3)
		end
		if string.multifind(lcObjId, {'food', 'ingred', 'empty'}, 1, true) then
			if logLevel2 then
				mwse.log('%s: target "%s" food|ingred|empty, skip', funcPrefix, targetId)
			end
			return
		end

		if string.multifind(lcObjId, {'chest', 'dwrv', 'dwem'}, 1, true) then
			if string.multifind(lcObjId, {'tomb', 'rare', 'gold', 'silver', 'barrel'}, 1, true) then
				canLock = true
				canTrap = true
				lockTier = 2
				if logLevel2 then
					mwse.log('%s: target "%s" chest|dwrv', funcPrefix, targetId)
					mwse.log('%s: target "%s" tomb|rare|gold|silver|barrel', funcPrefix, targetId)
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
			elseif string.find(lcObjId, 'barrel', 1, true) then
				canTrap = config.trapBarrels
				canLock = config.lockBarrels
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" barrel', funcPrefix, targetId)
				end
			elseif string.find(lcObjId, 'urn', 1, true) then
				canTrap = config.trapUrns
				canLock = config.lockUrns
				lockTier = 1
				if logLevel2 then
					mwse.log('%s: target "%s" urn', funcPrefix, targetId)
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
		end
	elseif string.find(lcObjId, 'door', 1, true) then
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
		if logLevel2 then
			if canLock then
				if debugLevel < 1 then
					mwse.log('%s: target "%s" door', funcPrefix, targetId)
					mwse.log('%s: target "%s" cavern_doors00|cavern_doors20|dwe|dwrv', funcPrefix, targetId)
				end
			end
		end
	end

	local changed = false

	if debugLevel > 0 then
		mwse.log('%s: debug target "%s" door, canLock = %s, canTrap = %s', funcPrefix, targetId, canLock, canTrap, lockTier)
	end

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
			if config.lockChance >= math.random(100) then
				local lockLevel = (lockTier + 1) * 20
				tes3.lock({reference = target, level = lockLevel})
				if logLevel3 then
					mwse.log('%s: locking target "%s" %s', funcPrefix, targetId, lockLevel)
				end
				changed = true
				justLocked = true
			end
		end
	end

	if not alreadyTrapped then
		if canTrap then
			if config.trapChance >= math.random(100) then
				local trapSpellId = table.choice(trapSpells)
				tes3.setTrap({reference = target, spell = trapSpellId})
				if logLevel3 then
					mwse.log('%s: trapping target "%s" with "%s"', funcPrefix, targetId, trapSpellId)
				end
				changed = true
				justTrapped = true
			end
		end
	end

	if changed then
		if activate then
			-- delay must be enough for lock and trap to setup
			delayedActivate(activator, target, 0.2)
			return false -- skip this activate!
		end
		return
	end

	-- normal activation/opening...
	if target.modified then
		return
	end
	-- ... but mark as modified
	target.modified = true
	if logLevel3 then
		mwse.log('%s: set target "%s".modified', funcPrefix, targetId)
	end
end

local function activate(e)
	if logLevel4 then
		mwse.log('%s: activate(e) e.target.modified = %s', modPrefix, e.target.modified)
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
	justTrapped = false
	process(actorRef, targetRef)
	if justTrapped then
		timer.start({duration = 0.2, type = timer.real, callback = 'ab01motrPT3',
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
	justLocked = false
	process(actorRef, targetRef)
	if justLocked then
		timer.start({duration = 0.2, type = timer.real, callback = 'ab01motrPT4',
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
		---logLevel5 = logLevel >= 5
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

	controls:createYesNoButton({
		label = 'Skip interiors where resting is not allowed',
		description = getYesNoDescription([[Default: %s.
Only process interior cells where you can freely rest (e.g. tombs, caves...)]], 'skipRestingIsIllegal'),
		variable = createConfigVariable('skipRestingIsIllegal')
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

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Max'}
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
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})
	optionList = {'Off', 'Doors', 'Doors, Containers'}
	controls:createDropdown({
		label = 'Debug level:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s
Note: this is meant to be used mostly for testing traps,
not for normal playing!]],'debugLevel'),
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