--[[
Try some smart auto-switch between local and world map /abot
--]]

-- begin configurable parameters

local defaultConfig = {
onEnteringInteriors = true, -- Allow changing map display when entering interior cells
onCrossingExteriors = true, -- Allow changing map display when crossing exterior cells
minExteriorCellLinkedDoorsForLocalMap = 4, -- Minimum number of linked doors in exterior to consider worth displaying the local map
localMapWithHostiles = true,
minActorAiFightTrigger = 82, -- Min actor AI Fight setting to be judged hostile
maxHostileDistanceTrigger = 3500, -- Max distance of hostile actor from player to trigger local map
fixTRpreview = true, -- try and fix ugly TR preview cell names on map header
}

-- end configurable parameters

local author = 'abot'
local modName = 'Smart Map'
local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

-- 2nd parameter advantage: anything not defined in the loaded file inherits the value from defaultConfig
local config = mwse.loadConfig(configName, defaultConfig) or defaultConfig
assert(config)

local mcm = require(author .. '.' .. modName .. '.mcm')
mcm.config = table.copy(config)

local function modConfigReady()
	mwse.registerModConfig(mcmName, mcm)
	mwse.log(modPrefix .. " modConfigReady")
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)

function mcm.onClose()
	config = table.copy(mcm.config)
	mwse.saveConfig(configName, config, {indent = false})
end


-- functions to e.g. avoid heavy/crashy loops on CellChange
-- when player is moving too fast e.g. superjumping

local scenicTravelAvailable  -- set in initialized()

local function initScenicTravelAvailable() -- call in initialized()
	if tes3.getGlobal('ab01boDest') then
		scenicTravelAvailable = true
	elseif tes3.getGlobal('ab01ssDest') then
		scenicTravelAvailable = true
	elseif tes3.getGlobal('ab01goDest') then
		scenicTravelAvailable = true
	elseif tes3.getGlobal('ab01compMounted') then
		scenicTravelAvailable = true
	else
		scenicTravelAvailable = false
	end
end

local function isGlobalPositive(globalVarId)
	local v = tes3.getGlobal(globalVarId)
	if v then
		if v > 0 then
			if math.floor(v) > 0 then
				return true
			end
		end
	end
	return false
end

local function isPlayerScenicTraveling()
	if not scenicTravelAvailable then
		return false
	end
	if isGlobalPositive('ab01boDest') then
		return true -- if scenic boat traveling
	end
	if isGlobalPositive('ab01ssDest') then
		return true -- if scenic strider traveling
	end
	if isGlobalPositive('ab01goDest') then
		return true -- if scenic gondola traveling
	end
	if isGlobalPositive('ab01compMounted') then
		return true -- if guar riding
	end
end

local function isPlayerMovingFast()
	local mobilePlayer = tes3.mobilePlayer
	if mobilePlayer then
		local velocity = mobilePlayer.velocity
		if velocity then
			if #velocity >= 300 then
				return true
			end
		end
	end
	return false
end

local GUIID_MenuMap = tes3ui.registerID('MenuMap')
local MenuMap_world = tes3ui.registerID('MenuMap_world')
local MenuMap_local = tes3ui.registerID('MenuMap_local')
local MenuMap_switch = tes3ui.registerID('MenuMap_switch')

--- local mapMenu -- nope fucking thing is hard to cache as it may be valid/invalid/not ready on loaded
local interior
local severalExteriorLinkedDoors
local hostileCell

--  note uiActivated for map may trigger before loaded event, so better to reset cached pointers from both events
local function uiActivated(e)
	local mapMenu = e.element
	interior = nil
	severalExteriorLinkedDoors = nil
	hostileCell = nil
	---lastInterior = nil
	---mwse.log("%s: 2 uiActivated mapMenu = %s", modPrefix, mapMenu)
	if not mapMenu then
		assert(mapMenu)
	end
	local switchButton = mapMenu:findChild(MenuMap_switch)
	if not switchButton then
		assert(switchButton)
		return
	end
	--[[mapMenu:register('keyEnter', function()
		switchButton:triggerEvent('mouseClick')
	end)--]]

end

local function loaded()
	interior = nil -- this is less of a problem as it is updated in cellChanged
	severalExteriorLinkedDoors = nil
	hostileCell = nil
end

local function fixTRpreviewCellName(map)
	local s = map.text
	if not s then
		return
	end
	if not s:upper():startswith('TR_') then
		return
	end
	-- ugly TR_Preview cell names
	local lastExteriorCell = tes3.dataHandler.lastExteriorCell
	if not lastExteriorCell then
		return
	end
	s = lastExteriorCell.id
	if (
		(not s)
	 or (s == '')
	 or (s:upper():startswith('TR_'))
	) then
		local region = lastExteriorCell.region
		if region then
			s = region.name
		end
	end
	if not s then
		return
	end
	if s == '' then
		return
	end
	local cell = tes3.getPlayerCell()
	if cell.isInterior then
		if not cell.behavesAsExterior then
			s = string.format("%s interior", s)
		end
	end
	map.text = s
end

