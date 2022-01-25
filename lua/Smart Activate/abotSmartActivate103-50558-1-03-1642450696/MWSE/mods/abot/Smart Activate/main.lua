--[[
allow to choose who to activate between 8 nearby actors
]]

local defaultConfig = {
actorsMenu = true, -- actorsMenu toggle
maxDistance = 48, -- Max distance between actors to classify them as colliding each other
maxActors = 8, -- Max number of selectable actors
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
			if config.logLevel > 1 then
				mwse.log("%s: %s:activate(%s)", modPrefix, activatorRef.id, targetRef.id)
			end		
			activatorRef:activate(targetRef)
		end
	})
end

local function activate(e)
	if not config.actorsMenu then
		return
	end
	local activator = e.activator
	if config.logLevel > 1 then
		mwse.log("\n%s: activate(e) e.activator = %s", modPrefix, activator)
	end
	if not (activator == tes3.player) then
		return
	end

	local target = e.target
	if config.logLevel > 1 then
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
	assert(mobile)

	local rng = config.maxDistance
	local colliders = {}

	if mobile then
		colliders[mobile] = mobile
		local boundSize = mobile.boundSize
		if boundSize then
			local boundMin = math.min(boundSize.x, boundSize.y)
			if boundMin > rng then
				rng = boundMin -- increase collision range for big creatures
				if config.logLevel > 1 then
					mwse.log("%s: max range set to %s min bound size = %s", modPrefix, target.id, rng)
				end
			end
		end
	end

	-- target actor included (even more than once), but dead actors not included
	local mobilesNear = tes3.findActorsInProximity({ reference = target, range = rng })
	---assert(mobilesNear)

	local mobilePlayer = tes3.mobilePlayer
	for _, m in pairs(mobilesNear) do
		if not (m == mobilePlayer) then
			local ref = m.reference
			if ref then
				if not colliders[m] then
					colliders[m] = m
					if config.logLevel > 1 then
						mwse.log("%s: %s colliding", modPrefix, m.reference.id)
					end
				end
			end
		end
	end

	local collidersArray = {}
	local i = 0
	for _, m in pairs(colliders) do
		i = i + 1
		collidersArray[i] = {mobile = m, name = m.reference.object.name}
		if config.logLevel > 1 then
			mwse.log('%s: collidersArray[%s] = {mobile = %s, name = %s}', modPrefix, i, m.reference.id, m.reference.object.name)
		end
	end

	if i < 2 then
		return
	end

	table.sort(collidersArray, sortf)

	local prev = nil
	for _, c in ipairs(collidersArray) do
		if prev then
			if c.name == prev.name then
				-- add digit suffix in case of clones
				c.name = c.name .. string.sub(c.mobile.reference.id, -8)
				prev.name = prev.name .. string.sub(prev.mobile.reference.id, -8)
			end
		end
		prev = c
	end
	table.sort(collidersArray, sortf)

	activateBtns = {}
	local j = 0
	for _, c in ipairs(collidersArray) do
		if j < 8 then
			j = j + 1
			if config.logLevel > 1 then
				mwse.log('%s: collidersArray[%s] = {mobile = %s, name = %s}', modPrefix, j, c.mobile.reference.id, c.name)
				mwse.log('%s: table.insert(activateBtns, %s)', modPrefix, c.name)
			end
			table.insert(activateBtns, c.name)
		end
	end
	
	table.insert(activateBtns, 'Cancel')
	local lastButtonIndex = table.size(activateBtns)
	if lastButtonIndex < 2 then
		return -- just in case
	end

	timer.delayOneFrame(function ()
		tes3.messageBox({
			message = 'Activate:', buttons = activateBtns,
			callback = function (ev)
				---assert(ev.button >= 0)
				local index = ev.button + 1
				if index < lastButtonIndex then
					local mob = collidersArray[index].mobile
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
						if config.logLevel > 1 then
							mwse.log("%s: delayedActivate(tes3.player, %s, 0.15)", modPrefix, activateRef.id)
						end
						delayedActivate(tes3.player, activateRef, 0.15)
					else
						-- starting dialog directly is more robust with scripted NPCs than trying to tes3.player:activete() them
						if config.logLevel > 1 then
							mwse.log("%s: %s:startDialogue()", modPrefix, mob.reference.id)
						end
						mob:startDialogue()
					end
				end
				activateBtns = {}
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
