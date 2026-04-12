local core = require("openmw.core")
--
local l10n = "placeStacks"

local localized = core.l10n(l10n, "en") -- English is the fallback language

-- local vfs = require("openmw.vfs")
-- local localizedPath = "l10n\\placeStacks"

local M = {}

M.CONSTANT_KEYS = {
	SettingsPageName = "PlaceStacksPage",
	L10n = l10n,
	Sections = {
		CommonBehavior = "settingsCommonBehavior",
		TakeStacks = "settingsTakeStacks",
		PlaceStacks = "settingsPlaceStacks",
	},
	CommonBehavior = {
		AutoCloseKey = "AutoClose",
		ModifierKey = "Modifier",
	},
	CommonSettings = {
		TransferOrder = "TransferOrder",
		ModifierSetting = "ModifierSetting",
		NotifyCountTransferred = "NotifyCountTransferred",
		NotifyValueTransferred = "NotifyValueTransferred",
		NotifyWeightTransferred = "NotifyWeightTransferred",
		NotifyTypesNotAllTransferred = "NotifyTypesNotAllTransferred",
	},
	TakeStacks = {
		KeyBind = "KeyBind",
		AllowOverEncumbrance = "AllowOverEncumbrance",
	},
	PlaceStacks = {
		KeyBind = "KeyBind",
		HoldMS = "HoldMS",
		DepositEquipped = "DepositEquipped",
		DepositMoney = "DepositMoney",
	},
	CustomInputs = {
		TakeStacks = "TakeStacksKeyBind",
		PlaceStacks = "PlaceStacksKeyBind",
	},
	Options = {
		StackType = { None = "None", Place = "Place", Take = "Take" },
		Notification = {
			Count = "Count",
			Value = "Value",
			Weight = "Weight",
			NotAllTransferred = "NotAllTransferred",
		},
	},
	-- misc:
	RecordIDs = {
		gold = "gold_001",
	},
	Notifications = {
		-- MAX_NOTIFICATION_STRING_SIZE = 40, -- can do 46 but adding 6 space for character width differences for different languages maybe
		MAX_NOTIFICATION_STRING_SIZE = 46,
	},
	-- Should be used when comparing the size of a single item with the container (not stacks)
	ContainerSizeEpsilon = 0.001, -- https://gitlab.com/OpenMW/openmw/-/merge_requests/4776
}
M.LOCALIZED_KEYS = {
	ModName = localized("ModName"),
	ModDescription = localized("ModDescription"),
	Sections = {
		CommonBehavior = {
			Name = localized("SectionName_CommonBehavior"),
			Description = localized("SectionDescription_CommonBehavior"),
		},
		TakeStacks = {
			Name = localized("SectionName_TakeStacks"),
			Description = localized("SectionDescription_TakeStacks"),
		},
		PlaceStacks = {
			Name = localized("SectionName_PlaceStacks"),
			Description = localized("SectionDescription_PlaceStacks"),
		},
	},
	Settings = {
		AutoClose = {
			Name = localized("SettingsNames_AutoClose"),
			Description = localized("SettingsDescription_AutoClose"),
			List = {
				localized("AutoClose_Never"),
				localized("AutoClose_Always"),
				localized("AutoClose_Fit"),
			},
		},
		Modifier = {
			Name = localized("SettingsNames_Modifier"),
			Description = localized("SettingsDescription_Modifier"),
			List = {
				localized("Modifier_Shift"),
				localized("Modifier_Ctrl"),
				localized("Modifier_Alt"),
				localized("Modifier_Super"),
			},
		},
		TakeStacksKeyBind = {
			Name = localized("SettingsNames_TakeStacksKeyBind"),
			Description = localized("SettingsDescription_TakeStacksKeyBind"),
			KeyDescription = localized("KeyDescription_TakeStacksKeyBind"),
		},
		PlaceStacksKeyBind = {
			Name = localized("SettingsNames_PlaceStacksKeyBind"),
			Description = localized("SettingsDescription_PlaceStacksKeyBind"),
			KeyDescription = localized("KeyDescription_PlaceStacksKeyBind"),
		},
		AllowOverEncumber = {
			Name = localized("SettingsNames_AllowOverEncumber"),
			Description = localized("SettingsDescription_AllowOverEncumber"),
		},
		HoldMS = {
			Name = localized("SettingsNames_HoldMS"),
			Description = localized("SettingsDescription_HoldMS"),
		},
		DepositEquipped = {
			Name = localized("SettingsNames_DepositEquipped"),
			Description = localized("SettingsDescription_DepositEquipped"),
		},
		DepositMoney = {
			Name = localized("SettingsNames_DepositMoney"),
			Description = localized("SettingsDescription_DepositMoney"),
		},
		ModifierSetting = {
			Name = localized("SettingsNames_ModifierSetting"),
			Description = localized("SettingsDescription_ModifierSetting"),
			List = {
				localized("ModifierSetting_Default"),
				localized("ModifierSetting_Invert"),
				localized("ModifierSetting_Disable"),
			},
		},
		TransferOrder = {
			Take = {
				Name = localized("SettingsNames_TransferOrder_Take"),
				Description = localized("SettingsDescription_TransferOrder_Take"),
			},
			Place = {
				Name = localized("SettingsNames_TransferOrder_Place"),
				Description = localized("SettingsDescription_TransferOrder_Place"),
			},
			List = {
				localized("TransferOrder_Any"),
				localized("TransferOrder_Valuable"),
				localized("TransferOrder_ValuableByWeight"),
				localized("TransferOrder_Lightest"),
				localized("TransferOrder_Cheapest"),
				localized("TransferOrder_Heaviest"),
			},
		},
		NotifyCountTransferred = {
			Take = {
				Name = localized("SettingsNames_NotifyCountTransferred_Take"),
				Description = localized("SettingsDescription_NotifyCountTransferred_Take"),
			},
			Place = {
				Name = localized("SettingsNames_NotifyCountTransferred_Place"),
				Description = localized("SettingsDescription_NotifyCountTransferred_Place"),
			},
		},
		NotifyValueTransferred = {
			Take = {
				Name = localized("SettingsNames_NotifyValueTransferred_Take"),
				Description = localized("SettingsDescription_NotifyValueTransferred_Take"),
			},
			Place = {
				Name = localized("SettingsNames_NotifyValueTransferred_Place"),
				Description = localized("SettingsDescription_NotifyValueTransferred_Place"),
			},
		},
		NotifyWeightTransferred = {
			Take = {
				Name = localized("SettingsNames_NotifyWeightTransferred_Take"),
				Description = localized("SettingsDescription_NotifyWeightTransferred_Take"),
			},
			Place = {
				Name = localized("SettingsNames_NotifyWeightTransferred_Place"),
				Description = localized("SettingsDescription_NotifyWeightTransferred_Place"),
			},
		},
		NotifyTypesNotAllTransferred = {
			Take = {
				Name = localized("SettingsNames_NotifyTypesNotAllTransferred_Take"),
				Description = localized("SettingsDescription_NotifyTypesNotAllTransferred_Take"),
			},
			Place = {
				Name = localized("SettingsNames_NotifyTypesNotAllTransferred_Place"),
				Description = localized("SettingsDescription_NotifyTypesNotAllTransferred_Place"),
			},
		},
	},
	Options = {
		---@class TransferOrder
		TransferOrder = {
			Any = localized("TransferOrder_Any"),
			Valuable = localized("TransferOrder_Valuable"),
			ValuableByWeight = localized("TransferOrder_ValuableByWeight"),
			Lightest = localized("TransferOrder_Lightest"),
			Cheapest = localized("TransferOrder_Cheapest"),
			Heaviest = localized("TransferOrder_Heaviest"),
		},
		---@class AutoClose
		AutoClose = {
			Never = localized("AutoClose_Never"),
			Always = localized("AutoClose_Always"),
			Fit = localized("AutoClose_Fit"),
		},
		---@class ModifierSetting
		ModifierSetting = {
			Default = localized("ModifierSetting_Default"),
			Invert = localized("ModifierSetting_Invert"),
			Disable = localized("ModifierSetting_Disable"),
		},
		---@class Modifier
		Modifier = {
			Shift = localized("Modifier_Shift"),
			Ctrl = localized("Modifier_Ctrl"),
			Alt = localized("Modifier_Alt"),
			Super = localized("Modifier_Super"),
		},
	},
}

