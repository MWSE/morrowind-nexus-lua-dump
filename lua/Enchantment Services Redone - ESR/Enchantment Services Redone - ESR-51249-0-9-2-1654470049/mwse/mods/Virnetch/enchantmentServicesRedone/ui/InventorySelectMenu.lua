
local common = require("Virnetch.enchantmentServicesRedone.common")

local InventorySelectMenu = {}

--- Add a label to the bottom of the InventorySelectMenu
--- @param menu tes3uiElement
--- @param id string|number id of the label
--- @return tes3uiElement label
function InventorySelectMenu.addBottomLabel(menu, id)
	local cancelButton = menu:findChild(common.GUI_ID.MenuInventorySelect_button_cancel)
	local label = cancelButton.parent:createLabel({ id = id })
	label.absolutePosAlignX = 0
	label.absolutePosAlignY = 0
	label.borderAllSides = 4

	-- Fix cancel button's position
	cancelButton.absolutePosAlignX = 1

	return label
end

--- Add players current gold amount to the menu
--- @param menu tes3uiElement
function InventorySelectMenu.addPlayerGold(menu)
	local goldLabel = InventorySelectMenu.addBottomLabel(menu, common.GUI_ID.MenuInventorySelect_gold_label)
	goldLabel.text = string.format("%s: %i", tes3.findGMST(tes3.gmst.sGold).value, tes3.getPlayerGold())
end

--- Changes the cancel button's text to be "Done"
--- @param menu tes3uiElement
function InventorySelectMenu.changeCancelToDone(menu)
	local cancelButton = menu:findChild(common.GUI_ID.MenuInventorySelect_button_cancel)
	cancelButton.text = tes3.findGMST(tes3.gmst.sDone).value
end


--- @class esrInventorySelectMenu.addToTilesParams.section
--- @field element tes3uiElement
--- @field item tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon
--- @field itemData tes3itemData

--- @class esrInventorySelectMenu.addToTilesParams
--- @field addBelow fun(section:esrInventorySelectMenu.addToTilesParams.section) Optional. Allows adding elements below itemTiles.
--- @field addRight fun(section:esrInventorySelectMenu.addToTilesParams.section) Optional. Allows adding elements to the right of itemTiles.
--- @field addToIcon fun(section:esrInventorySelectMenu.addToTilesParams.section) Optional. Allows adding elements to the icons of the itemTiles.


--[[
	Allows for quickly adding elements to different sections of item tiles in
	the InventorySelectMenu

	exampleParams = {
		--- @param section esrInventorySelectMenu.addToTilesParams.section
		addBelow = function(section)
			-- Show the item's id below its name
			section.element:createLabel({ text = section.item.id })
		end
	}
]]
--- @param params esrInventorySelectMenu.addToTilesParams
function InventorySelectMenu.addToInventorySelectMenuTiles(params)
	local menu = tes3ui.findMenu(common.GUI_ID.MenuInventorySelect)
	if not menu then return	end

	local pane = menu:findChild(common.GUI_ID.MenuInventorySelect_scrollpane).widget.contentPane
	for _, child in ipairs(pane.children) do
		if not child:findChild(common.GUI_ID.MenuInventorySelect_itemBlock) then

			child.widthProportional = 1.0
			child.borderTop = 2
			child.borderBottom = 2

			local item = child:getPropertyObject("MenuInventorySelect_object")
			local itemData = child:getPropertyObject("MenuInventorySelect_extra", "tes3itemData")

			-- Hide original item name
			local label = child:findChild(common.GUI_ID.MenuInventorySelect_item_brick)
			label.visible = false

			local newBlock = child:createBlock({ id = common.GUI_ID.MenuInventorySelect_itemBlock })
			newBlock.flowDirection = "top_to_bottom"
			newBlock.heightProportional = 1.0
			newBlock.widthProportional = 1.0
			newBlock.childAlignY = 0.5
			newBlock.borderLeft = 2
			newBlock.consumeMouseEvents = false

			local nameLabel = newBlock:createLabel({ id = common.GUI_ID.MenuInventorySelect_nameLabel })
			nameLabel.text = item.name
			nameLabel.consumeMouseEvents = false

			if params.addBelow then
				local belowBlock = newBlock:createBlock({ id = common.GUI_ID.MenuInventorySelect_belowBlock })
				belowBlock.autoWidth = true
				belowBlock.autoHeight = true
				belowBlock.borderLeft = 8
				belowBlock.consumeMouseEvents = false
				params.addBelow({
					element = belowBlock,
					item = item,
					itemData = itemData
				})
			end

			if params.addRight then
				local rightBlock = child:createBlock({ id = common.GUI_ID.MenuInventorySelect_rightBlock })
				rightBlock.autoWidth = true
				rightBlock.autoHeight = true
				rightBlock.absolutePosAlignX = 1.0
				rightBlock.absolutePosAlignY = 0.5
				rightBlock.borderAllSides = 8
				rightBlock.consumeMouseEvents = false
				params.addRight({
					element = rightBlock,
					item = item,
					itemData = itemData
				})
			end

			if params.addToIcon then
				local icon = child:findChild(common.GUI_ID.MenuInventorySelect_icon_brick)
				params.addToIcon({
					element = icon,
					item = item,
					itemData = itemData
				})
			end

			child:updateLayout()
		end
	end
end

return InventorySelectMenu