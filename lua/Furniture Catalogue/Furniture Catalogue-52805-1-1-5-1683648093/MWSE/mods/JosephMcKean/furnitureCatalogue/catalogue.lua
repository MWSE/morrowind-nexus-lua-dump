local MerchantManager = require("CraftingFramework").MerchantManager

local common = require("JosephMcKean.furnitureCatalogue.common")
local config = require("JosephMcKean.furnitureCatalogue.config")

local log = common.createLogger("catalogue")

local catalogueI = "jsmk_fc_catalogue_01" -- the id of the Furniture Catalogue
local catalogueType = { [catalogueI] = "catalogueI" }

--- Returns the type of catalogue of the object with the specified id
---@param id string
---@return string?
local function isCatalogue(id)
	return catalogueType[id:lower()]
end

---@class furnitureCatalogue.MenuActivator.RegisteredEvent
---@field item tes3misc? the catalogue item that triggers the menu

---@param e playItemSoundEventData
local function stopItemSounds(e)
	if not isCatalogue(e.item.id) then
		return
	end
	if e.state == 0 then -- item up
		tes3.playSound({ reference = e.reference, sound = "book open" })
	elseif e.state == 1 then -- item down
		tes3.playSound({ reference = e.reference, sound = "book close" })
	end
	return false
end
event.register("playItemSound", stopItemSounds, { priority = 1000 })

---@param catalogue tes3misc
local function triggerMenu(catalogue)
	tes3.playSound({ reference = tes3.player, sound = "scroll" })
	---@type furnitureCatalogue.MenuActivator.RegisteredEvent
	local eventData = { item = catalogue }
	timer.delayOneFrame(function()
		event.trigger("FurnitureCatalogueI", eventData)
	end, timer.real) --- timer type real so CF menu can open in menu mode
end

--- Triggered the MenuActivator FurnitureCatalogueI or FurnitureCatalogueII when activating the book
---@param e activateEventData
local function activateCatalogue(e)
	if e.activator ~= tes3.player then
		return
	end
	if not isCatalogue(e.target.id) then
		return
	end
	--- Allows drag-and-drop method
	if tes3ui.menuMode() then
		return
	end
	local catalogue = e.target.object ---@cast catalogue tes3misc
	triggerMenu(catalogue)
	return false
end
event.register("activate", activateCatalogue, { priority = -10 }) -- low priority to make sure player cannot activate the book while perfect placement-ing

--- Triggered the MenuActivator via equip is bugged
---@param e equipEventData
local function equipCatalogue(e)
	if e.reference ~= tes3.player then
		return
	end
	if not isCatalogue(e.item.id) then
		return
	end
	local catalogue = e.item ---@cast catalogue tes3misc
	triggerMenu(catalogue)
	return false
end
event.register("equip", equipCatalogue, { priority = 581 })

--- This section creates the essential objects so I don't need a plugin file
do
	--- Creating Furniture Catalogue: Standard
	local catalogueIObj = tes3.getObject(catalogueI)
	if not catalogueIObj then
		catalogueIObj = tes3.createObject({
			id = catalogueI,
			objectType = tes3.objectType.miscItem,
			name = "Furniture Catalogue: Standard",
			mesh = "jsmk\\fc\\catalogue_01.nif",
			icon = "jsmk\\fc\\catalogue_01.dds",
			weight = 3,
			value = 500,
		})
	end
end

---@param e cellChangedEventData
local function placeCatalogue(e)
	if e.cell.id == "Vivec, The Abbey of St. Delyn the Wise" and not tes3.player.data.furnitureCatalogue.catalogueIPlaced then
		tes3.player.data.furnitureCatalogue.catalogueIPlaced = true
		tes3.createReference({
			object = catalogueI,
			position = tes3vector3.new(1312.389, 346.616, -373.685),
			orientation = tes3vector3.new(0, 0, 0.67),
			cell = e.cell,
		})
	end
end
event.register("cellChanged", placeCatalogue)

local containers = {}
for merchantId, active in pairs(config.furnitureMerchants) do
	if active then
		table.insert(containers, { merchantId = merchantId, contents = { [catalogueI] = 1 } })
	end
end
local merchantManager = MerchantManager.new({ modName = "Furniture Catalogue", containers = containers })
merchantManager.logger:setLogLevel("INFO")
merchantManager:registerEvents()
