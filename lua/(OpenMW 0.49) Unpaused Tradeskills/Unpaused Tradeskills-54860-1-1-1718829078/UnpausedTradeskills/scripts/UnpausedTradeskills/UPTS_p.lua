local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local core = require("openmw.core")
local types = require('openmw.types')
local self = require('openmw.self')
local ambient = require('openmw.ambient')
local resources = types.Actor.stats.dynamic
local MODE = I.UI.MODE
local windows = require('scripts.uimodes.windows')
local MOD_NAME = "UnpausedTradeskills"

local dialogModes = {
    Barter = true,
    Companion = true,
    Dialogue = true,
    Enchanting = true,
    MerchantRepair = true,
    SpellBuying = true,
    SpellCreation = true,
    Training = true,
    Travel = true,
}



function uiModeChanged(m)
	core.sendGlobalEvent("UnpausedTradeskills_playerChangesMode",{player = self, mode = m.newMode})
	
    if m.newMode == nil then
        windows.mode = nil
        if currentDialogTarget then
            currentDialogTarget:sendEvent('UnpausedTradeskills_StopDialog')
            currentDialogTarget = nil
        end
    end
    if m.newMode ~= MODE.Interface then windows.closeModeMenu() end
    if dialogModes[m.newMode] and m.arg and m.arg ~= currentDialogTarget then --and settings.dialogsDontPause()
        if currentDialogTarget then
            currentDialogTarget:sendEvent('UnpausedTradeskills_StopDialog')
        end
        m.arg:sendEvent('UnpausedTradeskills_StartDialog', self)
        currentDialogTarget = m.arg
    end
	
end


I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = "Unpaused Tradeskills",
	description = ""
}

return {
	eventHandlers = {
		UiModeChanged	= uiModeChanged,
	}
}