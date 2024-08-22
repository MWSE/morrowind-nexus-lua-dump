-- This will disable pause mode for using interfaces
local I = require('openmw.interfaces')
local self = require('openmw.self')
local ui = require('openmw.ui')

local storage = require('openmw.storage')
local MOD_NAME = "comprehensive_rebalance"
local playerSettings = storage.globalSection("SettingsGlobal" .. MOD_NAME .. "menus")

local currentTarget = nil

local function SetRealtimeMenus()

	I.UI.setPauseOnMode('Interface', playerSettings:get("realtimeInterface") == false)
	I.UI.setPauseOnMode('Dialogue', playerSettings:get("realtimeDialogue") == false)
	I.UI.setPauseOnMode('Container', playerSettings:get("realtimeContainer") == false)
	I.UI.setPauseOnMode('Scroll', playerSettings:get("realtimeReading") == false)
	I.UI.setPauseOnMode('Book', playerSettings:get("realtimeReading") == false)
	I.UI.setPauseOnMode('Journal', playerSettings:get("realtimeJournal") == false)
	I.UI.setPauseOnMode('QuickKeysMenu', playerSettings:get("realtimeQuickKeysMenu") == false)
	I.UI.setPauseOnMode('Travel', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('Alchemy', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('Companion', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('Barter', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('SpellBuying', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('MerchantRepair', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('Repair', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('Recharge', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('Training', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('Enchanting', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('SpellCreating', playerSettings:get("realtimeInteractions") == false)
	I.UI.setPauseOnMode('Rest', playerSettings:get("realtimeMisc") == false)
	I.UI.setPauseOnMode('Jail', playerSettings:get("realtimeMisc") == false)
	I.UI.setPauseOnMode('LevelUp', playerSettings:get("realtimeMisc") == false)
end

--if we have realtime dialogue menu, we need to send an event to our target to make them stop
local function HandleDialogueNPC(data)
	if playerSettings:get("realtimeDialogue") and data.newMode == "Dialogue" and data.arg ~= nil then
		data.arg:sendEvent('DialogueStarted', self)
		currentTarget = data.arg
		--print("opened dialog")
	elseif currentTarget and data.newMode == nil then
		currentTarget:sendEvent('DialogueStopped', self)
		currentTarget = nil
		--print("stopped dialog")
	end
end

local function OnGUI(data)

	SetRealtimeMenus()
	HandleDialogueNPC(data)

end

SetRealtimeMenus()
return {
    eventHandlers = {
		UiModeChanged = OnGUI
	}
}
