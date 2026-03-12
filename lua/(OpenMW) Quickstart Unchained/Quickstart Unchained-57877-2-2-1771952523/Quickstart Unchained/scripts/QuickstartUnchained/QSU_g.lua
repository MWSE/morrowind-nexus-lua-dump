I = require('openmw.interfaces')
world	= require('openmw.world')
types	= require('openmw.types')
core	= require('openmw.core')
async	= require('openmw.async')
util	= require('openmw.util')
time	= require('openmw_aux.time')
v3 = util.vector3

require("scripts.QuickstartUnchained.QSU_parseScenarios")
require("scripts.QuickstartUnchained.QSU_globalHelpers")
require("scripts.QuickstartUnchained.QSU_helpers")

local worldFrozen = false
local chargenDoor

local function getPlayer()
	return world.players[1]
end

-- Dispatch to scenarios, return false if any handler returns false
local function dispatchWithBlock(handlerName, ...)
	if not saveData.activeScenarios then return end
	for scenarioName, scenarioData in pairs(saveData.activeScenarios) do
		local scenario = scenarios[scenarioName]
		if scenario and scenario.globalScripts and scenario.globalScripts[handlerName] then
			local result = scenario.globalScripts[handlerName](...)
			if result == false then
				return false
			end
		end
	end
end

-- Register ItemUsage handlers for common types
local itemTypes = {types.Potion, types.Ingredient, types.Armor, types.Clothing, types.Weapon, types.Book, types.Miscellaneous}
for _, itemType in ipairs(itemTypes) do
	I.ItemUsage.addHandlerForType(itemType, function(item, actor)
		return dispatchWithBlock("onUseItem", item, actor)
	end)
end

-- Register Activation handlers for common types
local activatableTypes = {types.Door, types.Container, types.NPC, types.Creature, types.Activator}
for _, objType in ipairs(activatableTypes) do
	I.Activation.addHandlerForType(objType, function(object, actor)
		return dispatchWithBlock("onActivate", object, actor)
	end)
end

-- Dispatch an event to all active scenarios' globalScripts
local function dispatchGlobalEvent(handlerName, ...)
	if not saveData.activeScenarios then return end
	for scenarioName, scenarioData in pairs(saveData.activeScenarios) do
		local scenario = scenarios[scenarioName]
		if scenario and scenario.globalScripts and scenario.globalScripts[handlerName] then
			scenario.globalScripts[handlerName](scenarioData.player, ...)
		end
	end
end

local keepChargenDoors = {
["chargen customs door"] = true,
["chargen door captain"] = true,
["chargendoorjournal"] = true,
["chargen barrel fatigue"] = true,
}
local fixChargenDoors = {
["chargen customs door"] = true,
--["chargen door captain"] = true, --mystery bug
["chargendoorjournal"] = true,
["chargen barrel fatigue"] = true,
}

-- Teleport objects to player's cell to set mwscript vars on inactive objects, then teleport back
local function setMWScriptVarsRemote(entries, player)
	if not player or #entries == 0 then return end
	local offset = v3(700, 700, 0) -- far underground so invisible
	-- Store originals and teleport to player's active cell
	for _, entry in ipairs(entries) do
		entry.origCell = entry.obj.cell
		entry.origPos = entry.obj.position
		entry.origRot = entry.obj.rotation
		entry.obj:teleport(player.cell, player.position + offset)
	end
	-- Next frame: objects should be active, set variables
	async:newUnsavableSimulationTimer(0.1, async:callback(function()
		for _, entry in ipairs(entries) do
			local script = world.mwscript.getLocalScript(entry.obj)
			if script and script.variables then
				for k, v in pairs(entry.vars) do
					script.variables[k] = v
				end
				print("QSU: Set mwscript vars on " .. entry.obj.recordId)
			else
				print("QSU: WARNING - could not get local script for " .. entry.obj.recordId)
			end
		end
		-- Next frame: teleport back to original location
		async:newUnsavableSimulationTimer(0.1, async:callback(function()
			for _, entry in ipairs(entries) do
				entry.obj:teleport(entry.origCell, entry.origPos, {
					rotation = entry.origRot,
				})
			end
		end))
	end))
