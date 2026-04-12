-- PLAYER SCRIPT
--
-- API Globals
Types = require("openmw.types")
Core = require("openmw.core")
I = require("openmw.interfaces")
Input = require("openmw.input")
Storage = require("openmw.storage")
local player = require("openmw.self")
local async = require("openmw.async")
local ui = require("openmw.ui")
--
PlaceStacksGlobals = Storage.globalSection("PlaceStacksGlobals")
-- Custom API Globals
DB = require("scripts.ArshvirGoraya.PlaceStacks.dbug")
Keys = require("scripts.ArshvirGoraya.PlaceStacks.keys")
Helpers = require("scripts.ArshvirGoraya.PlaceStacks.helpers")
DetectorHelpers = require("scripts.ArshvirGoraya.PlaceStacks.actionDetector.detectorHelpers")
--- Settings stuff
local settings = require("scripts.ArshvirGoraya.PlaceStacks.settings")
local tableSettings = settings.subscribeAndBuildTableSettings(async)
---@type SettingsCommonBehavior
local settingsTableCommonBehavior = tableSettings[Keys.CONSTANT_KEYS.Sections.CommonBehavior]
---@type SettingsTakeStacks
local settingsTableTakeStacks = tableSettings[Keys.CONSTANT_KEYS.Sections.TakeStacks]
---@type SettingsPlaceStacks
local settingsTablePlaceStacks = tableSettings[Keys.CONSTANT_KEYS.Sections.PlaceStacks]
settings.validateAllSelectSettings(ui)

-- Custom Var Globals
FocusedContainer = nil
-- Locals
local psd = require("scripts.ArshvirGoraya.PlaceStacks.actionDetector.placeStacksDetector")
local tsd = require("scripts.ArshvirGoraya.PlaceStacks.actionDetector.takeStacksDetector")

-- debug
local detectDebugAction = function(key)
	if not DB.logging then
		return false
	end
	if key.symbol == "\\" then
		return true
	end
end

local performDebugAction = function()
	--ui.showMessage()
	DB.log("placeStacks debug action")
	--DB.uilog("debug action")
end

-- ENTRY
local onKeyPress = function(key)
	if detectDebugAction(key) then
		performDebugAction()
	end
end

local onFrame = function(_) --@ ENTRY
	if
		DetectorHelpers.cancelDetectionThisFrame(
			FocusedContainer,
			Types,
			I.UI.getMode(),
			PlaceStacksGlobals:get("CurrentStackType"),
			psd
		)
	then
		return
	end
	--
	if psd.detectPlaceStacksHold() or psd.detectPlaceStacksPress() then
		Core.sendGlobalEvent("performPlaceStacks", {
			FocusedContainer,
			player,
			I.UI.getMode(),
			DetectorHelpers.detectPerformOnAllItems(
				Input,
				settingsTableCommonBehavior.Modifier,
				settingsTablePlaceStacks.ModifierSetting
			),
			settingsTablePlaceStacks,
		})
	end
	if tsd.detectTakeStacksPress(psd) then
		Core.sendGlobalEvent("performTakeStacks", {
			FocusedContainer,
			player,
			I.UI.getMode(),
			DetectorHelpers.detectPerformOnAllItems(
				Input,
				settingsTableCommonBehavior.Modifier,
				settingsTableTakeStacks.ModifierSetting
			),
			settingsTableTakeStacks,
		})
	end
end

local UIModeChanged = function(data) --@ ENTRY
	if DetectorHelpers.detectContainerOpened(data) then
		DB.log("container opened")
		FocusedContainer = data.arg
		psd.startDetectingPlaceStacksHoldIfEnabled(settingsTablePlaceStacks.HoldMS)
	end
end

local function notify(stackActionSettings, notificationStruct, stackType)
	local notificationString =
		DetectorHelpers.buildNotificationString(stackActionSettings, notificationStruct, stackType)
	if notificationString == "" then
		return
	end
	ui.showMessage(notificationString)
end

local function closeContainer()
	I.UI.setMode() -- set all ui to nothing
end

local function refreshContainer()
	I.UI.setMode("Container", { target = FocusedContainer }) -- will call uiModeChanged!
end

---@param notificationStruct NotificationStruct
local function autoClose(commonSettings, notificationStruct)
	if commonSettings.AutoClose == Keys.LOCALIZED_KEYS.Options.AutoClose.Never then
		refreshContainer()
	elseif commonSettings.AutoClose == Keys.LOCALIZED_KEYS.Options.AutoClose.Always then
		closeContainer()
	elseif commonSettings.AutoClose == Keys.LOCALIZED_KEYS.Options.AutoClose.Fit then
		local allTransferred = notificationStruct.totalTransferred.count == notificationStruct.totalConsidered.count
		if allTransferred then
			closeContainer()
		else
			refreshContainer()
		end
	end
end

local function notifyAndAutoClose(args)
	local notificationStruct, stackType = table.unpack(args)

	---@type SettingsStackAction
	local stackActionSettings
	stackActionSettings = settingsTableTakeStacks

	if stackType == Keys.CONSTANT_KEYS.Options.StackType.Place then
		stackActionSettings = settingsTablePlaceStacks
	end
	notify(stackActionSettings, notificationStruct, stackType)
	autoClose(settingsTableCommonBehavior, notificationStruct)
end

--
local M = {
	eventHandlers = { UiModeChanged = UIModeChanged, NotifyAndAutoClose = notifyAndAutoClose },
	engineHandlers = { onFrame = onFrame, onKeyPress = onKeyPress },
}
return M
