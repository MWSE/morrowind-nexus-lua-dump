self = require('openmw.self')
local iUI = require('openmw.interfaces').UI
local ui = require('openmw.ui')
local core = require('openmw.core')
local input = require('openmw.input')
local async = require('openmw.async')
local types = require('openmw.types')

local restStart = core.getGameTime()
local L = core.l10n('WakeUp')
local dynamicHealth = types.Player.stats.dynamic.health(self)
local cannotRestGMST = 'sRestMenu4'

local newGame = false
local inBed = false
local pendingMenuOpen = false
local pendingMenuClose = false
local charGenFinished = false
local hasSavedInBed = false

local function UiModeChanged(data)
	if data.newMode == 'MainMenu' then
		if not pendingMenuOpen and types.Player.isCharGenFinished(self) then
			pendingMenuOpen = true
			core.sendGlobalEvent('wu_setCharGen', { value = -2 })
		elseif pendingMenuOpen then
			pendingMenuOpen = false
			pendingMenuClose = true
		end

	elseif data.oldMode == 'MainMenu' and pendingMenuClose then
		pendingMenuClose = false
		core.sendGlobalEvent('wu_setCharGen', { value = -1 })
		types.Player.sendMenuEvent(self, 'wu_cleanSaves')

	elseif data.newMode == 'Rest' and not data.oldMode then
		if data.arg then
			inBed = true
			restStart = core.getGameTime()
		else
			ui.showMessage(core.getGMST(cannotRestGMST), { showInDialogue = false} )
		end

	elseif inBed and not data.newMode and data.oldMode == 'Rest' then
		local newHealth = dynamicHealth.current
		local newHealthMax = dynamicHealth.base + dynamicHealth.modifier

		if charGenFinished and (restStart < core.getGameTime()) then
			if (newHealth == newHealthMax or newHealth >= startHealthCurrent) then
				if not hasSavedInBed then
					hasSavedInBed = true
				end

				types.Player.sendMenuEvent(self, 'wu_doSave')
			else
				ui.showMessage(L('save_failed'), { showInDialogue = false} )
			end
		end

		inBed = false
	end
end

local function wu_showMessage(message)
	ui.showMessage(message, { showInDialogue = false })
end

local function quickSaveHandler()
	if not pendingMenuOpen and charGenFinished then
		pendingMenuOpen = true
		core.sendGlobalEvent('wu_setCharGen', { value = -2 })
	end
end

local function onFrame()
	if not inBed then
		iUI.removeMode('Rest')
	end

	if types.Player.isCharGenFinished(self) then
		iUI.removeMode('MainMenu')
	elseif pendingMenuOpen then
		iUI.addMode('MainMenu')
	end
end

input.registerTriggerHandler('QuickSave', async:callback(quickSaveHandler))

local function charGenCheck()
	charGenFinished = types.Player.isCharGenFinished(self)

	if not charGenFinished then
		async:newUnsavableSimulationTimer(1, charGenCheck)
	elseif newGame then
		newGame = false
		hasSavedInBed = true
		types.Player.sendMenuEvent(self, 'wu_doSave')
	end
end

local function onSave()
	return {
		charGenFinished = charGenFinished,
		hasSavedInBed = hasSavedInBed
	}
end

local function onLoad(data)
	if not data then
		charGenCheck()
		return
	end

	charGenFinished = data.charGenFinished
	hasSavedInBed = data.hasSavedInBed

	if not charGenFinished then
		charGenCheck()
	else
		core.sendGlobalEvent('wu_setCharGen', { value = -1 })
	end

	if hasSavedInBed then
		types.Player.sendMenuEvent(self, 'wu_cleanSaves')
	else
		iUI.showInteractiveMessage(L('startup_message'))
	end
end

return {
	engineHandlers = {
		onFrame = onFrame,
		onSave = onSave,
		onLoad = onLoad
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		wu_showMessage = wu_showMessage,
		wu_initCharGenCheck = charGenCheck,
		wu_newGame = function()
			newGame = true
		end,
		Died = function()
			iUI.showInteractiveMessage(L('wake_up'))
		end
	}
}