---@param notificationStruct NotificationStruct
function M.getLocalizedNotification(notificationType, notificationStruct, stackType, allTransferred, prependTitle)
	local notifString = nil
	local prependTitleString = ""
	if prependTitle then
		if stackType == M.CONSTANT_KEYS.Options.StackType.Place then
			prependTitleString = localized("Notification_Title_Place")
		else
			prependTitleString = localized("Notification_Title_Take")
		end
	end

	if notificationType == M.CONSTANT_KEYS.Options.Notification.Count then
		if stackType == M.CONSTANT_KEYS.Options.StackType.Place then
			if allTransferred then
				notifString = localized(
					"Notification_Count_Place_All",
					{ transferred = notificationStruct.totalTransferred.count }
				)
			else
				notifString = localized("Notification_Count_Place", {
					transferred = notificationStruct.totalTransferred.count,
					considered = notificationStruct.totalConsidered.count,
				})
			end
			return prependTitleString .. notifString
		else
			if allTransferred then
				notifString = localized(
					"Notification_Count_Take_All",
					{ transferred = notificationStruct.totalTransferred.count }
				)
			else
				notifString = localized("Notification_Count_Take", {
					transferred = notificationStruct.totalTransferred.count,
					considered = notificationStruct.totalConsidered.count,
				})
			end
			return prependTitleString .. notifString
		end
	elseif notificationType == M.CONSTANT_KEYS.Options.Notification.Value then
		if allTransferred then
			notifString =
				localized("Notification_Value_All", { transferred = notificationStruct.totalTransferred.value })
		else
			notifString = localized("Notification_Value", {
				transferred = notificationStruct.totalTransferred.value,
				considered = notificationStruct.totalConsidered.value,
			})
		end
		return prependTitleString .. notifString
	elseif notificationType == M.CONSTANT_KEYS.Options.Notification.Weight then
		if allTransferred then
			notifString =
				localized("Notification_Weight_All", { transferred = notificationStruct.totalTransferred.weight })
		else
			notifString = localized("Notification_Weight", {
				transferred = notificationStruct.totalTransferred.weight,
				considered = notificationStruct.totalConsidered.weight,
			})
		end
		return prependTitleString .. notifString
	elseif notificationType == M.CONSTANT_KEYS.Options.Notification.NotAllTransferred then
		local maxListStringsize = M.CONSTANT_KEYS.Notifications.MAX_NOTIFICATION_STRING_SIZE
		local typesList = Helpers.tableKeysToList(notificationStruct.tableOfNotAllTransferredTypes)

		local typesString = table.concat(typesList, ", ")

		local prependString = nil
		if stackType == M.CONSTANT_KEYS.Options.StackType.Place then
			prependString = localized("Notification_NotAllTransferredPrepend_Place")
		else
			prependString = localized("Notification_NotAllTransferredPrepend_Take")
		end

		local listString = ""
		if #typesList == 1 then
			maxListStringsize = maxListStringsize - (#prependString + 1) -- 1 = space
			listString = prependString .. " " .. Helpers.elipseListString(typesString, maxListStringsize)
		else
			maxListStringsize = maxListStringsize - (#prependString + 3) -- 3 = space and surrounding [ ]
			listString = prependString .. " [" .. Helpers.elipseListString(typesString, maxListStringsize) .. "]"
		end
		DB.log("listString Size: ", #listString)
		if prependTitle then
			return prependTitleString .. "\n" .. listString
		else
			return listString
		end
	end
end

return M
