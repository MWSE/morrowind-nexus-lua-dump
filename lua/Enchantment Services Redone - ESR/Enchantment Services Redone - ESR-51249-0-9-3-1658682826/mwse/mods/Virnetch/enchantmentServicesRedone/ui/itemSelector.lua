
local common = require("Virnetch.enchantmentServicesRedone.common")

local itemSelector = {}

function itemSelector:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- @return {item:tes3item, itemData:tes3itemData, count:number}
function itemSelector:getCurrentSelection()
	local item = self.element:getPropertyObject("vir_esr_item")
	if item and type(item) == "userdata" then
		return {
			item = item,
			itemData = self.element:getPropertyObject("vir_esr_itemData", "tes3itemData"),
			count = self.element:getPropertyInt("vir_esr_itemCount")
		}
	end
end

-- Show a tooltip for the item
function itemSelector:itemSelectTooltip(e)
	local currentSelection = self:getCurrentSelection()
	if currentSelection then
		tes3ui.createTooltipMenu({
			item = currentSelection.item,
			itemData = currentSelection.itemData
		})
	end
end

function itemSelector:removeItem()
	local itemSelect = self.element:findChild(common.GUI_ID.itemSelect_item)

	self.element:setPropertyInt("vir_esr_item", 0)
	self.element:setPropertyInt("vir_esr_itemData", 0)
	self.element:setPropertyInt("vir_esr_itemCount", 0)
	itemSelect:destroyChildren()

	if self.params.insideLabel then
		--- @type tes3uiElement
		local insideLabel = itemSelect:createLabel({ text = self.params.insideLabel })
		insideLabel.wrapText = true
		insideLabel.justifyText = "center"
		insideLabel.absolutePosAlignY = 0.5
	end

	self.element:getTopLevelMenu():updateLayout()
end

-- Set an item to the selector, removing any previous item
function itemSelector:setItem(params)
	params.count = params.count or 1

	self.element:setPropertyObject("vir_esr_item", params.item)
	if params.itemData then
		self.element:setPropertyObject("vir_esr_itemData", params.itemData)
	else
		self.element:setPropertyInt("vir_esr_itemData", 0)
	end
	self.element:setPropertyInt("vir_esr_itemCount", params.count)

	local itemSelect = self.element:findChild(common.GUI_ID.itemSelect_item)
	itemSelect:destroyChildren()

	-- Add another block to get rid of help events entirely when the item is removed
	local itemHolderBlock = itemSelect:createBlock({ id = common.GUI_ID.itemSelect_itemHolder })
	itemHolderBlock.widthProportional = 1.0
	itemHolderBlock.heightProportional = 1.0
	itemHolderBlock.borderAllSides = 8
	itemHolderBlock.childAlignY = 0.5
	itemHolderBlock:register(tes3.uiEvent.help, function(e)
		self:itemSelectTooltip(e)
	end)

	-- Add enchantment icon
	if params.item.enchantment then
		local magicIcon = itemHolderBlock:createImage({ path = "Textures\\menu_icon_magic.tga" })
		magicIcon.widthProportional = 1
		magicIcon.heightProportional = 1
	end

	-- Add shadow icon
	local shadowIcon = itemHolderBlock:createImage({ path = "icons\\" .. params.item.icon })
	shadowIcon.color = {0.0, 0.0, 0.0}
	shadowIcon.absolutePosAlignX = 0.6
	shadowIcon.absolutePosAlignY = 0.55

	-- Add item icon
	local icon = itemHolderBlock:createImage({ path = "icons\\" .. params.item.icon })
	icon.absolutePosAlignX = 0.5
	icon.absolutePosAlignY = 0.5

	-- Add count label
	local countLabel = icon:createLabel({ id = common.GUI_ID.itemSelect_count })
	countLabel.absolutePosAlignX = 1.0
	countLabel.absolutePosAlignY = 1.0
	countLabel.text = params.count
	countLabel.visible = (params.count > 1)

	self.element:getTopLevelMenu():updateLayout()
end


