local lastMouseX
local lastMouseY
local width
local height
local current_map
local main_map_menu
local map_table = {}

-- MAP SELECTED EVENTS
-- /////////////////////////////////////////////////////////////////

--- @param name string
--- @return string
local function GetMapFromId(name)
	return map_table[name]
end

--- @param e equipEventData
local function equipCallback(e)
	if (e.item.objectType ~= tes3.objectType.book) then
		return
	end

	-- display new map
	if main_map_menu == nil then
		return
	end

	-- switch on book name
	local map_or_nil = GetMapFromId(e.item.id)
	if map_or_nil == nil then
		return
	end

	current_map = map_or_nil

	local mapPane = main_map_menu:findChild("PartDragMenu_main")
	mapPane:findChild("MenuMap_world").visible = false
	mapPane:findChild("MenuMap_local").visible = false
	mapPane:findChild("MenuMap_switch").visible = false

	-- destroy old map
	local existing_map = mapPane:findChild("rf_map_image")
	if existing_map ~= nil then
		existing_map:destroy()
	end

	-- create new map
	local map = main_map_menu:createImage{ id = "rf_map_image", path = current_map }
	map.imageScaleX = 1
	map.imageScaleY = 1
	width = map.width
	height = map.height
	lastMouseX = 0
	lastMouseY = 0
	mapPane.childOffsetX = 0
	mapPane.childOffsetY = 0

	main_map_menu:updateLayout()
	if string.find(e.item.id, "bk_rf") then
		e.block = true
	end

end
event.register(tes3.event.equip, equipCallback)

-- ZOOM AND DRAG LOGIC
-- taken and adapted from https://www.nexusmods.com/morrowind/mods/48455
-- /////////////////////////////////////////////////////////////////

local function zoomIn(e)

	if current_map == nil then
		return
	end

	local map_menu = e.source
	local map_image = map_menu:findChild("rf_map_image")

	local unscaledWidth = map_image.width / map_image.imageScaleX
	local unscaledHeight = map_image.height / map_image.imageScaleY
	local unscaledOffsetX = (map_image.parent.childOffsetX - 0.5 * map_image.parent.width) / map_image.imageScaleX
	local unscaledOffsetY = (map_image.parent.childOffsetY + 0.5 * map_image.parent.height) / map_image.imageScaleY

	map_image.imageScaleX = math.min(map_image.imageScaleX + 0.1, 3)
	map_image.imageScaleY = math.min(map_image.imageScaleY + 0.1, 3)
	map_image.width = unscaledWidth * map_image.imageScaleX
	map_image.height = unscaledHeight * map_image.imageScaleY

	width = map_image.width
	height = map_image.height

	map_image.parent.childOffsetX = math.min((unscaledOffsetX * map_image.imageScaleX) + 0.5 * map_image.parent.width, 0)
	map_image.parent.childOffsetY = math.max((unscaledOffsetY * map_image.imageScaleY) - 0.5 * map_image.parent.height, 0)

	map_menu:updateLayout()
end

local function zoomOut(e)

	if current_map == nil then
		return
	end

	local map_menu = e.source
	local map_image = map_menu:findChild("rf_map_image")

	local unscaledWidth = map_image.width / map_image.imageScaleX
	local unscaledHeight = map_image.height / map_image.imageScaleY
	if (unscaledWidth * (map_image.imageScaleX - 0.1) < map_menu.width) then
		return
	elseif (unscaledHeight * (map_image.imageScaleY - 0.1) < map_menu.height) then
		return
	end
	local unscaledOffsetX = (map_image.parent.childOffsetX - 0.5 * map_image.parent.width) / map_image.imageScaleX
	local unscaledOffsetY = (map_image.parent.childOffsetY + 0.5 * map_image.parent.height) / map_image.imageScaleY

	map_image.imageScaleX = math.max(0.1, map_image.imageScaleX - 0.1)
	map_image.imageScaleY = math.max(0.1, map_image.imageScaleY - 0.1)
	map_image.width = unscaledWidth * map_image.imageScaleX
	map_image.height = unscaledHeight * map_image.imageScaleY

	width = map_image.width
	height = map_image.height

	map_image.parent.childOffsetX = math.min((unscaledOffsetX * map_image.imageScaleX) + 0.5 * map_image.parent.width, 0)
	map_image.parent.childOffsetY = math.max((unscaledOffsetY * map_image.imageScaleY) - 0.5 * map_image.parent.height, 0)

	if (map_image.parent.childOffsetX < -1 * (map_image.width - map_image.parent.width)) then
		map_image.parent.childOffsetX = -1 * (map_image.width - map_image.parent.width)
	end
	if (map_image.parent.childOffsetY > map_image.height - map_image.parent.height) then
		map_image.parent.childOffsetY = map_image.height - map_image.parent.height
	end

	map_menu:updateLayout()
