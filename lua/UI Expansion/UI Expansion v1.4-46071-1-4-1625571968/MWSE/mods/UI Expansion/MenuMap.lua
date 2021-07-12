local common = require("UI Expansion.common")

local GUIID_MenuMap = tes3ui.registerID("MenuMap")
local GUIID_MenuMap_switch = tes3ui.registerID("MenuMap_switch")

--
-- Local/world map selection.
--

local function changeCell(e)
	local MenuMap = tes3ui.findMenu(GUIID_MenuMap)
	if (MenuMap == nil) then
		return
	end

	local MenuMap_switch = MenuMap:findChild(GUIID_MenuMap_switch)
	if (MenuMap_switch == nil) then
		return
	end

	if (e.cell.isInterior ~= true and MenuMap_switch.text == tes3.findGMST(tes3.gmst.sWorld).value) then
		MenuMap_switch:triggerEvent("mouseClick")
	end
	if (e.cell.isInterior and MenuMap_switch.text == tes3.findGMST(tes3.gmst.sLocal).value) then
		MenuMap_switch:triggerEvent("mouseClick")
	end
end

-- SmartMap compatibility
local lfs = require("lfs")
if lfs.attributes("Data Files/MWSE/mods/abot/Smart Map/main.lua") then
	mwse.log("[UI Expansion] MenuMap: skipping cellChanged event to be managed by abot/Smart Map");
else
	event.register("cellChanged", changeCell)
end

local function onKeyInput()
	if (common.complexKeybindTest(common.config.keybindMapSwitch)) then
		local MenuMap = tes3ui.findMenu(GUIID_MenuMap)
		if (MenuMap == nil) then
			return
		end
		
		local MenuMap_switch = MenuMap:findChild(GUIID_MenuMap_switch)
		if MenuMap_switch then
			MenuMap_switch:triggerEvent("mouseClick")
		end
	end
end
event.register("keyDown", onKeyInput)

--
-- Expanded world map with zoom features.
--

local gridBounds = { x = { min = 0, max = 0 }, y = { min = 0, max = 0 } }

local function reallocateMap(dataHandler)
	local mapWidth = 0
	local mapHeight = 0

	local mapTexture = niPixelData.new(mapWidth, mapHeight).createSourceTexture()
	mapTexture:fill({ 25, 36, 33 })
	dataHandler.nonDynamicData.mapTexture = mapTexture
end

local function onInitialized()
	-- Scan to see what the grid bounds are.
	for _, cell in ipairs(tes3.dataHandler.nonDynamicData.cells) do
		if (not cell.isInterior) then
			if (cell.gridX < gridBounds.x.min) then
				gridBounds.x.min = cell.gridX
			elseif (cell.gridX > gridBounds.x.max) then
				gridBounds.x.max = cell.gridX
			end

			if (cell.gridY < gridBounds.y.min) then
				gridBounds.y.min = cell.gridY
			elseif (cell.gridY > gridBounds.y.max) then
				gridBounds.y.max = cell.gridY
			end
		end
	end

	-- Ensure that map reallocations from loading are respected.
	mwse.memory.writeFunctionCall({
		-- call = 
	})
end
-- event.register("initialized", onInitialized)