function itemSelector:onMouseClick()
	-- Check if there is already an item selected, and if so, remove it
	-- local item = self.element:getPropertyObject("vir_esr_item")
	-- if item and type(item) == "userdata" then
	local currentSelection = self:getCurrentSelection()
	if currentSelection then
		self:removeItem()
		if self.params.onUpdate then self.params.onUpdate() end

		tes3.playItemPickupSound({ item = currentSelection.item, pickup = false })

		return
	end

	--- @param e uiActivatedEventData
	local function onMenuInventorySelectMenuActivated(e)
		event.unregister(tes3.event.uiActivated, onMenuInventorySelectMenuActivated, { filter = "MenuInventorySelect" })
		if self.params.onMenuInventorySelectMenuActivated then
			self.params.onMenuInventorySelectMenuActivated(e)
		end
	end
	event.register(tes3.event.uiActivated, onMenuInventorySelectMenuActivated, { filter = "MenuInventorySelect" })

	tes3ui.showInventorySelectMenu({
		filter = self.params.inventorySelectParams.filter,
		title = self.params.inventorySelectParams.title,
		noResultsText = self.params.inventorySelectParams.noResultsText,
		noResultsCallback = function()
			event.unregister(tes3.event.uiActivated, onMenuInventorySelectMenuActivated, { filter = "MenuInventorySelect" })
		end,
		callback = function(e)
			--	params["item"]
			--	params["itemData"]
			--	params["count"]
			--	params["inventory"]
			--	params["actor"]
			if e.item then
				self:setItem(e)
				if self.params.onUpdate then self.params.onUpdate() end
			end
		end
	})
end

--- @class esrItemSelectorCreateParams
--- @field parent tes3uiElement
--- @field id number
--- @field label string Optional. Creates a label to the left of the selector.
--- @field insideLabel string Optional. A lable that will be shown in the holder when no item has been selected.
--- @field tooltip string Optional
--- @field inventorySelectParams tes3ui.showInventorySelectMenu.params
--- @field onUpdate function Optional. Called after an item has been set to or removed from the selector.
--- @field onMenuInventorySelectMenuActivated function Optional. Called on the uiActivated event for the InventorySelectMenu

--[[
	Create a UI element for selecting an item
	similar to the ones in the enchanting menu
]]
--- @param params esrItemSelectorCreateParams
function itemSelector.create(params)
	local selector = itemSelector:new()

	local itemBlock = params.parent:createBlock({ id = params.id })
	itemBlock.autoHeight = true
	itemBlock.autoWidth = true
	itemBlock.childAlignX = 0.5
	itemBlock.childAlignY = 0.5

	if params.label then
		local label = itemBlock:createLabel({ id = common.GUI_ID.itemSelect_label, text = params.label })
		label.borderRight = 6
		label.color = common.palette.headerColor
		if params.tooltip then
			label:register(tes3.uiEvent.help, function()
				common.tooltip(params.tooltip, true)
			end)
		end
	end

	local itemSelect = itemBlock:createThinBorder({ id = common.GUI_ID.itemSelect_item })
	itemSelect.width = 60
	itemSelect.height = 60
	itemSelect:register(tes3.uiEvent.mouseClick, function()
		if selector.onMouseClick then
			selector:onMouseClick()
		end
	end)

	if params.insideLabel then
		--- @type tes3uiElement
		local insideLabel = itemSelect:createLabel({ text = params.insideLabel })
		insideLabel.wrapText = true
		insideLabel.justifyText = "center"
		insideLabel.absolutePosAlignY = 0.5
	end

	selector.params = params
	selector.element = itemBlock

	-- Update the count label and remove item if player no longer has it
	itemBlock:getTopLevelMenu():registerAfter(tes3.uiEvent.update, function()
		local currentSelection = selector:getCurrentSelection()
		if currentSelection then
			if not tes3.player.object.inventory:findItemStack(currentSelection.item, currentSelection.itemData) then
				-- Item is not on player, remove from selector
				selector:removeItem()
			elseif not currentSelection.itemData then
				-- For items without itemData, update the count
				local currentCount = tes3.getItemCount({
					reference = tes3.player,
					item = currentSelection.item
				})

				if currentCount > 0 then
					selector.element:setPropertyInt("vir_esr_itemCount", currentCount)
					local countLabel = selector.element:findChild(common.GUI_ID.itemSelect_count)
					if countLabel then
						countLabel.text = currentCount
						countLabel.visible = (currentCount > 1)
					end
				else
					selector:removeItem()
				end
			end
		end
	end)

	return selector
end

return itemSelector