end

local function startDrag(e)

	if current_map == nil then
		return
	end

	tes3ui.captureMouseDrag(true)
	lastMouseX = e.data0
	lastMouseY = e.data1
end

local function releaseDrag()

	if current_map == nil then
		return
	end

	tes3ui.captureMouseDrag(false)
end

local function dragController(e)

	if current_map == nil then
		return
	end

	local changeX = lastMouseX - e.data0
	local changeY = lastMouseY - e.data1

	local main_map_menu = tes3ui.findMenu("MenuMap") -- name = "PartDragMenu_main"
	if main_map_menu == nil then
		return
	end
	local mapPane = main_map_menu:findChild("PartDragMenu_main")

	mapPane.childOffsetX = math.min(0, mapPane.childOffsetX - changeX)
	mapPane.childOffsetY = math.max(0, mapPane.childOffsetY - changeY)

	if (mapPane.childOffsetX < -1 * (width - mapPane.width)) then
		mapPane.childOffsetX = -1 * (width - mapPane.width)
	end
	if (mapPane.childOffsetY > height - mapPane.height) then
		mapPane.childOffsetY = height - mapPane.height
	end

	lastMouseX = e.data0
	lastMouseY = e.data1

	main_map_menu:updateLayout()
end

-- MAP MENU CREATE EVENTS
-- /////////////////////////////////////////////////////////////////

--- register zoom events etc
--- @param e uiActivatedEventData
local function onMenuMapActivated(e)
	local mapmenu = e.element
	mapmenu:register("mouseScrollUp", zoomIn)
	mapmenu:register("mouseScrollDown", zoomOut)
	mapmenu:register("mouseDown", startDrag)
	mapmenu:register("mouseRelease", releaseDrag)
	mapmenu:register("mouseStillPressed", dragController)

	local mapPane = mapmenu:findChild("PartDragMenu_main")
	mapPane.childOffsetX = 0
	mapPane.childOffsetY = 0

	main_map_menu = mapmenu

	mapmenu:updateLayout()
end
event.register(tes3.event.uiActivated, onMenuMapActivated, { filter = "MenuMap" })

--- disable vanilla map
--- @param e menuEnterEventData
local function menuEnterCallback(e)
	if main_map_menu ~= nil then
		local mapPane = main_map_menu:findChild("PartDragMenu_main")
		mapPane:findChild("MenuMap_world").visible = false
		mapPane:findChild("MenuMap_local").visible = false
		mapPane:findChild("MenuMap_switch").visible = false
	end

end
event.register(tes3.event.menuEnter, menuEnterCallback)

-- INIT MOD
-- /////////////////////////////////////////////////////////////////

