local types = require("openmw.types")
local auxUtils = require("openmw_aux.util")
local DB = require("scripts.ArshvirGoraya.PlaceStacks.dbug")
local sourceInventory = nil
local targetInventory = nil
local targetItemList = nil
local movedItemsCount = 0
local stackWeight = 0
local remainingCapacity = 0
local itemWeight = 0
local moveableItemCount = 0
local allItemsFit = true
-- local trackedEncumbrance = 0
local nonFittingItemTypesSet = {}
local nonFittingItemTypesListString = ""
local unfittableItemsCount = 0

return {
	eventHandlers = {
		PlaceStacks = function(args)
			sourceInventory = types.Container.inventory(args.sourceContainer)
			targetInventory = types.Container.inventory(args.targetContainer)
			-- DB.log("sourceInventory: ", auxUtils.deepToString(sourceInventory))
			-- DB.log("targetInventory: ", auxUtils.deepToString(targetInventory))
			-- DB.log("targetContainer: ", auxUtils.deepToString(args.targetContainer))

			-- loop through all items of source container and make a list.
			targetItemList = targetInventory:getAll() -- iterateable list of GameObjects
			if #targetItemList == 0 then -- container is empty
				return
			end

			nonFittingItemTypesSet = {}
			movedItemsCount = 0
			allItemsFit = true
			unfittableItemsCount = 0
			-- trackedEncumbrance = types.Container.getEncumbrance(args.targetContainer)

			-- getCapacity and getEncumbrance have to go through types.Actor and types.Container for some reason... cant just call it on args.targetContainer
			if types.Actor.objectIsInstance(args.targetContainer) then
				remainingCapacity = types.Actor.getCapacity(args.targetContainer)
					- types.Actor.getEncumbrance(args.targetContainer)
			else
				remainingCapacity = types.Container.getCapacity(args.targetContainer)
					- types.Container.getEncumbrance(args.targetContainer)
			end

			for _, item in pairs(targetItemList) do -- pairs instead of ipairs = no need for it to be ordered
				for _, sItem in pairs(sourceInventory:findAll(item.recordId)) do
					DB.log("deposit equipped setting: ", args.depositEquipped)
					if not args.depositEquipped then
						DB.log("item equpped: ", types.Actor.hasEquipped(args.sourceContainer, sItem)) -- assumes sourceContaienr is player actor
						if types.Actor.hasEquipped(args.sourceContainer, sItem) then
							DB.log("player has item equipped: ", sItem)
							goto continue
						end
					end

					-- Ensure to only place the amount of items that container can carry!
					itemWeight = sItem.type.record(sItem).weight
					stackWeight = sItem.count * itemWeight
					moveableItemCount = math.floor(remainingCapacity / itemWeight) -- how many items of this weight can fit into this container?
					moveableItemCount = math.max(moveableItemCount, 0)
					DB.log("moveable Item Count: ", moveableItemCount, " = ", remainingCapacity, "/", itemWeight)

					if moveableItemCount >= sItem.count then -- all items in item stack can fit
						moveableItemCount = sItem.count
					else
						DB.log("unfittable item type: ", sItem.type)
						nonFittingItemTypesSet[sItem.type] = true
						DB.log("unfittable count: ", sItem.count - moveableItemCount)
						unfittableItemsCount = unfittableItemsCount + (sItem.count - moveableItemCount)
						allItemsFit = false
					end
					-- trackedEncumbrance = trackedEncumbrance + moveableItemCount * itemWeight -- have to track encumbrance changes. cant use getEncumbrance because it doesn't actually change in value for some reason?
					remainingCapacity = remainingCapacity - moveableItemCount * itemWeight

					-- DB.log(
					-- 	"Container: ",
					-- 	types.Container.getEncumbrance(args.targetContainer),
					-- 	"/",
					-- 	types.Container.getCapacity(args.targetContainer),
					-- )
					-- DB.log("Encumbrance = ", trackedEncumbrance)
					DB.log("Remaining = ", remainingCapacity)
					DB.log("stackWeight: ", stackWeight)
					DB.log("can fit", moveableItemCount, "of: ", sItem.count, "(", sItem.recordId, ")")
					-- if moveableItemCount >= 0 then
					if moveableItemCount ~= 0 then
						sItem:split(moveableItemCount):moveInto(targetInventory)
						movedItemsCount = movedItemsCount + moveableItemCount

						-- local testItems = sItem:split(moveableItemCount)
						-- DB.log("moving Items: ", testItems.count)
						-- testItems:moveInto(targetInventory)
						-- movedItemsCount = movedItemsCount + moveableItemCount
					end
					DB.log("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
					::continue::
				end
			end
			nonFittingItemTypesListString = ""
			if args.PlaceStacksNotifyNotAllItemsTypes then
				DB.log("doing type loop")
				for key in pairs(nonFittingItemTypesSet) do
					nonFittingItemTypesListString = nonFittingItemTypesListString .. tostring(key) .. ", "
				end
				nonFittingItemTypesListString = string.sub(nonFittingItemTypesListString, 1, -3)
			end

			args.sourceContainer:sendEvent("PlaceStacksComplete", {
				movedItemsCount = movedItemsCount,
				allItemsFit = allItemsFit,
				unfittableItemsCount = unfittableItemsCount,
				-- nonFittingItemTypesSet = nonFittingItemTypesSet,
				nonFittingItemTypesListString = nonFittingItemTypesListString,
			}) -- send event to player
		end,
	},
}
