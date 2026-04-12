-- GLOBAL SCRIPT
--
-- API Globals
Types = require("openmw.types")
Core = require("openmw.core")
-- I = require("openmw.interfaces") -- I.UI is onlyt accessed through player script. must send it
-- Input = require("openmw.input") -- cant use input in global script must send from player script.
Storage = require("openmw.storage")
-- Custom Globals
DB = require("scripts.ArshvirGoraya.PlaceStacks.dbug")
Keys = require("scripts.ArshvirGoraya.PlaceStacks.keys")
Helpers = require("scripts.ArshvirGoraya.PlaceStacks.helpers")
PerformerHelpers = require("scripts.ArshvirGoraya.PlaceStacks.actionPerformer.performerHelpers")
-- Locals
local stackActionPerformer = require("scripts.ArshvirGoraya.PlaceStacks.actionPerformer.stackActionPerformer")
-- Global Variables (read-only in local scripts)

PlaceStacksGlobals = Storage.globalSection("PlaceStacksGlobals")
PlaceStacksGlobals:set("CurrentStackType", Keys.CONSTANT_KEYS.Options.StackType.None)
PlaceStacksGlobals:setLifeTime(Storage.LIFE_TIME.Temporary) -- removed on exit / on load

NotificationStruct = PerformerHelpers.getCleanNotificationStruct(nil)

local M = {
	eventHandlers = {
		performPlaceStacks = stackActionPerformer.performPlaceStacks,
		performTakeStacks = stackActionPerformer.performTakeStacks,
	},
}

return M