-- MERCHANT MANAGER
local all_items = {
	-- in bigger cities (AR, BM, EH, SM, VV), libraries
	bk_rf_wagner_vvardenfell = -1, -- 
	bk_rf_gridmap_v = -1, -- -
	bk_rf_gridmap_vm = -1, -- -

	-- only in bookshops
	bk_rf_gridmap_morrowind = -1, -- -
	bk_rf_gridmap_morrowind_ne = -1, -- Sadrith Mora, TR
	bk_rf_gridmap_morrowind_nw = -1, -- Gnisis, TR
	bk_rf_gridmap_morrowind_se = -1, -- TR
	bk_rf_gridmap_morrowind_sw = -1, -- Seyda Neen, TR, Ebonheart

	-- regional maps
	bk_rf_mel_ac = -1, -- Ebonheart, Tel Branora, Suran, Pelagiad, Molag mar
	bk_rf_mel_bc = -1, -- Caldera, Ald'ruhn, Ghostgate, Balmora, Gnaar Mok
	bk_rf_mel_rm = -1, -- Ald'ruhn, Ghostgate, Tel Vos, Vos
	bk_rf_mel_s = -1, -- Dagon Fel, Khuul, 
	bk_rf_mel_is = -1, -- Seyda Neen, Vicec, Suran, Hla Oad, Ebonheart, Pelagiad
	k_rf_mel_zb = -1, -- Ghostgate, Sadrith Mora, Ald'ruhn

	bk_rf_wagner_solstheim = -1, -- Solstheim, Dagon fel
	bk_rf_wagner_mournhold = -1, -- Mournhold
}
local items_middle = { bk_rf_mel_bc = -1, bk_rf_mel_rm = -1, k_rf_mel_zb = -1 }
local items_southwest = { bk_rf_mel_bc = -1, bk_rf_mel_is = -1 }
local items_north = { bk_rf_mel_s = -1, bk_rf_wagner_solstheim = -1 }
local items_south = { bk_rf_mel_ac = -1, bk_rf_mel_is = -1 }
local items_vivec = {
	bk_rf_mel_ac = -1,
	bk_rf_mel_is = -1,
	bk_rf_wagner_vvardenfell = -1,
	bk_rf_gridmap_v = -1,
	bk_rf_gridmap_vm = -1,
	bk_rf_gridmap_morrowind_sw = -1,
}
local items_aldruhn = {
	bk_rf_mel_bc = -1,
	bk_rf_mel_rm = -1,
	k_rf_mel_zb = -1,
	bk_rf_wagner_vvardenfell = -1,
	bk_rf_gridmap_v = -1,
	bk_rf_gridmap_vm = -1,
}
local items_balmora = {
	bk_rf_mel_bc = -1,
	bk_rf_mel_is = -1,
	bk_rf_wagner_vvardenfell = -1,
	bk_rf_gridmap_v = -1,
	bk_rf_gridmap_vm = -1,
}
local items_ebonheart = {
	bk_rf_mel_ac = -1,
	bk_rf_mel_is = -1,
	bk_rf_wagner_vvardenfell = -1,
	bk_rf_gridmap_v = -1,
	bk_rf_gridmap_vm = -1,
	bk_rf_gridmap_morrowind_sw = -1,
}
local items_sadrithmora = {
	k_rf_mel_zb = -1,
	bk_rf_gridmap_morrowind_ne = -1,
	bk_rf_wagner_vvardenfell = -1,
	bk_rf_gridmap_v = -1,
	bk_rf_gridmap_vm = -1,
}

