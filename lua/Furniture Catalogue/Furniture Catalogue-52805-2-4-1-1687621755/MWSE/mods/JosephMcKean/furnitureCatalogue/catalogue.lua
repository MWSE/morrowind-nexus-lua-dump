local MerchantManager = require("CraftingFramework").MerchantManager

local config = require("JosephMcKean.furnitureCatalogue.config")

local logging = require("JosephMcKean.furnitureCatalogue.logging")
local log = logging.createLogger("catalogue")

local catalogue = "jsmk_fc_catalogue_01" -- the id of the Furniture Catalogue
local catalogueType = { [catalogue] = "catalogue" }

--- Returns the type of catalogue of the object with the specified id
---@param id string
---@return string?
local function isCatalogue(id) return catalogueType[id:lower()] end

---@class furnitureCatalogue.MenuActivator.RegisteredEvent
---@field item tes3misc? the catalogue item that triggers the menu

---@param e playItemSoundEventData
local function stopItemSounds(e)
	if not isCatalogue(e.item.id) then return end
	if e.state == 0 then -- item up
		tes3.playSound({ reference = e.reference, sound = "book open" })
	elseif e.state == 1 then -- item down
		tes3.playSound({ reference = e.reference, sound = "book close" })
	end
	return false
end
event.register("playItemSound", stopItemSounds, { priority = 1000 })

---@param catalogueObj tes3misc
local function triggerMenu(catalogueObj)
	tes3.playSound({ reference = tes3.player, sound = "scroll" })
	---@type furnitureCatalogue.MenuActivator.RegisteredEvent
	local eventData = { item = catalogueObj }
	timer.delayOneFrame(function() event.trigger("FurnitureCatalogue", eventData) end, timer.real) --- timer type real so CF menu can open in menu mode
end

--- Triggered the MenuActivator FurnitureCatalogue when activating the book
---@param e activateEventData
local function activateCatalogue(e)
	if e.activator ~= tes3.player then return end
	if not isCatalogue(e.target.id) then return end
	--- Allows drag-and-drop method
	if tes3ui.menuMode() then return end
	local catalogueObj = e.target.object ---@cast catalogueObj tes3misc
	triggerMenu(catalogueObj)
	return false
end
event.register("activate", activateCatalogue, { priority = -10 }) -- low priority to make sure player cannot activate the book while perfect placement-ing

--- Triggered the MenuActivator via equip is bugged
---@param e equipEventData
local function equipCatalogue(e)
	if e.reference ~= tes3.player then return end
	if not isCatalogue(e.item.id) then return end
	local catalogueObj = e.item ---@cast catalogueObj tes3misc
	triggerMenu(catalogueObj)
	return false
end
event.register("equip", equipCatalogue, { priority = 581 })

--- This section creates the essential objects so I don't need a plugin file
do
	--- Creating Furniture Catalogue
	local catalogueObj = tes3.getObject(catalogue)
	if not catalogueObj then
		catalogueObj = tes3.createObject({
			id = catalogue,
			objectType = tes3.objectType.miscItem,
			name = "Furniture Catalogue",
			mesh = "jsmk\\fc\\catalogue_01.nif",
			icon = "jsmk\\fc\\catalogue_01.dds",
			weight = 3,
			value = 500,
		})
	end
end

---@param e cellChangedEventData
local function placeCatalogue(e)
	if e.cell.id == "Vivec, The Abbey of St. Delyn the Wise" and not tes3.player.data.furnitureCatalogue.cataloguePlaced then
		tes3.player.data.furnitureCatalogue.cataloguePlaced = true
		tes3.createReference({ object = catalogue, position = tes3vector3.new(1312.389, 346.616, -373.685), orientation = tes3vector3.new(0, 0, 0.67), cell = e.cell })
	end
end
event.register("cellChanged", placeCatalogue)

local containers = {}
for merchantId, active in pairs(config.furnitureMerchants) do if active then table.insert(containers, { merchantId = merchantId, contents = { [catalogue] = 1 } }) end end
local merchantManager = MerchantManager.new({ modName = "Furniture Catalogue", containers = containers })
merchantManager.logger:setLogLevel("DEBUG")
merchantManager:registerEvents()