end

-- Fix census office interior: unlock doors and set mwscript vars via teleport trick
local function fixCensusOfficeInterior()
	local player = getPlayer()
	if not player then
		print("QSU: WARNING - no player found, cannot fix census office mwscript vars")
		return
	end
	local censusDoor = world.getObjectByFormId(core.getFormId('Morrowind.esm', 113833))
	if not censusDoor or not censusDoor:isValid() then return end
	local cell = types.Door.destCell(censusDoor)
	if not cell then return end
	local _ = cell:getAll() -- force cell content load
	-- Unlock doors
	local lock1 = world.getObjectByFormId(core.getFormId('Morrowind.esm', 1464180))
	if lock1 and lock1:isValid() then types.Lockable.unlock(lock1) end
	local lock2 = world.getObjectByFormId(core.getFormId('Morrowind.esm', 1464184))
	if lock2 and lock2:isValid() then types.Lockable.unlock(lock2) end
	-- Collect objects that need mwscript var changes
	local toFix = {}
	local SocuciusErgalla = world.getObjectByFormId(core.getFormId('Morrowind.esm', 1464178))
	if SocuciusErgalla and SocuciusErgalla:isValid() then
		table.insert(toFix, {obj = SocuciusErgalla, vars = {state = -1, State = -1}})
	end
	--local ExitDoor = world.getObjectByFormId(core.getFormId('Morrowind.esm', 1464186)) --mystery bug
	--if ExitDoor and ExitDoor:isValid() then
	--	table.insert(toFix, {obj = ExitDoor, vars = {done = 1}})
	--end
	if #toFix > 0 then
		setMWScriptVarsRemote(toFix, player)
	end
end

local function deleteChargenBoat()
	local cells = {
		world.getExteriorCell(-2, -9),
		world.getExteriorCell(-1, -9),
		world.getExteriorCell(-2, -10),
	}
	for _, cell in ipairs(cells) do
		for _, obj in ipairs(cell:getAll()) do
			if keepChargenDoors[obj.recordId] then
				if fixChargenDoors[obj.recordId] then
					local script = world.mwscript.getLocalScript(obj)
					if script and script.variables then
						script.variables.done = 1
					end
				end
			elseif obj.recordId:find("chargen") then
				obj.enabled = false
			end
		end
	end
	fixCensusOfficeInterior()
end


local function bypassChargen(data)
	local player = data[1]
	local plus = data[2]
	world.setSimulationTimeScale(1)
	world.createObject("bk_a1_1_caiuspackage", 1):moveInto( types.NPC.inventory(player))
	--player:teleport(world.getExteriorCell(0,0), util.vector3(-14820.7, -13332.2, 962.8), {rotation = util.transform.rotateZ(math.rad(270))})
	
	async:newUnsavableSimulationTimer(0.05, async:callback(function() 
		--player:sendEvent("Quickstart_Unchained_showRaceMenu") 
		
		async:newUnsavableSimulationTimer(0.2, async:callback(function()
			chargenDoor = world.createObject("chargen exit door", 1)
			chargenDoor:teleport(player.cell, player.position)
			async:newUnsavableSimulationTimer(0.05, async:callback(function()
				local gv = world.mwscript.getGlobalVariables(player)
				gv.CharGenState = -1
				chargenDoor:activateBy(player)
				async:newUnsavableSimulationTimer(0.05, async:callback(function() 
					chargenDoor:remove()
					chargenDoor = nil
					print("WTF BY 1")
					player:sendEvent("Quickstart_Unchained_setupComplete")
				end))
			end))
		end))
	end))
end