local MerchantManager = require("CraftingFramework").MerchantManager
local containers = {
	-- book sellers
	{ merchantId = "codus callonus", contents = all_items },
	{ merchantId = "dorisa darvel", contents = all_items },
	{ merchantId = "jobasha", contents = all_items },
	{ merchantId = "simine fralinie", contents = all_items },

	-- Ald'Ruhn
	{ merchantId = "malpenix blonia", contents = items_aldruhn },
	{ merchantId = "tiras sadus", contents = items_aldruhn },
	-- ghostgate
	{ merchantId = "fonas retheran", contents = items_middle },
	-- buckmoth
	{ merchantId = "syloria siruliulus", contents = items_middle },

	-- Balmora
	{ merchantId = "clagius clanler", contents = items_balmora },
	{ merchantId = "dralasa nithryon", contents = items_balmora },
	{ merchantId = "ra'virr", contents = items_balmora },
	-- moonmoth
	{ merchantId = "urfing", contents = items_middle },
	{ merchantId = "naspis apinia", contents = items_middle },
	-- hla oad
	{ merchantId = "perien aurelie", contents = items_southwest },
	{ merchantId = "trasteve", contents = items_southwest },
	-- Caldera
	{ merchantId = "verick gemain", contents = { bk_rf_mel_bc = -1 } },
	-- Seyda Neen
	{ merchantId = "arrille", contents = { bk_rf_mel_bc = -1, bk_rf_mel_is = -1, bk_rf_gridmap_morrowind_sw = -1 } },

	-- Dagon fel
	{ merchantId = "fryfnhild", contents = items_north },
	{ merchantId = "heifnir", contents = items_north },
	-- tel Mora
	-- TODO has no regional map of North east
	{ merchantId = "berwen", contents = { bk_rf_mel_s = -1, bk_rf_wagner_vvardenfell = -1 } },
	-- Sadrith Mora
	{ merchantId = "ancola", contents = items_sadrithmora },
	{ merchantId = "elegal", contents = items_sadrithmora },
	{ merchantId = "llevas fels", contents = items_sadrithmora },
	-- tel Aruhn
	{ merchantId = "ferele athram", contents = { k_rf_mel_zb = -1 } },

	-- Ebonheart
	{ merchantId = "kaye", contents = items_ebonheart },
	{ merchantId = "landorume", contents = items_ebonheart },
	-- pelagiad
	{ merchantId = "mebestian ence", contents = items_south },
	-- Suran
	{ merchantId = "ralds oril", contents = items_south },
	-- Vivec
	{ merchantId = "baissa", contents = items_vivec },
	{ merchantId = "balen andrano", contents = items_vivec },
	{ merchantId = "bervyn lleryn", contents = items_vivec },
	{ merchantId = "gadayn andarys", contents = items_vivec },
	{ merchantId = "jeanne", contents = items_vivec },
	{ merchantId = "lucretinaus olcinius", contents = items_vivec },
	{ merchantId = "mevel fererus", contents = items_vivec },
	{ merchantId = "nalis gals", contents = items_vivec },
	{ merchantId = "tarvyn faren", contents = items_vivec },
	{ merchantId = "tervur braven", contents = items_vivec },

	-- gnisis
	-- TODO has no regional map of west gash
	{ merchantId = "hetman abelmawia", contents = { bk_rf_gridmap_morrowind_nw = -1, bk_rf_wagner_vvardenfell = -1 } },
	{ merchantId = "shulki ashunbabi", contents = { bk_rf_gridmap_morrowind_nw = -1, bk_rf_wagner_vvardenfell = -1 } },
	-- ald velothi
	{
		merchantId = "sedam omalen",
		contents = { bk_rf_mel_s = -1, bk_rf_gridmap_morrowind_nw = -1, bk_rf_wagner_vvardenfell = -1 },
	},
	-- khuul
	{ merchantId = "thongar", contents = { bk_rf_mel_s = -1, bk_rf_gridmap_morrowind_nw = -1 } },

	-- Molag mar
	{ merchantId = "mandur omalen", contents = { bk_rf_mel_ac = -1 } },
	{ merchantId = "vasesius viciulus", contents = { bk_rf_mel_ac = -1 } },
	-- tel branora
	{ merchantId = "fadase selvayn", contents = { bk_rf_mel_ac = -1, bk_rf_gridmap_morrowind_ne = -1 } },

	-- ashlanders
	{ merchantId = "lanabi", contents = { bk_rf_mel_s = -1, bk_rf_mel_rm = -1 } }, -- ahemusa
	{ merchantId = "kurapli", contents = { bk_rf_mel_s = -1, bk_rf_mel_rm = -1 } }, -- urshilaku camp
	{ merchantId = "massarapal", contents = { k_rf_mel_zb = -1, bk_rf_mel_rm = -1 } }, -- erabinimsun
	{ merchantId = "ashur-dan", contents = { k_rf_mel_zb = -1, bk_rf_mel_rm = -1 } }, -- Zainab Camp 
	{ merchantId = "areas", contents = all_items }, -- vampire
	{ merchantId = "lliros tures", contents = all_items }, -- house redoran

}