local function updateMap()

	---mwse.log("%s: updateMap()", modPrefix)
	local mapMenu = tes3ui.findMenu(GUIID_MenuMap)

	if not mapMenu then
		-- assert(mapMenu) -- it may happen!
		---mwse.log("%s: updateMap mapMenu = %s", modPrefix, mapMenu)
		return
	end
	--if not mapMenu.visible then
		---mwse.log("%s: updateMap mapMenu.visible = %s", modPrefix, mapMenu.visible)
		--return -- skipping return as this way it should work even when not pinned
	--end
	--if mapMenu.disabled then
		---mwse.log("%s: updateMap mapMenu.disabled = %s", modPrefix, mapMenu.disabled)
		--return
	--end
	local worldMap = mapMenu:findChild(MenuMap_world)
	if not worldMap then
		---assert(worldMap) -- it happens!
		return
	end
	local localMap = mapMenu:findChild(MenuMap_local)
	if not localMap then
		assert(localMap)
		return
	end
	local switchButton = mapMenu:findChild(MenuMap_switch)
	if not switchButton then
		assert(switchButton)
		return
	end

	---mwse.log("%s: 4 updateMap interior = %s, severalExteriorLinkedDoors = %s, localMap.visible = %s", modPrefix, interior, severalExteriorLinkedDoors, localMap.visible)

	if interior then
		if localMap.visible then
			if config.fixTRpreview then
				fixTRpreviewCellName(localMap)
			end
			return -- local map already visible in interior cell, always worth, return
		end
	else -- exterior cell
		local switchToLocal = severalExteriorLinkedDoors or (hostileCell and config.localMapWithHostiles)
		if localMap.visible then
			if switchToLocal then
				return -- local map already visible in doors filled exterior cell, or hostiles present so return
			end
		else -- world map already visible in exterior cell,
			if not switchToLocal then -- not a lot of doors, or hostiles present
				if worldMap.visible then
					if config.fixTRpreview then
						fixTRpreviewCellName(worldMap)
					end
				end
				return
			end
		end
	end

	-- else switch
	switchButton:triggerEvent('mouseClick')

	---local playerCell = tes3.getPlayerCell()
	---if playerCell then
		---if interior then
			---mwse.log("%s: switched to %s Local Map", modPrefix, playerCell)
		---else
			---mwse.log("%s: switched to %s World Map", modPrefix, playerCell)
		---end
	---end
end

local DOORTYPE = tes3.objectType.door

local function getLinkedDoorsCount(cell)
	local i = 0
	local m = config.minExteriorCellLinkedDoorsForLocalMap

	for linkedDoorRef in tes3.iterate(cell.activators) do
		if not linkedDoorRef.disabled then
			if not linkedDoorRef.deleted then
				local linkedDoorObj = linkedDoorRef.object
				if linkedDoorObj then
					if linkedDoorObj.objectType == DOORTYPE then
						if linkedDoorRef.destination then
							i = i + 1
							if i >= m then
								break
							end
						end -- if linkedDoorRef.destination
					end -- if linkedDoorObj.objectType
				end -- if linkedDoorObj
			end -- if not linkedDoorRef.deleted
		end -- if not linkedDoorRef.disabled
	end -- for linkedDoorRef
	return i
end

local function getFirstHostile(cell, fightLevel, maxDistance)
	local player = tes3.player
	for actor in tes3.iterate(cell.actors) do
		local mobile = actor.mobile
		if mobile then
			if not (mobile.actorType == 2) then -- 0 = creature, 1 = NPC, 2 = player
				if mobile.fight >= fightLevel then
					if player.position:distance(mobile.position) <= maxDistance then
						return mobile
					end
				end
			end
		end
	end
	return false
end

local function cellChanged(e)

	---mwse.log("%s: cellChanged", modPrefix)

	local mapMenu = tes3ui.findMenu(GUIID_MenuMap)

	--[[
	if mapMenu then
		mwse.log("%s: cellChanged mapMenu %s mapMenu.visible %s", modPrefix, mapMenu, mapMenu.visible)
	else
		mwse.log("%s: cellChanged mapMenu %s", modPrefix, mapMenu)
	end
	--]]
	if not mapMenu then
		return
	end

	--if not mapMenu.visible then
		--return
	--end

	interior = e.cell.isInterior

	---mwse.log("%s: 3 cellChanged interior = %s", modPrefix, interior)

	severalExteriorLinkedDoors = false

	if interior then
		if config.onEnteringInteriors then
			---if not e.cell.behavesAsExterior then
			updateMap()
			---end
		end
		return
	end

	-- exterior cell
	if not config.onCrossingExteriors then
		return -- skip disallowed exterior changes
	end

	if isPlayerMovingFast() then
		return
	end

	if isPlayerScenicTraveling() then
		return
	end

	local linkedDoorsCount = getLinkedDoorsCount(e.cell)
	--- mwse.log("%s: 3 cellChanged linkeDoorsCount = %s", modPrefix, linkedDoorsCount)
	if linkedDoorsCount >= config.minExteriorCellLinkedDoorsForLocalMap then
		severalExteriorLinkedDoors = true
	end

	if config.localMapInHostileCells then
		hostileCell = false
		if not e.cell.restingIsIllegal then -- skip safe settlement
			local hostileActor = getFirstHostile(e.cell, config.minActorAiFightTrigger, config.maxHostileDistanceTrigger)
			if hostileActor then
				hostileCell = true
			end
		end
	end

	timer.delayOneFrame(updateMap)

end

local function initialized()
	initScenicTravelAvailable()
	event.register('uiActivated', uiActivated, {filter = 'MenuMap'})
	event.register('loaded', loaded)
	event.register('cellChanged', cellChanged)
	local s = string.format("%s: initialized", modPrefix)
	mwse.log(s)
	---tes3.messageBox(s)
end
event.register('initialized', initialized)
