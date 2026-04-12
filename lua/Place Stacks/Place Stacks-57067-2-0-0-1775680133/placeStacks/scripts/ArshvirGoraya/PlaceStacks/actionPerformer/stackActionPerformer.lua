local M = {}

---@class StackActionArgs
---@field sourceContainer userdata
---@field targetContainer userdata
---@field player userdata
---@field performOnAllItems boolean
---@field transferOrder string
---@field startingTargetCapacity number
---@field notifyCountTransferred boolean
---@field notifyValueTransferred boolean
---@field notifyWeightTransferred boolean
---@field notifyTypesNotAllTransferred boolean
---@field items userdata[]

---@class TakeStacksArgs: StackActionArgs
---@field allowOverEncumbrance boolean

---@class PlaceStacksArgs: StackActionArgs
---@field depositMoney boolean
---@field depositEquipped boolean

local stackActionArgs = {}
---@ cast stackActionArgs PlaceStacksArgs | TakeStacksArgs

---@param stackActionSettings SettingsPlaceStacks | SettingsTakeStacks
local function preparePlaceStacksArgs(focusedContainer, player, performOnAllItems, stackActionSettings, stackType)
	if stackType == Keys.CONSTANT_KEYS.Options.StackType.Place then
		---@cast stackActionArgs PlaceStacksArgs
		---@cast stackActionSettings SettingsPlaceStacks
		stackActionArgs.depositMoney = stackActionSettings.DepositMoney
		stackActionArgs.depositEquipped = stackActionSettings.DepositEquipped
		--
		stackActionArgs.sourceContainer = player
		stackActionArgs.targetContainer = focusedContainer
	else
		---@cast stackActionArgs TakeStacksArgs
		---@cast stackActionSettings SettingsTakeStacks
		stackActionArgs.allowOverEncumbrance = stackActionSettings.AllowOverEncumbrance
		--
		stackActionArgs.sourceContainer = focusedContainer
		stackActionArgs.targetContainer = player
	end

	stackActionArgs.player = player
	stackActionArgs.performOnAllItems = performOnAllItems
	stackActionArgs.transferOrder = stackActionSettings.TransferOrder
	stackActionArgs.startingTargetCapacity =
		PerformerHelpers.getStartingContainerCapacity(stackActionArgs.targetContainer, Types)
	stackActionArgs.notifyCountTransferred = stackActionSettings.NotifyCountTransferred
	stackActionArgs.notifyValueTransferred = stackActionSettings.NotifyValueTransferred
	stackActionArgs.notifyWeightTransferred = stackActionSettings.NotifyWeightTransferred
	stackActionArgs.notifyTypesNotAllTransferred = stackActionSettings.NotifyTypesNotAllTransferred

	-- set items last.
	stackActionArgs.items = PerformerHelpers.filterItemsIntoTable(stackActionArgs, NotificationStruct, stackType, Types)
end

local function stackAction(stackType)
	DB.log("=== performing action: ", stackType)
	---@diagnostic disable-next-line: undefined-field
	local targetInventory = stackActionArgs.targetContainer.type.inventory(stackActionArgs.targetContainer)
	if
		PerformerHelpers.canTreatTargetContainerAsInfinite(stackActionArgs, stackType, Types)
		or PerformerHelpers.allItemsFitIntoContainer(
			stackActionArgs.startingTargetCapacity,
			NotificationStruct.totalConsidered.weight
		)
	then
		DB.log("all items can tranfer (no need to sort): ", #stackActionArgs.items)
		-- transfer all items
		for _, item in pairs(stackActionArgs.items) do
			DB.log("transfering item: ", PerformerHelpers.getItemName(item))
			item:moveInto(targetInventory) ---@diagnostic disable-line: undefined-field
		end
		NotificationStruct.totalTransferred.count = NotificationStruct.totalConsidered.count
		NotificationStruct.totalTransferred.value = NotificationStruct.totalConsidered.value
		NotificationStruct.totalTransferred.weight = NotificationStruct.totalConsidered.weight
		NotificationStruct.tableOfNotAllTransferredTypes = {}
		return
	end
	-- Transfer items until weight is reached
	DB.log("all items cant transfer (must sort)")
	stackActionArgs.items =
		PerformerHelpers.sortItemsIntoTransferOrder(stackActionArgs.items, stackActionArgs.transferOrder)
	local workingCapacity = stackActionArgs.startingTargetCapacity

	for _, item in ipairs(stackActionArgs.items) do
		local moveableItemCount = PerformerHelpers.getMoveableItemCountFromStack(workingCapacity, item)
		if moveableItemCount > 0 then
			item:split(moveableItemCount):moveInto(targetInventory) ---@diagnostic disable-line: undefined-field
			PerformerHelpers.updateNotificationStructTransferred(
				NotificationStruct,
				item,
				stackActionArgs,
				moveableItemCount
			)
		end
		workingCapacity = workingCapacity - PerformerHelpers.getItemWeight(item) * moveableItemCount
	end
end

local function performStackAction(args, stackType)
	local focusedContainer, player, uiMode, performOnAllItems, stackActionSettings = table.unpack(args)
	if
		not Helpers.canPerformStackAction(focusedContainer, Types, uiMode, PlaceStacksGlobals:get("CurrentStackType"))
	then
		return
	end
	PlaceStacksGlobals:set("CurrentStackType", stackType)
	NotificationStruct = PerformerHelpers.getCleanNotificationStruct()
	DB.log("matching only: ", not performOnAllItems)
	preparePlaceStacksArgs(focusedContainer, player, performOnAllItems, stackActionSettings, stackType)
	--
	stackAction(stackType)
	-- performPlaceStacksNotification()
	-- PerformerHelpers.performAutoClose()
	player:sendEvent("NotifyAndAutoClose", {
		NotificationStruct,
		stackType,
	})
	PlaceStacksGlobals:set("CurrentStackType", Keys.CONSTANT_KEYS.Options.StackType.None)
end

M.performPlaceStacks = function(args)
	performStackAction(args, Keys.CONSTANT_KEYS.Options.StackType.Place)
end

M.performTakeStacks = function(args)
	performStackAction(args, Keys.CONSTANT_KEYS.Options.StackType.Take)
end

return M