-- local logger = require("logging.logger").new { name = "RFuzzo", logLevel = "DEBUG" }
local manager = MerchantManager.new { modName = "Immersive Maps", containers = containers }

--- @param e initializedEventData
local function initializedCallback(e)
	-- init table
	-- vanilla
	map_table["bk_guide_to_ald_ruhn"] = "bookart/rfuzzo/MW-book-Ald'ruhn_Region.tga"
	map_table["bk_guide_to_balmora"] = "bookart/rfuzzo/MW-book-Balmora_Region.tga"
	map_table["bk_guide_to_sadrithmora"] = "bookart/rfuzzo/MW-book-Sadrith_Mora_Region.tga"
	map_table["bk_guide_to_vivec"] = "bookart/rfuzzo/MW-book-Vivec_Region.tga"
	map_table["bk_red_mountain_map"] = "bookart/rfuzzo/MW-book-Red_Mountain.tga"
	-- map_table["bk_guide_to_vvardenfell"] = "bookart/rfuzzo/"

	-- maps and compass outlander
	-- todo not sure if I want them

	-- maps and compass wagner
	map_table["bk_rf_wagner_mournhold"] = "MWSE/mods/Map and Compass/mapsWagner/mournholdMapWagner.tga"
	map_table["bk_rf_wagner_solstheim"] = "MWSE/mods/Map and Compass/mapsWagner/solstheimMapWagner.tga"
	map_table["bk_rf_wagner_vvardenfell"] = "MWSE/mods/Map and Compass/mapsWagner/vvardenfellMapWagner.tga"

	-- maps and compass gridmap
	map_table["bk_rf_gridmap_morrowind"] = "MWSE/mods/Map and Compass/mapsGridmap/mapMorrowind.tga"
	map_table["bk_rf_gridmap_morrowind_ne"] = "MWSE/mods/Map and Compass/mapsGridmap/mapNortheastMorrowind.tga"
	map_table["bk_rf_gridmap_morrowind_nw"] = "MWSE/mods/Map and Compass/mapsGridmap/mapNorthwestMorrowind.tga"
	map_table["bk_rf_gridmap_morrowind_se"] = "MWSE/mods/Map and Compass/mapsGridmap/mapSoutheastMorrowind.tga"
	map_table["bk_rf_gridmap_morrowind_sw"] = "MWSE/mods/Map and Compass/mapsGridmap/mapSouthwestMorrowind.tga"
	map_table["bk_rf_gridmap_v"] = "MWSE/mods/Map and Compass/mapsGridmap/mapVvardenfellandSolstheim.tga"
	map_table["bk_rf_gridmap_vm"] = "MWSE/mods/Map and Compass/mapsGridmap/mapVvardenfellandSolstheimwithMainland.tga"

	-- maps and compass Mel's N'wah Map Pack
	map_table["bk_rf_mel_ac"] = "MWSE/mods/Map and Compass/mapsNwah/nwahAzurasCoast.dds"
	map_table["bk_rf_mel_bc"] = "MWSE/mods/Map and Compass/mapsNwah/nwahBitterCoast.dds"
	map_table["bk_rf_mel_rm"] = "MWSE/mods/Map and Compass/mapsNwah/nwahRedMountain.dds"
	map_table["bk_rf_mel_s"] = "MWSE/mods/Map and Compass/mapsNwah/nwahSheogorad.dds"
	map_table["bk_rf_mel_is"] = "MWSE/mods/Map and Compass/mapsNwah/nwahTheInnerSea.dds"
	map_table["k_rf_mel_zb"] = "MWSE/mods/Map and Compass/mapsNwah/nwahZafirbelBay.dds"

	-- indexes of morrowind
	-- todo not sure if I want them
	manager:registerEvents()

	mwse.log("Immersive Maps initialized")
end
event.register(tes3.event.initialized, initializedCallback)

