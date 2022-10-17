--[[
allow to choose who to activate between 8 nearby actors
]]

local defaultConfig = {
actorsMenu = true, -- actorsMenu toggle
maxDistance = 48, -- Max distance between actors to classify them as colliding each other
maxActors = 8, -- Max number of selectable actors
allowDead = true, -- allow selecting dead actors
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium
}

local author = 'abot'
local modName = 'Smart Activate'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

local config = mwse.loadConfig(configName, defaultConfig)

local maxActors = config.maxActors
local allowDead = config.allowDead
local logLevel = config.logLevel

local AS_DEAD = tes3.animationState.dead
local AS_DYING = tes3.animationState.dying

local function isMobileDead(mobile)
	local health = mobile.health
	if health then
		if health.current then
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

local tes3_objectType_npc = tes3.objectType.npc
local tes3_objectType_creature = tes3.objectType.creature
---local tes3_actionFlag_useEnabled = tes3.actionFlag.useEnabled

local lastActivatedRef -- reset in loaded()

local function sortf(a, b)
	return a.name < b.name
end

-- initialized in loaded()
local inputController

local tes3_scanCode_lAlt = tes3.scanCode.lAlt
local tes3_scanCode_lShift = tes3.scanCode.lShift

local activateBtns = {}
local lastButtonIndex = 0

local activateRef

local function delayedActivate(activatorRef, targetRef, delaySec)
	local targetHandle = tes3.makeSafeObjectHandle(targetRef)
	local activatorHandle = tes3.makeSafeObjectHandle(activatorRef)
	timer.start({duration = delaySec, type = timer.real,
		callback = function ()
			if not targetHandle then
				return
			end
			if not activatorHandle then
				return
			end
			if not targetHandle:valid() then
				return
			end
			if not activatorHandle:valid() then
				return
			end
			targetRef = targetHandle:getObject()
			if not targetRef then
				return
			end
			activatorRef = activatorHandle:getObject()
			if not activatorRef then
				return
			end
			if logLevel > 1 then
				mwse.log('%s: "%s":activate("%s")', modPrefix, activatorRef.id, targetRef.id)
			end
			activatorRef:activate(targetRef)
		end
	})
end


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

	local i = 0
	local j = 0
	local c
	for gridX = cellGridX - 1, cellGridX + 1 do
		for gridY = cellGridY - 1, cellGridY + 1 do
			i = i + 1
			if not skip[i] then
				c = tes3.getCell({x = gridX, y = gridY})
				if c then
					j = j + 1
					cells[j] = c
					---mwse.log("culledCell = %s", c.editorName)
				elseif logLevel > 0 then
					mwse.log("%s: tes3.getCell({x = %s, y = %s}) failed", modPrefix, gridX, gridY)
				end
			end
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

local function findActorsInProximity(ref, range)
	local culledCells = getCulledCells(ref, range)
	local refPos = ref.position
	local dist, mob
	local t = {}
	local player = tes3.player
	local i = 1
	for _, cell in ipairs(culledCells) do
		for _, aRef in pairs(cell.actors) do
			if not (aRef == player) then
				dist = refPos:distance(aRef.position)
				if dist <= range then
					if not aRef.disabled then
						if not aRef.deleted then
							mob = aRef.mobile
							if mob then
								if allowDead
								or (not isMobileDead(mob)) then
									if i <= maxActors then
										t[i] = mob
										i = i + 1
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return t
end

local collidersArray = {}

local function activate(e)
	if not config.actorsMenu then
		return
	end
	local activator = e.activator
	if logLevel > 1 then
		mwse.log("\n%s: activate(e) e.activator = %s", modPrefix, activator)
	end
	if not (activator == tes3.player) then
		return
	end

	local target = e.target
	if logLevel > 1 then
		mwse.log("%s: activate(e) e.target = %s", modPrefix, target)
	end
	local obj = target.object
	local objType = obj.objectType
	if not (
		(objType == tes3_objectType_npc)
	 or (objType == tes3_objectType_creature)
	) then
		return
	end

	if inputController:isKeyDown(tes3_scanCode_lAlt)
	or inputController:isKeyDown(tes3_scanCode_lShift) then
		return -- skip if Alt or Shift pressed
	end

	if target == lastActivatedRef then
		lastActivatedRef = nil
		return
	end

	local mobile = target.mobile
	---assert(mobile) -- nope, it may be nil

	local rng = config.maxDistance
	local colliders = {}

	if mobile then
		colliders[mobile] = mobile
		local boundSize = mobile.boundSize
		if boundSize then
			local boundMin = math.min(boundSize.x, boundSize.y)
			if boundMin > rng then
				rng = boundMin -- increase collision range for big creatures
				if logLevel > 1 then
					mwse.log("%s: max range set to %s min bound size = %s", modPrefix, target.id, rng)
				end
			end
		end
	end

	-- target actor included (even more than once), but dead actors not included
	---local mobilesNear = tes3.findActorsInProximity({ reference = target, range = rng })
	local mobilesNear = findActorsInProximity(target, rng)
	---assert(mobilesNear)

	---local mobilePlayer = tes3.mobilePlayer
	local i = 0

	for _, m in pairs(mobilesNear) do
		---if not (m == mobilePlayer) then
		local ref = m.reference
		if ref then
			if not colliders[m] then
				i = i + 1
				colliders[m] = m
				if logLevel > 1 then
					mwse.log("%s: %s colliding", modPrefix, m.reference.id)
				end
			end
		end
		---end
	end

	if i < 1 then
		return
	end

	collidersArray = {}
	i = 0
	local n
	for _, m in pairs(colliders) do
		n = m.reference.object.name
		if n then
