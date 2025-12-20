ui = require('openmw.ui')
--util = require('openmw.util')
core = require('openmw.core')
--calendar = require('openmw_aux.calendar')
--time = require('openmw_aux.time')
--async = require('openmw.async')
--v2 = util.vector2
--v3 = util.vector3
I = require('openmw.interfaces')
--storage = require('openmw.storage')
--input = require('openmw.input')
self = require('openmw.self')
types = require('openmw.types')
--vfs = require('openmw.vfs')
--camera = require('openmw.camera')
--nearby = require('openmw.nearby')
--ambient = require('openmw.ambient')
--auxUi = require('openmw_aux.ui')
--debug = require('openmw.debug')
--animation = require('openmw.animation')
local plusRunning = false



local function onConsoleCommand(command, str)
    -- Handle "lua unchained" 
    if str:match("^lua unchained") then
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
		
		local plus = str:match("^lua unchained!")
		if types.Player.getBirthSign(self) == "" then
			plus = true
		end
        core.sendGlobalEvent("Quickstart_Unchained", {self, plus})
		ui.printToConsole("You break your chains and are free!", ui.CONSOLE_COLOR.Success)
        return true
    end
end

function onLoad()
	if not types.Player.isCharGenFinished(self) then
		ui.printToConsole("Type 'lua unchained' to break your chains (skip intro)", ui.CONSOLE_COLOR.Success)
	end
	--
	--local lastCell
	--time.runRepeatedly(function()
	--	
	--end, 1 * time.second)
end

local function UiModeChanged(data)
	if not plusRunning then return end
	if data.oldMode == "ChargenName" then
		I.UI.setMode("ChargenRace")
	end
	if data.oldMode == "ChargenRace" then
		I.UI.setMode("ChargenClass")
	end
	if data.oldMode == "ChargenClassCreate" or data.oldMode == "ChargenClassPick" or data.oldMode == "ChargenClassGenerate" then
		I.UI.setMode("ChargenBirth")
	end
	if data.oldMode == "ChargenBirth" then
		I.UI.setMode("ChargenClassReview")
		plusRunning = false
	end
	print(data.oldMode, data.newMode)
end

local function showRaceMenu()
	--I.UI.setMode("ChargenClassReview")
	I.UI.setMode("ChargenName")
	plusRunning = true
end

return {
	engineHandlers = {
		onConsoleCommand = onConsoleCommand,
		onLoad = onLoad,
		onInit = onLoad,
	},
	eventHandlers = {
		UiModeChanged=UiModeChanged,
		Quickstart_Unchained_showRaceMenu = showRaceMenu,
	}
}