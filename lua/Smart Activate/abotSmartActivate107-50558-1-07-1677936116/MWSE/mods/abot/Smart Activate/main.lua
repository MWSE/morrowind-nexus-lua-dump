--[[
allow to choose who to activate between 8 nearby actors
]]

local defaultConfig = {
actorsMenu = true, -- actorsMenu toggle
maxDistance = 72, -- Max distance between actors to classify them as colliding each other
maxSelectable = 8, -- Max number of selectable actors
allowDead = true, -- allow selecting dead actors
allowNPC = true, -- allow selecting NPCs
allowCreature = true, -- allow selecting creatures
allowContainer = false, -- allow selecting containers
allowOrganic = false, -- allow selecting organic containers
allowDoor = true, -- allow selecting 1 door
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High
}

local author = 'abot'
local modName = 'Smart Activate'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

local maxSelectable = config.maxSelectable
local allowDead = config.allowDead
local allowNPC = config.allowNPC
local allowCreature = config.allowCreature
local allowContainer = config.allowContainer
local allowOrganic = config.allowOrganic
local allowDoor = config.allowDoor
local logLevel = config.logLevel

local AS_DEAD = tes3.animationState.dead
local AS_DYING = tes3.animationState.dying

-- set in loaded()
local player, player1stPerson

local function isMobileDead(mobile)
	local health = mobile.health
	if health then
		if health.current then
			if logLevel >= 3 then
				mwse.log('%s: isMobileDead("%s") health.current = %s', modPrefix, mobile.reference.id, health.current)
			end
			if health.current <= 0 then
				return true
			end
		end
	end
	local actionData = mobile.actionData
	if not actionData then
		return false -- it may happen
	end
	local animState = actionData.animationAttackState
	if not animState then
		return false
	end
	if (animState == AS_DEAD)
	or (animState == AS_DYING) then
		return true
	end
	return mobile.isDead
end


-- initialized in loaded()
local inputController

local tes3_scanCode_lAlt = tes3.scanCode.lAlt
local tes3_scanCode_lShift = tes3.scanCode.lShift


local function getCulledCells(ref, maxDistanceFromRef)
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
	or (logLevel >= 2) then
		local msg = "%s: getCulledCells(ref = %s, maxDistanceFromRef = %s)"
		if j == 0 then
			msg = msg .. " no cells found!"
		end
		mwse.log(msg, modPrefix, ref, maxDistanceFromRef)
	end

	return cells
end


local function byNameAsc(a, b)
	return a.name < b.name
end

local function byDistAsc(a, b)
	return a.dist < b.dist
end

local tes3_objectType_npc = tes3.objectType.npc
local tes3_objectType_creature = tes3.objectType.creature
local tes3_objectType_container = tes3.objectType.container
local tes3_objectType_door = tes3.objectType.door

local selectableTypes = {tes3_objectType_npc, tes3_objectType_creature, tes3_objectType_container, tes3_objectType_door}

---local readableObjectTypes = table.invert(tes3.objectType)

local selectables = {}

local dummies = {'mannequin','practice dummy','archery target','target board'}

local function isDummy(ref)
	if ref then
		local name = ref.object.name
		if name then
			if #name > 0 then
				if string.multifind(string.lower(name), dummies, 1, true) then
					return true
				end
			end
		end
	end
	return false
end

