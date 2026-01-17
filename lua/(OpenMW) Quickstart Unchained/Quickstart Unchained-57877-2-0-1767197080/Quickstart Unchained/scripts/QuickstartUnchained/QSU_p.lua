ui = require('openmw.ui')
util = require('openmw.util')
core = require('openmw.core')
calendar = require('openmw_aux.calendar')
time = require('openmw_aux.time')
async = require('openmw.async')
v2 = util.vector2
v3 = util.vector3
I = require('openmw.interfaces')
storage = require('openmw.storage')
input = require('openmw.input')
types = require('openmw.types')
self = require("openmw.self")
ambient = require("openmw.ambient")
vfs = require('openmw.vfs')
camera = require('openmw.camera')
debug = require('openmw.debug')
nearby = require('openmw.nearby')
animation = require('openmw.animation')

local chargenStage = 5

-- Scenario choice window
require("scripts.QuickstartUnchained.QSU_parseScenarios")
require("scripts.QuickstartUnchained.QSU_helpers")

local scenarioChoice = require("scripts.QuickstartUnchained.QSU_scenarioChoice")

--[[ chargen sequence:
1. Player: showScenarioChoiceWindow() -- scenario selection 
2. Global: handleStartScenario{player, scenarioId} -- teleports the player, triggers scenario events
3. Player: bypassChargen() -- adds journal entries, changes control switches, etc
4. Player: showRaceMenu() -- triggers the sequence for showing the chargen dialogues
--- when chargen is finished (for compatibility with gentler race menu) --- :
5. Global: bypassChargen() -- adds the caius package, sets the global variable and does the chargen door trick.

This ensures that the player is teleported before activating the chargen door.
]]

local function bypassChargen()
	--Report to Caius Cosades
	for _, topicRecord in pairs(core.dialogue.topic.records) do
		local infos = topicRecord.infos[1]
		local filterActorId = infos and infos.filterActorId
		if filterActorId == "chargen captain" then
			if types.Player.addTopic then
				types.Player.addTopic(self, topicRecord.id)
			end
		end
	end
	
	types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, true)
	types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
	types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Jumping	, true)
	types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Looking	, true)
	types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic 	, true)
	types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.ViewMode, true)
	
	-- if you dont have a birthsign or enter it with an exclamation mark you get bonus stuff
	showRaceMenu()
	
end


local function showScenarioChoiceWindow()
	I.UI.setMode("Jail")
	scenarioChoice.show(function(scenarioId, scenario)
		if scenarioId == -1 then
			--pressed x button
		end
		I.UI.setMode()
		if scenario then
			core.sendGlobalEvent("Quickstart_Unchained_startScenario", {self, scenarioId})
		end
	end)
end


local function onConsoleCommand(command, str)
	-- Handle "lua quickstart" 
	if str:match("^lua quickstart") then
		showScenarioChoiceWindow()
		ui.printToConsole("You break your chains and are free!", ui.CONSOLE_COLOR.Success)
		return true
	end
end

-- Dispatch an event to all active scenarios' playerScripts
local function dispatchPlayerEvent(handlerName, ...)
	if not saveData.activeScenarios then return end
	for scenarioName, _ in pairs(saveData.activeScenarios) do
		local scenario = scenarios[scenarioName]
		if scenario and scenario.playerScripts and scenario.playerScripts[handlerName] then
			scenario.playerScripts[handlerName](...)
		end
	end
end

function showRaceMenu()
	chargenStage = 0
	I.UI.setMode("ChargenName")
end

local function UiModeChanged(data)
	-- Dispatch to active scenarios
	dispatchPlayerEvent("onUiModeChanged", data)
	
	if chargenStage >= 6 then return end
	
	if data.newMode == "ChargenName" then
		chargenStage = math.max(1, chargenStage)
	end
	if data.newMode == "ChargenRace" then
		chargenStage = math.max(2, chargenStage)
	end
	if (data.newMode == "ChargenClass" or data.newMode == "ChargenClassCreate" or data.newMode == "ChargenClassPick" or data.newMode == "ChargenClassGenerate") then
		chargenStage = math.max(3, chargenStage)
	end
	if data.newMode == "ChargenBirth" then
		chargenStage = math.max(4, chargenStage)
	end
	if data.newMode == "ChargenClassReview" then
		chargenStage = 5
	end
	
	if data.oldMode == "ChargenName" and chargenStage < 2 then
		async:newUnsavableSimulationTimer(0.01, async:callback(function()
			if not I.UI.getMode() and chargenStage < 2 then
				I.UI.setMode("ChargenRace")
			end
		end))
	end
	if data.oldMode == "ChargenRace" and chargenStage < 3 then
		async:newUnsavableSimulationTimer(0.01, async:callback(function()
			if not I.UI.getMode() and chargenStage < 3 then
				I.UI.setMode("ChargenClass")
			end
		end))
	end
	if (data.oldMode == "ChargenClassCreate" or data.oldMode == "ChargenClassPick" or data.oldMode == "ChargenClassGenerate") and chargenStage < 4 then
		async:newUnsavableSimulationTimer(0.01, async:callback(function()
			if not I.UI.getMode() and chargenStage < 4 then
				I.UI.setMode("ChargenBirth")
			end
		end))
	end
	if data.oldMode == "ChargenBirth" and chargenStage < 5 then
		async:newUnsavableSimulationTimer(0.01, async:callback(function()
			if not I.UI.getMode() and chargenStage < 5 then
				I.UI.setMode("ChargenClassReview")
			end
		end))
	end
	if data.oldMode == "ChargenClassReview" and chargenStage < 6 then
		async:newUnsavableSimulationTimer(0.01, async:callback(function()
			if not I.UI.getMode() and chargenStage < 6 then
				chargenStage = 6
				core.sendGlobalEvent("Quickstart_Unchained_bypassChargen", {self, true})
				scenarioOnSelected()
			end
		end))
	end