local function handleStartScenario(data)
	local player = data[1]
	local scenarioId = data[2]
	local scenarioData = scenarios[scenarioId]
	
	local location = scenarioData.locationScript(player)
	
	local cellId = location.cell
	local refNpc = location.refNpc
	local position = location.position
	local rotation = location.rotation
	local gridX = location.gridX
	local gridY = location.gridY
	local onSelected = scenarioData.globalScripts and scenarioData.globalScripts.onSelected
	
	local cell = nil
	
	world.setSimulationTimeScale(1)
	player:sendEvent("Quickstart_Unchained_bypassChargen")
	-- Handle exterior cells with grid coordinates
	if gridX and gridY then
		cell = world.getExteriorCell(gridX, gridY)
	elseif cellId then
		-- Try to find interior cell by name/id
		local success, result = pcall(function()
			return world.getCellById(cellId:lower())
		end)
		if success then
			cell = result
		elseif refNpc then
			for a,b in pairs(world.cells) do
				if not b.isExterior then
					for c,d in pairs(b:getAll(types.NPC)) do
						if d.recordId == refNpc then
							cell = b
							break
						end
					end
					if cell then break end
				end
			end
		end
	end
	
	if onSelected then
		onSelected(player, cell)
	end
	
	-- Call playerScripts.onSelected if it exists
	--if scenarioData.playerScripts and scenarioData.playerScripts.onSelected then
	--	player:sendEvent("Quickstart_Unchained_scenarioOnSelected", scenarioId)
	--end
	
	-- Activate global scenario if it has ongoing globalScripts
	local gs = scenarioData.globalScripts
	if gs and (gs.onLoad or gs.onUpdate or gs.onActivate or gs.onUseItem or gs.onActorActive or gs.onObjectActive or gs.onItemActive or gs.eventHandlers or gs.onEnd) then
		if not saveData.activeScenarios then saveData.activeScenarios = {} end
		saveData.activeScenarios[scenarioId] = {
			player = player,
		}
		print("Activated global scenario: " .. scenarioId)
	end
	
	if cell then
		deleteChargenBoat()
		player:teleport(cell, position, {
			onGround = false,
			rotation = rotation,
		})
		print("Teleported player to: " .. (cellId or ("exterior " .. (gridX or "?") .. "," .. (gridY or "?"))))
	else
		print("Could not find cell: " .. (cellId or "exterior"))
		-- Fallback: default location
		player:teleport(world.getExteriorCell(0,0), util.vector3(-14820.7, -13332.2, 962.8), {rotation = util.transform.rotateZ(math.rad(270))})
	end
end

local function onUpdate(dt)
	if worldFrozen then
		world.setSimulationTimeScale(0)
	end
	if not saveData.activeScenarios then return end
	
	for scenarioName, scenarioData in pairs(saveData.activeScenarios) do
		local scenario = scenarios[scenarioName]
		if scenario and scenario.globalScripts and scenario.globalScripts.onUpdate then
			scenario.globalScripts.onUpdate(scenarioData.player, dt)
		end
	end
end

--local function onActorActive(actor)
--	dispatchGlobalEvent("onActorActive", actor)
--end
--
local function onObjectActive(object)
	dispatchGlobalEvent("onObjectActive", object)
end
--
--local function onItemActive(item)
--	dispatchGlobalEvent("onItemActive", item)
--end

function endScenario(scenarioName)
	if saveData.activeScenarios and saveData.activeScenarios[scenarioName] then
		local scenario = scenarios[scenarioName]
		local player = saveData.activeScenarios[scenarioName].player
		if scenario and scenario.globalScripts and scenario.globalScripts.onEnd then
			scenario.globalScripts.onEnd(player)
		end
		saveData.activeScenarios[scenarioName] = nil
		if not next(saveData.activeScenarios) then saveData.activeScenarios = nil end
		if player then
			player:sendEvent("Quickstart_Unchained_endPlayerScenario", scenarioName)
		end
		print("Ended global scenario: " .. scenarioName)
	end
end