local function getSelectablesInProximity(targetRef, range)
	local aDist, aName, mesh, mob, obj, objType, ok
	local i = 0
	local targetRefPos = targetRef.position
	local funcPrefix = string.format('%s: getSelectablesInProximity("%s", %s)', modPrefix, targetRef.id, range)
	local logLevel2 = logLevel >= 2
	local logLevel3 = logLevel >= 3
	local logLevel4 = logLevel >= 4
	local t = {}
	local cell = targetRef.cell
	local mobCount = 0
	local contCount = 0
	local doorCount = 0

	local function processCell()
		for aRef in cell:iterateReferences(selectableTypes) do
			if not (
				(aRef == player)
				or (aRef == player1stPerson)
			) then
				aDist = targetRefPos:distance(aRef.position)
				if logLevel4 then
					mwse.log('%s: aRef = "%s" aDist = %s, range = %s', funcPrefix, aRef.id, aDist, range)
				end
				if (aDist <= range)
				and (not aRef.disabled)
				and (not aRef.deleted) then
					obj = aRef.object
					mesh = obj.mesh
					if mesh
					and (#mesh > 0) then
						if logLevel3 then
							mwse.log('%s: mesh = "%s"', funcPrefix, mesh)
						end
						objType = obj.objectType
						ok = false
						if ( (objType == tes3_objectType_npc)
							and allowNPC )
						or ( (objType == tes3_objectType_creature)
							and allowCreature) then
							mob = aRef.mobile
							if mob then
								if not isDummy(aRef) then -- skip mannequins
									if allowDead then
										ok = true
									elseif not isMobileDead(mob) then
										ok = true
									end
									if ok then
										mobCount = mobCount + 1
									end
								end
							end
							if logLevel3 then
								mwse.log('%s: mob = %s, ok = %s', funcPrefix, mob.reference.id, ok)
							end
						elseif objType == tes3_objectType_container then
							if obj.organic then
								ok = allowOrganic
							else
								ok = allowContainer
							end
							if ok then
								contCount = contCount + 1
							end
						elseif objType == tes3_objectType_door then
							ok = allowDoor
							if ok then
								doorCount = doorCount + 1
							end
						end
						if ok then
							aName = obj.name
							if logLevel3 then
								mwse.log('aName = "%s"', aName)
							end
							if (not aName)
							or (aName == '') then
								-- important! the messageBox may freeze on empty button text!
								-- e.g. invisible tiny sonar race NPCs could have no name
								ok = false
							end
						end
						if ok then
							i = i + 1
							if i > maxSelectable then
								return t
							end
							if logLevel2 then
								mwse.log('%s: t[%s] = {ref = "%s", name = "%s", dist = %s}',
									funcPrefix, i, aRef.id, aName, aDist)
							end
							t[i] = {ref = aRef, name = aName, dist = aDist}
						end
					end -- if mesh and ...
				end -- if (aDist <= range) and (not aRef.disabled) ...
			end -- if not (	(aRef == player) ...
		end -- for aRef
	end

	if cell.isInterior then
		if logLevel3 then
			mwse.log('%s: processing "%s" interior', funcPrefix, cell.editorName)
		end
		processCell()
	else
		local culledCells = getCulledCells(targetRef, range)
		for j = 1, #culledCells do
			cell = culledCells[j]
			if logLevel3 then
				mwse.log('%s: processing culledCells[%s] = %s', funcPrefix, j, cell.editorName)
			end
			processCell()
		end
	end

	if mobCount == 0 then -- no actors, no need for special menu
		return {[1] = {ref = targetRef, name = targetRef.object.name, dist = 0}}
	end

	local count = #t
	if count > 1 then
		table.sort(t, byDistAsc) -- sort by lesser distance
		local v
		local t2 = {}
		if count > maxSelectable then -- get only first maxSelectable items
			for k = 1, maxSelectable do
				v = t[k]
				t2[k] = v
			end
			t = t2
			count = #t
		end
		if doorCount >= 2 then -- max 1 door
			ok = true
			local j = 0
			t2 = {}
			for k = 1, count do
				v = t[k]
				if v.ref.object.objectType == tes3_objectType_door then
					if ok then
						ok = false
						j = j + 1
						t2[j] = v -- add first door, once
					end
				else
					j = j + 1
					t2[j] = v -- add non-door objects
				end
			end
			t = t2
			count = #t
		end
		if logLevel3  then
			mwse.log('%s: sorted by distance', funcPrefix)
			for k = 1, count do
				v = t[k]
				if logLevel3  then
					mwse.log('%s: t[%s] = {ref = "%s", name = "%s", dist = %s}',
						funcPrefix, k, v.ref.id, v.name, v.dist)
				end
			end
		end
	end
	return t
end


local function delayedPlayerActivate(targetRef, delaySec)
	local targetHandle = tes3.makeSafeObjectHandle(targetRef)
	timer.start({duration = delaySec, type = timer.real,
		callback = function ()
			if not targetHandle then
				return
			end
			if not targetHandle:valid() then
				return
			end
			targetRef = targetHandle:getObject()
			if not targetRef then
				return
			end
			if logLevel >= 2 then
				mwse.log('%s: player:activate("%s")', modPrefix, targetRef.id)
			end
			player:activate(targetRef)
		end
	})
end

local skips = 0 -- reset in loaded()
local activateBtns = {}
local lastButtonIndex = 0

local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local validTypes = {
[tes3_objectType_npc] = true,
[tes3_objectType_creature] = true,
[tes3_objectType_container] = true,
[tes3_objectType_door] = true,
}

local lastActivatedRef -- reset in loaded()
local function activate(e)
	if not config.actorsMenu then
		return
	end
	local funcPrefix = string.format("%s activate(e)", modPrefix)
	local activator = e.activator
	if not (activator == player) then
		if logLevel >= 3 then
			mwse.log("\n%s: e.activator = %s, skip", funcPrefix, activator)
		end
		return
	end

	local target = e.target
	if logLevel >= 2 then
		mwse.log('%s: e.target = "%s"', funcPrefix, target)
	end

	if target == lastActivatedRef then
		if logLevel >= 2 then
			mwse.log('%s: e.target == lastActivatedRef == "%s", skip', funcPrefix, target)
		end
		lastActivatedRef = nil
		return
	end

	local obj = target.object
	local objType = obj.objectType
	if not validTypes[objType] then
		if logLevel >= 2 then
			mwse.log("%s: objType = %s, skip", funcPrefix, mwse.longToString(objType))
		end
		return
	end

	if inputController:isKeyDown(tes3_scanCode_lAlt)
	or inputController:isKeyDown(tes3_scanCode_lShift) then
		if logLevel >= 2 then
			mwse.log("%s: Alt or Shift pressed, skip", funcPrefix)
		end
		return -- skip if Alt or Shift pressed
	end


	if skips > 0 then
		skips = skips - 1
		if logLevel >= 2 then
			mwse.log('%s: skips = %s, return', funcPrefix, skips)
		end
		return
	end

	local mobile = target.mobile
	---assert(mobile) -- nope, it may be nil

	local rng = config.maxDistance

	if mobile then
		local boundSize = mobile.boundSize
		if boundSize then
			local boundMin = math.min(boundSize.x, boundSize.y)
			if boundMin > rng then
				rng = boundMin -- increase collision range for big creatures
				if logLevel >= 2 then
					mwse.log("%s: max range set to %s, min bound size = %s", funcPrefix, target.id, rng)
				end
			end
		end
	end

	selectables = getSelectablesInProximity(target, rng)
	if #selectables < 2 then
		if logLevel >= 2 then
			mwse.log("%s: #selectables < 2, skip", funcPrefix)
		end
		return
	end

	table.sort(selectables, byNameAsc)

	local curr, currId, prev, prevId
	local modified = false
	local idCount = 0
	for j = 1, #selectables do
		curr = selectables[j]
		if prev then
			currId = curr.ref.id
			prevId = prev.ref.id
			if curr.name == prev.name then
				if currId == prevId then -- probably not yet cloned containers
					idCount = idCount + 1
					prev.name = string.format('%s %s', prev.name, idCount)
					idCount = idCount + 1
					curr.name = string.format('%s %s', curr.name, idCount)
				else
					prev.name = string.format('%s %s', prev.name, string.sub(prevId, -8))
					curr.name = string.format('%s %s', curr.name, string.sub(currId, -8))
				end
				modified = true
			end
		end
		prev = curr
	end

	if modified then
		table.sort(selectables, byNameAsc)
	end

	activateBtns = {}
	local aName
	local j = 0
	for k = 1, #selectables do
		curr = selectables[k]
		aName = curr.name
		if aName -- better safe than sorry
		 and (j < 8) then -- (9 messageBox buttons max, minus one for Cancel)
			j = j + 1
			if logLevel > 2 then
				mwse.log('%s: sorted selectables[%s] = {mobile = "%s", name = "%s"}\n%s: table.insert(activateBtns, "%s"',
					funcPrefix, j, curr.ref.id, aName, modPrefix, aName)
			end
			table.insert(activateBtns, aName)
		end
	end

	lastButtonIndex = j + 1
	if lastButtonIndex < 2 then -- should not be needed, but again better safe than sorry
		return
	end
	table.insert(activateBtns, 'Cancel')

	-- last better safe than sorry, I promise LOL , but something wrong with messageBox entries could freeze the game
	local size = table.size(activateBtns)
	if size < lastButtonIndex then
		if logLevel > 0 then
			mwse.log("%s: table.size(activateBtns) = %s\nlastButtonIndex = %s", funcPrefix, size, lastButtonIndex)
		end
		return
	end

	if logLevel >= 2 then
		local btnName
		for k = 1, #activateBtns do
			btnName = activateBtns[k]
			mwse.log("%s: activateBtns[%s] = %s", funcPrefix, k, btnName)
		end
	end

	timer.delayOneFrame(function ()
		tes3.messageBox({
			message = 'Activate:', buttons = activateBtns,
			callback = function (ev)
				---assert(ev.button >= 0)
				local index = ev.button + 1
				if logLevel >= 2 then
					mwse.log("%s: messageBox index = %s, lastButtonIndex = %s", funcPrefix, index, lastButtonIndex)
				end
				if index < lastButtonIndex then
					local sel = selectables[index]
					---assert(sel)
					local activateRef = sel.ref
					local mobi = activateRef.mobile

					local startDialog = mobi
					 and (not isMobileDead(mobi))
					 and mobi.hasFreeAction
					 and ( not string.find(string.lower(activateRef.object.id), 'summon', 1, true) )

					if startDialog then
						-- starting dialog directly is more robust with scripted NPCs than trying to player:activate()
						if logLevel >= 2 then
							mwse.log('%s: "%s":startDialogue()', funcPrefix, activateRef.id)
						end
						mobi:startDialogue()
					else
						skips = 1
						if activateRef.objectType == tes3_objectType_container then
							local mesh = activateRef.mesh
							if mesh then
								local lcMesh = string.lower(mesh)
								lcMesh = back2slash(lcMesh)
								if string.find(lcMesh, 'ac/anim_', 1, true) then
									if logLevel >= 2 then
										mwse.log("%s: animated container, don't skip", funcPrefix)
									end
									skips = 2
								end
							end
						end
						if logLevel >= 2 then
							mwse.log('%s: delayedPlayerActivate("%s", 0.15)', funcPrefix, activateRef.id)
						end
						delayedPlayerActivate(activateRef, 0.15)
						---if skips == 2 then
							return
						---end
					end
				end
				activateBtns = {}
				selectables = {}
			end
		})
	end)
	return false -- skip this activate
end


local function loaded()
	player = tes3.player
	player1stPerson = tes3.player1stPerson
	lastActivatedRef = nil
	skips = 0
	inputController = tes3.worldController.inputController
end


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

--[[
local function logConfig(cfg, options)
	mwse.log(json.encode(cfg, options))
end
]]

local yesOrNo = {[false] = 'No', [true] = 'Yes'}

local function modConfigReady()
	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		maxSelectable = config.maxSelectable
		allowDead = config.allowDead
		allowNPC = config.allowNPC
		allowCreature = config.allowCreature
		allowContainer = config.allowContainer
		allowOrganic = config.allowOrganic
		allowDoor = config.allowDoor
		logLevel = config.logLevel
		mwse.saveConfig(configName, config, {indent = true})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage({
		label = 'Preferences',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = ''})

	---local controls = preferences:createCategory{label = mcmName}
	local controls = preferences:createCategory({})

	controls:createYesNoButton({
		label = 'Enable selection menu',
		description = [[Default: Yes.
Enable selection menu to choose who to activate between up to 8 nearby actors/containers/doors.
Very useful in crowded places.
Note: you can also skip the selection menu by pressing Alt or Shift keys while activating.
]],
		variable = createConfigVariable('actorsMenu')
	})

	controls:createYesNoButton({
		label = 'Allow NPCs',
		description = string.format([[Default: %s.
Allow selecting NPCs in menu.]], yesOrNo[defaultConfig.allowNPC]),
		variable = createConfigVariable('allowNPC')
	})

	controls:createYesNoButton({
		label = 'Allow Creatures',
		description = string.format([[Default: %s.
Allow selecting creatures in menu.]], yesOrNo[defaultConfig.allowCreature]),
		variable = createConfigVariable('allowCreature')
	})

	controls:createYesNoButton({
		label = 'Allow dead actors',
		description = string.format([[Default: %s.
Allow selecting dead actors in menu.
Useful if you want to loot a dead creature or NPC.]], yesOrNo[defaultConfig.allowDead]),
		variable = createConfigVariable('allowDead')
	})

	controls:createYesNoButton({
		label = 'Allow containers',
		description = string.format([[Default: %s.
Allow selecting containers in menu.
Useful if you want to loot a container in a crowded place.]], yesOrNo[defaultConfig.allowContainer]),
		variable = createConfigVariable('allowContainer')
	})
	controls:createYesNoButton({
		label = 'Allow organic containers',
		description = string.format([[Default: %s.
Allow selecting organic/respawning containers
(e.g. plants, guild chests) in menu.]],
	yesOrNo[defaultConfig.allowOrganic]),
		variable = createConfigVariable('allowOrganic')
	})

	controls:createYesNoButton({
		label = 'Allow doors',
		description = string.format([[Default: %s.
Allow selecting one door in menu.
Useful if you want to open a door in a crowded place.
(Only one door because often loading doors are near each other so better to avoid activating the linked one)
]],yesOrNo[defaultConfig.allowDoor]),
		variable = createConfigVariable('allowDoor')
	})

	controls:createSlider({
		label = 'Max distance',
		variable = createConfigVariable('maxDistance')
		,min = 32, max = 192,
		description = string.format([[Max distance between things to classify them as colliding each other.
	Default: %s]], defaultConfig.maxDistance)
	})

	controls:createSlider({
		label = 'Max selectable',
		variable = createConfigVariable('maxSelectable')
		,min = 2, max = 8,
		description = string.format([[Max number of selectable things.
	Default: %s]], defaultConfig.maxSelectable)
	})

	controls:createDropdown({
		label = 'Logging level:',
		options = {
			{ label = '0. Off', value = 0 },
			{ label = '1. Low', value = 1 },
			{ label = '2. Medium', value = 2 },
			{ label = '3. High', value = 3 },
			{ label = '4. Max', value = 4 },
		},
		variable = createConfigVariable('logLevel'),
		description = [[Debug logging level. Default: 0. Off.]]
	})

	event.register('activate', activate, {priority = 100010}) -- higher priority than smart companions
	event.register('loaded', loaded)

	mwse.mcm.register(template)
	---logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)