-- important! the messagebox may freeze on empty button text!
-- e.g. invisible tiny sonar race NPCs could have no name
			if not (n == '') then
				i = i + 1
				collidersArray[i] = {mobile = m, name = n}
				if logLevel > 1 then
					mwse.log('%s: collidersArray[%s] = {mobile = "%s", name = "%s"}', modPrefix, i, m.reference.id, n)
				end
			end
		end
	end

	if i < 2 then
		return
	end

	table.sort(collidersArray, sortf)

	local prev = nil
	local cId, prevId
	for _, c in ipairs(collidersArray) do
		if prev then
			cId = c.mobile.reference.id
			prevId = prev.mobile.reference.id
			if c.name == prev.name then
				-- add digit suffix in case of clones
				c.name = c.name .. string.sub(cId, -8)
				prev.name = prev.name .. string.sub(prevId, -8)
			end
			if c.name == prev.name then
				c.name = cId
				prev.name = prevId
			end
		end
		prev = c
	end
	table.sort(collidersArray, sortf)

	activateBtns = {}
	local j = 0
	for _, c in ipairs(collidersArray) do
		if c then
			if c.name then -- better safe than sorry
				if j < 8 then
					j = j + 1
					if logLevel > 2 then
						mwse.log('%s: sorted collidersArray[%s] = {mobile = "%s", name = "%s"}', modPrefix, j, c.mobile.reference.id, c.name)
						mwse.log('%s: table.insert(activateBtns, "%s")', modPrefix, c.name)
					end
					table.insert(activateBtns, c.name)
				end
			end
		end
	end

	table.insert(activateBtns, 'Cancel')
	lastButtonIndex = j + 1
	if lastButtonIndex < 2 then
		return
	end
	local size = table.size(activateBtns)
	assert(size >= lastButtonIndex)
	if logLevel > 1 then
		mwse.log("table.size(activateBtns) = %s", size)
		mwse.log("lastButtonIndex = %s", lastButtonIndex)
	end
	if logLevel > 1 then
		for _, btn in pairs(activateBtns) do
			mwse.log("activateBtns btn = %s", btn)
		end
	end
	timer.delayOneFrame(function ()
		tes3.messageBox({
			message = 'Activate:', buttons = activateBtns,
			callback = function (ev)
				---assert(ev.button >= 0)
				local index = ev.button + 1
				if logLevel > 1 then
					mwse.log("index = %s, lastButtonIndex = %s", index, lastButtonIndex)
				end
				if index < lastButtonIndex then
					local colli = collidersArray[index]
					assert(colli)
					local mob = colli.mobile
					assert(mob)
					activateRef = mob.reference
					assert(activateRef)
					--[[if string.sub(activateRef.id, -1) == '0' then
						local fr = tes3.getReference(activateRef.baseObject.id)
						assert(fr == activateRef) -- if not, it means getReference may work better?
					end]]
					if isMobileDead(mob)
					or (not mob.hasFreeAction)
					or string.find(activateRef.object.id:lower(), 'summon', 1, true) then
						lastActivatedRef = activateRef
						if logLevel > 1 then
							mwse.log('%s: delayedActivate(tes3.player, "%s", 0.15)', modPrefix, lastActivatedRef.id)
						end
						delayedActivate(tes3.player, lastActivatedRef, 0.15)
					else
						-- starting dialog directly is more robust with scripted NPCs than trying to tes3.player:activate()
						if logLevel > 1 then
							mwse.log('%s: "%s":startDialogue()', modPrefix, activateRef.id)
						end
						mob:startDialogue()
					end
				end
				activateBtns = {}
				collidersArray = {}
			end
		})
	end)
	return false -- skip this activate
end


local function loaded()
	lastActivatedRef = nil
	inputController = tes3.worldController.inputController
end

local function initialized()
	event.register('activate', activate)
	event.register('loaded', loaded)
end
event.register('initialized', initialized)


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		maxActors = config.maxActors
		allowDead = config.allowDead
		logLevel = config.logLevel
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label = 'Preferences',
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{text = ''}

	---local controls = preferences:createCategory{label = mcmName}
	local controls = preferences:createCategory{}

	controls:createYesNoButton{
		label = 'Enable actors menu',
		description = [[Default: Yes.
Enable Actors menu to choose who to activate between up to 8 nearby actors.
Very useful in crowded places.
Note: you can also skip the Actors menu pressing Alt or Shift keys while activating.
]],
		variable = createConfigVariable('actorsMenu')
	}

	controls:createYesNoButton{
		label = 'Allow selecting dead actors',
		description = [[Default: Yes.
Allow selecting dead actors.
Useful if you want to loot a dead creature or NPC.
]],
		variable = createConfigVariable('allowDead')
	}

	controls:createSlider{
		label = 'Max distance',
		variable = createConfigVariable('maxDistance')
		,min = 32, max = 192,
		description = string.format([[Max distance between actors to classify them as colliding each other.
	Default: %s]], defaultConfig.maxDistance)
	}

	controls:createSlider{
		label = 'Max actors',
		variable = createConfigVariable('maxActors')
		,min = 2, max = 8,
		description = string.format([[Max number of selectable actors.
	Default: %s]], defaultConfig.maxActors)
	}

	controls:createDropdown{
		label = 'Logging level:',
		options = {
			{ label = '0. Off', value = 0 },
			{ label = '1. Low', value = 1 },
			{ label = '2. Medium', value = 2 },
		},
		variable = createConfigVariable('logLevel'),
		description = [[Debug logging level. Default: 0. Off.]]
	}

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)