-- Event handler version that doesn't notify player (to avoid loop)
local function endGlobalScenarioEvent(scenarioName)
	if saveData.activeScenarios and saveData.activeScenarios[scenarioName] then
		local scenario = scenarios[scenarioName]
		local player = saveData.activeScenarios[scenarioName].player
		if scenario and scenario.globalScripts and scenario.globalScripts.onEnd then
			scenario.globalScripts.onEnd(player)
		end
		saveData.activeScenarios[scenarioName] = nil
		if not next(saveData.activeScenarios) then saveData.activeScenarios = nil end
		print("Ended global scenario: " .. scenarioName)
	end
end

local function fixDisabledChargenDoors()
	local cells = {
		world.getExteriorCell(-2, -9),
		world.getExteriorCell(-1, -9),
		world.getExteriorCell(-2, -10),
	}
	for _, cell in ipairs(cells) do
		for _, obj in ipairs(cell:getAll()) do
			if keepChargenDoors[obj.recordId] then
				if not obj.enabled then
					obj.enabled = true
				end
				if fixChargenDoors[obj.recordId] then
					local script = world.mwscript.getLocalScript(obj)
					if script and script.variables then
						script.variables.done = 1
					end
				end
			end
		end
	end
	fixCensusOfficeInterior()
end

local function onLoad(data)
	saveData = data or {version = 2}
	
	-- Fix savegames where chargen doors were accidentally disabled
	if not saveData.version then
		async:newUnsavableSimulationTimer(0.1, async:callback(function()
			fixDisabledChargenDoors()
			saveData.version = 2
			print("QSU: Fixed disabled chargen doors")
		end))
	end
	-- Fix savegames where chargen doors were accidentally disabled
	--if saveData.version <3 then
	--	async:newUnsavableSimulationTimer(0.1, async:callback(function()
	--		fixDisabledChargenDoors()
	--		saveData.version = 3
	--		print("QSU: Fixed disabled chargen doors")
	--	end))
	--end
	
	-- Call onLoad for each active scenario (delayed to ensure world is ready)
	if saveData.activeScenarios then
		async:newUnsavableSimulationTimer(0.1, async:callback(function()
			for scenarioName, scenarioData in pairs(saveData.activeScenarios) do
				local scenario = scenarios[scenarioName]
				if scenario and scenario.globalScripts and scenario.globalScripts.onLoad then
					scenario.globalScripts.onLoad(scenarioData.player)
				end
			end
		end))
	end
end

local function onSave()
	return saveData
end

-- Dispatch custom events to active scenarios
local function dispatchCustomGlobalEvent(eventName, data)
	if not saveData.activeScenarios then return end
	for scenarioName, scenarioData in pairs(saveData.activeScenarios) do
		local scenario = scenarios[scenarioName]
		local handlers = scenario and scenario.globalScripts and scenario.globalScripts.eventHandlers
		if handlers and handlers[eventName] then
			handlers[eventName](scenarioData.player, data)
		end
	end
end

local function toggleWorldFreeze(data)
	local player = data[1]
	local state = data[2]
	
	worldFrozen = state
	
	if worldFrozen then
		world.setSimulationTimeScale(0)
	else
		world.setSimulationTimeScale(1)
	end
end



-- Build eventHandlers table, including custom events from scenarios
local eventHandlers = {
	Quickstart_Unchained_bypassChargen = bypassChargen,
	Quickstart_Unchained_startScenario = handleStartScenario,
	Quickstart_Unchained_deleteChargenBoat = deleteChargenBoat,
	Quickstart_Unchained_endGlobalScenario = endGlobalScenarioEvent,
	Quickstart_Unchained_toggleWorldFreeze = toggleWorldFreeze,
}

for scenarioName, scenario in pairs(scenarios) do
	local handlers = scenario.globalScripts and scenario.globalScripts.eventHandlers
	if handlers then
		for eventName, _ in pairs(handlers) do
			if not eventHandlers[eventName] then
				eventHandlers[eventName] = function(data)
					dispatchCustomGlobalEvent(eventName, data)
				end
			end
		end
	end
end

return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onUpdate = onUpdate,
		onObjectActive = onObjectActive,
		--onActorActive = onActorActive,
		--onItemActive = onItemActive,
	},
	eventHandlers = eventHandlers,
}