end

local function equipItems(itemTable)
	types.Actor.setEquipment(self, itemTable)
end

function endScenario(scenarioName)
	if saveData.activeScenarios and saveData.activeScenarios[scenarioName] then
		local scenario = scenarios[scenarioName]
		if scenario and scenario.playerScripts and scenario.playerScripts.onEnd then
			scenario.playerScripts.onEnd()
		end
		saveData.activeScenarios[scenarioName] = nil
		if not next(saveData.activeScenarios) then saveData.activeScenarios = nil end
		core.sendGlobalEvent("Quickstart_Unchained_endGlobalScenario", scenarioName)
	end
end

-- Event handler version that doesn't notify global (to avoid loop)
local function endPlayerScenarioEvent(scenarioName)
	if saveData.activeScenarios and saveData.activeScenarios[scenarioName] then
		local scenario = scenarios[scenarioName]
		if scenario and scenario.playerScripts and scenario.playerScripts.onEnd then
			scenario.playerScripts.onEnd()
		end
		saveData.activeScenarios[scenarioName] = nil
		if not next(saveData.activeScenarios) then saveData.activeScenarios = nil end
	end
end

function scenarioOnSelected(scenarioName)
	dispatchPlayerEvent("onSelected", dt)
end

local function activateScenario(scenarioName)
	if not saveData.activeScenarios then saveData.activeScenarios = {} end
	saveData.activeScenarios[scenarioName] = {}
end

local function onFrame(dt)
	-- Run active scenario scripts
	dispatchPlayerEvent("onFrame", dt)

	---- printing current position (debug)
	--if math.random() < 0.999 then return end
	--local pos = self.position
	--local yaw = self.rotation:getYaw()
	--print(self.cell.id, string.format(
	--	"\n\t\tposition = util.vector3(%.1f, %.1f, %.1f),\n\t\trotation = util.transform.rotateZ(math.rad(%.1f)),",
	--	pos.x, pos.y, pos.z,
	--	(math.deg(yaw)*10+0.5)/10
	--))
end

local function onKeyPress(key)
	dispatchPlayerEvent("onKeyPress", key)
end

local function onQuestUpdate(questId, stage)
	dispatchPlayerEvent("onQuestUpdate", questId, stage)
end

local function onConsume(item)
	dispatchPlayerEvent("onConsume", item)
end

local function onMouseWheel(item)
	dispatchPlayerEvent("onMouseWheel", item)
end

local function onTeleported()
	dispatchPlayerEvent("onTeleported")
end

local function onLoad(data)
	if not data then
		I.UI.setMode("Jail")
		scenarioChoice.show(function(scenarioId, scenario)
			if scenarioId == -1 then
				--pressed x button
			end
			I.UI.setMode()
			if scenario then
				core.sendGlobalEvent("Quickstart_Unchained_startScenario", {self, scenarioId})
			end
		end)
	end

	saveData = data or {}
	
	-- Call onLoad for each active scenario
	if saveData.activeScenarios then
		for scenarioName, _ in pairs(saveData.activeScenarios) do
			local scenario = scenarios[scenarioName]
			if scenario and scenario.playerScripts and scenario.playerScripts.onLoad then
				scenario.playerScripts.onLoad()
			end
		end
	end
	
	if not types.Player.isCharGenFinished(self) then
		ui.printToConsole("Type 'lua quickstart' to break your chains (skip intro)", ui.CONSOLE_COLOR.Success)
	end
end

local function onSave()
	return saveData
end

-- Dispatch custom events to active scenarios
local function dispatchCustomPlayerEvent(eventName, data)
	if not saveData.activeScenarios then return end
	for scenarioName, _ in pairs(saveData.activeScenarios) do
		local scenario = scenarios[scenarioName]
		local handlers = scenario and scenario.playerScripts and scenario.playerScripts.eventHandlers
		if handlers and handlers[eventName] then
			handlers[eventName](data)
		end
	end
end

-- Build eventHandlers table, including custom events from scenarios
local eventHandlers = {
	UiModeChanged = UiModeChanged,
	Quickstart_Unchained_showRaceMenu = showRaceMenu,
	Quickstart_Unchained_equipItems = equipItems,
	Quickstart_Unchained_activateScenario = activateScenario,
	Quickstart_Unchained_scenarioOnSelected = scenarioOnSelected, -- called after chargen locally
	Quickstart_Unchained_endPlayerScenario = endPlayerScenarioEvent,
	Quickstart_Unchained_bypassChargen = bypassChargen,
}

for scenarioName, scenario in pairs(scenarios) do
	local handlers = scenario.playerScripts and scenario.playerScripts.eventHandlers
	if handlers then
		for eventName, _ in pairs(handlers) do
			if not eventHandlers[eventName] then
				eventHandlers[eventName] = function(data)
					dispatchCustomPlayerEvent(eventName, data)
				end
			end
		end
	end
end

return {
	engineHandlers = {
		onConsoleCommand = onConsoleCommand,
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
		onFrame = onFrame,
		onKeyPress = onKeyPress,
		onQuestUpdate = onQuestUpdate,
		onConsume = onConsume,
		onTeleported = onTeleported,
		onMouseWheel = onMouseWheel,
	},
	eventHandlers = eventHandlers,
}