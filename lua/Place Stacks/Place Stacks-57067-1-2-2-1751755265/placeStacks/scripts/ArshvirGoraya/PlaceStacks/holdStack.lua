local input = require("openmw.input")
local self = require("openmw.self")
local core = require("openmw.core")
local storage = require("openmw.storage")
local settingsHold = storage.playerSection("settingsPlaceStacksModHold")
local settingsNotify = storage.playerSection("settingsPlaceStacksModNotification")
local settingsBehaviour = storage.playerSection("settingsPlaceStacksModBehaviour")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local types = require("openmw.types")

local DB = require("scripts.ArshvirGoraya.PlaceStacks.dbug")

local focusedContainer = nil
local heldWhenOpening = false
local targetTime = 0
local notificationString = ""

return {
	eventHandlers = {
		UiModeChanged = function(data)
			heldWhenOpening = false
			-- DB.log("UiModeChanged from", data.oldMode, "to", data.newMode, "(" .. tostring(data.arg) .. ")")
			if data.newMode ~= "Container" then
				return
			end
			if data.oldMode == "Container" then
				return
			end
			if not settingsHold:get("PlaceStacksHold") then
				return
			end
			if types.Actor.objectIsInstance(data.arg) then
				-- disable stacking on alive NPCs
				if not types.Actor.isDead(data.arg) then
					DB.log("NPC is alive... no stacking.")
					return
				end
			end
			DB.log("focused container: ", data.arg)
			focusedContainer = data.arg

			if input.isActionPressed(input.ACTION.Activate) then -- depracted. says to use getBooleanActionValue instead, but there doesn't seem to be a registered action for Activate in input.actions yet... so can't?
				heldWhenOpening = true
				targetTime = core.getRealTime() + settingsHold:get("PlaceStacksHoldMS") / 1000 -- convert ms to seconds
			end
		end,

		PlaceStacksComplete = function(args)
			DB.log("any: ", settingsNotify:get("PlaceStacksNotify"))
			DB.log("place stacks: ", settingsNotify:get("PlaceStacksNotifyPlaceStacks"))
			DB.log("not all: ", settingsNotify:get("PlaceStacksNotifyNotAllItems"))
			DB.log("not all types: ", settingsNotify:get("PlaceStacksNotifyNotAllItemsTypes"))

			if settingsNotify:get("PlaceStacksNotify") then
				notificationString = ""
				if settingsNotify:get("PlaceStacksNotifyPlaceStacks") then
					notificationString = notificationString .. "Placed Stacks: " .. tostring(args.movedItemsCount)
					DB.log("notificationString: ", notificationString)
				end
				if not args.allItemsFit then
					if settingsNotify:get("PlaceStacksNotifyPlaceStacks") then
						notificationString = notificationString .. "\n"
					end
					if
						settingsNotify:get("PlaceStacksNotifyNotAllItems")
						or settingsNotify:get("PlaceStacksNotifyNotAllItemsTypes")
					then
						notificationString = notificationString .. "Did not fit:"
					end
					if settingsNotify:get("PlaceStacksNotifyNotAllItems") then
						notificationString = notificationString .. " " .. tostring(args.unfittableItemsCount)
						DB.log("notificationString: ", notificationString)
					end
					if settingsNotify:get("PlaceStacksNotifyNotAllItemsTypes") then
						notificationString = notificationString .. " [" .. args.nonFittingItemTypesListString .. "]"
						DB.log("notificationString: ", notificationString)
					end
				end
				DB.log("notificationString: ", notificationString)
				if notificationString ~= "" then
					DB.log("show message: ", notificationString)
					-- ui.showMessage(
					-- 	notificationString .. "TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST"
					-- )
					ui.showMessage(notificationString)
				end
			end

			-- UI Behaviour
			if settingsHold:get("PlaceStacksHoldAutoClose") then
				I.UI.setMode()
			else
				I.UI.setMode("Container", { target = focusedContainer }) -- will call uiModeChanged!
			end
		end,
	},

	engineHandlers = {
		onFrame = function(dt)
			-- if input.isKeyPressed(input.KEY.G) then
			-- 	DB.log(
			-- 		"npc remaining space: ",
			-- 		types.Actor.getCapacity(focusedContainer) - types.Actor.getEncumbrance(focusedContainer)
			-- 	) -- may be actor or container so dont use type.Container
			-- end
			-- Hold Activate when in container:
			if heldWhenOpening then
				if not input.isActionPressed(input.ACTION.Activate) then
					heldWhenOpening = false
					return
				end
				-- DB.log("time remaining: ", targetTime - core.getRealTime())
				if core.getRealTime() >= targetTime then
					heldWhenOpening = false
					core.sendGlobalEvent("PlaceStacks", {
						sourceContainer = self,
						targetContainer = focusedContainer,
						depositEquipped = settingsBehaviour:get("PlaceStacksDepositEquipped"),
						PlaceStacksNotifyNotAllItemsTypes = settingsNotify:get("PlaceStacksNotifyNotAllItemsTypes"),
					})
				end
			end
		end,
	},
}
